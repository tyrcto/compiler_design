#pragma once
#ifndef SYMBOL_H
#define SYMBOL_H
#include<iostream>
#include<string>
#include<vector>

// Namespace
using namespace std;

// Type
// #define ERROR -1
 #define NON 0
// #define VAR_BOOL 1
// #define VAR_INT 2
// #define VAR_FLOAT 3
// #define VAR_STRING 4
// #define CONST_BOOL 5
// #define CONST_INT 6
// #define CONST_FLOAT 7
// #define CONST_STRING 8
// #define ARRAY_BOOL 9
// #define ARRAY_INT 10
// #define ARRAY_FLOAT 11
// #define ARRAY_STRING 12
// #define FUNC_BOOL 13
// #define FUNC_INT 14
// #define FUNC_FLOAT 15
// #define FUNC_STRING 16
// #define FUNC_NON 17

class Symbol {
    public:
        Symbol();
        Symbol(string, int);
        void insertArg(int);
        string name;
        int type;
        vector<int> argumentType;
        
};

class SymbolTable {
    public:
        SymbolTable();
        SymbolTable(string, SymbolTable*);
        Symbol* globalLookup(string);
        Symbol* localLookup(string);
        void insert(string, int);
        vector<Symbol*> table;
        SymbolTable *parentTable;
        string name;
        int returnType;
        bool hasReturn;
        int localValueIndex;
};
#endif //SYMBOL_H