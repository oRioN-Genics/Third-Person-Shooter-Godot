import sys
import subprocess
from pathlib import Path

PROJECT_ROOT = Path(r"F:/My Games Godot/tps-1")
TSCN_PATH    = PROJECT_ROOT / r"Assets/character_model/character_model.tscn"
GODOT_EXE    = Path(r"F:/Godot_v4.5-stable_win64.exe/Godot_v4.5-stable_win64_console.exe")
BUILD_DIR    = Path(r"F:/My Games Godot/tps-build")
EXPORT_NAME  = "Windows Desktop"


def get_model_uid(model_name: str):
    """Extract the UID from the model's .fbx.import file."""
    
    if not model_name.lower().endswith(".fbx"):
        model_name += ".fbx"
    
    import_path = PROJECT_ROOT / "Assets" / "character_model" / f"{model_name}.import"
    
    print(f"[UID] Looking for import file: {import_path}")
    
    if not import_path.exists():
        print(f"[ERROR] Import file not found: {import_path}")
        print(f"[ERROR] Make sure {model_name} has been imported by Godot")
        return None
    
    import_text = import_path.read_text(encoding="utf-8")
    
    # Look for uid= line in the [remap] section
    import re
    
    # First try to find it in [remap] section specifically
    remap_section = re.search(r'\[remap\](.*?)(?:\[|$)', import_text, re.DOTALL)
    
    if remap_section:
        uid_match = re.search(r'uid="([^"]+)"', remap_section.group(1))
        if uid_match:
            uid = uid_match.group(1)
            print(f"[UID] ✓ Found UID for {model_name}: {uid}")
            return uid
    
    # Fallback: search entire file
    uid_match = re.search(r'uid="([^"]+)"', import_text)
    if uid_match:
        uid = uid_match.group(1)
        print(f"[UID] ✓ Found UID for {model_name}: {uid}")
        return uid
    
    print(f"[ERROR] Could not find UID in {import_path}")
    print(f"[ERROR] Import file contents preview:")
    print(import_text[:500])
    return None


def create_clean_scene(model_name: str):
    """
    Create a completely clean character_model.tscn from scratch.
    No bone overrides, no custom transforms - just the essentials.
    """
    
    # Ensure .fbx extension
    if not model_name.lower().endswith(".fbx"):
        model_name += ".fbx"
    
    # Node name is filename without extension
    node_name = model_name.replace(".fbx", "")
    
    print(f"\n[CREATE] Generating clean scene for: {model_name}")
    print(f"[CREATE] Instance node name: {node_name}")
    
    # Get the correct UID for this model
    model_uid = get_model_uid(model_name)
    
    if not model_uid:
        print(f"[ERROR] Cannot proceed without UID")
        print(f"[ERROR] Make sure {model_name} has been imported by Godot at least once")
        return False
    
    # Clean scene template - minimal, no custom overrides
    scene_content = f'''[gd_scene load_steps=10 format=3 uid="uid://bmr2d5oo2pfgy"]

[ext_resource type="Script" uid="uid://bxf0ay2m6ron3" path="res://Assets/character_model/character_model.gd" id="1_70etq"]
[ext_resource type="PackedScene" uid="{model_uid}" path="res://Assets/character_model/{model_name}" id="2_70etq"]

[sub_resource type="AnimationNodeAnimation" id="AnimationNodeAnimation_70etq"]
animation = &"weight_shift_idle"

[sub_resource type="AnimationNodeAnimation" id="AnimationNodeAnimation_5e4b4"]
animation = &"falling_idle"

[sub_resource type="AnimationNodeAnimation" id="AnimationNodeAnimation_422nd"]
animation = &"slow_run"

[sub_resource type="AnimationNodeAnimation" id="AnimationNodeAnimation_obvr4"]
animation = &"fast_run"

[sub_resource type="AnimationNodeTransition" id="AnimationNodeTransition_7b78d"]
sync = true
xfade_time = 0.2
input_0/name = "Idle"
input_0/auto_advance = false
input_0/break_loop_at_end = false
input_0/reset = true
input_1/name = "Walk"
input_1/auto_advance = false
input_1/break_loop_at_end = false
input_1/reset = true
input_2/name = "Run"
input_2/auto_advance = false
input_2/break_loop_at_end = false
input_2/reset = true
input_3/name = "Sprint"
input_3/auto_advance = false
input_3/break_loop_at_end = false
input_3/reset = true
input_4/name = "Jump"
input_4/auto_advance = false
input_4/break_loop_at_end = false
input_4/reset = true

[sub_resource type="AnimationNodeAnimation" id="AnimationNodeAnimation_j6fbt"]
animation = &"walking"

[sub_resource type="AnimationNodeBlendTree" id="AnimationNodeBlendTree_rvvkx"]
graph_offset = Vector2(-487, 38)
nodes/output/position = Vector2(440, 60)
nodes/walk/node = SubResource("AnimationNodeAnimation_j6fbt")
nodes/walk/position = Vector2(-260, 160)
nodes/unarmed_movement/node = SubResource("AnimationNodeTransition_7b78d")
nodes/unarmed_movement/position = Vector2(100, 80)
nodes/idle/node = SubResource("AnimationNodeAnimation_70etq")
nodes/idle/position = Vector2(-220, 60)
nodes/run/node = SubResource("AnimationNodeAnimation_422nd")
nodes/run/position = Vector2(-220, 280)
nodes/sprint/node = SubResource("AnimationNodeAnimation_obvr4")
nodes/sprint/position = Vector2(-280, 380)
nodes/in_air/node = SubResource("AnimationNodeAnimation_5e4b4")
nodes/in_air/position = Vector2(-240, 500)
node_connections = [&"output", 0, &"unarmed_movement", &"unarmed_movement", 0, &"idle", &"unarmed_movement", 1, &"walk", &"unarmed_movement", 2, &"run", &"unarmed_movement", 3, &"sprint", &"unarmed_movement", 4, &"in_air"]

[node name="CharacterModel" type="Node3D" node_paths=PackedStringArray("animation_tree")]
script = ExtResource("1_70etq")
animation_tree = NodePath("AnimationTree")

[node name="{node_name}" parent="." instance=ExtResource("2_70etq")]

[node name="AnimationTree" type="AnimationTree" parent="."]
root_node = NodePath("../{node_name}")
tree_root = SubResource("AnimationNodeBlendTree_rvvkx")
anim_player = NodePath("../{node_name}/AnimationPlayer")
parameters/unarmed_movement/current_state = "Idle"
parameters/unarmed_movement/transition_request = ""
parameters/unarmed_movement/current_index = 0

[editable path="{node_name}"]
'''
    
    # Create backup of existing file
    if TSCN_PATH.exists():
        backup_path = TSCN_PATH.with_suffix(".tscn.backup")
        backup_path.write_text(TSCN_PATH.read_text(encoding="utf-8"), encoding="utf-8")
        print(f"[CREATE] Backup saved: {backup_path}")
    
    # Write the clean scene
    TSCN_PATH.write_text(scene_content, encoding="utf-8")
    print(f"[CREATE] ✓ Created clean scene: {TSCN_PATH}")
    print(f"[CREATE] ✓ No bone overrides, no custom transforms")
    
    return True


def build_game(build_suffix: str):
    """Build the game executable."""
    
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    output_exe = BUILD_DIR / f"game-{build_suffix}.exe"
    
    cmd = [
        str(GODOT_EXE),
        "--headless",
        "--path", str(PROJECT_ROOT),
        "--export-release", EXPORT_NAME,
        str(output_exe),
    ]
    
    print(f"\n[BUILD] Building game...")
    print(f"[BUILD] Command: {' '.join(cmd)}")
    print(f"[BUILD] Output: {output_exe}")
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode != 0:
        print(f"\n[BUILD] ✗ Build failed!")
        print(f"[BUILD] Error output:")
        print(result.stderr)
        return False
    
    print(f"[BUILD] ✓ Build successful: {output_exe}")
    return True


def verify_model_exists(model_name: str):
    """Check if the model file actually exists."""
    
    if not model_name.lower().endswith(".fbx"):
        model_name += ".fbx"
    
    model_path = PROJECT_ROOT / "Assets" / "character_model" / model_name
    
    if not model_path.exists():
        print(f"\n[ERROR] Model file not found: {model_path}")
        print(f"[ERROR] Available models in Assets/character_model/:")
        
        models_dir = PROJECT_ROOT / "Assets" / "character_model"
        if models_dir.exists():
            fbx_files = list(models_dir.glob("*.fbx"))
            if fbx_files:
                for fbx in fbx_files:
                    print(f"  - {fbx.name}")
            else:
                print("  (No .fbx files found)")
        
        return False
    
    print(f"[VERIFY] ✓ Model exists: {model_path}")
    return True


def main(argv):
    print("=" * 70)
    print("GODOT MODEL SWAP & BUILD - CLEAN START")
    print("=" * 70)
    
    if len(argv) < 2:
        print("\nUsage:")
        print("  python swap_model_and_build.py <model_name> [build_suffix]")
        print("\nExamples:")
        print("  python swap_model_and_build.py alien_soldier")
        print("  python swap_model_and_build.py alien_soldier.fbx alien_v1")
        print("  python swap_model_and_build.py universal_char_model")
        print("\nWhat this does:")
        print("  1. Creates a CLEAN character_model.tscn (no overrides)")
        print("  2. Sets it to use your specified model")
        print("  3. Builds a new game .exe")
        print("=" * 70)
        sys.exit(1)
    
    model_name = argv[1]
    build_suffix = argv[2] if len(argv) >= 3 else model_name.replace(".fbx", "")
    
    print(f"\nModel: {model_name}")
    print(f"Build suffix: {build_suffix}")
    print("=" * 70)
    
    # Step 1: Verify model exists
    if not verify_model_exists(model_name):
        sys.exit(1)
    
    # Step 2: Create clean scene
    if not create_clean_scene(model_name):
        print("\n[ERROR] Failed to create scene")
        sys.exit(1)
    
    # Step 3: Build the game
    if not build_game(build_suffix):
        print("\n[ERROR] Build failed")
        sys.exit(1)
    
    # Success!
    print("\n" + "=" * 70)
    print("✓ SUCCESS!")
    print("=" * 70)
    print(f"Scene file: {TSCN_PATH}")
    print(f"Game build: {BUILD_DIR / f'game-{build_suffix}.exe'}")
    print("\nNext steps:")
    print("  1. Test the game by running the .exe")
    print("  2. If player is still invisible, check in Godot Editor:")
    print("     - Open character_model.tscn")
    print("     - Check if model is visible in 3D viewport")
    print("     - Check Materials tab for missing textures")
    print("=" * 70)


if __name__ == "__main__":
    main(sys.argv)