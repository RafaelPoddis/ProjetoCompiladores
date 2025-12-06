%option noyywrap

%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>

    #define YY_DECL int yylex()

    #include "seman.tab.h"
%}

%%
[ \t\r]+           ;

[0-9]+\.[0-9]+     { yylval.val = make_real(atof(yytext));   return T_FLOAT; }
[0-9]+             { yylval.val = make_inteiro(atoi(yytext));return T_INT;   }

verdadeiro       { yylval.val = make_logico(1); return T_TRUE; }
falso            { yylval.val = make_logico(0); return T_FALSE; }

[a-zA-Z_][a-zA-Z0-9_]*  { yylval.id = strdup(yytext); return T_ID; }

"="                { return T_ATRIB; }
"+"                { return T_MAIS; }
"-"                { return T_MENOS; }
"*"                { return T_MULT; }
"/"                { return T_DIV; }
"("                { return T_APAR; }
")"                { return T_FPAR; }
"\n"               { return T_NEWLINE; }

.                  { fprintf(stderr, "Erro lexico! Caracter nao reconhecido: %s\n", yytext); }

%%
