using IFTPipeline:DataFrames
using YAML, CSV, DataFrames, PyCall

input = "resources/site_locations.csv"

data = DataFrame(CSV.File(input))
data.bounding_box = string.(data.top_left_lat, ",",  data.top_left_lon, ",", data.lower_left_lat, ",", data.lower_left_lon)
data = mapcols(x -> string.("\"", x, "\""), data)

datadict = Dict(pairs(eachcol(data)))
YAML.write_file("resources/site_locations.yml", (datadict))

@pyinclude(joinpath("workflow/scripts/flow_templating.py"))
const parse_paramsyml=PyNULL()
const generate_cylc_files=PyNULL()

copy!(parse_paramsyml, py"parse_paramsyml")
copy!(generate_cylc_files, py"generate_cylc_files")

generate_cylc_files("resources/site_locations.yml", "flow.j2")