"""
Extract 12 Pixel-Art Chess Characters from User Reference Image with Transparent Alpha
---------------------------------------------------------------------------------------
"""
from PIL import Image
import numpy as np
from collections import deque
from pathlib import Path

SOURCE_IMG = Path(r"C:/Users/Dwell/.gemini/antigravity/brain/d5cbd0d2-222f-40b5-bff0-276eecedfee4/.user_uploaded/media_1794233342315_bbdb01cd.jpg")
OUT_DIR = Path("art/sprites/pixel_25d")
OUT_DIR.mkdir(parents=True, exist_ok=True)

COLUMNS = [
    ("pawn", 5, 150),
    ("knight", 152, 345),
    ("bishop", 345, 495),
    ("rook", 495, 655),
    ("queen", 655, 825),
    ("king", 825, 995),
]

ROWS = [
    ("white", 130, 412),
    ("black", 535, 810),
]

img = Image.open(SOURCE_IMG).convert("RGB")
src_arr = np.array(img)

def is_background_color(rgb):
    r, g, b = int(rgb[0]), int(rgb[1]), int(rgb[2])
    # Dark checkerboard background tile colors: low saturation, dark
    # Dark tile is ~27, 25, 36. Lighter tile is ~40, 38, 50. Floor grid lines ~18, 16, 25.
    if r < 58 and g < 55 and b < 68 and abs(r - g) < 18 and abs(g - b) < 22:
        return True
    return False

def remove_background_bfs(crop_arr):
    h, w, _ = crop_arr.shape
    alpha = np.ones((h, w), dtype=np.uint8) * 255
    visited = np.zeros((h, w), dtype=bool)
    queue = deque()

    # Seed all border pixels that match background
    for y in range(h):
        for x in (0, w - 1):
            if is_background_color(crop_arr[y, x]):
                queue.append((y, x))
                visited[y, x] = True
                alpha[y, x] = 0

    for x in range(w):
        for y in (0, h - 1):
            if not visited[y, x] and is_background_color(crop_arr[y, x]):
                queue.append((y, x))
                visited[y, x] = True
                alpha[y, x] = 0

    # BFS flood fill from outside inward
    while queue:
        cy, cx = queue.popleft()
        for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx]:
                if is_background_color(crop_arr[ny, nx]):
                    visited[ny, nx] = True
                    alpha[ny, nx] = 0
                    queue.append((ny, nx))

    # Also trim any isolated dark border pixels in top/bottom 8 rows
    for y in range(min(12, h)):
        for x in range(w):
            if is_background_color(crop_arr[y, x]):
                alpha[y, x] = 0
    for y in range(max(0, h - 10), h):
        for x in range(w):
            if is_background_color(crop_arr[y, x]):
                alpha[y, x] = 0

    rgba = np.dstack((crop_arr, alpha))
    return rgba

print("Starting extraction of all 12 characters...")
for row_name, y1, y2 in ROWS:
    for col_name, x1, x2 in COLUMNS:
        crop = src_arr[y1:y2, x1:x2]
        clean_rgba = remove_background_bfs(crop)

        # Autocrop empty transparent borders
        alpha_channel = clean_rgba[:, :, 3]
        non_zero = np.argwhere(alpha_channel > 0)
        if non_zero.size > 0:
            ymin, xmin = non_zero.min(axis=0)
            ymax, xmax = non_zero.max(axis=0)
            cropped_rgba = clean_rgba[ymin:ymax+1, xmin:xmax+1]
        else:
            cropped_rgba = clean_rgba

        out_img = Image.fromarray(cropped_rgba, "RGBA")
        out_filename = f"{row_name}_{col_name}.png"
        out_path = OUT_DIR / out_filename
        out_img.save(out_path)
        print(f"Saved: {out_path} (Size: {out_img.size})")

print("All 12 characters extracted successfully!")
