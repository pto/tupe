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
