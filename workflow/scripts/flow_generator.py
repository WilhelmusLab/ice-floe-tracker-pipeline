
from jinja2 import Environment, FileSystemLoader # templating engine
import pandas as pd, os, argparse

def get_parameters(data, name, crs=None):
    if name != "bounding_box":
        return ",".join(list(data[name].values.astype(str)))
    elif name == "bounding_box" and crs is not None:
        return get_bounding_box_list(data, crs)
    
def generate_bounding_box(row, crs):
    if crs == "epsg3413":
        columns = ["left_x", "top_y", "right_x", "lower_y"]
    elif crs == "wgs84":
        columns = ["top_left_lat", "top_left_lon", "lower_right_lat", "lower_right_lon"]
    return "@".join(list(row[columns].values.astype(str)))

def get_bounding_box_list(data, crs="wgs84"):
    f = lambda x: generate_bounding_box(x, crs) 
    return ",".join(data.apply(f, axis=1).values)

def generate_cylc_file(csvfile="site_locations.csv", template="flow_template.j2", template_dir="./config", crs="wgs84", minfloearea=350, maxfloearea=90_000):
    
    df = pd.read_csv(csvfile)
    date_columns = ['startdate', 'enddate']
    df[date_columns] = df[date_columns].apply(lambda x: pd.to_datetime(x).dt.strftime('%Y-%m-%d'))
    df['bounding_box'] = None
    data = {c: get_parameters(df, c, crs) for c in df.columns}
    data['rows'] = len(df.index) - 1
    data['crs'] = crs
    data['minfloearea'] = minfloearea
    data['maxfloearea'] = maxfloearea
    data['centroid_x'] = data['center_lat']
    data['centroid_y'] = data['center_lon']
    env = Environment(loader=FileSystemLoader(template_dir))
    template = env.get_template(template)
    fname = os.path.join(template_dir, "flow.cylc")
    content = template.render(data)
    with open(fname, "w") as fh:
        fh.write(content)


def main():
    example = """Example:

    The following would create a flow file for however many rows of data the user input into the site_location.csv file for use on a high-performance cluster (like Brown's Oscar) with polar stereographic coordinates, and intending to process floes between 350 and 75000 pixels in area.

    python ./workflow/scripts/flow_generator.py --csvfile "./config/site_locations.csv" --template "flow_template_hpc.j2" --template_dir "./config/cylc_hpc" --crs "epsg3413" --minfloearea 350 --maxfloearea 75000

    In this second example, a flow file will be generated for use on a local OS using lat/lon inputs and considering floes from 500 - 90000 pixels in area.

    python workflow/scripts/flow_generator.py --csvfile "./config/site_locations.csv" --template "flow_template_local.j2" --template_dir "./config/cylc_local" --crs "wgs84" --minfloearea 500 """

    parser = argparse.ArgumentParser(description="Generate a Cylc flow file from a CSV matrix of unique location-parameter sets", epilog=example, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "--csvfile",
        type=str,
        help="path to `site_locations.csv` file with each param set as unique row",
    )
    parser.add_argument(
        "--template",
        type=str,
        choices=['flow_template_hpc.j2','flow_template_local.j2'],
        help="`flow_template.j2` file that needs to be populated",
    )
    parser.add_argument(
        "--template_dir",
        type=str,
        choices=['./config/cylc_hpc','./config/cylc_local'],
        help="Location path to the directory containing j2 template file",
    )
    parser.add_argument(
        "--crs",
        type=str,
        choices=['wgs84','epsg3413'],
        help="Either 'wgs84' or 'epsg3413'",
    )
    parser.add_argument(
        "--minfloearea",
        type=int,
        default=350,
        help="minimum pixel size of ice floes to process",
    )
    parser.add_argument(
        "--maxfloearea",
        type=int,
        default=90000,
        help="maximum pixel size of ice floes to process"
    )

    args = parser.parse_args()
    
    generate_cylc_file(**vars(args))

if __name__ == "__main__":

    main()
