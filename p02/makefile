all: parser

parser: y.tab.cc lex.yy.cc symbols.cc symbols.hh
	g++ -o parser y.tab.cc lex.yy.cc symbols.cc -lfl -ly 

lex.yy.cc: scanner.l
	flex -o lex.yy.cc scanner.l

y.tab.cc: parser.y
	bison -y -o y.tab.cc -d parser.y

clean:
	rm parser lex.yy.cc y.tab.*
