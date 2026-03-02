package main

import "core:fmt"
import "core:strings"

// @todo:cs there is a way to better follow the book using some parametric polymorphism.
// I should take a deeper look at this and try to rewrite it in a more odin way.
// I could also use some more function overrides in order to better implement things
// ie the way that append() in the base of the language works.

Ast_Node_Tag :: enum {
    expression,
    statement,
}

Expression_Precedence :: enum {
    lowest,
    equal,
    lessgreater,
    sum,
    product,
    prefix,
    call,
}

Expression :: union {
    Identitifer,
}

Ast_Expression_Statement :: struct {
    value: string,
    expression: ^Expression,
}

Ast_Statement :: union { 
    Ast_Let_Statement,
    Ast_Return_Statement,
    Ast_Expression_Statement,
}

Ast_Let_Statement :: struct { 
    tag         : Ast_Node_Tag,
    identitifer : ^Identitifer,
}

Ast_Return_Statement :: struct {
    token       : Token,
    return_value: Expression,
}

Ast_Node :: union {
    Ast_Statement,
}

Identitifer :: struct {
    token: Token,
    value: string,
}

Integer_Literal :: struct {
    token: Token,
    value: int,
}

Program :: struct {
    statements: [dynamic]^Ast_Statement,
}

Error_Tag :: enum {
    unexpected_token,
}

Parser_Error :: struct {
    tag     : Error_Tag,
    message : string,
    file    : string,
    location: u64,
}

prefix_parse_fn :: #type proc(p: ^Parser) -> ^Expression
infix_parse_fn  :: #type proc(p: ^Parser, ex: ^Expression) -> ^Expression

Parser :: struct {
    lexer       : ^Lexer,
    curr_token  : Token,
    peek_token  : Token,
    errors      : [dynamic]Parser_Error,

    prefix_parse_fns: map[Token_Tag]prefix_parse_fn,
    infix_parse_fns:  map[Token_Tag]infix_parse_fn,
}

parser_init :: proc(lexer: ^Lexer) -> ^Parser {
    p := new(Parser)
    p.lexer = lexer
    p.errors = make([dynamic]Parser_Error)
    next_token(p)
    next_token(p)

    parser_register_prefix(p, .ident, parse_identifier)

    return p
}

parser_deinit :: proc(p: ^Parser) {
    delete(p.errors)
    free(p)
}

parser_register_prefix :: proc(p: ^Parser, tag: Token_Tag, fn: prefix_parse_fn) {
    p.prefix_parse_fns[tag] = fn
}

parser_register_infix :: proc(p: ^Parser, tag: Token_Tag, fn: infix_parse_fn) {
    p.infix_parse_fns[tag] = fn
}

next_token :: proc(p: ^Parser) {
    p.curr_token = p.peek_token
    p.peek_token = lexer_get_token(p.lexer)
}

expect_peek :: proc(p: ^Parser, tag: Token_Tag) -> b32 {
    if p.peek_token.tag == tag {
        next_token(p)
        return true
    } else {
        error_peek(p, tag)
        return false
    }
}

add_error :: proc(p: ^Parser, error: Parser_Error) {
    append(&p.errors, error)
}

error_peek :: proc(p: ^Parser, tag: Token_Tag) {
    error := fmt.aprintf("Expected %v, found %v\n", p.peek_token.tag, tag);
    add_error(p, Parser_Error{
        message = error,
        tag = .unexpected_token,
    })
}

parse_let_statement :: proc(p: ^Parser) -> ^Ast_Statement {
    stmt := new(Ast_Let_Statement)

    if !expect_peek(p, .ident) {
        return nil
    }

    stmt.identitifer       = new(Identitifer)
    stmt.identitifer.token = p.curr_token 
    stmt.identitifer.value = p.curr_token.literal

    if !expect_peek(p, .assign) {
        return nil
    }

    for p.curr_token.tag != .semicolon {
        next_token(p)
    }

    return auto_cast stmt
}

parse_return_statement :: proc(p: ^Parser) -> ^Ast_Statement {
    stmt := new(Ast_Return_Statement)
    stmt.token = p.curr_token

    next_token(p)

    for p.curr_token.tag != .semicolon {
        next_token(p)
    }

    return auto_cast stmt
}

curr_token_is :: proc(p: ^Parser, tag: Token_Tag) -> b32 {
    return p.curr_token.tag == tag
}

peek_token_is :: proc(p: ^Parser, tag: Token_Tag) -> b32 {
    return p.peek_token.tag == tag
}

parse_statement :: proc(p: ^Parser) -> ^Ast_Statement {
    #partial switch p.curr_token.tag {
    case .let:
        return parse_let_statement(p)
    case .tok_return:
        return parse_return_statement(p)
    case:
        return parse_expression_statement(p)
    }
    return nil
}

parse_expression :: proc(p: ^Parser, precedence: Expression_Precedence) -> ^Expression {
    if prefix, ok := p.prefix_parse_fns[p.curr_token.tag]; ok {
        // returns the left hand prefix
        func := prefix
        return func(p)
    }
    return nil
}

parse_expression_statement :: proc(p: ^Parser) -> ^Ast_Statement {
    stmt := new(Ast_Expression_Statement)

    stmt.expression = parse_expression(p, .lowest)

    if peek_token_is(p, .semicolon) {
        next_token(p)
    }

    return auto_cast stmt
}

parse_identifier :: proc(p: ^Parser) -> ^Expression {
    ident := new(Identitifer)
    ident.token = p.curr_token
    ident.value = p.curr_token.literal

    return auto_cast ident
}

parse_program :: proc(p: ^Parser) -> ^Program {
    program := new(Program)
    program.statements = make([dynamic]^Ast_Statement)

    for p.curr_token.tag != .eof {
        stmt := parse_statement(p)
        if stmt != nil {
            append(&program.statements, stmt)
        }
        next_token(p)
    }
    return program
}

get_token_literal_from_ast_statement :: proc(node: ^Ast_Statement) -> string {
    ret_val, ok := node.(Ast_Let_Statement)
    if ok {
        return ret_val.identitifer.value
    }
    return ""
}

/// This is just for debugging purposes. It at runtime prints a version of a tree basically
/// in order to see what the ast tree looks like.
get_string :: proc(node: ^Ast_Node) -> string {
    switch v in node {
    case Ast_Statement: 
        value := node.(Ast_Statement)
        return get_string_statement(&value)
    case:
    }

    return ""
}

get_string_statement :: proc(statement: ^Ast_Statement) -> string {
    string_builder: strings.Builder
    strings.builder_init_len(&string_builder, 256)
    switch v in statement {
    case Ast_Let_Statement:
        return fmt.sbprintf(&string_builder, "%v: %d", v.tag, v.identitifer.value)
    case Ast_Return_Statement:
        return fmt.sbprintf(&string_builder, "%v: %d", v.token.tag, v.return_value)
    case Ast_Expression_Statement:
        return fmt.sbprintf(&string_builder, "%v: %s", v.expression, v.value)
    }


    return ""
}

get_token_literal_from_ast_node :: proc(node: ^Ast_Node) -> string {
    switch _ in node {
    case Ast_Statement: 
    case:
    }

    return ""
}

get_token_literal :: proc(program: ^Program) -> string {
    if len(program.statements) > 0 {
        return get_token_literal_from_ast_statement(program.statements[0])
    } else {
        return ""
    }
}

