# set @@cte_max_recursion_depth = 10000000;
-- >++++++++[<+++++++++>-]<.

with
    recursive
    tape (value) as (select ?),
    input (value) as (select ?),
    braceMatchesWorker(program, pointer, nests, charAt, matches, lastOpeningsAndNestPos)
    as (select tape.value,
               0,
               0,
               cast('' as char(1)) as charAt,
               json_object()       as matches,
               json_array()        as lastOpeningsAndNestPos
        from tape
        union all
        select program         as program,
               pointer + 1,
               case
                   when substring(program, pointer + 1, 1) = '[' then nests + 1
                   when substring(program, pointer + 1, 1) = ']' then nests - 1
                   else nests
                   end         as nests,
               substring(tape.value, pointer + 1, 1)
                ,
               -- matches
               IF(substring(program, pointer + 1, 1) = ']', json_insert(
                       json_insert(matches, concat('$."', json_extract(
                               lastOpeningsAndNestPos,
                               concat('$[', json_length(lastOpeningsAndNestPos) - 1, ']')), '"'),
                                   pointer + 1),
                       concat('$."', pointer + 1, '"'),
                       json_extract(lastOpeningsAndNestPos, concat('$[', json_length(lastOpeningsAndNestPos) - 1, ']'))
                   ), matches) as matches,

               -- lastOpeningsAndNestPos
               case
                   when substring(program, pointer + 1, 1) = '['
                       then json_array_append(lastOpeningsAndNestPos, '$', pointer + 1)
                   when substring(program, pointer + 1, 1) = ']'
                       then json_remove(lastOpeningsAndNestPos,
                                        concat('$[', json_length(lastOpeningsAndNestPos) - 1, ']'))
                   else lastOpeningsAndNestPos
                   end         as lastOpeningsAndNestPos
        from braceMatchesWorker,
             tape
        where pointer < length(program))
        ,
    bracesMatches (matches) as (select matches from braceMatchesWorker order by pointer desc limit 1),
    memLength (value) as (select 1000),
    interpreter (memory, memPointer, output, instrPointer, iteration, done)
    as (select cast(repeat('\0', memLength.value) as binary) as memory,
               1                                             as memPointer,
               cast('' as char(500))                         as output,
               1                                             as instrPointer,
               0                                             as iteration,
               false                                         as done
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
                            json_extract(bracesMatches.matches, concat('$."', instrPointer, '"')) + 1,
                            instrPointer + 1)
                when substring(tape.value, instrPointer, 1) = ']'
                    then if(substring(memory, memPointer, 1) <> '\0',
                            json_extract(bracesMatches.matches, concat('$."', instrPointer, '"')) + 1,
                            instrPointer + 1)
                else instrPointer + 1
                end
                                              as instrPointer,

            iteration + 1                     as iteration,
            instrPointer > length(tape.value) as done
        from interpreter,
             tape,
             memLength,
             bracesMatches
        where iteration < 600000 && !done)
select output, iteration, left(memory, 20) as memory, instrPointer, memPointer
from interpreter,
     memLength,
     tape,
     bracesMatches
order by iteration desc
LIMIT 100 OFFSET 1;
