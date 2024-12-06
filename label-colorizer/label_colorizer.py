#!/usr/bin/env python3.11
"""Utility to assign random colors to values in a grayscale integer array saved as a GeoTIFF."""

import typer
import pathlib
import rasterio
import numpy as np
from rasterio.enums import ColorInterp
import colorsys
import tqdm

app = typer.Typer()


@app.command()
def main(
    input_path: pathlib.Path,
    output_path: pathlib.Path,
    mask_value: int = 0,
    seed: int = 42,
    randomize: bool = True,
):
    with rasterio.open(input_path) as in_dataset:
        assert in_dataset.count == 1, "There should be only one band in the dataset"
        band1 = in_dataset.read(1)

        max_value = int(band1.max())
        all_values = range(1, max_value + 1)

        rng = np.random.default_rng(seed)
        if randomize:
            hsv_tuples = {i: (rng.uniform(), 1, 1) for i in all_values}
        else:
            hsv_tuples = {i: (i * 1.0 / max_value, 1, 1) for i in all_values}
        rgba_values = {i: (*colorsys.hsv_to_rgb(*hsv_tuples[i]), 1) for i in all_values}
        rgba_values[mask_value] = (0, 0, 0, 0)

        red = np.zeros(band1.shape)
        green = np.zeros(band1.shape)
        blue = np.zeros(band1.shape)
        alpha = np.zeros(band1.shape)

        for (x, y), value in tqdm.tqdm(np.ndenumerate(band1), total=np.prod(band1.shape)):
            rgba = rgba_values[value]
            red[x, y] = int(255 * rgba[0])
            green[x, y] = int(255 * rgba[1])
            blue[x, y] = int(255 * rgba[2])
            alpha[x, y] = int(255 * rgba[3])

        new_profile = in_dataset.profile
        new_profile.update(
            nodata=0,
            dtype="uint8",
            count=4,
            colorinterp=[
                ColorInterp.red,
                ColorInterp.green,
                ColorInterp.blue,
                ColorInterp.alpha,
            ],
        )

        with rasterio.open(output_path, mode="w", **new_profile) as out_dataset:
            out_dataset.write(red, 1)
            out_dataset.write(green, 2)
            out_dataset.write(blue, 3)
            out_dataset.write(alpha, 4)


if __name__ == "__main__":
    app()
