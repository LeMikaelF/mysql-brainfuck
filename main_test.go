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

func Test_Interpreter(t *testing.T) {
	db, err := sql.Open("mysql", "root:root@tcp(localhost:3306)/test_db")
	if err != nil {
		t.Fatalf("failed to open sql: %v", err)
	}

	var tests = []struct {
		tape           string
		expectedOutput string
	}{
		{
			// from http://esoteric.sange.fi/brainfuck/bf-source/prog/fibonacci.txt
			tape:           "+++++++++++>+>>>>++++++++++++++++++++++++++++++++++++++++++++>++++++++++++++++++++++++++++++++<<<<<<[>[>>>>>>+>+<<<<<<<-]>>>>>>>[<<<<<<<+>>>>>>>-]<[>++++++++++[-<-[>>+>+<<<-]>>>[<<<+>>>-]+<[>[-]<[-]]>[<<[>>>+<<<-]>>[-]]<<]>>>[>>+>+<<<-]>>>[<<<+>>>-]+<[>[-]<[-]]>[<<+>>[-]]<<<<<<<]>>>>>[++++++++++++++++++++++++++++++++++++++++++++++++.[-]]++++++++++<[->-<]>++++++++++++++++++++++++++++++++++++++++++++++++.[-]<<<<<<<<<<<<[>>>+>+<<<<-]>>>>[<<<<+>>>>-]<-[>>.>.<<<[-]]<<[>>+>+<<<-]>>>[<<<+>>>-]<<[<+>-]>[<+>-]<<<-]",
			expectedOutput: "supposed to generate Fibonacci sequence",
		},
		{
			tape:           "+++++++++[>++++++++<-]>.",
			expectedOutput: "H",
		},
		{
			tape:           ">+++++++++[<++++++++>-]<.>++++++[<+++++>-]<-.+++++++..+++.>> +++++++[<++++++>-]<++.------------.<++++++++.--------.+++.------.--------. >+.",
			expectedOutput: "Hello, world!",
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

func testName(test struct {
	tape           string
	expectedOutput string
}) string {
	return fmt.Sprintf("given '%s' returns '%s'", test.tape, test.expectedOutput)
}
