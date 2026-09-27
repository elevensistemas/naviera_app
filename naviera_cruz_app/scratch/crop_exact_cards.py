import os
from PIL import Image

src_path = r"C:\Users\ARBUENCS-SRV03\.gemini\antigravity-ide\brain\5ae1228b-6a49-408c-8d0a-a0d735dc722d\.user_uploaded\media_1790455492088.png"
img = Image.open(src_path).convert("RGB")
w, h = img.size
print(f"Source image size: {w} x {h}")

# In media_1790455492088.png (1024x473):
# The 5 course thumbnails are lined up vertically on the left side.
# Let's crop candidate boxes around X: 45 to 240, Y: 125 to 470
# Let's save slices along Y to see where each thumbnail image actually is!

# Let's inspect 5 exact Y bounding boxes:
# Card 1: Sunset Mooring (Y ~ 125 to ~ 190)
# Card 2: Izado Worker (Y ~ 205 to ~ 270)
# Card 3: Report Checklist (Y ~ 285 to ~ 350)
# Card 4: Electrical Box (Y ~ 360 to ~ 415)
# Card 5: Deck Helmet Officer (Y ~ 418 to ~ 468)

boxes = [
    (46, 126, 235, 190),
    (46, 207, 235, 270),
    (46, 287, 235, 350),
    (46, 360, 235, 415),
    (46, 418, 235, 468),
]

assets_dir = r"c:\xampp\htdocs\NCS 4.4 APP\naviera_cruz_app\assets\images\courses"
os.makedirs(assets_dir, exist_ok=True)

cropped_list = []
for i, b in enumerate(boxes, start=1):
    c = img.crop(b).resize((300, 300), Image.LANCZOS)
    c.save(os.path.join(assets_dir, f"course_{i}.png"))
    cropped_list.append(c)
    print(f"Saved course_{i}.png from box {b}")

# Assign for 6 to 12
for idx in range(6, 13):
    src = cropped_list[(idx - 1) % len(cropped_list)].copy()
    src.save(os.path.join(assets_dir, f"course_{idx}.png"))

# Re-encode training_course_images_data.dart
import base64
dart_out = r"c:\xampp\htdocs\NCS 4.4 APP\naviera_cruz_app\lib\app\training_course_images_data.dart"

dart_code = [
    "import 'dart:typed_data';\n",
    "import 'dart:convert';\n\n",
    "/// Real image bytes for Naviera Cruz del Sur training courses.\n\n"
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

print("Exact crop script finished!")
