package main

import "core:fmt"

main :: proc() {
    l: ^Lexer
    test_string := `
    let five = 5;
    let ten = 10;

    let add = fn(x, y) {
        x + y;
    }
    let result = add(five, ten);
    `
    l = lexer_init(test_string)
    tok := lexer_get_token(l)
    for tok.tag != .eof {
        fmt.printf("token: %v\n", tok.tag)
        tok = lexer_get_token(l)
    }
}
