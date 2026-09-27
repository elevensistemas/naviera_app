import os
from PIL import Image

src_path = r"C:\Users\ARBUENCS-SRV03\.gemini\antigravity-ide\brain\5ae1228b-6a49-408c-8d0a-a0d735dc722d\.user_uploaded\media_1790455492088.png"

if not os.path.exists(src_path):
    print(f"File not found: {src_path}")
    exit(1)

img = Image.open(src_path)
w, h = img.size
print(f"Original image size: {w} x {h}")

# Save full image or inspect coordinates
# Let's inspect thumbnail locations in media_1790455492088.png
# Card 1: Mooring sunset
# Card 2: Izado worker
# Card 3: Report checklist writing
# Card 4: Electrical hazard panel box
# Card 5: Deck officer

# Let's crop the 5 thumbnails from media_1790455492088.png
# In a typical mobile screenshot (e.g. 590x1000 or similar):
# X left is approx 44px to 228px (width ~ 184px)
# Let's detect exact bounding boxes of the 5 rounded thumbnail images!

# Card 1 (Amarre): Y from ~268 to ~402 (or proportional in h)
# Let's scan Y coordinates for non-white card thumbnails:
# Let's write a script that crops 5 candidate boxes and prints their info:

boxes = [
    (int(w * 0.045), int(h * 0.268), int(w * 0.230), int(h * 0.402)),
    (int(w * 0.045), int(h * 0.438), int(w * 0.230), int(h * 0.572)),
    (int(w * 0.045), int(h * 0.608), int(w * 0.230), int(h * 0.742)),
    (int(w * 0.045), int(h * 0.762), int(w * 0.230), int(h * 0.878)),
    (int(w * 0.045), int(h * 0.885), int(w * 0.230), int(h * 0.985)),
]

assets_dir = r"c:\xampp\htdocs\NCS 4.4 APP\naviera_cruz_app\assets\images\courses"
os.makedirs(assets_dir, exist_ok=True)

for i, box in enumerate(boxes, start=1):
    cropped = img.crop(box)
    cropped = cropped.resize((300, 300), Image.LANCZOS)
    cropped.save(os.path.join(assets_dir, f"course_{i}.png"))
    print(f"Cropped course_{i}.png with box {box}")

