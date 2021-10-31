%{
#include <stdio.h>
#include <string.h>
int symbol_count = 0;
int count_error = 0;
int count_main = 0;
int math = 0;
int lvl_math = 0;
char *op;
enum {
	TYPE_OPERAND ,
	TYPE_INT_OPERAND,
	TYPE_CHAR_OPERAND,
	TYPE_FLOAT_OPERAND,
	TYPE_OPERATOR,
	TYPE_ASSIGNMENT,
	TYPE_ASSIGNMENT_NEW,
	TYPE_LIST,
	TYPE_BLOCK,
	TYPE_IF,
	TYPE_IF_DECISIONS,
	TYPE_WHILE,
	TYPE_FOR,
	TYPE_NEW,
	TYPE_TYPE,
	TYPE_MAIN,
	TYPE_FUNC,
	TYPE_FUNC_VOID,
	TYPE_LOGIC
};

typedef struct node {
	char *token;
	struct node *left;
	struct node *right;
	int type;
} node;

typedef struct {
	char *type;
	char *id;
	char *value;
} symbol;
symbol table [500];
void parseTree (node *no);
void printf_error(char *a, char *b);
int check(const char *x);
void printTable();
void check_main();
node *mknode (char *token, node *left, node *right, int type);
int addchild(node *parent, node *child);
int countIf(int a, int b, char *op);
int arefmetic(int a, int b, char *op);
#define YYSTYPE struct node*
#include "lex.yy.c"
void yyerror(char* s){	printf("%s - %s in line: %d\n",s,yytext,count);}
%}
%token ERROR
%token MAIN METHOD VOID RETURN
%token IF ELSE FOR WHILE DO 
%token INT_CONST CHAR_CONST FLOAT_CONST  
%token INT FLOAT CHAR 
%token MINUS PLUS EQUALS ID BLOCKBEG BLOCKEND
%token BRACEBEG BRACEEND ASSIGNMENT AND OR LT LE GT GE XOR MOD
%token MUL DIV
%token STMTEND 
%left MINUS PLUS
%left MUL DIV

%%
s:  sts { 
	// fprintf(stderr, "WTF?!\n");
	// printTree($1, 0, 1);
	
	parseTree($1);
	check_main();
	printTable();
	
	printf("\n");
	
}; 
sts: sts list  {$$ = mknode("_", $1, $2, TYPE_LIST);}  | st_main  | ;


list: list entities {
	addchild($1, $2);
	//$$ = mknode("LIST", $1, $2, TYPE_LIST);
	// fprintf(stderr, "ADD\n");
} | {
	// fprintf(stderr, "BEGIN\n");
	$$ = mknode("LIST", NULL, NULL, TYPE_LIST);
};

entities: stmt | block | if_block | while_block | for_block | func  ;

st_main:  main block {$$ = mknode("MAIN",NULL,$2, TYPE_MAIN);} ;
main: MAIN BRACEBEG BRACEEND ;

block: BLOCKBEG list BLOCKEND { $$ = mknode("BLOCK", $2, NULL, TYPE_BLOCK); }

func:  func_void | func_no_void ;
func_void: VOID id BRACEBEG BRACEEND block {$$ = mknode("FUNC_VOID", $2, $5 , TYPE_FUNC_VOID);}
func_no_void: new BRACEBEG BRACEEND block return {$$ = mknode("FUNC", mknode("_",$1,$4,TYPE_LIST),$5 ,TYPE_FUNC);}
return: RETURN operand STMTEND {$$ = $2;}

for_block: FOR BRACEBEG for_count BRACEEND block {$$ = mknode("FOR", $3, mknode("", $5, NULL, TYPE_BLOCK), TYPE_FOR);};
for_count: stmt stmt stmt {$$ = mknode("_", $1, mknode("_", $2, $3, TYPE_LIST), TYPE_LIST);}; 


while_block: DO block WHILE BRACEBEG condexp_logic BRACEEND {$$ = mknode("DO_WHILE", $2, mknode("COND", $5, NULL, TYPE_WHILE), TYPE_BLOCK);}
		| WHILE BRACEBEG condexp_logic BRACEEND block  { $$ = mknode("WHILE", $3, $5, TYPE_WHILE); }

if_block: IF BRACEBEG condexp_logic BRACEEND if_decisions { $$ = mknode("COND", $3, $5, TYPE_IF); }
if_decisions: block |
              block ELSE block { $$ = mknode("_", $1, $3, TYPE_IF_DECISIONS); } |
	      block ELSE if_block { $$ = mknode("_", $1, $3, TYPE_IF_DECISIONS); };

stmt: exp STMTEND;

assignment: id ASSIGNMENT exp { $$ = mknode("=", $1, $3, TYPE_ASSIGNMENT); } |
	    new ASSIGNMENT exp { $$ = mknode("=", $1, $3, TYPE_ASSIGNMENT_NEW); }

operand: id | num;

id: ID { $$ = mknode(yytext, NULL, NULL, TYPE_OPERAND);}

new: type id { $$ = mknode("_", $1, $2, TYPE_NEW); }
type: types { $$ = mknode(yytext, NULL, NULL, TYPE_TYPE); }
types: INT | FLOAT | CHAR ;


num: INT_CONST { $$ = mknode(yytext, NULL, NULL, TYPE_INT_OPERAND);}
	| CHAR_CONST { $$ = mknode(yytext, NULL, NULL, TYPE_CHAR_OPERAND);}
	| FLOAT_CONST { $$ = mknode(yytext, NULL, NULL, TYPE_FLOAT_OPERAND);}

condexp_logic: exp op_logic exp {$$ = mknode($2->token, $1, $3, TYPE_LOGIC);}; 

// condexp: operand { $$ = mknode("!=", $1, mknode("0", NULL, NULL, TYPE_OPERAND), TYPE_OPERATOR); }
// 	| assignment { $$ = mknode("!=", $1, mknode("0", NULL, NULL, TYPE_OPERAND), TYPE_OPERATOR); }
// 	| exp;

exp: BRACEBEG exp BRACEEND { $$ = $2; }
	| exp op exp {$$ = mknode($2->token, $1, $3, TYPE_OPERATOR);}
	| operand
	| new
	| assignment;

op: ops { $$ = mknode(yytext, NULL, NULL, -1); }
ops: MINUS | PLUS | MUL | DIV;

op_logic: ops_logic { $$ = mknode(yytext, NULL, NULL, -1); }
ops_logic:  EQUALS | AND | OR | GT | GE | LT | LE | XOR | MOD ;
%%

int main() { yyparse(); return 1; }
int yywrap() { return 1; }

node *mknode(char *token, node *left, node *right, int type) {
	node *newnode = (node *) malloc(sizeof(node));
	char *newstr = (char *) malloc(sizeof(token)+1);
	strcpy(newstr, token);
	newnode->left = left;
	newnode->right = right;
	newnode->token = newstr;
	newnode->type = type;
	return newnode;
}

int addchild(node *parent, node *child) {
	if(parent->left == NULL) {
		parent->left = child;
		return 0;
	}
	else if(parent->right == NULL) {
		parent->right = mknode("_", child, NULL, TYPE_LIST);
		return 0;
	}
	else if(parent->right != NULL) {
		return addchild(parent->right, child);
	}

	return 1;
}

void printIndent(int lvl) {
  for(int i = 0; i < lvl; i++) {
    printf("    ");
  }
}

void parseTree (node *no){
	int symbol ;
	int symbol2 ;
	char *type ;
	char *type2 ;
//	char operator ;
	// int znach ;
	// int znach2 ;
//	fprintf(stderr, "no->token %s\n", no->token);
	switch(no->type){

		case TYPE_MAIN:
			count_main++;
			if(no->left != NULL)
//				count_main++;
				parseTree(no->left);
			if(no->right != NULL)
//				count_main++;
				parseTree(no->right);
			break;

		case TYPE_LIST:
			if(no->left != NULL)
				parseTree(no->left);
			if(no->right != NULL)
				parseTree(no->right);
			break;	

		case TYPE_FUNC_VOID:
			if(no->right != NULL)
				parseTree(no->right);
			if(no->right != NULL){
					symbol = check(no->left->token);
//					printf("asdwasd %d\n",symbol);
					if(symbol != -1){
						printf_error("change function name",no->left->token);
					}					
					table[symbol_count].type = "void";
					table[symbol_count].id = no->left->token;
//					table[symbol_count].value = "void";
					symbol_count++;
				}						
		break;

		case TYPE_FOR:
			break;

		case TYPE_FUNC:
			symbol = check (no->left->left->right->token);
			if(symbol != -1)
				printf_error("change function name",no->left->left->right->token);
			if(no->left->right != NULL)
				parseTree(no->left->right);
			if(no->left->left !=NULL)
				parseTree(no->left->left);
			symbol2 = check(no->right->token);
			
//			printf("aaaaaaaa %s\n",no->left->left->left->token);
			if(symbol2 == -1){
				symbol = check (no->left->left->right->token);
				type = no->left->left->left->token;
				if(!strcmp(type, "int") && no->right->type != TYPE_INT_OPERAND ){
					printf_error(" error int type in return", no->right->token);
				}else if (!strcmp(type, "char") && no->right->type != TYPE_CHAR_OPERAND ){
					printf_error(" error char type in return", no->right->token);
				}else if (!strcmp(type, "float") && no->right->type != TYPE_FLOAT_OPERAND ){
					printf_error(" error float type in return", no->right->token);
				}else { 
//					printf("aaaa\n");
					table[symbol].value = no->right->token;
					break;
				}
			}
			symbol = check (no->left->left->right->token);
			table[symbol].value = table[symbol2].value;
			

			type = table[symbol].type;
			type2 = table[symbol2].type;
			if(strcmp(type, type2) ){
				printf_error("no type func",table[symbol2].id);
			}

			break;

		case TYPE_BLOCK:
			if(no->left != NULL)
				parseTree(no->left);
			if(no->right != NULL)
				parseTree(no->right);
			break;

		case TYPE_IF:
			if(no->left != NULL){
				if(no->left->left != NULL && no->left->right != NULL){
					symbol = check(no->left->left->token ) ;
					symbol2 = check(no->left->right->token ) ;
					if(symbol != -1 && symbol2 != -1){
						type = table[symbol].type ;
						type2 = table[symbol2].type ;
						if(strcmp(type,type2)){
							printf_error("types don't match in if",NULL);
						}else {
							int a = atoi(table[check(no->left->left->token)].value);
							int b = atoi(table[check(no->left->right->token)].value);
							if(countIf(a,b,no->left->token) == 1){

								if(no->right != NULL){
									parseTree(no->right);
								}
							}
						 }

					}else if(symbol != -1 && symbol2 == -1){
						type = table[symbol].type ;
						if(!strcmp(type, "int") && no->left->right->type != TYPE_INT_OPERAND ){
							printf_error("no int in count if",no->left->right->token);
						}else if (!strcmp(type, "char") && no->left->right->type != TYPE_CHAR_OPERAND ){
							printf_error("no char in count if",no->left->right->token);
						}else if (!strcmp(type, "float") && no->left->right->type != TYPE_FLOAT_OPERAND ){
							printf_error("no float in count if",no->left->right->token);
						}else {
							int a = atoi(table[check(no->left->left->token)].value);
							int b = atoi(no->left->right->token);
							if(countIf(a,b,no->left->token) == 1){

								if(no->right != NULL){
									parseTree(no->right);
								}
							}
						 }
						
					}else if(symbol == -1 && symbol2 != -1){
						type2 = table[symbol2].type ;
						if(!strcmp(type2, "int") && no->left->left->type != TYPE_INT_OPERAND ){
							printf_error("no int in count if",no->left->left->token);
						}else if (!strcmp(type2, "char") && no->left->left->type != TYPE_CHAR_OPERAND ){
							printf_error("no char in count if",no->left->left->token);
						}else if (!strcmp(type2, "float") && no->left->left->type != TYPE_FLOAT_OPERAND ){
							printf_error("no float in count if",no->left->left->token);
						}else {
							int a = atoi(no->left->left->token);
							int b = atoi(table[check(no->left->right->token)].value);
							if(countIf(a,b,no->left->token) == 1){

								if(no->right != NULL){
									parseTree(no->right);
								}
							}
						 }

					}else if(symbol == -1 && symbol2 == -1){
						type2 = table[symbol2].type ;
						if(!strcmp(type2, "int") && no->left->left->type != TYPE_INT_OPERAND ){
							printf_error("no int in count if",no->left->left->token);
						}else if (!strcmp(type2, "char") && no->left->left->type != TYPE_CHAR_OPERAND ){
							printf_error("no char in count if",no->left->left->token);
						}else if (!strcmp(type2, "float") && no->left->left->type != TYPE_FLOAT_OPERAND ){
							printf_error("no float in count if",no->left->left->token);
						}else {
							int a = atoi(no->left->left->token);
							int b = atoi(no->left->right->token);
							if(countIf(a,b,no->left->token) == 1){

								if(no->right != NULL){
									parseTree(no->right);
								}
							}
						 }
					}
				}
			}else {printf_error("no if cound",NULL);}			
			break;

			case TYPE_WHILE:
			if(no->left != NULL){
				if(no->left->left != NULL && no->left->right != NULL){
					symbol = check(no->left->left->token ) ;
					symbol2 = check(no->left->right->token ) ;
					if(symbol != -1 && symbol2 != -1){
						type = table[symbol].type ;
						type2 = table[symbol2].type ;
						if(strcmp(type,type2)){
							printf_error("types don't match in if",NULL);
						}else {
							int a = atoi(table[check(no->left->left->token)].value);
							int b = atoi(table[check(no->left->right->token)].value);
							if(countIf(a,b,no->left->token) == 1){

								if(no->right != NULL){
									parseTree(no->right);
								}
							}
						 }

					}else if(symbol != -1 && symbol2 == -1){
						type = table[symbol].type ;
						if(!strcmp(type, "int") && no->left->right->type != TYPE_INT_OPERAND ){
							printf_error("no int in count if",no->left->right->token);
						}else if (!strcmp(type, "char") && no->left->right->type != TYPE_CHAR_OPERAND ){
							printf_error("no char in count if",no->left->right->token);
						}else if (!strcmp(type, "float") && no->left->right->type != TYPE_FLOAT_OPERAND ){
							printf_error("no float in count if",no->left->right->token);
						}else {
							int a = atoi(table[check(no->left->left->token)].value);
							int b = atoi(no->left->right->token);
							if(countIf(a,b,no->left->token) == 1){

								if(no->right != NULL){
									parseTree(no->right);
								}
							}
						 }
						
					}else if(symbol == -1 && symbol2 != -1){
						type2 = table[symbol2].type ;
						if(!strcmp(type2, "int") && no->left->left->type != TYPE_INT_OPERAND ){
							printf_error("no int in count if",no->left->left->token);
						}else if (!strcmp(type2, "char") && no->left->left->type != TYPE_CHAR_OPERAND ){
							printf_error("no char in count if",no->left->left->token);
						}else if (!strcmp(type2, "float") && no->left->left->type != TYPE_FLOAT_OPERAND ){
							printf_error("no float in count if",no->left->left->token);
						}else {
							int a = atoi(no->left->left->token);
							int b = atoi(table[check(no->left->right->token)].value);
							if(countIf(a,b,no->left->token) == 1){

								if(no->right != NULL){
									parseTree(no->right);
								}
							}
						 }

					}else if(symbol == -1 && symbol2 == -1){
						type2 = table[symbol2].type ;
						if(!strcmp(type2, "int") && no->left->left->type != TYPE_INT_OPERAND ){
							printf_error("no int in count if",no->left->left->token);
						}else if (!strcmp(type2, "char") && no->left->left->type != TYPE_CHAR_OPERAND ){
							printf_error("no char in count if",no->left->left->token);
						}else if (!strcmp(type2, "float") && no->left->left->type != TYPE_FLOAT_OPERAND ){
							printf_error("no float in count if",no->left->left->token);
						}else {
							int a = atoi(no->left->left->token);
							int b = atoi(no->left->right->token);
							if(countIf(a,b,no->left->token) == 1){

								if(no->right != NULL){
									parseTree(no->right);
								}
							}
						 }
					}
				}
			}else {printf_error("no if cound",NULL);}			
			break;

		case TYPE_ASSIGNMENT:
			symbol = check(no->left->token);
			if(symbol == -1){            
				printf_error("ERROR",no->left->token);                                                                                                                                                                                     
			}
			if(no->right->type == TYPE_OPERATOR){
				symbol = symbol_count;
				symbol_count = check(no->left->token);
				parseTree(no->right);
				if(no->left != NULL){
				parseTree(no->left);
				}
				symbol_count = symbol;
				break;
			}
			type = table[symbol].type ;
			if (no->right->type == TYPE_OPERAND){
				symbol2 = check(no->right->token);
				if(symbol2 == -1) {
					printf_error("no operand",no->right->token);
				}
				type2 = table[symbol2].type;
				if(strcmp(type, type2)){
					printf_error("types don't match",table[symbol2].id);
				}
				table[symbol].value = table[symbol2].value ;
				break;
			} else if (!strcmp(type, "int") && no->right->type != TYPE_INT_OPERAND ){
				printf_error("no types int",no->right->token);
			} else if (!strcmp(type, "char") && no->right->type != TYPE_CHAR_OPERAND ){
				printf_error("no types char",no->right->token);
			} else if (!strcmp(type, "float") && no->right->type != TYPE_FLOAT_OPERAND ){
				printf_error("no types float",no->right->token);
			}
			table[symbol].value = no->right->token ;
			break;

		case TYPE_OPERATOR:
	//		printf("aaa %s\n",no->left->token);
			if(no->right->right != NULL){
				lvl_math++;
				parseTree(no->right);
			}
			if(no->right->right == NULL){
			int a = atoi(no->left->token);
			int b = atoi(no->right->token);

			math = arefmetic(a,b,no->token);
			char convert[100];
			//table[symbol].value = (char) math;
			sprintf (convert, "% d", math);
			table[symbol_count].value = convert;
			printf("awd %s\n",table[symbol_count].value);
			break;
		//	printf("aaaa %s\n",no->left->token);
			}

		case TYPE_ASSIGNMENT_NEW:
			if(no->right->type == TYPE_OPERATOR){
				parseTree(no->right);
				if(no->left != NULL){
				parseTree(no->left);
				}
				break;
			}
			symbol = check(no->left->right->token);
			symbol2 = check(no->right->token);
			type = no->left->left->token;
			table[symbol_count].value = no->right->token ;
			
			if(no->left != NULL){
				parseTree(no->left);
			}
			
			if(symbol2 == -1 && no->right->type != TYPE_OPERATOR){
				if(!strcmp(type,"int") && no->right->type != TYPE_INT_OPERAND){
					printf_error("no type int",no->left->right->token);
				} else if (!strcmp(type, "char") && no->right->type != TYPE_CHAR_OPERAND ){
					printf_error("no type char",no->left->right->token);
				} else if (!strcmp(type, "float") && no->right->type != TYPE_FLOAT_OPERAND ){
					printf_error("no type float",no->left->right->token);
				}
			}
			break;
			
			
			// if(symbol != -1 ){
            //     printf_error("ERROR",no->left->right->token);
			// }else if(symbol == -1 && symbol2 != -1){	
			// 	if(strcmp(type,table[symbol2].type)){
			// 		printf_error("types don't match",table[symbol2].id);
			// 	}			
			// 	table[symbol_count].type = no->left->left->token;
			// 	table[symbol_count].id = no->left->right->token;
			// 	table[symbol_count].value = table[symbol2].value ;
			// 	symbol_count++;
			// 	break;
			// 	}
				
			// else{
			// 	if(symbol2 != -1){
			// 		table[symbol].value = table[symbol2].value;
			// 		table[symbol].type = no->left->left->token;
			// 		table[symbol].id = no->left->right->token;
			// 		symbol_count++;
			// 	break;
			// 	}
			// }
			// if(symbol == -1 && no->right != NULL && no->right->right == NULL && no->right->left == NULL ){
			// 	if(!strcmp(type,"int") && no->right->type != TYPE_INT_OPERAND){
			// 		printf_error("no type int ",no->right->token);
			// 	} else if (!strcmp(type, "char") && no->right->type != TYPE_CHAR_OPERAND ){
			// 		printf_error("no type char",no->right->token);
			// 	} else if (!strcmp(type, "float") && no->right->type != TYPE_FLOAT_OPERAND ){
			// 		printf_error("no type float",no->right->token);
			// 	}
			// 	table[symbol_count].type = no->left->left->token;
			// 	table[symbol_count].id = no->left->right->token;
			// 	table[symbol_count].value = no->right->token ;
			// 	symbol_count++;
			// 	break;
			// }
//			break;
		
			// if(symbol == -1 && no->right->right != NULL && no->right->left != NULL){
			// 		symbol = check(no->right->left->token);
			// 		symbol2 = check(no->right->right->token);
			// 		operator = atoi(no->right->token);
			// 		printf("operator %c\n",operator);
			// 		if(symbol == -1 && symbol2 == -1){
			// 			znach = atoi(no->right->right->token);
			// 			znach2 = atoi(no->right->left->token);
			// 		}
			// 		if(symbol != -1 && symbol2 == -1){
			// 			znach = atoi(table[symbol].value);
			// 			znach2 = atoi(no->right->left->token);
			// 		}
			// 		if(symbol == -1 && symbol2 != -1){
			// 			znach = atoi(no->right->right->token);
			// 			znach2 = atoi(table[symbol2].value);
			// 		}
					
			// 		printf("aaa %d\n",znach2);
			// 		printf("aaa %d\n",znach);
			// 		break;
			// 	}
			break;

		case TYPE_NEW:
		symbol = check(no->right->token);
			if(symbol != -1){
				printf_error("value declared",no->right->token);
				break;
			}
			if(symbol == -1 ){
				table[symbol_count].id = no->right->token;
				table[symbol_count].type = no->left->token;
				symbol_count++;		
			}
			break;

	
	}

	
}
void printTable(){
	for(int i = 0; i<symbol_count; i++){ 
		printf(" TYPE %s VAR ID %s VALUE %s\n",table[i].type, table[i].id, table[i].value);
	}	
}
int check(const char *x) {
	for(int i = 0; i<symbol_count; i++) {
		if(!strcmp(table[i].id, x)) {
			return i;
		}
	}
	return -1;
}
void printf_error(char *a, char *b){
	printf("ERROR %s %s\n",a,b);
	exit(1);
}
void check_main(){
	if(count_main != 1){
		printf_error("no main",NULL);
	}
}
int arefmetic(int a, int b, char *op){
	if (!strcmp(op ,"+")) {return a+b;}
	if (!strcmp(op , "-")) {return a-b;}
	if (!strcmp(op , "*")) {return a*b;}
	if (!strcmp( op , "/")) {return a/b;}
	return -1;
}
int countIf(int a, int b, char *op){
	//printf("%d %d %s",a, b, op);
	if (!strcmp( op, ">")){
		if(a>b) {return 1;}
		else {return 0;}
	}
	if (!strcmp(op , "<")){
		if(a<b) {return 1;}               
		else {return 0;}
	}
	if (!strcmp(op , ">=")){
		if(a>=b) {return 1;}               
		else {return 0;}
	}
	if (!strcmp(op , "<=")){
		if(a<=b) {return 1;}
		else {return 0;}
	}
	if (!strcmp(op , "==")){
		if(a==b) {return 1;}
		else {return 0;}
	}
	if (!strcmp(op , "!=")){
		if(a != b) {return 1;}
		else {return 0;}
	}else {printf_error("in", op);}
	return -1;
}

