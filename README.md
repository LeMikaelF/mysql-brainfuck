# MySQL Brainfuck interpreter

This is an interpreter for the esolang [Brainfuck](https://en.wikipedia.org/wiki/Brainfuck) that runs in a single MySQL
query. Since Brainfuck is turing-complete, this is part of an ongoing effort to rewrite MySQL in MySQL (just kidding).

It supports all of Brainfuck's operators (even nested loops!), the only limitation is that it doesn't do interactive
stuff (you give it all the input at the beginning, no interaction is possible during execution).

There is a small test harness with the following toy programs (sources for these programs are in the test file):

* Generate the fibonacci series
* Output a single letter (kind of dumb, used as a development aid)
* Output "Hello, world!"
* Fizzbuzz
* Reverse the given input

## To run tests
```sh
docker-compose up
# wait until DB is up
go test main_test.go -v
```
