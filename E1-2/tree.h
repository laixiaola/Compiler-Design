#ifndef TREE_H
#define TREE_H
#include <stdio.h>

typedef struct treeNode{
    // treeNode* parent;
    struct treeNode* firstchild;
    struct treeNode* rightbrother;
    char* name;
    int line;
    int istoken;
    char* id;
    float fdata;
    int idata;
} treeNode;

treeNode* createNode(char* name);
void traverseTree(treeNode* root,int level);
#endif