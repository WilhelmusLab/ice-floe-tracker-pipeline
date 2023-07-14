@testset "python deps" begin
    depslatlon = ["pyproj", "rasterio"] # numpy already included in skimage
    depssoit = ["requests", "skyfield"]
    deps = vcat(depslatlon, depssoit)
    pkgs = Conda._installed_packages()
    @test "pyproj" in pkgs
    @test "rasterio" in pkgs
    @test "requests" in pkgs
    @test "skyfield" in pkgs
    # @test all([dep in pkgs for dep in deps])
end
