
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

    # # this function is used to compute the order parameters
    # # through the simulation
    # function measure():
    #       h = z.dot(w.T)/norm/norm
    #       m = h.mean()
    #       hp = h[h>0]
    #       hn = h[h<0]
    #       np, nn = hp.shape[0], hn.shape[0]
    #       ms = (np*hp.mean() - nn*hn.mean())/(np+nn)
    #       q = (A*h*h[:,None]).mean()
    #       h1 = h[:group_size]
    #       h2 = h[group_size:2*group_size]
    #       h3 = h[2*group_size:]
    #       m1 = h1.mean()
    #       m2 = h2.mean()
    #       m3 = h3.mean()
    #       q1 = (h1*h1[:,None]).mean()
    #       q2 = (h2*h2[:,None]).mean()
    #       q3 = (h3*h3[:,None]).mean()
    #       q13 = (h1*h3[:,None]).mean()
    #       q23 = (h2*h3[:,None]).mean()
    #       qs = (q13 - q23)/2
    #
    #       trace = dict(
    #           m=m,
    #           q=q,
    #           m_1=m1,
    #           m_2=m2,
    #           m_3=m3,
    #           m_s=ms,
    #           q_1=q1,
    #           q_2=q2,
    #           q_3=q3,
    #           q_s=qs
    #       )
    #       return trace
    #
    #
    #       # initial measurement
    #       trace = measure()
end
