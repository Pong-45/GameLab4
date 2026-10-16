"""Build Godot animations from the supplied elf frames without changing the PNGs."""
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ANIMATIONS = {
    "Idle": ("IDLE", 1.0, True),
    "Walk": ("WALK", 0.8, True),
    "Run": ("RUN", 0.6, True),
    "Jump": ("JUMP", 0.6, False),
    "Attack": ("ATTACK", 0.3, False),
    "Hurt": ("HURT", 0.4, False),
    "Die": ("DIE", 0.8, False),
}


def main():
    lines = ['[gd_scene format=3]', '']
    frames = {}
    for name, (source, _, _) in ANIMATIONS.items():
        files = sorted((ROOT / "Assets/Icons/avatar").glob(f"Elf_01__{source}_*.png"))
        if len(files) != 10:
            raise ValueError(f"Expected 10 {source} frames, found {len(files)}")
        frames[name] = files
        for i, file in enumerate(files):
            path = file.relative_to(ROOT).as_posix()
            lines.append(f'[ext_resource type="Texture2D" path="res://{path}" id="{name}_{i}"]')
    # Use the same crop and pivot for every frame, preserving the artist's alignment.
    for name, files in frames.items():
        for i in range(len(files)):
            lines.extend(['', f'[sub_resource type="AtlasTexture" id="Frame_{name}_{i}"]',
                          f'atlas = ExtResource("{name}_{i}")',
                          'region = Rect2(739, 231, 1089, 617)'])
    for name, (_, duration, loop) in ANIMATIONS.items():
        times = ', '.join(f'{i * duration / 10:.3f}' for i in range(10))
        values = ', '.join(f'SubResource("Frame_{name}_{i}")' for i in range(10))
        lines.extend(['', f'[sub_resource type="Animation" id="Animation_{name}"]',
                      f'resource_name = "{name}"', f'length = {duration}',
                      f'loop_mode = {int(loop)}', 'tracks/0/type = "value"',
                      'tracks/0/path = NodePath("Sprite:texture")',
                      'tracks/0/interp = 0', 'tracks/0/keys = {',
                      f'"times": PackedFloat32Array({times}),',
                      '"transitions": PackedFloat32Array(1, 1, 1, 1, 1, 1, 1, 1, 1, 1),',
                      '"update": 1,', f'"values": [{values}]', '}'])
    library = ',\n'.join(f'&"{name}": SubResource("Animation_{name}")' for name in ANIMATIONS)
    lines.extend(['', '[sub_resource type="AnimationLibrary" id="AnimationLibrary_avatar"]',
                  '_data = {', library, '}', '', '[node name="Avatar" type="Node2D"]',
                  '', '[node name="Sprite" type="Sprite2D" parent="."]',
                  'texture_filter = 2', 'scale = Vector2(0.136, 0.136)',
                  'offset = Vector2(283.5, -289.5)',
                  'texture = SubResource("Frame_Idle_0")', '',
                  '[node name="AnimationPlayer" type="AnimationPlayer" parent="."]',
                  'libraries = {', '&"": SubResource("AnimationLibrary_avatar")', '}',
                  'autoplay = "Idle"', ''])
    (ROOT / 'Scenes/Sprites/avatar.tscn').write_text('\n'.join(lines), encoding='utf-8')


if __name__ == '__main__':
    main()
