%{
#include <stdio.h>
#include "hoc.h"

#define code2(c1, c2)		code(c1); code(c2)
#define code3(c1, c2, c3)	code(c1); code(c2); code(c3)

int yylex(void);
void yyerror(char *s);
void init(void);
%}

%union {
	Symbol *sym;
	Inst   *inst;
}

%token <sym>	NUMBER VAR BLTIN UNDEF
%right '='
%left '+' '-'
%left '*' '/' '%'
%left UNARYMINUS UNARYPLUS
%right '^'

%%
list:	  /* nothing */
		| list eos
		| list asgn eos			{ code2((Inst)pop, STOP); return 1; }
		| list expr eos			{ code2(print, STOP); return 1; }
		| list error eos		{ yyerrok; }
		;

eos:	  '\n'
   		| ';'
		;

asgn:	  VAR '=' expr			{ code3(varpush, (Inst)$1, assign); }

expr:	  NUMBER				{ code2(constpush, (Inst)$1); }
		| VAR					{ code3(varpush, (Inst)$1, eval); }
		| asgn
		| BLTIN '(' expr ')'	{ code2(bltin, (Inst)$1->u.ptr); }
		| '-' expr  %prec UNARYMINUS	{ code(negate); }
		| '+' expr  %prec UNARYPLUS	
		| expr '+' expr			{ code(add); }
		| expr '-' expr			{ code(sub); }
		| expr '*' expr			{ code(mul); }
		| expr '/' expr			{ code(divide); }
		| expr '%' expr			{ code(mod); }
		| expr '^' expr			{ code(power); }
		| '(' expr ')'	
		;
%%

#include <ctype.h>
#include <signal.h>
#include <setjmp.h>

char *progname;
int  lineno = 1;
jmp_buf begin;

void fpecatch(int);

int main(int argc, char *argv[])
{
	progname = argv[0];
	init();
	setjmp(begin);
	signal(SIGFPE, fpecatch);
	for (initcode(); yyparse(); initcode())
		execute(prog);
	return 0;
}

int yylex(void)
{
	int c;

	while ((c = getchar()) == ' ' || c == '\t')
		;

	if (c == EOF)
		return 0;
	if (c == '.' || isdigit(c)) {
		double d;

		ungetc(c, stdin);
		scanf("%lf", &d);
		yylval.sym = install("", NUMBER, d);
		return NUMBER;
	}
	if (isalpha(c)) {
		Symbol *s;
		char sbuf[100], *p = sbuf;

		do {
			*p++ = c;
		} while ((c = getchar()) != EOF && isalnum(c));
		ungetc(c, stdin);
		*p = '\0';
		if ((s = lookup(sbuf)) == 0)
			s = install(sbuf, UNDEF, 0.0);
		yylval.sym = s;
		return s->type == UNDEF ? VAR : s->type;
	}
	if (c == '\n')
		lineno++;

	return c;
}

void warning(char *s, char *t)
{
	fprintf(stderr, "%s: %s", progname, s);
	if (t)
		fprintf(stderr, " %s", t);
	fprintf(stderr, " near line %d\n", lineno);
}

void yyerror(char *s)
{
	warning(s, (char *)0);
}

void execerror(char *s, char *t)
{
	warning(s, t);
	longjmp(begin, 0);
}

void fpecatch(int i)
{
	execerror("floating point exception", (char *)0);
}
