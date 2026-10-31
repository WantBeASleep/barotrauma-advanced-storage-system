"""Объединение объявлений LuaCs в упрощённый std без игровых сигнатур."""

from __future__ import annotations

import argparse
from pathlib import Path
import re
import sys


PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
DEFAULT_ANNOTATIONS = PROJECT_ROOT.parent / "Barotrauma-Lua-Annotations"
DEFAULT_OUTPUT = PROJECT_ROOT / "selene_std_luacs.yml"

# Имена Lua 5.2 защищены от замены на any; сигнатуры берутся только из Selene.
# https://www.lua.org/manual/5.2/manual.html#6
# Учтены также совместимые имена из lua51, от которого наследуется std Selene.
# https://github.com/Kampfkarren/selene/tree/0.31.0/selene-lib/default_std
STANDARD_GLOBALS = set("""
_G _VERSION _ENV arg assert collectgarbage dofile error getmetatable ipairs load
loadfile loadstring next pairs pcall print rawequal rawget rawlen rawset require select
setmetatable tonumber tostring type xpcall module unpack newproxy getfenv setfenv
""".split())
STANDARD_LIBRARIES = {
    "bit32": "arshift band bnot bor btest bxor extract lrotate lshift replace rrotate rshift",
    "coroutine": "create resume running status wrap yield",
    "debug": "debug getfenv gethook getinfo getlocal getmetatable getregistry getupvalue "
             "getuservalue setfenv sethook setlocal setmetatable setupvalue setuservalue "
             "traceback upvalueid upvaluejoin",
    "io": "close flush input lines open output popen read stderr stdin stdout tmpfile type write",
    "math": "abs acos asin atan atan2 ceil cos cosh deg exp floor fmod frexp huge ldexp "
            "log log10 max min modf pi pow rad random randomseed sin sinh sqrt tan tanh",
    "os": "clock date difftime execute exit getenv remove rename setlocale time tmpname",
    "package": "config cpath loaded loaders loadlib path preload searchers searchpath seeall",
    "string": "byte char dump find format gmatch gsub len lower match rep reverse sub upper",
    "table": "concat getn insert maxn pack remove sort unpack",
}
STANDARD_FIELDS = {
    f"{library}.{field}"
    for library, fields in STANDARD_LIBRARIES.items()
    for field in fields.split()
}

TOKEN = re.compile(
    r"(?P<space>\s+)|(?P<long_comment>--\[(?P<level>=*)\[.*?\](?P=level)\])"
    r"|(?P<comment>--[^\n]*)|(?P<string>'(?:\\.|[^'\\])*'|\"(?:\\.|[^\"\\])*\")"
    r"|(?P<number>-?\d+(?:\.\d+)?)|(?P<name>[A-Za-z_][A-Za-z_0-9]*)"
    r"|(?P<symbol>\.\.\.|[.=:,;(){}])|(?P<unsupported>.)",
    re.DOTALL,
)


class AnnotationError(ValueError):
    """Аннотации имеют неподдерживаемую структуру."""


class Declarations:
    """Разбор декларативного подмножества Lua, используемого аннотациями.

    Поддерживаются присваивания, таблицы, пустые функции, local, do и return.
    Игровой Lua-код не исполняется. Новый синтаксис требует явной адаптации.
    """

    def __init__(self, path: Path):
        self.path = path
        self.source = path.read_text(encoding="utf-8-sig")
        self.tokens = []
        for match in TOKEN.finditer(self.source):
            if match.lastgroup == "comment" and re.match(r"--\[=*\[", match.group()):
                line = self.source.count("\n", 0, match.start()) + 1
                raise AnnotationError(f"{path}:{line}: незакрытый многострочный комментарий")
            if match.lastgroup not in {"space", "comment", "long_comment"}:
                self.tokens.append(match)
        self.index = 0
        self.locals: list[set[str]] = [set()]
        self.names: set[str] = set()

    def peek(self) -> str:
        return self.tokens[self.index].group() if self.index < len(self.tokens) else ""

    def fail(self, message: str):
        offset = self.tokens[self.index].start() if self.index < len(self.tokens) else len(self.source)
        line = self.source.count("\n", 0, offset) + 1
        raise AnnotationError(f"{self.path}:{line}: {message}")

    def take(self, expected: str):
        if self.peek() != expected:
            self.fail(f"ожидалось {expected!r}, получено {self.peek()!r}")
        self.index += 1

    def name(self) -> str:
        if self.index >= len(self.tokens) or self.tokens[self.index].lastgroup != "name":
            self.fail("ожидалось имя")
        name = self.peek()
        self.index += 1
        return name

    def path_name(self) -> str:
        parts = [self.name()]
        while self.peek() in {".", ":"}:
            self.index += 1
            parts.append(self.name())
        return ".".join(parts)

    def function_body(self):
        self.take("(")
        if self.peek() != ")":
            while True:
                if self.peek() == "...":
                    self.take("...")
                    break
                self.name()
                if self.peek() != ",":
                    break
                self.take(",")
        self.take(")")
        self.take("end")

    def value(self):
        if self.peek() == "function":
            self.take("function")
            self.function_body()
        elif self.peek() == "{":
            self.take("{")
            while self.peek() != "}":
                self.name()
                self.take("=")
                self.value()
                if self.peek() not in {",", ";"}:
                    break
                self.index += 1
            self.take("}")
        elif self.index < len(self.tokens) and self.tokens[self.index].lastgroup in {"string", "number"}:
            self.index += 1
        else:
            self.path_name()

    def record(self, name: str):
        root = name.split(".")[0]
        if any(root in scope for scope in self.locals):
            return
        if root in STANDARD_GLOBALS:
            return
        if root in STANDARD_LIBRARIES:
            # Не переопределяем ни таблицу, ни штатный член, ни его потомков.
            if "." in name and ".".join(name.split(".")[:2]) not in STANDARD_FIELDS:
                self.names.add(name)
        elif "." not in name:
            # CS.Type = {} объявляет поле CS, а не новую глобальную Type.
            self.names.add(name)

    def block(self, nested=False):
        while self.peek() and self.peek() != "end":
            if self.peek() == "do":
                self.take("do")
                self.locals.append(set())
                self.block(nested=True)
                self.locals.pop()
            elif self.peek() == "return":
                self.take("return")
                self.value()
            elif self.peek() == ";":
                self.take(";")
            else:
                local = self.peek() == "local"
                if local:
                    self.take("local")
                function = self.peek() == "function"
                if function:
                    self.take("function")
                name = self.name() if local else self.path_name()
                if function:
                    self.function_body()
                else:
                    self.take("=")
                    self.value()
                if local:
                    self.locals[-1].add(name)
                else:
                    self.record(name)
        if nested:
            self.take("end")
        elif self.peek():
            self.fail("лишний end")

    def parse(self) -> set[str]:
        self.block()
        return self.names


def build_std(annotations_root: Path) -> tuple[str, int]:
    names: set[str] = set()
    for side in ("Client", "Server"):
        directory = annotations_root / "Library" / side
        if not directory.is_dir():
            raise AnnotationError(f"Каталог аннотаций не найден: {directory}")
        paths = sorted(directory.rglob("*.lua"))
        if not paths:
            raise AnnotationError(f"Нет файлов .lua в каталоге: {directory}")
        side_names: set[str] = set()
        for path in paths:
            side_names.update(Declarations(path).parse())
        if not side_names:
            raise AnnotationError(f"Не найдены глобальные объявления: {directory}")
        names.update(side_names)
    lines = [
        "---",
        "# Сгенерировано tools/selene_std/generate_selene_std.py; вручную не изменять.",
        "# Источники: Barotrauma-Lua-Annotations/Library/Client и Library/Server.",
        "# Игровые объекты — any; штатные функции предоставляет встроенный std lua52.",
        "globals:",
    ]
    for name in sorted(names):
        lines.extend((f"  {name}:", "    any: true"))
    return "\n".join(lines) + "\n", len(names)


class RussianHelpFormatter(argparse.HelpFormatter):
    def add_usage(self, usage, actions, groups, prefix=None):
        super().add_usage(usage, actions, groups, prefix="Использование: ")


class RussianArgumentParser(argparse.ArgumentParser):
    def error(self, message):
        self.print_usage(sys.stderr)
        self.exit(2, f"Ошибка аргументов: {message}\n")


def parse_args() -> argparse.Namespace:
    parser = RussianArgumentParser(
        description="Обновить единый std Selene из клиентских и серверных аннотаций LuaCs.",
        epilog="Относительные пути отсчитываются от рабочего каталога. "
               "Пример из корня проекта: python tools/selene_std/generate_selene_std.py --dry-run",
        add_help=False, formatter_class=RussianHelpFormatter,
    )
    options = parser.add_argument_group("Параметры")
    options.add_argument("-h", "--help", action="help", help="Показать справку и завершить работу.")
    options.add_argument(
        "--annotations-root", type=Path, default=DEFAULT_ANNOTATIONS, metavar="КАТАЛОГ",
        help="Корень аннотаций с Library/Client и Library/Server. По умолчанию: "
             "соседний с проектом Barotrauma-Lua-Annotations.",
    )
    options.add_argument(
        "--output", type=Path, default=DEFAULT_OUTPUT, metavar="ФАЙЛ",
        help="Выходной YAML; существующий файл заменяется. По умолчанию: selene_std_luacs.yml в корне проекта.",
    )
    options.add_argument(
        "--dry-run", action="store_true",
        help="Прочитать и проверить источники, показать результат без записи и создания каталогов.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        content, count = build_std(args.annotations_root)
        output = args.output.resolve()
        if output.exists() and not output.is_file():
            raise AnnotationError(f"Выходной путь не является файлом: {output}")
        data = content.encode("utf-8")
        unchanged = output.is_file() and output.read_bytes() == data
        action = "Без изменений" if unchanged else "Обновление" if output.exists() else "Создание"
        print(f"{action}: {output}; определений: {count}.")
        if args.dry_run:
            print("Проверка завершена; файлы и каталоги не изменены.")
        elif not unchanged:
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_bytes(data)
    except (AnnotationError, OSError, UnicodeError) as error:
        print(f"Ошибка: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
