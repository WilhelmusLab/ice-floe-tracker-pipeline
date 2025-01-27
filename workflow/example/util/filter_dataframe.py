# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "pandas",
#   "typer",
# ]
# ///

import pathlib
from typing import Annotated

import pandas
import typer


def main(
    input: Annotated[pathlib.Path, typer.Argument(help="path to input csv file")],
    query: Annotated[str, typer.Argument(help="input to pandas.DataFrame.query, e.g. `350 <= area < 90000`")],
    output: Annotated[pathlib.Path, typer.Argument(help="path to output csv file")],
):
    """Filter a dataframe from the `input` CSV file using the query `query` and write to `output`."""
    df = pandas.read_csv(input)
    df_new = df.query(query)
    df_new.to_csv(output)
    
if __name__ == "__main__":
    typer.run(main)
