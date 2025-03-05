FROM --platform=$BUILDPLATFORM julia:1.11-bookworm
ARG TARGETARCH
ARG JULIA_CPU_TARGET="generic"
ENV JULIA_CPU_TARGET=${JULIA_CPU_TARGET}

# Dependencies
#===========================================
ENV TERM=xterm

# Python environment build
#===========================================
ENV CONDA_JL_HOME=/opt/conda
ENV JULIA_DEPOT_PATH=/opt/julia
COPY ./PythonSetupForIFTPipeline.jl /opt/PythonSetupForIFTPipeline.jl
RUN julia --project="/opt/PythonSetupForIFTPipeline.jl" "/opt/PythonSetupForIFTPipeline.jl/setup.jl"

# IFT Pipeline package build
#===========================================
COPY ./IFTPipeline.jl /opt/IFTPipeline.jl
RUN julia --project="/opt/IFTPipeline.jl" -e "using Pkg; Pkg.instantiate(); Pkg.precompile();"

# CLI setup
#===========================================
SHELL ["/bin/bash", "-c"]
ENTRYPOINT ["julia", "--project=/opt/IFTPipeline.jl", "/opt/IFTPipeline.jl/src/cli.jl" ]
