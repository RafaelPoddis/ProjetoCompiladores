#ifndef AAS_H
#define AAS_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#define LE_OP 1  
#define GE_OP 2  
#define EQ_OP 3  
#define NE_OP 4  

typedef enum {TYPE_STMT, TYPE_EXP } NodeType;
typedef enum {IfK, WhileK, AssignK, ReturnK, VarDecK, FunDecK, CallK, CompoundK } StmtType;
typedef enum {OpK, ConstK, IdK } ExpType;
typedef enum {Void, Integer, Boolean } VarType;

typedef struct AST {
    struct AST* filho[3]; 
    struct AST* irmao; 
    
    NodeType type;        
    int linha;            

    union {
        StmtType stmt;
        ExpType exp;
    } kind;

    char* name;   
    union {
        int oper;
        int val; 
    } attr;
    
    VarType varType; 

} AST;


AST* newStmtNode(StmtType kind);
AST* newExpNode(ExpType kind);
AST* createOpNode(int op, AST* left, AST* right);
AST* createValNode(float val);
AST* createIdNode(char* name);

void freeAST(AST* node);
void printTree(AST* root);

#endif /* AAS_H */