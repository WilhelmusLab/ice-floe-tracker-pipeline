using IFTPipeline:DataFrames
using YAML, CSV, DataFrames, PyCall
@pyinclude(joinpath("workflow/scripts/flow_templating.py"))

const generate_cylc_files=PyNULL()
copy!(generate_cylc_files, py"generate_cylc_files")

input = "config/example_files/site_locations.csv"

data = DataFrame(CSV.File(input))
data.bounding_box = string.(data.top_left_lat, ",",  data.top_left_lon, ",", data.lower_left_lat, ",", data.lower_left_lon)
data = mapcols(x -> string.("\"", x, "\""), data)

datadict = Dict(pairs(eachcol(data)))
YAML.write_file("resources/site_locations.yml", (datadict))



generate_cylc_files("resources/site_locations.yml", "flow.j2")