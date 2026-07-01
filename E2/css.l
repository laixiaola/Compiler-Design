%option noyywrap yylineno

%{
#include "tree.h"
#include "syntax.tab.h"
extern int WRONG;
int yycolumn=1;
#define YY_USER_ACTION \
    yylloc.first_line=yylloc.last_line=yylineno;\
    yylloc.first_column=yycolumn;\
    yylloc.last_column=yycolumn+yyleng-1;\
    yycolumn+=yyleng;
%}

DIGIT       [0-9]
LETTER      [A-Za-z_]
ID          {LETTER}({LETTER}|{DIGIT})*
INT         0[xX][0-9A-Fa-f]+|0[0-7]*|[1-9][0-9]*
FLOAT       {DIGIT}+\.{DIGIT}+([eE][+-]?{DIGIT}+)?|\.{DIGIT}+([eE][+-]?{DIGIT}+)?|{DIGIT}+\.?[eE][+-]?{DIGIT}+

%%

{INT}           { 
                    treeNode* node = createNode("INT");
                    node->idata = atoi(yytext); 
                    node->istoken=1;
                    node->line=yylineno;
                    yylval.type_node = node;
                    return INT; 
                }
{FLOAT}         { 
                    treeNode* node = createNode("FLOAT");
                    node->istoken=1;
                    node->line=yylineno;
                    node->fdata = atof(yytext); 
                    yylval.type_node = node;
                    return FLOAT; 
                }
";"             { treeNode* node = createNode("SEMI");
                    node->istoken=1;
                    node->line=yylineno;
                    yylval.type_node = node;
                    return SEMI; 
                }
","             { treeNode* node = createNode("COMMA");
                    node->istoken=1;
                    node->line=yylineno;
                    yylval.type_node = node;
                    return COMMA; 
                }
"<="|">="|"<"|">"|"=="|"!=" { 
                    treeNode* node = createNode("RELOP");
                    node->istoken=1;
                    node->line=yylineno;
                    node->id = strdup(yytext);
                    yylval.type_node = node;
                    return RELOP; 
                }
"="             { treeNode* node = createNode("ASSIGNOP");
                    node->istoken=1;
                    node->line=yylineno;
                    yylval.type_node = node;
                    return ASSIGNOP; 
                }
"+"             { treeNode* node = createNode("PLUS");
                    node->istoken=1;
                    node->line=yylineno;
                    yylval.type_node = node;
                    return PLUS; 
                }
"-"             { treeNode* node = createNode("MINUS");
                    node->istoken=1;
                    node->line=yylineno;
                    yylval.type_node = node;
                    return MINUS; 
                }
"*"             { treeNode* node = createNode("STAR");
                    node->istoken=1;
                    node->line=yylineno;
                    yylval.type_node = node;
                    return STAR; 
                }
"/"             { treeNode* node = createNode("DIV");
                    node->istoken=1;
                    node->line=yylineno;
                    yylval.type_node = node;
                    return DIV; 
                }
"&&"            { treeNode* node = createNode("AND");
                    node->istoken=1;
                    node->line=yylineno;
                    yylval.type_node = node;
                    return AND; 
                }
"||"            { treeNode* node = createNode("OR");
                    node->istoken=1;
                    node->line=yylineno;
                    yylval.type_node = node;
                    return OR; 
                }
"."             { treeNode* node = createNode("DOT");
                    node->istoken=1;
                    node->line=yylineno;
                    yylval.type_node = node;
                    return DOT; 
                }
"!"             { treeNode* node = createNode("NOT");
                    node->istoken=1;
                    node->line=yylineno;
                    yylval.type_node = node;
                    return NOT; 
                }
"("             { treeNode* node = createNode("LP");
                    node->istoken=1;
                    node->line=yylineno;
                    yylval.type_node = node;
                    return LP; 
                }
")"             { treeNode* node = createNode("RP");
                    node->istoken=1;
                    node->line=yylineno;
                    yylval.type_node = node;
                    return RP; 
                }
"["             { treeNode* node = createNode("LB");
                    node->istoken=1;
                    node->line=yylineno;
                    yylval.type_node = node;
                    return LB; 
                }
"]"             { treeNode* node = createNode("RB");
                    node->istoken=1;
                    node->line=yylineno;
                    yylval.type_node = node;
                    return RB; 
                }
"{"             { treeNode* node = createNode("LC");
                    node->istoken=1;
                    node->line=yylineno;
                    yylval.type_node = node;
                    return LC; 
                }
"}"             { treeNode* node = createNode("RC");
                    node->istoken=1;
                    node->line=yylineno;
                    yylval.type_node = node;
                    return RC; 
                }
"struct"        { treeNode* node = createNode("STRUCT");
                    node->istoken=1;
                    node->line=yylineno;
                    yylval.type_node = node;
                    return STRUCT; 
                }
"return"        { treeNode* node = createNode("RETURN");
                    node->istoken=1;
                    node->line=yylineno;
                    yylval.type_node = node;
                    return RETURN; 
                }
"if"            { treeNode* node = createNode("IF");
                    node->istoken=1;
                    node->line=yylineno;
                    yylval.type_node = node;
                    return IF; 
                }
"else"          { treeNode* node = createNode("ELSE");
                    node->istoken=1;
                    node->line=yylineno;
                    yylval.type_node = node;
                    return ELSE; 
                }
"while"         { treeNode* node = createNode("WHILE");
                    node->istoken=1;
                    node->line=yylineno;
                    yylval.type_node = node;
                    return WHILE; 
                }

"int"           { 
                    treeNode* node = createNode("TYPE");
                    node->id = "int";
                    node->istoken=1;
                    node->line=yylineno;
                    yylval.type_node = node;
                    return TYPE; 
                }
"float"         { 
                    treeNode* node = createNode("TYPE");
                    node->id = "float";
                    node->istoken=1;
                    node->line=yylineno;
                    yylval.type_node = node;
                    return TYPE; 
                }

{ID}            { 
                    treeNode* node = createNode("ID");
                    node->id = strdup(yytext);
                    node->istoken=1;
                    node->line=yylineno;
                    yylval.type_node = node;
                    return ID; 
                }


[ \t\r]+        ;

\n              {yycolumn=1;}

"//".*          ;

"/*"([^*]|\*+[^*/])*\*+"/" ;

.               {
                    WRONG=1;
                    printf("Error type A at Line %d: Mysterious character '%s'\n",
                            yylineno, yytext);
                }

%%