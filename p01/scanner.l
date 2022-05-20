%{
    #include <stdio.h>
    #include <map>
    #include <string>
    #define MAX_LINE_LENG 256
    #define LIST strcat(buf,yytext)
    #define token(t) {LIST; printf("<%s>\n",t);}
    #define tokenOper(t) {LIST; printf("<'%s'>\n", t);}
    #define tokenInteger(t,i) {LIST; printf("<%s: %d>\n",#t,atoi(i));}
    #define tokenString(t,s) {LIST; printf("<%s: %s>\n",#t,s);}
    int linenum = 0;
    char buf[MAX_LINE_LENG];

    using std::map;
    using std::string;
    using std::pair;

    class SymbolTable{
        private:
            int entryCount = 1;
            map<string, int> sTable;
        public:
            SymbolTable();
            int lookup(string s);
            int insert(string s);
            int dump();    
    };

    SymbolTable *symTable;

    char* strsplice(char* a, int len, int pos);
%}

LINECOMMENT     (\/\/.*)
BEGINCOMMENT    (\/\*)
ENDCOMMENT      (\*\/)
DELIMITER       ([,:;()\[\]{}]|(->))
ARITHMETIC      ([\+\-\*\/])
REMAINDER       (%)
RELATIONAL      ([<>]|(>=)|(<=)|(==)|(!=))
LOGICAL         ([&\|!])
ASSIGMENT       (=)
COMPOUND        ((\+=)|(\-=)|(\*=)|(\/=))

IDENTIFIER      ([a-zA-Z_][a-zA-Z_0-9]*)

INTEGER         ([0-9]+)
PLAIN_REAL      ([-\+])?{INTEGER}"."{INTEGER}
EXPREAL         ([-\+])?{INTEGER}"."{INTEGER}[Ee][+-]?{INTEGER}
REAL            {PLAIN_REAL}|{EXPREAL}
STRING          (\"(\\\"|[^\"])*\")
BOOLEAN         ("true"|"false")

%x COMMENT

%%
"bool"          {token("BOOL");}
"break"         {token("BREAK");}
"char"          {token("CHAR");}
"case"          {token("CASE");}
"class"         {token("CLASS");}
"continue"      {token("CONTINUE");}
"declare"       {token("DECLARE");}
"do"            {token("DO");}
"else"          {token("ELSE");}
"exit"          {token("EXIT");}
"float"         {token("FLOAT");}
"for"           {token("FOR");}
"fun"           {token("FUN");}
"if"            {token("IF");}
"int"           {token("INT");}
"loop"          {token("LOOP");}
"print"         {token("PRINT");}
"println"       {token("PRINTLN");}
"return"        {token("RETURN");}
"string"        {token("STRING");}
"val"           {token("VAL");}
"var"           {token("VAR");}
"while"         {token("WHILE");}

{BOOLEAN}       {tokenString(BOOL, yytext);}

{LINECOMMENT}   {LIST;}
{BEGINCOMMENT}  {
                    LIST; 
                    BEGIN (COMMENT);
                }

<COMMENT>[^\n]  {LIST;}
<COMMENT>\n     {
                    LIST;
                    printf("%d: %s", ++linenum, buf);
                    buf[0] = '\0';
                }
<COMMENT>{ENDCOMMENT}   {LIST; BEGIN 0;}

{DELIMITER}     |
{ARITHMETIC}    |
{REMAINDER}     |
{RELATIONAL}    |
{LOGICAL}       |
{ASSIGMENT}     |
{COMPOUND}      {tokenOper(yytext);}

{STRING}        {
                    tokenString(STRING, strsplice(yytext, yyleng-2, 1));
                }

{IDENTIFIER}    {
                    symTable->insert(yytext);
                    tokenString(ID, yytext);
                }

{REAL}          {tokenString(REAL, yytext);}

{INTEGER}       {tokenInteger(INTEGER, yytext);}

\n              {
                    LIST;
                    printf("%d: %s", ++linenum, buf);
                    buf[0] = '\0';
                }

[ \t]*          {LIST;}

.               {
                    LIST;
                    printf("%d:%s\n", ++linenum, buf);
                    printf("bad character:'%s'\n",yytext);
                    exit(-1);
                }

<<EOF>>         {
                    printf("%d: %s", ++linenum, buf);
                    buf[0] = '\0';
                    return 0;
                }
%%

SymbolTable::SymbolTable(){ 
}

void create(){
    symTable = new SymbolTable();
}

int SymbolTable::lookup(string s){
    if(sTable.find(s) !=sTable.end()){
        //printf("%s exists: id%d", yytext, sTable[s]);
        return sTable[s];
    }
    return 0;
}
int SymbolTable::insert(string s){
    if(lookup(s)){
        return sTable[s];
    }
    else{
        sTable.insert(pair<string, int>(s, entryCount));
        entryCount++;
        return entryCount-1;
    }
}
int SymbolTable::dump(){
    printf("\nSymbol Table:\n");
    for(auto &entry:sTable){
        printf("%d: %s\n", entry.second, entry.first.c_str());
    }
    return entryCount;
}

char* strsplice(char* a, int len, int pos)
{
    char* s = new char[len+1];
    for (int i = pos, j=0; j < len; i++, j++) {
        s[j]= a[i];
    }
    s[len]='\0';
    return s;
}
int main(){
    create();
    yylex();
    symTable->dump();
    return 0;
}