using ArgParse, Statistics

function parse_options()
  s = ArgParseSettings()

  @add_arg_table s begin
    "--machine-info"
      help = "Print CPU Specs"
      action = :store_true
    "--read-environment"
      help = "Read environment file"
    "--read-counters"
      help = "Read papi counter file"
    "--measurement"
      help = "Time or Counters"
      required = true
    "--explore-threads"
      help = "Vary number of threads"
      action = :store_true
    "--explore-problem-size"
      help = "Vary matrix size"
    "--polybench-source"
      help = "Source file to benchmark"
      required = true
    "--command"
      help = "Run executable"
  end

  return parse_args(s)
end

function print_machine_info()
  println("Machine Info:")

  # CPU model specs
  run(pipeline(`cat /proc/cpuinfo`, `grep 'model name'`,  `uniq`))
  
  # Number of physical cores
  print("Number of physical cores: ")
  run(pipeline(`grep '^core id' /proc/cpuinfo`, `sort -u`, `wc -l`))

  # Number of logical units
  print("Number of logical units: ")
  run(pipeline(`grep '^processor' /proc/cpuinfo`, `sort -u`, `wc -l`))

  println()
end

function explore_threads(env, binary, n_runs)
  m = match(r"export OMP_NUM_THREADS=(?<max_threads>\d+)", env)
  results = []

  for i=1:parse(Int32, m[:max_threads])
    e = replace(env, r"export OMP_NUM_THREADS=(?<max_threads>\d+)" => "export OMP_NUM_THREADS=$i")
    push!(results, run_n_times(e, binary, n_runs))
  end

  return results
end

function run_n_times(env, binary, n)
  results = []

  for i=1:n
    push!(results, chomp(read(`sh -c "$(env) ./$(binary)"`, String)))
  end

  return results
end

function print_stats(label, measurement, counters, results)
  if measurement == "time"
    times = parse.(Float64, results)
    println("$(label): \t $(minimum(times))s / $(maximum(times))s / $(mean(times))s")
  elseif measurement == "counters"
    counters = split(counters, "\n")
    run_results = map(r -> split(r ," "), results)

    for i = 1:size(counters, 1)
      counter_results = []

      for j = 1:size(run_results, 1)
        push!(counter_results, parse(Int64, run_results[j][i]))
      end

      println("$(label) $(counters[i][2:end-2]): \t $(minimum(counter_results)) / $(maximum(counter_results)) / $(mean(counter_results))")
    end
  else
    println(results)
  end
end

function main()
  args = parse_options()
  n_runs = 10
  binary = ""
  measurement_flag = ""
  counters = ""
  env = []
  
  #######################
  # Prepare Environment
  #######################

  if args["read-environment"] !== nothing 
    env = read(args["read-environment"], String)
  end

  if args["measurement"] == "time"
    measurement_flag = "-DPOLYBENCH_TIME"
  elseif args["measurement"] == "counters"
    measurement_flag = "-DPOLYBENCH_PAPI"
  end

  if args["read-counters"] !== nothing
    cp(args["read-counters"], "polybench-c-4.2.1-beta/utilities/papi_counters.list", force=true)
    counters = read(args["read-counters"], String)
  end

  ##################
  # Prepare Binary
  ##################

  if args["polybench-source"] !== nothing
    #binary = join(split(args["polybench-source"], "."), "_") * "_binary"
    binary = "correlation"
    run(`gcc -O0 $(measurement_flag) -fopenmp -I polybench-c-4.2.1-beta/utilities -I polybench-c-4.2.1-beta/datamining/correlation polybench-c-4.2.1-beta/utilities/polybench.c polybench-c-4.2.1-beta/$(args["polybench-source"]) -o $(binary) -I /home/tim/Code/compilers/hw4/papi/install/include -L /home/tim/Code/compilers/hw4/papi/install/lib -lpapi -lm`)
  end
  
  ###################
  # Run Experiments
  ###################

  # Print Specs
  if args["machine-info"]
    print_machine_info()
  end

  # Explore Problem Size and Threads
  if (args["explore-problem-size"] !== nothing) && args["explore-threads"]
    sizes = map(x -> parse(Int32, x), split(args["explore-problem-size"], ","))

    for s in sizes
      run(`gcc -O3 $(measurement_flag) -DNI=$(s) -DNJ=$(s) -DNK=$(s) -fopenmp -I polybench-c-4.2.1-beta/utilities -I polybench-c-4.2.1-beta/datamining/correlation polybench-c-4.2.1-beta/utilities/polybench.c polybench-c-4.2.1-beta/$(args["polybench-source"]) -o $(binary)_$(s) -I /home/tim/Code/compilers/hw4/papi/install/include -L /home/tim/Code/compilers/hw4/papi/install/lib -lpapi -lm`)
      results = explore_threads(env, "$(binary)_$(s)", n_runs)

      for i = 1:size(results, 1)
        print_stats("$(binary)_$(s)_$(i)", args["measurement"], counters, results[i])
      end
    end
  
  # Explore Only Problem Size
  elseif args["explore-problem-size"] !== nothing
    sizes = map(x -> parse(Int32, x), split(args["explore-problem-size"], ","))

    for s in sizes
      run(`gcc -O3 $(measurement_flag) -DNI=$(s) -DNJ=$(s) -DNK=$(s) -I polybench-c-4.2.1-beta/utilities -I polybench-c-4.2.1-beta/datamining/correlation polybench-c-4.2.1-beta/utilities/polybench.c polybench-c-4.2.1-beta/$(args["polybench-source"]) -o $(binary)_$(s) -I /home/tim/Code/compilers/hw4/papi/install/include -L /home/tim/Code/compilers/hw4/papi/install/lib -lpapi -lm`)
      results = run_n_times(env, "$(binary)_$(s)", n_runs)
      print_stats("$(binary)_$(s)", args["measurement"], counters, results)
    end

  # Explore Only Threads
  elseif args["explore-threads"]
    results = explore_threads(env, binary, n_runs)

    for i = 1:size(results, 1)
      print_stats("$(binary)_$(i)", args["measurement"], counters, results[i])
    end

  # Run Single Experiment
  elseif binary !== ""  && env != []
    results = run_n_times(env, binary, n_runs)
    print_stats(binary, args["measurement"], counters, results)
  end 
end

main()