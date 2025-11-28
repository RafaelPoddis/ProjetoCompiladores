//
// Esse código é de autoria de Rafael Poddis e Pedro Ernesto.
//
#include <stdio.h>

extern FILE *yyin;

int yyparse();

int main(int argc, char** argv) {
    if(argc > 1){
        yyin = fopen(argv[1], "r");
        if(yyin == NULL){
            fprintf(stderr, "Problema na leitura do arquivo!");
            return 1; // Erro de tipo 1
        }
    }
    else{
        yyin = fopen("src/entrada.txt", "r");        
        if(yyin == NULL){
            fprintf(stderr, "Problema na leitura do arquivo!");
            return 1; // Erro de tipo 1
        }
    }

    yyparse(); // chamada ao parser

    fclose(yyin);

    return 0;
}
