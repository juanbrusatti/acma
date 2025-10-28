import subprocess
import os
import io
import json
import zipfile
import csv
import uuid
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import StreamingResponse, JSONResponse, Response
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

        # Optimize each build and collect CSV summaries
        global_result = {
            "new_scraps": {},
            "deleted_stock": [],
            "deleted_scrap": []
        }
        for pieces_to_cut, stock in optimization_inputs:
            optimizer_result = optimize(pieces_to_cut, stock, zip_buffer)

            # Acumulamos resultados
            global_result["new_scraps"].update(optimizer_result.get("new_scraps", {}))
            global_result["deleted_stock"].extend(optimizer_result.get("deleted_stock", []))
            global_result["deleted_scrap"].extend(optimizer_result.get("deleted_scrap", []))

        # Esto es solo para verificar, hay que sacarlo después
        with zipfile.ZipFile(zip_buffer, 'a', zipfile.ZIP_DEFLATED) as zf:
            zf.writestr(
                "result.json",
                json.dumps(global_result, indent=2, ensure_ascii=False)
            )

        # Build multipart/mixed response with JSON and ZIP as separate parts
        zip_buffer.seek(0)
        zip_bytes = zip_buffer.getvalue()

        boundary = f"cutplan-{uuid.uuid4().hex}"
        boundary_bytes = boundary.encode('utf-8')
        CRLF = b"\r\n"

        json_bytes = json.dumps(global_result, ensure_ascii=False).encode('utf-8')

        body = bytearray()
        body.extend(b"--" + boundary.encode() + CRLF)
        body.extend(b"Content-Type: application/json; charset=utf-8" + CRLF)
        body.extend(b"Content-Disposition: inline; name=\"result\"" + CRLF + CRLF)
        body.extend(json_bytes + CRLF)

        body.extend(b"--" + boundary.encode() + CRLF)
        body.extend(b"Content-Type: application/zip" + CRLF)
        body.extend(b"Content-Disposition: attachment; filename=\"Plan de corte.zip\"" + CRLF + CRLF)
        body.extend(zip_bytes + CRLF)
        body.extend(b"--" + boundary.encode() + b"--" + CRLF)
        # End boundary
        body.extend(b"--" + boundary_bytes + b"--" + CRLF)

        print("[LOG] Respondiendo con multipart (JSON + ZIP)")
        return Response(content=bytes(body), media_type=f"multipart/mixed; boundary={boundary}")
    
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

    # Allow JSON string or dict
    if isinstance(input_data, str):
        try:
            input_data = json.loads(input_data)
        except Exception:
            raise HTTPException(status_code=400, detail='Invalid JSON in create_optimizations_objects')

    if not isinstance(input_data, dict):
        raise HTTPException(status_code=400, detail='Invalid payload for create_optimizations_objects')

    pieces = input_data.get('pieces_to_cut') or []
    stock = input_data.get('stock') or {}
    glassplates = stock.get('glassplates') or []
    scraps = stock.get('scraps') or []

    combos = build_combinations(pieces)
    results = []

    for (color, glass_type, thickness) in combos:

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
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=120
        )
    except subprocess.TimeoutExpired:
        raise HTTPException(status_code=500, detail='Optimizer timed out')

    if result.returncode != 0:
        stdout_tail = (result.stdout or b"").decode('utf-8', errors='replace')[-2000:]
        stderr_tail = (result.stderr or b"").decode('utf-8', errors='replace')[-4000:]
        print("[ERROR] Optimizer process failed")
        if stdout_tail.strip():
            print(f"[ERROR] Optimizer stdout (tail):\n{stdout_tail}")
        if stderr_tail.strip():
            print(f"[ERROR] Optimizer stderr (tail):\n{stderr_tail}")
        raise HTTPException(status_code=500, detail='Optimizer failed')

    stdout_data = result.stdout.decode('utf-8', errors='replace').strip()
    print("[DEBUG] STDOUT completo del optimizador:")
    print(stdout_data)
    try:
        # Buscar la última línea JSON válida en el output
        lines = stdout_data.splitlines()
        json_line = None
        for line in reversed(lines):
            line = line.strip()
            if line.startswith('{') and line.endswith('}'): # encontramos el json que nos interesa
                json_line = line
                break
        if json_line:
            print("[DEBUG] Última línea JSON encontrada:")
            print(json_line)
            optimizer_result = json.loads(json_line)
        else:
            optimizer_result = {}
    except Exception as e:
        print(f"[WARN] No se pudo parsear JSON del optimizador: {e}")
        optimizer_result = {}
            
    except Exception as e:
        print(f"[WARN] No se pudo parsear JSON del optimizador: {e}")
        optimizer_result = {}

    # Agregar PDFs y CSV al ZIP
    with zipfile.ZipFile(zip_buffer, 'a', zipfile.ZIP_DEFLATED) as zf:
        for root, _, files in os.walk(OUTPUT_VISUALS_DIR):
            for file in files:
                if file.endswith('.pdf'):
                    full_path = os.path.join(root, file)
                    arcname = os.path.relpath(full_path, OUTPUT_VISUALS_DIR)
                    zf.write(full_path, arcname=arcname)

        if os.path.exists(OUTPUT_CSV):
            zf.write(OUTPUT_CSV, arcname="cutting_plan.csv")

    # Retornamos solo el resultado JSON
    return optimizer_result
