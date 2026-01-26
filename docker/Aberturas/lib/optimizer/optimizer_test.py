import json
import os
import sys
import subprocess
import shutil
from pathlib import Path

BASE_DIR = Path(__file__).parent
OPTIMIZER = BASE_DIR / 'cut_optimizer.py'
OUTPUT_CSV = BASE_DIR / 'output_plan' / 'cutting_plan.csv'
OUTPUT_VISUALS = BASE_DIR / 'output_visuals'
OUTPUT_PLAN_DIR = BASE_DIR / 'output_plan'
VISUALS_RUNS_DIR = BASE_DIR / 'output_visuals'

# Ensure output directories exist
OUTPUT_PLAN_DIR.mkdir(exist_ok=True)
VISUALS_RUNS_DIR.mkdir(exist_ok=True)

# Define sample combinations (color, glass_type, thickness)
combos = [
    ("INC", "LAM", "3+3"),
    ("INC", "LAM", "4+4"),
    ("CLR", "MONO", "6"),
    ("BRZ", "LAM", "3+3"),
    ("VER", "DVH", "3+3"),
]

# Build full input (pieces & stock)
pieces = []
stock = {"glassplates": [], "scraps": []}

pid = 1
for color, gtype, thick in combos:
    for i in range(4):
        pieces.append({
            "id": f"V-{pid}",
            "width": 450 + i*20,
            "height": 320 + i*25,
            "quantity": 1,
            "color": color,
            "glass_type": gtype,
            "thickness": thick,
            "type_opening": "A"
        })
        pid += 1

# Stock: one large plate + one scrap per combo
gid = 1
sid = 1
for color, gtype, thick in combos:
    stock["glassplates"].append({
        "id": gid, "width": 2200, "height": 1600, "color": color,
        "glass_type": gtype, "thickness": thick, "quantity": 1
    })
    gid += 1
    stock["scraps"].append({
        "id": sid, "width": 900, "height": 700, "color": color,
        "glass_type": gtype, "thickness": thick
    })
    sid += 1


def combo_label(color, gtype, thick):
    label = f"{gtype}_{thick}_{color}"
    return label.replace(' ', '-').replace('/', '-').replace('\\', '-')


def run_combo(color, gtype, thick):
    # Filter pieces and stock for this combo
    pcs = [p for p in pieces if p["color"] == color and p["glass_type"] == gtype and p["thickness"] == thick]
    gps = [g for g in stock["glassplates"] if g["color"] == color and g["glass_type"] == gtype and g["thickness"] == thick]
    scs = [s for s in stock["scraps"] if s["color"] == color and s["glass_type"] == gtype and s["thickness"] == thick]

    payload = json.dumps({"pieces_to_cut": pcs, "stock": {"glassplates": gps, "scraps": scs}})

    # Run optimizer with stdin
    res = subprocess.run(
        [sys.executable, str(OPTIMIZER), '--stdin'],
        cwd=str(BASE_DIR),
        input=payload.encode('utf-8'),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=120
    )
    if res.returncode != 0:
        print(f"[ERROR] Optimizer failed for {color}/{gtype}/{thick}:\n{res.stderr.decode('utf-8')}")
        return False

    # Save CSV uniquely
    label = combo_label(color, gtype, thick)
    if OUTPUT_CSV.exists():
        dst_csv = OUTPUT_PLAN_DIR / f"cutting_plan_{label}.csv"
        shutil.copyfile(OUTPUT_CSV, dst_csv)

    # Save PDFs into a per-combo folder
    run_folder = VISUALS_RUNS_DIR / label
    run_folder.mkdir(parents=True, exist_ok=True)
    if OUTPUT_VISUALS.exists():
        for f in OUTPUT_VISUALS.glob('*.pdf'):
            shutil.copyfile(f, run_folder / f.name)

    return True


if __name__ == '__main__':
    print("[TEST] Running optimizer per combo and collecting outputs...")
    ok = True
    for color, gtype, thick in combos:
        print(f"  -> {color}/{gtype}/{thick}")
        if not run_combo(color, gtype, thick):
            ok = False

    # Summary
    csvs = sorted(OUTPUT_PLAN_DIR.glob('cutting_plan_*.csv'))
    print(f"[RESULT] CSVs generated: {len(csvs)}")
    for c in csvs[:10]:
        print("   ", c.name)

    for color, gtype, thick in combos:
        label = combo_label(color, gtype, thick)
        folder = VISUALS_RUNS_DIR / label
        pdfs = sorted(folder.glob('*.pdf'))
        print(f"[RESULT] PDFs for {label}: {len(pdfs)} files in {folder.relative_to(BASE_DIR)}")

    if ok:
        print("[OK] Test completed.")
    else:
        print("[FAIL] Some combos failed.")
