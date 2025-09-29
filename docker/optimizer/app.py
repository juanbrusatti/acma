import subprocess
import os
import io
import json
import zipfile
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import StreamingResponse, JSONResponse
import traceback
from fastapi import Request
import sys


app = FastAPI()

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
OPTIMIZER_SCRIPT = os.path.join(BASE_DIR, 'cut_optimizer.py')
OUTPUT_CSV = os.path.join(BASE_DIR, 'output_plan', 'cutting_plan.csv')
OUTPUT_VISUALS_DIR = os.path.join(BASE_DIR, 'output_visuals')

@app.post('/optimize')
async def run_optimize(request: Request):
    print("[LOG] POST /optimize iniciado")
    try:
        # read the JSON body
        body = await request.json()
        print(f"[LOG] Body recibido: {json.dumps(body)[:200]}...")

        if 'pieces_to_cut' not in body or 'stock' not in body:
            print("[ERROR] Body debe tener 'pieces_to_cut' y 'stock'")
            raise HTTPException(status_code=400, detail="Body must contain 'pieces_to_cut' and 'stock'")
        print(f"[LOG] Datos de entrada validados")

        # Create in-memory zip for the return to Rails
        zip_buffer = io.BytesIO()

        input = json.dumps({
            'pieces_to_cut': body['pieces_to_cut'],
            'stock': body['stock']
        })

        # Build combinations for color/thickness/glass_type
        optimization_inputs = create_optimizations_objects(input)

        for pieces_to_cut, stock in optimization_inputs:
            optimize(pieces_to_cut, stock, zip_buffer)


        zip_buffer.seek(0)

        print("[LOG] Respondiendo con ZIP")
        return StreamingResponse(zip_buffer, media_type='application/zip', headers={
            'Content-Disposition': 'attachment; filename="cutting_plan_visuals.zip"'
        })
    except Exception as e:
        print("[ERROR] Excepción en /optimize:")
        print(e)
        traceback.print_exc()
        raise HTTPException(status_code=500, detail='Optimizer failed')

@app.get('/health')
async def health():
    return {'status': 'ok'}

def build_combinations(pieces):
    """Return unique (color, glass_type, thickness) combos from pieces_to_cut."""
    combos = set()
    for p in pieces or []:
        combos.add((p.get('color'), p.get('glass_type'), p.get('thickness')))
    return combos


def create_optimizations_objects(input_data):
    """Create (pieces_to_cut, stock) tuples per (color, glass_type, thickness) combo.

    input_data can be a JSON string or a dict with keys 'pieces_to_cut' and 'stock'.
    Only combos that exist in pieces_to_cut are returned.
    """

    pieces = input_data.get('pieces_to_cut') or []
    stock = input_data.get('stock') or {}
    glassplates = stock.get('glassplates') or []
    scraps = stock.get('scraps') or []

    combos = build_combinations(pieces)
    results = []

    for (color, glass_type, thickness) in combos:
        # Filter pieces by combo
        pcs_combo = [p for p in pieces
                     if p.get('color') == color and p.get('glass_type') == glass_type and p.get('thickness') == thickness]

        # Filter stock by the same combo
        gps_combo = [g for g in glassplates
                     if g.get('color') == color and g.get('glass_type') == glass_type and g.get('thickness') == thickness]
        scs_combo = [s for s in scraps
                     if s.get('color') == color and s.get('glass_type') == glass_type and s.get('thickness') == thickness]

        if pcs_combo:
            results.append((pcs_combo, { 'glassplates': gps_combo, 'scraps': scs_combo }))

    return results

def optimize(pieces_to_cut, stock, zip_buffer: io.BytesIO):
    """
    Execute the optimizer and add to the zip the CSV and the pdf
    """
    # create the optimizer input
    optimizer_input = json.dumps({
        'pieces_to_cut': pieces_to_cut,
        'stock': stock
    })

    # Execute the optimizer
    try:
        result = subprocess.run(
            [sys.executable, OPTIMIZER_SCRIPT, '--stdin'],
            cwd=BASE_DIR,
            input=optimizer_input.encode('utf-8'),
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=120
        )
    except subprocess.TimeoutExpired:
        raise HTTPException(status_code=500, detail='Optimizer timed out')

    if result.returncode != 0:
        raise HTTPException(status_code=500, detail='Optimizer failed')

    # Verify the outputs and append them to the zip
    if not os.path.isdir(OUTPUT_VISUALS_DIR):
        raise HTTPException(status_code=500, detail='No visuals generated')

    # Helper to derive a label from the combination (color, glass_type, thickness) for csv name
    def _combo_label(pcs):
        if not pcs:
            return 'unknown'
        sample = pcs[0] or {}
        color = str(sample.get('color') or 'NA')
        gtype = str(sample.get('glass_type') or 'NA')
        thick = str(sample.get('thickness') or 'NA')
        label = f"{gtype}_{thick}_{color}"
        # Sanitize for file names
        return (
            label.replace(' ', '-')
                 .replace('/', '-')
                 .replace('\\', '-')
                 .replace('__', '_')
        )

    combo_label = _combo_label(pieces_to_cut)

    # Add PDFs and CSV to the ZIP
    with zipfile.ZipFile(zip_buffer, 'a', zipfile.ZIP_DEFLATED) as zf:
        # Generated PDFs
        for file in os.listdir(OUTPUT_VISUALS_DIR):
            if file.endswith('.pdf'):
                full_path = os.path.join(OUTPUT_VISUALS_DIR, file)
                zf.write(full_path, arcname=file)

        # CSV (if exists)
        if os.path.exists(OUTPUT_CSV):
            csv_name = f"cutting_plan_{combo_label}.csv"
            zf.write(OUTPUT_CSV, arcname=csv_name)
