settings = ArgParseSettings(; autofix_names=true)
@add_arg_table! settings begin
    "track"
    help = "Pair ice floes in day k with ice floes in day k+1"
    action = :command
end
IFTPipeline.mkclitrack!(settings)

params_path = "test_inputs/sample-tracker-params.toml"
latlonrefimage = "test_inputs/NE_Greenland_truecolor.2020162.aqua.250m.tiff"
data_path = "test_inputs/tracker/"
temp = mkpath(joinpath(@__DIR__, "__temp__"))
cliparams = [
    "track", # command
    "--imgs",
    temp,
    "--props",
    temp,
    "--passtimes",
    temp,
    "--latlon",
    latlonrefimage,
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
serialize(joinpath(temp, "passtimes.jls"), passtimes)

argsparam = parse_args(cliparams, settings; as_symbols=true)
cmd = argsparam[:_COMMAND_]
IFTPipeline.track(; argsparam[cmd]...)
tracked = deserialize(joinpath(temp, "labeled_floes.jls"))
@test isfile(joinpath(temp, "labeled_floes.jls"))
@test_skip nrow(tracked) == 18
@test_skip maximum(tracked.ID) == 6
@test "passtime" in names(tracked)
