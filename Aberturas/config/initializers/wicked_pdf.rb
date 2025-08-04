WickedPdf.configure do |c|
  # Path to the wkhtmltopdf executable: This usually isn't needed if using
  # one of the wkhtmltopdf-binary family of gems.
  # exe_path: '/usr/local/bin/wkhtmltopdf',
  #   or
  # exe_path: Gem.bin_path('wkhtmltopdf-binary', 'wkhtmltopdf')

  # Layout file to be used for all PDFs
  # (but can be overridden in `render :pdf` calls)
  # layout: 'pdf.html',

  # Using wkhtmltopdf without an X server can be achieved by enabling the
  # 'use_xvfb' flag. This will wrap all wkhtmltopdf calls in a 'xvfb-run'
  # command, in order to simulate an X server.
  #
  # use_xvfb: true,

  # You can specify default options for all PDFs here.
  # These can be overridden in individual calls to `render :pdf`
  c.enable_local_file_access = true
  c.disable_smart_shrinking = true
  c.margin = {
    top: 10,
    bottom: 10,
    left: 10,
    right: 10
  }
  c.javascript_delay = 2000
  c.timeout = 120
end
