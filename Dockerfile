FROM julia:1.11-bookworm

# DEPENDENCIES
#===========================================
ENV TERM=xterm

# Python environment build
#===========================================
COPY ./PythonSetupForIFTPipeline.jl /opt/PythonSetupForIFTPipeline.jl
RUN julia --project="/opt/PythonSetupForIFTPipeline.jl" "/opt/PythonSetupForIFTPipeline.jl/setup.jl"

# IFT Pipeline package build
#===========================================
COPY ./IFTPipeline.jl /opt/IFTPipeline.jl
RUN julia --project="/opt/IFTPipeline.jl" -e 'using Pkg; Pkg.instantiate(); Pkg.precompile();'

# Test the package
RUN julia --project="/opt/IFTPipeline.jl" -e 'using Pkg; Pkg.test();'

# CLI setup
#===========================================
SHELL ["/bin/bash", "-c"]
ENTRYPOINT ["julia", "--project=/opt/IFTPipeline.jl", "/opt/IFTPipeline.jl/src/cli.jl" ]
