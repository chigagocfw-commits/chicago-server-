import os
import re

OX_ITEMS_PATH = r'txData\Qbox_C6CA87.base\resources\[ox]\ox_inventory\data\items.lua'

def get_ox_items():
    with open(OX_ITEMS_PATH, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    # Match items defined in ox_inventory: ['item_name'] = {
    matches = re.findall(r"\[['\"]([a-zA-Z0-9_\-\.]+)['\"]\]\s*=\s*\{", content)
    return set(matches)

ox_items = get_ox_items()
print(f'Total items in ox_inventory: {len(ox_items)}')

# Look for resource install/readme files that declare items for ox_inventory or qb-core
resources_dir = r'txData\Qbox_C6CA87.base\resources'
found_item_sources = {}

for root, dirs, files in os.walk(resources_dir):
    for fn in files:
        if fn.endswith(('.lua', '.md', '.txt')):
            fp = os.path.join(root, fn)
            # check if file has item definitions like ['something'] = { label = ...
            try:
                with open(fp, 'r', encoding='utf-8', errors='ignore') as f:
                    txt = f.read()
                # look for pattern ['item'] = { label = ... } or ['item'] = { name = ... }
                matches = re.findall(r"\[['\"]([a-zA-Z0-9_\-\.]+)['\"]\]\s*=\s*\{[^}]*?label\s*=", txt, re.IGNORECASE)
                if matches and fp != os.path.abspath(OX_ITEMS_PATH):
                    diff = set(matches) - ox_items
                    if diff:
                        rel = os.path.relpath(fp, resources_dir)
                        found_item_sources[rel] = sorted(list(diff))
            except:
                pass

print(f'\nFound {len(found_item_sources)} source files with items missing from ox_inventory:')
for rel, missing in found_item_sources.items():
    print(f'\nSource: {rel} ({len(missing)} missing items)')
    for it in missing[:15]:
        print(f'  - {it}')
    if len(missing) > 15:
        print(f'  ... and {len(missing) - 15} more')

