#ifndef TREE_H
#define TREE_H
#include <stdio.h>

typedef struct treeNode{
    struct treeNode* firstchild;
    struct treeNode* rightbrother;
    char* name;     //节点名，对应token名字或者词法单元名字
    int line;       //所在行号
    int istoken;    //是否为token
    char* id;       //只有当token为ID或TYPE时id才有值，否则为NULL
    float fdata;    //当token为float时对应数值
    int idata;      //当token为int时对应数值
} treeNode;

treeNode* createNode(char* name);
void traverseTree(treeNode* root,int level);
#endif