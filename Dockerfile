FROM --platform=$BUILDPLATFORM julia:1.11-bookworm
ARG TARGETARCH
ARG JULIA_CPU_TARGET="generic"
ENV JULIA_CPU_TARGET=${JULIA_CPU_TARGET}

# Dependencies
#===========================================
ENV TERM=xterm

# Miniconda install
#===========================================
# Shell version – miniforge
ENV CONDA_PREFIX=/opt/conda
WORKDIR ${CONDA_PREFIX}
RUN apt-get update && apt-get install -y wget
RUN wget -O miniforge.sh "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
RUN bash miniforge.sh -b -u -p ${CONDA_PREFIX}

# Python environment build
#===========================================
ENV CONDA_JL_CONDA_EXE=${CONDA_PREFIX}/bin/conda
ENV CONDA_JL_HOME=${CONDA_PREFIX}
COPY ./PythonSetupForIFTPipeline.jl /opt/PythonSetupForIFTPipeline.jl
RUN julia --project="/opt/PythonSetupForIFTPipeline.jl" "/opt/PythonSetupForIFTPipeline.jl/setup.jl"

RUN env > /env.txt


# IFT Pipeline package build
#===========================================
# COPY ./IFTPipeline.jl /opt/IFTPipeline.jl
# RUN julia --project="/opt/IFTPipeline.jl" -e "using Pkg; Pkg.instantiate(); Pkg.precompile();"

# Test the package
# RUN julia --project="/opt/IFTPipeline.jl" -e "using Pkg; Pkg.test();"

# CLI setup
#===========================================
SHELL ["/bin/bash", "-c"]
# ENTRYPOINT ["julia", "--project=/opt/IFTPipeline.jl", "/opt/IFTPipeline.jl/src/cli.jl" ]
