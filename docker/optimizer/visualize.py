def draw_header(fig, page=1, total_pages=1, title="AR Y ASOCIADOS SRL"):

    from datetime import datetime
    import matplotlib.patches as patches

    # Recuadro (coordenadas relativas a la figura: [x, y, ancho, alto])
    rect = patches.Rectangle((0.02, 0.88), 0.96, 0.06, transform=fig.transFigure,
                             fill=False, linewidth=0.8, edgecolor="black")
    fig.patches.append(rect)

    # Texto izquierdo
    fig.text(0.03, 0.91,
             f"\nPágina {page}",
             ha="left", va="center", fontsize=7)

    # Texto central
    fig.text(0.5, 0.91, title,
             ha="center", va="center", fontsize=13, weight="bold", fontfamily="sans-serif")

    # Texto derecho (fecha)
    fig.text(0.97, 0.91, datetime.now().strftime("%d/%m/%Y"),
             ha="right", va="center", fontsize=7)

def generate_general_summary_pdf(all_cuts, output_folder='output_visuals', filename='resumen_general.pdf'):
    import matplotlib.pyplot as plt
    import os
    from matplotlib.backends.backend_pdf import PdfPages
    
    if not all_cuts:
        print("[INFO] No hay cortes para generar resumen general")
        return
    
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)
    
    output_path = os.path.join(output_folder, filename)
    
    fig_width, fig_height = 8.27, 11.69
    
    # Preparar datos para la tabla
    headers = ['Tipología', 'Clase', 'Cardinal', 'Cam.', 'Comp.', 'Ancho', 'Alto', 'Origen', 'Obra']
    table_data = [headers]
    
    for cut in all_cuts:
        origen = cut.get('plancha', '-')
        if origen.startswith('Sobrante_'):
            parts = origen.split('_')
            if len(parts) > 1:
                nro_ref = parts[1]
                origen = f"Sobrante NRO_REF = {nro_ref}"
        
        # Combinar Tipo, Grosor, Color en una sola columna
        tipo = cut.get('tipo', '-')
        grosor = cut.get('grosor', '-')
        color = cut.get('color', '-')
        comp = f"{tipo} {grosor} {color}".strip()
        
        work_name = cut.get('work', '-')
        work_id = cut.get('id_work', '')
        if work_id:
            work = f"{work_name} ({work_id})"
        else:
            work = work_name
        
        table_data.append([
            cut.get('tipologia', '-'),
            cut.get('clase', 'Simple'),
            cut.get('cardinal', '-'),
            cut.get('innertube', '-'),
            comp,
            str(int(cut.get('ancho', 0))),
            str(int(cut.get('alto', 0))),
            origen,
            work
        ])
    
    # Calcular cuántas filas caben por página (aprox 35-40 filas por página)
    rows_per_page = 24
    total_pages = (len(all_cuts) + rows_per_page - 1) // rows_per_page
    
    # Calcular estadísticas de cortes
    total_cuts = len(all_cuts)
    dvh_count = sum(1 for cut in all_cuts if cut.get('clase') == 'DVH')
    simple_count = sum(1 for cut in all_cuts if cut.get('clase') == 'Simple')
    
    # Agrupar DVH por ID base (antes del _)
    dvh_groups = {}
    for cut in all_cuts:
        if cut.get('clase') == 'DVH':
            id = cut.get('id_pieza', '')
            # Extraer ID base (antes del _)
            base_id = id.split('_')[0] if '_' in id else id
            
            if base_id not in dvh_groups:
                dvh_groups[base_id] = []
            dvh_groups[base_id].append(cut)
    
    # Crear tabla de resumen de DVH
    dvh_summary = []
    for base_id, cuts in dvh_groups.items():
        # Procesar los cortes de 2 en 2 (cada DVH tiene 2 vidrios)
        for i in range(0, len(cuts), 2):
            if i + 1 < len(cuts):
                cut1 = cuts[i]
                cut2 = cuts[i + 1]
                
                # Obtener composición de cada vidrio
                tipo1 = cut1.get('tipo', '-')
                grosor1 = cut1.get('grosor', '-')
                color1 = cut1.get('color', '-')
                comp1 = f"{tipo1} {grosor1} {color1}".strip()
                
                tipo2 = cut2.get('tipo', '-')
                grosor2 = cut2.get('grosor', '-')
                color2 = cut2.get('color', '-')
                comp2 = f"{tipo2} {grosor2} {color2}".strip()

                tipologia = cut1.get('tipologia', '')
                
                # Cámara (innertube)
                camara = cut1.get('innertube', '-')
                
                # Composición completa del DVH
                composicion_dvh = f"{comp1} / {camara} / {comp2}"
                
                dvh_summary.append({
                    'tipologia': tipologia,
                    'composicion': composicion_dvh,
                    'ancho': int(cut1.get('ancho', 0)),
                    'alto': int(cut1.get('alto', 0))
                })
    
    with PdfPages(output_path) as pdf:
        for page_num in range(total_pages):
            fig = plt.figure(figsize=(fig_width, fig_height))
            draw_header(fig, page=page_num + 1, total_pages=total_pages)
            
            ax = fig.add_subplot(111)
            ax.axis('off')
            
            if page_num == 0:
                # Título
                fig.text(0.5, 0.84, "RESUMEN GENERAL DE CORTES", 
                     ha='center', fontsize=12, weight='bold')
                fig.text(0.5, 0.80, f"Total de cortes: {total_cuts}", 
                         ha='center', fontsize=9)
                fig.text(0.5, 0.78, f"Cantidad de DVH: {int(dvh_count/2)} | Cantidad de vidrios simples: {simple_count}", 
                         ha='center', fontsize=8)
                # Tabla comienza más abajo en primera página (para dejar espacio al resumen)
                table_y_bottom = 0.05
                table_height = 0.71
            else:
                # En páginas posteriores, la tabla puede empezar más arriba
                table_y_bottom = 0.05
                table_height = 0.82
            
            # Calcular rango de filas para esta página
            start_idx = page_num * rows_per_page
            end_idx = min(start_idx + rows_per_page, len(all_cuts))
            
            # Datos de esta página (incluir header + datos)
            page_table_data = [headers] + table_data[1 + start_idx:1 + end_idx]
                
            if not page_table_data or len(page_table_data) <= 1:
                continue
            
            # Posicionar tabla centrada en la página
            table_ax = fig.add_axes([0.02, table_y_bottom, 0.96, table_height])
            table_ax.axis('off')

            # Ajustar colWidths para que sumen 1
            col_widths = [0.10, 0.07, 0.10, 0.07, 0.12, 0.10, 0.10, 0.20, 0.14]

            # Crear tabla centrada horizontalmente y arriba verticalmente
            table = table_ax.table(
                cellText=page_table_data,
                cellLoc='center',
                loc='upper center',
                colWidths=col_widths
            )
            
            # Estilizar tabla con letra más grande
            table.auto_set_font_size(False)
            table.set_fontsize(8)
            table.scale(1, 2.0)
            
            # Aplicar estilos a celdas
            for i, row in enumerate(page_table_data):
                for j, cell in enumerate(row):
                    table_cell = table[(i, j)]
                    table_cell.set_edgecolor('#ddd')
                    table_cell.set_linewidth(0.5)
                    
                    if i == 0:  # Header
                        table_cell.set_facecolor('#f3f3f3')
                        table_cell.set_text_props(weight='bold', color='#222', fontsize=8)
                        table_cell.set_edgecolor('#ddd')
                        table_cell.set_linewidth(1)
                    else:
                        # Alternar colores
                        if (start_idx + i - 1) % 2 == 0:
                            table_cell.set_facecolor('#ffffff')
                        else:
                            table_cell.set_facecolor('#f9f9f9')
                        table_cell.set_text_props(color='#333', fontsize=8)
            
            pdf.savefig(fig)
            plt.close(fig)
        
        # Agregar página con resumen de DVH si hay DVH
        if dvh_summary:
            # Preparar datos para la tabla de DVH
            dvh_headers = ['Tipología', 'Composición', 'Ancho', 'Alto']
            dvh_table_data = [dvh_headers]
            
            for dvh in dvh_summary:
                dvh_table_data.append([
                    dvh['tipologia'],
                    dvh['composicion'],
                    str(dvh['ancho']),
                    str(dvh['alto'])
                ])
            
            # Calcular cuántas filas de DVH caben por página
            dvh_rows_per_page = 25
            total_dvh_pages = (len(dvh_summary) + dvh_rows_per_page - 1) // dvh_rows_per_page
            
            for dvh_page_num in range(total_dvh_pages):
                fig_dvh = plt.figure(figsize=(fig_width, fig_height))
                draw_header(fig_dvh, page=total_pages + dvh_page_num + 1, total_pages=total_pages + total_dvh_pages)
                
                ax_dvh = fig_dvh.add_subplot(111)
                ax_dvh.axis('off')
                
                # Título del resumen de DVH
                fig_dvh.text(0.5, 0.84, "RESUMEN DE DVH", 
                             ha='center', fontsize=12, weight='bold')
                
                # Calcular rango de filas para esta página de DVH
                dvh_start_idx = dvh_page_num * dvh_rows_per_page
                dvh_end_idx = min(dvh_start_idx + dvh_rows_per_page, len(dvh_summary))
                
                # Datos de esta página (incluir header + datos)
                page_dvh_table_data = [dvh_headers] + dvh_table_data[1 + dvh_start_idx:1 + dvh_end_idx]
                
                if not page_dvh_table_data or len(page_dvh_table_data) <= 1:
                    continue
                
                # Posicionar tabla de DVH
                dvh_table_ax = fig_dvh.add_axes([0.05, 0.05, 0.90, 0.77])
                dvh_table_ax.axis('off')
                
                # Crear tabla de DVH
                dvh_table = dvh_table_ax.table(
                    cellText=page_dvh_table_data,
                    cellLoc='center',
                    loc='upper center',
                    colWidths=[0.15, 0.55, 0.15, 0.15]
                )
                
                # Estilizar tabla de DVH
                dvh_table.auto_set_font_size(False)
                dvh_table.set_fontsize(8)
                dvh_table.scale(1, 2.0)
                
                # Aplicar estilos a celdas
                for i, row in enumerate(page_dvh_table_data):
                    for j, cell in enumerate(row):
                        table_cell = dvh_table[(i, j)]
                        table_cell.set_edgecolor('#ddd')
                        table_cell.set_linewidth(0.5)
                        
                        if i == 0:  # Header
                            table_cell.set_facecolor('#f3f3f3')
                            table_cell.set_text_props(weight='bold', color='#222', fontsize=8)
                            table_cell.set_edgecolor('#ddd')
                            table_cell.set_linewidth(1)
                        else:
                            # Alternar colores
                            if (dvh_start_idx + i - 1) % 2 == 0:
                                table_cell.set_facecolor('#ffffff')
                            else:
                                table_cell.set_facecolor('#f9f9f9')
                            table_cell.set_text_props(color='#333', fontsize=8)
                
                pdf.savefig(fig_dvh)
                plt.close(fig_dvh)
    
    print(f"✅ Guardado PDF de resumen general: {output_path}")
    return output_path

def visualize_packing(packed_results, bin_details_map, output_folder='output_visuals'):
    import matplotlib.pyplot as plt
    import matplotlib.patches as patches
    import os
    from matplotlib.backends.backend_pdf import PdfPages

    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    pieces_by_bin = {}
    for r in packed_results:
        bin_id = r['Source_Plate_ID']
        pieces_by_bin.setdefault(bin_id, []).append(r)

    for bin_id, pieces in pieces_by_bin.items():
        if bin_id not in bin_details_map:
            print(f"[❌] Bin '{bin_id}' no encontrado en bin_details_map")
            continue

        bdet = bin_details_map[bin_id]
        bin_width, bin_height = bdet['width'], bdet['height']

        fig_width, fig_height = 8.27, 11.69
        fig, ax = plt.subplots(figsize=(fig_width, fig_height))
        draw_header(fig, page=1, total_pages=len(pieces_by_bin))

        margin_x = 0.5
        margin_y = 1.0
        usable_width = fig_width - 2 * margin_x
        usable_height = fig_height - 2 * margin_y

        """ if bin_width > bin_height:
            bin_width, bin_height = bin_height, bin_width
 """
        scale_x = usable_width / bin_width
        scale_y = usable_height / bin_height
        scale = min(scale_x, scale_y)

        scaled_width = bin_width * scale
        scaled_height = bin_height * scale
        offset_x = (fig_width - scaled_width) / 2
        offset_y = (fig_height - scaled_height) / 2

        ax.set_xlim(0, fig_width)
        ax.set_ylim(0, fig_height)
        ax.set_aspect('equal')
        ax.axis('off')

        ax.add_patch(patches.Rectangle(
            (offset_x, offset_y), scaled_width, scaled_height,
            edgecolor='black', facecolor='none', lw=1.5
        ))

        # --- IDs virtuales y resumen ---
        virtual_counter = 1
        resumen = []

        for piece in pieces:
            x0, y0 = piece['X_Coordinate'], piece['Y_Coordinate']
            w, h = piece['Packed_Width'], piece['Packed_Height']

            sx = offset_x + x0 * scale
            sy = offset_y + (bin_height - y0 - h) * scale
            sw = w * scale
            sh = h * scale

            # Determinar color según el tipo de pieza
            if piece.get('Is_Unused', False):
                color = 'lightcoral'              # Sobrante inútil (pequeño)
            elif piece.get('Is_Waste', False):
                color = 'grey'             # Sobrante útil (reutilizable)
            elif piece.get('Is_Transformed', False):
                color = 'orange'           # Pieza transformada (LAM 3+3 INC)
            else:
                color = 'lightblue'        # Pieza real del pedido
            # color = 'grey' if piece.get('Is_Waste', False) else 'red' if piece.get('Is_Unused', False) else 'lightblue'
            
            rect = patches.Rectangle((sx, sy), sw, sh,
                                     linewidth=0.6, edgecolor='black',
                                     facecolor=color, alpha=0.6)
            ax.add_patch(rect)

            # Calcular si hay espacio suficiente para mostrar dimensiones
            # Usar un porcentaje del tamaño total de la plancha
            if bin_width > bin_height:
                min_percentage = 0.08  # % del tamaño de la plancha
            else: 
                min_percentage = 0.06  # % del tamaño de la plancha

            min_w = bin_width * min_percentage
            min_h = bin_height * min_percentage
            show_dims = (w >= min_w and h >= min_h)

            if not piece.get('Is_Waste', False):

                if show_dims:
                    ax.text(sx + sw/2, sy + sh/2, piece.get('Typology', ''),
                        ha='center', va='center', fontsize=8, color='black', weight='bold')
                    if piece.get('Is_Transformed'):
                        ax.text(sx + sw/2, sy + sh/2 - 0.18, 'FLO',
                        ha='center', va='center', fontsize=7, color='black')
                    ax.text(sx + sw/2, sy + sh - 0.08, f"{w:.0f}",
                            ha='center', va='top', fontsize=8, weight='light')
                    ax.text(sx + 0.08, sy + sh/2, f"{h:.0f}",
                            ha='left', va='center', fontsize=8, weight='light', rotation=90)
                else: 
                    virtual_id = f"C{virtual_counter}"
                    virtual_counter += 1
                    ax.text(sx + sw/2, sy + sh/2, virtual_id,
                        ha='center', va='center', fontsize=6, color='black', weight='bold')
                    
                    resumen.append({
                        "virtual_id": virtual_id,
                        "piece_id": piece.get('Typology', ''),
                        "dims": f"{w:.0f} (Ancho) x {h:.0f} (Alto)",
                        "is_transformed": piece.get('Is_Transformed')
                    })

            else:
                # Sobrante
                if not piece.get('Is_Unused', False):
                    if not show_dims:
                        virtual_id = f"C{virtual_counter}"
                        virtual_counter += 1
                        ax.text(sx + sw/2, sy + sh/2, virtual_id,
                            ha='center', va='center', fontsize=6, color='black', weight='bold')
                        resumen.append({
                            "virtual_id": virtual_id,
                            "piece_id": "Sobrante",
                            "dims": f"{w:.0f} (Ancho) x {h:.0f} (Alto)"
                        })
                    else:
                        ax.text(sx + sw/2, sy + sh/2, "Sobrante",
                            ha='center', va='center', fontsize=6, color='black', weight='bold')
                        ax.text(sx + sw/2, sy + sh - 0.08, f"{w:.0f}",
                                ha='center', va='top', fontsize=8, weight='light')
                        ax.text(sx + 0.08, sy + sh/2, f"{h:.0f}",
                                ha='left', va='center', fontsize=8, weight='light', rotation=90)
                else:
                    pass

        # --- Título del plano ---
        dims_text = f"{bin_height:.0f} x {bin_width:.0f}"
        
        # Determinar si es sobrante o plancha (chequear tanto bin_id como type en bin_details_map)
        bin_type = str(bdet.get('type') or '').lower()
        is_scrap = (
            "scrap" in bin_id.lower() or 
            "leftover" in bin_id.lower() or 
            "sobrante" in bin_id.lower() or
            bin_type == 'leftover'
        )
        
        prefix = "Sobrante" if is_scrap else "Plancha"
        number_ref = str(bdet.get('ref_number') or '').strip()
        prefix += f" {number_ref}" if number_ref else ""

        gt = str(bdet.get('glass_type') or '').strip()
        th = str(bdet.get('thickness') or '').strip()
        co = str(bdet.get('color') or '').strip()
        suffix_parts = [p for p in [gt, th, co] if p]
        suffix = f" - {' '.join(suffix_parts)}" if suffix_parts else ""

        fig.text(0.5, 0.85, f"{prefix}, {dims_text}{suffix}",
                 ha='center', va='bottom', fontsize=11, weight='bold')

        combo_folder = "_".join([p for p in [gt, th, co] if p]) or "unknown"
        combo_folder = combo_folder.replace(' ', '-').replace('/', '-').replace('\\', '-')
        out_dir = os.path.join(output_folder, combo_folder)
        os.makedirs(out_dir, exist_ok=True)

        # --- Guardar PDF con múltiples páginas ---
        # Usar número de referencia para el nombre del archivo
        if is_scrap and number_ref:
            pdf_filename = f"Sobrante_{number_ref}.pdf"
        elif number_ref:
            pdf_filename = f"Plancha_{number_ref}.pdf"
        else:
            pdf_filename = f"{bin_id}.pdf"
        
        base_pdf = os.path.join(out_dir, pdf_filename)
        with PdfPages(base_pdf) as pdf:
            # Primera página con el diagrama
            pdf.savefig(fig)
            plt.close(fig)

            if resumen:
                fig2, ax2 = plt.subplots(figsize=(fig_width, fig_height))
                draw_header(fig2, page=2, total_pages=2) # Si no queremos volver a dibujar el header, sacamos esta línea
                ax2.axis('off')
                
                # Título para la segunda página
                fig2.text(0.5, 0.82, "RESUMEN DE CORTES PEQUEÑOS", 
                         ha='center', fontsize=12, weight='bold')
                
                # Dividir resumen en múltiples columnas si es necesario
                items_per_page = 35  # máximo de items por página
                y_start = 0.79  # Más cerca del título
                line_height = 0.014  # Líneas más juntas
                
                for i, r in enumerate(resumen):
                    y_pos = y_start - (i * line_height)
                    
                    if r["piece_id"] == "Sobrante":
                        text = f"• {r['virtual_id']}: Sobrante, {r['dims']}"
                    elif r['is_transformed']:
                        text = f"• {r['virtual_id']}: {r['piece_id']} (FLO), {r['dims']}"
                    else:
                        text = f"• {r['virtual_id']}: {r['piece_id']}, {r['dims']}"
                    
                    fig2.text(0.1, y_pos, text, ha='left', va='top', fontsize=9)
                    
                    # Si llegamos al final de la página, podríamos crear otra página
                    if i >= items_per_page - 1:
                        break
                
                pdf.savefig(fig2)
                plt.close(fig2)

        print(f"✅ Guardado PDF A4 vertical: {base_pdf}")