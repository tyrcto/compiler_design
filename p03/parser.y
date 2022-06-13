%{
    #include "symbols.hh"
    #include "codegenerator.hh"
    #define Trace(t)        {if (trace_flag)printf("TRACE==> %s\n", t);}

    // Optional printing flags
    bool trace_flag = true;
    bool dump_flag = true;
    int currFunID = -1;         // Keeps track of function scope

    int yyerror(std::string s);
    extern int yylex();
    extern FILE *yyin;
    extern char* yytext;
    extern int linenum;
    extern ofstream outFile;
    
    vector<bool>newScope;

    SymbolTableList symbolTable;        
    vector<vector<IDInfo> > fCalls;     // used for function invocations/calls
    CodeGenerator generator(outFile);
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
%type <info> const_val expr bool_expr fun_invocation
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
                    generator.endBlock();
                };

/* 1 or Multiple Functions */
opt_fun_dec:    fun_dec opt_fun_dec
                | /* empty symbol */;

/* Function declaration*/
fun_dec:        FUN ID 
                {
                    Trace("Function declaration");
                    IDInfo* info = new IDInfo();
                    info->init = false;                 // Is function return type stated? (defaulted to false)
                    info->flag = FUNCTION_FLAG;
                    int index = symbolTable.insert(*$2, *info);
                    if(!index) yyerror("Function redefinition");
                    
                    symbolTable.push();                 // Function scope
                    currFunID++;
                }
                '(' opt_args ')' opt_ret_type
                {
                    // Create code gen for method/function with corresponding formal arguments
                    IDInfo* info = symbolTable.lookup(*$2);
                    vector<int> argTypes = info->value.getArrTypesID();
                    generator.createMethod(*$2, info->type, argTypes);

                }  block
                {
                    if(dump_flag)symbolTable.dump();
                    symbolTable.pop();

                    IDInfo* info = symbolTable.lookup(*$2);
                    if(info->type == VOID_TYPE){
                        generator.write("return");
                    }
                    generator.endBlock();
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
                    info->funScope = currFunID;

                    if(!symbolTable.insert(*$1, *info)) yyerror("Duplicate arguments");
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

loop:           WHILE  {
                    Trace("WHILE loop");
                    int label = symbolTable.addLabel(0);
                    generator.createWhileStart(label);
                    
                } '(' bool_expr ')' {
                    
                    int label = symbolTable.lookupLabel(0);
                    generator.createWhileMid(label);

                } block_or_simp_alt {
                    
                    if($4->type != BOOL_TYPE) yyerror("Expression not a boolean");
                    
                    int label = symbolTable.lookupLabel(0);
                    generator.createWhileEnd(label);
                }
                | FOR '(' ID IN INT_CONST RANGE INT_CONST')' {

                    Trace("FOR loop");

                    IDInfo* info = new IDInfo();
                    info->type = INT_TYPE;
                    info->flag = VAR_FLAG;
                    info->value.i = $5;
                    info->funScope = currFunID;

                    if(!symbolTable.insert(*$3, *info)) yyerror("Variable redefinition");
                    int index = symbolTable.lookup(*$3)->funId;

                    int label = symbolTable.addLabel(0);
                    // init for loop increment variable to $5
                    generator.loadInt($5);
                    generator.createLocalVar(*$3, currFunID, index, true);
                    generator.createForStart(currFunID, index, $7, label);

                } block_or_simp_alt{

                    if($5 > $7) yyerror("Loop range is in descending order");
                    int index = symbolTable.lookup(*$3)->funId;

                    int label = symbolTable.lookupLabel(0);
                    generator.createForEnd(currFunID, index, label);
                };

/* Alternative option for Loop blocks */
block_or_simp_alt:      /* empty */
                {
                    Trace("Enter for scope");
                    newScope.push_back(true);
                    symbolTable.push();             // New scope
                } block_or_simp 
                {
                    Trace("Leaving for scope");
                    symbolTable.pop();
                    newScope.pop_back();
                };

conditional:    IF if_start1 '(' bool_expr ')' if_start2
                block_or_simp_alt ELSE 
                {
                    int label = symbolTable.lookupLabel(0);
                    generator.createElse(label);
                    
                } block_or_simp_alt
                {
                    int label = symbolTable.lookupLabel(0);
                    generator.createIfEnd(label, true);
                    Trace("IF-ELSE block");
                    if($4->type != BOOL_TYPE) yyerror("Expression not a boolean");
                }
                | IF if_start1 '(' bool_expr ')' if_start2 block_or_simp_alt
                {
                    int label = symbolTable.lookupLabel(0);
                    generator.createIfEnd(label, false);
                    Trace("IF block");
                    if($4->type != BOOL_TYPE) yyerror("Expression not a boolean");
                };

if_start1:       /* empty: Add label first before using it */
                {
                    int label = symbolTable.addLabel(0);
                };

if_start2:      /* empty */
                {
                    int label = symbolTable.lookupLabel(0);
                    generator.createIfStart(label);
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
                    generator.startPrint();
                } expr { generator.endPrint($3->type, false); 
                }
                | PRINTLN 
                {
                    Trace("Simple: Println expression");
                    generator.startPrint();
                } expr { generator.endPrint($3->type, true); 
                }
                | RETURN
                {
                    Trace("Simple: Return");
                    generator.write("return");
                }
                | RETURN expr    
                {
                    Trace("Simple: Return expression");
                    if(!symbolTable.checkFuncType($2->type)) yyerror("Return type does not match function return type");
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

                    // Check whether num of arguments is equal
                    vector<IDInfo> args = info->value.arr;
                    if(args.size() != fCalls[fCalls.size()-1].size()) yyerror("Number of arguments do not match");
                    for(int i=0;i< args.size();i++){
                        if(args[i].type != fCalls[fCalls.size()-1].at(i).type) yyerror("Argument types do not match");
                    }
                    $$ = info;
                    fCalls.pop_back();

                    vector<int> argTypes = info->value.getArrTypesID();
                    generator.createFunInvoc(info->symbol, info->type, argTypes);   // ID, return type, params
                };

/* Optional comma separated function expressions as arguments */
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
                    $$ = $1;
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
                        else generator.loadLocalVar(info->funScope, info->funId);
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
                | bool_expr
                | '(' expr ')'
                {
                    Trace("(Expression) in parentheses");
                    $$ = $2;
                };

bool_expr:      expr '<' expr
                {
                    Trace("Expression < Expression");
                    
                    if($1->type != $3->type) yyerror("Expression types incompatible");
                    if(!($1->type == INT_TYPE || $1->type == REAL_TYPE)) yyerror("Operator error");

                    IDInfo *info = new IDInfo();
                    info->type = BOOL_TYPE;
                    $$ = info;

                    // Boolean expression code generation
                    int label = symbolTable.lookupLabel(0);
                    generator.createRelational("<", label);

                }
                | expr LE expr
                {
                    Trace("Expression <= Expression");

                    if($1->type != $3->type) yyerror("Expression types incompatible");
                    if(!($1->type == INT_TYPE || $1->type == REAL_TYPE)) yyerror("Operator error");

                    IDInfo *info = new IDInfo();
                    info->type = BOOL_TYPE;
                    $$ = info;

                    int label = symbolTable.lookupLabel(0);
                    generator.createRelational("<=", label);

                }
                | expr '>' expr
                {
                    Trace("Expression > Expression");
                    if($1->type != $3->type) yyerror("Expression types incompatible");
                    if(!($1->type == INT_TYPE || $1->type == REAL_TYPE)) yyerror("Operator error");

                    IDInfo *info = new IDInfo();
                    info->type = BOOL_TYPE;
                    $$ = info;

                    int label = symbolTable.lookupLabel(0);
                    generator.createRelational(">", label);
                }
                | expr GE expr
                {
                    Trace("Expression >= Expression");
                    if($1->type != $3->type) yyerror("Expression types incompatible");
                    if(!($1->type == INT_TYPE || $1->type == REAL_TYPE)) yyerror("Operator error");

                    IDInfo *info = new IDInfo();
                    info->type = BOOL_TYPE;
                    $$ = info;

                    int label = symbolTable.lookupLabel(0);
                    generator.createRelational(">=", label);
                }
                | expr EQ expr
                {
                    Trace("Expression == Expression");
                    if($1->type != $3->type) yyerror("Expression types incompatible");

                    IDInfo *info = new IDInfo();
                    info->type = BOOL_TYPE;
                    $$ = info;

                    int label = symbolTable.lookupLabel(0);
                    generator.createRelational("==", label);
                }
                | expr NEQ expr
                {
                    Trace("Expression != Expression");
                    if($1->type != $3->type) yyerror("Expression types incompatible");

                    IDInfo *info = new IDInfo();
                    info->type = BOOL_TYPE;
                    $$ = info;

                    int label = symbolTable.lookupLabel(0);
                    generator.createRelational("!=", label);
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
                };

/* Block statement */
block:          '{' 
                {
                    Trace("Block statement start");
                    if(newScope.size()>0 && !newScope[newScope.size()-1]) 
                        symbolTable.push();             // Block scope

                }
                opt_var_dec opt_statement '}'       // Can have any number of variable/const declarations and/or statements
                {
                    Trace("Block statement end");
                    
                    if(newScope.size()>0 && !newScope[newScope.size()-1]) {
                        if(dump_flag)symbolTable.dump();
                        symbolTable.pop();              // Leave block scope
                    }
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
                    info->funScope = currFunID;

                    int index = symbolTable.insert(*$2, *info);
                    if(!index) yyerror("Variable redefinition");
                    
                    if(symbolTable.isGlobal(*$2)){ // class scope -> global variables
                        generator.createField(*$2, false);
                    }
                    else{   // local var
                        int lookupId = symbolTable.lookup(*$2)->funId;
                        generator.createLocalVar(*$2, currFunID, lookupId, false);
                    }
                }
                |VAR ID '=' expr
                {
                    Trace("Variable declaration with assignment (either from const/expression)");
                    $4->flag = VAR_FLAG;
                    $4->funScope = currFunID;

                    int index = symbolTable.insert(*$2, *$4);
                    if(!index) yyerror("Variable redefinition");
                    if(symbolTable.isGlobal(*$2)){ // class scope -> global variables
                        generator.createField(*$2, false);
                    }
                    else{   // local var
                        int lookupId = symbolTable.lookup(*$2)->funId;
                        generator.createLocalVar(*$2, currFunID, lookupId, true);
                    }
                }
                |VAR ID  ':' var_type '=' expr
                {
                    Trace("Variable declaration with type and assignment");
                    if($6->type != $4) yyerror("Wrong declared type");
                    $6->flag = VAR_FLAG;
                    $6->funScope = currFunID;

                    int index = symbolTable.insert(*$2, *$6);
                    if(!index) yyerror("Variable redefinition");
                   
                    if(symbolTable.isGlobal(*$2)){ // class scope -> global variables
                        generator.createField(*$2, false, $4);
                    }
                    else{   // local var
                        int lookupId = symbolTable.lookup(*$2)->funId;
                        generator.createLocalVar(*$2, currFunID, lookupId, true);
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

string getOutFilename(string filepath){
    string ofName;
    size_t slashPos = filepath.rfind('/');
    size_t dotPos = filepath.rfind('.');

    if(slashPos != -1){
        ofName = filepath.substr(slashPos+1, dotPos-slashPos-1);
    }
    else{   // no relative path
        ofName = filepath.substr(0,dotPos);
    }
    return (ofName+".jasm");
}

int main(int argc, char* argv[])
{
    /* open the source program file */
    if (argc != 2) {
        printf ("Prorgam usage: parser <filename>\n");
        exit(1);
    }
    yyin = fopen(argv[1], "r");         /* open input file */
    
    outFile.open(getOutFilename(argv[1]));
    generator.createOutFileHeader();    

    /* perform parsing */
    if (yyparse() == 1){                 /* parsing */
        yyerror("Parsing error!");     /* syntax error */
        cout << yytext << endl;
    }
    return 0;
}