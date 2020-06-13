#include "utils.h"

//initialization
node_table *my_tables = NULL;
int tmp_value = 1;
int index_label = 0;

/**
 * @brief Initialize first table
 * 
 */
void init_table() {
    my_tables = (node_table *)malloc(sizeof(node_table));
    my_tables->symbol_table = NULL;
    my_tables->prev_node_table = NULL;
}

/**
* @brief Create a new table as the new current table. Update the previous table
* 
*/
void create_new_table() {
    node_table *tmp = (node_table *)malloc(sizeof(node_table));
    tmp->symbol_table = NULL;
    tmp->prev_node_table = my_tables;
    my_tables = tmp;
}

/**
* @brief Add variable to the current symbol table
* 
* @param id 
*/
void addVar(char *id) {
    variable *tmp;
    HASH_FIND_STR(my_tables->symbol_table, id, tmp);
    if (tmp == NULL) {
        tmp = (variable *)malloc(sizeof(variable));
        tmp->id = id;
        tmp->value = 0;
        HASH_ADD_KEYPTR(hh, my_tables->symbol_table, tmp->id,
                        strlen(tmp->id), tmp);
    } else {
        printf("ERROR: multiple definition for variable %s\n", id);
        exit(-1);
    }
}

/**
* @brief Set the Var value
* 
* @param id 
* @param value 
*/
void setVar(char *id, int value) {
    variable *tmp;
    node_table *current_table = my_tables;
    int done = 0;
    while (!done) {
        HASH_FIND_STR(current_table->symbol_table, id, tmp);
        if (tmp == NULL) {
            if (current_table->prev_node_table == NULL) {
                printf("ERROR: variable %s is not defined\n", id);
                exit(-1);
            } else
                current_table = current_table->prev_node_table;
        } else
            done = 1;
    }
    tmp->value = value;
}

/**
* @brief Get the Var value
* 
* @param id 
* @return int 
*/
int getVar(char *id) {
    variable *tmp;
    node_table *current_table = my_tables;
    int done = 0;
    while (!done) {
        HASH_FIND_STR(current_table->symbol_table, id, tmp);
        if (tmp == NULL) {
            if (current_table->prev_node_table == NULL) {
                printf("ERROR: variable %s is not defined\n", id);
                exit(-1);
            } else
                current_table = current_table->prev_node_table;
        } else
            done = 1;
    }
    return tmp->value;
}

/**
* @brief Delete and Free current table
* 
*/
void delete_current_table() {
    variable *current_user, *tmp;
    HASH_ITER(hh, my_tables->symbol_table, current_user, tmp) {
        //printf("%s ::: %d\n\n", current_user->id, current_user->value);
        HASH_DEL(my_tables->symbol_table, current_user); /* delete; users advances to next */
        free(current_user);                              /* optional- if you want to free  */
    }

    if (my_tables->prev_node_table != NULL) {
        node_table *node_tmp;
        node_tmp = my_tables->prev_node_table;
        free(my_tables);
        my_tables = node_tmp;
    } else
        free(my_tables);  //used at the end of the file
}

/**
 * @brief Generates a new temp variable name
 * 
 * @param tmp_string String to fill
 */
void gen_tmp(char *tmp_string) {
    sprintf(tmp_string, "t%d", tmp_value);
    tmp_value++;
}

/**
 * @brief Generates a new Label
 * 
 * @param label String  to fill
 */
void gen_label(char *label) {
    sprintf(label, "L%d", index_label);
    index_label++;
}

/**
 * @brief Insert string in the linked list
 * 
 * @param variable_name Name of the variable
 * @param end_list Pointer to the end of the linked list
 * @return int Return code: 0 if successful and nonzero if an error occurs
 */
int insert_string(char *variable_name, node_string **end_list) {
    if (*end_list == NULL)
        return 1;
    node_string *new_node = malloc(sizeof(node_string));
    new_node->next_string = NULL;
    new_node->variable_string = NULL;
    (*end_list)->variable_string = variable_name;
    (*end_list)->next_string = new_node;
    *end_list = new_node;
    return 0;
}

/**
 * @brief Print all strings in the linked list
 * 
 * @param mystrings Pointer to the top of the linked list
 * @return int Return code: 0 if successful and nonzero if an error occurs
 */
int print_all(node_string *mystrings, node_string *tmp_string) {
    if (mystrings == NULL)
        return 1;

    int done = 0;
    while (!done) {
        if (tmp_string->variable_string == NULL)
            done = 1;
        else {
            printf("int %s;\n", tmp_string->variable_string);
            tmp_string = tmp_string->next_string;
        }
    }

    done = 0;
    while (!done) {
        if (mystrings == NULL)
            printf("NULL!");
        if (mystrings->variable_string == NULL)
            done = 1;
        else {
            printf("%s\n", mystrings->variable_string);
            mystrings = mystrings->next_string;
        }
    }
    return 0;
}

/**
 * @brief Remove linked list from the memory
 * 
 * @param mystrings Pointer to the top of the linked list
 * @return int Return code: 0 if successful and nonzero if an error occurs
 */
int free_all(node_string **mystrings) {
    if (*mystrings == NULL)
        return 1;
    int done = 0;
    node_string *tmp;
    while (!done) {
        if ((*mystrings)->variable_string == NULL) {
            done = 1;
            free(*mystrings);
            *mystrings = NULL;
        } else {
            free((*mystrings)->variable_string);
            tmp = (*mystrings)->next_string;
            free(*mystrings);
            *mystrings = tmp;
        }
    }
    return 0;
}