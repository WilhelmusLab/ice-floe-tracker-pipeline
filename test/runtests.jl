using IFTPipeline
using IFTPipeline: load_imgs, sharpen, sharpen_gray, loadimg, h5open
using .IceFloeTracker: DataFrames, save, Gray, create_cloudmask, deserialize, serialize, float64, load, imrotate, loadimg, RGB, DataFrame, nrow, rename!, Dates, Not, select!
using ArgParse: @add_arg_table!, ArgParseSettings, add_arg_group!, parse_args
using DelimitedFiles
using PyCall: @pyinclude, @py_str
using Pkg
using Random
using Serialization
using Test
using Conda
include(joinpath(@__DIR__, "config.jl"))

function test_similarity(imgA::BitMatrix, imgB::BitMatrix, error_rate=0.005)
    error = sum(imgA .!== imgB) / prod(size(imgA))
    res = error_rate > error
    if res
        @info "Test passed with $error mismatch with threshold $error_rate"
    else
        @warn "Test failed with $error mismatch with threshold $error_rate"
    end
    return res
end

## Get all test files filenames "test-*" in test folder and their corresponding names/label
alltests = [f for f in readdir() if startswith(f, "test-")]
testnames = [n[6:(end-3)] for n in alltests]

## Put the filenames to test below

to_test = alltests # uncomment this line to run all tests or add individual files below
[
    "test-pydeps.jl"
]

# Run the tests
@testset verbose = true "IceFloeTracker.jl" begin
    for test in to_test
        include(test)
    end
end