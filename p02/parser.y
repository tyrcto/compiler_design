%{
    #include <iostream>
    #include "symbols.hh"
    #define Trace(t)        {printf("===TRACE=> %s\n", t);}

    int yyerror(std::string s);
    extern int yylex();
    extern FILE *yyin;
    extern char* yytext;
    extern int linenum;
    SymbolTableList symbolTable;
    vector<vector<IDInfo> > fCalls;
%}

%union {
    int ival;
    std::string *sval;
    double dval;
    bool bval;
    int type;
    IDInfo* info;
}

%token GE LE EQ NEQ ADD SUB MUL DIV ARROW
%token IN RANGE
%token BOOL BREAK CHAR CASE CLASS CONTINUE DECLARE DO ELSE EXIT FLOAT FOR FUN IF INT LOOP PRINT PRINTLN RETURN STRING VAL VAR WHILE

%token <ival> INT_CONST
%token <dval> REAL_CONST
%token <bval> BOOL_CONST
%token <sval> STR_CONST
%token <sval> ID

 /* Precedence & Associativity */
%left '|'
%left '&'
%left '!'
%left '<' LE EQ GE '>' NEQ
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS

 /* Non-terminals */
%type <info> const_val expr fun_invocation
%type <type> var_type opt_ret_type

%%
program:        class_dec
                {
                    Trace("Reducing to program\n");
                    symbolTable.dump();
                }
                ;

class_dec:      CLASS ID 
                {
                    IDInfo *info = new IDInfo();
                    info->flag = CLASS_FLAG;
                    if(!symbolTable.insert(*$2, *info)) yyerror("function redefinition");
                }
                '{' opt_var_dec opt_fun_dec '}'
                {
                    Trace("Class declaration");
                }
                ;

opt_fun_dec:    fun_dec opt_fun_dec
                | /* zero */
                ;

fun_dec:        FUN ID 
                {
                    IDInfo* info = new IDInfo();
                    info->flag = FUNCTION_FLAG;
                    if(!symbolTable.insert(*$2, *info)) yyerror("Function redefinition");
                    symbolTable.push();
                }
                '(' opt_args ')' opt_ret_type block
                {
                    Trace("Function declaration");

                    symbolTable.dump();
                    symbolTable.pop();
                }
                ;

opt_ret_type:   ':' var_type
                {   
                    Trace("Set function return type");
                    symbolTable.setFuncType($2);
                }
                | /* void return type (function procedure) */
                {
                    Trace("Set function return type");
                    symbolTable.setFuncType(VOID_TYPE);
                }

statement:      simple
                | conditional
                | loop
                ;

loop:           WHILE '(' expr ')' block_or_simp
                {
                    Trace("While loop");
                    if($3->type != BOOL_TYPE) yyerror("Expression not a boolean");
                }
                | FOR '(' ID IN INT_CONST RANGE INT_CONST')' block_or_simp
                {
                    Trace("For loop");
                    if($5 > $7) yyerror("Loop range is in descending order");
                }
                ;

conditional:    IF expr block_or_simp ELSE block_or_simp
                {
                    Trace("IF-ELSE block");
                    if($2->type != BOOL_TYPE) yyerror("Expression not a boolean");
                }
                | IF expr block_or_simp
                {
                    Trace("IF block");
                    if($2->type != BOOL_TYPE) yyerror("Expression not a boolean");
                }
                ;

block_or_simp:  block|simple;

simple:         ID '=' expr
                {
                    Trace("ID assigment");

                    IDInfo *info = symbolTable.lookup(*$1); 
                    if(!info) yyerror("Undeclared identifier");
                    if(info->flag == CONST_FLAG) yyerror("Cannot re-assign value to constant variables");
                    if(info->flag == FUNCTION_FLAG) yyerror("Cannot assign value to functions");
                    
                }
                | ID '[' expr ']' '=' expr
                {
                    Trace("Array indexing");
                    if($3->type != INT_TYPE) yyerror("Array index not of integer type");
                }
                | PRINT expr
                {
                    Trace("Print expression");
                }
                | PRINTLN expr
                {
                    Trace("Println expression");
                }
                | RETURN
                {
                    Trace("Return");
                }
                | RETURN expr
                {
                    Trace("Return expression");
                }
                ;

fun_invocation: ID 
                {
                    fCalls.push_back(vector<IDInfo>());
                }
                '(' opt_expr ')'
                {
                    Trace("Function invoked");
                    IDInfo* info = symbolTable.lookup(*$1);
                    if(!info) yyerror("Undeclared identifier");
                    if(info->flag != FUNCTION_FLAG) yyerror("Not a function");

                    vector<IDInfo> params = info->value.arr;
                    if(params.size() != fCalls[fCalls.size()-1].size()) yyerror("Number of parameters do not match");
                    for(int i=0;i< params.size();i++){
                        if(params[i].type != fCalls[fCalls.size()-1].at(i).type) yyerror("Parameter types do not match");
                    }
                    $$ = info;
                    fCalls.pop_back();
                }
                ;

opt_expr: expr ',' opt_expr
                |expr
                | /* zero */
                ;

expr:           const_val
                | ID
                {
                    Trace("Identifier referenced");
                    IDInfo* info = symbolTable.lookup(*$1);
                    if(!info) yyerror("Undeclared identifier");
                    $$ = info;
                }
                | fun_invocation
                | expr '+' expr
                {
                    Trace("E + E");
                    if($1->type!=$3->type) yyerror("Expression types incompatible");
                    
                    IDInfo *info = new IDInfo();
                    info->type = $1->type;
                    $$ = info;
                }
                | expr '-' expr
                {
                    Trace("E - E");
                    if($1->type!=$3->type) yyerror("Expression types incompatible");
                    
                    IDInfo *info = new IDInfo();
                    info->type = $1->type;
                    $$ = info;
                }
                | expr '*' expr
                {
                    Trace("E * E");
                    if($1->type != $3->type) yyerror("Expression types incompatible");
                    
                    IDInfo *info = new IDInfo();
                    info->type = $1->type;
                    $$ = info;
                }
                | expr '/' expr
                {
                    Trace("E / E");
                    if($3 == 0) yyerror("Division by 0");
                    if($1->type!=$3->type) yyerror("Expression types incompatible");

                    IDInfo *info = new IDInfo();
                    info->type = $1->type;
                    $$ = info;
                }
                | expr '<' expr
                {
                    Trace("E < E");
                    if($1->type != $3->type) yyerror("Expression types incompatible");
                    IDInfo *info = new IDInfo();
                    info->type = BOOL_TYPE;
                    $$ = info;
                }
                | expr LE expr
                {
                    Trace("E <= E");
                    if($1->type != $3->type) yyerror("Expression types incompatible");
                    IDInfo *info = new IDInfo();
                    info->type = BOOL_TYPE;
                    $$ = info;
                }
                | expr '>' expr
                {
                    Trace("E > E");
                    if($1->type != $3->type) yyerror("Expression types incompatible");
                    IDInfo *info = new IDInfo();
                    info->type = BOOL_TYPE;
                    $$ = info;
                }
                | expr GE expr
                {
                    Trace("E >= E");
                    if($1->type != $3->type) yyerror("Expression types incompatible");
                    IDInfo *info = new IDInfo();
                    info->type = BOOL_TYPE;
                    $$ = info;
                }
                | expr EQ expr
                {
                    Trace("E == E");
                    if($1->type != $3->type) yyerror("Expression types incompatible");
                    IDInfo *info = new IDInfo();
                    info->type = BOOL_TYPE;
                    $$ = info;
                }
                | expr NEQ expr
                {
                    Trace("E != E");
                    if($1->type != $3->type) yyerror("Expression types incompatible");
                    IDInfo *info = new IDInfo();
                    info->type = BOOL_TYPE;
                    $$ = info;
                }
                | expr '&' expr
                {
                    Trace("E & E");
                    if($1->type != $3->type) yyerror("Expression types incompatible");
                    IDInfo *info = new IDInfo();
                    info->type = BOOL_TYPE;
                    $$ = info;
                }
                | expr '|' expr
                {
                    Trace("E | E");
                    if($1->type != $3->type) yyerror("Expression types incompatible");
                    IDInfo *info = new IDInfo();
                    info->type = BOOL_TYPE;
                    $$ = info;
                }
                | '(' expr ')'
                {
                    Trace("(expression) in parentheses");
                    $$ = $2;
                }
                | '-' expr %prec UMINUS
                {
                    Trace("Negate E");
                    if($2->type != INT_TYPE || $2->type != REAL_TYPE) yyerror("Cannot negate type");
                    IDInfo* info = new IDInfo();
                    info->type = $2->type;
                    $$ = info;
                }
                ;

opt_statements: statement opt_statements
                | /* zero */
                ;

block:          '{' opt_statements '}'
                {
                    Trace("Simple statement inside block");
                }
                ;

opt_args:       args opt_args
                | /* zero */
                ;

args:           args ',' args
                |ID ':' var_type
                {
                    Trace("Function formal arguments");
                    IDInfo* info = new IDInfo();
                    info->flag = VAR_FLAG;
                    info->type = $3;
                    if(!symbolTable.insert(*$1, *info)) yyerror("Duplicate arguments");
                }
                ;

opt_var_dec:    const_dec opt_var_dec
                | var_dec opt_var_dec
                | /* zero */
                ;

const_dec:      VAL ID '=' const_val
                {
                    Trace("Constant declaration");
                    if(!symbolTable.insert(*$2, *$4)) yyerror("Const variable redefinition");
                }
                |VAL ID ':' var_type '=' const_val
                {
                    Trace("Constant declaration with type");
                    if($6->type != $4)yyerror("Wrong declared type");
                    if(!symbolTable.insert(*$2, *$6)) yyerror("Const variable redefinition");
                }
                ;

var_dec:        VAR ID ':' var_type
                {
                    Trace("Variable declaration with type");
                    IDInfo *info = new IDInfo();
                    info->flag = VAR_FLAG;
                    if(!symbolTable.insert(*$2, *info)) yyerror("Variable redefinition");
                }
                |VAR ID  '=' const_val
                {
                    Trace("Variable declaration with const assignment");
                    $4->flag = VAR_FLAG;
                    if(!symbolTable.insert(*$2, *$4)) yyerror("Variable redefinition");
                }
                |VAR ID  var_type '=' const_val
                {
                    Trace("Variable declaration with const assignment");
                    if($3 && $5->type != $3) yyerror("Wrong declared type");
                    $5->flag = VAR_FLAG;
                    if(!symbolTable.insert(*$2, *$5)) yyerror("Variable redefinition");
                }
                |VAR ID ':' var_type '[' INT_CONST ']'
                {
                    Trace("Array declaration with type");
                    if(!symbolTable.insert(*$2, $4, $6)) yyerror("Array redefinition");
                }
                ;

var_type:       BOOL
                {
                    $$ = BOOL_TYPE;
                }
                |INT
                {
                    $$ = INT_TYPE;
                }
                |STRING
                {
                    $$ = STRING_TYPE;
                }
                |FLOAT
                {
                    $$ = REAL_TYPE;
                }
                ;

const_val:      BOOL_CONST
                {
                    $$ = BOOLConst($1);
                }
                |INT_CONST
                {
                    $$ = INTConst($1);
                    cout << "Int val:" << $1 << endl;
                }
                | REAL_CONST
                {
                    $$ = REALConst($1);
                }
                |STR_CONST
                {
                    $$ = STRConst($1);
                }

%%
int yyerror(std::string s)
{
    cerr << "[Error at line " << (linenum + 1) << "]: " << s << endl;
    cerr << "yytext: " << yytext << endl;
    exit(1);
}

int main(int argc, char* argv[])
{
    // yyparse();
    // return 0;
      /* open the source program file */
    if (argc < 2) {
        printf ("Usage: sc filename\n");
        exit(1);
    }
    yyin = fopen(argv[1], "r");         /* open input file */

    /* perform parsing */
    if (yyparse() == 1){                 /* parsing */
        yyerror("Parsing error!");     /* syntax error */
        cout << yytext << endl;
    }
    return 0;
}