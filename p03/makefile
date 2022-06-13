CXX = g++
CXXFLAGS = -lfl -ly

ext_cc 		:= codegenerator.cc symbols.cc
ext_header 	:= codegenerator.hh symbols.hh

all: compiler

compiler: y.tab.cc lex.yy.cc $(ext_cc) $(ext_header)
	$(CXX) -o $@ y.tab.cc lex.yy.cc $(ext_cc) $(CXXFLAGS) 

lex.yy.cc: scanner.l
	flex -o $@ $?

y.tab.cc: parser.y
	bison -y -o $@ -d $?

clean:
	rm compiler parser lex.yy.cc y.tab.*