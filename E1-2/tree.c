#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tree.h"

treeNode* createNode(char* name){
    treeNode* newnode=(treeNode*)malloc(sizeof(treeNode));
    // newnode->parent=NULL;
    newnode->firstchild=NULL;
    newnode->rightbrother=NULL;
    newnode->name=name;
    newnode->line=-1;
    newnode->istoken=0;
    newnode->fdata=0.0;
    newnode->idata=0;
    return newnode;
}

void traverseTree(treeNode* root,int level){
    if(root==NULL) return;
    //动作
    if(strcmp(root->name,"NULL")!=0){
        for(int i=0;i<level;i++) printf("  ");
        if(root->istoken){
            printf("%s",root->name);
            if(strcmp(root->name,"ID")==0){
                printf(": %s",root->id);
            }
            else if(strcmp(root->name,"FLOAT")==0){
                printf(": %f",root->fdata);
            }
            else if(strcmp(root->name,"INT")==0){
                printf(": %d",root->idata);
            }
            else if(strcmp(root->name,"TYPE")==0){
                printf(": %s",root->id);
            }
            printf("\n");
            
        }
        else{
            printf("%s (%d)\n",root->name,root->line);
        }
    }
    traverseTree(root->firstchild,level+1);
    traverseTree(root->rightbrother,level);
}