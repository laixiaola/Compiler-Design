%option noyywrap yylineno

%{
#include "syntax.tab.h"
int yycolumn=1;
#define YY_USER_ACTION \
    yylloc.first_line=yylloc.last_line=yylineno;\
    yylloc.first_column=yycolumn;\
    yylloc.last_column=yycolumn+yyleng-1;\
    yycolumn+=yyleng
%}

DIGIT       [0-9]
LETTER      [A-Za-z_]
ID          {LETTER}({LETTER}|{DIGIT})*
INT         0[xX][0-9A-Fa-f]+|0[0-7]*|[1-9][0-9]*
FLOAT       {DIGIT}+\.{DIGIT}+([eE][+-]?{DIGIT}+)?|\.{DIGIT}+([eE][+-]?{DIGIT}+)?|{DIGIT}+\.?[eE][+-]?{DIGIT}+

%%

{INT}           {   
                    yylval=atoi(yytext);
                    return INT;}    
{FLOAT}         {return FLOAT;}
";"             { return SEMI; }
","             { return COMMA; }
"<="|">="|"<"|">"|"=="|"!="     { return RELOP; }
"="             { return ASSIGNOP; }
"+"             { return PLUS; }
"-"             { return MINUS; }
"*"             { return STAR; }
"/"             { return DIV; }
"&&"            { return AND; }
"||"            { return OR; }
"."             { return DOT; }
"!"             { return NOT; }
"int"           { return TYPE; }
"float"         { return TYPE; }
"("             { return LP; }
")"             { return RP; }
"["             { return LB; }
"]"             { return RB; }
"{"             { return LC; }
"}"             { return RC; }
"struct"        { return STRUCT; }
"return"        { return RETURN; }
"if"            { return IF; }
"else"          { return ELSE; }
"while"         { return WHILE; }

{ID}            {return ID;}


[ \t\r]+        ;

\n              {yycolumn=1;}

"//".*          ;

"/*"([^*]|\*+[^*/])*\*+"/" ;

.               {
                    printf("Error type A at Line %d: Mysterious character '%s'\n",
                            yylineno, yytext);
                }

%%