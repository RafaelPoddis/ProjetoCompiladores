%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "AAS.h"

extern int yylex();
extern int yyparse();
extern FILE* yyin;

void yyerror(const char* s);

/* Variáveis globais para o "Canvas" de impressão */
#define MAX_LINES 20
#define MAX_WIDTH 80
char canvas[MAX_LINES][MAX_WIDTH];

%}

%union {
    int   ival;
    float fval;
    struct AST* node;
}

%token<ival> T_INT
%token<fval> T_FLOAT
%token T_MAIS T_MENOS T_LPAR T_RPAR T_MULT T_DIV
%token T_NEWLINE

%left T_MAIS T_MENOS
%left T_MULT T_DIV

%type<node> exp termo fator

%start calculation 

%%

calculation:
    | calculation line
    ;

line: exp T_NEWLINE { 
        printf("\n");
        printTree($1); // Chama a nova função de print
        printf("\nResultado: %.2f\n", evalAST($1));
        printf("---------------------\n ");
        freeAST($1);
    }
    | T_NEWLINE { printf("> "); }
    ;

exp : exp T_MAIS termo    { $$ = createOpNode('+', $1, $3); } 
    | exp T_MENOS termo   { $$ = createOpNode('-', $1, $3); } 
    | termo               { $$ = $1; }      
    ;

termo : termo T_MULT fator    { $$ = createOpNode('*', $1, $3); } 
      | termo T_DIV fator     { $$ = createOpNode('/', $1, $3); } 
      | fator                 { $$ = $1; }      
      ;

fator : T_LPAR exp T_RPAR { $$ = $2; }
      | T_INT             { $$ = createValNode((float)$1); }
      | T_FLOAT           { $$ = createValNode($1); }
      ;

%%

int main(int argc, char **argv){
    if(argc > 1) yyin = fopen(argv[1], "r");
    else {
        printf("Digite uma expressão (ex: 2 * (3 + 4)):\n> ");
        yyin = stdin;
    }

    do { yyparse(); } while(!feof(yyin));

    if (yyin != stdin) fclose(yyin);
    return 0;
}

void yyerror(const char* s) {
    fprintf(stderr, "Erro: %s\n", s);
    exit(1);
}