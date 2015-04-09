@everywhere H(x) = erfc(x/sqrt(2))/2

function main()
    # Parse command line
    args = parse_commandline()
    input, label = args["input"], args["label"]

    # Assert the input is a valid file
    @assert isfile(input) "input is not a valid file"

    # Parse input JSON file
    config  = JSON.parsefile(input)
    config["label"]     = label
    config["zeitgeist"] = [config["D"]]

    # Epsilon, Rho and Beta ranges
    β_grid  = colon(config["beta"]...)
    ρ_grid   = colon(config["rho"]...)
    ε_grid   = colon(config["epsilon"]...)

    # Create list of arguments for simulations
    grid = [(i, j, k) for i in ε_grid, j in ρ_grid, k in β_grid]
    mcArgs = sort(reshape(grid, length(grid)))

    # print(40^"=")
    # print("Passed:", json.dumps(config, indent=4), sep="\n")
    @time begin
       # Monte carlo
       println("Monte carlo simulations:")
       @time results = pmap(arg -> monteCarlo(arg..., config), mcArgs)

       #Save data
       println("Saving Data:")
       @time save_data(result, config)

       println("Total:")
    end
    # print(40^"=")


end
