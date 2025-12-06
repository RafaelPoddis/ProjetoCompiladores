%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>

    extern int yylex(void);
    extern int yyparse(void);
    extern FILE *yyin;

    void yyerror(const char *s);

    /* ================== TABELA DE SÍMBOLOS COM ESCOPO ================== */

    typedef struct Var {
        char *nome;
        int   valor;
        struct Var *prox;
    } Var;

    typedef struct Escopo {
        Var *vars;             /* lista encadeada de variáveis deste escopo */
        struct Escopo *prox;   /* escopo imediatamente externo */
    } Escopo;

    Escopo *topo_escopo = NULL;

    void enter_scope() {
        Escopo *e = (Escopo*) malloc(sizeof(Escopo));
        e->vars = NULL;
        e->prox = topo_escopo;
        topo_escopo = e;
        /* printf(">> Entrou em novo escopo\n"); */
    }

    void leave_scope() {
        if (topo_escopo == NULL) return;

        /* libera as variáveis deste escopo */
        Var *v = topo_escopo->vars;
        while (v) {
            Var *tmp = v;
            v = v->prox;
            free(tmp->nome);
            free(tmp);
        }
        Escopo *tmpE = topo_escopo;
        topo_escopo = topo_escopo->prox;
        free(tmpE);
        /* printf("<< Saiu de escopo\n"); */
    }

    /* procura variável apenas no escopo atual (para checar redeclaração) */
    Var* find_var_current(const char *nome) {
        if (!topo_escopo) return NULL;
        Var *v = topo_escopo->vars;
        while (v) {
            if (strcmp(v->nome, nome) == 0) return v;
            v = v->prox;
        }
        return NULL;
    }

    /* procura variável em todos os escopos, de dentro pra fora */
    Var* find_var(const char *nome) {
        Escopo *e = topo_escopo;
        while (e) {
            Var *v = e->vars;
            while (v) {
                if (strcmp(v->nome, nome) == 0) return v;
                v = v->prox;
            }
            e = e->prox;
        }
        return NULL;
    }

    /* declaração: cria variável no escopo atual */
    void declare_var(const char *nome) {
        if (!topo_escopo) {
            fprintf(stderr, "Erro interno: nenhum escopo ativo ao declarar '%s'.\n", nome);
            return;
        }
        if (find_var_current(nome) != NULL) {
            fprintf(stderr, "Erro semantico: variavel '%s' ja declarada neste escopo.\n", nome);
            return;
        }
        Var *v = (Var*) malloc(sizeof(Var));
        v->nome = strdup(nome);
        v->valor = 0;  /* valor inicial */
        v->prox = topo_escopo->vars;
        topo_escopo->vars = v;
        /* printf("Declarada %s no escopo atual\n", nome); */
    }

    /* atribuição: procura em qualquer escopo; se não existir, erro */
    void set_var(const char *nome, int valor) {
        Var *v = find_var(nome);
        if (!v) {
            fprintf(stderr, "Erro semantico: variavel '%s' nao declarada.\n", nome);
            return;
        }
        v->valor = valor;
    }

    int get_var(const char *nome) {
        Var *v = find_var(nome);
        if (!v) {
            fprintf(stderr, "Erro semantico: variavel '%s' nao declarada. Assumindo 0.\n", nome);
            return 0;
        }
        return v->valor;
    }

%}

%union {
    int ival;
    char *id;
}

/* TOKENS */
%token T_INT_KW     /* "int" */
%token T_PRINT      /* "print" */

%token<id>  T_ID
%token<ival> T_NUM

%token T_MAIS
%token T_MENOS
%token T_MULT
%token T_DIV
%token T_ATRIB   /* '=' */

%token T_LBRACE  /* '{' */
%token T_RBRACE  /* '}' */
%token T_APAR  /* '(' */
%token T_FPAR  /* ')' */

%token T_NEWLINE

%left T_MAIS T_MENOS
%left T_MULT T_DIV

%type<ival> exp
%type<ival> termo
%type<ival> fator

%start program

%%  /* ====================== REGRAS ====================== */

program :
        /* vazio */
      | program line
      ;

line :
        stmt T_NEWLINE
      | T_NEWLINE
      ;

stmt :
        decl
      | atrib
      | imprime
      | bloco
      ;

/* declaração: int x */
decl :
        T_INT_KW T_ID
            {
                declare_var($2);
                /* opcional: printf("Declaracao de %s\n", $2); */
                free($2);
            }
      ;

/* atribuição: x = exp */
atrib :
        T_ID T_ATRIB exp
            {
                set_var($1, $3);
                free($1);
            }
      ;

/* print exp */
imprime :
        T_PRINT exp
            {
                printf("PRINT: %d\n", $2);
            }
      ;

/* bloco: { <linhas> } com novo escopo */
bloco :
        T_LBRACE
            { enter_scope(); }
        bloco_conteudo
        T_RBRACE
            { leave_scope(); }
      ;

bloco_conteudo :
        /* vazio (bloco vazio) */
      | bloco_conteudo line
      ;

/* EXPRESSÕES ARITMÉTICAS */

exp :
        exp T_MAIS  termo   { $$ = $1 + $3; }
      | exp T_MENOS termo   { $$ = $1 - $3; }
      | termo               { $$ = $1;      }
      ;

termo :
        termo T_MULT fator  { $$ = $1 * $3; }
      | termo T_DIV  fator  {
                if ($3 == 0) {
                    fprintf(stderr, "Erro semantico: divisao por 0.\n");
                    $$ = 0;
                } else {
                    $$ = $1 / $3;
                }
            }
      | fator
      ;

fator :
        T_MENOS fator       { $$ = -$2; }
      | T_APAR exp T_FPAR   { $$ = $2;  }
      | T_NUM               { $$ = $1;  }
      | T_ID                { $$ = get_var($1); free($1); }
      ;

%%  /* ====================== C CÓDIGO ====================== */

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

    /* cria escopo global */
    enter_scope();

    yyparse();

    /* sai do escopo global e libera memória */
    leave_scope();

    return 0;
}

void yyerror(const char *s) {
    fprintf(stderr, "Erro sintatico: %s\n", s);
}
