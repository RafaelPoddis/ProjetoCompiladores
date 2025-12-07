/* -------------------------------------------------- */
/* Modificado para construir a AST conforme Louden    */
/* -------------------------------------------------- */

%{
#include "globals.h"
#include "util.c" // Incluindo diretamente para simplificar compilação neste exemplo
#define YYSTYPE TreeNode *

TreeNode * savedTree; /* Árvore final */
extern int yylex();
void yyerror(const char* s);
%}

/* Atualização da Union para manipular nós da árvore */
/* Como definimos YYSTYPE como TreeNode*, não precisamos da %union complexa antiga para nós,
   mas precisamos lidar com tokens que retornam strings/ints do scanner.
   No scanner, mantenha yylval.sval e ival, mas aqui faremos type casting quando necessário
   ou alteramos o scanner para retornar tudo em nós ou strings.
   
   Para simplificar e manter seu scanner: Vamos assumir que o yylex retorna tokens e
   seta valores globais ou usa uma union compatível.
*/

%token T_IF T_ELSE T_WHILE T_RETURN T_VOID T_INT
%token T_MAIS T_MENOS T_VEZES T_DIVIDIDO
%token T_MENOR T_MAIOR T_MENOR_IGUAL T_MAIOR_IGUAL T_IGUALDADE T_DIFERENTE
%token T_RECEBE T_PONTO_VIRGULA T_VIRGULA 
%token T_LPAR T_RPAR T_LCOLCHETE T_RCOLCHETE T_LCHAVE T_RCHAVE
%token ID NUM

%left T_MAIS T_MENOS
%left T_VEZES T_DIVIDIDO

%%

/* Regras da Gramática com Ações Semânticas */

programa: declaration_list
        { savedTree = $1; }
        ;

declaration_list: declaration_list declaration
        {
             TreeNode * t = $1;
             if (t != NULL) {
                 while (t->sibling != NULL) t = t->sibling;
                 t->sibling = $2;
                 $$ = $1;
             } else $$ = $2;
        }
        | declaration { $$ = $1; }
        ;

declaration: var_declaration { $$ = $1; }
           | fun_declaration { $$ = $1; }
           ;

var_declaration: type_specifier ID T_PONTO_VIRGULA
        {
             $$ = newExpNode(VarK); // Usamos VarK para declaração simples também
             $$->attr.name = copyString(((TreeNode*)$2)->attr.name); // Assumindo que ID vem como nó ou string
             $$->child[0] = $1; // Tipo
        }
        | type_specifier ID T_LCOLCHETE NUM T_RCOLCHETE T_PONTO_VIRGULA
        {
             $$ = newExpNode(VarK);
             $$->attr.name = copyString(((TreeNode*)$2)->attr.name);
             $$->child[0] = $1; // Tipo
             // Adicionar tamanho do array como atributo ou filho
        }
        ;

type_specifier: T_INT 
        { 
            $$ = newExpNode(TypeK); 
            $$->type = Integer; 
        }
        | T_VOID 
        { 
            $$ = newExpNode(TypeK); 
            $$->type = Void; 
        }
        ;

fun_declaration: type_specifier ID T_LPAR params T_RPAR compound_stmt
        {
            $$ = newStmtNode(CompoundK); // Representando função
            // Lógica para nome da função e filhos (tipo, params, corpo)
            $$->child[0] = $1; // Tipo retorno
            $$->child[1] = $4; // Params
            $$->child[2] = $6; // Corpo
            $$->attr.name = copyString(((TreeNode*)$2)->attr.name); 
        }
        ;

params: param_list { $$ = $1; }
      | T_VOID { $$ = NULL; }
      ;

param_list: param_list T_VIRGULA param
        {
             TreeNode * t = $1;
             if (t != NULL) {
                 while (t->sibling != NULL) t = t->sibling;
                 t->sibling = $3;
                 $$ = $1;
             } else $$ = $3;
        }
        | param { $$ = $1; }
        ;

param: type_specifier ID
        {
            $$ = newExpNode(VarK);
            $$->child[0] = $1;
            $$->attr.name = copyString(((TreeNode*)$2)->attr.name);
        }
        | type_specifier ID T_LCOLCHETE T_RCOLCHETE
        {
            $$ = newExpNode(VarK);
            $$->child[0] = $1;
            $$->attr.name = copyString(((TreeNode*)$2)->attr.name);
            // Marcar como array
        }
        ;

compound_stmt: T_LCHAVE local_declarations statement_list T_RCHAVE
        {
            $$ = newStmtNode(CompoundK);
            $$->child[0] = $2; // Declarações locais
            $$->child[1] = $3; // Statements
        }
        ;

local_declarations: local_declarations var_declaration
        {
             TreeNode * t = $1;
             if (t != NULL) {
                 while (t->sibling != NULL) t = t->sibling;
                 t->sibling = $2;
                 $$ = $1;
             } else $$ = $2;
        }
        | /* empty */ { $$ = NULL; }
        ;

statement_list: statement_list statement
        {
             TreeNode * t = $1;
             if (t != NULL) {
                 while (t->sibling != NULL) t = t->sibling;
                 t->sibling = $2;
                 $$ = $1;
             } else $$ = $2;
        }
        | /* empty */ { $$ = NULL; }
        ;

statement: expression_stmt { $$ = $1; }
         | compound_stmt { $$ = $1; }
         | selection_stmt { $$ = $1; }
         | iteration_stmt { $$ = $1; }
         | return_stmt { $$ = $1; }
         ;

expression_stmt: expression T_PONTO_VIRGULA { $$ = $1; }
               | T_PONTO_VIRGULA { $$ = NULL; }
               ;

selection_stmt: T_IF T_LPAR expression T_RPAR statement
        {
            $$ = newStmtNode(IfK);
            $$->child[0] = $3; // Condição
            $$->child[1] = $5; // Then
        }
        | T_IF T_LPAR expression T_RPAR statement T_ELSE statement
        {
            $$ = newStmtNode(IfK);
            $$->child[0] = $3; // Condição
            $$->child[1] = $5; // Then
            $$->child[2] = $7; // Else
        }
        ;

iteration_stmt: T_WHILE T_LPAR expression T_RPAR statement
        {
            $$ = newStmtNode(WhileK);
            $$->child[0] = $3; // Condição
            $$->child[1] = $5; // Corpo
        }
        ;

return_stmt: T_RETURN T_PONTO_VIRGULA
        {
             $$ = newStmtNode(ReturnK);
        }
        | T_RETURN expression T_PONTO_VIRGULA
        {
             $$ = newStmtNode(ReturnK);
             $$->child[0] = $2;
        }
        ;

expression: var T_RECEBE expression
        {
            $$ = newStmtNode(AssignK); // ou ExpK com attr op '='
            $$->child[0] = $1; // L-value
            $$->child[1] = $3; // R-value
        }
        | simple_expression { $$ = $1; }
        ;

var: ID
        {
            $$ = newExpNode(IdK);
            $$->attr.name = copyString(((TreeNode*)$1)->attr.name);
        }
        | ID T_LCOLCHETE expression T_RCOLCHETE
        {
            $$ = newExpNode(IdK);
            $$->attr.name = copyString(((TreeNode*)$1)->attr.name);
            $$->child[0] = $3; // Índice
        }
        ;

simple_expression: additive_expression relop additive_expression
        {
            $$ = newExpNode(OpK);
            $$->child[0] = $1;
            $$->child[1] = $3;
            $$->attr.op = ((TreeNode*)$2)->attr.op;
        }
        | additive_expression { $$ = $1; }
        ;

relop: T_MENOR_IGUAL { $$ = newExpNode(OpK); $$->attr.op = T_MENOR_IGUAL; }
     | T_MENOR       { $$ = newExpNode(OpK); $$->attr.op = T_MENOR; }
     | T_MAIOR       { $$ = newExpNode(OpK); $$->attr.op = T_MAIOR; }
     | T_MAIOR_IGUAL { $$ = newExpNode(OpK); $$->attr.op = T_MAIOR_IGUAL; }
     | T_IGUALDADE   { $$ = newExpNode(OpK); $$->attr.op = T_IGUALDADE; }
     | T_DIFERENTE   { $$ = newExpNode(OpK); $$->attr.op = T_DIFERENTE; }
     ;

additive_expression: additive_expression addop term
        {
            $$ = newExpNode(OpK);
            $$->child[0] = $1;
            $$->child[1] = $3;
            $$->attr.op = ((TreeNode*)$2)->attr.op;
        }
        | term { $$ = $1; }
        ;

addop: T_MAIS  { $$ = newExpNode(OpK); $$->attr.op = T_MAIS; }
     | T_MENOS { $$ = newExpNode(OpK); $$->attr.op = T_MENOS; }
     ;

term: term mulop factor
        {
            $$ = newExpNode(OpK);
            $$->child[0] = $1;
            $$->child[1] = $3;
            $$->attr.op = ((TreeNode*)$2)->attr.op;
        }
        | factor { $$ = $1; }
        ;

mulop: T_VEZES    { $$ = newExpNode(OpK); $$->attr.op = T_VEZES; }
     | T_DIVIDIDO { $$ = newExpNode(OpK); $$->attr.op = T_DIVIDIDO; }
     ;

factor: T_LPAR expression T_RPAR { $$ = $2; }
      | var { $$ = $1; }
      | call { $$ = $1; }
      | NUM 
      { 
          $$ = newExpNode(ConstK);
          $$->attr.val = ((TreeNode*)$1)->attr.val; // Assumindo conversão correta no scanner
      }
      ;

call: ID T_LPAR args T_RPAR
      {
          $$ = newExpNode(CallK);
          $$->attr.name = copyString(((TreeNode*)$1)->attr.name);
          $$->child[0] = $3; // Argumentos
      }
      ;

args: arg_list { $$ = $1; }
    | /* empty */ { $$ = NULL; }
    ;

arg_list: arg_list T_VIRGULA expression
        {
             TreeNode * t = $1;
             if (t != NULL) {
                 while (t->sibling != NULL) t = t->sibling;
                 t->sibling = $3;
                 $$ = $1;
             } else $$ = $3;
        }
        | expression { $$ = $1; }
        ;

%%

void yyerror(const char* s) {
    fprintf(stderr, "ERRO SINTATICO: %s - LINHA: %d\n", s, num_linha);
}
