package main

import (
	"database/sql"
	_ "embed"
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
	input          string
	expectedOutput string
}

func Test_Interpreter(t *testing.T) {
	db, err := sql.Open("mysql", "root:root@tcp(localhost:3306)/test_db")
	if err != nil {
		t.Fatalf("failed to open sql: %v", err)
	}
	_, err = db.Exec("set @@cte_max_recursion_depth = 10000000")
	if err != nil {
		t.Fatalf("could not set max recursion depth: %v", err)
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
			input:          "ABCDEFG",
			expectedOutput: "GFEDCBA",
		},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			var actualOutput string
			err := db.QueryRow(query, test.tape, test.input).Scan(&actualOutput)
			if err != nil {
				t.Fatalf("could not query: %v", err)
			}
			if test.expectedOutput != actualOutput {
				t.Errorf("wrong return value: expected '%v', got '%v'", test.expectedOutput, actualOutput)
			}
		})
	}
}
