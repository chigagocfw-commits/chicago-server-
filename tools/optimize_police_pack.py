import os
import sys
import shutil
import subprocess
import zlib
import struct
from PIL import Image

RAGE_EXE = os.path.abspath(r'tools\rage-cli\rage.exe')
SQUEEZE_EXE = os.path.abspath(r'tools\squeezeit\squeezeit-x86_64-pc-windows-msvc\squeezeit-cli.exe')
BASE_DIR = os.path.abspath(r'txData\Qbox_C6CA87.base\resources\[customs]\[cars]\a19police\stream')
WORK_ROOT = os.path.abspath(r'tools\work_pack')

def to_pow2(n):
    p = 1
    while p < n:
        p *= 2
    if (p - n) > (n - p // 2) and p // 2 >= 4:
        return p // 2
    return p

def get_ytd_memory(path):
    with open(path, 'rb') as f:
        hdr = f.read(16)
        if len(hdr) < 16 or hdr[:4] != b'RSC7':
            return 0.0
        decomp = zlib.decompress(f.read(), -15)
        return len(decomp) / 1024 / 1024

def inspect_ytd(path):
    with open(path, 'rb') as f:
        hdr = f.read(16)
        decomp = zlib.decompress(f.read(), -15)
    sys_size = 262144
    sys_mem = decomp[:sys_size]
    tex_count = struct.unpack('<H', sys_mem[0x38:0x3a])[0]
    ptr_offset = struct.unpack('<I', sys_mem[0x30:0x34])[0] & 0x00FFFFFF
    ptrs = [struct.unpack('<I', sys_mem[ptr_offset + i * 8 : ptr_offset + i * 8 + 4])[0] & 0x00FFFFFF for i in range(tex_count)]
    res = []
    for p in ptrs:
        name_ptr = struct.unpack('<I', sys_mem[p + 0x28 : p + 0x2c])[0] & 0x00FFFFFF
        name = sys_mem[name_ptr : sys_mem.find(b'\x00', name_ptr)].decode('ascii', errors='ignore')
        width, height = struct.unpack('<HH', sys_mem[p + 0x50 : p + 0x54])
        fmt = sys_mem[p + 0x58 : p + 0x5c]
        fmt_code = fmt[0] if len(fmt) > 0 else 0
        fmt_str = fmt.decode('ascii', errors='ignore') if fmt_code > 32 else hex(fmt_code)
        res.append((name, width, height, fmt_str, fmt_code))
    return res

def optimize_vehicle(src_ytd):
    fn = os.path.basename(src_ytd)
    car_name = os.path.splitext(fn)[0]
    initial_mem = get_ytd_memory(src_ytd)
    print(f"\n==========================================")
    print(f"Optimizing: {fn} (Current memory: {initial_mem:.2f} MiB)")
    print(f"==========================================")

    # 1. Backup
    bak_path = src_ytd + '.bak'
    if not os.path.exists(bak_path):
        shutil.copy2(src_ytd, bak_path)
        print(f"  [+] Backup saved: {bak_path}")
    else:
        print(f"  [*] Backup already exists: {bak_path}")

    car_work = os.path.join(WORK_ROOT, car_name)
    if os.path.exists(car_work):
        shutil.rmtree(car_work, ignore_errors=True)
    os.makedirs(car_work, exist_ok=True)
    export_dir = os.path.join(car_work, 'exported')

    # 2. Export textures
    subprocess.run([RAGE_EXE, 'textures', src_ytd, '-o', export_dir], check=True, capture_output=True)

    # 3. Analyze textures
    tex_list = inspect_ytd(src_ytd)
    replace_files = []

    for name, w, h, fmt_str, fmt_code in tex_list:
        png_path = os.path.join(export_dir, f'{name}.png')
        if not os.path.exists(png_path):
            continue

        needs_action = False
        new_w, new_h = w, h

        # Non-multiple-of-4 check
        if new_w % 4 != 0 or new_h % 4 != 0:
            new_w = to_pow2(new_w)
            new_h = to_pow2(new_h)
            needs_action = True

        # Liveries/Signs max 2048
        if new_w > 2048 or new_h > 2048:
            scale = min(2048 / new_w, 2048 / new_h)
            new_w = to_pow2(int(new_w * scale))
            new_h = to_pow2(int(new_h * scale))
            needs_action = True

        # Equipment / lightbar / dials that are 2048 -> downscale to 1024
        equip_keywords = ['defender', 'emis', 'lights', 'lightbar', 'siren', 'anpr', 'monitor', 'screen']
        if any(k in name.lower() for k in equip_keywords) and (new_w >= 2048 or new_h >= 2048):
            new_w, new_h = 1024, 1024
            needs_action = True

        # Uncompressed 0x15 textures (e.g. A8R8G8B8)
        if fmt_code == 0x15:
            needs_action = True

        if needs_action:
            img = Image.open(png_path)
            if img.size != (new_w, new_h):
                img = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
            out_png = os.path.join(car_work, f'{name}.png')
            img.save(out_png)
            replace_files.append((name, out_png))
            print(f"  [>] Adjusting {name}: {w}x{h} ({fmt_str}) -> {new_w}x{new_h}")

    # 4. Build replacement YTD
    temp_ytd = os.path.join(car_work, 'built.ytd')
    if replace_files:
        build_cmd = [RAGE_EXE, 'textures', 'build', '--from', src_ytd, '--output', temp_ytd, '-f', 'bc3']
        for _, p in replace_files:
            build_cmd.append(p)
        res = subprocess.run(build_cmd, capture_output=True, text=True)
        if res.returncode != 0:
            print(f"  [!] Build error for {fn}: {res.stderr}")
            return initial_mem, initial_mem
    else:
        shutil.copy2(src_ytd, temp_ytd)

    # 5. Squeeze with squeezeit for vehicle rules & odd textures
    sqz_cmd = [SQUEEZE_EXE, '--preset', 'vehicles', temp_ytd]
    subprocess.run(sqz_cmd, capture_output=True)

    # 6. Verify and deploy
    final_mem = get_ytd_memory(temp_ytd)
    print(f"  [*] Memory reduction: {initial_mem:.2f} MiB -> {final_mem:.2f} MiB")

    shutil.copy2(temp_ytd, src_ytd)
    print(f"  [OK] Successfully deployed optimized {fn}")
    return initial_mem, final_mem

def main():
    targets = []
    for dirpath, _, filenames in os.walk(BASE_DIR):
        for fn in filenames:
            if fn.endswith('.ytd') and not fn.endswith('.bak'):
                fp = os.path.join(dirpath, fn)
                mem = get_ytd_memory(fp)
                if mem > 16.0:
                    targets.append((fp, fn, mem))

    targets.sort(key=lambda x: x[2], reverse=True)
    print(f"Starting batch optimization for {len(targets)} oversized vehicles...")

    results = []
    for fp, fn, mem in targets:
        init_m, fin_m = optimize_vehicle(fp)
        results.append((fn, init_m, fin_m))

    # Clean up work root
    shutil.rmtree(WORK_ROOT, ignore_errors=True)

    print("\n" + "=" * 60)
    print(f"{'Vehicle YTD':<25} {'Original':<12} {'Optimized':<12} {'Saved':<10}")
    print("=" * 60)
    total_orig = sum(r[1] for r in results)
    total_fin = sum(r[2] for r in results)
    for fn, init_m, fin_m in results:
        saved = init_m - fin_m
        pct = (saved / init_m * 100) if init_m > 0 else 0
        print(f"{fn:<25} {init_m:>7.2f} MiB  {fin_m:>7.2f} MiB  {saved:>6.2f} MiB ({pct:.0f}%)")
    print("-" * 60)
    total_saved = total_orig - total_fin
    total_pct = (total_saved / total_orig * 100) if total_orig > 0 else 0
    print(f"{'TOTAL':<25} {total_orig:>7.2f} MiB  {total_fin:>7.2f} MiB  {total_saved:>6.2f} MiB ({total_pct:.0f}%)")
    print("=" * 60)

if __name__ == '__main__':
    main()
