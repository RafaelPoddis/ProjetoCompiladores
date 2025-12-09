#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "AAS.h"

#define MAX_LINES 20
#define MAX_WIDTH 80
extern char canvas[MAX_LINES][MAX_WIDTH];

/* Cria nó de operando */
AST* createOpNode(char op, AST* left, AST* right) {
    AST* node = (AST*) malloc(sizeof(AST));
    node->type = TYPE_OP;
    node->data.oper = op;
    node->left = left;
    node->right = right;
    return node;
}

/* Cria nó de valor */
AST* createValNode(float val) {
    AST* node = (AST*) malloc(sizeof(AST));
    node->type = TYPE_VAL;
    node->data.value = val;
    node->left = NULL;
    node->right = NULL;
    return node;
}

/* Avalia a árvore */
/* Se nó for valor, retorna o valor */
/* Se for operador, realiza as operações recursivamente */
float evalAST(AST* node) {
    if (!node) return 0;
    if (node->type == TYPE_VAL) return node->data.value;
    
    float l = evalAST(node->left);
    float r = evalAST(node->right);
    
    switch (node->data.oper) {
        case '+': return l + r;
        case '-': return l - r;
        case '*': return l * r;
        case '/': return (r != 0) ? l / r : 0;
    }
    return 0;
}

/* Libera a memória ocupada pela árvore recursivamente */
void freeAST(AST* node) {
    if (!node) return;
    freeAST(node->left);
    freeAST(node->right);
    free(node);
}

/* --- LÓGICA DE IMPRESSÃO BONITA (PRETTY PRINT) --- */

// 1. Calcula a altura da árvore para saber quantas linhas precisamos
int getHeight(AST* root) {
    if (!root) return 0;
    int lh = getHeight(root->left);
    int rh = getHeight(root->right);
    return (lh > rh ? lh : rh) + 1;
}

// 2. Preenche a matriz (canvas) recursivamente
void fillBuffer(AST* node, int level, int left, int right) {
    if (!node || level >= MAX_LINES) return;

    int width = right - left;
    int mid = left + width / 2;

    // Converte o dado do nó para string
    char str[10];
    if (node->type == TYPE_OP) {
        sprintf(str, "(%c)", node->data.oper);
    } else {
        // Se for inteiro redondo, imprime sem casas decimais para economizar espaço
        if (node->data.value == (int)node->data.value)
            sprintf(str, "%.0f", node->data.value);
        else
            sprintf(str, "%.1f", node->data.value);
    }

    // Calcula onde começar a escrever para ficar centralizado na posição 'mid'
    int len = strlen(str);
    int start = mid - len / 2;
    
    // Proteção para não estourar o buffer lateral
    if (start < 0) start = 0;
    if (start + len >= MAX_WIDTH) start = MAX_WIDTH - len - 1;

    // Escreve o nó no canvas
    strncpy(&canvas[level * 2][start], str, len);

    // Desenha as "pernas" para os filhos na linha seguinte (level*2 + 1)
    if (node->left) {
        // Desenha o braço esquerdo '/'
        int childMid = left + (mid - left) / 2;
        // Ponto médio entre o pai e o filho
        int slashPos = (mid + childMid) / 2; 
        if (slashPos >= 0 && slashPos < MAX_WIDTH) 
             canvas[level * 2 + 1][slashPos] = '/';
             
        fillBuffer(node->left, level + 1, left, mid);
    }

    if (node->right) {
        // Desenha o braço direito '\'
        int childMid = mid + (right - mid) / 2;
        int backSlashPos = (mid + childMid) / 2;
        if (backSlashPos >= 0 && backSlashPos < MAX_WIDTH)
            canvas[level * 2 + 1][backSlashPos] = '\\';
            
        fillBuffer(node->right, level + 1, mid, right);
    }
}

// 3. Função Principal que limpa o canvas e imprime
void printTree(AST* root) {
    // Limpa o canvas com espaços
    for (int i = 0; i < MAX_LINES; i++) {
        for (int j = 0; j < MAX_WIDTH; j++) {
            canvas[i][j] = ' ';
        }
        canvas[i][MAX_WIDTH - 1] = '\0'; // Terminador de string
    }

    int h = getHeight(root);
    fillBuffer(root, 0, 0, MAX_WIDTH);

    // Imprime apenas as linhas usadas (altura * 2, pois usamos linhas intercaladas para conectores)
    for (int i = 0; i < h * 2; i++) {
        // Remove espaços em branco sobrando à direita para o terminal ficar limpo
        int j = MAX_WIDTH - 2;
        while (j > 0 && canvas[i][j] == ' ') j--;
        canvas[i][j+1] = '\0';
        
        printf("%s\n", canvas[i]);
    }
}