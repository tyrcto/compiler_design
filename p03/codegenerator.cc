#include "codegenerator.hh"

CodeGenerator::CodeGenerator(){
    currentFrame = 0;
}

CodeGenerator::~CodeGenerator(){
    outFile.close();
}

void CodeGenerator::setOutFile(string filename){
    string ofName;
    size_t slashPos = filename.rfind('/');
    size_t dotPos = filename.rfind('.');
    cout << "Length:" << filename.length() << "\tSlash: "<< slashPos << "\tDot: "<< dotPos << endl;
    if(slashPos != -1){
        ofName = filename.substr(slashPos+1, dotPos-slashPos-1);
    }
    else{   // no relative path
        ofName = filename.substr(0,dotPos);
    }
    outFile.open(ofName+".jasm");
    outFile << "/*-------------------------------------------------*/\n"
                "/* \t\tJava Assembly Code\t\t */\n"
                "/*-------------------------------------------------*/\n";
}

void CodeGenerator::write(string str){
    if(currentFrame > 0){
        for(int i=0;i<currentFrame;i++)
            outFile << "\t";
    }
    outFile << str << "\n";
}

void CodeGenerator::createClass(string name){
    write("class "+ name);
    write("{");
    currentFrame++;
    fName = name;
}

void CodeGenerator::endBlock(int tabCount){
    // for(int i=0;i<tabCount;i++) write("\t");
    currentFrame--;
    write("}");
}

void CodeGenerator::createMethod(string name, vector<string> paramTypes){
    if(name == "main"){
        write("method public static void " + name + "(java.lang.String[])");
    }
    else{
        write("method public static void " + name + "()");
    }
    write("max_stack 15");
    write("max_locals 15");
    write("{");
    currentFrame++;
}

void CodeGenerator::createField(string id, bool init, int val){
    write("field static int " + id + (init?(" = "+ to_string(val)):""));
}
void CodeGenerator::loadGlobalVar(string id){
    write("getstatic int " + fName + "." + id);
}
void CodeGenerator::loadLocalVar(int index){
    write("iload "+ to_string(index));
}
void CodeGenerator::createLocalVar(string id, int index, int val){
    write("sipush ");
    write(std::to_string(val));
    write("\nistore ");
    write(std::to_string(index));
    write("\n");
}

void CodeGenerator::loadConst(int type, CGValue val){
    switch(type){
        case 0:
            write("iconst_" + to_string(val.b?1:0));
            break;
        case 1:
            write("sipush " + to_string(val.i));
            break;
        case 2:
            write("ldc \""+ val.s + "\"");
            break;
        default: break;
    }
}

void CodeGenerator::assignGlobal(string id){
    write("putstatic int " + id + fName + "." + id);
}

void CodeGenerator::assignLocal(int index, int val){
    write("sipush" + to_string(val));
    write("istore " +to_string(index));
}

void CodeGenerator::endPrint(int type, bool isLn){
    string s = "invokevirtual void java.io.PrintStream.print";
    if(isLn) s.append("ln");

    switch(type){
        case 0:
            s.append("(boolean)");
            break;
        case 1:
            s.append("(int)");
            break;
        case 2:
            s.append("(java.lang.String)");
            break;
        default: break;
    }
    write(s);
}

void CodeGenerator::createConditional(string op){
    write("isub");
    
    string label = "Lfalse";

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
