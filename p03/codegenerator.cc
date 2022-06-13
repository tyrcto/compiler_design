#include "codegenerator.hh"

CodeGenerator::CodeGenerator(ofstream& outRef):outFile(outRef){
    tabCount = 0;
    flag = false;
}

CodeGenerator::~CodeGenerator(){
    outFile.close();
}

void CodeGenerator::write(string str){
    if(tabCount > 0){
        for(int i=0;i<tabCount;i++)
            outFile << "\t";
    }
    outFile << str << "\n";
}

void CodeGenerator::createOutFileHeader(){
    outFile << "/*-------------------------------------------------*/\n"
                "/* \t\t\t\tJava Assembly Code\t\t\t\t */\n"
                "/*-------------------------------------------------*/\n";
}

void CodeGenerator::createClass(string name){
    if(flag) write("/* Create class */");
    write("class "+ name);
    write("{");
    addTab();
    fName = name;
}

void CodeGenerator::createMethod(string name, int returnType, vector<int> argTypes){
    if(flag) write("/* Create Method */");
    if(name == "main"){
        write("method public static void main (java.lang.String[])");
    }
    else{
        string temp = "method public static "+ typeStr[returnType] + " " + name + "(";
        for(int i=0;i<argTypes.size();i++){
            temp += typeStr[argTypes[i]];
            if(i!=argTypes.size()-1) temp += ", ";
        }
        temp += ")";
        write(temp);
    }
    write("max_stack 15");
    write("max_locals 15");
    write("{");
    addTab();
}

void CodeGenerator::endBlock(){
    subTab();
    write("}");
}

void CodeGenerator::createField(string id, bool init, int val){
    if(flag) write("/* Create global var */");
    write("field static int " + id + (init?(" = "+ to_string(val)):""));
}

void CodeGenerator::loadGlobalVar(string id){
    if(flag) write("/* Load global var */");
    write("getstatic int " + fName + "." + id);
}

void CodeGenerator::createLocalVar(string id, int scopeId, int index, bool isInit){
    if(flag) write("/* Create local var\tscope: " +to_string(scopeId)+"\tindex: " + to_string(index) +" */");
    if(!isInit) loadInt(0);
    write("istore " + to_string(index));
}

void CodeGenerator::loadLocalVar(int scopeId, int index){
    if(flag) write("/* Load local var\tscope: " +to_string(scopeId)+"\tindex: " + to_string(index) +" */");
    write("iload " +to_string(index));
}

void CodeGenerator::loadInt(int val){
    if(flag) write("/* Load Int */");
    write("sipush " + to_string(val));
}

void CodeGenerator::loadConst(int type, CGValue val){
    if(flag) write("/* Load const */");
    switch(type){
        case 0:
            write("iconst_" + to_string(val.b?1:0));
            break;
        case 1:
            loadInt(val.i);
            break;
        case 2:
            write("ldc \""+ val.s + "\"");
            break;
        default: break;
    }
}

void CodeGenerator::assignGlobal(string id){
    if(flag) write("/* Assign global var */");
    write("putstatic int "+ fName + "." + id);
}

void CodeGenerator::assignLocal(int index, int val){
    if(flag) write("/* Assign local var */");
    write("istore " +to_string(index));
}

void CodeGenerator::startPrint(){
    write("getstatic java.io.PrintStream java.lang.System.out");
}

void CodeGenerator::endPrint(int type, bool isLn){
    string s = "invokevirtual void java.io.PrintStream.print";
    if(isLn) s.append("ln");

    s.append(("("+typeStr[type]+")"));
    write(s);
}

void CodeGenerator::createRelational(string op, int labelCount){
    if(flag) write("/* Create Relational */");
    write("isub");

    string label = "Ltrue" + to_string(labelCount);

    if(op == "<"){
        write("iflt "+ label);
    }
    else if (op == "<="){
        write("ifle "+ label);
    }
    else if (op == ">"){
        write("ifgt "+ label);
    }
    else if (op == ">="){
        write("ifge "+ label);
    }
    else if (op == "=="){
        write("ifeq "+ label);
    }
    else if (op == "!="){
        write("ifne "+ label);
    }
}

void CodeGenerator::createFunInvoc(string name, int returnType, vector<int> paramTypes){
    if(flag) write("/* Create function invocation */");
    string temp = "invokestatic " + typeStr[returnType] + " " + fName + "." + name + "(";
    for(int i=0;i<paramTypes.size();i++){
        temp += typeStr[paramTypes[i]];
        if(i!=paramTypes.size()-1) temp += ", ";
    }
    temp += ")";
    write(temp);
}

void CodeGenerator::createIfStart(int labelCount){
    if(flag) write("/* Create If START */");
    write("goto Lfalse" + to_string(labelCount));
    subTab();
    write("Ltrue"+to_string(labelCount)+":");
    addTab();
}

void CodeGenerator::createIfEnd(int labelCount, bool withElse){
    if(flag) write("/* Create If END */");
    subTab();
    if(withElse)    write("Lexit" + to_string(labelCount)+":");
    else            write("Lfalse" + to_string(labelCount)+":");
    addTab();
}

void CodeGenerator::createElse(int labelCount){
    if(flag) write("/* Create else */");
    write("goto Lexit"+to_string(labelCount));
    subTab();
    write("Lfalse" + to_string(labelCount)+":");
    addTab();
}

void CodeGenerator::createWhileStart(int labelCount){
    if(flag) write("/* Create While START */");
    subTab();
    write("Lbegin" + to_string(labelCount)+":");
    addTab();
}

void CodeGenerator::createWhileMid(int labelCount){
    if(flag) write("/* Create While MID */");
    write("iconst_0");
    write("goto Lfalse" + to_string(labelCount));
    subTab();
    write("Ltrue" + to_string(labelCount)+":");
    addTab();
    write("iconst_1");
    subTab();
    write("Lfalse" + to_string(labelCount)+":");
    addTab();
    write("ifeq Lexit" + to_string(labelCount));
}

void CodeGenerator::createWhileEnd(int labelCount){
    if(flag) write("/* Create While END */");
    write("goto Lbegin" + to_string(labelCount));
    write("Lexit" + to_string(labelCount) + ":");
}

void CodeGenerator::createForStart(int scopeId, int index, int limit, int labelCount){
    if(flag) write("/* Create For START */");
    subTab();
    write("Lbegin" + to_string(labelCount) + ":");
    addTab();
    loadLocalVar(scopeId, index);
    loadInt(limit);
    write("isub");
    write("ifle Ltrue" + to_string(labelCount));
    write("iconst_0");
    write("goto Lfalse" + to_string(labelCount));
    subTab();
    write("Ltrue" + to_string(labelCount) + ":");
    addTab();
    write("iconst_1");
    subTab();
    write("Lfalse" + to_string(labelCount)+":");
    addTab();
    write("ifeq Lexit" + to_string(labelCount));
}

void CodeGenerator::createForEnd(int scopeId, int index, int labelCount){
    if(flag) write("/* Create For END */");
    loadLocalVar(scopeId, index);
    loadInt(1);                     // increment value by 1
    write("iadd");
    write("istore " + to_string(index));
    write("goto Lbegin" + to_string(labelCount));
    subTab();
    write("Lexit" + to_string(labelCount) + ":");
    addTab();
}
