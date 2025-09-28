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
    from datetime import datetime
    from matplotlib.backends.backend_pdf import PdfPages

    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    pieces_by_bin = {}
    for r in packed_results:
        bin_id = r['Source_Plate_ID']
        if bin_id not in pieces_by_bin:
            pieces_by_bin[bin_id] = []
        pieces_by_bin[bin_id].append(r)

    for bin_id, pieces in pieces_by_bin.items():
        if bin_id not in bin_details_map:
            print(f"[❌] Bin '{bin_id}' no encontrado en bin_details_map")
            continue

        bin_width = bin_details_map[bin_id]['width']
        bin_height = bin_details_map[bin_id]['height']

        # Crear figura en tamaño A4 horizontal (landscape)
        fig, ax = plt.subplots(figsize=(8.27, 11.69))  # A4 landscape en pulgadas
        draw_header(fig, page=1, total_pages=len(pieces_by_bin))

        # Más espacio abajo del plano
        fig.subplots_adjust(left=0.22, right=0.78, top=0.88, bottom=0.18)  # bottom antes: 0.12

        # Determinar tipo de placa y mostrar texto arriba del plano
        bin_name = bin_id.lower()
        if "scrap" in bin_name or "leftover" in bin_name:
            plano_label = f"Sobrante {bin_width:.0f} x {bin_height:.0f}"
        else:
            plano_label = f"Plancha {bin_width:.0f} x {bin_height:.0f}"
        fig.text(0.5, 0.90, plano_label, ha='center', va='bottom', fontsize=11, weight='bold')

        # Ajustar márgenes para centrar y ampliar el área de dibujo
        fig.subplots_adjust(left=0.22, right=0.78, top=0.88, bottom=0.12)

        # Área de dibujo
        ax.set_xlim(0, bin_width)
        ax.set_ylim(0, bin_height)
        ax.set_aspect('equal', adjustable='box')
        ax.invert_yaxis()

        # Bordes
        ax.spines['right'].set_visible(False)
        ax.spines['bottom'].set_visible(False)
        ax.xaxis.set_visible(False)  # Quitar eje X
        ax.yaxis.set_visible(False)  # Quitar eje Y

        # Dibujar placa
        ax.add_patch(patches.Rectangle((0, 0), bin_width, bin_height,
                                       edgecolor='black', facecolor='none', lw=2))

        for piece in pieces:
            x0, y0 = piece['X_Coordinate'], piece['Y_Coordinate']
            w, h = piece['Packed_Width'], piece['Packed_Height']

            # Dibujar pieza
            rect = patches.Rectangle((x0, y0), w, h,
                                     linewidth=1, edgecolor='red',
                                     facecolor='skyblue', alpha=0.6)
            ax.add_patch(rect)

            # Mostrar tipología (usando 'Piece_ID' que es la tipología)
            typology = piece.get('Piece_ID', '')
            label = f"{typology}\n{w:.0f} x {h:.0f}"

            # Ajuste automático: si es muy chico el rectángulo, poner la etiqueta afuera
            if w < 60 or h < 40:
                ax.text(x0 + w/2, y0 + h + 10, label,
                        ha='center', va='bottom', fontsize=7, color='black')
            else:
                ax.text(x0 + w/2, y0 + h/2, label,
                        ha='center', va='center', fontsize=8, color='black')

        # Guardar PDF
        base_pdf = os.path.join(output_folder, f"{bin_id}.pdf")
        with PdfPages(base_pdf) as pdf:
            pdf.savefig(fig, bbox_inches='tight')
        print(f"✅ Guardado PDF: {base_pdf}")

        plt.close(fig)
