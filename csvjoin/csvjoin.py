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
    left_on: Annotated[str, typer.Argument(help="column on which to join")],
    right: Annotated[pathlib.Path, typer.Argument(help="path to right csv file")],
    right_on: Annotated[str, typer.Argument(help="column on which to join")],
    output: Annotated[pathlib.Path, typer.Argument(help="path to output csv file")],
    how: Annotated[HOW, typer.Option(help="type of join")] = HOW.left,
    on_is_utc: Annotated[
        bool, typer.Option(help="`on` is a datetime which should be treated as UTC")
    ] = False,
):
    """Join two csv files."""
    left_df = read_df(path=left, index_col=left_on, on_is_utc=on_is_utc)
    right_df = read_df(path=right, index_col=right_on, on_is_utc=on_is_utc)
    output_df = left_df.join(right_df, how=how.value)
    output_df.to_csv(output, date_format="%Y-%m-%dT%H:%M:%SZ")

def read_df(path, index_col, on_is_utc=False):
    read_kwargs = dict(index_col=index_col)
    if on_is_utc:
        read_kwargs["converters"] = {index_col: partial(pandas.to_datetime, utc=True)}
    df = pandas.read_csv(path, **read_kwargs)
    return df

if __name__ == "__main__":
    app()
