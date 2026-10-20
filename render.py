from pathlib import Path

from jinja2 import Environment, FileSystemLoader, StrictUndefined
from nornir import InitNornir
from nornir.core.task import Result, Task
from nornir_utils.plugins.functions import print_result

env = Environment(
    loader=FileSystemLoader("templates"),
    trim_blocks=True,
    lstrip_blocks=True,
    keep_trailing_newline=True,
    undefined=StrictUndefined,
)


def render(task: Task) -> Result:
    data = dict(task.host.items())  # host data + inherited group data (role)
    text = env.get_template("frr.conf.j2").render(name=task.host.name, **data)
    Path(f"configs/{task.host.name}.conf").write_text(text)
    return Result(host=task.host, result=f"configs/{task.host.name}.conf written")


if __name__ == "__main__":
    nr = InitNornir(config_file="nornir_config.yml")
    print_result(nr.run(task=render))
