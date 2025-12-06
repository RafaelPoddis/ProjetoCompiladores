/* escopo.l */
%option noyywrap

%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>

    #define YY_DECL int yylex()

    #include "seman.tab.h"   /* nome gerado pelo bison */
%}

%%

[ \t\r]+           ;   /* ignora espaços, tabs e \r */

"int"              { return T_INT_KW; }
"print"            { return T_PRINT; }

[0-9]+             { yylval.ival = atoi(yytext); return T_NUM; }

"{"                { return T_LBRACE; }
"}"                { return T_RBRACE; }

"="                { return T_ATRIB; }
"+"                { return T_MAIS; }
"-"                { return T_MENOS; }
"*"                { return T_MULT; }
"/"                { return T_DIV; }
"("                { return T_APAR; }
")"                { return T_FPAR; }

[a-zA-Z_][a-zA-Z0-9_]*  { yylval.id = strdup(yytext); return T_ID; }

"\n"               { return T_NEWLINE; }

.                  { fprintf(stderr, "Erro lexico! Caracter nao reconhecido: %s\n", yytext); }

%%
