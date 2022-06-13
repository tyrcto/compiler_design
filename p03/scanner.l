%{
    using namespace std;
    #include "symbols.hh"
    #include "y.tab.hh"
    #include <fstream>

    #define MAX_LINE_LENG 256
    #define LIST {strcat(buf,yytext); bufCounter+=yyleng;}
    
    #define token(t) {LIST; if(token_flag) printf("<%s>\n",#t); return t;}
    #define tokenChar(t) {LIST; if(token_flag) printf("<'%c'>\n", t); return t;} 
    #define tokenDChar(t) {LIST; if(token_flag) printf("<'%s'>\n", #t);}
    #define tokenInteger(t,i) {LIST; if(token_flag) printf("<%s: %d>\n",#t,atoi(i));}
    #define tokenString(t,s) {LIST; if(token_flag) printf("<%s: %s>\n",#t,s);}
    
    bool token_flag = false;
    bool srcCode_flag = false;

    int linenum = 0;
    char buf[MAX_LINE_LENG];
    int bufCounter = 0;
    std::ofstream outFile;

    void removeCommentTag(int opt){
        std::string s(buf);
        size_t pos;
        if(opt==0) {pos = s.find("/*");}
        else if(opt==1){pos = s.find("*/");}
        else {pos = s.find("//");}
        if(pos!=-1){
            buf[pos] = ' ';
            buf[pos + 1] = ' ';
        }
    }
%}

LINECOMMENT     (\/\/.*)
BEGINCOMMENT    (\/\*)
ENDCOMMENT      (\*\/)
DELIMITER       ([,:;()\[\]{}])
ARITHMETIC      ([\+\-\*\/])
REMAINDER       (%)
RELATIONAL      ([<>])
LOGICAL         ([&\|!])
ASSIGMENT       (=)

IDENTIFIER      ([a-zA-Z_][a-zA-Z_0-9]*)

INTEGER         ([-\+]?[0-9]+)
PLAIN_REAL      ([-\+])?{INTEGER}"."{INTEGER}
EXPREAL         ([-\+])?{INTEGER}"."{INTEGER}[Ee][+-]?{INTEGER}
REAL            {PLAIN_REAL}|{EXPREAL}
STRING          (\"(\\\"|[^\"])*\")
BOOLEAN         ("true"|"false")

%x COMMENT

%%
 /* reserved keywords */
"bool"          {token(BOOL); }
"break"         {token(BREAK); }
"char"          {token(CHAR); }
"case"          {token(CASE); }
"class"         {token(CLASS); }
"continue"      {token(CONTINUE); }
"declare"       {token(DECLARE); }
"do"            {token(DO); }
"else"          {token(ELSE); }
"exit"          {token(EXIT); }
"float"         {token(FLOAT); }
"for"           {token(FOR); }
"fun"           {token(FUN); }
"if"            {token(IF); }
"in"            {token(IN); }   // added for FOR LOOP
"int"           {token(INT); }
"loop"          {token(LOOP); }
"print"         {token(PRINT); }
"println"       {token(PRINTLN); }
"return"        {token(RETURN); }
"string"        {token(STRING); }
"val"           {token(VAL); }
"var"           {token(VAR); }
"while"         {token(WHILE); }

 /* single operators */
{DELIMITER}     |
{ARITHMETIC}    |
{REMAINDER}     |
{ASSIGMENT}     |
{LOGICAL}       |
{RELATIONAL}    {tokenChar(yytext[0]); }

 /* compound operators */
".."            {tokenDChar(..); return RANGE;} // Added for FOR LOOP
">="            {tokenDChar(>=); return GE;}
"<="            {tokenDChar(<=); return LE;}
"=="            {tokenDChar(==); return EQ;}
"!="            {tokenDChar(!=); return NEQ;}
"+="            {tokenDChar(+=); return ADD;}
"-="            {tokenDChar(-=); return SUB;}
"*="            {tokenDChar(*=); return MUL;}
"/="            {tokenDChar(/=); return DIV;}
"->"            {tokenDChar(->); return ARROW;}

{BOOLEAN}       {
                    tokenString(BOOL, yytext);
                    if(yytext == "true") {yylval.bval = true;}
                    else {yylval.bval = false;}
                    return BOOL_CONST;
                }

{STRING}        {
                    char* s = new char[yyleng-2];
                    for (int i = 1, j=0; j < yyleng-2; i++, j++) {
                        s[j]= yytext[i];
                    }
                    s[yyleng-2]='\0';
                    tokenString(STRING, s);
                    yylval.sval = new string(s);
                    return STR_CONST;
                }

{REAL}          {
                    tokenString(REAL, yytext);
                    yylval.dval = atof(yytext);
                    return REAL_CONST;
                }

{INTEGER}       {
                    tokenInteger(INTEGER, yytext);
                    yylval.ival = atoi(yytext);
                    return INT_CONST;
                }

{IDENTIFIER}    {
                    tokenString(ID, yytext);
                    yylval.sval = new string(yytext);
                    return ID;
                }

{LINECOMMENT}   {LIST; removeCommentTag(2);}
{BEGINCOMMENT}  {
                    LIST; 
                    removeCommentTag(0);
                    BEGIN (COMMENT);
                }

<COMMENT>[^\n]  {LIST;}
<COMMENT>\n     {
                    linenum++;
                    if(srcCode_flag) printf("%d: %s", linenum, buf);
                    buf[bufCounter-1]='\0';
                    outFile << "/* " << to_string(linenum ) << ": " << buf << " */\n";

                    LIST;
                    buf[0] = '\0';
                    bufCounter = 0;
                }
<COMMENT>{ENDCOMMENT}   {
                    LIST; 
                    removeCommentTag(1);
                    BEGIN 0;
                }

\n              {
                    linenum++;
                    if(srcCode_flag) printf("%d: %s", ++linenum, buf);
                    buf[bufCounter-1]='\0';
                    outFile << "/* " << to_string(linenum) << ": " << buf << " */\n";

                    LIST;
                    buf[0] = '\0';
                    bufCounter = 0;
                }

[ \t\r]*          {LIST;}

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