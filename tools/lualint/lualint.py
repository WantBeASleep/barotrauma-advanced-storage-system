from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parents[1]
SELENE = PROJECT_ROOT / "bin" / "selene.exe"
DEFAULT_TARGET = "Lua"


class RussianHelpFormatter(argparse.HelpFormatter):
    def add_usage(self, usage, actions, groups, prefix=None):
        super().add_usage(usage, actions, groups, prefix="Использование: ")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Статическая проверка Lua-кода проекта с помощью Selene.",
        add_help=False,
        formatter_class=RussianHelpFormatter,
    )
    positional = parser.add_argument_group("Позиционные аргументы")
    options = parser.add_argument_group("Параметры")
    options.add_argument(
        "-h", "--help", action="help", help="Показать справку и завершить работу."
    )
    positional.add_argument(
        "targets",
        nargs="*",
        default=[DEFAULT_TARGET],
        metavar="ПУТЬ",
        help="Lua-файлы или каталоги для проверки относительно корня проекта. По умолчанию: Lua/.",
    )
    options.add_argument(
        "--selene-arg",
        action="append",
        default=[],
        metavar="АРГУМЕНТ",
        help="Дополнительный аргумент Selene. Для нескольких аргументов повторите параметр.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    if not SELENE.is_file():
        print(f"Исполняемый файл Selene не найден: {SELENE}", file=sys.stderr)
        return 1

    command = [str(SELENE), *args.selene_arg, *args.targets]
    completed = subprocess.run(command, cwd=PROJECT_ROOT)
    return completed.returncode


if __name__ == "__main__":
    raise SystemExit(main())
