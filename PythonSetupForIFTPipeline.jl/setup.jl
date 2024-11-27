using Pkg
using Conda

# Instantiate all the dependencies
Pkg.instantiate()

# Initialize the Conda environment
ENV["PYTHON"]=""
Pkg.build("PyCall")

# Add the dependencies to the Conda environment
Conda.runconda(Conda.Cmd(["env", "update", "-n", "base", "--file", joinpath(@__DIR__, "environment.yaml")]))

# Rebuild PyCall with the new conda environment
Pkg.build("PyCall")
