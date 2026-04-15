#!/usr/bin/env python3
"""Create a macOS DMG with drag-to-Applications installer experience."""

import os
import sys
import struct
import zlib

# --- Generate background PNG ---
def make_png(path, width=600, height=400):
    """Create a dark background with arrow and text instructions."""
    try:
        from PIL import Image, ImageDraw, ImageFont

        img = Image.new("RGBA", (width, height), (245, 245, 247, 255))
        draw = ImageDraw.Draw(img)

        # Arrow line from app position to Applications position
        ax, ay = 150, 220
        bx, by = 450, 220
        draw.line([(ax + 90, ay), (bx - 30, by)], fill=(100, 100, 100, 180), width=4)
        # Arrowhead
        draw.polygon(
            [(bx - 30, by), (bx - 48, by - 14), (bx - 48, by + 14)],
            fill=(100, 100, 100, 180),
        )

        # Instruction text
        try:
            font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 18)
        except (OSError, IOError):
            font = ImageFont.load_default()
        text = "Drag ClaudeSwitch to the Applications folder"
        bbox = draw.textbbox((0, 0), text, font=font)
        tw = bbox[2] - bbox[0]
        draw.text(((width - tw) / 2, 340), text, fill=(80, 80, 80, 220), font=font)

        img.save(path)

    except ImportError:
        # Fallback: minimal solid-color PNG without Pillow
        raw = b""
        bg = (245, 245, 247, 255)
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
    app_path = os.path.join(os.getcwd(), "ClaudeSwitch.app")

    bg_path = os.path.join(os.getcwd(), "dmg_background.png")
    make_png(bg_path)

    # dmgbuild settings
    settings = {
        "format": "UDBZ",
        "size": None,
        "files": [app_path],
        "symlinks": {"Applications": "/Applications"},
        "icon_locations": {
            "ClaudeSwitch.app": (150, 200),
            "Applications": (450, 200),
        },
        "background": bg_path,
        "icon_size": 128.0,
        "text_size": 16.0,
        "window_rect": ((200, 120), (800, 520)),
        "default_view": "icon-view",
        "icon_view_settings": {"arrangeBy": "none"},
    }

    from dmgbuild import build_dmg

    output = f"{dmg_name}.dmg"
    build_dmg(output, "ClaudeSwitch", settings)
    print(f"Created {output}")


if __name__ == "__main__":
    main()
