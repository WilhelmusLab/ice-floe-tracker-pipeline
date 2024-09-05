# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "pandas",
#   "typer",
# ]
# ///

import pathlib
from typing import Optional

import pandas
import typer


def main(
    datafile: pathlib.Path,
    index_col: str,
    start: Optional[int] = None,
    stop: Optional[int] = None,
    step: Optional[int] = None,
):
    f = pandas.read_csv(datafile)
    print("\n".join(f[index_col].values[start:stop:step]))


if __name__ == "__main__":
    typer.run(main)
