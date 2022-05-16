#include "symbols.hh"

// IDValue.getArrDesc: used to get ARRAY_TYPE's contents
string IDValue::getArrDesc(){
    string s = "[";
    int arr_type = arr[0].type;
    for(int i = 0;i<arr.size();i++){
         switch(arr_type){
            case BOOL_TYPE: s+= b? "true":"false"; break;
            case INT_TYPE:  s+= to_string(i); break;
            case REAL_TYPE: s+= to_string(d); break;
            case STRING_TYPE:  s+= s; break;
            default: break;
        }
        s+=',';
    }
    s+=']';
    return s;
}

// IDInfo.getDesc: retrieve a string of ID's details
string IDInfo::getDesc(){
    string s = "";
    s+= to_string(id) + "\t" + symbol +"\t";
    switch(type){
        case BOOL_TYPE:     s+="bool\t"; break;
        case INT_TYPE:      s+="int\t"; break;
        case REAL_TYPE:     s+="real\t"; break;
        case STRING_TYPE:   s+="string\t"; break;
        case ARRAY_TYPE:    s+= string("arr:"+to_string(value.arr.size())+"\t"); break;
        case VOID_TYPE:     s+="void\t"; break;
        default: break;
    }
    
    switch(flag){
        case CLASS_FLAG:    s+="class\t"; break;
        case CONST_FLAG:    s+="const\t"; break;
        case VAR_FLAG:      s+="var\t"; break;
        case FUNCTION_FLAG: s+="func\t"; break;
        default: break;
    }
    
    if(init){   // variable value is initialized
        switch(type){
            case BOOL_TYPE: s+= value.b? "true":"false"; break;
            case INT_TYPE:  s+= to_string(value.i); break;
            case REAL_TYPE: s+= to_string(value.d); break;
            case STRING_TYPE:  s+= value.s; break;
            case ARRAY_TYPE: 
                s+= value.getArrDesc(); 
                break;
            default: break;
        }
    }
    else s+= "</>";
    return s;
}

SymbolTable::SymbolTable(){     // constructor
    entryCount = 0;
}

IDInfo* SymbolTable::lookup(string s){
    if(sTable.find(s) != sTable.end()){
        return new IDInfo(sTable[s]);
    }
    return nullptr;
}

int SymbolTable::insert(string s, int type, int flag, IDValue val, bool init){
    if(lookup(s)){
        return sTable[s].id;
    }
    else{
        symbols.push_back(s);
        sTable[s].id = entryCount;
        sTable[s].symbol = s;
        sTable[s].type = type;
        sTable[s].flag = flag;
        sTable[s].value = val;
        sTable[s].init = init;
        entryCount += 1;
        return entryCount;
    }
}

int SymbolTable::dump(){
    cout << "Table entries: " << entryCount << endl;
    cout << "<ID>\t<SYM>\t<TYPE>\t<FLAG>\t<VAL>\n";
    for(auto& entry:sTable){
        cout << entry.second.getDesc() <<endl;
    }
    return entryCount;
}

void SymbolTable::setFuncType(int type){
    sTable[symbols[symbols.size()-1]].type = type;
}

void SymbolTable::addFuncArg(string id, IDInfo info){
    sTable[symbols[symbols.size() - 1]].value.arr.push_back(info);
}

SymbolTableList::SymbolTableList(){
    top = -1;
    push();
}

void SymbolTableList::push(){
    list.push_back(SymbolTable());
    top++;
}

bool SymbolTableList::pop(){
    if(list.size() <= 0) return false;
    list.pop_back();
    top--;
    return true;
}
IDInfo* SymbolTableList::lookup(string s){
    // search through the accessible scope for wanted ID
    for(int i=top;i>=0;i--){
        if(list[i].lookup(s)) return list[i].lookup(s);
    }
    return nullptr;
}

int SymbolTableList::insert(string s, IDInfo info){
    return list[top].insert(s, info.type, info.flag, info.value, info.init);
}

int SymbolTableList::insert(string s, int type, int size){  // used to insert ARRAY_TYPE
    IDValue val;
    val.arr = vector<IDInfo>(size);
    for(int i=0;i<size;i++){
        val.arr[i].id = -1;
        val.arr[i].type = type;
        val.arr[i].flag = VAR_FLAG;
    }
    return list[top].insert(s, ARRAY_TYPE, VAR_FLAG, val, false);
}

int SymbolTableList::dump(){
    cout << "-----DUMP----\n";
    for(int i=top; i>=0;i--){
        cout << "Frame " << i << ":\n";     // scope
        list[i].dump();
    }
    cout << "-----END-----\n";
    return top;
}

void SymbolTableList::setFuncType(int type){
    list[top - 1].setFuncType(type);
}

void SymbolTableList::addFuncArg(string id, IDInfo info)
{
    list[top - 1].addFuncArg(id, info);
}

// Const values utils
IDInfo *BOOLConst(bool val){
    IDInfo* info = new IDInfo();
    info->id = 0;
    info->type = BOOL_TYPE;
    info->value.b = val;
    info->flag = CONST_FLAG;
    info->init = true;
    return info;
}
IDInfo *INTConst(int val)
{
    IDInfo* info = new IDInfo();
    info->id = 0;
    info->type = INT_TYPE;
    info->value.i = val;
    info->flag = CONST_FLAG;
    info->init = true;
    return info;
}
IDInfo *REALConst(double val){
    IDInfo* info = new IDInfo();
    info->id = 0;
    info->type = REAL_TYPE;
    info->value.d = val;
    info->flag = CONST_FLAG;
    info->init = true;
    return info;
}
IDInfo *STRConst(string* val)
{
    IDInfo* info = new IDInfo();
    info->id = 0;
    info->type = STRING_TYPE;
    info->value.s = *val;
    info->flag = CONST_FLAG;
    info->init = true;
    return info;
}