/* seman1.y */

%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>

    extern int yylex(void);
    extern int yyparse(void);
    extern FILE *yyin;

    void yyerror(const char *s);
%}

/* ------------------------------------------------------------------
   Tudo aqui dentro vai para o .tab.h ANTES do union YYSTYPE.
   ------------------------------------------------------------------ */
%code requires {

    /* ---- TIPOS ---- */
    typedef enum {
        TIPO_INTEIRO,
        TIPO_REAL,
        TIPO_LOGICO
    } Tipo;

    typedef struct {
        Tipo tipo;
        union {
            int   ival;
            float fval;
            int   bval;   /* 0 ou 1 para lógico */
        } u;
    } Valor;

    /* Forward decl de Var para usar em protótipos */
    typedef struct Var Var;

    /* Protótipos que serão usados no .y e no .l */
    Valor make_inteiro(int x);
    Valor make_real(float x);
    Valor make_logico(int b);

    Valor valor_var(const char *nome);
    void  define_var_val(const char *nome, Valor v);
    void  imprime_valor(Valor v);

    Valor op_soma(Valor a, Valor b);
    Valor op_sub(Valor a, Valor b);
    Valor op_mult(Valor a, Valor b);
    Valor op_div(Valor a, Valor b);
    Valor op_unario_menos(Valor a);
}

/* ------------------------------------------------------------------
   YYSTYPE
   ------------------------------------------------------------------ */
%union {
    Valor val;   /* usado em exp/termo/fator e literais */
    char *id;    /* usado em T_ID */
}

/* ---- TOKENS COM VALOR ---- */
%token<val> T_INT
%token<val> T_FLOAT
%token<val> T_TRUE
%token<val> T_FALSE
%token<id>  T_ID

/* ---- TOKENS SIMPLES ---- */
%token T_MAIS
%token T_MENOS
%token T_MULT
%token T_DIV
%token T_ATRIB

%token T_APAR
%token T_FPAR

%token T_NEWLINE

/* precedência aritmética */
%left T_MAIS T_MENOS
%left T_MULT T_DIV

/* tipos dos não-terminais */
%type<val> exp
%type<val> termo
%type<val> fator

%start calculo

%%  /* ====================== REGRAS ====================== */

calculo :
        /* vazio */
      | calculo line
      ;

line :
        exp T_NEWLINE
            {
                printf("Resultado: ");
                imprime_valor($1);
            }
      | T_ID T_ATRIB exp T_NEWLINE
            {
                define_var_val($1, $3);  /* inferência do tipo na atribuição */
                printf("%s = ", $1);
                imprime_valor($3);
                free($1);
            }
      | T_NEWLINE
      ;

/* + e - binários com inferência de tipo */
exp :
        exp T_MAIS  termo  { $$ = op_soma($1, $3); }
      | exp T_MENOS termo  { $$ = op_sub($1, $3);  }
      | termo               { $$ = $1;             }
      ;

/* * e / binários com inferência de tipo */
termo :
        termo T_MULT fator  { $$ = op_mult($1, $3); }
      | termo T_DIV  fator  { $$ = op_div($1, $3);  }
      | fator               { $$ = $1;              }
      ;

/* fator com - unário, literais, lógicos e IDs */
fator :
        T_MENOS fator       { $$ = op_unario_menos($2); }
      | T_APAR exp T_FPAR   { $$ = $2;                  }
      | T_INT               { $$ = $1;                  }
      | T_FLOAT             { $$ = $1;                  }
      | T_TRUE              { $$ = $1;                  }
      | T_FALSE             { $$ = $1;                  }
      | T_ID                { $$ = valor_var($1); free($1); }
      ;

%%  /* ====================== C CÓDIGO ====================== */

/* ---- IMPLENTAÇÃO DOS TIPOS ---- */

Valor make_inteiro(int x) {
    Valor v;
    v.tipo = TIPO_INTEIRO;
    v.u.ival = x;
    return v;
}

Valor make_real(float x) {
    Valor v;
    v.tipo = TIPO_REAL;
    v.u.fval = x;
    return v;
}

Valor make_logico(int b) {
    Valor v;
    v.tipo = TIPO_LOGICO;
    v.u.bval = (b != 0);
    return v;
}

void imprime_valor(Valor v) {
    switch (v.tipo) {
        case TIPO_INTEIRO:
            printf("%d\n", v.u.ival);
            break;
        case TIPO_REAL:
            printf("%f\n", v.u.fval);
            break;
        case TIPO_LOGICO:
            printf("%s\n", v.u.bval ? "verdadeiro" : "falso");
            break;
    }
}

/* ---- TABELA DE SÍMBOLOS: nome -> Valor (tipo + valor) ---- */

struct Var {
    char *nome;
    Valor val;
    struct Var *prox;
};

Var *tabela = NULL;

Var *busca_var(const char *nome) {
    Var *p = tabela;
    while (p != NULL) {
        if (strcmp(p->nome, nome) == 0)
            return p;
        p = p->prox;
    }
    return NULL;
}

/* define/atualiza variavel com tipo inferido do Valor */
void define_var_val(const char *nome, Valor v) {
    Var *var = busca_var(nome);
    if (var == NULL) {
        var = (Var*) malloc(sizeof(Var));
        var->nome = strdup(nome);
        var->val  = v;  /* tipo e valor inferidos da expressão */
        var->prox = tabela;
        tabela    = var;
    } else {
        /* já existe: checagem de tipo (sem coerção por enquanto) */
        if (var->val.tipo != v.tipo) {
            fprintf(stderr,
                    "Erro semantico: atribuicao de tipo incompativel para '%s'.\n",
                    nome);
            /* didaticamente podemos sobrescrever mesmo assim */
        }
        var->val = v;
    }
}

Valor valor_var(const char *nome) {
    Var *var = busca_var(nome);
    if (var == NULL) {
        fprintf(stderr,
                "Variavel '%s' nao declarada. Assumindo 0 (inteiro).\n",
                nome);
        return make_inteiro(0);
    }
    return var->val;
}

/* ---- OPERACOES SEMÂNTICAS ---- */

static void erro_tipo(const char *op) {
    fprintf(stderr, "Erro semantico: tipos incompativeis em '%s'.\n", op);
}

Valor op_soma(Valor a, Valor b) {
    if (a.tipo == TIPO_LOGICO || b.tipo == TIPO_LOGICO) {
        erro_tipo("+");
        return make_inteiro(0);
    }
    if (a.tipo == TIPO_REAL || b.tipo == TIPO_REAL) {
        float va = (a.tipo == TIPO_REAL) ? a.u.fval : (float)a.u.ival;
        float vb = (b.tipo == TIPO_REAL) ? b.u.fval : (float)b.u.ival;
        return make_real(va + vb);
    } else { /* ambos inteiros */
        return make_inteiro(a.u.ival + b.u.ival);
    }
}

Valor op_sub(Valor a, Valor b) {
    if (a.tipo == TIPO_LOGICO || b.tipo == TIPO_LOGICO) {
        erro_tipo("-");
        return make_inteiro(0);
    }
    if (a.tipo == TIPO_REAL || b.tipo == TIPO_REAL) {
        float va = (a.tipo == TIPO_REAL) ? a.u.fval : (float)a.u.ival;
        float vb = (b.tipo == TIPO_REAL) ? b.u.fval : (float)b.u.ival;
        return make_real(va - vb);
    } else {
        return make_inteiro(a.u.ival - b.u.ival);
    }
}

Valor op_mult(Valor a, Valor b) {
    if (a.tipo == TIPO_LOGICO || b.tipo == TIPO_LOGICO) {
        erro_tipo("*");
        return make_inteiro(0);
    }
    if (a.tipo == TIPO_REAL || b.tipo == TIPO_REAL) {
        float va = (a.tipo == TIPO_REAL) ? a.u.fval : (float)a.u.ival;
        float vb = (b.tipo == TIPO_REAL) ? b.u.fval : (float)b.u.ival;
        return make_real(va * vb);
    } else {
        return make_inteiro(a.u.ival * b.u.ival);
    }
}

Valor op_div(Valor a, Valor b) {
    if (a.tipo == TIPO_LOGICO || b.tipo == TIPO_LOGICO) {
        erro_tipo("/");
        return make_real(0.0f);
    }
    float va = (a.tipo == TIPO_REAL) ? a.u.fval : (float)a.u.ival;
    float vb = (b.tipo == TIPO_REAL) ? b.u.fval : (float)b.u.ival;

    if (vb == 0.0f) {
        fprintf(stderr, "Divisao por 0 nao esta definida!\n");
        yyerror("Divisao por 0 nao esta definida!");
        return make_real(0.0f);
    }
    return make_real(va / vb);
}

Valor op_unario_menos(Valor a) {
    if (a.tipo == TIPO_LOGICO) {
        fprintf(stderr, "Erro semantico: - unario em logico.\n");
        return make_inteiro(0);
    }
    if (a.tipo == TIPO_REAL) {
        return make_real(-a.u.fval);
    } else {
        return make_inteiro(-a.u.ival);
    }
}

/* ---- MAIN E ERRO ---- */

int main(int argc, char **argv) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            fprintf(stderr, "Nao consegui abrir arquivo '%s'\n", argv[1]);
            return 1;
        }
    } else {
        yyin = stdin;
    }

    yyparse();
    return 0;
}

void yyerror(const char *s) {
    fprintf(stderr, "Erro sintatico/semantico: %s\n", s);
}
