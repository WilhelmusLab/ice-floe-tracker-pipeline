settings = ArgParseSettings(; autofix_names=true)
@add_arg_table! settings begin
    "track"
    help = "Pair ice floes in day k with ice floes in day k+1"
    action = :command
end
IFTPipeline.mkclitrack!(settings)

params_path = "../config/sample-tracker-params.toml"

data_path = "test_inputs/tracker/"
temp = mkpath(joinpath(@__DIR__, "__temp__"))
cliparams = [
    "track",
    "--imgs",
    temp,
    "--props",
    temp,
    "--passtimes",
    temp,
    "--deltat",
    temp,
    "--output",
    temp,
    "--params",
    params_path,
]

obj = deserialize(joinpath(data_path, "tracker_test_data.dat"))
passtimes = deserialize(joinpath(data_path, "passtimes.dat"))

# Keep floes with area >= 350 pixels
for (i, prop) in enumerate(obj.props)
    obj.props[i] = prop[prop[:, :area].>=350, :]
end

serialize(joinpath(temp, "segmented_floes.jls"), obj.imgs)
serialize(joinpath(temp, "floe_props.jls"), obj.props)
serialize(joinpath(temp, "timedeltas.jls"), [15.0, 20.0])
serialize(joinpath(temp, "passtimes.jls"), passtimes)

argsparam = parse_args(cliparams, settings; as_symbols=true)
cmd = argsparam[:_COMMAND_]
IFTPipeline.track(; argsparam[cmd]...)
tracked = deserialize(joinpath(temp, "labeled_floes.jls"))
@test isfile(joinpath(temp, "labeled_floes.jls"))
@test nrow(tracked) == 22
@test maximum(tracked.ID) == 10
@test "passtime" in names(tracked)
