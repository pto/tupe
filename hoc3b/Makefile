YFLAGS = -d
OBJS = hoc.o init.o lex.o math.o symbol.o

hoc:	$(OBJS)
		cc $(OBJS) -lm -o hoc

hoc.o math.o:	hoc.h

init.o lex.o symbol.o:	hoc.h y.tab.h

clean:
		rm -f $(OBJS) y.tab.h
