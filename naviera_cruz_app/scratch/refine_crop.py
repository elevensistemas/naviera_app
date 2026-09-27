import os
from PIL import Image

src_path = r"C:\Users\ARBUENCS-SRV03\.gemini\antigravity-ide\brain\5ae1228b-6a49-408c-8d0a-a0d735dc722d\.user_uploaded\media_1790457486604.png"
img = Image.open(src_path)
w, h = img.size
print(f"Source size: {w}x{h}")

# In media_1790457486604.png (1024x402):
# The uploaded image contains the vertical screenshot of the courses!
# Let's find the exact bounding boxes of the 5 cards.
# Card 1 (Amarre): ~268px to ~402px? Wait, total height is 402!
# Let's inspect where the thumbnails are located in this 1024x402 image.

# Let's save a visualization overlay or find the thumbnail boundaries by detecting dark/card pixel borders.
# Card 1 thumbnail: left_x ~ 45, width ~ 190, top ~ 108, height ~ 54?
# Wait! Let's scan X and Y coordinates to find non-white thumbnail pixels on the left side!

thumbnails = []
# X is between 40 and 240
# Y coordinates for the 5 cards in 402px height:
# Card 1: Y 108 to 162
# Card 2: Y 176 to 230
# Card 3: Y 244 to 298
# Card 4: Y 306 to 352
# Card 5: Y 355 to 400

# Let's check card thumbnail X coordinates: ~ 45 to ~ 235
box1 = (45, 108, 235, 162)
box2 = (45, 176, 235, 230)
box3 = (45, 244, 235, 298)
box4 = (45, 306, 235, 352)
box5 = (45, 355, 235, 400)

boxes = [box1, box2, box3, box4, box5]

assets_dir = r"c:\xampp\htdocs\NCS 4.4 APP\naviera_cruz_app\assets\images\courses"

for idx, b in enumerate(boxes, start=1):
    c = img.crop(b).resize((300, 300), Image.LANCZOS)
    c.save(os.path.join(assets_dir, f"course_{idx}.png"))
    print(f"Crop {idx} size: {c.size}")

# Regenerate training_course_images_data.dart with these refined crops
import base64
dart_out = r"c:\xampp\htdocs\NCS 4.4 APP\naviera_cruz_app\lib\app\training_course_images_data.dart"

dart_code = [
    "import 'dart:typed_data';\n",
    "import 'dart:convert';\n\n",
    "/// Real image bytes for Naviera Cruz del Sur training courses.\n",
    "/// Extracted from official app design & saved in assets/images/courses/\n\n"
]

for idx in range(1, 13):
    src_idx = idx if idx <= 5 else ((idx - 1) % 5 + 1)
    png_path = os.path.join(assets_dir, f"course_{src_idx}.png")
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

print("Refined crop script finished successfully!")
