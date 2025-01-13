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


def main(datafile: pathlib.Path, index_column: str, row_index: str):
    """
    Get the cylc parameters for a preprocessing run from a CSV file.
    """
    df = pandas.read_csv(datafile, index_col=index_column)
    print(_template(df, row_index))


def _template(df, row_index):
    """
    Examples:

        >>> import io, pandas
        >>> csv = '''id,location,left_x,right_x,lower_y,top_y,center_lat,center_lon,startdate,enddate
        ... beaufort-sea-0,beaufort-sea,-2383879,-883879,-750000,750000,75.0,-135.0,2020-09-05,2020-09-08
        ... hudson-bay-0,hudson-bay,-2795941,-1295941,-3368686,-1868686,60.0,-83.0,2020-09-06,2020-09-09
        ... '''
        >>> df = pandas.read_csv(io.StringIO(csv), index_col="id")

        >>> print(_template(df, row_index="beaufort-sea-0"))
        --set START="2020-09-06" --set END="2020-09-09" --set CENTROID_LAT="60.0" --set CENTROID_LON="-83.0" --set BBOX="-2795941,-3368686,-1295941,-1868686" --set LOCATION="hudson-bay"

        >>> print(_template(df, row_index="hudson-bay-0"))
        --set START="2020-09-06" --set END="2020-09-09" --set BBOX="-2795941,-3368686,-1295941,-1868686" --set LOCATION="hudson-bay"
        
    """
    r = df.loc[row_index]
    s = (
        f'--set START="{r.startdate}" '
        f'--set END="{r.enddate}" '
        f'--set CENTROID_LAT="{r.center_lat}" '  
        f'--set CENTROID_LON="{r.center_lon}" '  
        f'--set BBOX="{r.left_x},{r.lower_y},{r.right_x},{r.top_y}" '
        f'--set LOCATION="{r.location}"'
    )
    return s


if __name__ == "__main__":
    typer.run(main)
