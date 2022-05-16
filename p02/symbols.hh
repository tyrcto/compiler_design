/* Util header file for Symbol Table */
#pragma once
#include <iostream>
#include <map>
#include <string>
#include <vector>

using namespace std;

// Data types
enum type{
    BOOL_TYPE,
    INT_TYPE,
    REAL_TYPE,
    STRING_TYPE,
    ARRAY_TYPE,
    VOID_TYPE           // for function procedures  (not return type)
};

// Variable types
enum flag{
    CLASS_FLAG, 
    VAR_FLAG,
    CONST_FLAG,
    FUNCTION_FLAG
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
};

struct IDInfo{
    int id = 0;             
    string symbol ="";      // symbol name
    int type = INT_TYPE;    // data type
    int flag = VAR_FLAG;    // variable type
    IDValue value;          // value of var
    bool init = false;      // is value assigned to it?
    string getDesc();       // output
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
        int insert(string s, int type, int flag, IDValue val, bool init);
        int dump();    
        
        // Function Utils
        void setFuncType(int type);                 // set current pointed function return type
        void addFuncArg(string id, IDInfo info);    // add necessary args to said function
};

class SymbolTableList{
    // Overall symbol table
    private:
        vector<SymbolTable> list;
        int top;
    public:
        SymbolTableList();
        IDInfo* lookup(string s);
        int insert(string s, IDInfo info);
        int insert(string s, int type, int size);
        int dump();
        void push();
        bool pop();

        // Function Utils (pass over parameters to desired scope)
        void setFuncType(int type);
        void addFuncArg(string id, IDInfo info);
};

// More utils for converting constant values
IDInfo *BOOLConst(bool val);
IDInfo *INTConst(int val);
IDInfo *REALConst(double val);
IDInfo *STRConst(string* val);