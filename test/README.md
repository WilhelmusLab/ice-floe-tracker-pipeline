# CLI Test scripts

Scripts to test local and dockerized version of the ice floe tracker CLI.

To run the tests using the local version of the Ice Floe Tracker CLI, call:
```bash
./test-IFTPipeline.jl-cli.sh 
```

To run the tests using a dockerized version of the Ice Floe Tracker CLI, call:
```bash
IFT="docker run -v `pwd`:/app -w /app brownccv/icefloetracker-julia" ./test-IFTPipeline.jl-cli.sh 
```

... where `brownccv/icefloetracker-julia` can be replaced with any local or remote tagged version of the ice floe tracker image.
