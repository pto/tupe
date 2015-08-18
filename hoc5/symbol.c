#include <stdlib.h>
#include <string.h>
#include "hoc.h"
#include "y.tab.h"

static Symbol *symlist = 0;

Symbol *lookup(char *symbol)
{
	Symbol *sp;

	for (sp = symlist; sp != (Symbol *)0; sp = sp->next)
		if (strcmp(sp->name, symbol) == 0)
			return sp;
	return 0;
}

Symbol *install(char *symbol, int type, double value)
{
	Symbol *sp;
	char *emalloc(size_t);

	sp = (Symbol *)emalloc(sizeof(Symbol));
	sp->name = emalloc(strlen(symbol) + 1);
	strcpy(sp->name, symbol);
	sp->type = type;
	sp->u.val = value;
	sp->next = symlist;
	symlist = sp;
	return sp;
}

char *emalloc(size_t n)
{
	char *p;

	p = malloc(n);
	if (p == 0)
		execerror("out of memory", (char *)0);
	return p;
}
