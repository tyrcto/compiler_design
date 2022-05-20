if "make" fails, run:
	lex scanner.l
	mv lex.yy.c lex.yy.cc	
	g++ -o scanner -O lex.yy.cc -ll

*Note: code is written in C++ which requires a .cc file, hence the 2nd command