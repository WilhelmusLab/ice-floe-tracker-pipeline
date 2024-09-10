"""
    landmask(; input, output)

Given an input directory with a landmask file, create a land/soft ice mask object with both dilated and non_dilated versions. The object is serialized to the snakemake output directory. 

# Arguments
- `input`: path to landmask source image
- `output`: path to output file
"""
function landmask(; input::String, output::String)
    @info "Using $input as landmask"
    check_landmask_path(input)
    img = load(input)
    @info "Landmask found at $input."
    
    @info "Create landmask, both dilated and non-dilated as namedtuple"
    landmask = create_landmask(img)

    @info "Saving landmask to $output"    
    serialize(output, landmask)
    
    @info "Landmask created and serialized succesfully."
    return nothing
end
