"""Проверки извлечения имён и безопасного обновления std."""

from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).with_name("generate_selene_std.py")


class GeneratorTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.annotations = self.root / "annotations"
        self.client = self.annotations / "Library" / "Client"
        self.server = self.annotations / "Library" / "Server"
        self.client.mkdir(parents=True)
        self.server.mkdir(parents=True)
        self.output = self.root / "output" / "std.yml"
        (self.client / "global.lua").write_text("""
---@class TypeOnly
--[=[
FakeGlobal = {}
]=]
CS = { Nested = { Field = {} } }
ClientOnly = CS.ClientType
Shared = {}
local LocalType = {}
function LocalType.method() end
LocalType = {}
function TypeOnly.method() end
do
   local Scoped = {}
   function Scoped.method() end
end
Scoped = {}
function global_function(value) end
math = {}
math.clamp = function(value, low, high) end
function math.abs(value) end
string = {}
function string.startsWith(value, prefix) end
bit32 = {}
function bit32.bnot(value) end
function print(value) end
function loadstring(value) end
arg = {}
""", encoding="utf-8")
        (self.server / "global.lua").write_text("""
ServerOnly = {}
Shared = nil
math.clamp = function(value) end
""", encoding="utf-8")

    def run_generator(self, *args):
        return subprocess.run(
            [sys.executable, "-B", str(SCRIPT), "--annotations-root", "annotations",
             "--output", "output/std.yml", *args],
            cwd=self.root, capture_output=True, text=True, encoding="utf-8",
        )

    def test_union_excludes_types_locals_and_standard_functions(self):
        result = self.run_generator()
        self.assertEqual(result.returncode, 0, result.stderr)
        names = {
            line.strip().removesuffix(":")
            for line in self.output.read_text(encoding="utf-8").splitlines()
            if line.startswith("  ") and not line.startswith("    ")
        }
        self.assertEqual(names, {
            "CS", "ClientOnly", "ServerOnly", "Shared", "Scoped",
            "global_function", "math.clamp", "string.startsWith",
        })
        first = self.output.read_bytes()
        result = self.run_generator()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.output.read_bytes(), first)

    def test_dry_run_does_not_create_or_overwrite(self):
        result = self.run_generator("--dry-run")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.output.parent.exists())
        self.output.parent.mkdir()
        self.output.write_bytes(b"original")
        result = self.run_generator("--dry-run")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.output.read_bytes(), b"original")

    def test_missing_side_or_empty_side_keeps_output(self):
        self.output.parent.mkdir()
        self.output.write_bytes(b"original")
        (self.server / "global.lua").unlink()
        for missing in (False, True):
            if missing:
                self.server.rmdir()
            with self.subTest(missing=missing):
                result = self.run_generator()
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn("Traceback", result.stderr)
                self.assertEqual(self.output.read_bytes(), b"original")

    def test_unsupported_source_fails_without_partial_write(self):
        self.output.parent.mkdir()
        self.output.write_bytes(b"original")
        (self.server / "global.lua").write_text(
            "if SERVER then DynamicGlobal = {} end\n", encoding="utf-8"
        )
        result = self.run_generator()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("global.lua", result.stderr)
        self.assertNotIn("Traceback", result.stderr)
        self.assertEqual(self.output.read_bytes(), b"original")

    def test_help_does_not_need_sources(self):
        result = self.run_generator("--help")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Использование:", result.stdout)
        self.assertFalse(self.output.parent.exists())

    def test_unclosed_comment_is_not_a_declaration(self):
        (self.server / "global.lua").write_text(
            "--[[\nFakeGlobal = {}\n", encoding="utf-8"
        )
        result = self.run_generator()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("global.lua", result.stderr)
        self.assertFalse(self.output.exists())

    def test_output_directory_is_rejected_even_in_dry_run(self):
        self.output.mkdir(parents=True)
        result = self.run_generator("--dry-run")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("Traceback", result.stderr)


if __name__ == "__main__":
    unittest.main()
