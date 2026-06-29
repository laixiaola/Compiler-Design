%option noyywrap yylineno

%{
#include <stdio.h>
%}

DIGIT       [0-9]
LETTER      [A-Za-z_]
ID          {LETTER}({LETTER}|{DIGIT})*
INT         0[xX][0-9A-Fa-f]+|0[0-7]*|[1-9][0-9]*
FLOAT       {DIGIT}+\.{DIGIT}+([eE][+-]?{DIGIT}+)?|\.{DIGIT}+([eE][+-]?{DIGIT}+)?|{DIGIT}+\.?[eE][+-]?{DIGIT}+

%%

{INT}           { printf("INT\n"); }    
{FLOAT}         { printf("FLOAT\n"); }
";"             { printf("SEMI\n"); }
","             { printf("COMMA\n"); }
"<="|">="|"<"|">"|"=="|"!="     { printf("RELOP\n"); }
"="             { printf("ASSIGNOP\n"); }
"+"             { printf("PLUS\n"); }
"-"             { printf("MINUS\n"); }
"*"             { printf("STAR\n"); }
"/"             { printf("DIV\n"); }
"&&"            { printf("AND\n"); }
"||"            { printf("OR\n"); }
"."             { printf("DOT\n"); }
"!"             { printf("NOT\n"); }
"int"           { printf("TYPE\n"); }
"float"         { printf("TYPE\n"); }
"("             { printf("LP\n"); }
")"             { printf("RP\n"); }
"["             { printf("LB\n"); }
"]"             { printf("RB\n"); }
"{"             { printf("LC\n"); }
"}"             { printf("RC\n"); }
"struct"        { printf("STRUCT\n"); }
"return"        { printf("RETURN\n"); }
"if"            { printf("IF\n"); }
"else"          { printf("ELSE\n"); }
"while"         { printf("WHILE\n"); }
{ID}            { printf("ID\n"); }


[ \t\r]+        ;

\n              ;

"//".*          ;

"/*"([^*]|\*+[^*/])*\*+"/" ;

.               {
                    printf("Error type A at Line %d: Mysterious character '%s'\n",
                            yylineno, yytext);
                }

%%
int main(int argc,char** argv){
    if(argc>1){
        FILE* f=fopen(argv[1],"r");
        if(!f){
            perror(argv[1]);
            return 1;
        }
        yyrestart(f);
        yylex();
        return 0;
    }
    
    return 1;
}