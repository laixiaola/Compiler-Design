#ifndef SYMTAB_H
#define SYMTAB_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// 基础数据类型
typedef enum {
    TYPE_INT,
    TYPE_FLOAT,
    TYPE_STRUCT,
    TYPE_VOID,
    TYPE_ERROR   // 错误类型标记
} BasicType;

// 符号种类
typedef enum {
    SYM_VAR,        // 普通变量/数组
    SYM_FUNC,       // 函数
    SYM_STRUCT,     // 结构体类型
    SYM_MEMBER      // 结构体成员
} SymKind;

// 函数参数
typedef struct ParamNode {
    BasicType type;
    char name[64];
    struct ParamNode *next;
} ParamNode;

// 结构体成员
typedef struct MemberNode {
    char name[64];
    BasicType type;
    struct MemberNode *next;
} MemberNode;

// 符号表项
typedef struct Symbol {
    char name[64];
    SymKind kind;
    BasicType b_type;
    int lineno;

    int arr_dim;                // 数组维度
    ParamNode *param_list;      // 函数参数链表
    int param_cnt;
    MemberNode *member_list;    // 结构体成员链表

    struct Symbol *next;
} Symbol;

// 全局唯一符号表
extern Symbol *global_table;

// 初始化全局符号表
void symtab_init();

// 全局插入符号：全局查重，重名直接报错（规则4）
Symbol* sym_insert(const char *name, SymKind kind, BasicType b_type, int line);

// 全局查找符号
Symbol* sym_lookup(const char *name);

// ========== 函数相关接口（规则3、6） ==========
// 检查当前是否处于函数内，禁止嵌套定义
int in_func_scope();
// 进入函数定义
void enter_func();
// 退出函数定义
void leave_func();

// 函数追加形参
void func_add_param(Symbol *func, BasicType p_type, const char *p_name);

// ========== 结构体相关接口（规则5、7） ==========
// 结构体添加成员（成员全局唯一）
int struct_add_member(Symbol *struct_sym, BasicType m_type, const char *m_name, int line);

// 名等价判断：结构体按名字比较（规则5）
int struct_name_equal(const char *s1, const char *s2);

// ========== 类型检查接口（规则1、2 核心） ==========
// 赋值检查：int/float 禁止互赋
int check_assign(BasicType left, BasicType right, int line);

// 算术运算检查：仅 int/float 允许
int check_arithmetic(BasicType t1, BasicType t2, int line);

// 逻辑运算/分支条件检查：只能是 int
int check_logic_cond(BasicType t, int line);

// 数组设置维度
void sym_set_array_dim(Symbol *sym, int dim);

// 打印符号表
void symtab_print();
// 释放所有内存
void symtab_destroy();

#endif
