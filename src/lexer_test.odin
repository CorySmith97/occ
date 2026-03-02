package main

import "core:testing"

@test
test_next_token :: proc(t: ^testing.T) {
    l: ^Lexer
    tok: Token

    test_string := `
    let five = 5;
    let ten = 10;

    let add = fn(x, y) {
        x + y;
    }
    let result = add(five, ten);
    !-/*5;
    5 < 10 > 5;

    if (5 < 10) {
        return true;
    } else {
        return false;
    }

    10 == 10;
    10 != 9;
    `
    
    test_res := [?]Token{
        {literal = "let", tag = .let,},
        {literal = "five", tag = .ident,},
        {literal = "=", tag = .assign,},
        {literal = "5", tag = .integer,},
        {literal = ";", tag = .semicolon,},

        {literal = "let", tag = .let,},
        {literal = "ten", tag = .ident,},
        {literal = "=", tag = .assign,},
        {literal = "10", tag = .integer,},
        {literal = ";", tag = .semicolon,},

        {literal = "let", tag = .let,},
        {literal = "add", tag = .ident,},
        {literal = "=", tag = .assign,},
        {literal = "fn", tag = .function,},
        {literal = "(", tag = .lparen,},
        {literal = "x", tag = .ident,},
        {literal = ",", tag = .comma,},
        {literal = "y", tag = .ident,},
        {literal = ")", tag = .rparen,},
        {literal = "{", tag = .lbrace,},
        {literal = "x", tag = .ident,},
        {literal = "+", tag = .plus,},
        {literal = "y", tag = .ident,},
        {literal = ";", tag = .semicolon,},
        {literal = "}", tag = .rbrace,},

        {literal = "let", tag = .let,},
        {literal = "result", tag = .ident,},
        {literal = "=", tag = .assign,},
        {literal = "add", tag = .ident,},
        {literal = "(", tag = .lparen,},
        {literal = "five", tag = .ident,},
        {literal = ",", tag = .comma,},
        {literal = "ten", tag = .ident,},
        {literal = ")", tag = .rparen,},
        {literal = ";", tag = .semicolon,},
        {literal = "!", tag = .bang,},
        {literal = "-", tag = .minus,},
        {literal = "/", tag = .slash,},
        {literal = "*", tag = .asterisk,},
        {literal = "5", tag = .integer,},
        {literal = ";", tag = .semicolon,},
        {literal = "5", tag = .integer,},
        {literal = "<", tag = .lt,},
        {literal = "10", tag = .integer,},
        {literal = ">", tag = .gt,},
        {literal = "5", tag = .integer,},
        {literal = ";", tag = .semicolon,},
        {literal = "if", tag = .tok_if,},
        {literal = "(", tag = .lparen,},
        {literal = "5", tag = .integer,},
        {literal = "<", tag = .lt,},
        {literal = "10", tag = .integer,},
        {literal = ")", tag = .rparen,},
        {literal = "{", tag = .lbrace,},
        {literal = "return", tag = .tok_return,},
        {literal = "true", tag = .tok_true,},
        {literal = ";", tag = .semicolon,},
        {literal = "}", tag = .rbrace,},
        {literal = "else", tag = .tok_else,},
        {literal = "{", tag = .lbrace,},
        {literal = "return", tag = .tok_return,},
        {literal = "false", tag = .tok_false,},
        {literal = ";", tag = .semicolon,},
        {literal = "}", tag = .rbrace,},
        {literal = "10", tag = .integer,},
        {literal = "==", tag = .eq,},
        {literal = "10", tag = .integer,},
        {literal = ";", tag = .semicolon,},
        {literal = "10", tag = .integer,},
        {literal = "!=", tag = .not_eq,},
        {literal = "9", tag = .integer,},
        {literal = ";", tag = .semicolon,},
        {literal = "", tag = .eof,},
    }

    l = lexer_init(test_string)
    defer lexer_deinit(l)

    tok = lexer_get_token(l)
    for tag in test_res {
        testing.expectf(t, tag.tag == tok.tag, "expected %v, got %v", tag.tag, tok.tag)
        //testing.expectf(t, tag.literal == tok.literal, "expected %v, got %v", tag, tok.tag)
        tok = lexer_get_token(l)
    }
}
