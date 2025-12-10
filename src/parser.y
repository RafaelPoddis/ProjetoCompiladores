/* -------------------------------------------------- */
/* -------- Todo código abaixo está de acordo ------- */
/* - com o Apendice A do livro do Kenneth C. Louden - */
/* -------------------------------------------------- */

%error-verbose
%expect 1

%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include "AAS.h"

    extern int num_linha;
    extern int yylex();
    extern int yyparse();
    extern FILE* yyin;
    extern char* yytext; 

    void yyerror(const char* s) {
        /* s contém a mensagem automática do Bison */
        fprintf(stderr, "ERRO SINTATICO: %s\n", s);
        fprintf(stderr, " -> Ocorreu na linha %d, perto de: '%s'\n", num_linha, yytext);
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
};

/* ------------------------------------- */
/* ------- Declaração dos tokens ------- */
/* ------------------------------------- */
%token<ival> NUM "numero"
%token<sval> ID  "identificador"

/* Palavras chave */
%token T_IF "if" 
%token T_ELSE "else" 
%token T_WHILE "while" 
%token T_RETURN "return" 
%token T_VOID "void" 
%token T_INT "int"

/* Operadores */
%token T_MAIS "+" 
%token T_MENOS "-" 
%token T_VEZES "*" 
%token T_DIVIDIDO "/"

/* Comparadores */
%token T_MENOR "<" 
%token T_MAIOR ">" 
%token T_MENOR_IGUAL "<=" 
%token T_MAIOR_IGUAL ">=" 
%token T_IGUALDADE "==" 
%token T_DIFERENTE "!="
%token T_RECEBE "="

/* Pontuacao */
%token T_PONTO_VIRGULA ";" 
%token T_VIRGULA "," 
%token T_LPAR "(" 
%token T_RPAR ")" 
%token T_LCOLCHETE "[" 
%token T_RCOLCHETE "]" 
%token T_LCHAVE "{" 
%token T_RCHAVE "}"

%left T_MAIS T_MENOS
%left T_VEZES T_DIVIDIDO

%type <ival> addop mulop relop type_specifier

%type <node> program declaration_list declaration var_declaration fun_declaration
%type <node> params param_list param compound_stmt local_declarations statement_list
%type <node> statement expression_stmt selection_stmt iteration_stmt return_stmt
%type <node> expression var simple_expression additive_expression term factor call args arg_list

/* ------------------------------------- */
/* ------- Gramática Transcrita -------- */
/* ------------------------------------- */
%%
    program: 
        declaration_list
        {
            printf("\n--- INICIO DA ARVORE ---\n");
            printTree($1); 
            printf("--- FIM DA ARVORE ---\n");
        }
        ;
    
    declaration_list:
        declaration_list declaration
        {
            AST * t = $1;
            if (t != NULL) {
                while (t->irmao != NULL)
                    t = t->irmao;
                t->irmao = $2;
                $$ = $1;
            } else {
                $$ = $2;
            }
        }
        | declaration { $$ = $1; }
        ;

    declaration:
        var_declaration { $$ = $1; }
        | fun_declaration { $$ = $1; }
        ;

    var_declaration:
        type_specifier ID T_PONTO_VIRGULA
        {
            $$ = newStmtNode(VarDecK);
            $$->varType = ($1 == T_INT) ? Integer : Void;
            $$->name = $2; 
            $$->attr.val = 0; 
        }
        | type_specifier ID T_LCOLCHETE NUM T_RCOLCHETE T_PONTO_VIRGULA
        {
            $$ = newStmtNode(VarDecK);
            $$->varType = ($1 == T_INT) ? Integer : Void;
            $$->name = $2;
            $$->attr.val = $4;
        }
        ;

    type_specifier:
        T_INT   { $$ = T_INT; }
        | T_VOID { $$ = T_VOID; }
        ;

    fun_declaration:
        type_specifier ID T_LPAR params T_RPAR compound_stmt
        {
            $$ = newStmtNode(FunDecK);
            $$->varType = ($1 == T_INT) ? Integer : Void;
            $$->name = $2;
            $$->filho[0] = $4;
            $$->filho[1] = $6;
        }
        ;

    params:
        param_list { $$ = $1; }
        | T_VOID   { $$ = NULL; }
        ;

    param_list:
        param_list T_VIRGULA param
        {
            AST * t = $1;
            if (t != NULL) {
                while (t->irmao != NULL) t = t->irmao;
                t->irmao = $3;
                $$ = $1;
            } else {
                $$ = $3;
            }
        }
        | param { $$ = $1; }
        ;

    param:
        type_specifier ID
        {
            $$ = newStmtNode(VarDecK); 
            $$->varType = ($1 == T_INT) ? Integer : Void;
            $$->name = $2;
            $$->attr.val = 0; 
        }
        | type_specifier ID T_LCOLCHETE T_RCOLCHETE
        {
            $$ = newStmtNode(VarDecK);
            $$->varType = ($1 == T_INT) ? Integer : Void;
            $$->name = $2;
            $$->attr.val = 1; 
        }
        ;

    compound_stmt:
        T_LCHAVE local_declarations statement_list T_RCHAVE
        {
            $$ = newStmtNode(CompoundK); 
            $$->filho[0] = $2; 
            $$->filho[1] = $3; 
        }
        ;

    local_declarations:
        local_declarations var_declaration
        {
            AST * t = $1;
            if (t != NULL) {
                while (t->irmao != NULL) t = t->irmao;
                t->irmao = $2;
                $$ = $1;
            } else {
                $$ = $2;
            }
        }
        | /* empty */ { $$ = NULL; }
        ;

    statement_list:
        statement_list statement
        {
            AST * t = $1;
            if (t != NULL) {
                while (t->irmao != NULL) t = t->irmao;
                t->irmao = $2;
                $$ = $1;
            } else {
                $$ = $2;
            }
        }
        | /* empty */ { $$ = NULL; }
        ;

    statement:
        expression_stmt { $$ = $1; }
        | compound_stmt { $$ = $1; }
        | selection_stmt { $$ = $1; }
        | iteration_stmt { $$ = $1; }
        | return_stmt { $$ = $1; }
        ;

    expression_stmt:
        expression T_PONTO_VIRGULA { $$ = $1; }
        | T_PONTO_VIRGULA { $$ = NULL; }
        ;

    selection_stmt:
        T_IF T_LPAR expression T_RPAR statement
        {
            $$ = newStmtNode(IfK);
            $$->filho[0] = $3; // condicao
            $$->filho[1] = $5; // then
        }
        | T_IF T_LPAR expression T_RPAR statement T_ELSE statement
        {
            $$ = newStmtNode(IfK);
            $$->filho[0] = $3; // condicao
            $$->filho[1] = $5; // then 
            $$->filho[2] = $7; // else 
        }
        ;

    iteration_stmt:
        T_WHILE T_LPAR expression T_RPAR statement
        {
            $$ = newStmtNode(WhileK);
            $$->filho[0] = $3; // condicao 
            $$->filho[1] = $5; // loop 
        }
        ;

    return_stmt:
        T_RETURN T_PONTO_VIRGULA
        {
            $$ = newStmtNode(ReturnK);
        }
        | T_RETURN expression T_PONTO_VIRGULA
        {
            $$ = newStmtNode(ReturnK);
            $$->filho[0] = $2;
        }
        ;

    expression:
        var T_RECEBE expression
        {
            $$ = newStmtNode(AssignK); //atribui
            $$->filho[0] = $1; //var
            $$->filho[1] = $3; //Valor
        }
        | simple_expression { $$ = $1; }
        ;

    var:
        ID
        {
            $$ = createIdNode($1);
        }
        | ID T_LCOLCHETE expression T_RCOLCHETE
        {
            $$ = createIdNode($1);
            $$->filho[0] = $3;
        }
        ;

    simple_expression:
        additive_expression relop additive_expression
        {
            switch($2) {
                case T_MENOR_IGUAL: $$ = createOpNode(LE_OP, $1, $3); break;
                case T_MENOR:       $$ = createOpNode('<', $1, $3); break;
                case T_MAIOR:       $$ = createOpNode('>', $1, $3); break;
                case T_MAIOR_IGUAL: $$ = createOpNode(GE_OP, $1, $3); break; 
                case T_IGUALDADE:   $$ = createOpNode(EQ_OP, $1, $3); break;
                case T_DIFERENTE:   $$ = createOpNode(NE_OP, $1, $3); break;
                default:            $$ = createOpNode('?', $1, $3);
            }
        }
        | additive_expression { $$ = $1; }
        ;

    relop:
        T_MENOR_IGUAL { $$ = T_MENOR_IGUAL; }
        | T_MENOR     { $$ = T_MENOR; }
        | T_MAIOR     { $$ = T_MAIOR; }
        | T_MAIOR_IGUAL { $$ = T_MAIOR_IGUAL; }
        | T_IGUALDADE   { $$ = T_IGUALDADE; }
        | T_DIFERENTE   { $$ = T_DIFERENTE; }
        ;

    additive_expression:
        additive_expression addop term
        {
            $$ = ($2 == T_MAIS) ? createOpNode('+', $1, $3) : createOpNode('-', $1, $3);
        }
        | term { $$ = $1; }
        ;

    addop:
        T_MAIS  { $$ = T_MAIS; }
        | T_MENOS { $$ = T_MENOS; }
        ;

    term:
        term mulop factor
        {
            $$ = ($2 == T_VEZES) ? createOpNode('*', $1, $3) : createOpNode('/', $1, $3);
        }
        | factor { $$ = $1; }
        ;

    mulop:
        T_VEZES    { $$ = T_VEZES; }
        | T_DIVIDIDO { $$ = T_DIVIDIDO; }
        ;

    factor:
        T_LPAR expression T_RPAR { $$ = $2; }
        | var  { $$ = $1; }
        | call { $$ = $1; }
        | NUM  { $$ = createValNode($1); }
        ;

    call:
        ID T_LPAR args T_RPAR
        {
            $$ = newStmtNode(CallK); 
            $$->name = $1;
            $$->filho[0] = $3; //args
        }
        ;
    
    args:
        arg_list { $$ = $1; }
        | /* empty */ { $$ = NULL; }
        ;

    arg_list:
        arg_list T_VIRGULA expression
        {
            AST * t = $1;
            if (t != NULL) {
                while (t->irmao != NULL) t = t->irmao;
                t->irmao = $3;
                $$ = $1;
            } else {
                $$ = $3;
            }
        }
        | expression { $$ = $1; }
        ;

%%

/* --- CÓDIGO DO MAIN --- */

extern FILE* yyin;

int main(int argc, char** argv) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            perror("Erro ao abrir arquivo");
            return 1;
        }
    }

    printf("Iniciando analise sintatica\n");
    if (yyparse() == 0) {
        printf("Gramatica aceita.\n");
    } else {
        printf("Falha na analise sintatica.\n");
    }
    
    if (yyin) fclose(yyin);
    return 0;
}