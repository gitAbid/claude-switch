#!/usr/bin/env python3
"""Create a macOS DMG with drag-to-Applications installer experience."""

import os
import sys
import struct
import tempfile
import zlib


def make_background(path, width=600, height=400):
    """Create a light background with arrow and text instructions."""
    try:
        from PIL import Image, ImageDraw, ImageFont

        img = Image.new("RGBA", (width, height), (245, 245, 247, 255))
        draw = ImageDraw.Draw(img)

        # Arrow from app position to Applications position
        draw.line([(240, 200), (390, 200)], fill=(100, 100, 100, 180), width=4)
        draw.polygon([(390, 200), (374, 188), (374, 212)], fill=(100, 100, 100, 180))

        try:
            font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 16)
        except (OSError, IOError):
            font = ImageFont.load_default()

        text = "Drag ClaudeSwitch to the Applications folder"
        bbox = draw.textbbox((0, 0), text, font=font)
        tw = bbox[2] - bbox[0]
        draw.text(((width - tw) / 2, 330), text, fill=(80, 80, 80, 220), font=font)

        img.save(path)

    except ImportError:
        # Fallback: solid-color PNG without Pillow
        bg = (245, 245, 247, 255)
        raw = b""
        for y in range(height):
            raw += b"\x00"
            for x in range(width):
                raw += struct.pack("BBBB", *bg)

        def chunk(ctype, data):
            c = ctype + data
            return (
                struct.pack(">I", len(data))
                + c
                + struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)
            )

        ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
        with open(path, "wb") as f:
            f.write(
                b"\x89PNG\r\n\x1a\n"
                + chunk(b"IHDR", ihdr)
                + chunk(b"IDAT", zlib.compress(raw))
                + chunk(b"IEND", b"")
            )


def main():
    dmg_name = sys.argv[1] if len(sys.argv) > 1 else "ClaudeSwitch"
    cwd = os.getcwd()
    app_path = os.path.join(cwd, "ClaudeSwitch.app")
    bg_path = os.path.join(cwd, "dmg_background.png")

    make_background(bg_path)

    # Write a dmgbuild Python settings file
    settings_content = f"""
format = 'UDBZ'
size = None
files = ['{app_path}']
symlinks = {{'Applications': '/Applications'}}
icon_locations = {{
    'ClaudeSwitch.app': (150, 190),
    'Applications': (450, 190),
}}
background = '{bg_path}'
icon_size = 128.0
text_size = 16.0
window_rect = ((200, 120), (800, 520))
default_view = 'icon-view'
icon_view_settings = {{'arrangeBy': 'none'}}
"""

    with tempfile.NamedTemporaryFile(mode="w", suffix=".py", delete=False) as f:
        f.write(settings_content)
        settings_file = f.name

    try:
        from dmgbuild import build_dmg

        output = f"{dmg_name}.dmg"
        build_dmg(output, "ClaudeSwitch", settings_file)
        print(f"Created {output}")
    finally:
        os.unlink(settings_file)


if __name__ == "__main__":
    main()
