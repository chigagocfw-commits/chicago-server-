import re
import os

def get_items(path):
    if not os.path.exists(path):
        return set()
    with open(path, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    matches = re.findall(r"\[['\"]([a-zA-Z0-9_\-\.]+)['\"]\]\s*=", content)
    return set(matches)

ox_items = get_items(r'txData\Qbox_C6CA87.base\resources\[ox]\ox_inventory\data\items.lua')
qbx_items = get_items(r'txData\Qbox_C6CA87.base\resources\[qbx]\qbx_core\shared\items.lua')

print(f'ox_inventory total items: {len(ox_items)}')
print(f'qbx_core total items: {len(qbx_items)}')

missing_in_ox = qbx_items - ox_items
print(f'Items in qbx_core but MISSING in ox_inventory: {len(missing_in_ox)}')
for item in sorted(list(missing_in_ox))[:40]:
    print(f'  - {item}')

