if abspath(PROGRAM_FILE) == @__FILE__
    
    # Initialize the Conda environment
    using Pkg
    ENV["PYTHON"]=""
    Pkg.build("PyCall")

    # Add the dependencies to the Conda environment
    using Conda
    Conda.runconda(Conda.Cmd(["env", "update", "-n", "base", "--file", joinpath(@__DIR__, "..", "Python.yaml")]))
    
    # Rebuild PyCall
    Pkg.build("PyCall")

end