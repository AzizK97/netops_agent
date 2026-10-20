
import argparse
import subprocess

from nornir import InitNornir
from nornir.core.task import Result, Task
from nornir_utils.plugins.functions import print_result

LAB_PREFIX = "clab-data_center"
RELOAD = "/usr/lib/frr/frr-reload.py"


def push(task: Task, apply: bool) -> Result:
    container = f"{LAB_PREFIX}-{task.host.name}"
    mode = "--reload" if apply else "--test"
    proc = subprocess.run(
        ["docker", "exec", container, "python3", RELOAD, mode, "/etc/frr/frr.conf"],
        capture_output=True,
        text=True,
    )
    failed = proc.returncode != 0
    return Result(
        host=task.host,
        result=proc.stdout + (proc.stderr if failed else ""),
        changed=apply,
        failed=failed,
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Diff or apply rendered FRR configs")
    parser.add_argument("--apply", action="store_true", help="apply (default: diff only)")
    parser.add_argument("--node", help="limit to one router")
    args = parser.parse_args()

    nr = InitNornir(config_file="nornir_config.yml")
    if args.node:
        nr = nr.filter(name=args.node)
    print_result(nr.run(task=push, apply=args.apply))
