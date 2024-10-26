if abspath(PROGRAM_FILE) == @__FILE__
    
    # Instantiate all the dependencies
    using Pkg
    Pkg.instantiate()
    
    # Initialize the Conda environment
    ENV["PYTHON"]=""
    Pkg.build("PyCall")

    # Add the dependencies to the Conda environment
    using Conda
    Conda.runconda(Conda.Cmd(["env", "update", "-n", "base", "--file", joinpath(@__DIR__, "Python.yaml")]))
    
    # Rebuild PyCall with the new conda environment
    Pkg.build("PyCall")

end