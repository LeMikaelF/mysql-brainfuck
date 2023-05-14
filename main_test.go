package main

import (
	"database/sql"
	_ "embed"
	"fmt"
	_ "github.com/go-sql-driver/mysql"
	"testing"
)

//go:embed interpreter.sql
var query string

//go:embed fizzbuzz.txt
var fizzBuzzOutput string

type test struct {
	name           string
	tape           string
	expectedOutput string
}

func Test_Interpreter(t *testing.T) {
	db, err := sql.Open("mysql", "root:root@tcp(localhost:3306)/test_db")
	if err != nil {
		t.Fatalf("failed to open sql: %v", err)
	}

	var tests = []test{
		{
			// from http://esoteric.sange.fi/brainfuck/bf-source/prog/fibonacci.txt
			name:           "fibonacci series",
			tape:           "+++++++++++>+>>>>++++++++++++++++++++++++++++++++++++++++++++>++++++++++++++++++++++++++++++++<<<<<<[>[>>>>>>+>+<<<<<<<-]>>>>>>>[<<<<<<<+>>>>>>>-]<[>++++++++++[-<-[>>+>+<<<-]>>>[<<<+>>>-]+<[>[-]<[-]]>[<<[>>>+<<<-]>>[-]]<<]>>>[>>+>+<<<-]>>>[<<<+>>>-]+<[>[-]<[-]]>[<<+>>[-]]<<<<<<<]>>>>>[++++++++++++++++++++++++++++++++++++++++++++++++.[-]]++++++++++<[->-<]>++++++++++++++++++++++++++++++++++++++++++++++++.[-]<<<<<<<<<<<<[>>>+>+<<<<-]>>>>[<<<<+>>>>-]<-[>>.>.<<<[-]]<<[>>+>+<<<-]>>>[<<<+>>>-]<<[<+>-]>[<+>-]<<<-]",
			expectedOutput: "1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89",
		},
		{
			name:           "output a single letter",
			tape:           "+++++++++[>++++++++<-]>.",
			expectedOutput: "H",
		},
		{
			name:           "output 'Hello, world!'",
			tape:           ">+++++++++[<++++++++>-]<.>++++++[<+++++>-]<-.+++++++..+++.>> +++++++[<++++++>-]<++.------------.<++++++++.--------.+++.------.--------. >+.",
			expectedOutput: "Hello, world!",
		},
		{
			// from https://desuarchive.org/g/thread/59327915/#59346579
			name:           "Fizzbuzz",
			tape:           ">++++++[<++++++++>-]++++++++++[>++++++++++<-]>[>>+<<->>>>+++<<[>+>->+<[>]>[<+>-]<<[<]>-]>[-<+>]>>>[-]+>[-]<<[>-<[>>+<<-]]>>[<<+>>-]<[>+++++++[>++++++++++<-]>.>>+++[>+++++<-]>[<+++++++>-]<.>++++[>++++<-]>+[<<+>>-]<<..[-]<<[-]<<-<<<<<<<+>>>>>>>]<[-]<[-]+++++<<[>+>->+<[>]>[<+>-]<<[<]>-]>[-<+>]>+>>[-]+>[-]<<[>-<[>>+<<-]]>>[<<+>>-]<[>++++++[>+++++++++++<-]>.>+++++++++[>+++++++++++++<-]>.+++++..[-]<<[-]<<-<<<<<<<+>>>>>>>]<[-]<[-]>[-]<<<<<<[>>>>>+>+<<<<<<-]>>>>>[<<<<<+>>>>>-]+>[<<<<<<[-]>>>>>->[-]],<[<<[>>>+>+<<<<-]>>>[-<<<+>>>]>>>++++++++++<<[->+>-[>+>>]>[+[-<+>]>+>>]<<<<<<]>>[-]>>>++++++++++<[->-[>+>>]>[+[-<+>]>+>>]<<<<<]>[-]>>[>++++++[-<++++++++>]<.<<+>+>[-]]<[<[->-<]++++++[->++++++++<]>.[-]]<<++++++[-<++++++++>]<.[-]<<[-<+>]<-<<-]++++++++++.[-]<<<<]",
			expectedOutput: fizzBuzzOutput,
		},
		{
			// from https://www.nayuki.io/page/brainfuck-interpreter-javascript
			name:           "Reverse the input",
			tape:           ">,[>,]<[.<]",
			expectedOutput: "GFEDCBA",
		},
	}

	for _, test := range tests {
		t.Run(testName(test), func(t *testing.T) {
			var actualOutput string
			var ignored any
			err := db.QueryRow(query, test.tape).Scan(&actualOutput, &ignored, &ignored, &ignored, &ignored)
			if err != nil {
				t.Fatalf("could not query: %v", err)
			}
			if test.expectedOutput != actualOutput {
				t.Errorf("wrong return value: expected '%v', got '%v'", test.expectedOutput, actualOutput)
			}
		})
	}
}

func testName(test test) string {
	return fmt.Sprintf("given '%s' returns '%s'", test.tape, test.expectedOutput)
}
