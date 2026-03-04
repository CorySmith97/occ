#+feature dynamic-literals
package main

import "core:strconv"
import "core:fmt"
import "core:strings"
import "core:log"

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

precendences := map[Token_Tag]Expression_Precedence {
    .eq = .equal,
    .not_eq = .equal,
    .lt = .lessgreater,
    .gt = .lessgreater,
    .plus = .sum,
    .minus = .sum,
    .slash = .product,
    .asterisk = .product,
}

Expression :: union {
    Identitifer,
    Integer_Literal,
    Prefix_Expression,
    Infix_Expression,
}

Ast_Statement :: union { 
    Ast_Let_Statement,
    Ast_Return_Statement,
    Ast_Expression_Statement,
}

Ast_Node :: union {
    Ast_Statement,
}

Prefix_Expression :: struct {
    token: Token,
    operator: string,
    right: ^Expression,
}

Infix_Expression :: struct {
    token: Token,
    lhs: ^Expression,
    rhs: ^Expression,
    operator: string,
}

Ast_Expression_Statement :: struct {
    value: string,
    expression: ^Expression,
}

Ast_Let_Statement :: struct { 
    tag         : Ast_Node_Tag,
    identitifer : ^Identitifer,
}

Ast_Return_Statement :: struct {
    token       : Token,
    return_value: Expression,
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
    integer_parse_error,
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

    parser_register_prefix(p, .ident,   parse_identifier)
    parser_register_prefix(p, .integer, parse_integer_literal)
    parser_register_prefix(p, .bang,    parse_prefix_expression)
    parser_register_prefix(p, .minus,   parse_prefix_expression)

    parser_register_infix(p, .plus,     parse_infix_expression)
    parser_register_infix(p, .minus,    parse_infix_expression)
    parser_register_infix(p, .slash,    parse_infix_expression)
    parser_register_infix(p, .asterisk, parse_infix_expression)
    parser_register_infix(p, .eq,       parse_infix_expression)
    parser_register_infix(p, .not_eq,   parse_infix_expression)
    parser_register_infix(p, .lt,       parse_infix_expression)
    parser_register_infix(p, .gt,       parse_infix_expression)

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

error_no_prefix_fn :: proc(p: ^Parser, t: Token_Tag) {
    error := fmt.aprintf("No prefix parse function for token type: %v", t)
    add_error(p, Parser_Error{
        message = error,
        tag = .unexpected_token,
    })
}

error_peek :: proc(p: ^Parser, tag: Token_Tag) {
    error := fmt.aprintf("Expected %v, found %v\n", p.peek_token.tag, tag);
    add_error(p, Parser_Error{
        message = error,
        tag = .unexpected_token,
    })
}

peek_precedence :: proc(p: ^Parser) -> Expression_Precedence {
    if p, ok := precendences[p.peek_token.tag]; ok {
        return p
    }

    return .lowest
}

curr_precedence :: proc(p: ^Parser) -> Expression_Precedence {
    if p, ok := precendences[p.curr_token.tag]; ok {
        return p
    }

    return .lowest
}

parse_infix_expression :: proc(p: ^Parser, lhs: ^Expression) -> ^Expression {
    ex := new(Expression)

    exp := Infix_Expression{}

    exp.token = p.curr_token
    exp.operator = p.curr_token.literal
    exp.lhs = lhs
    precedence := curr_precedence(p)
    next_token(p)
    exp.rhs = parse_expression(p, precedence)

    ex^ = exp
    return ex
}

parse_prefix_expression :: proc(p: ^Parser) -> ^Expression {
    exp := new(Expression)
    pre := Prefix_Expression{}

    pre.token = p.curr_token
    pre.operator = p.curr_token.literal

    next_token(p)

    pre.right = parse_expression(p, .prefix)

    exp^ = pre

    return exp
}

parse_let_statement :: proc(p: ^Parser) -> ^Ast_Statement {
    stmt := new(Ast_Statement)
    let := Ast_Let_Statement{}

    if !expect_peek(p, .ident) {
        return nil
    }

    let.identitifer       = new(Identitifer)
    let.identitifer.token = p.curr_token 
    let.identitifer.value = p.curr_token.literal

    if !expect_peek(p, .assign) {
        return nil
    }

    for p.curr_token.tag != .semicolon {
        next_token(p)
    }

    stmt^ = let

    return stmt
}

parse_return_statement :: proc(p: ^Parser) -> ^Ast_Statement {
    stmt := new(Ast_Statement)
    ret := Ast_Return_Statement{}

    ret.token = p.curr_token

    next_token(p)

    for p.curr_token.tag != .semicolon {
        next_token(p)
    }

    stmt^ = ret

    return stmt
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
        log.log(.Debug, "This is trying to parse as an expression")
        return parse_expression_statement(p)
    }
    return nil
}

parse_expression :: proc(p: ^Parser, precedence: Expression_Precedence) -> ^Expression {
    if prefix, ok := p.prefix_parse_fns[p.curr_token.tag]; ok {
        // returns the left hand prefix
        func := prefix
        left_expression := func(p)

        for (!peek_token_is(p, .semicolon)) && (precedence < peek_precedence(p)) {
            infix, ok := p.infix_parse_fns[p.peek_token.tag];
            if !ok {
                return nil
            }
            infix_fn := infix
            next_token(p)

            left_expression = infix(p, left_expression)
        }

        return left_expression
    }
    error_no_prefix_fn(p, p.curr_token.tag)
    return nil
}

parse_integer_literal :: proc(p: ^Parser) -> ^Expression {
    exp := new(Expression)
    literal := Integer_Literal{}
    ok: bool

    literal.value, ok = strconv.parse_int(p.curr_token.literal)

    if !ok {
        add_error(p, Parser_Error{
            tag = .integer_parse_error,
            message = "failed to parse integer literal",
            file = #file,
            location = #line,
        })
    }
    literal.token = p.curr_token

    exp^ = literal

    return exp
}

parse_expression_statement :: proc(p: ^Parser) -> ^Ast_Statement {
    stmt := new(Ast_Statement)
    exp := Ast_Expression_Statement{}

    exp.expression = parse_expression(p, .lowest)

    if peek_token_is(p, .semicolon) {
        next_token(p)
    }

    stmt^ = exp

    return stmt
}

parse_identifier :: proc(p: ^Parser) -> ^Expression {
    ident := new(Expression)
    ii := Identitifer{}
    ii.token = p.curr_token
    ii.value = p.curr_token.literal

    ident^ = ii

    return ident
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

token_literal :: proc{
    get_token_literal_from_ast_statement,
    get_token_literal_from_ast_node,
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

to_string :: proc{
    to_string_statement,
    to_string_expression,
    to_string_program,
}

to_string_program :: proc(prog: ^Program) -> string {
    ret_val: string
    for stmt in prog.statements {
        ret_val = strings.concatenate({ret_val, to_string_statement(stmt)})
    }
    return ret_val
}

to_string_expression :: proc(ex: ^Expression) -> string {
    switch v in ex {
    case Identitifer:
        return fmt.aprintf("%s", v.value)
    case Integer_Literal:
        return fmt.aprintf("%s", v.token.literal)
    case Prefix_Expression:
        return fmt.aprintf("(%s%s)", v.operator, to_string(v.right))
    case Infix_Expression:
        return fmt.aprintf("(%s %s %s)", to_string_expression(v.lhs), v.operator, to_string_expression(v.rhs))
    }

    // fallback
    return ""
}

to_string_statement :: proc(statement: ^Ast_Statement) -> string {
    switch &v in statement {
    case Ast_Let_Statement:
        return fmt.aprintf("%v: %d", v.tag, v.identitifer.value)
    case Ast_Return_Statement:
        return fmt.aprintf("%v: %d", v.token.tag, v.return_value)
    case Ast_Expression_Statement:
        return to_string_expression(v.expression)
    }
    return ""
}

get_expression :: proc(statement: ^Ast_Statement) -> ^Expression {
    switch v in statement {
    case Ast_Let_Statement:
        return nil
    case Ast_Return_Statement:
        return nil
    case Ast_Expression_Statement:
        return v.expression
    }

    return nil
}
