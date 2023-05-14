with
    recursive tape (value) as (select ?),
              interpreter (memory, pointer, output, iteration)
                  as (select repeat(0, 50)        as memory,
                             1                    as pointer,
                             cast('' as char(50)) as output,
                             0                    as iteration
                      union all
                      select memory,
                             case
                                 when substring(tape.value, pointer, 1) = '>' then pointer + 1
                                 when substring(tape.value, pointer, 1) = '<' then pointer - 1
                                 else pointer
                                 end,
                             output,
                             iteration + 1
                      from interpreter,
                           tape
                      where iteration < 10)
select output, iteration, memory, pointer
from interpreter
order by iteration;
