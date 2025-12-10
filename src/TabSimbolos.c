#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "TabSimbolos.h"

Tabela* criaTabela(Tabela* pai) {
    Tabela* tabela = (Tabela*) malloc(sizeof(Tabela));
    tabela->cabeca = NULL;
    tabela->pai = pai;
    return tabela;
}

void liberaTabela(Tabela* tabela) {
    if (tabela == NULL) return;
    Simbolo* simb = tabela->cabeca;
    while (simb != NULL) {
        Simbolo* prox = simb->prox;
        free(simb->name);
        free(simb);
        simb = prox;
    }
    free(tabela);
}

int insereSimbolo(Tabela* tabela, char* name, VarType type, int ehArray, int tamanhoArray, int ehFuncao, int linha) {
    // Verifica se ja esta no escopo
    Simbolo* simb = tabela->cabeca;
    while (simb != NULL) {
        if (strcmp(simb->name, name) == 0) {
            fprintf(stderr, "ERRO SEMANTICO linha %d: Variavel '%s' ja declarada na linha %d\n", 
                    linha, name, simb->linha);
            return 0; // Erro
        }
        simb = simb->prox;
    }
    
    // Insere novo simbolo
    Simbolo* novoSimb = (Simbolo*) malloc(sizeof(Simbolo));
    novoSimb->name = strdup(name);
    novoSimb->type = type;
    novoSimb->ehArray = ehArray;
    novoSimb->tamanhoArray = tamanhoArray;
    novoSimb->ehFuncao = ehFuncao;
    novoSimb->linha = linha;
    novoSimb->prox = tabela->cabeca;
    tabela->cabeca = novoSimb;
    return 1; // Deu certo
}

Simbolo* procuraSimbolo(Tabela* tabela, char* name, int procuraPai) {
    Simbolo* simb = tabela->cabeca;
    while (simb != NULL) {
        if (strcmp(simb->name, name) == 0) {
            return simb;
        }
        simb = simb->prox;
    }
    
    // Procura no escopo pai se necessario
    if (procuraPai && tabela->pai != NULL) {
        return procuraSimbolo(tabela->pai, name, procuraPai);
    }
    
    return NULL; // Não encontrado
}

void verificaMain(AST* arvore) {
    if (arvore == NULL) return;
    AST* noAtual = arvore;
    while (noAtual->irmao != NULL) {
        noAtual = noAtual->irmao;
    }
    int temErro = 0;
    //Tem q ser funcao
    if (noAtual->type != TYPE_STMT || noAtual->kind.stmt != FunDecK) temErro = 1;
    //Tem q ser main
    else if (strcmp(noAtual->name, "main") != 0) temErro = 1;
    //Tem q ser retorno void
    else if (noAtual->varType != Void) temErro = 1;
    //Tem q n ter parametros
    else if (noAtual->filho[0] != NULL) temErro = 1;

    if (temErro) {
        fprintf(stderr, "ERRO SEMANTICO: A ultima declaracao DEVE ser 'void main(void)'.\n");
        fprintf(stderr, " -> Encontrado: ");
        if (noAtual->type == TYPE_STMT && noAtual->kind.stmt == FunDecK) {
            char* tipoStr = (noAtual->varType == Integer) ? "int" : "void";
            printf("%s %s(...)\n", tipoStr, noAtual->name);
        } else {
            printf("Uma declaracao de variavel ou outro elemento.\n");
        }
    }
}

void verificaSemantica(AST* arvore, Tabela* tabela) {
    if (arvore == NULL) return;
    
    if (arvore->type == TYPE_STMT) {
        switch (arvore->kind.stmt) {
            case VarDecK:
                //verica se variavel e do tipo void
                if (arvore->varType == Void) fprintf(stderr, "ERRO SEMANTICO linha %d: Variavel '%s' declarada como VOID. Apenas INT e permitido.\n", arvore->linha, arvore->name);
                // Insere variavel na tabela de simbolos
                insereSimbolo(tabela, arvore->name, arvore->varType, 
                           (arvore->attr.val > 0), arvore->attr.val, 0, arvore->linha);
                break;
                
            case FunDecK:{
                // Insere função na tabela de simbolos
                insereSimbolo(tabela, arvore->name, arvore->varType, 0, 0, 1, arvore->linha);
                // Cria novo escopo para a função
                Tabela* escopoFuncao = criaTabela(tabela);
                verificaSemantica(arvore->filho[0], escopoFuncao); // Parâmetros
                verificaSemantica(arvore->filho[1], escopoFuncao); // Corpo da função
                liberaTabela(escopoFuncao);
                break;
            }
            case CompoundK:{
                // Cria novo escopo para o bloco composto
                Tabela* escopoBloco = criaTabela(tabela);
                verificaSemantica(arvore->filho[0], escopoBloco); // Declarações locais
                verificaSemantica(arvore->filho[1], escopoBloco); // Instruções
                liberaTabela(escopoBloco);
                break;
                }
            case AssignK:
                // Verifica se a variavel existe antes da atribuição
                verificaSemantica(arvore->filho[0], tabela); // Verifica esquerda
                verificaSemantica(arvore->filho[1], tabela); // Verifica direita
                break;
                
            default:
                // Processa filhos para outras instruções
                for (int i = 0; i < 3; i++) {
                    verificaSemantica(arvore->filho[i], tabela);
                }
                break;
        }
    } 
    else if (arvore->type == TYPE_EXP) {
        if (arvore->kind.exp == IdK) {
            // Verifica se a variavel foi declarada
            Simbolo* simb = procuraSimbolo(tabela, arvore->name, 1);
            if (simb == NULL) {
                fprintf(stderr, "ERRO SEMANTICO linha %d: Variavel '%s' nao declarada\n", 
                        arvore->linha, arvore->name);
            }
        }
        else if (arvore->kind.exp == OpK) { //verifica divisao por zero
            if (arvore->attr.oper == '/') { 
                AST* denominador = arvore->filho[1]; 
                if (denominador != NULL && denominador->kind.exp == ConstK && denominador->attr.val == 0) { 
                    fprintf(stderr, "ERRO SEMANTICO linha %d: Divisao por zero explicita detectada.\n", arvore->linha);
                }
            }
        }
        // Processa filhos para expressões
        for (int i = 0; i < 3; i++) {
            verificaSemantica(arvore->filho[i], tabela);
        }
    }
    
    // Processa nós irmãos
    verificaSemantica(arvore->irmao, tabela);
}

void printTabela(Tabela* tabela, int nivel) {
    if (tabela == NULL) return;
    
    // Imprime indentação baseada no nivel do escopo
    for (int i = 0; i < nivel; i++) {
        printf("  ");
    }
    printf("=== Escopo Nivel %d ===\n", nivel);
    
    if (tabela->cabeca == NULL) {
        for (int i = 0; i < nivel; i++) {
            printf("  ");
        }
        printf("(vazio)\n");
    } else {
        Simbolo* simb = tabela->cabeca;
        while (simb != NULL) {
            for (int i = 0; i < nivel; i++) {
                printf("  ");
            }
            
            // Imprime detalhes do simbolo
            if (simb->ehFuncao) {
                printf("Funcao: %s", simb->name);
                if (simb->type == Integer) {
                    printf(" -> int");
                } else {
                    printf(" -> void");
                }
                printf(" (linha %d)\n", simb->linha);
            } else {
                printf("Variavel: %s", simb->name);
                if (simb->type == Integer) {
                    printf(" : int");
                } else {
                    printf(" : void");
                }
                if (simb->ehArray) {
                    printf("[%d]", simb->tamanhoArray);
                }
                printf(" (linha %d)\n", simb->linha);
            }
            
            simb = simb->prox;
        }
    }
    printf("\n");
}