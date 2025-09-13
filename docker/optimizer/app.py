import subprocess
import os
import io
import zipfile
from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse, JSONResponse

app = FastAPI()

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
OPTIMIZER_SCRIPT = os.path.join(BASE_DIR, 'cut_optimizer.py')
OUTPUT_CSV = os.path.join(BASE_DIR, 'output_plan', 'cutting_plan.csv')
OUTPUT_VISUALS_DIR = os.path.join(BASE_DIR, 'output_visuals')
INPUTS_JSON = os.path.join(BASE_DIR, 'inputs.json')

@app.post('/optimize')
async def run_optimize():
    # Ensure inputs.json exists
    if not os.path.exists(INPUTS_JSON):
        raise HTTPException(status_code=400, detail='inputs.json not found')

    # Run the optimizer script without args (it will use inputs.json)
    try:
        # Suppress stdout/stderr by redirecting to DEVNULL
        result = subprocess.run(
            ['python', OPTIMIZER_SCRIPT, '--inp', 'inputs.json'],
            cwd=BASE_DIR,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=120
        )
    except subprocess.TimeoutExpired:
        raise HTTPException(status_code=500, detail='Optimizer timed out')

    if result.returncode != 0:
        raise HTTPException(status_code=500, detail='Optimizer failed')

    # Verify images exist
    if not os.path.isdir(OUTPUT_VISUALS_DIR):
        raise HTTPException(status_code=500, detail='No visuals generated')

    image_files = [f for f in os.listdir(OUTPUT_VISUALS_DIR) if f.lower().endswith('.png')]
    if not image_files:
        raise HTTPException(status_code=500, detail='No PNG images generated')

    # Create in-memory zip
    zip_buffer = io.BytesIO()
    with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zf:
        for img in image_files:
            full_path = os.path.join(OUTPUT_VISUALS_DIR, img)
            zf.write(full_path, arcname=img)
        if os.path.exists(OUTPUT_CSV):
            zf.write(OUTPUT_CSV, arcname='cutting_plan.csv')
    zip_buffer.seek(0)

    return StreamingResponse(zip_buffer, media_type='application/zip', headers={
        'Content-Disposition': 'attachment; filename="cutting_plan_visuals.zip"'
    })

@app.get('/health')
async def health():
    return {'status': 'ok'}
