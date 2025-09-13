def visualize_packing(packed_results, bin_details_map, output_folder='output_visuals'):
    import matplotlib.pyplot as plt
    import matplotlib.patches as patches
    import os

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

        original_bin_info = bin_details_map[bin_id]
        bin_width = original_bin_info['width']
        bin_height = original_bin_info['height']

        fig, ax = plt.subplots(1)
        ax.set_title(f'Plan de Corte - Placa: {bin_id}')
        ax.set_xlim(0, bin_width)
        ax.set_ylim(0, bin_height)
        ax.set_aspect('equal', adjustable='box')

        # Dibujar borde de la placa
        ax.add_patch(patches.Rectangle((0, 0), bin_width, bin_height, edgecolor='black', facecolor='none', lw=2))

        # Dibujar piezas y recolectar las coordenadas de los cortes (bordes)
        x_ticks = {0, bin_width}
        y_ticks = {0, bin_height}
        for piece in pieces:
            x0 = piece['X_Coordinate']
            y0 = piece['Y_Coordinate']
            w = piece['Packed_Width']
            h = piece['Packed_Height']

            rect = patches.Rectangle(
                (x0, y0),
                w,
                h,
                linewidth=1,
                edgecolor='r',
                facecolor='skyblue',
                alpha=0.75
            )
            ax.add_patch(rect)
            ax.text(
                x0 + w / 2,
                y0 + h / 2,
                piece['Piece_ID'],
                ha='center',
                va='center',
                fontsize=8
            )

            # Añadir bordes para las escalas: inicio y fin de cada pieza
            x_ticks.add(int(x0))
            x_ticks.add(int(x0 + w))
            y_ticks.add(int(y0))
            y_ticks.add(int(y0 + h))

        # Ordenar ticks y juntar valores muy cercanos/duplicados en uno solo
        def merge_close(sorted_vals, tol=1e-3):
            merged = []
            for v in sorted_vals:
                if not merged or abs(v - merged[-1]) > tol:
                    merged.append(v)
            return merged

        x_ticks_sorted = sorted(x_ticks)
        y_ticks_sorted = sorted(y_ticks)
        x_ticks_merged = merge_close(x_ticks_sorted)
        y_ticks_merged = merge_close(y_ticks_sorted)

        ax.set_xticks(x_ticks_merged)
        ax.set_yticks(y_ticks_merged)

        # Preparar etiquetas: si el número es efectivamente entero, mostrar sin decimales
        def fmt_label(v, tol=1e-3):
            if abs(v - round(v)) <= tol:
                return str(int(round(v)))
            return f"{v:.2f}"

        x_labels = [fmt_label(v) for v in x_ticks_merged]
        y_labels = [fmt_label(v) for v in y_ticks_merged]

        # Rotar etiquetas del eje X verticalmente para evitar solapamiento
        ax.set_xticklabels(x_labels, rotation=90, va='center', ha='center', fontsize=8)
        ax.set_yticklabels(y_labels, fontsize=8)

    # Mostrar líneas de corte/grid sólo en esas posiciones para facilitar lectura
    ax.grid(True, which='both', linestyle='--', alpha=0.6)

    # Ajustar distancia de las etiquetas del eje X para que no queden pegadas
    # al gráfico (especialmente la última etiqueta)
    ax.tick_params(axis='x', which='major', pad=10)

    # Etiquetas numéricas claras
    ax.set_xlabel("Ancho")
    ax.set_ylabel("Alto")

    # Ajustes para evitar que las etiquetas queden recortadas al guardar
    fig.tight_layout(pad=1.0)
    filepath = os.path.join(output_folder, f"{bin_id}.png")
    fig.savefig(filepath, bbox_inches='tight', dpi=150)
    plt.close(fig)
    print(f"\n✅ Visualizaciones guardadas en la carpeta: '{output_folder}/'")
