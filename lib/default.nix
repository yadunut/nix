# Utility functions for the nut-clan configuration
{
  # Collect all files in a directory and return their full paths
  # This is useful for importing all Nix modules from a directory
  #
  # Example:
  #   collectNixFiles ./modules
  #   => [ ./modules/file1.nix ./modules/file2.nix ]
  #
  # Type: Path -> [Path]
  collectNixFiles = path: map (name: path + "/${name}") (builtins.attrNames (builtins.readDir path));
}
