#ifndef AAS_H
#define AAS_H

/* Tipo de nó: operador ou valor */
typedef enum { TYPE_OP, TYPE_VAL } NodeType;

/* Estrutura da árvore sintática abstrata */
typedef struct AST {
    NodeType type;
    union {
        char oper;
        float value;
    } data;
    struct AST *left;
    struct AST *right;
} AST;

/* Funções de criação de nós */
AST* createOpNode(char op, AST* left, AST* right);
AST* createValNode(float val);

/* Funções de manipulação da árvore */
float evalAST(AST* node);
void freeAST(AST* node);

/* Funções de impressão bonita */
void printTree(AST* root);
int getHeight(AST* root);
void fillBuffer(AST* node, int level, int left, int right);

#endif /* AAS_H */