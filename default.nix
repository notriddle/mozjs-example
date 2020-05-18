# Allows you to specify if this is a release build on the CLI
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
  mozjs-example = cargoNix.rootCrate.build.override {
    crateOverrides = pkgs.defaultCrateOverrides // {
      mozjs = {src, ...}: {
        # Tell it to pull in all our specified deps (like autoconf).
        buildInputs = dependencies.devDeps;
      };
      mozjs_sys = {src, ...}: {
        # Tell it to pull in all our specified deps (like autoconf).
        buildInputs = dependencies.devDeps;
      };
    };
  };
in
mozjs-example
