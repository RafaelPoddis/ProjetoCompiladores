#include "globals.h"

/* Lista de quádruplas */
typedef struct {
    char *op;
    char *arg1;
    char *arg2;
    char *res;
} Quad;

Quad quads[1000];
int quad_count = 0;
int temp_count = 0;
int label_count = 0;

/* Gera novo temporário: $t1, $t2... */
char * newTemp() {
    char *t = (char *) malloc(10);
    sprintf(t, "$t%d", temp_count++);
    return t;
}

/* Gera novo label: L1, L2... */
char * newLabel() {
    char *l = (char *) malloc(10);
    sprintf(l, "L%d", label_count++);
    return l;
}

/* Emite quádrupla */
void emit(char * op, char * a1, char * a2, char * res) {
    quads[quad_count].op = op;
    quads[quad_count].arg1 = a1;
    quads[quad_count].arg2 = a2;
    quads[quad_count].res = res;
    quad_count++;
}

/* Função recursiva principal para gerar código */
char * cgen(TreeNode * tree) {
    char * p1, * p2, * t;
    char * l1, * l2;
    
    if (tree == NULL) return NULL;

    switch (tree->nodekind) {
        case StmtK:
            switch (tree->kind.stmt) {
                case IfK:
                    p1 = cgen(tree->child[0]); // Condição
                    l1 = newLabel(); // Else ou Fim
                    l2 = newLabel(); // Fim (se tiver else)
                    emit("IFF", p1, l1, "-"); // Se falso, vai para L1 [cite: 323]
                    cgen(tree->child[1]); // Bloco Then
                    if (tree->child[2] != NULL) { // Tem Else
                        emit("GOTO", l2, "-", "-");
                        emit("LAB", l1, "-", "-");
                        cgen(tree->child[2]); // Bloco Else
                        emit("LAB", l2, "-", "-");
                    } else {
                        emit("LAB", l1, "-", "-");
                    }
                    break;
                
                case AssignK:
                    p1 = cgen(tree->child[1]); // Expressão (lado direito) [cite: 254]
                    // Assumindo que child[0] é o ID
                    emit("ASSIGN", p1, "-", tree->child[0]->attr.name);
                    break;
                
                // Implementar WhileK, ReturnK, CompoundK...
                default:
                    break;
            }
            break;

        case ExpK:
            switch (tree->kind.exp) {
                case OpK:
                    p1 = cgen(tree->child[0]);
                    p2 = cgen(tree->child[1]);
                    t = newTemp();
                    /* Mapear token do operador para string */
                    char opStr[5]; 
                    if (tree->attr.op == T_MAIS) strcpy(opStr, "ADD");
                    else if (tree->attr.op == T_MENOS) strcpy(opStr, "SUB");
                    // ... outros operadores
                    
                    emit(opStr, p1, p2, t);
                    return t;
                
                case ConstK:
                    t = newTemp();
                    char valStr[20];
                    sprintf(valStr, "%d", tree->attr.val);
                    emit("LOAD", valStr, "-", t); // Carrega imediato
                    return t;

                case IdK:
                    return tree->attr.name; // Retorna o nome da variável
                
                default:
                    break;
            }
            break;
    }
    /* Processa irmãos (lista de comandos) */
    cgen(tree->sibling);
    return NULL;
}

void printQuads() {
    int i;
    printf("\nCodigo Intermediario (Quadruplas):\n");
    printf("----------------------------------\n");
    for (i = 0; i < quad_count; i++) {
        printf("(%s, %s, %s, %s)\n",
            quads[i].op,
            quads[i].arg1,
            quads[i].arg2,
            quads[i].res);
    }
    printf("----------------------------------\n");
}
