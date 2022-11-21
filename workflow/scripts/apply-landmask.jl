#!/usr/bin/env julia
using IceFloeTracker: create_landmask, apply_landmask, load, @persist

@time begin
# expecting input images in ARGS[1]
dir = ARGS[1]

targetdir = "results"

targetsubdir = joinpath(targetdir,"landmasked_images")

if !isdir(targetsubdir)
    @info "making directory at $targetsubdir"
    mkdir(targetsubdir)
else
    @info "$targetsubdir directory already exists. Proceeding..."
end

imgs = readdir(dir); total = length(imgs)
@info "There are $(total-1) images to landmask in $dir"

# look for Land.tif in /input_images
    if "Land.tif" in imgs
        @info "`Land.tif` found in $dir. Using it as coastline image for masking land."
        
        # Grab coastline
        coastline = popat!(imgs, findall(x->x=="Land.tif",imgs)[1])

        # Create landmask
        @info "creating landmask for $coastline"
        @time "elapsed time to load coastline image" img = load(joinpath(dir,coastline))
        # time to load coastline image: 8.500827 seconds (107.31 M allocations: 7.629 GiB, 11.19% gc time) 
        @time "elapsed time to create landmask" landmask = create_landmask(img)
        @persist landmask joinpath(targetsubdir,"landmask.png") 
        # elapsed time to create landmask: 243.185778 seconds (3.82 M allocations: 476.858 MiB, 0.10% gc time, 1.92% compilation time)
        
        @info "Landmask from $coastline created successfully. Applying it to $imgs.."
    else
        error("`Land.tif` not found in $dir. Please ensure a coastline image `Land.tif` exists in $dir.")
    end

for (i, imgname) in enumerate(imgs)
   
    # make output filename
    fname = imgname[1:findlast(".",imgname)[1]-1]*"_landmasked.png"
    outpath = joinpath(targetsubdir, fname)
    
    @info "Processing $imgname ($i/$total)"

    # Apply landmask to img
    @info "applying landmask and persisting to $fname in $targetsubdir"
    @persist landmasked = apply_landmask(load(joinpath(dir,imgname)), .!landmask) outpath
end

@info "Landmasking completed."

end
