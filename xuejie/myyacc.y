%{

#include <stdio.h>
#include <string.h>
#include "lex.yy.c"
#include "symbol.h"

#define Trace(t) 	print(t)

#define TYPE_BOOL 1
#define TYPE_INT 2
#define TYPE_FLOAT 3
#define TYPE_STRING 4
extern int yylex();
    extern FILE *yyin;
    extern char* yytext;
%}
/** Start Rule **/
%start program

%union {
    int intVal;
    float floatVal;
    char* stringVal;
}

// tokens
%token DOT COMMA COLON SEMICOLON ARROW  // . , :  ; ->
%token PAR_L PAR_R SBRA_L SBRA_R BRA_L BRA_R  // ( ) [ ] { }
%token ADD SUB MULT DIVIDE PERCENT  // + - * / %
%token LE LEEQ GR GREQ EQ NEQ  // < <= > >= == !=   �P�_
%token AND OR NOT ASSIGN // & | ! = 
%token BOOLEAN BREAK CHAR CASE CLASS CONTINUE DECLARE DO ELSE EXIT
%token FLOAT FOR FUN IF INT LOOP PRINT PRINTLN RETURN STRING
%token VAL VAR WHILE IN
%token ss
/*
%token BEGINA END INTEGER  PROCEDURE  
*/
%token <intVal> FALSE TRUE
%token <intVal> INT_VAL
%token <floatVal> FLOAT_VAL
%token <stringVal> STRING_VAL
%token <stringVal> ID

%type <intVal> assign_type data_type constant_exp  
%type <intVal> int_exp block_stmt expr block_body
%type <floatVal> float_exp

/*
 * (7) |
 * (6) &
 * (5) !
 * (4) < <= > >= == !=
 * (3) + -
 * (2) * / %
 * (1) - (unary) 
*/
%right ASSIGN
%left OR
%left AND
%left NOT
%left LE LEEQ GR GREQ EQ NEQ 
%left ADD CUT
%left MULT DIVIDE PERCENT
%nonassoc UMINUS


%%

// Program // class identifier { < variable and constant declarations or function declarations > }
program : CLASS ID BRA_L class_block BRA_R
class_block : const_or_var_dec class_block
			| func_decs class_block
			| ; // class_block �ۤv�����e��

/* data Types */

data_type : INT		{ $$ = TYPE_INT;}
		 | FLOAT	{ $$ = TYPE_FLOAT;}
		 | STRING	{ $$ = TYPE_STRING;}
		 | BOOLEAN	{ $$ = TYPE_BOOL;}

/** Functions **/ 

// function_declarations //fun identifier ( <formal arguments > ) < : type > \n block
func_decs : func_dec func_decs
		  |;
func_dec : FUN ID PAR_L PAR_R block_stmt
		 | FUN ID PAR_L  PAR_R block_stmt COLON data_type block_stmt //���^�ǫ��A
		 | FUN ID PAR_L formal_arguments PAR_R block_stmt
		 | FUN ID PAR_L formal_arguments PAR_R block_stmt COLON data_type block_stmt //���^�ǫ��A
	 	 ;
formal_arguments : formal_argument // identifier : type <, identifier : type , ... , identifier : type>
				 | formal_argument COMMA formal_arguments; 
formal_argument : ID COLON data_type ;	// identifier : type 

/** Constant or Variable Declarations **/

const_or_var_dec : var_decs const_or_var_dec
			 	  | const_decs const_or_var_dec
				  |;
const_decs : const_dec const_decs
		   |;			
const_dec : VAL ID ASSIGN constant_exp  //val identifier <: type > = constant_exp
		  |VAL ID COLON data_type
 		  |VAL ID ASSIGN expr
		  |VAL ID  COLON data_type ASSIGN expr //�P�_ expr �O���O constant
		  ;	
var_decs : var_dec  var_decs
		 |;
var_dec : VAR ID		// var identifier <: type >< = constant exp >
		|VAR ID COLON data_type
		|VAR ID ASSIGN expr 
		|VAR ID COLON data_type ASSIGN expr //�P�_ expr �O���O constant
		;

/** Array **/

array : VAR ID COLON data_type SBRA_L expr SBRA_R
		; //var identifier : type [ num ]

/** Statements **/

statements : statement statements
		   |
		   ;

statement : simple_stmt
	  	   | block_stmt
		   | conditional_stmt
		   | loop_stmt
		   | expr
		   ;
//simple
simple_stmt:
	ID ASSIGN expr	//identifier = expression
	|ID SBRA_L integer_expr SBRA_R ASSIGN expr	// identifier[integer expression] = expression
	|PRINT PAR_L expr	PAR_R	//print <(> expression <)> ???
	|PRINTLN PAR_L expr	PAR_R	//println <(> expression <)>
	|RETURN //return
	|RETURN ID 
	|RETURN expr //return expression
	;
assign_type: COLON data_type { $$ = $2;}

/** block_stmt **/

block_stmt : BRA_L block_body BRA_R { $$ = $2; }
block_body:block_body const_or_var_dec
	 	|block_body statements 
	 	|;

conditional_stmt:IF PAR_L boolean_expr PAR_R
				block_or_simple
				ELSE
				block_or_simple

				|IF PAR_L boolean_expr PAR_R
				block_or_simple
				;
block_or_simple:block_stmt
				|simple_stmt
				;
loop_stmt:WHILE PAR_L boolean_expr PAR_R
     block_or_simple

	 |FOR PAR_L ID IN integer_expr DOT DOT integer_expr PAR_R
	 block_or_simple
	 ; 
									
//constant_exp
constant_exp : INT_VAL{ 
         $$ = TYPE_INT;
       }
	|FALSE|TRUE
	|FLOAT_VAL
	|STRING_VAL
	;
// int_exp �� val �ݩ� ��type <intVal>
int_expr: INT_VAL ADD INT_VAL;

integer_expr:INT;

boolean_expr:expr
			;

expr : PAR_L expr PAR_R { $$ = $2; }
     | SUB expr
	  { 
		if($2 == TYPE_INT || $2 == TYPE_FLOAT){
			 }else{
				 printf("variable TYPE error, must be INT or FLOAT");
			 }
	  }
     | NOT expr
     | expr MULT expr
	  { 
		 if($1 == $3){
			 if($1 == TYPE_INT || $1 == TYPE_FLOAT){
			 }else{
				 printf("variable TYPE error");
			 }
		 }else{
			 printf("type are not equal, TYPE error");
		 }
	  }
     | expr DIVIDE expr
	  { 
		 if($1 == $3){
			 if($1 == TYPE_INT || $1 == TYPE_FLOAT){
			 }else{
				 printf("variable TYPE error");
			 }
		 }else{
			 printf("type are not equal, TYPE error");
		 }
	  }
	 | expr PERCENT expr
	  { 
		 if($1 == $3){
			 if($1 == TYPE_INT || $1 == TYPE_FLOAT){
			 }else{
				 printf("variable TYPE error");
			 }
		 }else{
			 printf("type are not equal, TYPE error");
		 }
	  }
     | expr ADD expr
	  { 
		 if($1 == $3){
			 if($1 == TYPE_INT || $1 == TYPE_FLOAT){
			 }else{
				 printf("variable TYPE error");
			 }
		 }else{
			 printf("type are not equal, TYPE error");
		 }
	  }
	 | expr LE expr
	 { 
		 if($1 == $3){
			 if($1 == TYPE_INT || $1 == TYPE_FLOAT){
			 }else{
				 printf("variable TYPE error");
			 }
		 }else{
			 printf("type are not equal, TYPE error");
		 }
	  }
     | expr LEEQ expr
	 { 
		 if($1 == $3){
			 if($1 == TYPE_INT || $1 == TYPE_FLOAT){
			 }else{
				 printf("variable TYPE error");
			 }
		 }else{
			 printf("type are not equal, TYPE error");
		 }
	  }
     | expr GR expr
	 { 
		 if($1 == $3){
			 if($1 == TYPE_INT || $1 == TYPE_FLOAT){
			 }else{
				 printf("variable TYPE error");
			 }
		 }else{
			 printf("type are not equal, TYPE error");
		 }
	  }
	 | expr GREQ expr
	 { 
		 if($1 == $3){
			 if($1 == TYPE_INT || $1 == TYPE_FLOAT){
			 }else{
				 printf("variable TYPE error");
			 }
		 }else{
			 printf("type are not equal, TYPE error");
		 }
	  }
     | expr EQ expr
	 { 
		 if($1 == $3){
			 if($1 == TYPE_INT || $1 == TYPE_FLOAT){
			 }else{
				 printf("variable TYPE error");
			 }
		 }else{
			 printf("type are not equal, TYPE error");
		 }
	  }
	 | expr NEQ expr
	 { 
		 if($1 == $3){
			 if($1 == TYPE_INT || $1 == TYPE_FLOAT){
			 }else{
				 printf("variable TYPE error");
			 }
		 }else{
			 printf("type are not equal, TYPE error");
		 }
	  }
	 | expr AND expr
	 | expr OR expr
	 | simple_stmt
	 ;

	

%%


yyerror(msg)
char *msg;
{
    fprintf(stderr, "%s\n", msg);
}

int main (int argc, char *argv[]) {
    /* open the source program file */
    if (argc != 2) {
        printf ("Usage: sc filename\n");
        exit(1);
    }
    yyin = fopen(argv[1], "r");         /* open input file */

    /* perform parsing */
    if (yyparse() == 1)                 /* parsing */
        yyerror("Parsing error !");     /* syntax error */
}
	