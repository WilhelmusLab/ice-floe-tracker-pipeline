#!/usr/bin/env python3.11
"""Utility to label segmented binary images."""

import pathlib
from typing import Annotated

import skimage
import typer
import numpy as np
import imageio
import tifffile

app = typer.Typer()


@app.command()
def main(
    input: Annotated[
        pathlib.Path, typer.Argument(help="path to segmented binary image file")
    ],
    output: Annotated[
        pathlib.Path, typer.Argument(help="path to write labeled integer image file")
    ],
):
    """Give integer labels to disconnected regions in a binary image."""
    segmented = imageio.imread(input)

    with tifffile.TiffFile(input) as tif:
        photometric_interpretation = tif.pages[0].tags["PhotometricInterpretation"]
    if photometric_interpretation == tifffile.PHOTOMETRIC.MINISWHITE:
        segmented = np.logical_not(segmented)

    labeled = skimage.measure.label(segmented)
    minimum_scalar_type = smallest_dtype(labeled)
    imageio.imsave(output, labeled.astype(minimum_scalar_type))


def smallest_dtype(array):
    arr_min = array.min()
    arr_max = array.max()
    if np.issubdtype(array.dtype, np.integer):
        # based on https://stackoverflow.com/a/73688443/24937841
        for dtype in [
            np.uint8,
            np.int8,
            np.uint16,
            np.int16,
            np.uint32,
            np.int32,
            np.uint64,
            np.int64,
        ]:
            if (arr_min >= np.iinfo(dtype).min) and (arr_max <= np.iinfo(dtype).max):
                return dtype

    else:
        raise ValueError()


if __name__ == "__main__":
    app()
