# Instantiate all the dependencies
using Pkg
Pkg.instantiate()

# Initialize the Conda environment
using Conda

# Add the dependencies to the Conda environment
Conda.runconda(
    Conda.Cmd([
        "env", "update", "-n", "base", "--file", joinpath(@__DIR__, "environment.yaml")
    ]),
)

# Force PyCall to use the Conda version on Linux.
ENV["PYTHON"] = ""

# Build PyCall with the new conda environment
Pkg.build("PyCall")
