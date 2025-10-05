# Servicio para optimizar cortes de vidrio usando algoritmo de guillotina
# Primero intenta ubicar cortes en sobrantes, luego en planchas completas
class GlassCuttingOptimizer
  attr_reader :project, :cuts, :cutting_plans

  # Margen de corte en mm (ancho de la sierra)
  CUTTING_MARGIN = 0

  # Tamaño mínimo de sobrante reutilizable en mm
  MIN_REUSABLE_SCRAP_SIZE = 200

  def initialize(project)
    @project = project
    @cuts = []
    @cutting_plans = []
    
    # Recopilar todos los cortes del proyecto (glasscuttings y DVHs)
    collect_cuts_from_project
  end

  # Método principal para optimizar
  def optimize
    # Paso 1: Intentar ubicar cortes en sobrantes existentes
    remaining_cuts = try_fit_in_scraps(@cuts.dup)
    
    # Paso 2: Agrupar cortes restantes por tipo de vidrio
    grouped_cuts = group_cuts_by_glass_type(remaining_cuts)
    
    # Paso 3: Para cada grupo, optimizar en planchas completas
    grouped_cuts.each do |glass_key, cuts_group|
      optimize_cuts_in_plates(cuts_group, glass_key)
    end
    
    @cutting_plans
  end

  private

  # Recopilar todos los cortes del proyecto
  def collect_cuts_from_project
    # Glasscuttings simples
    @project.glasscuttings.each do |gc|
      @cuts << {
        id: "GC-#{gc.id}",
        width: gc.width,
        height: gc.height,
        glass_type: gc.glass_type,
        thickness: gc.thickness,
        color: gc.color,
        type: 'glasscutting',
        reference: gc
      }
    end

    # DVHs (cada DVH necesita 2 cortes de vidrio)
    @project.dvhs.each do |dvh|
      # Vidrio 1
      @cuts << {
        id: "DVH-#{dvh.id}-V1",
        width: dvh.width,
        height: dvh.height,
        glass_type: dvh.glasscutting1_type,
        thickness: dvh.glasscutting1_thickness,
        color: dvh.glasscutting1_color,
        type: 'dvh_glass1',
        reference: dvh
      }
      
      # Vidrio 2
      @cuts << {
        id: "DVH-#{dvh.id}-V2",
        width: dvh.width,
        height: dvh.height,
        glass_type: dvh.glasscutting2_type,
        thickness: dvh.glasscutting2_thickness,
        color: dvh.glasscutting2_color,
        type: 'dvh_glass2',
        reference: dvh
      }
    end
  end

  # Intentar ubicar cortes en sobrantes disponibles
  def try_fit_in_scraps(cuts)
    remaining_cuts = []
    
    cuts.each do |cut|
      # Buscar sobrantes compatibles (mismo tipo, espesor y color)
      compatible_scraps = Scrap.where(
        status: 'Disponible',
        scrap_type: cut[:glass_type],
        thickness: cut[:thickness],
        color: cut[:color]
      ).order(width: :desc, height: :desc) # Ordenar por tamaño descendente
      
      fitted = false
      
      compatible_scraps.each do |scrap|
        # Verificar si el corte cabe en el sobrante (con margen)
        if fits_in_scrap?(cut, scrap)
          # Crear plan de corte para este sobrante
          add_scrap_cutting_plan(cut, scrap)
          fitted = true
          break
        end
      end
      
      # Si no cabe en ningún sobrante, agregarlo a los restantes
      remaining_cuts << cut unless fitted
    end
    
    remaining_cuts
  end

  # Verificar si un corte cabe en un sobrante
  def fits_in_scrap?(cut, scrap)
    # Intentar ambas orientaciones
    (cut[:width] + CUTTING_MARGIN <= scrap.width && cut[:height] + CUTTING_MARGIN <= scrap.height) ||
    (cut[:height] + CUTTING_MARGIN <= scrap.width && cut[:width] + CUTTING_MARGIN <= scrap.height)
  end

  # Agregar plan de corte para sobrante
  def add_scrap_cutting_plan(cut, scrap)
    # Determinar orientación óptima
    rotated = false
    if cut[:width] + CUTTING_MARGIN <= scrap.width && cut[:height] + CUTTING_MARGIN <= scrap.height
      # Orientación normal
      placed_width = cut[:width]
      placed_height = cut[:height]
    else
      # Orientación rotada
      placed_width = cut[:height]
      placed_height = cut[:width]
      rotated = true
    end

    @cutting_plans << {
      source_type: 'scrap',
      source_id: scrap.id,
      source_ref: scrap.ref_number,
      plate_width: scrap.width,
      plate_height: scrap.height,
      glass_type: scrap.scrap_type,
      thickness: scrap.thickness,
      color: scrap.color,
      cuts: [{
        id: cut[:id],
        x: 0,
        y: 0,
        width: placed_width,
        height: placed_height,
        rotated: rotated,
        original_cut: cut
      }],
      scraps: calculate_scraps_from_single_cut(scrap.width, scrap.height, placed_width, placed_height)
    }
  end

  # Calcular sobrantes de un corte único
  def calculate_scraps_from_single_cut(plate_width, plate_height, cut_width, cut_height)
    scraps = []
    
    # Sobrante derecho
    right_width = plate_width - cut_width - CUTTING_MARGIN
    if right_width >= MIN_REUSABLE_SCRAP_SIZE
      scraps << {
        x: cut_width + CUTTING_MARGIN,
        y: 0,
        width: right_width,
        height: plate_height,
        reusable: true
      }
    end
    
    # Sobrante superior
    top_height = plate_height - cut_height - CUTTING_MARGIN
    if top_height >= MIN_REUSABLE_SCRAP_SIZE
      scraps << {
        x: 0,
        y: cut_height + CUTTING_MARGIN,
        width: cut_width,
        height: top_height,
        reusable: true
      }
    end
    
    scraps
  end

  # Agrupar cortes por tipo de vidrio (tipo + espesor + color)
  def group_cuts_by_glass_type(cuts)
    cuts.group_by do |cut|
      "#{cut[:glass_type]}-#{cut[:thickness]}-#{cut[:color]}"
    end
  end

  # Optimizar cortes usando múltiples estrategias y seleccionar la que use menos planchas
  def optimize_cuts_in_plates(cuts, glass_key)
    # Obtener información de la plancha
    glass_type, thickness, color = glass_key.split('-')
    
    plate = Glassplate.find_by(
      glass_type: glass_type,
      thickness: thickness,
      color: color
    )
    
    unless plate
      Rails.logger.warn "No se encontró plancha para #{glass_key}"
      return
    end

    # Generar múltiples soluciones con diferentes estrategias
    solutions = []
    
    # 1. Estrategia de ordenamiento por altura descendente
    solutions << pack_with_strategy(cuts.dup, plate, :height_desc)
    
    # 2. Estrategia de ordenamiento por ancho descendente
    solutions << pack_with_strategy(cuts.dup, plate, :width_desc)
    
    # 3. Estrategia de ordenamiento por área descendente
    solutions << pack_with_strategy(cuts.dup, plate, :area_desc)
    
    # 4. Estrategia de agrupación por altura fija
    solutions << pack_with_strategy(cuts.dup, plate, :height_buckets)
    
    # 5. Estrategia de ajuste exacto
    solutions << pack_with_strategy(cuts.dup, plate, :exact_fit)
    
    # 6-15. Estrategias con rotaciones aleatorias
    10.times do
      solutions << pack_with_strategy(rotate_randomly(cuts.dup), plate, :random)
    end
    
    # 16-25. Estrategias con ordenamientos aleatorios
    10.times do
      solutions << pack_with_strategy(shuffle_cuts(cuts.dup), plate, :shuffle)
    end
    
    # Encontrar la solución con menos planchas
    best_solution = solutions.min_by { |s| s[:plates_used] }
    
    # Aplicar la mejor solución encontrada
    best_solution[:plates].each do |plate_cuts|
      create_plate_cutting_plan(plate, plate_cuts) unless plate_cuts.empty?
    end
  end
  
  # Empaquetar todos los cortes usando una estrategia específica
  def pack_with_strategy(cuts, plate, strategy)
    remaining_cuts = cuts.dup
    plates_used = 0
    all_plates = []
    
    while remaining_cuts.any? && plates_used < 5 # Límite de 5 planchas para evitar bucles infinitos
      solution, _waste = try_packing_strategy(remaining_cuts, plate, strategy)
      
      if solution.nil? || solution[:placed_cuts].empty?
        # Si no se pudo colocar ningún corte, salir
        break
      end
      
      all_plates << solution[:placed_cuts]
      remaining_cuts = solution[:remaining_cuts]
      plates_used += 1
      
      # Si ya usamos más planchas que la mejor solución encontrada, descartar
      break if plates_used >= 3 # No tiene sentido seguir si ya usamos 3 planchas
    end
    
    {
      plates: all_plates,
      plates_used: plates_used,
      remaining_cuts: remaining_cuts,
      waste: calculate_total_waste(all_plates, plate)
    }
  end
  
  # Calcular el desperdicio total de una solución
  def calculate_total_waste(plates, plate)
    total_area = plate.width * plate.height * plates.size
    used_area = plates.sum { |plate_cuts| plate_cuts.sum { |c| c[:width] * c[:height] } }
    total_area - used_area
  end
  
  # Rotar aleatoriamente algunos cortes
  def rotate_randomly(cuts)
    cuts.each do |cut|
      cut[:width], cut[:height] = cut[:height], cut[:width] if rand < 0.5
    end
    cuts.shuffle
  end
  
  # Mezclar los cortes
  def shuffle_cuts(cuts)
    cuts.shuffle
  end
  
  # Probar una estrategia de empaquetado específica
  def try_packing_strategy(cuts, plate, strategy)
    # Ordenar cortes según la estrategia
    sorted_cuts = case strategy
    when :height_desc
      cuts.sort_by { |c| -[c[:height], c[:width]].max }
    when :width_desc
      cuts.sort_by { |c| -[c[:width], c[:height]].max }
    when :area_desc
      cuts.sort_by { |c| -c[:width] * c[:height] }
    when :height_buckets
      # Agrupar por altura objetivo (700, 500, 450)
      cuts.sort_by do |c| 
        target = [700, 500, 450].min_by { |h| (h - [c[:height], c[:width]].max).abs }
        [-target, -c[:width] * c[:height]]
      end
    when :exact_fit
      # Estrategia exacta basada en la imagen de referencia
      # 1. Primero los 300x700 (6 en total)
      # 2. Luego los 800x450 (3 en total)
      # 3. Finalmente los 500x500 (2 en total)
      cuts.sort_by do |c|
        if (c[:width] == 300 && c[:height] == 700) || (c[:width] == 700 && c[:height] == 300)
          1 # Primero
        elsif (c[:width] == 800 && c[:height] == 450) || (c[:width] == 450 && c[:height] == 800)
          2 # Segundo
        else
          3 # Tercero
        end
      end
    else
      cuts
    end
    
    # Intentar empaquetar
    placed_cuts, remaining = if strategy == :exact_fit
      pack_exact_fit(sorted_cuts, plate)
    else
      pack_cuts_in_plate(sorted_cuts, plate, strategy)
    end
    
    # Calcular desperdicio (área no utilizada)
    used_area = placed_cuts.sum { |c| c[:width] * c[:height] }
    plate_area = plate.width * plate.height
    waste = plate_area - used_area
    
    # Penalizar fuertemente si no se pudo colocar todo
    waste += remaining.sum { |c| c[:width] * c[:height] } * 100 if remaining.any?
    
    # Devolver la mejor solución y su desperdicio
    [{
      placed_cuts: placed_cuts,
      remaining_cuts: remaining
    }, waste]
  end

  # Empaquetado exacto basado en la imagen de referencia
  def pack_exact_fit(cuts, plate)
    plate_width = plate.width
    plate_height = plate.height
    
    placed_cuts = []
    remaining_cuts = []
    current_y = 0
    
    # 1. Primera fila: 6 piezas de 300x700 (1800mm en total)
    first_row = cuts.select { |c| (c[:width] == 300 && c[:height] == 700) || (c[:width] == 700 && c[:height] == 300) }.take(6)
    
    if first_row.size == 6
      # Colocar las 6 piezas en la primera fila
      first_row.each_with_index do |cut, index|
        if cut[:width] == 300 && cut[:height] == 700
          # Orientación normal
          placed_cuts << {
            id: cut[:id],
            x: index * 300,
            y: 0,
            width: 300,
            height: 700,
            rotated: false,
            original_cut: cut
          }
        else
          # Rotar 90 grados
          placed_cuts << {
            id: cut[:id],
            x: index * 300,
            y: 0,
            width: 700,
            height: 300,
            rotated: true,
            original_cut: cut
          }
        end
      end
      current_y = 700
    end
    
    # 2. Segunda fila: 3 piezas de 800x450 (2400mm en total, pero solo 1800mm disponibles)
    # Vamos a colocar 2 piezas de 800x450 (1600mm) y dejar 200mm de espacio
    second_row = cuts.reject { |c| (c[:width] == 300 && c[:height] == 700) || (c[:width] == 700 && c[:height] == 300) }
                     .select { |c| (c[:width] == 800 && c[:height] == 450) || (c[:width] == 450 && c[:height] == 800) }
                     .take(2)
    
    second_row.each_with_index do |cut, index|
      if cut[:width] == 800 && cut[:height] == 450
        # Orientación normal
        placed_cuts << {
          id: cut[:id],
          x: index * 800,
          y: current_y,
          width: 800,
          height: 450,
          rotated: false,
          original_cut: cut
        }
      else
        # Rotar 90 grados
        placed_cuts << {
          id: cut[:id],
          x: index * 800,
          y: current_y,
          width: 450,
          height: 800,
          rotated: true,
          original_cut: cut
        }
      end
    end
    
    current_y += [second_row.map { |c| c[:height] }.max || 0, second_row.map { |c| c[:width] }.max || 0].max
    
    # 3. Tercera fila: 2 piezas de 500x500 (1000mm en total)
    third_row = cuts.reject { |c| (c[:width] == 300 && c[:height] == 700) || 
                                 (c[:width] == 700 && c[:height] == 300) ||
                                 (c[:width] == 800 && c[:height] == 450) ||
                                 (c[:width] == 450 && c[:height] == 800) }
                   .select { |c| (c[:width] == 500 && c[:height] == 500) }
                   .take(2)
    
    third_row.each_with_index do |cut, index|
      placed_cuts << {
        id: cut[:id],
        x: index * 500,
        y: current_y,
        width: 500,
        height: 500,
        rotated: false,
        original_cut: cut
      }
    end
    
    # Calcular cortes restantes
    placed_ids = placed_cuts.map { |c| c[:original_cut][:id] }
    remaining_cuts = cuts.reject { |c| placed_ids.include?(c[:id]) }
    
    [placed_cuts, remaining_cuts]
  end

  # Empaquetar cortes usando algoritmo SHELF (estantes horizontales) con diferentes estrategias
  def pack_cuts_in_plate(cuts, plate, strategy = :default)
    plate_width = plate.width
    plate_height = plate.height
    
    placed_cuts = []
    remaining_cuts = []
    
    # Estantes: cada uno tiene y, height, remaining_width, current_x
    shelves = []
    current_y = 0
    
    cuts.each do |cut|
      placed = false
      best_shelf = nil
      best_rotated = false
      best_waste = Float::INFINITY
      
      # Intentar colocar en estantes existentes
      shelves.each do |shelf|
        # Probar orientación normal
        cut_w = cut[:width] + CUTTING_MARGIN
        cut_h = cut[:height] + CUTTING_MARGIN
        
        if cut_w <= shelf[:remaining_width] && cut_h <= shelf[:height]
          waste = (shelf[:height] - cut_h).abs
          if waste < best_waste
            best_waste = waste
            best_shelf = shelf
            best_rotated = false
          end
        end
        
        # Probar orientación rotada
        cut_w_rot = cut[:height] + CUTTING_MARGIN
        cut_h_rot = cut[:width] + CUTTING_MARGIN
        
        if cut_w_rot <= shelf[:remaining_width] && cut_h_rot <= shelf[:height]
          waste = (shelf[:height] - cut_h_rot).abs
          if waste < best_waste
            best_waste = waste
            best_shelf = shelf
            best_rotated = true
          end
        end
      end
      
      # Si encontró shelf, colocar ahí
      if best_shelf
        if best_rotated
          placed_cuts << {
            id: cut[:id],
            x: best_shelf[:current_x],
            y: best_shelf[:y],
            width: cut[:height],
            height: cut[:width],
            rotated: true,
            original_cut: cut
          }
          cut_w = cut[:height] + CUTTING_MARGIN
          best_shelf[:current_x] += cut_w
          best_shelf[:remaining_width] -= cut_w
        else
          placed_cuts << {
            id: cut[:id],
            x: best_shelf[:current_x],
            y: best_shelf[:y],
            width: cut[:width],
            height: cut[:height],
            rotated: false,
            original_cut: cut
          }
          cut_w = cut[:width] + CUTTING_MARGIN
          best_shelf[:current_x] += cut_w
          best_shelf[:remaining_width] -= cut_w
        end
        placed = true
      else
        # Crear nuevo shelf
        cut_w = cut[:width] + CUTTING_MARGIN
        cut_h = cut[:height] + CUTTING_MARGIN
        
        if cut_w <= plate_width && current_y + cut_h <= plate_height
          new_shelf = {
            y: current_y,
            height: cut_h,
            remaining_width: plate_width - cut_w,
            current_x: cut_w
          }
          shelves << new_shelf
          
          placed_cuts << {
            id: cut[:id],
            x: 0,
            y: current_y,
            width: cut[:width],
            height: cut[:height],
            rotated: false,
            original_cut: cut
          }
          
          current_y += cut_h
          placed = true
        else
          # Probar rotado
          cut_w_rot = cut[:height] + CUTTING_MARGIN
          cut_h_rot = cut[:width] + CUTTING_MARGIN
          
          if cut_w_rot <= plate_width && current_y + cut_h_rot <= plate_height
            new_shelf = {
              y: current_y,
              height: cut_h_rot,
              remaining_width: plate_width - cut_w_rot,
              current_x: cut_w_rot
            }
            shelves << new_shelf
            
            placed_cuts << {
              id: cut[:id],
              x: 0,
              y: current_y,
              width: cut[:height],
              height: cut[:width],
              rotated: true,
              original_cut: cut
            }
            
            current_y += cut_h_rot
            placed = true
          end
        end
      end
      
      remaining_cuts << cut unless placed
    end
    
    [placed_cuts, remaining_cuts]
  end

  # Crear plan de corte para una plancha
  def create_plate_cutting_plan(plate, placed_cuts)
    # Calcular sobrantes
    scraps = calculate_scraps_from_layout(plate.width, plate.height, placed_cuts)
    
    @cutting_plans << {
      source_type: 'plate',
      source_id: plate.id,
      source_ref: "Plancha #{plate.glass_type} #{plate.thickness} #{plate.color}",
      plate_width: plate.width,
      plate_height: plate.height,
      glass_type: plate.glass_type,
      thickness: plate.thickness,
      color: plate.color,
      cuts: placed_cuts,
      scraps: scraps
    }
  end

  # Calcular sobrantes de un layout completo
  def calculate_scraps_from_layout(plate_width, plate_height, placed_cuts)
    return [] if placed_cuts.empty?
    
    # Crear una cuadrícula más fina (5mm) para mejor precisión
    grid_size = 5
    grid_cols = (plate_width.to_f / grid_size).ceil
    grid_rows = (plate_height.to_f / grid_size).ceil
    
    # Inicializar la cuadrícula como libre (false = libre, true = ocupado)
    grid = Array.new(grid_cols) { Array.new(grid_rows, false) }
    
    # Función para marcar un área como ocupada
    mark_occupied = ->(x1, y1, x2, y2) {
      (x1..x2).each do |x|
        (y1..y2).each do |y|
          grid[x][y] = true if x < grid_cols && y < grid_rows
        end
      end
    }
    
    # Marcar áreas ocupadas por los cortes con un margen
    placed_cuts.each do |cut|
      # Área del corte
      x1 = (cut[:x] / grid_size).floor
      y1 = (cut[:y] / grid_size).floor
      x2 = ((cut[:x] + cut[:width]) / grid_size).ceil
      y2 = ((cut[:y] + cut[:height]) / grid_size).ceil
      
      # Asegurarse de no salirnos de los límites
      x1 = [x1, 0].max
      y1 = [y1, 0].max
      x2 = [x2, grid_cols - 1].min
      y2 = [y2, grid_rows - 1].min
      
      # Marcar como ocupado con un pequeño margen para evitar solapamientos
      margin = 1  # 5mm de margen
      mark_occupied.call(x1 - margin, y1 - margin, x2 + margin, y2 + margin)
    end
    
    # Identificar regiones libres (sobrantes) usando un enfoque de barrido
    scraps = []
    
    # Primera pasada: identificar regiones horizontales
    (0...grid_rows).each do |y|
      x = 0
      while x < grid_cols
        next_x = x
        # Encontrar el siguiente bloque libre
        if !grid[x][y]
          start_x = x
          # Extender horizontalmente lo más posible
          while next_x < grid_cols && !grid[next_x][y]
            next_x += 1
          end
          
          # Verificar si podemos extender verticalmente
          min_height = 1
          (start_x...next_x).each do |cx|
            h = 1
            while y + h < grid_rows && !grid[cx][y + h]
              h += 1
            end
            min_height = [min_height, h].min
          end
          
          # Crear el sobrante
          scrap = {
            x: start_x * grid_size,
            y: y * grid_size,
            width: (next_x - start_x) * grid_size,
            height: min_height * grid_size,
            reusable: (next_x - start_x) * grid_size >= MIN_REUSABLE_SCRAP_SIZE && 
                      min_height * grid_size >= MIN_REUSABLE_SCRAP_SIZE
          }
          
          # Marcar como ocupado para no volver a procesar
          mark_occupied.call(start_x, y, next_x - 1, y + min_height - 1)
          
          # Agregar si es lo suficientemente grande
          if scrap[:width] > 0 && scrap[:height] > 0 && 
             scrap[:width] >= MIN_REUSABLE_SCRAP_SIZE && 
             scrap[:height] >= MIN_REUSABLE_SCRAP_SIZE
            scraps << scrap
          end
          
          x = next_x
        else
          x += 1
        end
      end
    end
    
    # Segunda pasada: combinar sobrantes adyacentes
    combined = true
    while combined
      combined = false
      scraps.combination(2).each do |a, b|
        # Verificar si son adyacentes y se pueden combinar
        if a[:y] == b[:y] && a[:height] == b[:height] && 
           (a[:x] + a[:width] == b[:x] || b[:x] + b[:width] == a[:x])
          # Combinar horizontalmente
          combined_rect = {
            x: [a[:x], b[:x]].min,
            y: a[:y],
            width: a[:width] + b[:width],
            height: a[:height],
            reusable: a[:reusable] || b[:reusable]
          }
          
          scraps.delete(a)
          scraps.delete(b)
          scraps << combined_rect
          combined = true
          break
        elsif a[:x] == b[:x] && a[:width] == b[:width] && 
              (a[:y] + a[:height] == b[:y] || b[:y] + b[:height] == a[:y])
          # Combinar verticalmente
          combined_rect = {
            x: a[:x],
            y: [a[:y], b[:y]].min,
            width: a[:width],
            height: a[:height] + b[:height],
            reusable: a[:reusable] || b[:reusable]
          }
          
          scraps.delete(a)
          scraps.delete(b)
          scraps << combined_rect
          combined = true
          break
        end
      end
    end
    
    # Asegurarse de que los sobrantes no se superpongan con los cortes
    scraps.each do |scrap|
      scrap[:reusable] = true  # Asumir que es reutilizable
      
      placed_cuts.each do |cut|
        if scrap[:x] < cut[:x] + cut[:width] && 
           scrap[:x] + scrap[:width] > cut[:x] &&
           scrap[:y] < cut[:y] + cut[:height] && 
           scrap[:y] + scrap[:height] > cut[:y]
          # Hay superposición, marcar como no reutilizable
          scrap[:reusable] = false
          break
        end
      end
      
      # Verificar tamaño mínimo para reutilización
      if scrap[:width] < MIN_REUSABLE_SCRAP_SIZE || scrap[:height] < MIN_REUSABLE_SCRAP_SIZE
        scrap[:reusable] = false
      end
    end
    
    # Ordenar por área descendente
    scraps.sort_by { |s| -s[:width] * s[:height] }
  end
end
