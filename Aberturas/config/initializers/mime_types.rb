# Register PDF as a valid MIME type
Mime::Type.register "application/pdf", :pdf unless Mime::Type.lookup_by_extension(:pdf)
