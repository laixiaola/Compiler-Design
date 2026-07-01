%{
#include <stdio.h>
#include <stdlib.h>
#include "tree.h"
#include "symtab.h"  // 添加符号表头文件

extern int yylex();
extern int yyparse();
void yyerror(char* msg);
treeNode* root=NULL;
int WRONG=0;

// 辅助函数：从语法树节点获取类型信息
BasicType get_type_from_specifier(treeNode* spec);
char* get_id_from_node(treeNode* node);
int get_int_from_node(treeNode* node);
%}

%locations
%union{
    treeNode* type_node;
}

%token <type_node> SEMI COMMA RELOP ASSIGNOP PLUS MINUS STAR DIV AND OR DOT NOT TYPE LP RP LB RB LC RC STRUCT RETURN IF ELSE WHILE ID LOWER_THAN_ELSE INT FLOAT 

%type <type_node> Program ExtDefList Def ExtDef Specifier ExtDecList FunDec CompSt VarDec OptTag DefList Tag
%type <type_node> StructSpecifier VarList ParamDec StmtList Stmt DecList Dec Exp Args

%right ASSIGNOP 
%left OR
%left AND 
%left RELOP 
%left PLUS MINUS 
%left STAR DIV 
%right NOT UMINUS
%left LP RP LB RB DOT 
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

Program
    : ExtDefList {
        $$ = createNode("Program");
        root = $$;
        $$->firstchild = $1;
        @$ = @1;
        $$->line = @1.first_line;
        
        // 程序结束时打印符号表
        symtab_print();
    }
    ;

ExtDefList
    : ExtDef ExtDefList {
        $$ = createNode("ExtDefList");
        $$->firstchild = $1;
        if($1) $1->rightbrother = $2;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | {
        $$ = NULL;
    }
    ;

ExtDef
    : Specifier ExtDecList SEMI {
        $$ = createNode("ExtDef");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        if($2) $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
        
        // 处理全局变量声明
        BasicType b_type = get_type_from_specifier($1);
        treeNode* extDecList = $2;
        while(extDecList) {
            treeNode* varDec = extDecList->firstchild;
            if(varDec) {
                // 获取变量名
                treeNode* idNode = varDec->firstchild;
                if(idNode && idNode->istoken && strcmp(idNode->name, "ID") == 0) {
                    char* varName = idNode->id;
                    // 检查是否为函数（全局变量不能是函数）
                    Symbol* existing = sym_lookup(varName);
                    if(existing && existing->kind == SYM_FUNC) {
                        fprintf(stderr, "Error type D at Line %d: Variable '%s' conflicts with function\n", 
                                varDec->line, varName);
                        WRONG = 1;
                    } else {
                        Symbol* sym = sym_insert(varName, SYM_VAR, b_type, varDec->line);
                        if(sym && varDec->firstchild->rightbrother) {
                            // 检查是否为数组
                            int dim = 0;
                            treeNode* child = varDec->firstchild->rightbrother;
                            while(child && child->name && strcmp(child->name, "LB") == 0) {
                                dim++;
                                child = child->rightbrother;
                            }
                            if(dim > 0) {
                                sym_set_array_dim(sym, dim);
                            }
                        }
                    }
                }
            }
            extDecList = extDecList->rightbrother;
        }
    }
    | Specifier SEMI {
        $$ = createNode("ExtDef");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | Specifier FunDec CompSt {
        $$ = createNode("ExtDef");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
        
        // 处理函数定义
        BasicType return_type = get_type_from_specifier($1);
        treeNode* funDec = $2;
        if(funDec) {
            treeNode* idNode = funDec->firstchild;
            if(idNode && idNode->istoken && strcmp(idNode->name, "ID") == 0) {
                char* funcName = idNode->id;
                
                // 检查是否已存在同名符号
                Symbol* existing = sym_lookup(funcName);
                if(existing) {
                    fprintf(stderr, "Error type D at Line %d: Function '%s' redefined\n", 
                            idNode->line, funcName);
                    WRONG = 1;
                } else {
                    // 进入函数作用域
                    enter_func();
                    
                    // 插入函数符号
                    Symbol* funcSym = sym_insert(funcName, SYM_FUNC, return_type, idNode->line);
                    
                    // 处理参数
                    treeNode* varList = funDec->firstchild->rightbrother->rightbrother;
                    if(varList && varList->firstchild) {
                        treeNode* paramDec = varList->firstchild;
                        while(paramDec) {
                            treeNode* specifier = paramDec->firstchild;
                            treeNode* varDec = specifier ? specifier->rightbrother : NULL;
                            if(specifier && varDec) {
                                BasicType param_type = get_type_from_specifier(specifier);
                                treeNode* idNode2 = varDec->firstchild;
                                if(idNode2 && idNode2->istoken && strcmp(idNode2->name, "ID") == 0) {
                                    func_add_param(funcSym, param_type, idNode2->id);
                                }
                            }
                            paramDec = paramDec->rightbrother;
                        }
                    }
                    
                    // 处理函数体（在CompSt中处理局部变量声明）
                    // 注意：CompSt已经在下面处理
                    
                    // 退出函数作用域
                    leave_func();
                }
            }
        }
    }
    | Specifier ExtDecList error
    {
        fprintf(stderr,"Error type B at Line %d: Missing \";\"\n",@2.last_line);
        yyerrok;
        WRONG=1;
        $$ = createNode("ExtDef");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $$->line = @1.first_line;
    }
    | Specifier error
    {
        fprintf(stderr,
            "Error type B at Line %d: Missing \";\"\n",
            @1.last_line);
        yyerrok;
        WRONG=1;
        $$ = createNode("ExtDef");
        $$->firstchild = $1;
        $$->line = @1.first_line;
    }
    ;

ExtDecList
    : VarDec {
        $$ = createNode("ExtDecList");
        $$->firstchild = $1;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | VarDec COMMA ExtDecList {
        $$ = createNode("ExtDecList");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        if($3) $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
    }
    ;

Specifier
    : TYPE {
        $$ = createNode("Specifier");
        $$->firstchild = $1;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | StructSpecifier {
        $$ = createNode("Specifier");
        $$->firstchild = $1;
        @$ = @1;
        $$->line = @1.first_line;
    }
    ;

StructSpecifier
    : STRUCT OptTag LC DefList RC {
        $$ = createNode("StructSpecifier");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        if($2) $2->rightbrother = $3;
        $3->rightbrother = $4;
        if($4) $4->rightbrother = $5;
        @$ = @1;
        $$->line = @1.first_line;
        
        // 处理结构体定义
        char* structName = NULL;
        if($2 && $2->firstchild) {
            treeNode* idNode = $2->firstchild;
            if(idNode && idNode->istoken && strcmp(idNode->name, "ID") == 0) {
                structName = idNode->id;
            }
        }
        
        // 如果是命名结构体，插入符号表
        if(structName) {
            Symbol* existing = sym_lookup(structName);
            if(existing && existing->kind == SYM_STRUCT) {
                fprintf(stderr, "Error type D at Line %d: Struct '%s' redefined\n", 
                        $2->line, structName);
                WRONG = 1;
            } else {
                Symbol* structSym = sym_insert(structName, SYM_STRUCT, TYPE_STRUCT, $2->line);
                
                // 处理结构体成员
                if(structSym && $4) {
                    treeNode* defList = $4;
                    while(defList) {
                        treeNode* def = defList->firstchild;
                        if(def) {
                            treeNode* specifier = def->firstchild;
                            treeNode* decList = specifier ? specifier->rightbrother : NULL;
                            if(specifier && decList) {
                                BasicType member_type = get_type_from_specifier(specifier);
                                treeNode* dec = decList->firstchild;
                                while(dec) {
                                    treeNode* varDec = dec->firstchild;
                                    if(varDec) {
                                        treeNode* idNode2 = varDec->firstchild;
                                        if(idNode2 && idNode2->istoken && strcmp(idNode2->name, "ID") == 0) {
                                            struct_add_member(structSym, member_type, idNode2->id, idNode2->line);
                                        }
                                    }
                                    dec = dec->rightbrother;
                                }
                            }
                        }
                        defList = defList->rightbrother;
                    }
                }
            }
        }
    }
    | STRUCT Tag {
        $$ = createNode("StructSpecifier");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        @$ = @1;
        $$->line = @1.first_line;
        
        // 处理结构体引用
        if($2 && $2->firstchild) {
            treeNode* idNode = $2->firstchild;
            if(idNode && idNode->istoken && strcmp(idNode->name, "ID") == 0) {
                Symbol* structSym = sym_lookup(idNode->id);
                if(!structSym || structSym->kind != SYM_STRUCT) {
                    fprintf(stderr, "Error type D at Line %d: Undefined struct '%s'\n", 
                            idNode->line, idNode->id);
                    WRONG = 1;
                }
            }
        }
    }
    ;

OptTag
    : ID {
        $$ = createNode("OptTag");
        $$->firstchild = $1;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | {
        $$ = NULL;
    }
    ;

Tag
    : ID {
        $$ = createNode("Tag");
        $$->firstchild = $1;
        @$ = @1;
        $$->line = @1.first_line;
    }
    ;

VarDec
    : ID {
        $$ = createNode("VarDec");
        $$->firstchild = $1;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | VarDec LB INT RB {
        $$ = createNode("VarDec");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        $3->rightbrother = $4;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | VarDec LB INT error
    {
        fprintf(stderr,
            "Error type B at Line %d: Missing \"]\"\n",
            @3.last_line);

        yyerrok;
        WRONG=1;

        $$ = createNode("VarDec");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        $$->line = @1.first_line;
    }
    ;

FunDec
    : ID LP VarList RP {
        $$ = createNode("FunDec");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        if($3) $2->rightbrother = $3;
        if($3) $3->rightbrother = $4;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | ID LP RP {
        $$ = createNode("FunDec");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
    }
    ;

VarList
    : ParamDec {
        $$ = createNode("VarList");
        $$->firstchild = $1;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | ParamDec COMMA VarList {
        $$ = createNode("VarList");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        if($3) $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
    }
    ;

ParamDec
    : Specifier VarDec {
        $$ = createNode("ParamDec");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        @$ = @1;
        $$->line = @1.first_line;
    }
    ;

CompSt
    : LC DefList StmtList RC {
        $$ = createNode("CompSt");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        if($2) $2->rightbrother = $3;
        if($3) $3->rightbrother = $4;
        @$ = @1;
        $$->line = @1.first_line;
        
        // 处理局部变量声明（在函数体内）
        if(in_func_scope()) {
            treeNode* defList = $2;
            while(defList) {
                treeNode* def = defList->firstchild;
                if(def) {
                    treeNode* specifier = def->firstchild;
                    treeNode* decList = specifier ? specifier->rightbrother : NULL;
                    if(specifier && decList) {
                        BasicType var_type = get_type_from_specifier(specifier);
                        treeNode* dec = decList->firstchild;
                        while(dec) {
                            treeNode* varDec = dec->firstchild;
                            if(varDec) {
                                treeNode* idNode = varDec->firstchild;
                                if(idNode && idNode->istoken && strcmp(idNode->name, "ID") == 0) {
                                    // 局部变量插入符号表
                                    Symbol* existing = sym_lookup(idNode->id);
                                    if(existing) {
                                        fprintf(stderr, "Error type D at Line %d: Variable '%s' redefined\n", 
                                                idNode->line, idNode->id);
                                        WRONG = 1;
                                    } else {
                                        Symbol* sym = sym_insert(idNode->id, SYM_VAR, var_type, idNode->line);
                                        if(sym && varDec->firstchild->rightbrother) {
                                            int dim = 0;
                                            treeNode* child = varDec->firstchild->rightbrother;
                                            while(child && child->name && strcmp(child->name, "LB") == 0) {
                                                dim++;
                                                child = child->rightbrother;
                                            }
                                            if(dim > 0) {
                                                sym_set_array_dim(sym, dim);
                                            }
                                        }
                                    }
                                }
                            }
                            dec = dec->rightbrother;
                        }
                    }
                }
                defList = defList->rightbrother;
            }
        }
    }
    ;

StmtList
    : Stmt StmtList {
        $$ = createNode("StmtList");
        $$->firstchild = $1;
        if($2) $1->rightbrother = $2;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | {
        $$ = NULL;
    }
    ;

Stmt
    : Exp SEMI {
        $$ = createNode("Stmt");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        @$ = @1;
        $$->line = @1.first_line;
        
        // 表达式语句类型检查
        // 这里可以添加表达式的类型检查逻辑
    }
    | CompSt {
        $$ = createNode("Stmt");
        $$->firstchild = $1;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | RETURN Exp SEMI {
        $$ = createNode("Stmt");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
        
        // 检查return语句类型
        // 需要获取当前函数的返回类型进行比较
    }
    | IF LP Exp RP Stmt %prec LOWER_THAN_ELSE {
        $$ = createNode("Stmt");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        $3->rightbrother = $4;
        $4->rightbrother = $5;
        @$ = @1;
        $$->line = @1.first_line;
        
        // 检查条件表达式必须是int类型
        // check_logic_cond(exp_type, @3.first_line);
    }
    | IF LP Exp RP Stmt ELSE Stmt {
        $$ = createNode("Stmt");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        $3->rightbrother = $4;
        $4->rightbrother = $5;
        $5->rightbrother = $6;
        $6->rightbrother = $7;
        @$ = @1;
        $$->line = @1.first_line;
        
        // 检查条件表达式必须是int类型
        // check_logic_cond(exp_type, @3.first_line);
    }
    | WHILE LP Exp RP Stmt {
        $$ = createNode("Stmt");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        $3->rightbrother = $4;
        $4->rightbrother = $5;
        @$ = @1;
        $$->line = @1.first_line;
        
        // 检查条件表达式必须是int类型
        // check_logic_cond(exp_type, @3.first_line);
    }
    | Exp error
    {
        fprintf(stderr,"Error type B at Line %d: Missing \";\"\n",@1.last_line);
        yyerrok;
        WRONG=1;
        $$ = createNode("Stmt");
        $$->firstchild = $1;
        $$->line = @1.first_line;
    }
    | RETURN Exp error
    {
        fprintf(stderr,"Error type B at Line %d: Missing \";\"\n",@2.last_line);
        yyerrok;
        WRONG=1;
        $$ = createNode("Stmt");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $$->line = @1.first_line;
    }
    ;

DefList
    : Def DefList {
        $$ = createNode("DefList");
        $$->firstchild = $1;
        if($2) $1->rightbrother = $2;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | {
        $$ = NULL;
    }
    ;

Def
    : Specifier DecList SEMI {
        $$ = createNode("Def");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | Specifier DecList error
    {
        fprintf(stderr,
            "Error type B at Line %d: Missing \";\"\n",
            @2.last_line);
        yyerrok;
        WRONG=1;
        $$ = createNode("Def");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $$->line = @1.first_line;
    }
    ;

DecList
    : Dec {
        $$ = createNode("DecList");
        $$->firstchild = $1;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | Dec COMMA DecList {
        $$ = createNode("DecList");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        if($3) $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
    }
    ;

Dec
    : VarDec {
        $$ = createNode("Dec");
        $$->firstchild = $1;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | VarDec ASSIGNOP Exp {
        $$ = createNode("Dec");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
        
        // 处理初始化赋值类型检查
        // 需要获取变量类型和表达式类型进行比较
        // check_assign(var_type, exp_type, @2.first_line);
    }
    ;

Exp
    : Exp ASSIGNOP Exp {
        $$ = createNode("Exp");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
        
        // 赋值类型检查
        // check_assign(left_type, right_type, @2.first_line);
    }
    | Exp AND Exp {
        $$ = createNode("Exp");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
        
        // 逻辑与运算检查
        // check_arithmetic(t1, t2, @2.first_line);
    }
    | Exp OR Exp {
        $$ = createNode("Exp");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
        
        // 逻辑或运算检查
        // check_arithmetic(t1, t2, @2.first_line);
    }
    | Exp RELOP Exp {
        $$ = createNode("Exp");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
        
        // 关系运算检查
        // check_arithmetic(t1, t2, @2.first_line);
    }
    | Exp PLUS Exp {
        $$ = createNode("Exp");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
        
        // 加法运算检查
        // check_arithmetic(t1, t2, @2.first_line);
    }
    | Exp MINUS Exp {
        $$ = createNode("Exp");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
        
        // 减法运算检查
        // check_arithmetic(t1, t2, @2.first_line);
    }
    | Exp STAR Exp {
        $$ = createNode("Exp");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
        
        // 乘法运算检查
        // check_arithmetic(t1, t2, @2.first_line);
    }
    | Exp DIV Exp {
        $$ = createNode("Exp");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
        
        // 除法运算检查
        // check_arithmetic(t1, t2, @2.first_line);
    }
    | LP Exp RP {
        $$ = createNode("Exp");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | MINUS Exp %prec UMINUS {
        $$ = createNode("Exp");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | NOT Exp {
        $$ = createNode("Exp");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | ID LP Args RP {
        $$ = createNode("Exp");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        $3->rightbrother = $4;
        @$ = @1;
        $$->line = @1.first_line;
        
        // 函数调用检查
        if($1 && $1->istoken && strcmp($1->name, "ID") == 0) {
            Symbol* func = sym_lookup($1->id);
            if(!func || func->kind != SYM_FUNC) {
                fprintf(stderr, "Error type D at Line %d: Undefined function '%s'\n", 
                        $1->line, $1->id);
                WRONG = 1;
            }
            // 参数类型检查
            // 需要遍历Args节点与函数参数列表进行比较
        }
    }
    | ID LP RP {
        $$ = createNode("Exp");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
        
        // 无参函数调用检查
        if($1 && $1->istoken && strcmp($1->name, "ID") == 0) {
            Symbol* func = sym_lookup($1->id);
            if(!func || func->kind != SYM_FUNC) {
                fprintf(stderr, "Error type D at Line %d: Undefined function '%s'\n", 
                        $1->line, $1->id);
                WRONG = 1;
            } else if(func->param_cnt > 0) {
                fprintf(stderr, "Error type D at Line %d: Function '%s' expects %d arguments\n", 
                        $1->line, $1->id, func->param_cnt);
                WRONG = 1;
            }
        }
    }
    | Exp LB Exp RB {
        $$ = createNode("Exp");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        $3->rightbrother = $4;
        @$ = @1;
        $$->line = @1.first_line;
        
        // 数组访问检查
        // 需要检查Exp是否是数组类型，以及索引是否是int类型
    }
    | Exp DOT ID {
        $$ = createNode("Exp");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
        
        // 结构体成员访问检查
        // 需要检查Exp是否是结构体类型，以及成员是否存在
    }
    | ID {
        $$ = createNode("Exp");
        $$->firstchild = $1;
        @$ = @1;
        $$->line = @1.first_line;
        
        // 变量引用检查
        if($1 && $1->istoken && strcmp($1->name, "ID") == 0) {
            Symbol* sym = sym_lookup($1->id);
            if(!sym) {
                fprintf(stderr, "Error type D at Line %d: Undefined variable '%s'\n", 
                        $1->line, $1->id);
                WRONG = 1;
            }
        }
    }
    | INT {
        $$ = createNode("Exp");
        $$->firstchild = $1;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | FLOAT {
        $$ = createNode("Exp");
        $$->firstchild = $1;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | Exp LB Exp error RB
    {
        fprintf(stderr,
            "Error type B at Line %d: Missing \"]\"\n",
            @2.last_line);

        yyerrok;
        WRONG=1;

        $$ = createNode("Exp");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        $$->line = @1.first_line;
    }
    ;

Args
    : Exp COMMA Args {
        $$ = createNode("Args");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | Exp {
        $$ = createNode("Args");
        $$->firstchild = $1;
        @$ = @1;
        $$->line = @1.first_line;
    }
    ;

%%

void yyerror(char *msg){}

// ========== 辅助函数实现 ==========

// 从Specifier节点获取类型
BasicType get_type_from_specifier(treeNode* spec) {
    if(!spec) return TYPE_ERROR;
    
    treeNode* child = spec->firstchild;
    if(!child) return TYPE_ERROR;
    
    // 判断是TYPE还是StructSpecifier
    if(child->istoken && strcmp(child->name, "TYPE") == 0) {
        if(child->id) {
            if(strcmp(child->id, "int") == 0) return TYPE_INT;
            if(strcmp(child->id, "float") == 0) return TYPE_FLOAT;
            if(strcmp(child->id, "void") == 0) return TYPE_VOID;
        }
        return TYPE_ERROR;
    } else if(strcmp(child->name, "StructSpecifier") == 0) {
        return TYPE_STRUCT;
    }
    
    return TYPE_ERROR;
}

// 从节点获取ID字符串
char* get_id_from_node(treeNode* node) {
    if(!node || !node->istoken || strcmp(node->name, "ID") != 0) {
        return NULL;
    }
    return node->id;
}

// 从节点获取整数值
int get_int_from_node(treeNode* node) {
    if(!node || !node->istoken || strcmp(node->name, "INT") != 0) {
        return 0;
    }
    return node->idata;
}