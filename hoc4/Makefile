YFLAGS = -d
OBJS = hoc.o code.o init.o math.o symbol.o

hoc:	$(OBJS)
		cc $(OBJS) -lm -o hoc

code.o hoc.o math.o:	hoc.h

code.o init.o symbol.o:	y.tab.h

x.tab.h: y.tab.h
	-cmp -s x.tab.h y.tab.h || cp y.tab.h x.tab.h

clean:
		rm -f $(OBJS) [xy].tab.h
