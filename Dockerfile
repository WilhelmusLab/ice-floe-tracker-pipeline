FROM julia:1.11-bookworm

# DEPENDENCIES
#===========================================
ENV TERM=xterm

# Julia Processor Targets for Precompile
# From https://github.com/JuliaCI/julia-buildkite/blob/main/utilities/build_envs.sh
#===========================================
RUN if ["$TARGETARCH" = "amd64"]; then \
    export JULIA_CPU_TARGET="generic;sandybridge,-xsaveopt,clone_all;haswell,-rdrnd,base(1);x86-64-v4,-rdrnd,base(1)" ; \
elif [ "$TARGETARCH" = "arm64" ]; then \
    export JULIA_CPU_TARGET="generic;cortex-a57;thunderx2t99;carmel,clone_all;apple-m1,base(3);neoverse-512tvb,base(3)" ; \
fi ;

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
