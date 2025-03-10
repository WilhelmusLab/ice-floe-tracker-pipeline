#!/usr/bin/env python3.11
"""Utility to join two csv files."""

from enum import Enum
import pathlib
from typing import Annotated

import pandas
import typer

app = typer.Typer()

class HOW(str, Enum):
    left = "left"
    right = "right"
    outer = "outer"
    inner = "inner"
    cross = "cross"

@app.command()
def main(
    left: Annotated[
        pathlib.Path, typer.Argument(help="path to left csv file")
    ],
    right: Annotated[
        pathlib.Path, typer.Argument(help="path to right csv file")
    ],
    on: Annotated[
        str, typer.Argument(help="column on which to join")
    ],
    output: Annotated[
        pathlib.Path, typer.Argument(help="path to output csv file")
    ],
    how: Annotated[
        HOW,
        typer.Option(help="type of join")
    ]=HOW.left,
):
    """Join two csv files."""
    left_df = pandas.read_csv(left, index_col=on)
    right_df = pandas.read_csv(right, index_col=on)
    output_df = left_df.join(right_df, on=on, how=how.value)
    output_df.to_csv(output)

if __name__ == "__main__":
    app()
