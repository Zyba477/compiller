%option nounput
%option noinput
%{
#include <string.h>
#include <stdio.h>
#include "y.tab.h"
int count = 1;
%}

%%
"main" return MAIN;
"int" return INT;
"float" return FLOAT;
"char" return CHAR;
"if" return IF;
"else" return ELSE;
"while" return WHILE;
"do" return DO;
"for" return FOR;
"void" return VOID;
"return" return RETURN;
[A-Z]+[a-z]* return METHOD;
[-+]?[0-9]+ return INT_CONST;
[\'][a-zA-Z0-9@#$%^&*?!][\'] return CHAR_CONST;
[0-9]+"."[0-9]+ return FLOAT_CONST;
[a-zA-Z]+[0-9]*[a-zA-Z]* return ID;
-[a-zA-Z]+ return ID;
"+" return PLUS;
"-" return MINUS;
"=" return ASSIGNMENT;
"==" return EQUALS;
"&&" return AND;
"||" return OR;
"{" return BLOCKBEG;
"}" return BLOCKEND;
"(" return BRACEBEG;
")" return BRACEEND;
">" return GT;
"<" return LT;
"<=" return LE;
">=" return GE;
"/" return DIV;
"%" return MOD;
"*" return MUL;
"^" return XOR;
";" return STMTEND;
" " { }
"//".* { } ;
\n ;count++;

[.] return yytext[0];
%%
