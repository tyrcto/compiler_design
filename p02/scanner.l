%{
    using namespace std;
    #include "symbols.hh"
    #include "y.tab.hh"

    #define MAX_LINE_LENG 256
    #define LIST strcat(buf,yytext)
    
    #define token(t) {LIST; printf("\t<%s>\n",#t);}
    #define tokenChar(t) {LIST; printf("\t<'%c'>\n", t);}
    #define tokenInteger(t,i) {LIST; printf("\t<%s: %d>\n",#t,atoi(i));}
    #define tokenString(t,s) {LIST; printf("\t<%s: %s>\n",#t,s);}
    int linenum = 0;
    char buf[MAX_LINE_LENG];

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
"bool"          {token(BOOL); return BOOL; }
"break"         {token(BREAK); return BREAK; }
"char"          {token(CHAR); return CHAR; }
"case"          {token(CASE); return CASE; }
"class"         {token(CLASS); return CLASS; }
"continue"      {token(CONTINUE); return CONTINUE; }
"declare"       {token(DECLARE); return DECLARE; }
"do"            {token(DO); return DO; }
"else"          {token(ELSE); return ELSE; }
"exit"          {token(EXIT); return EXIT; }
"float"         {token(FLOAT); return FLOAT; }
"for"           {token(FOR); return FOR; }
"fun"           {token(FUN); return FUN; }
"if"            {token(IF); return IF; }
"in"            {token(IN); return IN; }
"int"           {token(INT); return INT; }
"loop"          {token(LOOP); return LOOP; }
"print"         {token(PRINT); return PRINT; }
"println"       {token(PRINTLN); return PRINTLN; }
"return"        {token(RETURN); return RETURN; }
"string"        {token(STRING); return STRING; }
"val"           {token(VAL); return VAL; }
"var"           {token(VAR); return VAR; }
"while"         {token(WHILE); return WHILE; }

 /* single operators */
{DELIMITER}     |
{ARITHMETIC}    |
{REMAINDER}     |
{ASSIGMENT}     |
{LOGICAL}       |
{RELATIONAL}    {tokenChar(yytext[0]); return yytext[0];}

 /* compound operators */
".."            {token(..); return RANGE;}
">="            {token(>=); return GE;}
"<="            {token(<=); return LE;}
"=="            {token(==); return EQ;}
"!="            {token(!=); return NEQ;}
"+="            {token(+=); return ADD;}
"-="            {token(-=); return SUB;}
"*="            {token(*=); return MUL;}
"/="            {token(/=); return DIV;}
"->"            {token(->); return ARROW;}

{BOOLEAN}       {
                    tokenString(BOOL, yytext);
                    if(yytext == "true") {yylval.bval = true;}
                    else {yylval.bval = false;}
                    return BOOL_CONST;
                }

{STRING}        {
                    char* s = new char[yyleng-1];
                    for (int i = 1, j=0; j < yyleng-2; i++, j++) {
                        s[j]= yytext[i];
                    }
                    s[yyleng-1]='\0';
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

\n              {
                    LIST;
                    printf("%d: %s", ++linenum, buf);
                    buf[0] = '\0';
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