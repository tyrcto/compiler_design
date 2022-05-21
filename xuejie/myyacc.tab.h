/* A Bison parser, made by GNU Bison 3.0.4.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015 Free Software Foundation, Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

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

#ifndef YY_YY_MYYACC_TAB_H_INCLUDED
# define YY_YY_MYYACC_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token type.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    DOT = 258,
    COMMA = 259,
    COLON = 260,
    SEMICOLON = 261,
    ARROW = 262,
    PAR_L = 263,
    PAR_R = 264,
    SBRA_L = 265,
    SBRA_R = 266,
    BRA_L = 267,
    BRA_R = 268,
    ADD = 269,
    SUB = 270,
    MULT = 271,
    DIVIDE = 272,
    PERCENT = 273,
    LE = 274,
    LEEQ = 275,
    GR = 276,
    GREQ = 277,
    EQ = 278,
    NEQ = 279,
    AND = 280,
    OR = 281,
    NOT = 282,
    ASSIGN = 283,
    BOOLEAN = 284,
    BREAK = 285,
    CHAR = 286,
    CASE = 287,
    CLASS = 288,
    CONTINUE = 289,
    DECLARE = 290,
    DO = 291,
    ELSE = 292,
    EXIT = 293,
    FLOAT = 294,
    FOR = 295,
    FUN = 296,
    IF = 297,
    INT = 298,
    LOOP = 299,
    PRINT = 300,
    PRINTLN = 301,
    RETURN = 302,
    STRING = 303,
    VAL = 304,
    VAR = 305,
    WHILE = 306,
    IN = 307,
    ss = 308,
    FALSE = 309,
    TRUE = 310,
    INT_VAL = 311,
    FLOAT_VAL = 312,
    STRING_VAL = 313,
    ID = 314,
    CUT = 315,
    UMINUS = 316
  };
#endif

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED

union YYSTYPE
{
#line 21 "myyacc.y" /* yacc.c:1909  */

    int intVal;
    float floatVal;
    char* stringVal;

#line 122 "myyacc.tab.h" /* yacc.c:1909  */
};

typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;

int yyparse (void);

#endif /* !YY_YY_MYYACC_TAB_H_INCLUDED  */
