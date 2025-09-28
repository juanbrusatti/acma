import subprocess
import os
import io
import json
import zipfile
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import StreamingResponse, JSONResponse
import traceback
from fastapi import Request


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
        # Guardar input.json y stock_data.json
        if 'pieces_to_cut' not in body or 'stock' not in body:
            print("[ERROR] Body debe tener 'pieces_to_cut' y 'stock'")
            raise HTTPException(status_code=400, detail="Body must contain 'pieces_to_cut' and 'stock'")
        print(f"[LOG] input.json y stock_data.json guardados")

        # Guarda en pieces_to_cut y stock lo que recibimos del body 
        optimizer_input = json.dumps({
            'pieces_to_cut': body['pieces_to_cut'],
            'stock': body['stock']
        })
        print("[LOG] Ejecutando optimizador...")
        try:
            result = subprocess.run(
                ['python', OPTIMIZER_SCRIPT, '--stdin'], # Basicamente le dice al optimizador que lea de stdin y no de archivos, en stdin esta el json con pieces_to_cut y stock
                cwd=BASE_DIR,
                input=optimizer_input.encode('utf-8'),
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                timeout=120
            )
        except subprocess.TimeoutExpired:
            print("[ERROR] Optimizer timed out")
            raise HTTPException(status_code=500, detail='Optimizer timed out')

        print(f"[LOG] Optimizer returncode: {result.returncode}")
        if result.returncode != 0:
            print("[ERROR] Optimizer failed")
            raise HTTPException(status_code=500, detail='Optimizer failed')

        # Verify visuals exist
        if not os.path.isdir(OUTPUT_VISUALS_DIR):
            print(f"[ERROR] {OUTPUT_VISUALS_DIR} no existe")
            raise HTTPException(status_code=500, detail='No visuals generated')

        # Create in-memory zip
        zip_buffer = io.BytesIO()
        with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zf:
            # Agregar PDFs
            for file in os.listdir(OUTPUT_VISUALS_DIR):
                if file.endswith(".pdf"):
                    full_path = os.path.join(OUTPUT_VISUALS_DIR, file)
                    zf.write(full_path, arcname=file)
            if os.path.exists(OUTPUT_CSV):
                zf.write(OUTPUT_CSV, arcname='cutting_plan.csv')


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
