# set @@cte_max_recursion_depth=1000000;
-- >++++++++[<+++++++++>-]<.

with
#     recursive tape (value) as (select '>+++++++++[<++++++++>-]<.>++++++[<+++++>-]<-.+++++++..+++.>> +++++++[<++++++>-]<++.------------.<++++++++.--------.+++.------.--------. >+.'),
    recursive tape (value) as (select ?),
              memLength (value) as (select 1000),
              interpreter (memory, memPointer, output, instrPointer, iteration, done)
                  as (select cast(repeat('\0', memLength.value) as binary) as memory,
                             1                          as memPointer,
                             cast('' as char(50))       as output,
                             1                          as instrPointer,
                             0                          as iteration,
                             false                      as done
                      from memLength
                      union all
                      select
                          -- memory
                          -- TODO implement comma operator (input)
                          case
                              when substring(tape.value, instrPointer, 1) = '+' then concat(
                                      substring(memory, 1, memPointer - 1),
                                      char((ascii(substring(memory, memPointer, 1)) + 1) % 256),
                                      substring(memory, memPointer + 1)
                                  )
                              when substring(tape.value, instrPointer, 1) = '-' then concat(
                                      substring(memory, 1, memPointer - 1),
                                      char((ascii(substring(memory, memPointer, 1)) - 1) % 256),
                                      substring(memory, memPointer + 1)
                                  )
                              else memory
                              end                           as memory,

                          -- memPointer
                          case
                              when substring(tape.value, instrPointer, 1) = '>' then (memPointer + 1)
                              when substring(tape.value, instrPointer, 1) = '<' then (memPointer - 1)
                              else memPointer
                              end                           as memPointer,

                          -- output
                          if(substring(tape.value, instrPointer, 1) = '.',
                             concat(output, substring(memory, memPointer, 1)),
                             output)                        as output,

                          -- instrPointer
                          case
                              when substring(tape.value, instrPointer, 1) = '['
                                  then if(substring(memory, memPointer, 1) = '\0',
                                          locate(']', substring(tape.value, instrPointer + 1)) + instrPointer + 1,
                                          instrPointer + 1)
                              when substring(tape.value, instrPointer, 1) = ']'
                                  then if(substring(memory, memPointer, 1) <> '\0',
                                          1 + instrPointer -
                                          locate('[', reverse(substring(tape.value, 1, instrPointer - 1))),
                                          instrPointer + 1)
                              else instrPointer + 1
                              end
                                                            as instrPointer,

                          iteration + 1                     as iteration,
                          instrPointer > length(tape.value) as done
                      from interpreter,
                           tape,
                           memLength
                      where iteration < 10000 && !done)
select output, iteration, left(memory, 20) as memory, instrPointer, memPointer
from interpreter, memLength, tape
order by iteration desc
LIMIT 10000 OFFSET 1;
