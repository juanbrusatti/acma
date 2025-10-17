module PaginationHelper
  # Método genérico para mostrar la información de paginación
  def pagination_info_generic(collection, item_name = "elementos")
    return "No se encontraron #{item_name}" unless collection.respond_to?(:current_page)
    
    if collection.total_pages > 0
      start_item = (collection.current_page - 1) * collection.per_page + 1
      end_item = [start_item + collection.per_page - 1, collection.total_entries].min
      "Mostrando #{start_item} - #{end_item} de #{collection.total_entries} #{item_name}"
    else
      "No se encontraron #{item_name}"
    end
  end

  # Método genérico para renderizar la paginación con estilos consistentes
  def render_pagination(collection, params = {})
    return unless collection.respond_to?(:current_page) && collection.total_pages > 1
    
    will_paginate collection,
      renderer: WillPaginate::ActionView::LinkRenderer,
      class: "pagination",
      previous_label: '<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path></svg>',
      next_label: '<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path></svg>',
      inner_window: 2,
      outer_window: 1,
      params: params
  end

  # Método para renderizar el contenedor completo de paginación
  def pagination_container(collection, item_name = "elementos", params = {})
    content_tag :div, class: "mt-10 flex flex-col items-center border-t border-gray-100 pt-6" do
      concat content_tag(:div, pagination_info_generic(collection, item_name), class: "text-sm text-gray-500 mb-4")
      concat render_pagination(collection, params)
    end
  end
end
