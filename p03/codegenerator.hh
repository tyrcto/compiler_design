#pragma once
#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <map>

using namespace std;

struct CGValue{
    bool b = false;         // boolean val
    int i = 0;              // integer val
    string s = "";          // string val
    CGValue(bool nb, int ni, string ns): b(nb), i(ni), s(ns){ }
};

const string typeStr[] = {
    "boolean", 
    "int", 
    "java.lang.String", 
    "void" 
};

class CodeGenerator{
    private:
        ofstream& outFile;
        string fName;
        int tabCount;
        bool flag;

    public:
        CodeGenerator(ofstream& outRef);
        ~CodeGenerator();
        
        void write(string str);
        void createOutFileHeader();

        inline void addTab(){ tabCount++; }
        inline void subTab(){ tabCount--; }

        void createClass(string className);
        void createMethod(string methodName, int returnType, vector<int> paramTypes);
        
        void endBlock();

        void createField(string id,bool init, int val=0);
        void loadGlobalVar(string id);

        void createLocalVar(string id, int scopeId, int index, bool isInit);
        void loadLocalVar(int scopeId, int index);

        void createFormalArg(int scopeId, int index);

        void loadInt(int val);
        void loadConst(int type, CGValue val);

        // value assignments
        void assignGlobal(string id);        
        void assignLocal(int index, int val);        

        void startPrint();
        void endPrint(int type, bool isLn);
        
        void createRelational(string op, int labelCount);
        void createFunInvoc(string name, int returnType, vector<int> paramTypes);

        void createIfStart(int labelCount);
        void createIfEnd(int labelCount, bool withElse);
        void createElse(int labelCount);

        void createWhileStart(int labelCount);
        void createWhileMid(int labelCount);
        void createWhileEnd(int labelCount);

        void createForStart(int scopeId, int index, int limit, int labelCount);
        void createForEnd(int scopeId, int index, int labelCount);
};
