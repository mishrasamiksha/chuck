

D           [0-9]
L           [a-zA-Z_]
H           [a-fA-F0-9]
E           [Ee][+-]?{D}+
FS          (f|F|l|L)
IS          (u|U|l|L)*


%{
/*----------------------------------------------------------------------------
    ChucK Concurrent, On-the-fly Audio Programming Language
      Compiler and Virtual Machine

    Copyright (c) 2004 Ge Wang and Perry R. Cook.  All rights reserved.
      http://chuck.cs.princeton.edu/
      http://soundlab.cs.princeton.edu/

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
    U.S.A.
-----------------------------------------------------------------------------*/

//-----------------------------------------------------------------------------
// file: chuck.yy.c
// desc: chuck lexer
//
// author: Ge Wang (gewang@cs.princeton.edu) - generated by lex
//         Perry R. Cook (prc@cs.princeton.edu)
//
// initial version created by Ge Wang;
// based on ansi C grammar by Jeff Lee, maintained by Jutta Degener
//
// date: Summer 2002
//-----------------------------------------------------------------------------

#include <stdlib.h>
#include <string.h>
#ifndef __PLATFORM_WIN32__
#include <unistd.h>
#endif
#include "chuck_utils.h"
#include "chuck_absyn.h"
#include "chuck_errmsg.h"

#if !defined(__PLATFORM_WIN32__) && !defined(__ANDROID__) && !defined(__EMSCRIPTEN__)
  #include "chuck.tab.h"
#else
  #include "chuck_yacc.h"
#endif


// globals
extern YYSTYPE yylval;
// 1.5.0.5 (ge) added for precise location tracking
extern YYLTYPE yylloc;
// 1.5.0.5 (ge) added
t_CKINT yycolumn = 1;

// define error handling
#define YY_FATAL_ERROR(msg) EM_error2( 0, msg )

#if defined(_cplusplus) || defined(__cplusplus)
extern "C" {
#endif

  // function prototypes
  int yywrap(void);
  void adjust();
  c_str strip_lit( c_str str );
  c_str alloc_str( c_str str );
  long htol( c_str str );

  // 1.5.0.5 (ge) added
  void a_newline( void );
  void yycleanup( void );
  void yyinitial( void );
  void yyflush( void );

#if defined(_cplusplus) || defined(__cplusplus)
}
#endif

// yycleanup | 1.5.0.5 (ge)
void yycleanup( void )
{
    // clean up the FILE
    if( yyin )
    {
        fclose( yyin );
        yyin = NULL;
    }
}

// yyflush | 1.5.0.5 (ge)
void yyflush( void )
{
    // flush the buffer
    YY_FLUSH_BUFFER;
}

// yyinitial | 1.5.0.5 (ge)
void yyinitial( void )
{
    // set to initial
    BEGIN(YY_START);
    // reset
    yycolumn = 1;
    EM_tokPos = yycolumn;
    yylloc.first_line   = yylloc.last_line   = 1;
    yylloc.first_column = yylloc.last_column = 0;
}

// yywrap()
int yywrap( void )
{
    yycolumn = 1;
    return 1;
}

// new line
void a_newline()
{
    EM_newline( yylloc.last_column );
}

// manually advance
void advance_m()
{
    yycolumn++;
    yylloc.first_column++;
    yylloc.last_column++;
}

// adjust()
void adjust()
{
    // update tok pos
    EM_tokPos = yylloc.first_column;

    // handy debug print for precise position and bounds of each token
    // fprintf( stderr, "yylloc: %d %ld %d %d ------ %s\n", yylloc.first_line, yycolumn, yylloc.last_line, yylloc.last_column, yytext );
}

// strip
c_str strip_lit( c_str str )
{
    str[strlen(str)-1] = '\0';
    return str+1;
}

// alloc_str()
c_str alloc_str( c_str str )
{
    c_str s = (c_str)malloc( strlen(str) + 1 );
    strcpy( s, str );

    return s;
}

// to long
long htol( c_str str )
{
    char * c = str;
    unsigned long n = 0;

    // skip over 0x
    c += 2;
    while( *c )
    {
        n <<= 4; 
        switch( *c )
        {
        case '1': case '2': case '3': case '4': case '5':
        case '6': case '7': case '8': case '9': case '0':
            n += *c - '0';
            break;

        case 'a': case 'b': case 'c': case 'd': case 'e': case 'f':
            n += *c - 'a' + 10;
            break;

        case 'A': case 'B': case 'C': case 'D': case 'E': case 'F':
            n += *c - 'A' + 10;
            break;
        }    
        c++;
    }

    return n;
}


// block comment hack
#define block_comment_hack loop: \
    while ((c = input()) != '*' && c != 0 && c != EOF ) { \
        if( c == '\n' ) { a_newline(); } \
        else { advance_m(); adjust(); } \
    } \
    if( c == EOF ) { \
        adjust(); \
    } else if( (c1 = input()) != '/' && c != 0 ) { \
        advance_m(); \
        adjust(); \
        unput(c1); \
        goto loop; \
    } \
    if( c != 0 ) { advance_m(); advance_m(); adjust(); };


// comment hack
#define comment_hack \
    while( (c = input()) != '\n' && c != '\r' && c != 0 && c != EOF ) ; \
    if( c != 0 ) { \
        if( c == '\n' ) { a_newline(); } \
    }


// 1.5.0.5 added for tracking | (thanks ekeyser + Becca Royal-Gordon)
// https://stackoverflow.com/questions/656703/how-does-flex-support-bison-location-exactly
// https://www.gnu.org/software/bison/manual/html_node/Tracking-Locations.html
#define YY_USER_ACTION yylloc.first_line = yylloc.last_line = yylineno; \
    yylloc.first_column = yycolumn; yylloc.last_column = yycolumn + yyleng - 1; \
    yycolumn += yyleng;


%}

%option yylineno

%%

"//"                    { char c; adjust(); comment_hack; continue; }
"<--"                   { char c; adjust(); comment_hack; continue; }
"/*"                    { char c, c1; adjust(); block_comment_hack; continue; }
" "                     { adjust(); continue; }
"\t"                    { adjust(); continue; }
"\r\n"                  { adjust(); a_newline(); continue; }
"\n"                    { adjust(); a_newline(); continue; }

"++"                    { adjust(); return PLUSPLUS; }
"--"                    { adjust(); return MINUSMINUS; }
"#("                    { adjust(); return POUNDPAREN; }
"%("                    { adjust(); return PERCENTPAREN; }
"@("                    { adjust(); return ATPAREN; }

","                     { adjust(); return COMMA; }
":"                     { adjust(); return COLON; }
"."                     { adjust(); return DOT; }
"+"                     { adjust(); return PLUS; }
"-"                     { adjust(); return MINUS; }
"*"                     { adjust(); return TIMES; }
"/"                     { adjust(); return DIVIDE; }
"%"                     { adjust(); return PERCENT; }
"#"                     { adjust(); return POUND; }
"$"                     { adjust(); return DOLLAR; }

"::"                    { adjust(); return COLONCOLON; }
"=="                    { adjust(); return EQ; }
"!="                    { adjust(); return NEQ; }
"<"                     { adjust(); return LT; }
">"                     { adjust(); return GT; }
"<="                    { adjust(); return LE; }
">="                    { adjust(); return GE; }
"&&"                    { adjust(); return AND; }
"||"                    { adjust(); return OR; }
"&"                     { adjust(); return S_AND; }
"|"                     { adjust(); return S_OR; }
"^"                     { adjust(); return S_XOR; }
">>"                    { adjust(); return SHIFT_RIGHT; }
"<<"                    { adjust(); return SHIFT_LEFT; }
"="                     { adjust(); return ASSIGN; }
"("                     { adjust(); return LPAREN; }
")"                     { adjust(); return RPAREN; }
"["                     { adjust(); return LBRACK; }
"]"                     { adjust(); return RBRACK; }
"{"                     { adjust(); return LBRACE; }
"}"                     { adjust(); return RBRACE; }
";"                     { adjust(); return SEMICOLON; }
"?"                     { adjust(); return QUESTION; }
"!"                     { adjust(); return EXCLAMATION; }
"~"                     { adjust(); return TILDA; }
for                     { adjust(); return FOR; }
while                   { adjust(); return WHILE; }
until                   { adjust(); return UNTIL; }
repeat                  { adjust(); return LOOP; }
continue                { adjust(); return CONTINUE; }
break                   { adjust(); return BREAK; }
if                      { adjust(); return IF; }
else                    { adjust(); return ELSE; }
do                      { adjust(); return DO; }
"<<<"                   { adjust(); return L_HACK; }
">>>"                   { adjust(); return R_HACK; }

return                  { adjust(); return RETURN; }

function                { adjust(); return FUNCTION; }
fun                     { adjust(); return FUNCTION; }
new                     { adjust(); return NEW; }
class                   { adjust(); return CLASS; }
interface               { adjust(); return INTERFACE; }
extends                 { adjust(); return EXTENDS; }
implements              { adjust(); return IMPLEMENTS; }
public                  { adjust(); return PUBLIC; }
protected               { adjust(); return PROTECTED; }
private                 { adjust(); return PRIVATE; }
static                  { adjust(); return STATIC; }
pure                    { adjust(); return ABSTRACT; }
const                   { adjust(); return CONST; }
spork                   { adjust(); return SPORK; }
typeof                  { adjust(); return TYPEOF; }
external                { adjust(); return EXTERNAL; }
global                  { adjust(); return GLOBAL; }

"=>"                    { adjust(); return CHUCK; }
"=<"                    { adjust(); return UNCHUCK; }
"!=>"                   { adjust(); return UNCHUCK; }
"=^"                    { adjust(); return UPCHUCK; }
"@=>"                   { adjust(); return AT_CHUCK; }
"+=>"                   { adjust(); return PLUS_CHUCK; }
"-=>"                   { adjust(); return MINUS_CHUCK; }
"*=>"                   { adjust(); return TIMES_CHUCK; }
"/=>"                   { adjust(); return DIVIDE_CHUCK; }
"&=>"                   { adjust(); return S_AND_CHUCK; }
"|=>"                   { adjust(); return S_OR_CHUCK; }
"^=>"                   { adjust(); return S_XOR_CHUCK; }
">>=>"                  { adjust(); return SHIFT_RIGHT_CHUCK; }
"<<=>"                  { adjust(); return SHIFT_LEFT_CHUCK; }
"%=>"                   { adjust(); return PERCENT_CHUCK; }
"@"                     { adjust(); return AT_SYM; }
"@@"                    { adjust(); return ATAT_SYM; }
"->"                    { adjust(); return ARROW_RIGHT; }
"<-"                    { adjust(); return ARROW_LEFT; }

0[xX][0-9a-fA-F]+{IS}?  { adjust(); yylval.ival=htol(yytext); return NUM; }
0[cC][0-7]+{IS}?        { adjust(); yylval.ival=atoi(yytext); return NUM; }
[0-9]+{IS}?             { adjust(); yylval.ival=atoi(yytext); return NUM; }
([0-9]+"."[0-9]*)|([0-9]*"."[0-9]+) { adjust(); yylval.fval=atof(yytext); return FLOAT; }
[A-Za-z_][A-Za-z0-9_]*  { adjust(); yylval.sval=alloc_str(yytext); return ID; }
\"(\\.|[^\\"])*\"       { adjust(); yylval.sval=alloc_str(strip_lit(yytext)); return STRING_LIT; }
`(\\.|[^\\`])*`         { adjust(); yylval.sval=alloc_str(strip_lit(yytext)); return STRING_LIT; }
'(\\.|[^\\'])'          { adjust(); yylval.sval=alloc_str(strip_lit(yytext)); return CHAR_LIT; }

.                       { adjust(); EM_error( EM_tokPos, "illegal token" ); }

%%
