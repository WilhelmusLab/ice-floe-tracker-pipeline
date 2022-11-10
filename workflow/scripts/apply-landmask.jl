#!/usr/bin/env julia
# using IceFloeTracker: create_landmask, apply_landmask, load, persist
using DelimitedFiles: readdlm
dir = ARGS[1]
strel = readdlm("se_landmask.csv", ',', Bool)
if !isdir("landmasked_images")
    mkdir("landmasked_images")
end
imgs = readdir(dir); total = length(imgs)
for (i,img) in enumerate(imgs)
    fname = img[1:findlast(".",img)[1]-1]*"_landmasked"
    path = joinpath("landmasked_images",fname)
    @info "Processing $img ($i/$total)"
    # create landmask and apply it
    # img = load(i)
    # img = println(i)
    # landmask = create_landmask(img, se)
    @info "creating landmask for $img"
    @info "applying landmask and saving to $fname"
    println()
    # @persist landmasked = apply_landmask(img, landmask) "$i"*"_landmasked"
    # Apply landmask?
end
