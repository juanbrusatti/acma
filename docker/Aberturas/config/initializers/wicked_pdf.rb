WickedPdf.configure do |c|
  # Path to the wkhtmltopdf executable: Using system wkhtmltopdf
  c.exe_path = '/usr/local/bin/wkhtmltopdf'

  # Layout file to be used for all PDFs
  # (but can be overridden in `render :pdf` calls)
  # layout: 'pdf.html',

  # Using wkhtmltopdf without an X server can be achieved by enabling the
  # 'use_xvfb' flag. This will wrap all wkhtmltopdf calls in a 'xvfb-run'
  # command, in order to simulate an X server.
  c.use_xvfb = true

  # You can specify default options for all PDFs here.
  # These can be overridden in individual calls to `render :pdf`
  c.enable_local_file_access = true
  
  # Additional options for better PDF generation
  c.default_options = {
    page_size: 'A4',
    margin_top: '10mm',
    margin_bottom: '10mm', 
    margin_left: '10mm',
    margin_right: '10mm',
    disable_smart_shrinking: true,
    print_media_type: true,
    disable_external_links: true,
    enable_local_file_access: true,
    javascript_delay: 1000,
    timeout: 30
  }
  c.disable_smart_shrinking = true
  c.margin = {
    top: 10,
    bottom: 10,
    left: 10,
    right: 10
  }
  c.javascript_delay = 100
  c.timeout = 10
  c.page_size = 'A4'
  c.print_media_type = true
  c.disable_external_links = true
  c.disable_forms = true
  c.lowquality = false
  c.dpi = 96
end
