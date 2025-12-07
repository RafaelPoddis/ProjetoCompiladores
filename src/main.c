#include <stdio.h>
#include <stdlib.h>
#include "globals.h"

/* 1. Definição das variáveis globais (Flags) */
int num_linha = 1;
int TraceScan = 0; /* Mude para 1 se quiser ver tokens */
int TraceParse = 0; /* Mude para 1 se quiser ver a árvore */
int TraceCode = 1; /* Mude para 1 se quiser ver o código gerado */
int Error = 0;

/* Variáveis externas do Flex/Bison */
extern FILE *yyin;
extern int yyparse();

/* Protótipos do CGEN */
char * cgen(TreeNode * syntaxTree);
void printQuads(); 

int main(int argc, char** argv) {
    /* Lógica de abertura de arquivo */
    if(argc > 1){
        yyin = fopen(argv[1], "r");
        if(yyin == NULL){
            fprintf(stderr, "Problema na leitura do arquivo: %s\n", argv[1]);
            return 1;
        }
    } else {
        /* Caminho padrão ou stdin */
        yyin = fopen("src/entrada.txt", "r");        
        if(yyin == NULL){
            fprintf(stderr, "Arquivo src/entrada.txt não encontrado. Usando entrada padrão.\n");
            yyin = stdin; 
        }
    }

    printf("Iniciando analise...\n");
    
    /* 2. Chama o Parser (Análise Sintática) */
    yyparse(); 

    /* Verifica se houve erro antes de prosseguir */
    if (Error) {
        printf("Compilacao abortada devido a erros.\n");
        return 1;
    }

    printf("Analise concluida. Gerando codigo...\n");

    /* 3. Chama o Gerador de Código (Passando a árvore salva) */
    if (savedTree != NULL) {
        cgen(savedTree);
        
        /* 4. Imprime as Quádruplas geradas */
        printQuads();
    } else {
        printf("A arvore sintatica esta vazia (programa vazio?).\n");
    }

    if (yyin != stdin) fclose(yyin);

    return 0;
}
