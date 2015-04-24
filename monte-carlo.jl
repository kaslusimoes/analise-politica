@everywhere function monteCarlo(ρ::Float64,
                                β::Float64,
                                ε::Float64,
                                config::Dict{UTF8String, Real})
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

    # generating the social network
    A = zeros(N, N)
    A[1:g     , 1:g     ] = 1
    # A[1:g     , g+1:2g  ] = 0
    A[1:g     , 2g+1:end] = 1
    # A[g+1:2g  , 1:g     ] = 0
    A[g+1:2g  , g+1:2g  ] = 1
    A[g+1:2g  , 2g+1:end] = 1
    # A[2g+1:end, 1:g     ] = 0
    # A[2g+1:end, g+1:2g  ] = 0
    A[2g+1:end, 2g+1:end] = 1

    transpose!(A)
    for i in 1:N A[i, i] = 0 end

    # defining some difference in influence power
    power = zeros(N)
    power[1:g]      = pow1
    power[g+1:2g]   = pow2
    power[2g+1:end] = 1

    # this function is used to compute the order parameters
    # through the simulation
    function measure():
        h = z'w' / norm^2
        m = mean(h)

        hp = h[h .> 0]
        hn = h[h .< 0]

        np, nn = size(hp, 1), size(hn, 1)
        ms = (np*mean(hp) - nn*mean(hn))/(np+nn)

        q = mean(A*h*h[:,None])
        h1 = h[1:group_size]
        h2 = h[group_size+1:2group_size]
        h3 = h[2group_size+1:end]
        m1, m2, m3 = mean(h1), mean(h2), mean(h3)
        q1, q2, q3 = mean(h1*h1'), mean(h2*h2'), mean(h3*h3')
        q13, q23 = mean(h1*h3'), mean(h2*h3')
        qs = (q13 - q23)/2

        return Dict("m"    => m,
                    "q"    => q,
                    "m_1"  => m1,
                    "m_2"  => m2,
                    "m_3"  => m3,
                    "m_s"  => ms,
                    "q>_1" => q1,
                    "q_2"  => q2,
                    "q_3"  => q3,
                    "q_s"  => qs)
    end

    # initial measurement
    trace = measure()

    # agent interaction potential
    function energy(hi::Float64, hj::Float64):
        X  = hi*sign(hj)/(Q*γ)
        Ep = -γ*γ*log(ε + (1-2ε)erfc(-X/sqrt(2))/2)
        return Ep
    end

    # main MC loop 1st gov
    for t in 1:sweeps*N
        # copy it here
    end

    # invert power to simulate new government
    Power = zeros(N)
    Power[1   :g  ] = pow2
    Power[g+1 :2g ] = pow1
    Power[2g+1:end] = 1

    # main MC loop 2st gov
    for t in 1:sweeps*N
        # pick an agent uniformly in {1,..,N}
        i = sample(1:N)
        # compute the probabilities of agent i to interact with each of
        # his neighbors through the reputation matrix
        pij = normalize(A, 2)
        # and pick a neighbor with the computed probability
        j = sample(pij)


    end

    # formating the acquired data:
    # result is dict of dicts
    # each dict inside result has the form
    #   {(eps, rho, beta): Dataframe}
    # and the Dataframes are special tables that make accessing,
    # reading and saving the data easier.

    # still needing to fix all this code; check if it's correct
    dfs, dfA, dfw = DataFrame(trace), DataFrame(A), DataFrame(w)
    p = (eps, rho, beta)
    stat_dict = Dict(p => dfs)
    A_dict    = Dict(p => dfA)
    w_dict    = Dict(p => dfw)

    return Dict("stat" => stat_dict, "rep" => A_dict, "agt" => w_dict)
end
