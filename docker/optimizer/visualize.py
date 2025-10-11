def draw_header(fig, page=1, total_pages=1, title="AR Y ASOCIADOS SRL"):

    from datetime import datetime
    import matplotlib.patches as patches

    # Recuadro (coordenadas relativas a la figura: [x, y, ancho, alto])
    rect = patches.Rectangle((0.02, 0.93), 0.96, 0.06, transform=fig.transFigure,
                             fill=False, linewidth=0.8, edgecolor="black")
    fig.patches.append(rect)

    # Texto izquierdo
    fig.text(0.03, 0.955,
             f"\nPágina {page} / {total_pages}",
             ha="left", va="center", fontsize=7)

    # Texto central
    fig.text(0.5, 0.955, title,
             ha="center", va="center", fontsize=13, weight="bold", fontfamily="sans-serif")

    # Texto derecho (fecha)
    fig.text(0.97, 0.955, datetime.now().strftime("%d/%m/%Y"),
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

        # --- FIGURA A4 EN PULGADAS (VERTICAL / PORTRAIT) ---
        fig_width, fig_height = 8.27, 11.69
        fig, ax = plt.subplots(figsize=(fig_width, fig_height))
        draw_header(fig, page=1, total_pages=len(pieces_by_bin))

        # --- Márgenes en pulgadas ---
        margin_x = 0.5
        margin_y = 1.0  # deja espacio arriba y abajo

        usable_width = fig_width - 2 * margin_x
        usable_height = fig_height - 2 * margin_y

        if bin_width > bin_height:
            bin_width, bin_height = bin_height, bin_width

        # Escalar bin para que quepa dentro del A4 manteniendo aspecto
        scale_x = usable_width / bin_width
        scale_y = usable_height / bin_height
        scale = min(scale_x, scale_y)

        scaled_width = bin_width * scale
        scaled_height = bin_height * scale

        # Coordenadas base para centrar dentro de la hoja
        offset_x = (fig_width - scaled_width) / 2
        offset_y = (fig_height - scaled_height) / 2

        ax.set_xlim(0, fig_width)
        ax.set_ylim(0, fig_height)
        ax.set_aspect('equal')
        ax.axis('off')

        # Dibujar borde del bin escalado
        ax.add_patch(patches.Rectangle(
            (offset_x, offset_y), scaled_width, scaled_height,
            edgecolor='black', facecolor='none', lw=1.5
        ))

        # Dibujar las piezas escaladas
        for piece in pieces:
            x0, y0 = piece['X_Coordinate'], piece['Y_Coordinate']
            w, h = piece['Packed_Width'], piece['Packed_Height']

            sx = offset_x + x0 * scale
            sy = offset_y + (bin_height - y0 - h) * scale  # invertir eje Y
            sw = w * scale
            sh = h * scale

            color = 'grey' if piece.get('Is_Waste', False) else 'skyblue'

            rect = patches.Rectangle((sx, sy), sw, sh,
                                     linewidth=0.6, edgecolor='black',
                                     facecolor=color, alpha=0.6)
            ax.add_patch(rect)

            # Dimensiones dentro del corte
            # Ancho arriba, dentro del rectángulo
            ax.text(sx + sw/2, sy + sh - 0.08, f"{w:.0f}", ha='center', va='top', fontsize=8, weight='light')
            # Alto a la izquierda, dentro del rectángulo, rotado
            ax.text(sx + 0.08, sy + sh/2, f"{h:.0f}", ha='left', va='center', fontsize=8, weight='light', rotation=90)

            # Etiqueta solo el ID en el centro (sin dimensiones)
            if not piece.get('Is_Waste', False):
                ax.text(sx + sw/2, sy + sh/2, f"{piece.get('Piece_ID', '')}",
                        ha='center', va='center', fontsize=6, color='black', weight='bold')
            else:
                ax.text(sx + sw/2, sy + sh/2, "Sobrante",
                        ha='center', va='center', fontsize=6, color='black', weight='bold')

        # Título debajo del encabezado
        dims_text = f"{bin_height:.0f} x {bin_width:.0f}"
        prefix = "Sobrante" if ("scrap" in bin_id.lower() or "leftover" in bin_id.lower()) else "Plancha"
        gt = str(bdet.get('glass_type') or '').strip()
        th = str(bdet.get('thickness') or '').strip()
        co = str(bdet.get('color') or '').strip()
        suffix_parts = [p for p in [gt, th, co] if p]
        suffix = f" - {' '.join(suffix_parts)}" if suffix_parts else ""
        fig.text(0.5, 0.91, f"{prefix} {dims_text}{suffix}",
                 ha='center', va='bottom', fontsize=11, weight='bold')

        # --- Guardar PDF exacto A4 ---
        combo_folder = "_".join([p for p in [gt, th, co] if p]) or "unknown"
        combo_folder = combo_folder.replace(' ', '-').replace('/', '-').replace('\\', '-')
        out_dir = os.path.join(output_folder, combo_folder)
        os.makedirs(out_dir, exist_ok=True)

        base_pdf = os.path.join(out_dir, f"{bin_id}.pdf")
        with PdfPages(base_pdf) as pdf:
            pdf.savefig(fig)

        plt.close(fig)
        print(f"✅ Guardado PDF A4 vertical: {base_pdf}")
