
# using IceFloeTracker: create_landmask, apply_landmask, load
using DelimitedFiles: readdlm
dir = ARGS[1]
strel = readdlm("se_landmask.csv", ',', Bool)
imgs = readdir(dir); total = length(imgs)
for (i,img) in enumerate(imgs)
    fname = img[1:findlast(".",img)[1]-1]
    @info "Processing $img ($i/$total)"
    # create landmask and apply it
    # img = load(i)
    # img = println(i)
    # landmask = create_landmask(img, se)
    @info "creating landmask for $img"
    @info "applying landmask and saving to $fname"*"_landmasked"
    println()
    # @persist apply_landmask(img, landmask) "$i"*"_landmasked"
end
