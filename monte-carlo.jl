using JSON

function save_data(idx_data_list, config, label=["epsilon", "rho", "beta"])
    d0 = idx_data_list.pop(0)[-1]

    stat_dict = d0["stat"]
    rep_dict  = d0["rep"]
    agt_dict  = d0["agt"]

    for entry in idx_data_list
        d = entry[-1]
        stat_dict.update(d["stat"])
        rep_dict.update(d["rep"])
        agt_dict.update(d["agt"])
    end

    stat_panel = pd.Panel(stat_dict)
    rep_panel  = pd.Panel(rep_dict)
    agt_panel  = pd.Panel(agt_dict)

    stat_panel.items.set_names(label, inplace=True)
    rep_panel.items.set_names(label, inplace=True)
    agt_panel.items.set_names(label, inplace=True)

    SAVE_DIR = config["save_directory"] * config["label"]
    if os.path.exists(config["save_directory"])
        if not os.path.exists(SAVE_DIR)
            os.mkdir(SAVE_DIR)
        end
    else
        raise Exception("%s is not a valid path"%config["save_directory"])
    end

    open(joinpath(SAVE_DIR, "config.json"), "w") do file
        json.dump(config, file, indent=4)
    end

    open(joinpath(SAVE_DIR, '/statistics.csv'), "w") do file
        df = stat_panel.to_frame()
        df.to_csv(file)#, mode='a', index=False, index_label=False)
    end

    open(joinpath(SAVE_DIR, '/reputation.csv'), "w") do file
        df = rep_panel.to_frame()
        df.to_csv(file)#, mode='a', index=False, index_label=False)
    end

    open(joinpath(SAVE_DIR, '/state.csv'), "w") do file
        df = agt_panel.to_frame()
        df.to_csv(file)#, mode='a', index=False, index_label=False)
    end
end

function run(x)
    idx, eps, rho, beta = x
    r = mc(rho, beta, eps, config)
    return idx, r
end


function main(input::String,      # Input file with model parameters
              label::String = "") # Label given to simulation files

    # Assert the input is a valid file
    @assert isfile(input) "input is not a valid file"

    # Create a dictionary with the configurations stores on the input file
    config  = JSON.parsefile(input)
    config["label"]     = label
    config["zeitgeist"] = [config["D"]]

    beta_grid  = colon(config["beta"]...)
    rho_grid   = colon(config["rho"]...)
    eps_grid   = colon(config["epsilon"]...)

    grid   = mgrid[eps_grid, rho_grid, beta_grid]
    points = vstack([x.ravel() for x in grid]).T
    order  = arange(points.shape[0])[:,np.newaxis]
    args   = hstack([order, points])

    pool = mp.Pool()
    t0 = time.time()
    print(40*"=")
    print("Passed:", json.dumps(config, indent=4), sep="\n")
    print("Starting at: ", time.asctime())
    result = pool.map(run, args)
    pool.close()
    pool.join()
    result.sort()
    t = time.time()
    print("pool.map(run, args) took %s"%(timedelta(seconds=(t-t0))))

    t0_save = time.time()
    save_data(result, config)
    t_save = time.time()
    print("save_data took %s"%(timedelta(seconds=(t_save-t0_save))))
    t_final = time.time()
    print("Total time spent: %s"%(timedelta(seconds=(t_save-t0))))
    print("Finished at: ", time.asctime())
    print(40*"=")
end
