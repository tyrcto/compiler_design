/* A Bison parser, made by GNU Bison 3.8.2.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2021 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

#ifndef YY_YY_MYYACC_TAB_H_INCLUDED
# define YY_YY_MYYACC_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token kinds.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    YYEMPTY = -2,
    YYEOF = 0,                     /* "end of file"  */
    YYerror = 256,                 /* error  */
    YYUNDEF = 257,                 /* "invalid token"  */
    DOT = 258,                     /* DOT  */
    COMMA = 259,                   /* COMMA  */
    COLON = 260,                   /* COLON  */
    SEMICOLON = 261,               /* SEMICOLON  */
    ARROW = 262,                   /* ARROW  */
    PAR_L = 263,                   /* PAR_L  */
    PAR_R = 264,                   /* PAR_R  */
    SBRA_L = 265,                  /* SBRA_L  */
    SBRA_R = 266,                  /* SBRA_R  */
    BRA_L = 267,                   /* BRA_L  */
    BRA_R = 268,                   /* BRA_R  */
    ADD = 269,                     /* ADD  */
    SUB = 270,                     /* SUB  */
    MULT = 271,                    /* MULT  */
    DIVIDE = 272,                  /* DIVIDE  */
    PERCENT = 273,                 /* PERCENT  */
    LE = 274,                      /* LE  */
    LEEQ = 275,                    /* LEEQ  */
    GR = 276,                      /* GR  */
    GREQ = 277,                    /* GREQ  */
    EQ = 278,                      /* EQ  */
    NEQ = 279,                     /* NEQ  */
    AND = 280,                     /* AND  */
    OR = 281,                      /* OR  */
    NOT = 282,                     /* NOT  */
    ASSIGN = 283,                  /* ASSIGN  */
    BOOLEAN = 284,                 /* BOOLEAN  */
    BREAK = 285,                   /* BREAK  */
    CHAR = 286,                    /* CHAR  */
    CASE = 287,                    /* CASE  */
    CLASS = 288,                   /* CLASS  */
    CONTINUE = 289,                /* CONTINUE  */
    DECLARE = 290,                 /* DECLARE  */
    DO = 291,                      /* DO  */
    ELSE = 292,                    /* ELSE  */
    EXIT = 293,                    /* EXIT  */
    FLOAT = 294,                   /* FLOAT  */
    FOR = 295,                     /* FOR  */
    FUN = 296,                     /* FUN  */
    IF = 297,                      /* IF  */
    INT = 298,                     /* INT  */
    LOOP = 299,                    /* LOOP  */
    PRINT = 300,                   /* PRINT  */
    PRINTLN = 301,                 /* PRINTLN  */
    RETURN = 302,                  /* RETURN  */
    STRING = 303,                  /* STRING  */
    VAL = 304,                     /* VAL  */
    VAR = 305,                     /* VAR  */
    WHILE = 306,                   /* WHILE  */
    IN = 307,                      /* IN  */
    ss = 308,                      /* ss  */
    FALSE = 309,                   /* FALSE  */
    TRUE = 310,                    /* TRUE  */
    INT_VAL = 311,                 /* INT_VAL  */
    FLOAT_VAL = 312,               /* FLOAT_VAL  */
    STRING_VAL = 313,              /* STRING_VAL  */
    ID = 314,                      /* ID  */
    CUT = 315,                     /* CUT  */
    UMINUS = 316                   /* UMINUS  */
  };
  typedef enum yytokentype yytoken_kind_t;
#endif

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
union YYSTYPE
{
#line 19 "myyacc.y"

    int intVal;
    float floatVal;
    char* stringVal;

#line 131 "myyacc.tab.h"

};
typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;


int yyparse (void);


#endif /* !YY_YY_MYYACC_TAB_H_INCLUDED  */
