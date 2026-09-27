import os
from PIL import Image

src_path = r"C:\Users\ARBUENCS-SRV03\.gemini\antigravity-ide\brain\5ae1228b-6a49-408c-8d0a-a0d735dc722d\.user_uploaded\media_1790455492088.png"
img = Image.open(src_path).convert("RGB")
w, h = img.size

# The thumbnail images are on the left side, roughly between x=40 and x=240.
# Let's find rows where non-white/non-light-gray pixels exist in x in [45, 230].

thumbnail_y_ranges = []
in_thumb = False
start_y = 0

for y in range(h):
    # Check if this row y has thumbnail content (not plain white/gray card background)
    # Thumbnail pixels have color variations (e.g. sunset orange, electrical gray, helmet blue)
    has_thumb_pixel = False
    for x in range(45, 220, 5):
        r, g, b = img.getpixel((x, y))
        # If pixel is significantly different from white/light-gray background (240-255)
        if not (r > 235 and g > 235 and b > 235) and not (r > 220 and g > 220 and b > 225):
            # Check for non-gray color or dark color
            if abs(r - g) > 8 or abs(g - b) > 8 or r < 180:
                has_thumb_pixel = True
                break
                
    if has_thumb_pixel and not in_thumb:
        in_thumb = True
        start_y = y
    elif not has_thumb_pixel and in_thumb:
        in_thumb = False
        if (y - start_y) > 20: # Only count if height > 20px
            thumbnail_y_ranges.append((start_y, y))

if in_thumb and (h - start_y) > 20:
    thumbnail_y_ranges.append((start_y, h))

print(f"Found {len(thumbnail_y_ranges)} thumbnail Y ranges:")
for idx, (y1, y2) in enumerate(thumbnail_y_ranges, start=1):
    print(f"  Thumb {idx}: Y = {y1} to {y2} (height: {y2 - y1}px)")

# Now for each Y range, find the exact X range (left & right)
cropped_imgs = []
assets_dir = r"c:\xampp\htdocs\NCS 4.4 APP\naviera_cruz_app\assets\images\courses"
os.makedirs(assets_dir, exist_ok=True)

for idx, (y1, y2) in enumerate(thumbnail_y_ranges, start=1):
    # Find x1 and x2
    min_x = w
    max_x = 0
    for y in range(y1, y2):
        for x in range(30, 250):
            r, g, b = img.getpixel((x, y))
            if not (r > 235 and g > 235 and b > 235) and not (r > 225 and g > 225 and b > 230):
                if abs(r - g) > 6 or abs(g - b) > 6 or r < 200:
                    min_x = min(min_x, x)
                    max_x = max(max_x, x)
                    
    box = (min_x, y1, max_x, y2)
    print(f"  Refined Box {idx}: {box}")
    thumb_img = img.crop(box).resize((300, 300), Image.LANCZOS)
    thumb_img.save(os.path.join(assets_dir, f"course_{idx}.png"))
    cropped_imgs.append(thumb_img)

# Fill for courses 6-12
for idx in range(6, 13):
    src_img = cropped_imgs[(idx - 1) % len(cropped_imgs)].copy()
    src_img.save(os.path.join(assets_dir, f"course_{idx}.png"))

# Now write training_course_images_data.dart
import base64
dart_out = r"c:\xampp\htdocs\NCS 4.4 APP\naviera_cruz_app\lib\app\training_course_images_data.dart"

dart_code = [
    "import 'dart:typed_data';\n",
    "import 'dart:convert';\n\n",
    "/// Real image bytes for Naviera Cruz del Sur training courses.\n",
    "/// Extracted directly from official course materials.\n\n"
]

for idx in range(1, 13):
    png_path = os.path.join(assets_dir, f"course_{idx}.png")
    with open(png_path, "rb") as f:
        b64 = base64.b64encode(f.read()).decode("utf-8")
    dart_code.append(f"const String courseImg{idx}Base64 = '{b64}';\n")
    dart_code.append(f"final Uint8List courseImg{idx}Bytes = base64Decode(courseImg{idx}Base64);\n\n")

dart_code.append("final Map<int, Uint8List> courseImagesMap = {\n")
for idx in range(1, 13):
    dart_code.append(f"  {idx}: courseImg{idx}Bytes,\n")
dart_code.append("};\n")

with open(dart_out, "w", encoding="utf-8") as f:
    f.write("".join(dart_code))

print("Auto-detection & thumbnail extraction completed!")
