import sys
import subprocess
from pathlib import Path
import re

PROJECT_ROOT = Path(r"F:/My Games Godot/tps-1")
TSCN_PATH = PROJECT_ROOT / r"Assets/character_model/character_model.tscn"
GODOT_EXE = Path(r"F:/Godot_v4.5-stable_win64.exe/Godot_v4.5-stable_win64_console.exe")
BUILD_DIR = Path(r"F:/My Games Godot/tps-build")
EXPORT_NAME = "Windows Desktop"


def get_model_uid(model_name: str) -> str | None:
    """Extract the UID from the model's .fbx.import file."""
    if not model_name.lower().endswith(".fbx"):
        model_name += ".fbx"

    import_path = PROJECT_ROOT / "Assets" / "character_model" / f"{model_name}.import"

    if not import_path.exists():
        print(f"[ERROR] Import file not found: {import_path}")
        print("[ERROR] Make sure the model has been imported by Godot at least once.")
        return None

    import_text = import_path.read_text(encoding="utf-8")

    # Prefer UID from [remap] section
    remap_section = re.search(r"\[remap\](.*?)(?:\[|$)", import_text, re.DOTALL)
    if remap_section:
        uid_match = re.search(r'uid="([^"]+)"', remap_section.group(1))
        if uid_match:
            uid = uid_match.group(1)
            print(f"[UID] Found UID: {uid}")
            return uid

    # Fallback: search entire file
    uid_match = re.search(r'uid="([^"]+)"', import_text)
    if uid_match:
        uid = uid_match.group(1)
        print(f"[UID] Found UID: {uid}")
        return uid

    print(f"[ERROR] Could not find UID in {import_path}")
    return None


def update_model_reference(model_name: str) -> bool:
    """
    Update only the PackedScene reference for the character model in the scene.
    Preserves all custom nodes, settings, and modifications.
    """
    if not TSCN_PATH.exists():
        print(f"[ERROR] Scene file not found: {TSCN_PATH}")
        print("[ERROR] Create/prepare character_model.tscn in Godot first.")
        return False

    if not model_name.lower().endswith(".fbx"):
        model_name += ".fbx"

    print(f"[MODEL] Updating model reference to: {model_name}")

    new_uid = get_model_uid(model_name)
    if not new_uid:
        print("[ERROR] Cannot proceed without UID.")
        return False

    content = TSCN_PATH.read_text(encoding="utf-8")

    # Backup original scene
    backup_path = TSCN_PATH.with_suffix(".tscn.backup")
    backup_path.write_text(content, encoding="utf-8")
    print(f"[BACKUP] Scene backup saved to: {backup_path}")

    # Find the PackedScene ext_resource for the character model
    ext_match = re.search(
        r'\[ext_resource type="PackedScene" uid="([^"]+)" '
        r'path="(res://Assets/character_model/[^"]+\.fbx)" '
        r'id="([^"]+)"\]',
        content,
    )
    if not ext_match:
        print("[ERROR] Could not find PackedScene ext_resource for character model.")
        return False

    old_uid, old_path, ext_id = ext_match.groups()
    print(f"[MODEL] Previous model: {old_path} (uid={old_uid})")
    print(f"[MODEL] Using resource id: {ext_id}")

    old_line = ext_match.group(0)
    new_line = (
        f'[ext_resource type="PackedScene" uid="{new_uid}" '
        f'path="res://Assets/character_model/{model_name}" '
        f'id="{ext_id}"]'
    )
    content = content.replace(old_line, new_line, 1)

    # Skeleton cleanup: remove bone overrides if present
    print("[CLEANUP] Removing Skeleton3D bone overrides if present...")
    lines = content.split("\n")
    cleaned_lines: list[str] = []
    in_skeleton = False
    bones_removed = 0

    for line in lines:
        if '[node name="Skeleton3D"' in line:
            in_skeleton = True
            cleaned_lines.append(line)
        elif in_skeleton and line.startswith("bones/"):
            bones_removed += 1
            continue
        elif in_skeleton and (line.startswith("[") or not line.strip()):
            in_skeleton = False
            cleaned_lines.append(line)
        else:
            cleaned_lines.append(line)

    content = "\n".join(cleaned_lines)
    if bones_removed > 0:
        print(f"[CLEANUP] Removed {bones_removed} bone override line(s).")

    # Armature transform cleanup
    armature_transform_pattern = (
        r'(\[node name="(?:Armature|Armeture)"[^\[]*?)'
        r"transform = Transform3D\([^\)]+\)\n"
    )
    if re.search(armature_transform_pattern, content):
        content = re.sub(armature_transform_pattern, r"\1", content)
        print("[CLEANUP] Removed Armature transform.")

    TSCN_PATH.write_text(content, encoding="utf-8")

    print("[MODEL] Model reference updated successfully.")
    return True


def build_game(build_suffix: str) -> bool:
    """Build the game executable using Godot in headless mode."""
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    output_exe = BUILD_DIR / f"game-{build_suffix}.exe"

    cmd = [
        str(GODOT_EXE),
        "--headless",
        "--path",
        str(PROJECT_ROOT),
        "--export-release",
        EXPORT_NAME,
        str(output_exe),
    ]

    print(f"[BUILD] Building game: {output_exe}")
    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.returncode != 0:
        print("[BUILD] Build failed.")
        print("[BUILD] stderr:")
        print(result.stderr)
        return False

    print("[BUILD] Build completed successfully.")
    return True


def ensure_model_exists(model_name: str) -> bool:
    """Ensure that the specified FBX model file exists in the character_model folder."""
    if not model_name.lower().endswith(".fbx"):
        model_name += ".fbx"

    model_path = PROJECT_ROOT / "Assets" / "character_model" / model_name

    if not model_path.exists():
        print(f"[ERROR] Model file not found: {model_path}")
        print("[INFO] Available models:")
        models_dir = PROJECT_ROOT / "Assets" / "character_model"
        if models_dir.exists():
            fbx_files = list(models_dir.glob("*.fbx"))
            if fbx_files:
                for fbx in fbx_files:
                    print(f"  - {fbx.name}")
            else:
                print("  (No .fbx files found)")
        return False

    print(f"[MODEL] Using model file: {model_path}")
    return True


def main(argv: list[str]) -> None:
    print("=" * 70)
    print("Godot Character Model Swap and Build")
    print("=" * 70)

    if len(argv) < 2:
        print("Usage:")
        print("  python swap_model_and_build.py <model_name> [build_suffix]")
        print()
        print("Examples:")
        print("  python swap_model_and_build.py alien_soldier")
        print("  python swap_model_and_build.py universal_char_model uni")
        sys.exit(1)

    model_name = argv[1]
    build_suffix = argv[2] if len(argv) >= 3 else model_name.replace(".fbx", "")

    print(f"[ARGS] Model name: {model_name}")
    print(f"[ARGS] Build suffix: {build_suffix}")
    print("=" * 70)

    if not ensure_model_exists(model_name):
        sys.exit(1)

    if not update_model_reference(model_name):
        print("[ERROR] Failed to update model reference.")
        sys.exit(1)

    if not build_game(build_suffix):
        print("[ERROR] Build failed.")
        sys.exit(1)

    print("=" * 70)
    print("Operation completed successfully.")
    print(f"Scene: {TSCN_PATH}")
    print(f"Build: {BUILD_DIR / f'game-{build_suffix}.exe'}")
    print("=" * 70)


if __name__ == "__main__":
    main(sys.argv)
