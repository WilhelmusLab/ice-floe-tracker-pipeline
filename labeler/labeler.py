# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "scikit-image",
#   "typer",
#   "numpy",
#   "imageio",
# ]
# ///

import pathlib
from typing import Annotated
import logging

import skimage
import typer
import numpy as np
import imageio

_logger = logging.getLogger(__name__)

app = typer.Typer()


@app.callback()
def main(
    quiet: Annotated[
        bool, typer.Option(help="Make the program less talkative.")
    ] = False,
    verbose: Annotated[
        bool, typer.Option(help="Make the program more talkative.")
    ] = False,
    debug: Annotated[
        bool, typer.Option(help="Make the program much more talkative.")
    ] = False,
):
    if debug:
        level = logging.DEBUG
    elif verbose:
        level = logging.INFO
    elif quiet:
        level = logging.ERROR
    else:
        level = logging.WARNING

    logging.basicConfig(level=level)
    return


@app.command()
def label(
    input: Annotated[
        pathlib.Path, typer.Argument(help="path to segmented binary image file")
    ],
    output: Annotated[
        pathlib.Path, typer.Argument(help="path to write labeled integer image file")
    ],
):
    """"""
    segmented = np.logical_not(imageio.imread(input))
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

    label("labeler/segmented-0.tiff", "labeler/labeled-0.tiff")
    # app()
