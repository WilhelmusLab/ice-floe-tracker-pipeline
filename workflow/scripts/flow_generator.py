
from jinja2 import Environment, FileSystemLoader # templating engine
import pandas as pd, os

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
    """
    Generate cylc files from template.

    Parameters
    ----------
    csvfile : str
        Name of CSV file with parameters for cylc flow file. Each row is a unique set of parameters.
    template : str
        Name of template file to fill.
    template_dir : str
        Path to directory with template and csv files.
    crs : str
        Either "wgs84" (default) or "epsg3413"
    minfloearea : int
        Default = 350
    maxfloearea : int
        Default = 90,000
    """
    df = pd.read_csv(csvfile)
    df['startdate'] = pd.to_datetime(df['startdate']).dt.strftime('%Y-%m-%d')
    df['enddate'] = pd.to_datetime(df['enddate']).dt.strftime('%Y-%m-%d')
    df['bounding_box'] = None
    data = {c: get_parameters(df, c, crs) for c in df.columns}
    data['crs'] = crs
    data['minfloearea'] = minfloearea
    data['maxfloearea'] = maxfloearea
    data['centroid_x'] = data['center_x']
    data['centroid_y'] = data['center_y']
    template_dir = "./config"
    template = "flow_template.j2"
    env = Environment(loader=FileSystemLoader(template_dir))
    template = env.get_template(template)
    fname = os.path.join(template_dir, "testflow.cylc")
    content = template.render(data)
    with open(fname, "w") as fh:
        fh.write(content)

generate_cylc_file('./config/site_locations.csv', 'flow_template.j2', template_dir='./config', crs="wgs84")