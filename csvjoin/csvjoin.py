#!/usr/bin/env python3.11
"""Utility to join two csv files."""

from enum import Enum
from functools import partial
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
    left: Annotated[pathlib.Path, typer.Argument(help="path to left csv file")],
    right: Annotated[pathlib.Path, typer.Argument(help="path to right csv file")],
    on: Annotated[str, typer.Argument(help="column on which to join")],
    output: Annotated[pathlib.Path, typer.Argument(help="path to output csv file")],
    how: Annotated[HOW, typer.Option(help="type of join")] = HOW.left,
    on_is_utc: Annotated[
        bool, typer.Option(help="`on` is a datetime which should be treated as UTC")
    ] = False,
):
    """Join two csv files."""
    read_kwargs = dict(index_col=on)
    if on_is_utc:
        read_kwargs["converters"] = {on: partial(pandas.to_datetime, utc=True)}
    left_df = pandas.read_csv(left, **read_kwargs)
    right_df = pandas.read_csv(right, **read_kwargs)
    output_df = left_df.join(right_df, on=on, how=how.value)
    output_df.to_csv(output, date_format="%Y-%m-%dT%H:%M:%SZ")


if __name__ == "__main__":
    app()
