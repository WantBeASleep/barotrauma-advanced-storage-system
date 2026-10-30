"""Copy vanilla reference atlases and index their item XML consumers (stdlib only)."""

from argparse import ArgumentParser
from collections import Counter
from hashlib import sha256
import json
from pathlib import Path
import shutil
import struct
import xml.etree.ElementTree as ET


SKILL_DIR = Path(__file__).resolve().parents[2]
ATLASES = {
    "InventoryIconAtlas.png": "Content/Items/InventoryIconAtlas.png",
    "InventoryIconAtlas2.png": "Content/Items/InventoryIconAtlas2.png",
    "MedicinesSprites.png": "Content/Items/Medical/Medicines.png",
    "MineralsSprites.png": "Content/Items/Materials/minerals.png",
    "GeneticIconAndSprites.png": "Content/Items/Genetic/Genetic.png",
}


def parse_args():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("--game-root", type=Path, help="Barotrauma installation; otherwise search ancestors of this script.")
    parser.add_argument("--output", type=Path, default=SKILL_DIR / "references", help="Output directory; default: this skill's references. Relative paths use the current directory.")
    parser.add_argument("--dry-run", action="store_true", help="Parse and validate all inputs; report counts without writing files.")
    return parser.parse_args()


def attrs(element):
    return {key.lower(): value for key, value in element.attrib.items()}


def png_size(path):
    with path.open("rb") as stream:
        header = stream.read(24)
    if header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise ValueError(f"Not a PNG: {path}")
    return list(struct.unpack(">II", header[16:24]))


def numbers(value):
    return [int(part.strip()) for part in value.split(",")]


def build_catalog(game):
    manifest_path = "Content/ContentPackages/Vanilla.xml"
    manifest = ET.parse(game / manifest_path).getroot()
    inputs = {manifest_path}
    definitions = {}
    texts = {"ru": {}, "en": {}}
    for entry in manifest:
        path = attrs(entry).get("file", "")
        kind = entry.tag.lower()
        if kind == "item":
            inputs.add(path)
            root = ET.parse(game / path).getroot()
            for element in ([root] if "identifier" in attrs(root) else root):
                data = attrs(element)
                if "identifier" in data:
                    identifier = data["identifier"]
                    if identifier in definitions:
                        raise ValueError(f"Duplicate item identifier: {identifier}")
                    definitions[identifier] = (path, element)
        elif kind == "text":
            language = next((lang for lang, folder in (("ru", "Russian"), ("en", "English")) if f"/{folder}/" in path), None)
            if language:
                inputs.add(path)
                for element in ET.parse(game / path).getroot():
                    # Multiple alternatives exist in dialogue; only entity text is needed.
                    if element.tag.lower().startswith(("entityname.", "entitydescription.")):
                        texts[language].setdefault(element.tag.lower(), "".join(element.itertext()).strip())

    local_by_texture = {texture.lower(): local for local, texture in ATLASES.items()}
    size_cache = {}

    def texture_path(texture, xml_path):
        path = texture.replace("\\", "/")
        if not path.lower().startswith("content/"):
            path = (Path(xml_path).parent / path).as_posix()
        return path

    def image_record(data, xml_path, owner, role, xml_element):
        texture = texture_path(data["texture"], xml_path)
        if texture not in size_cache:
            size_cache[texture] = png_size(game / texture)
        if "sourcerect" in data:
            rect = numbers(data["sourcerect"])
        elif "sheetindex" in data and "sheetelementsize" in data:
            x, y = numbers(data["sheetindex"])
            width, height = numbers(data["sheetelementsize"])
            rect = [x * width, y * height, width, height]
        else:
            rect = [0, 0, *size_cache[texture]]
        if len(rect) != 4:
            raise ValueError(f"Invalid rectangle for {owner}: {rect}")
        x, y, width, height = rect
        atlas_width, atlas_height = size_cache[texture]
        within_texture = min(x, y) >= 0 and min(width, height) > 0 and x + width <= atlas_width and y + height <= atlas_height
        if not within_texture and texture.lower() in local_by_texture:
            raise ValueError(f"Out-of-bounds rectangle for {owner}: {texture} {rect}")
        return {
            "role": role, "xml_element": xml_element,
            "defined_by": owner, "xml": xml_path,
            "texture": texture,
            "reference": local_by_texture.get(texture.lower()),
            "rect": rect, "size_px": [width, height], "within_texture": within_texture,
            "attributes": data,
        }

    resolved = {}

    def resolve(identifier, stack=()):
        if identifier in resolved:
            return resolved[identifier]
        if identifier in stack:
            raise ValueError(f"Variant cycle: {stack + (identifier,)}")
        xml_path, element = definitions[identifier]
        data = attrs(element)
        parent = data.get("variantof")
        inherited, primary = ({}, {}) if not parent else resolve(parent, stack + (identifier,))
        merged = {**inherited, **data}
        primary = dict(primary)
        for child in element:
            role = {"sprite": "world_sprite", "inventoryicon": "inventory_icon"}.get(child.tag.lower())
            if not role:
                continue
            child_data = attrs(child)
            previous = primary.get(role)
            effective = {**(previous["attributes"] if previous else {}), **child_data}
            # Geometry notation can change in a variant.
            if "sourcerect" in child_data:
                effective.pop("sheetindex", None)
                effective.pop("sheetelementsize", None)
            elif "sheetindex" in child_data:
                effective.pop("sourcerect", None)
            if previous and "texture" not in child_data:
                effective["texture"] = previous["texture"]
            if "texture" in effective:
                primary[role] = image_record(effective, xml_path, identifier, role, child.tag)
        resolved[identifier] = merged, primary
        return merged, primary

    def localized(data, identifier, language, description=False):
        prefix = "entitydescription." if description else "entityname."
        key = data.get("descriptionidentifier" if description else "nameidentifier") or identifier
        value = texts[language].get(prefix + key.lower())
        if not value and not description and data.get("fallbacknameidentifier"):
            value = texts[language].get(prefix + data["fallbacknameidentifier"].lower())
        return value or data.get("description" if description else "name", "")

    rows = []

    def uses_atlas(identifier, stack=()):
        if identifier in stack:
            raise ValueError(f"Variant cycle: {stack + (identifier,)}")
        xml_path, element = definitions[identifier]
        for child in element.iter():
            texture = attrs(child).get("texture")
            if texture and texture_path(texture, xml_path).lower() in local_by_texture:
                return True
        parent = attrs(element).get("variantof")
        return bool(parent and uses_atlas(parent, stack + (identifier,)))

    for identifier, (xml_path, element) in sorted(definitions.items()):
        if not uses_atlas(identifier):
            continue
        data, primary = resolve(identifier)
        images = list(primary.values())

        def visit(node, path):
            counts = Counter()
            for child in node:
                counts[child.tag] += 1
                child_path = f"{path}/{child.tag}[{counts[child.tag]}]"
                child_data = attrs(child)
                # Main Sprite/InventoryIcon are already resolved above.
                is_primary = node is element and child.tag.lower() in ("sprite", "inventoryicon")
                if "texture" in child_data and not is_primary:
                    texture = texture_path(child_data["texture"], xml_path)
                    if texture.lower() in local_by_texture:
                        images.append(image_record(child_data, xml_path, identifier, "auxiliary", child_path))
                visit(child, child_path)

        visit(element, element.tag)
        if not any(image["reference"] for image in images):
            continue
        rows.append({
            "identifier": identifier,
            "name": {lang: localized(data, identifier, lang) for lang in texts},
            "description": {lang: localized(data, identifier, lang, True) for lang in texts},
            "category": data.get("category", ""), "tags": data.get("tags", "").split(",") if data.get("tags") else [],
            "aliases": data.get("aliases", ""),
            "xml": xml_path, "variant_of": data.get("variantof"),
            "item_scale_xml": data.get("scale"),
            "sprite_color_xml": data.get("spritecolor"),
            "inventory_icon_color_xml": data.get("inventoryiconcolor"),
            "images": images,
        })
    atlas_info = []
    for local, texture in ATLASES.items():
        uses = [image for row in rows for image in row["images"] if image["reference"] == local]
        atlas_info.append({
            "file": local, "source": texture,
            "size_px": png_size(game / texture),
            "sha256": sha256((game / texture).read_bytes()).hexdigest(),
            "item_count": sum(any(image["reference"] == local for image in row["images"]) for row in rows),
            "roles": dict(sorted(Counter(image["role"] for image in uses).items())),
            "unique_rectangles": len({tuple(image["rect"]) for image in uses}),
        })
    index = {
        "schema_version": 1,
        "game_version": attrs(manifest).get("gameversion"),
        "manifest": manifest_path, "items_file": "items.jsonl",
        "item_count": len(rows), "atlases": atlas_info,
        "source_xml_sha256": {path: sha256((game / path).read_bytes()).hexdigest() for path in sorted(inputs)},
    }
    return index, rows


def main():
    args = parse_args()
    game = args.game_root
    if game is None:
        game = next((path for path in SKILL_DIR.parents if (path / "Content/ContentPackages/Vanilla.xml").is_file()), None)
    if game is None:
        raise SystemExit("Cannot find Barotrauma. Supply --game-root.")
    try:
        game = game.resolve()
        output = args.output.resolve()
        if output == game or game in output.parents and "Content" in output.relative_to(game).parts:
            raise ValueError("Output must not overwrite the game's Content directory.")
        index, rows = build_catalog(game)
        if not args.dry_run:
            output.mkdir(parents=True, exist_ok=True)
            for local, texture in ATLASES.items():
                shutil.copyfile(game / texture, output / local)
            (output / "atlas-index.json").write_text(json.dumps(index, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            (output / "items.jsonl").write_text("".join(json.dumps(row, ensure_ascii=False, separators=(",", ":")) + "\n" for row in rows), encoding="utf-8")
        print(json.dumps({"dry_run": args.dry_run, "game_version": index["game_version"], "items": len(rows), "atlases": index["atlases"]}, ensure_ascii=False, indent=2))
    except (OSError, ValueError, KeyError, ET.ParseError) as error:
        raise SystemExit(f"Cannot refresh references: {error}") from error


if __name__ == "__main__":
    main()
