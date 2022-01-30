# Used by "mix format"
[
  import_deps: [:phoenix, :open_api_spex],
  inputs: ["*.{ex,exs}", "priv/*/seeds.exs", "{config,lib,lib_dev,test}/**/*.{ex,exs}"],
  subdirectories: ["priv/*/migrations"]
]
