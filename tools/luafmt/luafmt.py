from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parents[1]
STYLUA = PROJECT_ROOT / "bin" / "stylua.exe"
LUA_DIR = "Lua"


class RussianHelpFormatter(argparse.HelpFormatter):
    def add_usage(self, usage, actions, groups, prefix=None):
        super().add_usage(usage, actions, groups, prefix="Использование: ")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Форматирование Lua-кода проекта в Lua/ с помощью StyLua.",
        add_help=False,
        formatter_class=RussianHelpFormatter,
    )
    options = parser.add_argument_group("Параметры")
    options.add_argument(
        "-h", "--help", action="help", help="Показать справку и завершить работу."
    )
    options.add_argument(
        "--check",
        action="store_true",
        help="Проверить форматирование и показать различия без изменения файлов.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    if not STYLUA.is_file():
        print(f"Исполняемый файл StyLua не найден: {STYLUA}", file=sys.stderr)
        return 1

    command = [str(STYLUA), "--verify"]
    if args.check:
        command.append("--check")
    command.append(LUA_DIR)

    completed = subprocess.run(command, cwd=PROJECT_ROOT)
    return completed.returncode


if __name__ == "__main__":
    raise SystemExit(main())
