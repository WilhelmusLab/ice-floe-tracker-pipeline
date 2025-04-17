# Instantiate all the dependencies
using Pkg

# Force PyCall to use the Conda version on Linux.
ENV["PYTHON"] = ""

# Build PyCall with the new conda environment
Pkg.build("PyCall")
