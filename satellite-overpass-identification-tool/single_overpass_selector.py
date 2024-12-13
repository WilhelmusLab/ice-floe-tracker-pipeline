import argparse
import pathlib
import pandas

def main():
    parser = argparse.ArgumentParser(
        description="Aqua and Terra Satellite Overpass time tool"
    )
    parser.add_argument(
        "path",
        type=pathlib.Path,
        help="Path to the CSV file",
    )
    parser.add_argument(
        "--date",
        type=pandas.to_datetime,
        help="Date in format YYYY-MM-DD",
    )
    parser.add_argument(
        "--satellite",
        type=str,
        help="satellite name in lowercase, e.g. 'aqua', 'terra'",
    )
    parser.add_argument(
        "--field",
        type=str,
        default="overpass time",
        help="name of the field to report",
    )
    args = parser.parse_args()

    get_single_field(**vars(args))

def get_single_field(path, date, satellite, field):
    df = pandas.read_csv(path, index_col=["date", "satellite"], parse_dates=["date"])
    print(df.loc[date,satellite][field])


if __name__ == "__main__":
    main()
