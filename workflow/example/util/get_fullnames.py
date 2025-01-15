# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "pandas",
#   "typer",
# ]
# ///

import pathlib
from typing import Optional, Annotated

import pandas
import typer


def main(
    datafile: Annotated[pathlib.Path, typer.Argument(help="path to csv file")],
    column: Annotated[str, typer.Argument(help="name of column to return")],
    start: Annotated[
        Optional[int], typer.Argument(help="initial row index to return")
    ] = None,
    stop: Annotated[
        Optional[int], typer.Argument(help="final row index to return")
    ] = None,
    step: Annotated[
        Optional[int], typer.Argument(help="size of steps between returned row indices")
    ] = None,
):
    """Print values from the `column` column in a CSV file, from row `start` to `stop` in steps of `step`."""
    f = pandas.read_csv(datafile)
    print("\n".join(f[column].values[start:stop:step]))


if __name__ == "__main__":
    typer.run(main)
