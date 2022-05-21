%{
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "myyacc.tab.hh"


#define LIST strcat(buf,yytext)
#define MAX_LINE_LENG 256
#define token(t) {LIST; return(t);}

int num_lines = 1;
char buf [MAX_LINE_LENG];
char strBuf [MAX_LINE_LENG];
char symtable [211][30+1];
int sytblPtr = 0;

void clearBUFF() {
    ++num_lines;
    buf[0]='\0';
}

%}

digit    [0-9]
decimals    {digit}+
exponent    [eE]["+"-]?{decimals}
realNum     ["+"-]?({decimals}"."{decimals}?{exponent}?|"."{decimals}{exponent}?|{decimals}{exponent})
alpha    [A-Za-z]
blank    [ \t]
newline  \r?\n
id      {alpha}({alpha}|{digit})*
%x  BLOCK_COMMENT LINE_COMMENT STRING

%%
<<EOF>> { LIST; clearBUFF(); return(0); }

"."     token(DOT); /// new
","     token(COMMA);
":"     token(COLON);
";"     token(SEMICOLON);
"->"    token(ARROW);
"("     token(PAR_L);
")"     token(PAR_R);
"["     token(SBRA_L);
"]"     token(SBRA_R);
"{"     token(BRA_L);
"}"     token(BRA_R);

"+"     token(ADD);
"-"     token(SUB);
"*"     token(MULT);
"/"     token(DIVIDE);
"%"     token(PERCENT);


"<"   token(LE);
"<="  token(LEEQ);
">"   token(GR);
">="  token(GREQ);
"=="  token(EQ);
"!="  token(NEQ);

"&"      token(AND);
"|"      token(OR);
"!"      token(NOT);
"="      token(ASSIGN);

[bB][oO][oO][lL][eE][aA][nN] { token(BOOLEAN);}
[bB][rR][eE][aA][kK] { token(BREAK);}
[cC][hH][aA][rR] { token(CHAR);}
[cC][aA][sS][eE] { token(CASE);}
[cC][lL][aA][sS][sS] { token(CLASS);}
[cC][oO][nN][tT][iI][nN][uU][eE]    { token(CONTINUE);} 
[dD][eE][cC][lL][aA][rR][eE] { token(DECLARE);}
[dD][oO]      { token(DO);}
[eE][lL][sS][eE]     { token(ELSE);}
[eE][xX][iI][tT]     { token(EXIT);}
[fF][lL][oO][aA][tT]   { token(FLOAT);}
[fF][oO][rR]       { token(FOR);}
[fF][uU][nN]   { token(FUN);}
[iI][fF]   { token(IF);}
[iI][nN][tT]      { token(INT);}
[lL][oO][oO][pP]    { token(LOOP);}
[pP][rR][iI][nN][tT]    { token(PRINT);}
[pP][rR][iI][nN][tT][lL][nN]    { token(PRINTLN);}
[rR][eE][tT][uU][rR][nN]   { token(RETURN);}
[sS][tT][rR][iI][nN][gG]   { token(STRING);}
[vV][aA][lL]     { token(VAL);}
[vV][aA][rR]     { token(VAR);} 
[wW][hH][iI][lL][eE]     { token(WHILE);}
[iI][nN]  { token(IN);}
[tT][rR][uU][eE]     { yylval.intVal = 1; token(TRUE);}
[fF][aA][lL][sS][eE]  { yylval.intVal = 0; token(FALSE);} 

{blank}*    {LIST;}
{id}        { 
                yylval.stringVal = new std::string(yytext);
                token(ID);
            }
{decimals}  { 
                yylval.intVal = atoi(yytext);
                token(INT_VAL);
            }
{realNum}   {
                yylval.floatVal = atof(yytext);
                token(FLOAT_VAL);
            }
{newline}   {clearBUFF();}

"//"    {LIST; BEGIN LINE_COMMENT;}
"/*"    {LIST; BEGIN BLOCK_COMMENT;}
\"      {LIST; strBuf[0] = '\0'; BEGIN STRING;}
<LINE_COMMENT>.     {LIST;}
<LINE_COMMENT>\n    {clearBUFF();
                    BEGIN 0;}

<BLOCK_COMMENT>.        {LIST;}
<BLOCK_COMMENT>\n       {LIST;
                        clearBUFF();}
<BLOCK_COMMENT>"*/"     {LIST;BEGIN 0;}

<STRING>\"      {
                    BEGIN 0;
                    yylval.stringVal = new std::string(yytext);
                    token(STRING_VAL);
                }                      
<STRING>.         {LIST; strcat(strBuf, yytext);}
<STRING>\"\"      {LIST; strcat(strBuf, "\"");}

%%
