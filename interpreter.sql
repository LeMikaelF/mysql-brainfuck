with
    recursive constants(tape, input, memLength, maxIterations) as (select ?, ?, 1000, 600000),
              braceMatchesWorker(tapePointer, matches, openingBracesStack)
                  as (select 0,
                             json_object() as matches,
                             json_array()  as openingBracesStack
                      union all
                      select tapePointer + 1,
                             -- matches
                             IF(substring(constants.tape, tapePointer + 1, 1) = ']', json_insert(
                                     json_insert(matches, concat('$."', json_extract(
                                             openingBracesStack,
                                             concat('$[', json_length(openingBracesStack) - 1, ']')), '"'),
                                                 tapePointer + 1),
                                     concat('$."', tapePointer + 1, '"'),
                                     json_extract(
                                             openingBracesStack,
                                             concat('$[', json_length(openingBracesStack) - 1, ']'))
                                 ), matches) as matches,

                             -- openingBracesStack
                             case
                                 when substring(constants.tape, tapePointer + 1, 1) = '['
                                     then json_array_append(openingBracesStack, '$', tapePointer + 1)
                                 when substring(constants.tape, tapePointer + 1, 1) = ']'
                                     then json_remove(openingBracesStack,
                                                      concat('$[', json_length(openingBracesStack) - 1, ']'))
                                 else openingBracesStack
                                 end         as openingBracesStack
                      from braceMatchesWorker,
                           constants
                      where tapePointer < length(constants.tape)),
              bracesMatches (matches) as (select matches from braceMatchesWorker order by tapePointer desc limit 1),
              interpreter (memory, memPointer, output, instrPointer, inputPointer, iteration, done)
                  as (select cast(repeat('\0', constants.memLength) as binary) as memory,
                             1                                                 as memPointer,
                             cast('' as char(500))                             as output,
                             1                                                 as instrPointer,
                             1                                                 as inputPointer,
                             0                                                 as iteration,
                             false                                             as done
                      from constants
                      union all
                      select
                          -- memory
                          case
                              when substring(constants.tape, instrPointer, 1) = '+' then concat(
                                      substring(memory, 1, memPointer - 1),
                                      char((ascii(substring(memory, memPointer, 1)) + 1) % 256),
                                      substring(memory, memPointer + 1)
                                  )
                              when substring(constants.tape, instrPointer, 1) = '-' then concat(
                                      substring(memory, 1, memPointer - 1),
                                      char((ascii(substring(memory, memPointer, 1)) - 1) % 256),
                                      substring(memory, memPointer + 1)
                                  )
                              when substring(constants.tape, instrPointer, 1) = ',' then concat(
                                      substring(memory, 1, memPointer - 1),
                                      substring(constants.input, inputPointer, 1),
                                      substring(memory, memPointer + 1)
                                  )
                              else memory
                              end                               as memory,

                          -- memPointer
                          case
                              when substring(constants.tape, instrPointer, 1) = '>' then (memPointer + 1)
                              when substring(constants.tape, instrPointer, 1) = '<' then (memPointer - 1)
                              else memPointer
                              end                               as memPointer,

                          -- output
                          if(substring(constants.tape, instrPointer, 1) = '.',
                             concat(output, substring(memory, memPointer, 1)),
                             output)                            as output,

                          -- instrPointer
                          case
                              when substring(constants.tape, instrPointer, 1) = '['
                                  then if(substring(memory, memPointer, 1) = '\0',
                                          json_extract(bracesMatches.matches,
                                                       concat('$."', instrPointer, '"')) + 1, instrPointer + 1)
                              when substring(constants.tape, instrPointer, 1) = ']'
                                  then if(substring(memory, memPointer, 1) <> '\0',
                                          json_extract(bracesMatches.matches,
                                                       concat('$."', instrPointer, '"')) + 1, instrPointer + 1)
                              else instrPointer + 1
                              end
                                                                as instrPointer,

                          -- inputPointer
                          if(substring(constants.tape, instrPointer, 1) = ',',
                             inputPointer + 1,
                             inputPointer)                      as inputPointer,

                          -- iteration
                          iteration + 1                         as iteration,

                          -- done
                          instrPointer > length(constants.tape) as done
                      from interpreter,
                           constants,
                           bracesMatches
                      where iteration < constants.maxIterations && !done)
select output
from interpreter,
     bracesMatches
order by iteration desc
LIMIT 1 OFFSET 1;
