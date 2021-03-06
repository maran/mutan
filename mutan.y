%{
package mutan

import (
	_"fmt"
)

var Tree *SyntaxTree

%}

%union {
	num int
	str string
	tnode *SyntaxTree
}

%token ASSIGN EQUAL IF LEFT_BRACES RIGHT_BRACES STORE LEFT_BRACKET RIGHT_BRACKET ASM LEFT_PAR RIGHT_PAR STOP
%token ADDR ORIGIN CALLER CALLVAL CALLDATALOAD CALLDATASIZE GASPRICE DOT THIS ARRAY CALL COMMA SIZEOF QUOTE
%token <str> ID NUMBER INLINE_ASM OP TYPE STR
%type <tnode> program statement_list statement expression assign_expression simple_expression get_variable
%type <tnode> if_statement op_expression buildins closure_funcs new_var new_array arguments sep get_id string

%%

program
	: statement_list { Tree = $1 }
	;

statement_list
	: statement_list statement { $$ = NewNode(StatementListTy, $1, $2) }
	| /* Empty */ { $$ = NewNode(EmptyTy) }
	;

statement
	: expression { $$ = $1 }
	| if_statement { $$ = $1 }
	| ASM LEFT_PAR INLINE_ASM RIGHT_PAR { $$ = NewNode(InlineAsmTy); $$.Constant = $3 }
	;


buildins
	: STOP LEFT_PAR RIGHT_PAR { $$ = NewNode(StopTy) }
	/*| CALL LEFT_PAR arguments RIGHT_PAR { $$ = NewNode(CallTy, $3) }*/
	| CALL LEFT_PAR get_variable COMMA get_variable COMMA get_variable COMMA get_id COMMA get_id RIGHT_PAR
	  {
		  $$ = NewNode(CallTy, $3, $5, $7, $9, $11)
	  }
	| SIZEOF LEFT_PAR ID RIGHT_PAR { $$ = NewNode(SizeofTy); $$.Constant = $3 }
	| THIS DOT closure_funcs { $$ = $3 }
	;

arguments
	: arguments get_variable sep { $$ = NewNode(ArgTy, $1, $2) }
	| /* Empty */ { $$ = NewNode(EmptyTy) }
	;

sep
	: COMMA { $$ = NewNode(EmptyTy) }
	| /* Empty */ { $$ = NewNode(EmptyTy) }
	;

closure_funcs
	: ORIGIN LEFT_PAR RIGHT_PAR { $$ = NewNode(OriginTy) }
	| CALLER LEFT_PAR RIGHT_PAR { $$ = NewNode(CallerTy) }
	| CALLVAL LEFT_PAR RIGHT_PAR { $$ = NewNode(CallValTy) }
	| CALLDATALOAD LEFT_PAR RIGHT_PAR { $$ = NewNode(CallDataLoadTy) }
	| CALLDATASIZE LEFT_PAR RIGHT_PAR { $$ = NewNode(CallDataSizeTy) }
	| GASPRICE LEFT_PAR RIGHT_PAR { $$ = NewNode(GasPriceTy) }
	;

if_statement
	: IF expression LEFT_BRACES statement_list RIGHT_BRACES { $$ = NewNode(IfThenTy, $2, $4) }
	;

expression
	: op_expression { $$ = $1 }
	| assign_expression { $$ = $1 }
	| /* Empty */  { $$ = NewNode(EmptyTy) }
	;

op_expression
	: expression OP expression { $$ = NewNode(OpTy, $1, $3); $$.Constant = $2 }
	;


assign_expression
	: ID ASSIGN expression
	  {
	      node := NewNode(SetLocalTy)
	      node.Constant = $1
	      $$ = NewNode(AssignmentTy, $3, node)
	  }
	| ID LEFT_BRACKET expression RIGHT_BRACKET ASSIGN assign_expression
	  {
	      $$ = NewNode(AssignArrayTy, $3, $6); $$.Constant = $1
	  }
	| new_var ASSIGN expression
	  {
	      node := NewNode(SetLocalTy)
	      node.Constant = $1.Constant
	      $$ = NewNode(AssignmentTy, $3, $1, node)
	  }
	| new_var { $$ = $1 }
	| new_array { $$ = $1 }
	| STORE LEFT_BRACKET expression RIGHT_BRACKET ASSIGN expression
	  {
	      node := NewNode(SetStoreTy, $3)
	      $$ = NewNode(AssignmentTy, $6, node)
	  }
	| simple_expression { $$ = $1 }
	;

new_var
	: TYPE ID
	  {
	
	      $$ = NewNode(NewVarTy)
	      $$.Constant = $2
	      $$.VarType = $1
	  }

new_array
	: TYPE LEFT_BRACKET NUMBER RIGHT_BRACKET ID
	  {
	      $$ = NewNode(NewArrayTy)
	      $$.VarType = $1
	      $$.Size = $3
	      $$.Constant = $5
	      
	  }
	;

simple_expression
	: get_variable { $$ = $1 }
	;

get_variable
	: get_id { $$ = $1 }
	| NUMBER { $$ = NewNode(ConstantTy); $$.Constant = $1 }
	| ID LEFT_BRACKET expression RIGHT_BRACKET { $$ = NewNode(ArrayTy, $3); $$.Constant = $1 }
	| STORE LEFT_BRACKET expression RIGHT_BRACKET { $$ = NewNode(StoreTy, $3) }
	| string { $$ = $1 }
	| buildins { $$ = $1 }
	;

get_id
	: ID { $$ = NewNode(IdentifierTy); $$.Constant = $1 }
	;

string 
	: QUOTE STR QUOTE { $$ = NewNode(StringTy); $$.Constant = $2 }
	;

%%

