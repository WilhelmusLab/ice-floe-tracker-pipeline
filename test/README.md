# CLI Test scripts

Scripts to test local and dockerized version of the ice floe tracker CLI.

To run the tests using the local version of the Ice Floe Tracker CLI, first:
```bash
source ./test-IFTPipeline.jl-cli.sh
```

Then run the appropriate function with the dataset you would like to test. Preprocessing:
```bash
preprocess_original input_data/ne-greenland.20220913.terra.250m/
preprocess_buckley input_data/ne-greenland.20220913.terra.250m/
```

For tracking (and preprocessing), you need to pass all the source data directories you'd like to process:
```bash
# `track` uses dependency injection to select the preprocessing pipeline
PREPROCESS=preprocess_original track input_data/ne-greenland.2022091{3,4}.terra.250m/  

# `track_original` and `track_buckley` are wrappers around `track`
track_original input_data/ne-greenland.2022091{3,4}.terra.250m/
track_buckley input_data/ne-greenland.2022091{3,4}.terra.250m/
```

To run the tests using a dockerized version of the Ice Floe Tracker CLI, call:
```bash
IFT="docker run -v `pwd`:/app -w /app brownccv/icefloetracker-julia" <function name> ...
```
... where `brownccv/icefloetracker-julia` can be replaced with any local or remote tagged version of the ice floe tracker image.

For example:
```bash
IFT="docker run -v `pwd`:/app -w /app brownccv/icefloetracker-julia" track_buckley input_data/ne-greenland.2022091{3,4}.terra.250m/
```

