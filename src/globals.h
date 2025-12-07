#ifndef _GLOBALS_H_
#define _GLOBALS_H_

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

/* Tipos de tokens */
extern int num_linha;

/* --- ESTRUTURA DA ÁRVORE (AST) --- */
/* Adaptado do livro Louden e do exemplo quad.y */

typedef enum { StmtK, ExpK } NodeKind;
typedef enum { IfK, WhileK, AssignK, ReturnK, CompoundK } StmtKind;
typedef enum { OpK, ConstK, IdK, TypeK, CallK, VarK } ExpKind; // VarK para acesso a vetores/vars
typedef enum { Void, Integer, Boolean } ExpType;

#define MAXCHILDREN 3

typedef struct treeNode {
    struct treeNode * child[MAXCHILDREN];
    struct treeNode * sibling; // Para listas de declarações ou statements
    int lineno;
    NodeKind nodekind;
    union { StmtKind stmt; ExpKind exp; } kind;
    union {
        int op;       // Para operadores (+, -, etc)
        int val;      // Para números
        char * name;  // Para IDs
    } attr;
    ExpType type; /* Para verificação de tipos */
} TreeNode;

/* Funções auxiliares para construção da árvore */
TreeNode * newStmtNode(StmtKind kind);
TreeNode * newExpNode(ExpKind kind);
char * copyString(char * s);

/* Flags para rastreamento */
extern int TraceScan;
extern int TraceParse;
extern int TraceCode;
extern TreeNode * savedTree;

#endif
