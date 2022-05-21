# all:
# lex scanner.l
# cc -o scanner -O lex.yy.c -ll

CC ?= g++
WGD ?= -w
LEX ?= flex
BS ?= bison

myyacc: lex.yy.o myyacc.o
	$(CC) -o $@ $^ $(WGD)

lex.yy.c: scanner.l
	$(LEX) -o lex.yy.cc $<

myyacc.tab.c myyacc.tab.h: myyacc.y
	$(BS) -d $<

lex.yy.o: lex.yy.cc myyacc.tab.h
	$(CC) -c $< -o $@ $(WGD)

myyacc.o: myyacc.tab.cc myyacc.tab.h
	$(CC) -c $< -o $@ $(WGD)

test: myyacc
	./myyacc ./example.kt

.PHONY: clean build
clean:
	rm -f myyacc
	rm -f *.o
	rm -f lex.yy.cc
	rm -f myyacc.tab.[ch]

build: myyacc