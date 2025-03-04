# Labeler

The labeler converts a binary TIFF image where regions are marked in white into an integer image where contiguous regions are labeled with integers. 

## Run the code

You can run the local version of the code from this directory by calling
```bash
pipx run . label
```

You can run the code anywhere by calling:
```bash
pipx run --spec "git+https://github.com/wilhelmuslab/ice-floe-tracker-pipeline#egg=labeler&subdirectory=labeler" label
```
