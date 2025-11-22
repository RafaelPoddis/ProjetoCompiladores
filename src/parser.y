%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>

    extern int num_linha;
    extern int yylex();
    extern int yyparse();
    extern FILE* yyin;

    void yyerror(const char* s);
%}

%union {
    int     ival;
    char*   sval;
}

%token<ival> T_INT
%token<sval> T_STRING

%token T_IF T_ELSE T_WHILE T_RETURN T_VOID T_INPUT T_OUTPUT
%token ID NUM
%token T_MAIS T_MENOS T_VEZES T_DIVIDIDO
%token T_MENOR T_MAIOR T_MENOR_IGUAL T_MAIOR_IGUAL T_IGUAL T_DIFERENTE
%token T_RECEBE
%token T_PONTO_VIRGULA T_VIRGULA 
%token T_LPAR T_RPAR T_COLCHETE T_RCOLCHETE T_LCHAVE T_RCHAVE

%left T_MAIS T_MENOS

%%
    programa: 
        | declaration_list
        ;
    
    declaration_list:
        declaration_list declaration
        | declaration
        ;
%%