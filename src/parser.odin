package main


Ast_Node_Tag :: enum {
    expression,
    statement,
}

Ast_Statement :: struct { 
    tag: Ast_Node_Tag,
    identitifer: ^Identitifer,
}

Ast_Node :: union {
    Ast_Statement,
}

Identitifer :: struct {
    token: Token,
    value: string,
}

Program :: struct {
    statements: [dynamic]Ast_Node,
}

Parser :: struct {
    lexer: ^Lexer,
    curr_token: Token,
    peek_token: Token,
}

parser_init :: proc(lexer: ^Lexer) -> ^Parser {
    p := new(Parser)
    next_token(p)
    next_token(p)

    return p
}

next_token :: proc(p: ^Parser) {
    p.curr_token = p.peek_token
    p.peek_token = lexer_get_token(p.lexer)
}

parse_program :: proc(p: ^Parser) -> ^Program {
    return nil
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
        return get_token_literal_from_ast_node(&program.statements[0])
    } else {
        return ""
    }
}

