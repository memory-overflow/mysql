%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <stdbool.h>
#define N 20
void yyerror(char *s, ...);
void emit(char *s, ...);
//char *database;

//字段信息
struct tableField {
    char *field;  //字段
    int type;    // 0 int ;1 char
    int length;
    struct tableField *nextfield;
};
//表名
struct createStruct {
    char *table;
    struct tableField * tfield;
};
//运行时存储的数据库和表的相关信息
typedef struct dbs {
    char *dbname;
    struct createStruct *table;
    struct dbs *nextdb;
    }DBS;
DBS *head=NULL;

//select struct
struct selectTable {
    char *table;
    struct selectTable *next;
};
struct selectFields {
    char *table;
    char *field;
    struct selectFields *next;
};
struct selectConditions {
    struct selectConditions *left;
    struct selectConditions *right;
    char comp_op;
    int type;
    char *value;
    char *table;
};
struct selectStruct {
    struct selectTable  *table;
    struct selectFields *fields;
    struct selectconditions *cons;
};
bool createdb (char *dbname);
bool createtable(struct createStruct *table);
void showtable();
void showinfo();
%}
%union {
        int ival;
        char *sval;

        struct tableField *tf;
        struct createStruct *cs;

        struct selectConditions *sc;
        struct selectFields  *sf;
        struct selectTable *st;
        struct selectStruct  *ss;
}
%token <ival> NUMBER
%token <sval> TABLE
%token <sval> CHAR
%token <sval> INT
%token <sval> CREATE
%token <sval> DATABASE
%token <sval> SELECT
%token <sval> FROM
%token <sval> VAR
%token <sval> WHERE
%token <sval> AND
%token <sval> OR
%token <sval> DELETE
%token <sval> USE
%token <sval> DROP
%token <sval> UPDATE
%token <sval> INSERT
%token <sval> SET
%token <sval> INTO
%token <sval> VALUES
%token <sval> SHOW
%token <sval> TABLES

%type <sval> dbs
%type <ival> table
%type <ival> field
%type <ival> comp_left
%type <ival> comp_right
%type <ival> comp_op

%type <cs> create_tables_sql
%type <tf> fieldsdefinition
%type <tf> field_type
%type <tf> type

%type <sval> table_name
%type <tf> fieldtype

%type <ss> select_sql 
%type <sf> select_fields  
%type <sf> fields  
%type <st> tables
%type <sc> select_condition
%type <sc> select_conditions

%left OR
%left AND
%start sqls
%%
sqls: sql ';'
| sqls sql ';'
;

sql:  create_database_sql
        {
           if(createdb(yylval.sval))
            printf("create db %s succeed!\n",yylval.sval);
            else
            printf("create db %s failed!\n",yylval.sval);
            printf("sql>");
            //printf("%s",head->dbname);
        }
   |  create_tables_sql 
        {
        if(createtable($1))
            printf("create table %s succeed!\n",$1->table);
        else 
            printf("create table %s failed!\n",$1->table);
 //           showinfo();
            printf("sql>");
        //printf("table %s type %d filed %s length %d\n",$1->table,$1->tfield->type,$1->tfield,$1->tfield->length);
        }
   |  select_sql {}
   |  delete_sql {}
   |  use_database_sql {}
   |  drop_table_sql
   |  drop_database_sql
   |  update_sql
   |  insert_sql
   |  show_table_sql
    
//create database sql
create_database_sql: CREATE DATABASE dbs   {}
dbs: VAR  {
      //  emit("create database %s succeed!",$1);
       // printf("sql>");
        } 
//create tables sql
create_tables_sql:  CREATE TABLE table_name '(' fieldsdefinition ')' 
                 {
                 $$=(struct createStruct*)malloc(sizeof(struct createStruct));
                 $$->table=$3;
                 $$->tfield=$5;
                 //printf("%s",$$->tfield->length);
                 }
table_name: VAR 
          {
          }
fieldsdefinition:field_type 
                 {
                    $$=(struct tableField*)malloc(sizeof(struct tableField));
                    $$=$1;
                 }
                | fieldsdefinition ',' field_type 
                {
                    $$=(struct tableField*)malloc(sizeof(struct tableField));
                    $$->nextfield=$3;
                }
field_type:fieldtype type  
           {
            //$$->field=(char*)malloc(sizeof(char));
            //$$->field=$1;
           }
fieldtype: VAR {}
type: CHAR '(' NUMBER ')' 
      {
        $$->type=1; 
        $$->length=$3; 
      }
    | INT {$$->type=0;}
//select sql
select_sql: SELECT select_fields FROM tables {
        emit("SELECT %s field FROM %d table", $2, $4);
        printf("sql>");
}
        |  SELECT select_fields FROM tables WHERE select_conditions {printf("select success!\n");}
select_fields:fields
             | '*' {}
fields: field {
//        $$ = 1;
}
        | fields ',' field {
       // $$ = $1 + 1;
     //char *a=$1;
     //printf("%s",a);
}
field: VAR {
//        emit("filed %s", $1);
} 
    | table '.' VAR

tables: table {
}
    | tables ',' table {
        $$ = $1 + 1;
}
table: VAR {
        //emit("table %s", $1);
}
select_conditions: select_condition 
                 | '(' select_conditions ')' 
                 | select_conditions AND select_conditions 
                 | select_conditions OR select_conditions 
select_condition:comp_left comp_op comp_right
comp_left:field
comp_right:field
          |NUMBER
comp_op: '<'
       | '>'
       | '='
       | '!''='

//delete sql 
delete_sql:DELETE FROM  table_name {printf("delete from succeed\nsql>");}
          |DELETE FROM  table_name WHERE delete_conditions {printf("condition delete succeed\nsql>");}
delete_conditions:select_conditions 

//choose the databse 
use_database_sql:USE DATABASE dbs {printf("use database succeed\nsql>");}

//drop tabel and drop dbs
drop_table_sql: DROP TABLE table_name {printf("yes\nsql>");}
drop_database_sql:DROP DATABASE dbs {printf("yes\nsql>");} 

//update sql
update_sql:UPDATE table_name SET set_opt WHERE find_opt {printf("yes\nsql>");}
set_opt:select_conditions 
find_opt:select_conditions

//insert sql
insert_sql:INSERT INTO table_name SET set_opt {printf("yes\nsql>"); }

//show table sql
show_table_sql: SHOW TABLES
              {
                showtable();
              }
%%
void yyerror(char *s, ...)
{
        extern yylineno;

        va_list ap;
        va_start(ap, s);

        fprintf(stderr, "line %d, error: ", yylineno);
        vfprintf(stderr, s, ap);
        fprintf(stderr, "\n");
}
void emit(char *s, ...)
{
        extern yylineno;

        va_list ap;
        va_start(ap, s);

        fprintf(stdout, "line %d, sql_parse: ", yylineno);
        vfprintf(stdout, s, ap);
        fprintf(stdout, "\n");
}

bool createdb(char *dbname)
{
    head=(DBS*)malloc(sizeof(DBS));
    if( NULL == head )
    return false;
    else 
    {
        head->dbname=dbname;
        return true;
    }
}
bool createtable(struct createStruct *table)
{
    if(head!=NULL)
    {
      head->table=table;
      return true;
    }
    else
    {
      printf("please create db first\n");
      return false;
    }
 showinfo();
}
void showinfo()
{
    printf("dbname is %s,",head->dbname);
    printf("tablename is %s,",head->table->table);
 /*
 printf("dbname is %s,",head->dbname);
    printf("dbname is %s,",head->dbname);
    printf("dbname is %s,",head->dbname);
    */
    }
void showtable()
{
    printf("table in db %s\n",head->dbname);
    printf("%s\nsql>",head->table->table);
}
