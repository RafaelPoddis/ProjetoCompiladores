%option noyywrap

%{
#include <stdio.h>
#include <stdlib.h>
#include "aas.tab.h" // Certifique-se que o nome bate com o output do bison -d
%}

%%
[ \t] ; // ignorar espaços
[0-9]+\.[0-9]+ { yylval.fval = atof(yytext); return T_FLOAT; }
[0-9]+         { yylval.ival = atoi(yytext); return T_INT; }
"("            { return T_LPAR; }
")"            { return T_RPAR; }
"+"            { return T_MAIS; }
"-"            { return T_MENOS; }
"*"            { return T_MULT; }
"/"            { return T_DIV; }
"\n"           { return T_NEWLINE; }
.              { printf("Caractere invalido: %s\n", yytext); }
%%