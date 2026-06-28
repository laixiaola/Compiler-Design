%option noyywrap

%{
#include <stdio.h>
#include "syntax.tab.h"      // bison生成
extern int yylineno;

void yyerror(const char *msg);
%}

DIGIT       [0-9]
LETTER      [A-Za-z_]
ID          {LETTER}({LETTER}|{DIGIT})*
INT         0[xX][0-9A-Fa-f]+|0[0-7]*|[1-9][0-9]*
FLOAT       {DIGIT}+\.{DIGIT}+([eE][+-]?{DIGIT}+)?|\.{DIGIT}+([eE][+-]?{DIGIT}+)?|{DIGIT}+\.?[eE][+-]?{DIGIT}+

%%

{INT}           {return INT;}    
{FLOAT}         {return FLOAT;}
";"             { return SEMI; }
","             { return COMMA; }
"="             { return ASSIGNOP; }
"<="|">="|"<"|">"|"=="|"!="     { return RELOP; }
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

{ID}            {
                    yylval.type_string = strdup(yytext);
                    return ID;
                }


[ \t\r]+        ;

\n              { yylineno++; }

"//".*          ;

"/*"([^*]|\*+[^*/])*\*+"/" ;

.               {
                    printf("Error type A at Line %d: Mysterious character '%s'\n",
                            yylineno, yytext);
                }

%%