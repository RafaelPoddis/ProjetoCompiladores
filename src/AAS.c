#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "AAS.h"

extern int num_linha;

/* Variável de indentação para impressão */
static int indent = 0;

/* --- CONSTRUTORES --- */

AST* newStmtNode(StmtType kind) {
    AST* node = (AST*) malloc(sizeof(AST));
    int i;
    for (i = 0; i < 3; i++) node->filho[i] = NULL;
    node->irmao = NULL;
    node->type = TYPE_STMT;
    node->kind.stmt = kind;
    node->linha = num_linha; 
    return node;
}

AST* newExpNode(ExpType kind) {
    AST* node = (AST*) malloc(sizeof(AST));
    int i;
    for (i = 0; i < 3; i++) node->filho[i] = NULL;
    node->irmao = NULL;
    node->type = TYPE_EXP;
    node->kind.exp = kind;
    node->varType = Void;
    node->linha = num_linha;
    return node;
}

AST* createOpNode(int op, AST* left, AST* right) {
    AST* node = newExpNode(OpK);
    node->filho[0] = left;
    node->filho[1] = right;
    node->attr.oper = op;
    node->linha = num_linha;
    return node;
}

AST* createValNode(float val) {
    AST* node = newExpNode(ConstK);
    node->attr.val = (int)val;
    node->linha = num_linha;
    return node;
}

AST* createIdNode(char* name) {
    AST* node = newExpNode(IdK);
    if (name != NULL) node->name = strdup(name);
    else node->name = NULL;
    node->linha = num_linha;
    return node;
}

/* --- FUNÇÕES AUXILIARES --- */

void freeAST(AST* node) {
    if (node == NULL) return;
    int i;
    for (i = 0; i < 3; i++) freeAST(node->filho[i]);
    freeAST(node->irmao);
    if (node->type == TYPE_EXP && node->kind.exp == IdK && node->name != NULL) {
        free(node->name);
    }
    free(node);
}

void printTree(AST* tree) {
    int i;
    while (tree != NULL) {
        // Indentação
        for (i = 0; i < indent; i++) printf("  ");
        
        if (tree->type == TYPE_STMT) {
            switch (tree->kind.stmt) {
                case IfK:     printf("If\n"); break;
                case WhileK:  printf("While\n"); break;
                case AssignK: printf("Atribuicao\n"); break;
                case ReturnK: printf("Return\n"); break;
                
                case VarDecK: 
                    printf("Declaracao Var: %s", tree->name);
                    if (tree->varType == Integer) printf(" (int)"); else printf(" (void)");
                    if (tree->attr.val > 0) printf(" [Vetor tam: %d]", tree->attr.val);
                    printf("\n");
                    break;

                case FunDecK:
                    printf("Declaracao Funcao: %s", tree->name);
                    if (tree->varType == Integer) printf(" (int)\n"); else printf(" (void)\n");
                    break;
                
                case CallK:
                    printf("Chamada de Funcao: %s\n", tree->name);
                    break;

                case CompoundK:
                    printf("Bloco { ... }\n");
                    break;

                default:      
                    printf("Statement Desconhecido\n"); 
                    break;
            }
        } else if (tree->type == TYPE_EXP) {
            switch (tree->kind.exp) {
                case OpK:    
                    printf("Op: ");
                    switch(tree->attr.oper) {
                        case LE_OP: printf("<=\n"); break;
                        case GE_OP: printf(">=\n"); break;
                        case EQ_OP: printf("==\n"); break;
                        case NE_OP: printf("!=\n"); break;
                        default:    printf("%c\n", tree->attr.oper); break;
                    }
                    break;
                case ConstK: printf("Const: %d\n", tree->attr.val); break;
                case IdK:    printf("Id: %s\n", tree->name); break;
                default:     printf("Exp Desconhecida\n"); break;
            }
        } else {
            printf("No Desconhecido\n");
        }
        
        indent++;
        for (i = 0; i < 3; i++) {
            printTree(tree->filho[i]);
        }
        indent--;
        tree = tree->irmao;
    }
}