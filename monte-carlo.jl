using JSON

# function save_data(idx_data_list, config, label=["epsilon", "rho", "beta"])
#     d0 = idx_data_list.pop(0)[-1]
#
#     stat_dict = d0["stat"]
#     rep_dict  = d0["rep"]
#     agt_dict  = d0["agt"]
#
#     for entry in idx_data_list
#         d = entry[-1]
#         stat_dict.update(d["stat"])
#         rep_dict.update(d["rep"])
#         agt_dict.update(d["agt"])
#     end
#
#     stat_panel = pd.Panel(stat_dict)
#     rep_panel  = pd.Panel(rep_dict)
#     agt_panel  = pd.Panel(agt_dict)
#
#     stat_panel.items.set_names(label, inplace=True)
#     rep_panel.items.set_names(label, inplace=True)
#     agt_panel.items.set_names(label, inplace=True)
#
#     SAVE_DIR = config["save_directory"] * config["label"]
#     if os.path.exists(config["save_directory"])
#         if not os.path.exists(SAVE_DIR)
#             os.mkdir(SAVE_DIR)
#         end
#     else
#         raise Exception("%s is not a valid path"%config["save_directory"])
#     end
#
#     open(joinpath(SAVE_DIR, "config.json"), "w") do file
#         json.dump(config, file, indent=4)
#     end
#
#     open(joinpath(SAVE_DIR, '/statistics.csv'), "w") do file
#         df = stat_panel.to_frame()
#         df.to_csv(file)#, mode='a', index=False, index_label=False)
#     end
#
#     open(joinpath(SAVE_DIR, '/reputation.csv'), "w") do file
#         df = rep_panel.to_frame()
#         df.to_csv(file)#, mode='a', index=False, index_label=False)
#     end
#
#     open(joinpath(SAVE_DIR, '/state.csv'), "w") do file
#         df = agt_panel.to_frame()
#         df.to_csv(file)#, mode='a', index=False, index_label=False)
#     end
# end

@everywhere function run(arg, config)
    eps, rho, beta = arg
    return mc(rho, beta, eps, config)
end


function main(input::String,      # Input file with model parameters
              label::String = "") # Label given to simulation files

    # Assert the input is a valid file
    @assert isfile(input) "input is not a valid file"

    # Create a dictionary with the configurations stores on the input file
    config  = JSON.parsefile(input)
    config["label"]     = label
    config["zeitgeist"] = [config["D"]]

    # Epsilon, Rho and Beta ranges
    beta_grid  = colon(config["beta"]...)
    rho_grid   = colon(config["rho"]...)
    eps_grid   = colon(config["epsilon"]...)

    # Create list of arguments for simulations
    grid = [(i, j, k) for i in eps_grid, j in rho_grid, k in beta_grid]
    args = sort(reshape(grid, length(grid)))

    # print(40^"=")
    # print("Passed:", json.dumps(config, indent=4), sep="\n")
    @time begin
       # Monte carlo
       println("Monte carlo simulations:")
       @time results = pmap(arg -> run(arg, config), args)

       #Save data
       println("Saving Data:")
       @time save_data(result, config)

       println("Total:")
    end
    # print(40^"=")
end
