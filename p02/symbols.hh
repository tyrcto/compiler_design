#pragma once
#include <iostream>
#include <map>
#include <string>
#include <vector>

using namespace std;

enum type{
    BOOL_TYPE,
    INT_TYPE,
    REAL_TYPE,
    STRING_TYPE,
    ARRAY_TYPE,
    VOID_TYPE           // for function procedures
};

enum flag{
    CLASS_FLAG, 
    VAR_FLAG,
    CONST_FLAG,
    FUNCTION_FLAG
};

struct IDValue;
struct IDInfo;

struct IDValue{
    int i = 0;
    double d = 0.0;
    bool b = false;
    string s = "";
    vector<IDInfo> arr;
    string getArrDesc();
};

struct IDInfo{
    int id = 0;
    string symbol ="";
    int type = INT_TYPE;
    int flag = VAR_FLAG;
    IDValue value;
    bool init = false;
    string getDesc();
};

class SymbolTable{
    private:
        int entryCount;
        string lastSymbol;
        map<string, IDInfo> sTable;
    public:
        SymbolTable();
        IDInfo* lookup(string s);
        int insert(string s, int type, int flag, IDValue val);
        int dump();    
        void setFuncType(int type);
};

class SymbolTableList{
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

        void setFuncType(int type);
};

IDInfo *BOOLConst(bool val);
IDInfo *INTConst(int val);
IDInfo *REALConst(double val);
IDInfo *STRConst(string* val);