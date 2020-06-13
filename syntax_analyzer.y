%{
    #include "utils.h"
    int yylex();
    void yyerror(char *s);

    node_string *tmp_string;
    node_string *end_tmp;

    node_string *commands;
    node_string *end_commands;

    node_string *to_free;
    node_string *end_to_free;
%}


%union {
    int number;
    int is_cond;
    char *identifier;
    struct {
        char *true_label;
        char *false_label;
    } label;

    char *next;
}

%token <number> NUMBER IF WHILE
%token <identifier> ID RELOP
%token INT ENDMARKER ASSIGN PRINT ENDFILE

%type <identifier> expr
%type <identifier> bexpr 
%type <identifier> comp
%type <label> blabel
%type <next> nextlabel
%type <next> liststmt
%type <next> print_if
%type <next> print_while
%type <next> print_else
%type <is_cond> stmt
%type <next> whilelabel


%nonassoc EXPR_PRECEDENCE
%left '(' ')'
%right ELSE
%left '+' '-'
%left '*' '/'
%right UMINUS
%nonassoc ASSIGN_PRECEDENCE
%nonassoc ENDMARKER
%left OR
%left AND
%right NOT
%nonassoc RELOP

%%
program : liststmt ENDFILE                  {
                                                delete_current_table(); //delete last symbol table
                                                char *command = calloc(100, sizeof(char));
                                                sprintf(command, "delete_current_table();");
                                                insert_string(command, &end_commands);
                                                return 0;
                                            }                    
        ;

liststmt : liststmt stmt        {
                                    if($2 == 1) {
                                        //print label after condition
                                        char *command = calloc(100, sizeof(char));
                                        sprintf(command, "%s :", $1);
                                        insert_string(command, &end_commands);

                                        //update next label
                                        char *new_label = calloc(100, sizeof(char));
                                        gen_label(new_label);
                                        insert_string(new_label, &end_to_free); //to free memory
                                        $$ = new_label;
                                    }
                                    else
                                        $$ = $1;
                                }
         | nextlabel stmt       { 
                                    if($2 == 1) {
                                        //print label after condition
                                        char *command = calloc(100, sizeof(char));
                                        sprintf(command, "%s :", $1);
                                        insert_string(command, &end_commands);

                                        //update next label
                                        char *new_label = calloc(100, sizeof(char));
                                        gen_label(new_label);
                                        insert_string(new_label, &end_to_free); //to free memory
                                        $$ = new_label;
                                    }
                                    else
                                        $$ = $1; 
                                }            
         ;  

nextlabel   :   {
                    //generate the first next label
                    char *new_label = calloc(100, sizeof(char));
                    gen_label(new_label);
                    insert_string(new_label, &end_to_free); //to free memory
                    $$ = new_label;
                } 
            ;

stmt    :   INT ID ENDMARKER                    {
                                                    addVar($2);
                                                    char *command = calloc(100, sizeof(char));
                                                    sprintf(command,"addVar(\"%s\");", $2);
                                                    insert_string(command, &end_commands);
                                                    $$ = 0;
                                                }
        |   INT  ID ASSIGN bexpr ENDMARKER      { 
                                                    addVar($2);
                                                    char *command = calloc(100, sizeof(char));
                                                    sprintf(command,"addVar(\"%s\");\nsetVar(\"%s\", %s);", $2, $2, $4);
                                                    insert_string(command, &end_commands);
                                                    $$ = 0;
                                                }
        |   ID ASSIGN bexpr ENDMARKER           {
                                                    getVar($1); //check if var is already defined
                                                    char *command = calloc(100, sizeof(char));
                                                    sprintf(command, "setVar(\"%s\", %s);", $1, $3);
                                                    insert_string(command, &end_commands);
                                                    $$ = 0;
                                                }
        |   PRINT '(' ID ')' ENDMARKER          {
                                                    char *command = calloc(100, sizeof(char));
                                                    sprintf(command, "printf(\"%%s : %%d\\n\", \"%s\", getVar(\"%s\"));", $3, $3);
                                                    insert_string(command, &end_commands);
                                                    $$ = 0;
                                                }
        |   openbracket liststmt closebracket   { $$ = 0; }
        |   '{' '}'                             { $$ = 0; }
        |   IF '(' blabel bexpr ')' print_if stmt                       { 
                                                                            char *command = calloc(100, sizeof(char));
                                                                            sprintf(command, "%s :", $3.false_label);
                                                                            insert_string(command, &end_commands);
                                                                            $$ = 1; 
                                                                        }
        |   IF '(' blabel bexpr ')' print_if stmt ELSE print_else stmt  { $$ = 1; }
        |   whilelabel WHILE '(' blabel bexpr ')' print_while stmt      {
                                                                            char *command = calloc(100, sizeof(char));
                                                                            sprintf(command, "goto %s;", $1);
                                                                            insert_string(command, &end_commands);
                                                                            $$ = 1;
                                                                        }
        ;

print_if :  {
                //init if 3AC code
                char *command = calloc(100, sizeof(char));
                sprintf(command, "if(%s) goto %s;\ngoto %s;\n%s :", $<identifier>-1, $<label>-2.true_label, $<label>-2.false_label, $<label>-2.true_label);
                insert_string(command, &end_commands);
                $$ = $<next>-5; //S.next
            }
         ;

print_while :   {
                    //init while   3AC code
                    char *command = calloc(100, sizeof(char));
                    sprintf(command, "if(%s) goto %s;\ngoto %s;\n%s :", $<identifier>-1, $<label>-2.true_label, $<next>-6, $<label>-2.true_label);
                    insert_string(command, &end_commands);
                    $$ = $<next>-5; //S.next
                }
            ;

print_else  :   {
                    //init else code
                    char *command = calloc(100, sizeof(char));
                    sprintf(command, "goto %s;\n%s :",$<next>-2, $<label>-5.false_label);
                    insert_string(command, &end_commands);
                    $$ = $<next>-2; //S.next
                }
            ;


blabel  :       {
                    //generate true and false label
                    char *new_label = calloc(100, sizeof(char));
                    gen_label(new_label);
                    insert_string(new_label, &end_to_free);   //to free memory
                    $$.true_label = new_label;
                    //check about Condition. 0 for IF, 1  for WHILE.
                    if($<number>-1== 0) {
                        char *new_label_false = calloc(100, sizeof(char));
                        gen_label(new_label_false);
                        insert_string(new_label_false, &end_to_free);   //to free memory
                        $$.false_label = new_label_false;
                    }
                    else
                        $$.false_label = $<next>-3;
                }
        ;

whilelabel  :               {
                                //generate label for loop
                                char *new_label = calloc(100, sizeof(char));
                                char *command = calloc(100, sizeof(char));
                                gen_label(new_label);
                                insert_string(new_label, &end_to_free);
                                sprintf(command, "%s :", new_label);
                                insert_string(command, &end_commands);
                                $$ = new_label;
                            }

openbracket : '{'           {
                                create_new_table();
                                char *command = calloc(100, sizeof(char));
                                sprintf(command, "create_new_table();");
                                insert_string(command, &end_commands);
                            }
            ;  

closebracket : '}'          {
                                delete_current_table();
                                char *command = calloc(100, sizeof(char));
                                sprintf(command, "delete_current_table();");
                                insert_string(command, &end_commands);
                            }
             ;

bexpr   :   bexpr OR bexpr                  {
                                                char *tmp_variable, *comp_string;
                                                tmp_variable = calloc(100,sizeof(char));
                                                comp_string = calloc(100,sizeof(char));
                                                gen_tmp(tmp_variable);
                                                sprintf(comp_string, "%s = %s || %s;",tmp_variable,$1,$3);
                                                insert_string(tmp_variable, &end_tmp);
                                                insert_string(comp_string, &end_commands);
                                                $$ = tmp_variable;
                                            }
        |   bexpr AND bexpr                 {
                                                char *tmp_variable, *comp_string;
                                                tmp_variable = calloc(100,sizeof(char));
                                                comp_string = calloc(100,sizeof(char));
                                                gen_tmp(tmp_variable);
                                                sprintf(comp_string, "%s = %s && %s;",tmp_variable,$1,$3);
                                                insert_string(tmp_variable, &end_tmp);
                                                insert_string(comp_string, &end_commands);
                                                $$ = tmp_variable;
                                            }
        |   NOT bexpr                       {
                                                char *tmp_variable, *comp_string;
                                                tmp_variable = calloc(100,sizeof(char));
                                                comp_string = calloc(100,sizeof(char));
                                                gen_tmp(tmp_variable);
                                                sprintf(comp_string, "%s = ! %s;",tmp_variable,$2);
                                                insert_string(tmp_variable, &end_tmp);
                                                insert_string(comp_string, &end_commands);
                                                $$ = tmp_variable;
                                            }
        |   '(' bexpr ')'                   { $$ = $2; }
        |   ID ASSIGN bexpr  %prec ASSIGN_PRECEDENCE      
                                            {
                                                getVar($1); //check if var is already defined
                                                char *command = calloc(100, sizeof(char));
                                                sprintf(command, "setVar(\"%s\", %s);", $1, $3);
                                                insert_string(command, &end_commands);
                                                char *command2 = calloc(100, sizeof(char));
                                                sprintf(command2, "getVar(\"%s\")",$1);
                                                $$ = command2;
                                            }
        |   comp
        |   expr %prec EXPR_PRECEDENCE
        ;

comp    :   expr RELOP expr                    { 
                                                char *tmp_variable, *comp_string;
                                                tmp_variable = calloc(100,sizeof(char));
                                                comp_string = calloc(100,sizeof(char));
                                                gen_tmp(tmp_variable);
                                                sprintf(comp_string, "%s = %s %s %s;", tmp_variable, $1, $2, $3);
                                                insert_string(tmp_variable, &end_tmp);
                                                insert_string(comp_string, &end_commands);
                                                $$ = tmp_variable;
                                            }     
        ;

expr    :   expr '+' expr                   {
                                                char *tmp_variable, *expr_string;
                                                tmp_variable = calloc(100,sizeof(char));
                                                expr_string = calloc(100,sizeof(char));
                                                gen_tmp(tmp_variable);
                                                sprintf(expr_string, "%s = %s + %s;",tmp_variable,$1,$3);
                                                insert_string(tmp_variable, &end_tmp);
                                                insert_string(expr_string, &end_commands);
                                                $$ = tmp_variable;
                                            }
        |   expr '-' expr                   { 
                                                char *tmp_variable, *expr_string;
                                                tmp_variable = calloc(100,sizeof(char));
                                                expr_string = calloc(100,sizeof(char));   
                                                gen_tmp(tmp_variable);
                                                sprintf(expr_string, "%s = %s - %s;",tmp_variable,$1,$3);
                                                insert_string(tmp_variable, &end_tmp);
                                                insert_string(expr_string, &end_commands);
                                                $$ = tmp_variable;
                                            }
        |   expr '*' expr                   { 
                                                char *tmp_variable, *expr_string;
                                                tmp_variable = calloc(100,sizeof(char));
                                                expr_string = calloc(100,sizeof(char));
                                                gen_tmp(tmp_variable);
                                                sprintf(expr_string, "%s = %s * %s;",tmp_variable,$1,$3);
                                                insert_string(tmp_variable, &end_tmp);
                                                insert_string(expr_string, &end_commands);
                                                $$ = tmp_variable;
                                            }
        |   expr '/' expr                   { 
                                                char *tmp_variable, *expr_string;
                                                tmp_variable = calloc(100,sizeof(char));
                                                expr_string = calloc(100,sizeof(char));
                                                gen_tmp(tmp_variable);
                                                sprintf(expr_string, "%s = %s / %s;",tmp_variable,$1,$3);
                                                insert_string(tmp_variable, &end_tmp);
                                                insert_string(expr_string, &end_commands);
                                                $$ = tmp_variable;
                                            }
        |   '(' expr ')'                    { $$ = $2;}
        |   '-' expr    %prec UMINUS        { 
                                                char *tmp_variable, *expr_string;
                                                tmp_variable = calloc(100,sizeof(char));
                                                expr_string = calloc(100,sizeof(char));
                                                gen_tmp(tmp_variable);
                                                sprintf(expr_string,"%s = -%s;",tmp_variable,$2);
                                                insert_string(tmp_variable, &end_tmp);
                                                insert_string(expr_string, &end_commands);
                                                $$ = tmp_variable;
                                            }            
        |   '+' expr    %prec UMINUS        {   
                                                char *tmp_variable, *expr_string;
                                                tmp_variable = calloc(100,sizeof(char));
                                                expr_string = calloc(100,sizeof(char));
                                                gen_tmp(tmp_variable);
                                                sprintf(expr_string,"%s = +%s;",tmp_variable,$2);
                                                insert_string(tmp_variable, &end_tmp);
                                                insert_string(expr_string, &end_commands);
                                                $$ = tmp_variable;
                                            }
        |   ID                              {   
                                                getVar($1); //check if var is already defined
                                                char *id_string;
                                                id_string = calloc(100,sizeof(char));
                                                sprintf(id_string, "getVar(\"%s\")", $1);
                                                insert_string(id_string, &end_to_free);   //to free memory
                                                $$ = id_string;
                                            }
        |   NUMBER                          { 
                                                char *expr_string =  calloc(100,sizeof(char));
                                                sprintf(expr_string,"%d", $1);
                                                insert_string(expr_string, &end_to_free);   //to free memory
                                                $$ = expr_string;
                                            }
        ;
%%
int main(){
    // yydebug = 1;
    //init my tables
    init_table();

    //init node_strings
    tmp_string = (node_string *)malloc(sizeof(node_string));
    end_tmp = tmp_string;
    commands = (node_string *)malloc(sizeof(node_string));
    end_commands = commands;
    to_free = (node_string *)malloc(sizeof(node_string));
    end_to_free = to_free;

    char *command = calloc(100, sizeof(char));
    sprintf(command, "init_table();");
    insert_string(command, &end_commands);

    //start parsing
    if(yyparse() !=0){
        fprintf(stderr,"Abnormal exit\n");
    } else {
        //print all commands
        print_all(commands, tmp_string);
    }
    
    //free memory
    free_all(&tmp_string);
    free_all(&commands);
    free_all(&to_free);
    return 0;
}

void  yyerror(char *s){
    fprintf(stderr, "Error: %s\n",s);
}