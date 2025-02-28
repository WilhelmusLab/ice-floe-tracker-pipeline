"""
    track(
    imgsdir::String,
    propsdir::String,
    passtimesdir::String,
    paramsdir::String,
    outdir::String,
)

Pair floes in the floe library using an equivalent implementation as in the MATLAB script `final_2020.m` from https://github.com/WilhelmusLab/ice-floe-tracker/blob/main/existing_code/final_2020.m.

# Arguments
- `indir`: path to directory containing the floe library (cropped floe masks for registration and correlation), extracted features from segmented images, and satellite overpass times.
- `condition_thresholds`: 3-tuple of thresholds (each a named tuple) for deciding whether to match floe `i` from day `k` to floe j from day `k+1`.
- `mc_thresholds`: thresholds for area mismatch and psi-s shape correlation and goodness of a match. 

See `IceFloeTracker.jl/notebooks/track-floes/track-floes.ipynb` for a sample workflow.

Following are the default set of thresholds `condition_thresholds` used for floe matching:
- Condition 1: time elapsed `dt` from image `k` to image `k+1` and distance between floes centroids `dist`: `t1=(dt = (30, 100, 1300), dist=(15, 30, 120))`

- Condition 2: area of floe i `area`, and the computed ratios for area, major axis,  minor axis, and convex area of floes `i` and `j` in days `k` and `k+1`, respectively: `t2=(area=1200, arearatio=0.28, majaxisratio=0.10, minaxisratio=0.12, convexarearatio=0.14)`

- Condition 3: as in the previous condition but set as follows: `
t3=(area=1200, arearatio=0.18, majaxisratio=0.07, minaxisratio=0.08, convexarearatio=0.09)`
"""
function track(; args...)
    condition_thresholds, mc_thresholds = get_thresholds(; args...)
    vals = NamedTuple{Tuple(keys(args))}(values(args)) # convert to NamedTuple
    imgs = deserialize(joinpath(vals.imgs, "segmented_floes.jls"))
    props = deserialize(joinpath(vals.props, "floe_props.jls"))
    passtimes = deserialize(joinpath(vals.passtimes, "passtimes.jls"))
    latlon = vals.latlon
    labeledfloes = IceFloeTracker.pairfloes(imgs, props, passtimes, latlon, condition_thresholds, mc_thresholds)
    serialize(joinpath(vals.output, "labeled_floes.jls"), labeledfloes)
    return nothing
end

"""
    track_single(
        imgs::Array{String},
        props::Array{String},
        passtimes::Array{DateTime},
        latlon::String,
        output::String,
        ...
)
Pair floes in the floe library using an equivalent implementation as in the MATLAB script `final_2020.m` from https://github.com/WilhelmusLab/ice-floe-tracker/blob/main/existing_code/final_2020.m.

# Arguments
- `imgs`: segmented images filenames (.tiff)
- `props`: corresponding floe properties filenames (.csv)
- `passtimes`: corresponding pass-times for each image
- `latlon`: an example image with geospatial data (e.g., the original true-color image, .tiff)
- `output`: filename for output file (.csv)
- tracker parameters (see source code)

Following are the default set of thresholds `condition_thresholds` used for floe matching:
- Condition 1: time elapsed `dt` from image `k` to image `k+1` and distance between floes centroids `dist`: `t1=(dt = (30, 100, 1300), dist=(15, 30, 120))`
- Condition 2: area of floe i `area`, and the computed ratios for area, major axis,  minor axis, and convex area of floes `i` and `j` in days `k` and `k+1`, respectively: `t2=(area=1200, arearatio=0.28, majaxisratio=0.10, minaxisratio=0.12, convexarearatio=0.14)`
- Condition 3: as in the previous condition but set as follows: `t3=(area=1200, arearatio=0.18, majaxisratio=0.07, minaxisratio=0.08, convexarearatio=0.09)`
"""
function track_single(;
    imgs::Array{String},
    props::Array{String},
    passtimes::Array{DateTime},
    latlon::String,
    output::String,
    dist::Array{Int}=[200, 250, 300],
    dt_thresh::Array{Int}=[30, 100, 1300],
    Sminimumarea::Float64=400.0,
    Sarearatio::Float64=0.18,
    Smajaxisratio::Float64=0.1,
    Sminaxisratio::Float64=0.12,
    Sconvexarearatio::Float64=0.14,
    Lminimumarea::Float64=1200.0,
    Larearatio::Float64=0.28,
    Lmajaxisratio::Float64=0.1,
    Lminaxisratio::Float64=0.15,
    Lconvexarearatio::Float64=0.14,
    mxrot::Int64=10,
    psi::Float64=0.95,
    sz::Int64=16,
    comp::Float64=0.25,
    mm::Float64=0.22,
    corr::Float64=0.68,
    small_floe_area::Float64=0.18,
    large_floe_area::Float64=0.236,
)

    # Load the files – can we drop the memory requirements by doing two at once?
    @info "Loading $imgs"
    imgs_::Vector{Matrix{<:Integer}} = [load_labeled_img(img) for img in imgs]

    @info "Loading $props"
    props_ = [DataFrame(CSV.File(prop)) for prop in props]
    # go through each of the props_ dataframes and convert each 
    # into the element type from the corresponding image.
    for (img_, prop_) in zip(imgs_, props_)
        label_type = eltype(img_)
        @debug "converting labels to $label_type"
        prop_[!, :label] = convert.(label_type, prop_[!, :label])
    end
    @info "Loaded: $props_"

    @info "Set condition thresholds"
    small_floe_settings = (
        minimumarea=Sminimumarea,
        arearatio=Sarearatio,
        majaxisratio=Smajaxisratio,
        minaxisratio=Sminaxisratio,
        convexarearatio=Sconvexarearatio,
    )
    large_floe_settings = (
        minimumarea=Lminimumarea,
        arearatio=Larearatio,
        majaxisratio=Lmajaxisratio,
        minaxisratio=Lminaxisratio,
        convexarearatio=Lconvexarearatio,
    )
    search_thresholds = (dt=dt_thresh, dist=dist)
    condition_thresholds = (; search_thresholds, small_floe_settings, large_floe_settings)

    @debug condition_thresholds

    @info "Set MC thresholds"
    mc_thresholds = (
        comp=(; mxrot, sz, comp, mm, psi),
        goodness=(; corr, small_floe_area, large_floe_area),
    )
    @debug mc_thresholds

    @info "Using passtimes=$passtimes"
    add_passtimes!(props_, passtimes)
    addfloemasks!(props_, imgs_)
    addψs!(props_)
    adduuid!(props_)

    tracked_floes = long_tracker(props_, condition_thresholds, mc_thresholds)
    FileIO.save(output, select!(tracked_floes, Not(:mask, :psi)))
    return tracked_floes
end

function parse_params(params::AbstractString)
    params = parsefile(params)
    @info params
    search_thresholds = dict2nt(params["search_thresholds"])
    small_floe_settings = dict2nt(params["small_floe_settings"])
    large_floe_settings = dict2nt(params["large_floe_settings"])
    condition_thresholds = (; search_thresholds, small_floe_settings, large_floe_settings)
    d = dict2nt(params["mc_thresholds"])
    mc_thresholds = mkmct(d)
    return condition_thresholds, mc_thresholds
end

function parse_params(; args...)
    d = values(args)
    condition_thresholds = (
        search_thresholds=(
            dt=parselistas(Int64, d.dt_thresh), dist=parselistas(Int64, d.dist)
        ),
        large_floe_settings=(
            minimumarea=d.Lminimumarea,
            arearatio=d.Larearatio,
            convexarearatio=d.Lconvexarearatio,
            majaxisratio=d.Lmajaxisratio,
            minaxisratio=d.Lminaxisratio,
        ),
        small_floe_settings=(
            minimumarea=d.Sminimumarea,
            arearatio=d.Sarearatio,
            convexarearatio=d.Sconvexarearatio,
            majaxisratio=d.Smajaxisratio,
            minaxisratio=d.Sminaxisratio,
        ),
    )
    mc_thresholds = mkmct(d)
    return condition_thresholds, mc_thresholds
end

function mkmct(d)
    return (
        comp=(mxrot=d.mxrot, sz=d.sz, comp=d.comp, mm=d.mm, psi=d.psi),
        goodness=(
            corr=d.corr,
            large_floe_area=d.large_floe_area,
            small_floe_area=d.small_floe_area,
        ),
    )
end

function get_thresholds(; args...)
    v = values(args)
    if !isnothing(v.params)
        condition_thresholds, mc_thresholds = parse_params(v.params)
    else
        condition_thresholds, mc_thresholds = parse_params(; args...)
    end
    return condition_thresholds, mc_thresholds
end

"""
    dict2nt(d)

Convert a dictionary `d` to a NamedTuple.
"""
dict2nt(d) = NamedTuple((Symbol(key), value) for (key, value) in d)

parselistas(T, x) = [parse(T, i) for i in split(x)]
