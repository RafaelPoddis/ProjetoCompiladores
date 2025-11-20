/* -------------------------------------------- */
/* ----- Todo código abaixo está de acordo ---- */
/*com o Apendice A do livro do Kenneth C. Louden*/
/* -------------------------------------------- */
%option noyywrap

%{
    #include <stdio.h>
    #include <stdlib.h>
    #include "parser.tab.h"

    #define YY_DECL int yylex() // Define como a função yylex deve ser declarada

    int num_linha = 1; // Contador de linhas para mensagens de erro

    // Função para imprimir erros léxicos
    void erro_lexico(const char *lexema) {
        fprintf(stderr, "ERRO LEXICO: \"%s\" - LINHA: %d\n", lexema, num_linha);
    }
    
%}

/* ---------------------------------------- */
/* ---- Definicao dos tokens ID e NUM ----- */
/* ---------------------------------------- */
DIGITO      [0-9]
LETRA       [a-zA-Z]
ID          {LETRA}+
NUM         {DIGITO}+

%%
[ \t\r] ; // ignorar espaços em branco
\n     { num_linha++;} // Conta linhas

/* ---------------------------------------- */
/* ------------ Palavras Chave ------------ */
/* ---------------------------------------- */
"if"        { return T_IF; }
"else"      { return T_ELSE; }
"while"     { return T_WHILE; }
"return"    { return T_RETURN; }
"int"       { return T_INT; }
"void"      { return T_VOID; }
"input"     { return T_INPUT; }
"output"    { return T_OUTPUT; }

/* ---------------------------------------- */
/* ---------- Simbolos Especiais ---------- */
/* ---------------------------------------- */
"+"     {return T_MAIS;}
"-"     {return T_MENOS;}
"*"     {return T_VEZES;}
"/"     {return T_DIVIDIDO;}
"<"     {return T_MENOR;}
"<="    {return T_MENOR_IGUAL;}
">"     {return T_MAIOR;}
">="    {return T_MAIOR_IGUAL;}
"=="    {return T_IGUALDADE;}
"!="    {return T_DIFERENTE;}
"="     {return T_RECEBE;}
";"     {return T_PONTO_VIRGULA;}
","     {return T_VIRGULA;}
"("     {return T_LPAR;}
")"     {return T_RPAR;}
"["     {return T_LCOLCHETE;}
"]"     {return T_RCOLCHETE;}
"{"     {return T_LCHAVE;}"
"}"     {return T_RCHAVE;}
"/*"    {return T_COMENTARIO_INICIO;}
"*/"    {return T_COMENTARIO_FIM;}

/* ---------------------------------------- */
/* ----------- Tokens ID e NUM ------------ */
/* ---------------------------------------- */
{ID}    { yylval.sval = strdup(yytext); return T_ID; }
{NUM}   { yylval.ival = atoi(yytext); return T_NUM; }

/* ---------------------------------------- */
/* ------------- Erro Léxico -------------- */
/* ---------------------------------------- */
. {
    erro_lexico(yytext);
    exit(1);
}
%%