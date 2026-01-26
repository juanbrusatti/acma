import subprocess
import os
import json
import zipfile
import io
import tempfile
import shutil

class Optimizer:
    def __init__(self):
        self.base_dir = os.path.dirname(os.path.abspath(__file__))
        self.optimizer_script = os.path.join(self.base_dir, 'cut_optimizer.py')
    
    def optimize(self, pieces_to_cut, stock):
        """
        Ejecuta el optimizador con los datos proporcionados
        Returns: (success, result_data, zip_bytes)
        """
        try:
            # Crear directorios temporales
            temp_dir = tempfile.mkdtemp()
            output_csv = os.path.join(temp_dir, 'cutting_plan.csv')
            output_visuals_dir = os.path.join(temp_dir, 'output_visuals')
            os.makedirs(output_visuals_dir, exist_ok=True)
            
            # Preparar datos de entrada
            input_data = {
                "pieces_to_cut": pieces_to_cut,
                "stock": stock
            }
            
            # Ejecutar optimizador
            process = subprocess.run(
                ['python3', self.optimizer_script],
                input=json.dumps(input_data),
                text=True,
                capture_output=True,
                cwd=temp_dir
            )
            
            if process.returncode != 0:
                return False, f"Optimizer failed: {process.stderr}", None
            
            # Leer resultados
            result_data = None
            zip_bytes = None
            
            # Leer CSV si existe
            if os.path.exists(output_csv):
                with open(output_csv, 'r') as f:
                    result_data = f.read()
            
            # Crear ZIP con visuals si existen
            if os.path.exists(output_visuals_dir) and os.listdir(output_visuals_dir):
                zip_buffer = io.BytesIO()
                with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zip_file:
                    for root, dirs, files in os.walk(output_visuals_dir):
                        for file in files:
                            file_path = os.path.join(root, file)
                            arcname = os.path.relpath(file_path, output_visuals_dir)
                            zip_file.write(file_path, arcname)
                zip_bytes = zip_buffer.getvalue()
                zip_buffer.close()
            
            # Limpiar directorio temporal
            shutil.rmtree(temp_dir)
            
            return True, result_data, zip_bytes
            
        except Exception as e:
            return False, f"Error: {str(e)}", None
