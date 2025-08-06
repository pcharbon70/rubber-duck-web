[
  import_deps: [:ash_admin, :ash_authentication, :ash_phoenix, :ash, :reactor, :phoenix],
  plugins: [Spark.Formatter, Phoenix.LiveView.HTMLFormatter],
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}"]
]
