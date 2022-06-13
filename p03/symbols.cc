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

vector<int> IDValue::getArrTypesID(){
    vector<int> types;
    cout << "Num of formal params: " << arr.size() << endl;
    for(auto&a:arr){
        types.push_back(a.type);
    }
    return types;
}

// IDInfo.getDesc: retrieve a string of ID's details
string IDInfo::getDesc(){
    string s = "";
    s+= to_string(id) + "\t" + to_string(funId) + "\t" + symbol +"\t";
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
    s += "\t" + to_string(scope) + "\t" + to_string(funScope);  
    return s;
}

// Symbol Table
SymbolTable::SymbolTable(){     // constructor
    entryCount = 0;
}

IDInfo* SymbolTable::lookup(string s){
    if(sTable.find(s) != sTable.end()){
        return new IDInfo(sTable[s]);
    }
    return nullptr;
}

int SymbolTable::insert(string s, int type, int flag, IDValue val, bool init, int scope, int funScope){
    if(lookup(s)){
        return sTable[s].id;
    }
    else{
        symbols.push_back(s);
        sTable[s].id = entryCount;
        sTable[s].funId = funVarCount[funScope];
        sTable[s].symbol = s;
        sTable[s].type = type;
        sTable[s].flag = flag;
        sTable[s].value = val;
        sTable[s].init = init;
        sTable[s].scope = scope;
        sTable[s].funScope = funScope;
        cout << ">Insert:\n" << sTable[s].getDesc() << endl;
        localVarCount += 1;
        entryCount += 1;
        return entryCount;
    }
}

int SymbolTable::dump(){
    cout << "Table entries: " << entryCount << endl;
    if(entryCount)
        cout << "<ID>\t<FID>\t<SYM>\t<TYPE>\t<FLAG>\t<VAL>\t<SCOPE>\t<FSCOPE>\n";
    for(auto& entry:sTable){
        cout << entry.second.getDesc() <<endl;
    }
    return entryCount;
}

void SymbolTable::setFuncType(int type){
    IDInfo *check = &sTable[symbols[symbols.size()-1]];
    if(!check->init){
        check->type = type;
        check->init = true;
        cout << "not\n";
    }
}

bool SymbolTable::checkFuncType(int type){
    IDInfo *check = &sTable[symbols[symbols.size()-1]];
    if(check->type != type) return false;
    return true;
}

void SymbolTable::addFuncArg(string id, IDInfo info){
    sTable[symbols[symbols.size() - 1]].value.arr.push_back(info);
}

// Symbol Table List
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
        if(list[i].lookup(s)){ 
            cout << ">Lookup:\n" << list[i].lookup(s)->getDesc() << endl;
            return list[i].lookup(s);
        }
    }
    return nullptr;
}

bool sortScope(const IDInfo* a, const IDInfo* b){return a->scope > b->scope;}

bool SymbolTableList::isGlobal(string id){
    vector<IDInfo*> searchList;
    for(int i=top;i>=0;i--){
        IDInfo* temp = list[i].lookup(id);
        if(temp && temp->flag != CONST_FLAG)    // all var from all scopes
            searchList.push_back(temp);
    }
    if(searchList.size() == 0) return false;
    if(searchList.size() == 1) return (searchList[0]->scope == 1)?true: false;  
    else {
        cout << "Var from all scopes\nBefore sorting\n";
         for(auto& s: searchList){
            cout << s->getDesc() << endl;
        }
        sort(searchList.begin(), searchList.end(), sortScope);
        cout << "After sorting\n";
        for(auto& s: searchList){
            cout << s->getDesc() << endl;
        }
        if(searchList[0]->scope == 1)return true;
        return false;
    }
}

int SymbolTableList::insert(string s, IDInfo info){
    if(funVarCount.find(info.funScope) == funVarCount.end()){   // if current function scope has not been recorded
        funVarCount[info.funScope] = 0;
    }
    else{
        funVarCount[info.funScope] = funVarCount[info.funScope]+1;
    }
    cout << "Function var count\nFunID\tCount\n";
    for(auto&v :funVarCount){
        cout << v.first << "\t" << v.second <<endl;
    }
    return list[top].insert(s, info.type, info.flag, info.value, info.init, top, info.funScope);
}

int SymbolTableList::insert(string s, int type, int size){  // used to insert ARRAY_TYPE
    IDValue val;
    val.arr = vector<IDInfo>(size);
    for(int i=0;i<size;i++){
        val.arr[i].id = -1;
        val.arr[i].type = type;
        val.arr[i].flag = VAR_FLAG;
    }
    return list[top].insert(s, ARRAY_TYPE, VAR_FLAG, val, false, top, top);
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

bool SymbolTableList::checkFuncType(int type){
    return list[top - 1].checkFuncType(type);
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

int SymbolTableList::lookupLabel(int scope){
    cout << "current frame: "<< top << endl;
    return label.lookup(top);
}
int SymbolTableList::addLabel(int scope){
    cout << "current frame: "<< top << endl;
    return label.add(top);
}

LabelController::LabelController(){
    last = 0;
}

bool LabelController::checkLabel(int label){
    for(auto& scope: activeLabel){
        for(auto& sLabel:scope.second){
            if(sLabel == label)
                return true;
        }
    }
    return false;
}

bool LabelController::checkScope(int scopeId){
    if(activeLabel.find(scopeId) != activeLabel.end()) return true;
    return false;
}

int LabelController::lookup(int scopeId){
    if(checkScope(scopeId))return activeLabel[scopeId][activeLabel[scopeId].size()-1];
    cout << "Lookup Label error\tScope: " << scopeId << "\tlast: " << last << endl;
    print();
    return -1;
}

int LabelController::add(int scopeId){
    cout << "Add label: "<< scopeId << ", " << last << endl; 
    activeLabel[scopeId].push_back(last);
    last++;
    print();
    return last-1;
    // cout << "Add Label error\tScope: " << scopeId << "\tlast: " << last << endl;
}

void LabelController::print(){
    cout << "Label info:\n";
    for(auto&scope :activeLabel){
        for(auto& label:scope.second){
            cout << scope.first << ": " << label << endl;
        }
    }
}