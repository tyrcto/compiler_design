%{
    #include "symbols.hh"
    #include "codegenerator.hh"
    #define Trace(t)        {if (trace_flag)printf("TRACE==> %s\n", t);}

    // Optional printing flags
    bool trace_flag = true;
    bool dump_flag = true;
    int labelCount = 0;

    int yyerror(std::string s);
    extern int yylex();
    extern FILE *yyin;
    extern char* yytext;
    extern int linenum;
    
    SymbolTableList symbolTable;        
    vector<vector<IDInfo> > fCalls;     // used for function invocations/calls
    CodeGenerator generator;
    vector<IDInfo> fFormal;
%}

%union {
    int ival;
    std::string *sval;
    double dval;
    bool bval;
    int type;
    IDInfo* info;
}

 /*Compound operator tokens */
%token GE LE EQ NEQ ADD SUB MUL DIV ARROW
 /* Additional tokens to support FOR LOOP */
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
/* Program unit */
program:        class_dec
                {
                    Trace("Reducing to program\n");
                    if(dump_flag)symbolTable.dump();
                    symbolTable.pop();
                };

/* Class declaration */
class_dec:      CLASS ID 
                {
                    Trace("Class declaration");

                    IDInfo *info = new IDInfo();
                    info->flag = CLASS_FLAG;
                    int index = symbolTable.insert(*$2, *info);
                    if(!index) yyerror("Class redefinition");
                
                    symbolTable.push();     // Class scope
                    generator.createClass(*$2);
                }
                '{' opt_var_dec opt_fun_dec '}'
                {
                    /* Class must have at least 1 method (i.e. main method) */
                    IDInfo *mainMethod = symbolTable.lookup("main"); 
                    if(!mainMethod || mainMethod->flag != FUNCTION_FLAG) yyerror("No [main] method found");

                    if(trace_flag) symbolTable.dump();
                    symbolTable.pop();
                    generator.endBlock(0);
                };

/* 1 or Multiple Functions */
opt_fun_dec:    fun_dec opt_fun_dec
                | /* empty symbol */;

/* Function declaration*/
fun_dec:        FUN ID 
                {
                    Trace("Function declaration");
                    IDInfo* info = new IDInfo();
                    info->init = false;         // Is function return type stated?
                    info->flag = FUNCTION_FLAG;
                    int index = symbolTable.insert(*$2, *info);
                    if(!index) yyerror("Function redefinition");
                    if(*$2 == "main"){
                        // main function declared 
                    }
                    symbolTable.push(); // Function scope
                }
                '(' opt_args ')'
                {
                    IDInfo* info = symbolTable.lookup(*$2);
                    vector<string> paramTypes = info->value.getArrTypes();

                    generator.createMethod(*$2, paramTypes);
                    fFormal.clear();    // clear for next function's formal arguments
                } opt_ret_type block
                {
                    if(dump_flag)symbolTable.dump();
                    symbolTable.pop();
                    generator.endBlock(1);
                };

/* Optional formal arguments */
opt_args:       args
                | /* empty symbol */;

/* 1 or Multiple arguments */
args:           arg ',' args
                |arg;

/* Only 1 argument */
arg:           ID ':' var_type
                {
                    Trace("Function formal arguments");

                    IDInfo* info = new IDInfo();
                    info->flag = VAR_FLAG;
                    info->type = $3;    // Assign var type to ID
                    int index = symbolTable.insert(*$1, *info);
                    if(!index) yyerror("Duplicate arguments");
                    
                    symbolTable.addFuncArg(*$1, *info); // add argument to current pointed function
                };

/* Function's optional return type */
opt_ret_type:   ':' var_type
                {   
                    Trace("Set function return type");
                    symbolTable.setFuncType($2);
                }
                | /* void return type (a.k.a. function procedure) */
                {
                    Trace("Set function return type to VOID");
                    symbolTable.setFuncType(VOID_TYPE);
                };

statement:      simple
                | block
                | conditional
                | loop
                | fun_invocation;

loop:           WHILE '(' expr ')' block_or_simp
                {
                    Trace("WHILE loop");
                    if($3->type != BOOL_TYPE) yyerror("Expression not a boolean");
                }
                | FOR '(' ID IN INT_CONST RANGE INT_CONST')' block_or_simp
                {
                    Trace("FOR loop");
                    if($5 > $7) yyerror("Loop range is in descending order");
                };

conditional:    IF expr if_start
                block_or_simp ELSE 
                {
                    labelCount--;
                    generator.write("goto Lexit"+to_string(labelCount));
                    generator.subFrame();
                    generator.write("Lfalse" + to_string(labelCount)+":");
                    generator.addFrame();
                } block_or_simp
                {
                    Trace("IF-ELSE block");
                    if($2->type != BOOL_TYPE) yyerror("Expression not a boolean");
                    generator.subFrame();
                    generator.write("Lexit"+to_string(labelCount)+":");
                    generator.addFrame();
                }
                | IF expr if_start block_or_simp
                {
                    Trace("IF block");
                    if($2->type != BOOL_TYPE) yyerror("Expression not a boolean");
                };

if_start:       /* empty */
                {
                    generator.write("iconst_0");
                    generator.write("goto Lcomp" + to_string(labelCount));
                    generator.subFrame();
                    generator.write("Ltrue"+to_string(labelCount)+":");
                    generator.addFrame();
                    generator.write("iconst_1");
                    generator.subFrame();
                    generator.write("Lcomp"+to_string(labelCount)+":");
                    generator.addFrame();
                    generator.write("ifeq Lfalse"+to_string(labelCount));
                    labelCount++;
                };

 /* Provide option for either block or simple statements */
block_or_simp:  block | simple;

simple:         ID '=' expr
                {
                    Trace("Simple: ID assigment");

                    IDInfo *info = symbolTable.lookup(*$1); 
                    if(!info) yyerror("Undeclared identifier");
                    if(info->flag == CONST_FLAG) yyerror("Cannot re-assign value to constant variables");
                    if(info->flag == FUNCTION_FLAG) yyerror("Cannot assign value to functions");

                    if(symbolTable.isGlobal(*$1)) generator.assignGlobal(*$1);
                    else generator.assignLocal(info->id, $3->value.i);
                }
                | ID '[' expr ']' '=' expr
                {
                    Trace("Simple: Array indexing assigment");
                    IDInfo *info = symbolTable.lookup(*$1); 
                    if(!info) yyerror("Undeclared identifier");
                    if(info->flag != VAR_FLAG) yyerror("Not a variable");
                    if(info->type != ARRAY_TYPE) yyerror("Not an array");
                    if($3->type != INT_TYPE) yyerror("Array index not of integer type");
                    if($3->value.i >= info->value.arr.size() || $3->value.i < 0) yyerror("Index out of range");
                    if(info->value.arr[0].type != $6->type) yyerror("Types are incompatible");
                }
                | PRINT 
                {
                    Trace("Simple: Print expression");
                    generator.write("getstatic java.io.PrintStream java.lang.System.out");
                }
                expr
                {
                    generator.endPrint($3->type, false);
                }
                | PRINTLN 
                {
                    Trace("Simple: Println expression");
                    generator.write("getstatic java.io.PrintStream java.lang.System.out");
                }
                expr
                {
                    generator.endPrint($3->type, true);
                }
                | RETURN
                {
                    Trace("Simple: Return");
                    generator.write("return");
                }
                | RETURN expr    
                {
                    Trace("Simple: Return expression");
                    if(!symbolTable.setFuncType($2->type)) yyerror("Return type does not match function return type");
                    generator.write("ireturn");
                };

/* Serves as both function expression and procedure */
fun_invocation: ID 
                {
                    Trace("Function invoked");
                    fCalls.push_back(vector<IDInfo>());
                }
                '(' opt_comma_sep ')'
                {
                    IDInfo* info = symbolTable.lookup(*$1);
                    if(!info) yyerror("Undeclared identifier");
                    if(info->flag != FUNCTION_FLAG) yyerror("Not a function");

                    // Check whether num of parameters is equal
                    vector<IDInfo> params = info->value.arr;
                    if(params.size() != fCalls[fCalls.size()-1].size()) yyerror("Number of parameters do not match");
                    for(int i=0;i< params.size();i++){
                        if(params[i].type != fCalls[fCalls.size()-1].at(i).type) yyerror("Parameter types do not match");
                    }
                    $$ = info;
                    fCalls.pop_back();
                };

/* Optional comma separated function expressions as parameters */
opt_comma_sep:  comma_sep_expr
                | /* empty symbol */;

/* 1 or Multiple function expressions */
comma_sep_expr: fun_expr ',' comma_sep_expr
                | fun_expr;

/* Only 1 function expression */
fun_expr:       expr
                {
                    fCalls[fCalls.size()-1].push_back(*$1);
                };

/* All possible expresions */
expr:           const_val
                {
                    CGValue tempVal($1->value.b, $1->value.i, $1->value.s);
                    generator.loadConst($1->type, tempVal);
                }
                | ID
                {
                    Trace("Identifier referenced");
                    IDInfo* info = symbolTable.lookup(*$1);
                    if(!info) yyerror("Undeclared identifier");
                    $$ = info;

                    if(symbolTable.isGlobal(*$1)){ // global var
                        generator.loadGlobalVar(*$1);
                    }
                    else{   // local var
                        if(info->flag == CONST_FLAG) {
                            CGValue tempVal(info->value.b, info->value.i, info->value.s);
                            generator.loadConst(info->type, tempVal);
                        }
                        else generator.loadLocalVar(info->id);
                    }
                }
                | ID '[' expr ']'
                {
                    IDInfo *info = symbolTable.lookup(*$1);
                    if(!info) yyerror("Undeclared identifier");
                    if(info->type != ARRAY_TYPE) yyerror("Identifier is not an array");
                    if($3->type != INT_TYPE) yyerror("Array index not of integer type");
                    if($3->value.i >= info->value.arr.size() || $3->value.i < 0) yyerror("Index out of range");
                    $$ = new IDInfo(info->value.arr[$3->value.i]);
                }
                | fun_invocation
                {
                    Trace("Function as expression");
                }
                | '-' expr %prec UMINUS
                {
                    Trace("Unary Minus Expression");

                    // Makes sure type is either INT or REAL, otherwise impossible(error)
                    if(!($2->type == INT_TYPE || $2->type == REAL_TYPE)) yyerror("Operator error");
                    
                    IDInfo* info = new IDInfo();
                    info->type = $2->type;
                    $$ = info;
                    generator.write("ineg");
                }
                | expr '+' expr
                {
                    Trace("Expression + Expression");
                    
                    if($1->type!=$3->type) yyerror("Expression types incompatible");    // Type must be compatible to perform operation
                    if(!($1->type == INT_TYPE || $1->type == REAL_TYPE)) yyerror("Operator error");
                    
                    IDInfo *info = new IDInfo();
                    info->type = $1->type;
                    $$ = info;
                    generator.write("iadd");
                }
                | expr '-' expr
                {
                    Trace("Expression - Expression");

                    if($1->type!=$3->type) yyerror("Expression types incompatible");
                    if(!($1->type == INT_TYPE || $1->type == REAL_TYPE)) yyerror("Operator error");
                    
                    IDInfo *info = new IDInfo();
                    info->type = $1->type;
                    $$ = info;
                    generator.write("isub");
                }
                | expr '*' expr
                {
                    Trace("Expression * Expression");
                    if($1->type != $3->type) yyerror("Expression types incompatible");
                    if(!($1->type == INT_TYPE || $1->type == REAL_TYPE)) yyerror("Operator error");
                    
                    IDInfo *info = new IDInfo();
                    info->type = $1->type;
                    $$ = info;
                    generator.write("imul");
                }
                | expr '/' expr
                {
                    Trace("Expression/ Expression");
                    if($3 == 0) yyerror("Division by 0");   // Divisor must not equal 0
                    if($1->type!=$3->type) yyerror("Expression types incompatible");
                    if(!($1->type == INT_TYPE || $1->type == REAL_TYPE)) yyerror("Operator error");

                    IDInfo *info = new IDInfo();
                    info->type = $1->type;
                    $$ = info;
                    generator.write("idiv");
                }
                | expr '<' expr
                {
                    // BOOLEAN EXP
                    Trace("Expression < Expression");
                    
                    if($1->type != $3->type) yyerror("Expression types incompatible");
                    if(!($1->type == INT_TYPE || $1->type == REAL_TYPE)) yyerror("Operator error");

                    IDInfo *info = new IDInfo();
                    info->type = BOOL_TYPE;
                    $$ = info;

                    // Boolean expression code generation
                    generator.write("isub");
                    generator.write("iflt Lfalse" + to_string(labelCount));

                }
                | expr LE expr
                {
                    Trace("Expression <= Expression");

                    if($1->type != $3->type) yyerror("Expression types incompatible");
                    if(!($1->type == INT_TYPE || $1->type == REAL_TYPE)) yyerror("Operator error");

                    IDInfo *info = new IDInfo();
                    info->type = BOOL_TYPE;
                    $$ = info;

                    generator.write("isub");
                    generator.write("ifle Lfalse" + to_string(labelCount));
                }
                | expr '>' expr
                {
                    Trace("Expression > Expression");
                    if($1->type != $3->type) yyerror("Expression types incompatible");
                    if(!($1->type == INT_TYPE || $1->type == REAL_TYPE)) yyerror("Operator error");

                    IDInfo *info = new IDInfo();
                    info->type = BOOL_TYPE;
                    $$ = info;

                    generator.write("isub");
                    generator.write("ifgt Ltrue" + to_string(labelCount));
                }
                | expr GE expr
                {
                    Trace("Expression >= Expression");
                    if($1->type != $3->type) yyerror("Expression types incompatible");
                    if(!($1->type == INT_TYPE || $1->type == REAL_TYPE)) yyerror("Operator error");

                    IDInfo *info = new IDInfo();
                    info->type = BOOL_TYPE;
                    $$ = info;

                    generator.write("isub");
                    generator.write("ifge Lfalse" + to_string(labelCount));
                }
                | expr EQ expr
                {
                    Trace("Expression == Expression");
                    if($1->type != $3->type) yyerror("Expression types incompatible");

                    IDInfo *info = new IDInfo();
                    info->type = BOOL_TYPE;
                    $$ = info;

                    generator.write("isub");
                    generator.write("ifeq Lfalse" + to_string(labelCount));
                }
                | expr NEQ expr
                {
                    Trace("Expression != Expression");
                    if($1->type != $3->type) yyerror("Expression types incompatible");

                    IDInfo *info = new IDInfo();
                    info->type = BOOL_TYPE;
                    $$ = info;

                    generator.write("isub");
                    generator.write("ifne Lfalse" + to_string(labelCount));
                }
                | '!' expr
                {
                    Trace("NOT Expression");
                    if($2->type != BOOL_TYPE) yyerror("Not a boolean");     // Must be of boolean type to be able to inverse the result

                    IDInfo* info = new IDInfo();
                    info->type = BOOL_TYPE;
                    $$ = info;
                    generator.write("ixor");
                }
                | expr '&' expr
                {
                    Trace("Expression AND Expression");

                    if($1->type != $3->type) yyerror("Expression types incompatible");

                    IDInfo *info = new IDInfo();
                    info->type = BOOL_TYPE;
                    $$ = info;
                    generator.write("iand");
                }
                | expr '|' expr
                {
                    Trace("Expression OR Expression");

                    if($1->type != $3->type) yyerror("Expression types incompatible");

                    IDInfo *info = new IDInfo();
                    info->type = BOOL_TYPE;
                    $$ = info;
                    generator.write("ior");
                }
                | '(' expr ')'
                {
                    Trace("(Expression) in parentheses");
                    $$ = $2;
                };

/* Block statement */
block:          '{' 
                {
                    Trace("Block statement start");
                    symbolTable.push();             // Block scope
                }
                opt_var_dec opt_statement '}'       // Can have any number of variable/const declarations and/or statements
                {
                    Trace("Block statement end");
                    if(dump_flag)symbolTable.dump();
                    symbolTable.pop();              // Leave block scope
                };

/* 1 or Multiple statements */
opt_statement:  statement opt_statement
                | /* empty symbol */;

/* 1 or Multiple const/var declarations */
opt_var_dec:    const_dec opt_var_dec
                | var_dec opt_var_dec
                | /* empty symbol */;

/* Constant declaration */
const_dec:      VAL ID '=' const_val
                {
                    Trace("Constant declaration");
                    // type determined by assigned constant value
                    int index = symbolTable.insert(*$2, *$4);
                    if(!index) yyerror("Const variable redefinition");
                }
                |VAL ID ':' var_type '=' const_val
                {
                    Trace("Constant declaration with type");

                    if($6->type != $4)yyerror("Wrong declared type");   // Must be correctly typed
                    int index = symbolTable.insert(*$2, *$6);
                    if(!index) yyerror("Const variable redefinition");
                };

/* Variable declaration */
var_dec:        VAR ID ':' var_type
                {
                    Trace("Variable declaration with type");

                    IDInfo *info = new IDInfo();
                    info->flag = VAR_FLAG;
                    int index = symbolTable.insert(*$2, *info);
                    if(!index) yyerror("Variable redefinition");
                    
                    if(symbolTable.isGlobal(*$2)){ // class scope -> global variables
                        generator.createField(*$2, false);
                    }
                    else{   // local var
                        generator.createLocalVar(*$2, index, 0);
                    }
                }
                |VAR ID  '=' const_val
                {
                    Trace("Variable declaration with const assignment");
                    $4->flag = VAR_FLAG;
                    int index = symbolTable.insert(*$2, *$4);
                    if(!index) yyerror("Variable redefinition");
                    if(symbolTable.isGlobal(*$2)){ // class scope -> global variables
                        generator.createField(*$2, false);
                    }
                    else{   // local var
                        generator.createLocalVar(*$2, index, 0);
                    }
                }
                |VAR ID  ':' var_type '=' const_val
                {
                    Trace("Variable declaration with type and const assignment");
                    if($6->type != $4) yyerror("Wrong declared type");
                    $6->flag = VAR_FLAG;
                    int index = symbolTable.insert(*$2, *$6);
                    if(!index) yyerror("Variable redefinition");
                   
                    if(symbolTable.isGlobal(*$2)){ // class scope -> global variables
                        generator.createField(*$2, false, $4);
                    }
                    else{   // local var
                        generator.createLocalVar(*$2, index, 0);
                    }
                }
                |VAR ID ':' var_type '[' INT_CONST ']'
                {
                    Trace("Array declaration with type");
                    int index = symbolTable.insert(*$2, $4, $6);
                    if(!index) yyerror("Array redefinition");
                };

/* Predefined Variable Types */
var_type:       BOOL    { $$ = BOOL_TYPE;}
                | INT    { $$ = INT_TYPE; }
                | STRING { $$ = STRING_TYPE; }
                | FLOAT  { $$ = REAL_TYPE; };

/* Const values types */
const_val:      BOOL_CONST      { $$ = BOOLConst($1); }
                | INT_CONST     { $$ = INTConst($1); }
                | REAL_CONST    { $$ = REALConst($1); }
                | STR_CONST     { $$ = STRConst($1); };

%%
int yyerror(std::string s)
{
    cerr << "[Error at line " << (linenum + 1) << "]: " << s << endl;
    cerr << "yytext: " << yytext << endl;
    exit(1);
}

int main(int argc, char* argv[])
{
    /* open the source program file */
    if (argc != 2) {
        printf ("Prorgam usage: parser <filename>\n");
        exit(1);
    }
    yyin = fopen(argv[1], "r");         /* open input file */
    generator.setOutFile(argv[1]);
    std::cout << argv[1] << " output\n";

    /* perform parsing */
    if (yyparse() == 1){                 /* parsing */
        yyerror("Parsing error!");     /* syntax error */
        cout << yytext << endl;
    }
    return 0;
}