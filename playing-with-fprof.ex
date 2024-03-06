:fprof.start()

IO.puts "#{inspect(self())}"

# :fprof.trace([:start, procs: :all])
:fprof.trace([:start, procs: [self()]])
#
# Do some work
# 1..5 |> Enum.each(fn i ->
#     spawn(fn -> IO.puts "I wont do anything" end)
# end)
 
:fprof.trace(:stop)
:fprof.profile()
:fprof.analyse()
# :fprof.analyse(totals: false, dest: 'prof.analysis')
