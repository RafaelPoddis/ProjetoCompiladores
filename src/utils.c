#include "globals.h"

TreeNode * newStmtNode(StmtKind kind) {
    TreeNode * t = (TreeNode *) malloc(sizeof(TreeNode));
    int i;
    if (t==NULL) fprintf(stderr,"Erro de memória na linha %d\n",num_linha);
    else {
        for (i=0;i<MAXCHILDREN;i++) t->child[i] = NULL;
        t->sibling = NULL;
        t->nodekind = StmtK;
        t->kind.stmt = kind;
        t->lineno = num_linha;
    }
    return t;
}

TreeNode * newExpNode(ExpKind kind) {
    TreeNode * t = (TreeNode *) malloc(sizeof(TreeNode));
    int i;
    if (t==NULL) fprintf(stderr,"Erro de memória na linha %d\n",num_linha);
    else {
        for (i=0;i<MAXCHILDREN;i++) t->child[i] = NULL;
        t->sibling = NULL;
        t->nodekind = ExpK;
        t->kind.exp = kind;
        t->lineno = num_linha;
        t->type = Void;
    }
    return t;
}

char * copyString(char * s) {
    int n;
    char * t;
    if (s==NULL) return NULL;
    n = strlen(s)+1;
    t = malloc(n);
    if (t==NULL) fprintf(stderr,"Erro de memória na linha %d\n",num_linha);
    else strcpy(t,s);
    return t;
}
