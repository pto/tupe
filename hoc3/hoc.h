typedef struct Symbol {
	char *name;
	short type;	// VAR, BLTIN, or UNDEF
	union {
		double val;			// if VAR
		double (*ptr)();	// if BLTIN
	} u;
	struct Symbol *next;
} Symbol;

Symbol *install(), *lookup();
