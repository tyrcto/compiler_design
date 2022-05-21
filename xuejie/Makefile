all: myyacc

myyacc: y.tab.cc lex.yy.cc symbol.cpp symbol.h
	g++ -o myyacc y.tab.cc lex.yy.cpp symbol.cpp -lfl -ly 

lex.yy.cc: scanner.l
	flex -o lex.yy.cc scanner.l

y.tab.cc: myyacc.y
	bison -y -o y.tab.cc -d myyacc.y

clean:
	rm myyacc lex.yy.cc y.tab.*
