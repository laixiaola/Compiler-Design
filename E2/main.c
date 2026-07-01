#include <stdio.h>
#include "tree.h"
#include "syntax.tab.h"
extern treeNode* root;
extern void yyrestart(FILE *);
extern int WRONG;
int main(int argc,char** argv){
    if(argc>1){
        FILE* f=fopen(argv[1],"r");
        if(!f){
            perror(argv[1]);
            return 1;
        }
        yyrestart(f);
        yyparse();
        if(!WRONG){
            traverseTree(root,0);
            return 0;
        }
    }
    
    return 1;
}
