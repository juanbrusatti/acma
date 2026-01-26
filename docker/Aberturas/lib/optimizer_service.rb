require 'json'
require 'tempfile'
require 'open3'

class OptimizerService
  def initialize
    @optimizer_path = Rails.root.join('lib', 'optimizer', 'optimizer_lib.py')
  end

  def optimize(pieces_to_cut, stock)
    begin
      # Crear script temporal para llamar al optimizador
      temp_script = create_temp_script(pieces_to_cut, stock)
      
      # Ejecutar el optimizador Python
      stdout, stderr, status = Open3.capture3(
        "python3",
        temp_script.path,
        chdir: File.dirname(@optimizer_path)
      )
      
      temp_script.close
      temp_script.unlink
      
      unless status.success?
        Rails.logger.error "Optimizer failed: #{stderr}"
        return { success: false, error: "Optimizer execution failed: #{stderr}" }
      end
      
      # Parsear resultado
      result = JSON.parse(stdout)
      
      if result['success']
        {
          success: true,
          data: result['data'],
          zip_bytes: result['zip_bytes']
        }
      else
        {
          success: false,
          error: result['error']
        }
      end
      
    rescue => e
      Rails.logger.error "Optimizer service error: #{e.message}"
      { success: false, error: "Service error: #{e.message}" }
    end
  end

  private

  def create_temp_script(pieces_to_cut, stock)
    script = Tempfile.new(['optimizer_call', '.py'])
    script.write(<<~PYTHON)
      #!/usr/bin/env python3
      import sys
      import os
      import json
      import re
      
      # Agregar el directorio del optimizador al path
      sys.path.insert(0, '#{File.dirname(@optimizer_path)}')
      
      from optimizer_lib import Optimizer
      
      # Datos de entrada (convertir Ruby false/true a Python False/True)
      pieces_to_cut_str = #{pieces_to_cut.to_json}
      stock_str = #{stock.to_json}
      
      # Reemplazar SOLO valores booleanos, no los que están en strings
      # Usar regex para reemplazar :false, :true, "false", "true" como valores JSON
      pieces_to_cut_str = re.sub(r':\s*false\b', ': False', pieces_to_cut_str)
      pieces_to_cut_str = re.sub(r':\s*true\b', ': True', pieces_to_cut_str)
      stock_str = re.sub(r':\s*false\b', ': False', stock_str)
      stock_str = re.sub(r':\s*true\b', ': True', stock_str)
      
      pieces_to_cut = json.loads(pieces_to_cut_str)
      stock = json.loads(stock_str)
      
      # Ejecutar optimizador
      optimizer = Optimizer()
      success, result_data, zip_bytes = optimizer.optimize(pieces_to_cut, stock)
      
      # Preparar salida
      output = {
          'success': success,
          'data': result_data,
          'zip_bytes': zip_bytes.hex() if zip_bytes else None,
          'error': result_data if not success else None
      }
      
      print(json.dumps(output))
    PYTHON
    script.flush
    script.chmod(0755)  # Hacer el script ejecutable
    script
  end
end
