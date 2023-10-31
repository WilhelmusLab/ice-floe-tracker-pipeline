
from jinja2 import Environment, FileSystemLoader # templating engine
import csv, os, yaml # parser

input_csv_file = "./config/site_locations.csv"
output_yaml_file = "./config/site_data.yaml"

def convert_csv_to_yaml():
    """
    Convert the CSV matrix 'site_locations.csv' into a yaml file.    
    """
    data = {}
    with open(input_csv_file, 'r') as csv_file:
        csv_reader = csv.DictReader(csv_file)
        for row in csv_reader:
            for column, value in row.items():
                if column not in data:
                    data[column] = []
                data[column].append(value)

    # Write the data to a YAML file
    with open(output_yaml_file, 'w') as yaml_file:
        yaml.dump(data, yaml_file, default_flow_style=False)

    print(f"CSV file '{input_csv_file}' has been converted to YAML file '{output_yaml_file}'.")

def parse_paramsyml(yamlfile):
    """
    Parse yaml file with parameters for cylc files.    
    """
    with open(yamlfile, "r") as f:
        dataimp = yaml.load(f, Loader=yaml.FullLoader)
    n = len(dataimp["startdate"])
    return [{k: dataimp[k][i] for k in dataimp} for i in range(n)]

def generate_cylc_files(envfile, template, template_dir="./config"):
    """
    Generate cylc files from template.

    Parameters
    ----------
    envfile : str
        Path to yaml file with parameters for cylc files.
    template : str
        Name of template file.
    template_dir : str
        Path to directory with template file.
    """
    convert_csv_to_yaml()
    data = parse_paramsyml(envfile)
    env = Environment(loader=FileSystemLoader(template_dir))
    template = env.get_template(template)
    fname = os.path.join(template_dir, "flow.cylc")
    print(data)
    for i, conf in enumerate(data, 1):
        content = template.render(conf)
        with open(fname, "w") as fh:
            fh.write(content)

generate_cylc_files('./config/site_data.yaml', 'flow_template.j2', template_dir='./config')