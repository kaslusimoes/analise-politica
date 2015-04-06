
# The macro everywhere sets stage for parallel computing
@everywhere H(x) = erfc(x/sqrt(2))/2

@everywhere function monteCarlo(ρ::Float64, β::Float64, ε::Float64, config::Dict{UTF8String, Real})
    N0 = config["N"]
    D  = config["D"]
    dw = config["dw"]
    dr = config["dr"]
    sweeps  = config["sweeps"]
    pow1, pow2 = config["power1"], config["power2"]

    g = group_size = int(ceil(N0/3))
    N = 3g
    normD = sqrt(D)
    Q = normD/sqrt(D)
    γ = sqrt(1 - ρ^2)/ρ

    # Seed for RNG
    srand(78956347)

    # sampling a N x D matrix with entries distributed by a Normal
    # with zero mean and unity variance.
    w1 = rand(Normal(0.1, 0.75), g, D)
    w2 = rand(Normal(0.1, -0.75), g, D)
    w3 = rand(Normal(), g, D)
    w = vcat(w1, w2, w3)

    # normalize each line i so that w[i] ⋅ w[i] = norm²
    # the lines are the agents cognitive vectors
    w .*= normD ./ sqrt(sum(w.*w, 2))

    # the zeitgeist vector using the same normalization
    z = normD ./ norm(ones(D))

    
end

@everywhere function run(arg, config)
    ε, ρ, β = arg
    return mc(ρ, β, ε, config)
end

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
       @time results = pmap(arg -> run(arg, config), mcArgs)

       #Save data
       println("Saving Data:")
       @time save_data(result, config)

       println("Total:")
    end
    # print(40^"=")


end
