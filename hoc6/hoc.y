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
	int    narg;
}

%token <sym>	NUMBER STRING PRINT VAR BLTIN UNDEF WHILE IF ELSE
%token <sym>	FUNCTION PROCEDURE RETURN FUNC PROC READ
%token <narg>	ARG

%type <inst>	stmt asgn expr prlist stmtlist cond while if begin end
%type <sym>		procname
%type <narg>	arglist

%right '='
%left OR
%left AND
%left GT GE LT LE EQ NE
%left '+' '-'
%left '*' '/' '%'
%left UNARYMINUS UNARYPLUS NOT
%right '^'

%%
list:	  /* nothing */
		| list eos
		| list defn eos
		| list asgn eos			{ code2((Inst)pop_discard, STOP); return 1; }
		| list stmt eos			{ code(STOP); return 1; }
		| list expr eos			{ code2(print, STOP); return 1; }
		| list error eos		{ yyerrok; }
		;

eos:	  '\n'
   		| ';'
		;

asgn:	  VAR '=' expr			{ code3(varpush, (Inst)$1, assign); $$ = $3; }
		| ARG '=' expr			{
			defnonly("$"); code2(varpush, (Inst)$1, assign); $$ = $3; }
		;

stmt:	  expr					{ code((Inst)pop); }
		| RETURN				{ defnonly("return"); code(procret); }
		| RETURN expr			{
			defnonly("return"); $$ = $2; code(funcret); }
		| PROCEDURE begin '(' arglist ')' {
			$$ = $2; code3(call, (Inst)$1, (Inst)$4); }
		| PRINT prlist			{ $$ = $2; }
		| while cond stmt end	{
			($1)[1] = (Inst)$3;
			($1)[2] = (Inst)$4; }
		| if cond stmt end 		{
			($1)[1] = (Inst)$3;
			($1)[3] = (Inst)$4; }
		| if cond stmt end ELSE stmt end {
			($1)[1] = (Inst)$3;
			($1)[2] = (Inst)$6;
			($1)[3] = (Inst)$7; }
		| '{' stmtlist '}'		{ $$ = $2; }
		;

cond:	  '(' expr ')'			{ code(STOP); $$ = $2; }

while:	  WHILE					{ $$ = code3(whilecode, STOP, STOP); }
		;

if:		  IF					{ $$ = code(ifcode); code3(STOP, STOP, STOP); }
  		;

end:	  /* nothing */			{ code(STOP); $$ = progp; }
   		;

stmtlist: /* nothing */			{ $$ = progp; }
		| stmtlist eos
		| stmtlist stmt
		;

expr:	  NUMBER				{ $$ = code2(constpush, (Inst)$1); }
		| VAR					{ $$ = code3(varpush, (Inst)$1, eval); }
		| ARG					{ defnonly("$"); $$ = code2(arg, (Inst)$1); }
		| asgn
		| FUNCTION begin '(' arglist ')' {
			$$ = $2; code3(call, (Inst)$1, (Inst)$4); }
		| READ '(' VAR ')'		{ $$ = code2(varread, (Inst)$3); }
		| BLTIN '(' expr ')'	{ $$ = $3; code2(bltin, (Inst)$1); }
		| '-' expr  %prec UNARYMINUS	{ $$ = $2; code(negate); }
		| '+' expr  %prec UNARYPLUS		{ $$ = $2; }
		| expr '+' expr			{ code(add); }
		| expr '-' expr			{ code(sub); }
		| expr '*' expr			{ code(mul); }
		| expr '/' expr			{ code(divide); }
		| expr '%' expr			{ code(mod); }
		| expr '^' expr			{ code(power); }
		| '(' expr ')'			{ $$ = $2; }
		| expr GT expr			{ code(gt); }
		| expr GE expr			{ code(ge); }
		| expr LT expr			{ code(lt); }
		| expr LE expr			{ code(le); }
		| expr EQ expr			{ code(eq); }
		| expr NE expr			{ code(ne); }
		| expr AND expr			{ code(and); }
		| expr OR expr			{ code(or); }
		| NOT expr				{ $$ = $2; code(not); }
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
	int follow(int, int, int);

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
	switch (c) {
	case '>':	return follow('=', GE, GT);
	case '<':	return follow('=', LE, LT);
	case '=':	return follow('=', EQ, '=');
	case '!':	return follow('=', NE, NOT);
	case '|':   return follow('|', OR, '|');
	case '&':	return follow('&', AND, '&');
	case '\n':	lineno++; return '\n';
	default:	return c;
	}
}

int follow(int expect, int ifyes, int ifno)
{
	int c = getchar();

	if (c == expect)
		return ifyes;
	ungetc(c, stdin);
	return ifno;
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
