from jinja2 import Environment, FileSystemLoader # templating engine
import yaml # parser
import os

def parse_paramsyml(yamlfile):
    """
    Parse yaml file with parameters for cylc files.    
    """
    with open(yamlfile, "r") as f:
        dataimp = yaml.load(f, Loader=yaml.FullLoader)
    n = len(dataimp["startdate"])
    return [{k: dataimp[k][i] for k in dataimp} for i in range(n)]

def generate_cylc_files(envfile, template, template_dir="config/cylc_template"):
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
    data = parse_paramsyml(envfile)
    env = Environment(loader=FileSystemLoader(template_dir))
    template = env.get_template(template)
    for i, conf in enumerate(data, 1):
        folder = template_dir + "/param_set_" + str(i)
        os.mkdir(folder)
        fname = folder + "/flow.cylc"
        content = template.render(conf)
        with open(fname, "w") as fh:
            fh.write(content)