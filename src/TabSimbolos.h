#ifndef TABSIMBOLOS_H
#define TABSIMBOLOS_H

#include "AAS.h"

typedef struct Simbolo {
    char* name;
    VarType type;
    int ehArray;
    int tamanhoArray;
    int ehFuncao;
    int linha;
    struct Simbolo* prox;
} Simbolo;

typedef struct Tabela {
    Simbolo* cabeca;
    struct Tabela* pai;
} Tabela;

Tabela* criaTabela(Tabela* pai);
void liberaTabela(Tabela* table);
int insereSimbolo(Tabela* table, char* name, VarType type, int ehArray, int tamanhoArray, int ehFuncao, int linha);
Simbolo* procuraSimbolo(Tabela* table, char* name, int searchpai);
void verificaSemantica(AST* tree, Tabela* table);
void printTabela(Tabela* table, int level);

#endif