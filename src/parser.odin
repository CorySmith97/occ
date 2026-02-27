package main

import "core:fmt"

Ast_Node_Tag :: enum {
    expression,
    statement,
}

Ast_Expression :: struct {
    value: string,
}

Ast_Statement :: union { 
    Ast_Let_Statement,
    Ast_Return_Statement,
}

Ast_Let_Statement :: struct { 
    tag         : Ast_Node_Tag,
    identitifer : ^Identitifer,
}

Ast_Return_Statement :: struct {
    token       : Token,
    return_value: Ast_Expression,
}

Ast_Node :: union {
    Ast_Statement,
    Ast_Expression,
}

Identitifer :: struct {
    token: Token,
    value: string,
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

Parser :: struct {
    lexer       : ^Lexer,
    curr_token  : Token,
    peek_token  : Token,
    errors      : [dynamic]Parser_Error,
}

parser_init :: proc(lexer: ^Lexer) -> ^Parser {
    p := new(Parser)
    p.lexer = lexer
    p.errors = make([dynamic]Parser_Error)
    next_token(p)
    next_token(p)

    return p
}

parser_deinit :: proc(p: ^Parser) {
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
    }
    return nil
}

parse_expression :: proc(p: ^Parser) -> ^Ast_Expression {
    return nil
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

get_token_literal_from_ast_node :: proc(node: ^Ast_Node) -> string {
    switch _ in node {
    case Ast_Statement: 
    case Ast_Expression: 
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

