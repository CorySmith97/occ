#+feature dynamic-literals
package main

import "core:fmt"

keywords := map[string]Token_Tag {
    "let" = .let,
    "fn" = .function,
    "if" = .tok_if,
    "else" = .tok_else,
    "return" = .tok_return,
    "true" = .tok_true,
    "false" = .tok_false,
}

Lexer :: struct {
    input: string,
    position: u64,
    read: u64,
    char: u8,
}

Token_Tag :: enum {
    let,
    ident,
    integer,
    function,
    plus,
    asterisk,
    minus,
    lparen,
    rparen,
    lbrace,
    rbrace,
    assign,
    bang,
    eq,
    not_eq,
    lt,
    gt,
    slash,
    comma,
    semicolon,
    tok_if,
    tok_else,
    tok_return,
    tok_true,
    tok_false,
    illegal,
    eof,
}

Token :: struct {
    tag: Token_Tag,
    literal: string,
}

lexer_init :: proc(input: string) -> ^Lexer {
    l, err := new(Lexer)
    l.input = input
    l.position  = 0
    l.read  = 0
    l.char  = input[0]
    
    read_char(l)
    return l
}

lexer_deinit :: proc(l: ^Lexer) {
    free(l)
}


lexer_get_token :: proc(l: ^Lexer) -> Token {
    t: Token

    eat_whitespace(l)

    switch l.char {
    case '/': 
        t.tag = .slash
        t.literal = "/"
        break;
    case '<': 
        t.tag = .lt
        t.literal = "<"
        break;
    case '>': 
        t.tag = .gt
        t.literal = ">"
        break;
    case '!': 
        if peek_char(l) == '=' {
            t.tag = .not_eq
            t.literal = "!="
            read_char(l)
        } else {
            t.tag = .bang
            t.literal = "!"
        }
        break;
    case '*': 
        t.tag = .asterisk
        t.literal = "*"
        break;
    case '=': 
        if peek_char(l) == '=' {
            t.tag = .eq
            t.literal = "=="
            read_char(l)
        } else {
            t.tag = .assign
            t.literal = "="
        }
        break;
    case '-':
        t.tag = .minus
        t.literal = "-"
        break;
    case '+': 
        t.tag = .plus
        t.literal = "+"
        break;
    case '(':
        t.tag = .lparen
        t.literal = "("
        break;
    case ')':
        t.tag = .rparen
        t.literal = ")"
        break;
    case '{':
        t.tag = .lbrace
        t.literal = "{"
        break;
    case '}':
        t.tag = .rbrace
        t.literal = "}"
        break;
    case ';':
        t.tag = .semicolon
        t.literal = ";"
        break;
    case ',': 
        t.tag = .comma
        t.literal = ","
        break;
    case 0:
        t.tag = .eof
    case: 
        if is_letter(l.char) {
            start := l.position
            t.literal = get_literal(l)
            t.tag = get_literal_tag(t.literal)
            return t
        }
        else if is_number(l.char) {
            start := l.position
            t.literal = get_integer(l)
            t.tag = .integer
            return t
        }
        else {
            t.tag = .illegal
        }
    }

    read_char(l)
    return t
}

@(private="file")
get_literal_tag :: proc(literal: string) -> Token_Tag {
    if tag, t_ok := keywords[literal]; t_ok {
        return tag
    }

    return .ident
}

@(private="file")
get_literal :: proc(l: ^Lexer) -> string {
    start := l.position
    for is_letter(l.char) {
        read_char(l)
    }

    return l.input[start:l.position]
}

@(private="file")
get_integer :: proc(l: ^Lexer) -> string {
    start := l.position
    for is_number(l.char) {
        read_char(l)
    }

    return l.input[start:l.position]
}

@(private="file")
read_char :: proc(l: ^Lexer) {
    if l.read >= auto_cast len(l.input) {
        l.char = 0
    } else {
        l.char = l.input[l.read]
    }
    l.position = l.read
    l.read += 1
}

@(private="file")
eat_whitespace :: proc(l: ^Lexer) {
    for l.char == '\r' || l.char == '\t' ||l.char == ' ' ||l.char == '\n' {
        read_char(l)
    }
}

@(private="file")
is_letter :: proc(char: u8) -> bool {
    return (char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z')
}

@(private="file")
is_number :: proc(char: u8) -> bool {
    return char >= '0' && char <= '9'
}

@(private="file")
peek_char :: proc(l: ^Lexer) -> u8 {
    if l.read >= auto_cast len(l.input) {
        return 0
    } else {
        return l.input[l.read]
    }
}
