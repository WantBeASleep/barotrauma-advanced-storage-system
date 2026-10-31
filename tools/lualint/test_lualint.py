"""Контрольные примеры проверяют реальную конфигурацию и запуск Selene."""

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
LINTER = PROJECT_ROOT / "tools" / "lualint" / "lualint.py"


class LualintTests(unittest.TestCase):
    def lint(self, source):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "example.lua"
            path.write_text(source, encoding="utf-8")
            result = subprocess.run(
                [sys.executable, str(LINTER), str(path),
                 "--selene-arg=--display-style=Json", "--selene-arg=--no-summary"],
                cwd=directory, capture_output=True, text=True, encoding="utf-8",
            )
        diagnostics = [json.loads(line) for line in result.stdout.splitlines()]
        return result, {item["code"] for item in diagnostics}

    def test_mixed_environment_and_extensions(self):
        result, codes = self.lint("""
if CLIENT then
   GUI.AnyMethod(Item, CS.Barotrauma.GUIButton)
end
if SERVER then
   Networking.AnyMethod(Game, CS.Barotrauma.GameServer)
end
print(math.clamp(1, 0, 2), math.lerp(0, 2, 0.5), math.round(1.5), math.sign(1))
print(math.remap(1, 0, 2, 0, 4), string.startsWith("abc", "a"), string.endsWith("abc", "c"))
debug.breakpoint()
printerror("пример")
""")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(codes, set())

    def test_unknown_name_and_type_only_name(self):
        for name in ("Charactre", "GUIButton", "Barotrauma", "__ctor", "ModUtils"):
            with self.subTest(name=name):
                result, codes = self.lint(f"print({name})\n")
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("undefined_variable", codes)

    def test_accidental_global(self):
        result, codes = self.lint("accidental_global = 1\nprint(accidental_global)\n")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("unscoped_variables", codes)

    def test_standard_lua_checks_remain_enabled(self):
        for source in (
            'print(math.abs("строка"))', 'print(string.lower(123))',
            'table.insert()', 'print(bit32.bnot("строка"))',
            'print(math.clmap(1, 0, 2))', 'print(string.stratsWith("a", "a"))',
        ):
            with self.subTest(source=source):
                result, codes = self.lint(source + "\n")
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("incorrect_standard_library_use", codes)

    def test_lua52_functions(self):
        result, _ = self.lint("print(table.unpack(table.pack(1, 2)), bit32.band(1, 2), rawlen({}))\n")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
