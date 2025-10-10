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

        # --- FIGURA A4 EN PULGADAS (landscape) ---
        fig, ax = plt.subplots(figsize=(8.27, 11.69))  # A4 horizontal
        draw_header(fig, page=1, total_pages=len(pieces_by_bin))

        # --- Configurar área de dibujo centrada ---
        margin_x = 0.5  # pulgadas
        margin_y = 1.0  # pulgadas (más espacio arriba)
        usable_width = 11.69 - 2 * margin_x
        usable_height = 8.27 - 2 * margin_y

        # Escalar bin para que quepa dentro del A4 manteniendo aspecto
        scale_x = usable_width / bin_width
        scale_y = usable_height / bin_height
        scale = min(scale_x, scale_y)

        scaled_width = bin_width * scale
        scaled_height = bin_height * scale

        # Coordenadas base para centrar dentro de la hoja
        offset_x = (11.69 - scaled_width) / 2
        offset_y = (8.27 - scaled_height) / 2

        ax.set_xlim(0, 11.69)
        ax.set_ylim(0, 8.27)
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

            rect = patches.Rectangle((sx, sy), sw, sh,
                                     linewidth=0.6, edgecolor='red',
                                     facecolor='skyblue', alpha=0.6)
            ax.add_patch(rect)

            # Etiquetas
            label = f"{piece.get('Piece_ID', '')}\n{h:.0f}x{w:.0f}"
            fontsize = 6 if min(sw, sh) < 0.7 else 8
            ax.text(sx + sw/2, sy + sh/2, label,
                    ha='center', va='center', fontsize=fontsize, color='black')

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

        # --- Guardar PDF exacto A4 sin recortes ---
        combo_folder = "_".join([p for p in [gt, th, co] if p]) or "unknown"
        combo_folder = combo_folder.replace(' ', '-').replace('/', '-').replace('\\', '-')
        out_dir = os.path.join(output_folder, combo_folder)
        os.makedirs(out_dir, exist_ok=True)

        base_pdf = os.path.join(out_dir, f"{bin_id}.pdf")
        with PdfPages(base_pdf) as pdf:
            pdf.savefig(fig)  # sin bbox_inches='tight' para mantener A4 exacto

        plt.close(fig)
        print(f"✅ Guardado PDF A4: {base_pdf}")
