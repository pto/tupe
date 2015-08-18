#include <stdio.h>
#include <math.h>
#include "hoc.h"
#include "y.tab.h"

#define NSTACK 256
static Datum stack[NSTACK];
static Datum *stackp;

#define NPROG 2000
Inst prog[NPROG];
Inst *progp;
Inst *pc;

void initcode(void)
{
	stackp = stack;
	progp = prog;
}

void push(Datum d)
{
	if (stackp >= &stack[NSTACK])
		execerror("stack overflow", (char *)0);
	*stackp++ = d;
}

Datum pop(void)
{
	if (stackp <= stack)
		execerror("stack underflow", (char  *)0);
	return *--stackp;
}

void pop_discard(void)
{
	if (stackp <= stack)
		execerror("stack underflow", (char  *)0);
	--stackp;
}

Inst *code(Inst f)
{
	Inst *oprogp = progp;
	if (progp >= &prog[NPROG])
		execerror("program too big", (char *)0);
	*progp++ = f;
	return oprogp;
}

void execute(Inst *p)
{
	char *display(Inst *);

	for (pc = p; *pc != STOP; ) {
		printf("TRACE: %s\n", display(pc));
		(*(*pc++))();
	}
}

void constpush()
{
	Datum d;

	d.val = ((Symbol *)*pc++)->u.val;
	push(d);
}

void varpush()
{
	Datum d;

	d.sym = (Symbol *)(*pc++);
	push(d);
}

void add(void)
{
	Datum d1, d2;

	d2 = pop();
	d1 = pop();
	d1.val += d2.val;
	push(d1);
}

void sub(void)
{
	Datum d1, d2;

	d2 = pop();
	d1 = pop();
	d1.val -= d2.val;
	push(d1);
}

void mul(void)
{
	Datum d1, d2;

	d2 = pop();
	d1 = pop();
	d1.val *= d2.val;
	push(d1);
}

void divide(void)
{
	Datum d1, d2;

	d2 = pop();
	d1 = pop();
	if (d2.val == 0)
		execerror("divide by zero", (char *)0);
	d1.val /= d2.val;
	push(d1);
}

void mod(void)
{
	Datum d1, d2;

	d2 = pop();
	d1 = pop();
	d1.val = fmod(d1.val, d2.val);
	push(d1);
}

void power(void)
{
	Datum d1, d2;

	d2 = pop();
	d1 = pop();
	d1.val = Pow(d1.val, d2.val);
	push(d1);
}

void negate(void)
{
	Datum d1;

	d1 = pop();
	d1.val = -d1.val;
	push(d1);
}

void eval(void)
{
	Datum d;

	d = pop();
	if (d.sym->type == UNDEF)
		execerror("undefined variable", d.sym->name);
	d.val = d.sym->u.val;
	push(d);
}

void assign(void)
{
	Datum d1, d2;

	d1 = pop();
	d2 = pop();
	if (d1.sym->type != VAR && d1.sym->type != UNDEF)
		execerror("assignment to non-variable", d1.sym->name);
	d1.sym->u.val = d2.val;
	d1.sym->type = VAR;
    push(d2);
}

void print(void)
{
	Datum d;

	d = pop();
	printf("\t%.8g\n", d.val);
}

void bltin(void)
{
	Datum d;
	Symbol *s;

	d = pop();
	s = (Symbol *)(*pc++);
	d.val =(*((double (*)())s->u.ptr))(d.val);
	push(d);
}

char buffer[BUFSIZ];

char *display(Inst *pc)
{
	Symbol *ps;

	ps = *((Symbol **)(pc + 1));

	if (*pc == add) { return "add"; }
   	else if (*pc == sub) { return "sub"; }	
	else if (*pc == mul) { return "mul"; }
	else if (*pc == divide) { return "div"; }
	else if (*pc == mod) { return "mod"; }
	else if (*pc == constpush) { 
		snprintf(buffer, BUFSIZ, "constpush %g", ps->u.val);
		return buffer;
   	} else if (*pc == varpush) {
	   	snprintf(buffer, BUFSIZ, "varpush %s", ps->name);
		return buffer;
   	}
	else if (*pc == bltin) {
	   	snprintf(buffer, BUFSIZ, "bltin %s", ps->name);
		return buffer;
   	}
	else if (*pc == power) { return "power"; }
	else if (*pc == negate) { return "negate"; }
	else if (*pc == assign) { return "assign"; }
	else if (*pc == (Inst)pop) { return "pop"; }
	else if (*pc == pop_discard) { return "pop_discard"; }
	else if (*pc == eval) { return "eval"; }
	else if (*pc == print) { return "print"; }
	else return "unknown opcode";
}
