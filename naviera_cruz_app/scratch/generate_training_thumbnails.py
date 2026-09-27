import os
import base64
from PIL import Image, ImageDraw, ImageFilter, ImageFont

def draw_thumbnail(course_id, title, color_theme, icon_type):
    width, height = 300, 300
    img = Image.new('RGB', (width, height), color=color_theme[0])
    draw = ImageDraw.Draw(img)
    
    # Create background gradient
    for y in range(height):
        r = int(color_theme[0][0] + (color_theme[1][0] - color_theme[0][0]) * (y / height))
        g = int(color_theme[0][1] + (color_theme[1][1] - color_theme[0][1]) * (y / height))
        b = int(color_theme[0][2] + (color_theme[1][2] - color_theme[0][2]) * (y / height))
        draw.line([(0, y), (width, y)], fill=(r, g, b))
        
    # Draw thematic nautical shapes / illustrations
    if icon_type == 'mooring':
        # Sunset ocean, sea waves and bollard rope
        draw.ellipse([150, 40, 270, 160], fill=(255, 160, 60)) # Sun
        draw.rectangle([0, 160, 300, 300], fill=(10, 40, 90)) # Ocean
        for y in range(165, 300, 15):
            draw.line([(0, y), (300, y)], fill=(20, 70, 140), width=3)
        # Bollard
        draw.rectangle([60, 140, 120, 260], fill=(50, 60, 75))
        draw.ellipse([45, 120, 135, 150], fill=(70, 85, 105))
        # Rope
        draw.line([(10, 240), (80, 180), (290, 270)], fill=(220, 180, 110), width=12)
        
    elif icon_type == 'crane':
        # Crane rigging and industrial hoist
        draw.rectangle([0, 0, 300, 300], fill=(25, 35, 50))
        # Crane boom
        draw.line([(20, 20), (280, 120)], fill=(230, 140, 20), width=14)
        draw.line([(20, 20), (280, 20)], fill=(230, 140, 20), width=8)
        for x in range(30, 270, 35):
            draw.line([(x, 20), (x+25, 120)], fill=(200, 110, 10), width=4)
        # Cable & Hook
        draw.line([(220, 95), (220, 200)], fill=(180, 190, 200), width=5)
        draw.ellipse([200, 200, 240, 240], fill=(230, 140, 20))
        draw.arc([205, 220, 235, 265], start=0, end=200, fill=(230, 140, 20), width=6)
        
    elif icon_type == 'report':
        # Safety checklist clipboard and pen
        draw.rectangle([0, 0, 300, 300], fill=(30, 50, 75))
        # Clipboard
        draw.rectangle([60, 40, 240, 260], fill=(160, 110, 60))
        draw.rectangle([70, 65, 230, 250], fill=(245, 247, 250))
        draw.rectangle([110, 30, 190, 60], fill=(90, 95, 105))
        # Checklines
        for y in [95, 140, 185, 225]:
            draw.rectangle([85, y, 105, y+20], fill=(220, 225, 235))
            draw.line([(88, y+10), (95, y+17), (103, y+4)], fill=(16, 163, 74), width=4)
            draw.line([(120, y+10), (215, y+10)], fill=(80, 95, 115), width=4)
            
    elif icon_type == 'electric':
        # Electrical breaker panel with yellow hazard sign
        draw.rectangle([0, 0, 300, 300], fill=(40, 45, 55))
        draw.rectangle([40, 30, 260, 270], fill=(70, 75, 85))
        draw.rectangle([55, 45, 245, 255], fill=(30, 35, 42))
        # Switches
        for row in range(2):
            for col in range(4):
                x = 75 + col * 42
                y = 65 + row * 60
                draw.rectangle([x, y, x+26, y+40], fill=(15, 20, 25))
                draw.rectangle([x+4, y+5, x+22, y+20], fill=(220, 50, 50) if col%2==0 else (50, 200, 80))
        # Lightning hazard sign
        draw.polygon([(150, 185), (115, 250), (185, 250)], fill=(245, 180, 20))
        draw.polygon([(150, 195), (135, 225), (152, 225), (142, 245), (165, 215), (148, 215)], fill=(20, 20, 20))
        
    elif icon_type == 'operations':
        # Officer with helmet & vest in front of ship deck
        draw.rectangle([0, 0, 300, 180], fill=(15, 85, 155)) # Sky/sea
        draw.rectangle([0, 180, 300, 300], fill=(60, 70, 85)) # Deck
        # Ship rail
        draw.line([(0, 150), (300, 150)], fill=(220, 225, 235), width=6)
        draw.line([(0, 175), (300, 175)], fill=(220, 225, 235), width=6)
        # Person silhouette with orange safety vest & helmet
        draw.ellipse([110, 80, 190, 160], fill=(235, 130, 20)) # Helmet
        draw.rectangle([125, 125, 175, 165], fill=(240, 210, 175)) # Face
        draw.polygon([(80, 165), (220, 165), (240, 300), (60, 300)], fill=(235, 100, 15)) # Orange vest
        draw.line([(100, 170), (100, 300)], fill=(245, 245, 245), width=10) # Reflective stripe
        draw.line([(200, 170), (200, 300)], fill=(245, 245, 245), width=10)

    elif icon_type == 'firstaid':
        # Medical first aid cross & kit
        draw.rectangle([0, 0, 300, 300], fill=(15, 110, 180))
        draw.rectangle([50, 60, 250, 240], fill=(240, 245, 250))
        # Red cross
        draw.rectangle([125, 90, 175, 210], fill=(220, 38, 38))
        draw.rectangle([90, 125, 210, 175], fill=(220, 38, 38))

    elif icon_type == 'fire':
        # Firefighter helmet, flame & hose
        draw.rectangle([0, 0, 300, 300], fill=(180, 40, 20))
        # Flames
        draw.polygon([(60, 300), (90, 140), (130, 220), (170, 100), (210, 200), (250, 120), (270, 300)], fill=(245, 160, 20))
        draw.polygon([(100, 300), (140, 170), (170, 240), (200, 160), (230, 300)], fill=(250, 230, 50))

    elif icon_type == 'survival':
        # Lifebuoy ring in ocean waves
        draw.rectangle([0, 0, 300, 300], fill=(10, 75, 140))
        # Waves
        for y in range(40, 300, 30):
            draw.arc([-50, y, 150, y+40], start=0, end=180, fill=(40, 125, 200), width=4)
            draw.arc([150, y, 350, y+40], start=0, end=180, fill=(40, 125, 200), width=4)
        # Lifebuoy ring
        draw.ellipse([60, 60, 240, 240], fill=(235, 75, 30))
        draw.ellipse([105, 105, 195, 195], fill=(10, 75, 140))
        # White stripes on ring
        draw.rectangle([135, 60, 165, 105], fill=(245, 245, 245))
        draw.rectangle([135, 195, 165, 240], fill=(245, 245, 245))
        draw.rectangle([60, 135, 105, 165], fill=(245, 245, 245))
        draw.rectangle([195, 135, 240, 165], fill=(245, 245, 245))

    elif icon_type == 'isps':
        # ISPS shield & vessel port security gate
        draw.rectangle([0, 0, 300, 300], fill=(20, 35, 60))
        # Golden security shield
        draw.polygon([(150, 40), (240, 80), (220, 220), (150, 265), (80, 220), (60, 80)], fill=(220, 160, 20))
        draw.polygon([(150, 55), (225, 90), (208, 210), (150, 250), (92, 210), (75, 90)], fill=(30, 45, 75))
        # Key lock
        draw.ellipse([132, 110, 168, 150], fill=(235, 180, 40))
        draw.polygon([(138, 140), (162, 140), (168, 190), (132, 190)], fill=(235, 180, 40))

    elif icon_type == 'marpol':
        # Ocean water & eco globe leaf
        draw.rectangle([0, 0, 300, 300], fill=(5, 100, 120))
        draw.ellipse([50, 50, 250, 250], fill=(16, 163, 74))
        draw.ellipse([65, 65, 235, 235], fill=(10, 140, 190))
        draw.arc([80, 120, 220, 220], start=0, end=180, fill=(16, 163, 74), width=16)

    elif icon_type == 'confined':
        # Tank entrance and gas detector
        draw.rectangle([0, 0, 300, 300], fill=(45, 40, 35))
        draw.ellipse([50, 50, 250, 250], fill=(80, 75, 70))
        draw.ellipse([70, 70, 230, 230], fill=(15, 12, 10))
        # Gas meter device
        draw.rectangle([180, 140, 260, 260], fill=(235, 140, 20))
        draw.rectangle([195, 155, 245, 195], fill=(180, 230, 210))

    elif icon_type == 'imdg':
        # IMDG dangerous cargo container placard
        draw.rectangle([0, 0, 300, 300], fill=(180, 60, 20))
        draw.polygon([(150, 40), (260, 150), (150, 260), (40, 150)], fill=(245, 245, 245))
        draw.polygon([(150, 55), (245, 150), (150, 245), (55, 150)], fill=(235, 40, 30))
        # Skull or Class 3 symbol
        draw.polygon([(150, 80), (190, 160), (110, 160)], fill=(245, 245, 245))

    return img

configs = [
    (1, "amarre", ((0, 40, 90), (220, 100, 30)), 'mooring'),
    (2, "crane", ((25, 35, 50), (70, 85, 105)), 'crane'),
    (3, "report", ((30, 50, 75), (50, 80, 120)), 'report'),
    (4, "electric", ((40, 45, 55), (80, 90, 105)), 'electric'),
    (5, "operations", ((15, 85, 155), (235, 100, 15)), 'operations'),
    (6, "firstaid", ((15, 110, 180), (240, 245, 250)), 'firstaid'),
    (7, "fire", ((180, 40, 20), (250, 180, 20)), 'fire'),
    (8, "survival", ((10, 75, 140), (235, 75, 30)), 'survival'),
    (9, "isps", ((20, 35, 60), (220, 160, 20)), 'isps'),
    (10, "marpol", ((5, 100, 120), (16, 163, 74)), 'marpol'),
    (11, "confined", ((45, 40, 35), (235, 140, 20)), 'confined'),
    (12, "imdg", ((180, 60, 20), (245, 245, 245)), 'imdg'),
]

out_dart = "c:/xampp/htdocs/NCS 4.4 APP/naviera_cruz_app/lib/app/training_images_data.dart"
os.makedirs(os.path.dirname(out_dart), exist_ok=True)

dart_code = ["import 'dart:typed_data';\n"]

for cid, name, theme, icon_type in configs:
    img = draw_thumbnail(cid, name, theme, icon_type)
    from io import BytesIO
    buf = BytesIO()
    img.save(buf, format='PNG')
    b64 = base64.b64encode(buf.getvalue()).decode('utf-8')
    dart_code.append(f"// Thumbnail for course {cid} ({name})\n")
    dart_code.append(f"const String trainingImg{cid}Base64 = '{b64}';\n")
    dart_code.append(f"final Uint8List trainingImg{cid}Bytes = base64Decode(trainingImg{cid}Base64);\n\n")

with open(out_dart, "w", encoding="utf-8") as f:
    f.write("".join(dart_code))

print("Successfully generated training_images_data.dart with 12 thumbnail images!")
