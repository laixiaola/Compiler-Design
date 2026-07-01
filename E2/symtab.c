#include "symtab.h"

Symbol *global_table = NULL;
static int func_nest_flag = 0;  // 标记是否在函数内(禁止嵌套定义)

void symtab_init() {
    global_table = NULL;
    func_nest_flag = 0;
}

// 全局插入：所有标识符全局唯一（规则4）
Symbol* sym_insert(const char *name, SymKind kind, BasicType b_type, int line) {
    if (sym_lookup(name) != NULL) {
        fprintf(stderr, "Line %d: Error: identifier \"%s\" redefined (all global, no duplicate)\n", line, name);
        return NULL;
    }

    Symbol *new_sym = (Symbol*)malloc(sizeof(Symbol));
    strncpy(new_sym->name, name, 63);
    new_sym->name[63] = '\0';
    new_sym->kind = kind;
    new_sym->b_type = b_type;
    new_sym->lineno = line;

    new_sym->arr_dim = 0;
    new_sym->param_list = NULL;
    new_sym->param_cnt = 0;
    new_sym->member_list = NULL;

    new_sym->next = global_table;
    global_table = new_sym;
    return new_sym;
}

Symbol* sym_lookup(const char *name) {
    Symbol *p = global_table;
    while (p) {
        if (strcmp(p->name, name) == 0)
            return p;
        p = p->next;
    }
    return NULL;
}

// ========== 函数嵌套控制（规则6） ==========
int in_func_scope() {
    return func_nest_flag;
}

void enter_func() {
    func_nest_flag = 1;
}

void leave_func() {
    func_nest_flag = 0;
}

// 函数添加形参
void func_add_param(Symbol *func, BasicType p_type, const char *p_name) {
    if (!func || func->kind != SYM_FUNC) return;

    ParamNode *node = (ParamNode*)malloc(sizeof(ParamNode));
    node->type = p_type;
    strncpy(node->name, p_name, 63);
    node->name[63] = '\0';
    node->next = NULL;

    ParamNode *tail = func->param_list;
    if (!tail)
        func->param_list = node;
    else {
        while (tail->next) tail = tail->next;
        tail->next = node;
    }
    func->param_cnt++;
}

// ========== 结构体 & 成员规则（规则5、7） ==========
int struct_add_member(Symbol *struct_sym, BasicType m_type, const char *m_name, int line) {
    // 规则7：结构体成员名全局唯一，不能和任何符号重名
    if (sym_lookup(m_name)) {
        fprintf(stderr, "Line %d: Error: struct member \"%s\" duplicate with other identifier\n", line, m_name);
        return 0;
    }

    MemberNode *node = (MemberNode*)malloc(sizeof(MemberNode));
    strncpy(node->name, m_name, 63);
    node->name[63] = '\0';
    node->type = m_type;
    node->next = NULL;

    MemberNode *tail = struct_sym->member_list;
    if (!tail)
        struct_sym->member_list = node;
    else {
        while (tail->next) tail = tail->next;
        tail->next = node;
    }
    return 1;
}

// 名等价（规则5）：仅比较结构体名称
int struct_name_equal(const char *s1, const char *s2) {
    return strcmp(s1, s2) == 0;
}

// ========== 类型检查（规则1、规则2 核心） ==========
// 规则1：int 和 float 禁止互相赋值
int check_assign(BasicType left, BasicType right, int line) {
    if ((left == TYPE_INT && right == TYPE_FLOAT) || (left == TYPE_FLOAT && right == TYPE_INT)) {
        fprintf(stderr, "Line %d: Error: cannot assign int and float to each other\n", line);
        return 0;
    }
    return 1;
}

// 规则2：算术运算仅允许 int / float
int check_arithmetic(BasicType t1, BasicType t2, int line) {
    if ((t1 != TYPE_INT && t1 != TYPE_FLOAT) || (t2 != TYPE_INT && t2 != TYPE_FLOAT)) {
        fprintf(stderr, "Line %d: Error: only int/float can do arithmetic operation\n", line);
        return 0;
    }
    // 顺带检查规则1：int/float 不能混合运算
    if ((t1 == TYPE_INT && t2 == TYPE_FLOAT) || (t1 == TYPE_FLOAT && t2 == TYPE_INT)) {
        fprintf(stderr, "Line %d: Error: int and float cannot mixed arithmetic operation\n", line);
        return 0;
    }
    return 1;
}

// 规则2：逻辑运算、if/while 条件只能是 int
int check_logic_cond(BasicType t, int line) {
    if (t != TYPE_INT) {
        fprintf(stderr, "Line %d: Error: condition/logic operation must be int type\n", line);
        return 0;
    }
    return 1;
}

void sym_set_array_dim(Symbol *sym, int dim) {
    if (sym) sym->arr_dim = dim;
}

// 打印符号表
void symtab_print() {
    printf("\n===== Global Symbol Table =====\n");
    Symbol *p = global_table;
    while (p) {
        printf("Name: %-15s Line: %-4d ", p->name, p->lineno);
        switch(p->kind) {
            case SYM_VAR: printf("Kind: Variable/Array"); break;
            case SYM_FUNC: printf("Kind: Function, ParamNum: %d", p->param_cnt); break;
            case SYM_STRUCT: printf("Kind: Struct"); break;
            case SYM_MEMBER: printf("Kind: Struct Member"); break;
        }
        printf("\n");
        p = p->next;
    }
    printf("================================\n\n");
}

// 释放内存
void symtab_destroy() {
    Symbol *p = global_table, *q;
    while (p) {
        q = p->next;
        ParamNode *pp = p->param_list, *pq;
        while(pp) { pq = pp->next; free(pp); pp = pq; }
        MemberNode *mm = p->member_list, *mq;
        while(mm) { mq = mm->next; free(mm); mm = mq; }
        free(p);
        p = q;
    }
    global_table = NULL;
}
