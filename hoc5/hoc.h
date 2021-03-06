void execerror(char* s, char* t);

typedef struct Symbol {
	char *name;
	short type;	// VAR, BLTIN, or UNDEF
	union {
		double val;			// if VAR
		double (*ptr)();	// if BLTIN
	} u;
	struct Symbol *next;
} Symbol;

Symbol *install(char *symbol, int type, double value);
Symbol *lookup(char *symbol);

typedef union Datum {
	double val;
	Symbol *sym;
} Datum;

Datum pop(void);
void pop_discard(void);

typedef void (*Inst)();
#define STOP (Inst)0

extern Inst prog[];
extern Inst *progp;
extern Inst *pc;

void eval(void), add(void), sub(void), mul(void), divide(void);
void mod(void), negate(void), power(void);
void assign(void), bltin(void), varpush(void), constpush(void), print(void);
double Pow(double, double);
void prexpr(void);
void gt(void), lt(void), eq(void), ge(void), le(void), ne(void);
void and(void), or(void), not(void), ifcode(void), whilecode(void);

Inst *code(Inst);
void initcode(void);
void execute(Inst *);
void prexpr(void);
