#!/usr/bin/env julia
using IceFloeTracker: create_landmask, apply_landmask, load, @persist
# using DelimitedFiles: readdlm

# @time begin
# expecting input images in ARGS[1]
dir = ARGS[1]
dir = "resources/input-images"
# se = readdlm("se_landmask.csv", ',', Bool)
# se = readdlm("se_landmask.csv", ',', Bool)
targetdir = "results"

targetsubdir = joinpath(targetdir,"landmasked_images")
pwd()

if !isdir(targetsubdir)
    @info "making directory at $targetsubdir"
    mkdir(targetsubdir)
else
    @info "say what to do if directory already exists."
end

imgs = readdir(dir); total = length(imgs)
@info "There are $(total-1) images to landmask in $dir"

# look for Land.tif in /input_images
    if "Land.tif" in imgs
        @info "`Land.tif` found in $dir. Using it as coastline image for masking land."
        
        # Grab coastline
        coastline = popat!(imgs, findall(x->x=="Land.tif",imgs)[1])

        # Create landmask
        @time img = load(joinpath(dir,coastline))
        @time landmask = create_landmask(img)
    else
        error("`Land.tif` not found in $dir. Please ensure a coastline image `Land.tif` exists in $dir.")
    end

# Use a subset to process for now
    imgs = imgs[1:2]

# for (i, imgname) in enumerate(imgs)
    i=1; imgname = imgs[1]
    fname = imgname[1:findlast(".",imgname)[1]-1]*"_landmasked.png"
    outpath = joinpath(targetsubdir, fname)
    @info "Processing $imgname ($i/$total)"
    # create landmask and apply it
    @time img = load(joinpath(dir,imgname))
    # img = println(i)
    @info "creating landmask for $imgname"
    

    @info "applying landmask and persisting to $fname in $targetsubdir"
    @persist landmasked = apply_landmask(img, landmask) outpath
# end
# end
