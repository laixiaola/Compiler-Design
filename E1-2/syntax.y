%{
#include <stdio.h>
#include <stdlib.h>
#include "tree.h"
extern int yylex();
extern int yyparse();
void yyerror(char* msg);
treeNode* root=NULL;
int WRONG=0;
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
    }
    | STRUCT Tag {
        $$ = createNode("StructSpecifier");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        @$ = @1;
        $$->line = @1.first_line;
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
    }
    /* | LC DefList StmtList error
    {
        fprintf(stderr,"Error type B at Line %d: Missing \"}\"\n",@3.last_line);
        yyerrok;
        WRONG=1;
        $$ = createNode("CompSt");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        if($2) $2->rightbrother = $3;
        $$->line = @1.first_line;
    } */
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
    }
    | Exp AND Exp {
        $$ = createNode("Exp");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | Exp OR Exp {
        $$ = createNode("Exp");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | Exp RELOP Exp {
        $$ = createNode("Exp");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | Exp PLUS Exp {
        $$ = createNode("Exp");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | Exp MINUS Exp {
        $$ = createNode("Exp");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | Exp STAR Exp {
        $$ = createNode("Exp");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | Exp DIV Exp {
        $$ = createNode("Exp");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
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
    }
    | ID LP RP {
        $$ = createNode("Exp");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | Exp LB Exp RB {
        $$ = createNode("Exp");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        $3->rightbrother = $4;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | Exp DOT ID {
        $$ = createNode("Exp");
        $$->firstchild = $1;
        $1->rightbrother = $2;
        $2->rightbrother = $3;
        @$ = @1;
        $$->line = @1.first_line;
    }
    | ID {
        $$ = createNode("Exp");
        $$->firstchild = $1;
        @$ = @1;
        $$->line = @1.first_line;
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