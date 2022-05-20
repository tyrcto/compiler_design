all: scanner.exe

scanner.exe: lex.yy.cc
	g++ -o scanner -O lex.yy.cc -ll
		
lex.yy.cc: scanner.l
	lex scanner.l
	mv lex.yy.c lex.yy.cc

clean:
	rm lex.yy.c lex.yy.cc scanner