:eprof.start()

hello = fn name ->
  IO.puts "hello world, #{name}"
end

parent = self()
pid = spawn(fn ->
  IO.puts "new process"
  Enum.map(1..1000, fn x -> hello.(x) end)

  x = 1+1

  :timer.sleep(1000)

  send(parent, :finished)
end)

IO.puts("child #{inspect(pid)}")

# :eprof.start_profiling([pid, self()])
# :eprof.start_profiling([self()])
:eprof.start_profiling([pid])

  receive do
    :finished -> 
        :eprof.stop_profiling()
        # :eprof.stop()

        :eprof.analyze()
  end

