function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "input"
            help = "Input file with model parameters"
            arg_type = String
            required = true
        "label"
            help = "Output Label"
            arg_type = String
            required = true
    end

    return parse_args(s)
end
