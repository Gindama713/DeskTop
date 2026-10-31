"""Remove the black background the Windows shell bakes into 256px icon bitmaps.

Flood-fills from the border through near-black pixels only, so dark artwork
inside the icon survives. Idempotent: already-transparent PNGs are skipped.
"""
import os
from collections import deque

from PIL import Image

ICONS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "assets", "icons")
THRESHOLD = 12


def clear_black_bg(path):
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    px = im.load()

    if im.getchannel("A").getextrema()[0] == 0:
        return "skip"

    visited = bytearray(w * h)
    q = deque()

    def dark(x, y):
        r, g, b, a = px[x, y]
        return a > 0 and r < THRESHOLD and g < THRESHOLD and b < THRESHOLD

    for x in range(w):
        for y in (0, h - 1):
            if dark(x, y) and not visited[y * w + x]:
                visited[y * w + x] = 1
                q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if dark(x, y) and not visited[y * w + x]:
                visited[y * w + x] = 1
                q.append((x, y))

    while q:
        x, y = q.popleft()
        px[x, y] = (0, 0, 0, 0)
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not visited[ny * w + nx] and dark(nx, ny):
                visited[ny * w + nx] = 1
                q.append((nx, ny))

    im.save(path)
    return "fixed"


if __name__ == "__main__":
    fixed = skipped = 0
    for name in sorted(os.listdir(ICONS)):
        if not name.lower().endswith(".png"):
            continue
        if name.startswith("_"):
            continue
        if clear_black_bg(os.path.join(ICONS, name)) == "fixed":
            fixed += 1
        else:
            skipped += 1
    print("fixed", fixed, "skipped", skipped)
