with
    recursive tape (value) as (select ?),
              memLength (value) as (select 50),
              interpreter (memory, memPointer, output, instrPointer, iteration)
                  as (select repeat(0, 50)        as memory,
                             1                    as memPointer,
                             cast('' as char(50)) as output,
                             1                    as instrPointer,
                             0                    as iteration
                      union all
                      select
                          -- memory
                          case
                              when substring(tape.value, instrPointer, 1) = '+' then concat(
                                      substring(memory, 1, memPointer - 1),
                                      char(ascii(substring(memory, memPointer, 1)) + 1),
                                      substring(memory, memPointer + 1)
                                  )
                              when substring(tape.value, instrPointer, 1) = '-' then concat(
                                      substring(memory, 1, memPointer - 1),
                                      char(ascii(substring(memory, memPointer, 1)) - 1),
                                      substring(memory, memPointer + 1)
                                  )
                              else memory
                              end          as memory,

                          -- memPointer
                          case
                              when substring(tape.value, memPointer, 1) = '>'
                                  then (memPointer + 1) % memLength.value
                              when substring(tape.value, memPointer, 1) = '<'
                                  then (memPointer - 1) % memLength.value
                              else memPointer
                              end          as memPointer,

                          -- output
                          if(substring(tape.value, instrPointer, 1) = '.',
                             concat(output, substring(memory, memPointer, 1)),
                             output)       as output,

                          instrPointer + 1 as instrPointer,
                          iteration + 1    as iteration
                      from interpreter,
                           tape,
                           memLength
                      where iteration < 10)
select output, iteration, memory, instrPointer, memPointer
from interpreter
order by iteration desc;
