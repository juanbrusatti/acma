# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Include the builds directory where Tailwind output is written
Rails.application.config.assets.paths << Rails.root.join("app/assets/builds")

# Explicitly precompile the Tailwind bundle so it is served as /assets/tailwind.css
Rails.application.config.assets.precompile += %w[ tailwind.css ]
