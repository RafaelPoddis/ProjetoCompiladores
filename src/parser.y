/* -------------------------------------------------- */
/* -------- Todo código abaixo está de acordo ------- */
/* - com o Apendice A do livro do Kenneth C. Louden - */
/* -------------------------------------------------- */

%expect 1

%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include "stdarg.h"
    #include "AAS.h"

    extern int num_linha;
    extern int yylex();
    extern int yyparse();
    // extern FILE* yyin;

    void yyerror(const char* s) {
        fprintf(stderr, "ERRO SINTATICO: %s - LINHA: %d\n", s, num_linha);
        exit(EXIT_FAILURE);
    }

    /* Variáveis globais para o "Canvas" de impressão */
    #define MAX_LINES 20
    #define MAX_WIDTH 80
    char canvas[MAX_LINES][MAX_WIDTH];

%}

/* ------------------------------------- */
/* - Declaração dos tipos de variaveis - */
/* ------------------------------------- */
%union {
    int     ival;
    char    *sval;
    struct AST* node;
}

/* ------------------------------------- */
/* ------- Declaração dos tokens ------- */
/* ------------------------------------- */
%token<ival> NUM
%token<sval> ID

%token T_IF T_ELSE T_WHILE T_RETURN T_VOID T_INT
%token T_MAIS T_MENOS T_VEZES T_DIVIDIDO
%token T_MENOR T_MAIOR T_MENOR_IGUAL T_MAIOR_IGUAL T_IGUALDADE T_DIFERENTE
%token T_RECEBE
%token T_PONTO_VIRGULA T_VIRGULA 
%token T_LPAR T_RPAR T_LCOLCHETE T_RCOLCHETE T_LCHAVE T_RCHAVE

%left T_MAIS T_MENOS
%left T_VEZES T_DIVIDIDO

%type <node> addop mulop term factor expression var simple_expression relop

/* ------------------------------------- */
/* ------- Gramática Transcrita -------- */
/* ------------------------------------- */
%%
    programa: 
        | declaration_list
        ;
    
    declaration_list:
        declaration_list declaration
        | declaration
        ;

    declaration:
        var_declaration
        | fun_declaration
        ;

    var_declaration:
        type_specifier ID T_PONTO_VIRGULA
        | type_specifier ID T_LCOLCHETE NUM T_RCOLCHETE T_PONTO_VIRGULA
        ;

    type_specifier:
        T_INT
        | T_VOID
        ;

    fun_declaration:
        type_specifier ID T_LPAR params T_RPAR compound_stmt
        ;

    params:
        param_list
        | T_VOID
        ;

    param_list:
        param_list T_VIRGULA param
        | param
        ;

    param:
        type_specifier ID
        | type_specifier ID T_LCOLCHETE T_RCOLCHETE
        ;

    compound_stmt:
        T_LCHAVE local_declarations statement_list T_RCHAVE
        ;

    local_declarations:
        local_declarations var_declaration
        | /* empty */
        ;

    statement_list:
        statement_list statement
        | /* empty */
        ;

    statement:
        expression_stmt
        | compound_stmt
        | selection_stmt
        | iteration_stmt
        | return_stmt
        ;

    expression_stmt:
        expression T_PONTO_VIRGULA
        | T_PONTO_VIRGULA
        ;

    selection_stmt:
        T_IF T_LPAR expression T_RPAR statement
        | T_IF T_LPAR expression T_RPAR statement T_ELSE statement
        ;

    iteration_stmt:
        T_WHILE T_LPAR expression T_RPAR statement
        ;

    return_stmt:
        T_RETURN T_PONTO_VIRGULA
        | T_RETURN expression T_PONTO_VIRGULA
        ;

    expression:
        var T_RECEBE expression
        | simple_expression
        ;

    var:
        ID
        | ID T_LCOLCHETE expression T_RCOLCHETE
        ;

    simple_expression:
        additive_expression relop additive_expression
        | additive_expression
        ;

    relop:
        T_MENOR_IGUAL
        | T_MENOR
        | T_MAIOR
        | T_MAIOR_IGUAL
        | T_IGUALDADE
        | T_DIFERENTE
        ;

    additive_expression:
        additive_expression addop term
        | term
        ;

    addop:
        T_MAIS      { $$ = createOpNode('+', $1, $3); }
        | T_MENOS    { $$ = createOpNode('-', $1, $3); }
        ;

    term:
        term mulop factor { $$ = createOpNode($2, $1, $3); }
        | factor
        ;

    mulop:
        T_VEZES
        | T_DIVIDIDO
        ;

    factor:
        T_LPAR expression T_RPAR
        | var
        | call
        | NUM   { $$ = createValNode($1); }
        ;

    call:
        ID T_LPAR args T_RPAR
        ;
    
    args:
        arg_list
        | /* empty */
        ;

    arg_list:
        arg_list T_VIRGULA expression
        | expression
        ;
%%