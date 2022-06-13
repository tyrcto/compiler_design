/* Util header file for Symbol Table */
#pragma once
#include <iostream>
#include <map>
#include <string>
#include <vector>
#include <algorithm>

using namespace std;

// Data types
enum type{
    BOOL_TYPE,
    INT_TYPE,
    STRING_TYPE,
    VOID_TYPE ,          // for function procedures  (not return type)
    REAL_TYPE,
    ARRAY_TYPE
};

// Variable types
enum flag{
    CLASS_FLAG, 
    FUNCTION_FLAG,
    VAR_FLAG,
    CONST_FLAG
};

struct IDValue;
struct IDInfo;

struct IDValue{
    int i = 0;              // integer val
    double d = 0.0;         // real val
    bool b = false;         // boolean val
    string s = "";          // string val
    vector<IDInfo> arr;     // array val
    string getArrDesc();    // output
    vector<int> getArrTypesID();
};

struct IDInfo{
    int id = 0;             
    int funId = 0;          // ID in its function scope (for code generator)
    string symbol ="";      // symbol name
    int type = INT_TYPE;    // data type
    int flag = VAR_FLAG;    // variable type
    IDValue value;          // value of var
    bool init = false;      // is value assigned to it?
    int scope = -1;         // block scope in which it is defined
    int funScope = -1;
    string getDesc();       // output

};

static map<int, int> funVarCount;       // function variable count

class LabelController{
    private:
        map<int, vector<int>> activeLabel;
        vector<int> usedLabel;
        int last;
    public:
        LabelController();
        bool checkLabel(int label);
        bool checkScope(int scopeId);
        int lookup(int scopeId);
        int add(int scopeId);
        void print();
};

class SymbolTable{
    // Symbol table per scope
    private:
        int entryCount;
        vector<string> symbols;
        map<string, IDInfo> sTable;

    public:
        SymbolTable();
        IDInfo* lookup(string s);
        int insert(string s, int type, int flag, IDValue val, bool init, int scope, int funScope);
        int dump();    
        
        // Function Utils
        void setFuncType(int type);                 // set current pointed function return type, return false if type was defined
        bool checkFuncType(int type);
        void addFuncArg(string id, IDInfo info);    // add necessary args to said function
};

class SymbolTableList{
    // Overall symbol table
    private:
        vector<SymbolTable> list;
        int top;
        LabelController label;
        
    public:
        SymbolTableList();
        IDInfo* lookup(string s);
        int insert(string s, IDInfo info);
        int insert(string s, int type, int size);
        int dump();
        void push();
        bool pop();
        bool isGlobal(string id);

        // Function Utils (pass over parameters to desired scope)
        void setFuncType(int type);             // return false if type was defined
        bool checkFuncType(int type);
        void addFuncArg(string id, IDInfo info);

        int lookupLabel(int scope);
        int addLabel(int scope);
};

// More utils for converting constant values
IDInfo *BOOLConst(bool val);
IDInfo *INTConst(int val);
IDInfo *REALConst(double val);
IDInfo *STRConst(string* val);