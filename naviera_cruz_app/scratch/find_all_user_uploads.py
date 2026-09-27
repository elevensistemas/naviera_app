import os
import glob
from PIL import Image

uploaded_dir = r"C:\Users\ARBUENCS-SRV03\.gemini\antigravity-ide\brain\5ae1228b-6a49-408c-8d0a-a0d735dc722d\.user_uploaded"

files = glob.glob(os.path.join(uploaded_dir, "*.png"))
print(f"Found {len(files)} uploaded files:")

for f in files:
    try:
        im = Image.open(f)
        print(f"  {os.path.basename(f)}: size {im.size[0]} x {im.size[1]}")
    except Exception as e:
        print(f"  {os.path.basename(f)}: {e}")

