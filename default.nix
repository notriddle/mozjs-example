{release ? true}:
let
  dependencies = import ./nix/dependencies.nix;
  pkgs = dependencies.pkgs;
  # Import Cargo.nix with supplied arguments.
  cargoNix = pkgs.callPackage ./Cargo.nix {
    # Pass the "release" flag on.
    inherit release;
    # Use our version of nixpkgs.
    inherit pkgs;
    nixpkgs = pkgs;
    # Tell it to build with clang (because mozjs needs it).
    stdenv = pkgs.clangStdenv;
  };
in
cargoNix.rootCrate.build
