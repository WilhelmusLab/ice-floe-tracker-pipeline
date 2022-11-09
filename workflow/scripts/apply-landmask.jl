
using IceFloeTracker: create_landmask, apply_landmask, load, readdlm
dir = ARGS[1]
strel = readdlm("se_landmask.csv", ',', Bool)
imgs = readdir(dir)
for i in imgs
    # create landmask and apply it
    # img = load(i)
    img = println(i)
    # landmask = create_landmask(img, se)
    println("creating landmask")
    println("applying landmask and saving to", "$i"*"_landmasked" )
    # @persist apply_landmask(img, landmask) "$i"*"_landmasked"
end
