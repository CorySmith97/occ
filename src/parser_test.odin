package main

import "core:fmt"
import "core:testing"

@test
parser_test :: proc(t: ^testing.T) {
    input := `
    let x = 5;
    let y = 10;
    let foobar = 838383;
    return foobar;
    `
    defer free_all(context.allocator)

    l := lexer_init(input)
    p := parser_init(l)

    program := parse_program(p)
    if program == nil {
        testing.fail(t)
    }

    check_parser_errors(t, p)

    if len(program.statements) != 4 {
        testing.fail(t)
    }

    item := program.statements[3]
    fmt.printf("last statement: %v\n", item)

    tests := [?]string{
        "x",
        "y",
        "foobar",
    }

    for test, i in tests {
        value := program.statements[i]
        test_val, ok := value.(Ast_Let_Statement)
        if ok {
            testing.expectf(t, test_val.identitifer.value == test, "Expected: %s, found: %s", test, test_val.identitifer.value)
        }
    }
}

// @todo:cs this needs actual testing for the different types.
// [] Let statement
// [] Return statement
// [] Expressions
// [] Identity

@test
parser_test_string :: proc(t: ^testing.T) {
}

test_let_statement :: proc(t: ^testing.T, stmt: ^Ast_Statement) {
}

check_parser_errors :: proc(t: ^testing.T, p: ^Parser) {
    if len(p.errors) > 0 {
        testing.fail(t)
    }
}
