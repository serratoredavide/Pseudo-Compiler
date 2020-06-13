#include <ctype.h>
#include <stdio.h>

#include "uthash.h"

typedef struct variable {
    const char *id;  //hash key
    int value;
    UT_hash_handle hh;  //make structure hashable
} variable;

typedef struct node_table {
    variable *symbol_table;
    struct node_table *prev_node_table;
} node_table;

typedef struct node_string {
    char *variable_string;
    struct node_string *next_string;
}node_string;

extern node_table *my_tables;
extern int tmp_value;

void init_table();
void create_new_table();
void addVar(char *id);
void setVar(char *id, int value);
int getVar(char *id);
void delete_current_table();
void gen_tmp(char *tmp_string);
void gen_label(char *label);

int insert_string(char *variable_name, node_string **end_list);
int print_all(node_string *mystrings, node_string *tmp_string);
int free_all(node_string **mystrings);