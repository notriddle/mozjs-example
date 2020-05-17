# This is a file we'll write ourselves to make it easier to ensure that configurations stay the same between each environment, both build and dev.

let
  sources = import ./sources.nix;
  pkgs = import sources.nixpkgs { };
in
{
  # This will import our pinned instance of the nixpkgs upstream repository.
  inherit pkgs;
  # This will contain all of the CLI tools that our shell uses.
  devDeps = [
    (import sources.crate2nix {inherit pkgs;})
    pkgs.cargo
    pkgs.llvm
    pkgs.autoconf213
  ];
  # Pinned versions of other tools.
  libclang = pkgs.llvmPackages.libclang;
}
