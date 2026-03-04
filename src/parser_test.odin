package main

import "core:log"
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

    tests := [?]string{
        "x",
        "y",
        "foobar",
    }

    for test, i in tests {
        value := program.statements[i]
        switch &val in program.statements[i] {
        case Ast_Let_Statement:
            test_statement_let(t, &val)
        case Ast_Return_Statement:
            test_statement_return(t, &val)
        case Ast_Expression_Statement:
            test_statement_expression(t, &val)
        }
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
parser_test_integer_literal :: proc(t: ^testing.T) {
    input := "5;"
    defer free_all(context.allocator)

    l := lexer_init(input)
    p := parser_init(l)

    program := parse_program(p)
    if program == nil {
        testing.fail(t)
    }
    check_parser_errors(t, p)

    if len(program.statements) != 1 {
        testing.fail(t)
    }

    stmt := program.statements[0]

    #partial switch v in stmt {
    case Ast_Expression_Statement:
        literal := v.expression.(Integer_Literal)

        tests := 5

        testing.expectf(t, tests == literal.value, "Integer literal was not parsed correctly %v %v", l, literal)
    }
}

@test
parser_test_prefix_expression :: proc(t: ^testing.T) {
    Prefix_Test :: struct {
        input: string,
        operator: string,
        integer_val: int,
    }

    tests := []Prefix_Test{
        {"!5;", "!", 5},
        {"-15;", "-", 15},
    }

    for test, index in tests {
        defer free_all(context.allocator)

        l := lexer_init(test.input)
        p := parser_init(l)
        program := parse_program(p)
        check_parser_errors(t, p)

        if len(program.statements) != 1 {
            testing.fail(t)
        }
        stmt := program.statements[0]
        v := stmt.(Ast_Expression_Statement)
        prefix := v.expression.(Prefix_Expression)

        testing.expectf(t, test.operator == prefix.operator, "Expected operator to be %s, got %s", test.operator, prefix.operator)
        // @todo:cs implement tests for prefixes
    }
}

@test
parser_test_infix_expression :: proc(t: ^testing.T) {
    Infix_Test :: struct {
        input: string,
        lhs_val: int,
        operator: string,
        rhs_val: int,
    }

    tests := []Infix_Test{
        {"5 + 5;", 5, "+", 5},
        {"5 - 5;", 5, "-", 5},
        {"5 * 5;", 5, "*", 5},
        {"5 / 5;", 5, "/", 5},
        {"5 < 5;", 5, "<", 5},
        {"5 > 5;", 5, ">", 5},
        {"5 == 5;", 5, "==", 5},
        {"5 != 5;", 5, "!=", 5},
    }

    for test, index in tests {
        defer free_all(context.allocator)

        l := lexer_init(test.input)
        p := parser_init(l)
        program := parse_program(p)
        check_parser_errors(t, p)

        stmt := program.statements[0]
        expression := stmt.(Ast_Expression_Statement)
        v := expression.expression.(Infix_Expression)
        testing.expectf(t, v.operator == test.operator, "operators should be the same. Got: %s, Expected: %s", v.operator, test.operator)
    }
}

@test
parser_test_precendence :: proc(t: ^testing.T) {
    Prec_Test :: struct {
        input: string,
        expected: string,
    }

    tests := []Prec_Test{
        {
            "-a * b",
            "((-a) * b)",
        },
        {
            "!-a",
            "(!(-a))",
        },
        {
            "a + b + c",
            "((a + b) + c)",
        },
        {
            "a + b - c",
            "((a + b) - c)",
        },
        {
            "a * b * c",
            "((a * b) * c)",
        },
        {
            "a * b / c",
            "((a * b) / c)",
        },
        {
            "a + b / c",
            "(a + (b / c))",
        },
        {
            "a + b * c + d / e -f",
            "(((a + (b * c)) + (d / e)) - f)",
        },
        {
            "3 + 4; -5 * 5",
            "(3 + 4)((-5) * 5)",
        },
        {
            "5 > 4 == 3 < 4",
            "((5 > 4) == (3 < 4))",
        },
        {
            "5 > 4 != 3 > 4",
            "((5 > 4) != (3 > 4))",
        },
        {
            "3 + 4 * 5 == 3 * 1 + 4 * 5",
            "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))",
        },
    }

    for test, index in tests {
        defer free_all(context.allocator)
        l := lexer_init(test.input)
        p := parser_init(l)
        program := parse_program(p)
        check_parser_errors(t, p)
        actual := to_string(program)
        testing.expectf(t, actual == test.expected, "Expected: %s, got: %s", test.expected, actual)

        
    }
}

test_integer_literal :: proc(t: ^testing.T, ex: Integer_Literal, expected: int) {

    testing.expectf(t, ex.value == expected, "Integer Literal does not match expected: %d, got %d", expected, ex.value)
}

test_statement_let :: proc(t: ^testing.T, stmt: ^Ast_Let_Statement) {
}

test_statement_return :: proc(t: ^testing.T, stmt: ^Ast_Return_Statement) {
}

test_statement_expression :: proc(t: ^testing.T, stmt: ^Ast_Expression_Statement) {
}

test_identity :: proc(t: ^testing.T, stmt: ^Identitifer) {
}

check_parser_errors :: proc(t: ^testing.T, p: ^Parser) {
    if len(p.errors) > 0 {
        for err in p.errors {
            log.log(.Error, err.message)
        }
    }
}
