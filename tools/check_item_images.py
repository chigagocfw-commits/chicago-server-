import re
import os

items_path = r'txData\Qbox_C6CA87.base\resources\[ox]\ox_inventory\data\items.lua'
images_dir = r'txData\Qbox_C6CA87.base\resources\[ox]\ox_inventory\web\images'

with open(items_path, 'r', encoding='utf-8', errors='ignore') as f:
    txt = f.read()

# match ['item_name'] = { ... }
items = re.findall(r"\[['\"]([a-zA-Z0-9_\-\.]+)['\"]\]\s*=\s*\{([^}]+)\}", txt)

missing_images = []
for name, body in items:
    img_match = re.search(r"image\s*=\s*['\"]([^'\"]+)['\"]", body)
    img_name = img_match.group(1) if img_match else f"{name}.png"
    if not img_name.endswith('.png'):
        img_name += '.png'
    
    img_file = os.path.join(images_dir, img_name)
    if not os.path.exists(img_file):
        missing_images.append((name, img_name))

print(f"Items defined in ox_inventory: {len(items)}")
print(f"Items missing image PNGs in web/images: {len(missing_images)}")
for name, img in missing_images[:30]:
    print(f"  - {name} (missing {img})")

