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
                min_percentage = 0.05

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
        base_pdf = os.path.join(out_dir, f"{bin_id}.pdf")
        with PdfPages(base_pdf) as pdf:
            # Primera página con el diagrama
            pdf.savefig(fig)
            plt.close(fig)
            
            # Segunda página con resumen si hay cortes pequeños
            if resumen:
                fig2, ax2 = plt.subplots(figsize=(fig_width, fig_height))
                draw_header(fig2, page=2, total_pages=2) # SI no queremos volver a dibujar el header, sacamos esta linea
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