# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "pandas",
#   "typer",
# ]
# ///

import pathlib

import pandas
import typer


def main(datafile: pathlib.Path, index_col: str, index_val: str):
    df = pandas.read_csv(datafile, index_col=index_col)
    r = df.loc[index_val]
    print(
        f"""--icp {r.startdate} --fcp {r.enddate} --set=BBOX="{r.left_x},{r.lower_y},{r.right_x},{r.top_y}" --set=LOCATION="'{r.location}'" """
    )


if __name__ == "__main__":
    typer.run(main)
