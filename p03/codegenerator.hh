#pragma once
#include <iostream>
#include <fstream>
#include <string>
#include <vector>

using namespace std;

struct CGValue{
    bool b = false;         // boolean val
    int i = 0;              // integer val
    string s = "";          // string val
    CGValue(bool nb, int ni, string ns): b(nb), i(ni), s(ns){ 
    }
};

class CodeGenerator{
    private:
        ofstream outFile;
        string fName;
        int currentFrame;
    public:
        CodeGenerator();
        ~CodeGenerator();
        void setOutFile(string filename);
        void write(string str);

        inline void addFrame(){currentFrame++;}
        inline void subFrame(){currentFrame--;}

        void createClass(string className);
        void endBlock(int tabCount);
        void createMethod(string methodName, vector<string> paramTypes);
        void createBlock();
        void createField(string id,bool init, int val=0);

        void loadGlobalVar(string id);
        void loadLocalVar(int index);

        void createLocalVar(string id, int index, int val);

        void loadConst(int type, CGValue val);

        void assignGlobal(string id);        
        void assignLocal(int index, int val);        

        void endPrint(int type, bool isLn);
        void createConditional(string op);
};