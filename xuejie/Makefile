# all:
# lex scanner.l
# cc -o scanner -O lex.yy.c -ll

CC ?= g++
WGD ?= -w
LEX ?= flex
BS ?= bison

myyacc: lex.yy.cc myyacc.tab.cc symbol.cpp symbol.hh
	$(CC) -o myyacc lex.yy.cc symbol.cpp symbol.hh -ll -ly

lex.yy.cc: scanner.l
	$(LEX) -o lex.yy.cc $<

myyacc.tab.cc myyacc.tab.h: myyacc.y
	$(BS) -y -o myyacc.tab.cc -d $<

test: myyacc
	./myyacc ./example.kt

.PHONY: clean build
clean:
	rm -f myyacc
	rm -f *.o
	rm -f lex.yy.cc
	rm -f myyacc.tab.[ch]

build: myyacc
