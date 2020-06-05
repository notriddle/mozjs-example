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
in
cargoNix.rootCrate.build.override {
  crateOverrides = pkgs.defaultCrateOverrides // {
    encoding_c_mem = {src, ...}: {
      # Copy .h files from target directory to output directory.
      # encoding_c_mem assumes that its include file in target/ will be
      # available to crates that depend on it. This is not true in Nix.
      postInstall = ''
        echo "export DEP_ENCODING_C_MEM_INCLUDE_DIR=$lib/include" > $lib/env
        cp include -rP $lib/include
      '';
    };
    mozjs-example = {src, ...}: {
      # Expose libclang.
      extraRustcOpts=["-C" "linker=${pkgs.llvmPackages.clang}/bin/clang" "-C" "link-arg=-fuse-ld=${pkgs.llvmPackages.lld}/bin/ld.lld"];
      LIBCLANG_PATH = "${dependencies.libclang.lib}/lib";
      CLANGFLAGS="-isystem ${pkgs.clangStdenv.lib.getDev pkgs.clangStdenv.cc.cc}/lib/clang/${pkgs.clangStdenv.cc.cc.version}/include -isystem ${pkgs.clangStdenv.cc.cc.gcc}/include/c++/${pkgs.clangStdenv.cc.cc.gcc.version}/${pkgs.hostPlatform.config} -isystem ${pkgs.clangStdenv.cc.cc.gcc}/include/c++/${pkgs.clangStdenv.cc.cc.gcc.version} -isystem ${pkgs.clangStdenv.lib.getDev pkgs.clangStdenv.cc.libc}/include";
      CC="${pkgs.llvmPackages.clang}/bin/clang";
      CXX="${pkgs.llvmPackages.clang}/bin/clang";
      LD="${pkgs.llvmPackages.lld}/bin/ld.lld";
      # Tell it to pull in all our specified deps (like autoconf).
      buildInputs = dependencies.devDeps;
    };
    mozjs = {src, ...}: {
      # Expose libclang.
      extraRustcOpts=["-C" "linker=${pkgs.llvmPackages.clang}/bin/clang" "-C" "link-arg=-fuse-ld=${pkgs.llvmPackages.lld}/bin/ld.lld"];
      LIBCLANG_PATH = "${dependencies.libclang.lib}/lib";
      CLANGFLAGS="-isystem ${pkgs.clangStdenv.lib.getDev pkgs.clangStdenv.cc.cc}/lib/clang/${pkgs.clangStdenv.cc.cc.version}/include -isystem ${pkgs.clangStdenv.cc.cc.gcc}/include/c++/${pkgs.clangStdenv.cc.cc.gcc.version}/${pkgs.hostPlatform.config} -isystem ${pkgs.clangStdenv.cc.cc.gcc}/include/c++/${pkgs.clangStdenv.cc.cc.gcc.version} -isystem ${pkgs.clangStdenv.lib.getDev pkgs.clangStdenv.cc.libc}/include";
      CC="${pkgs.llvmPackages.clang}/bin/clang";
      CXX="${pkgs.llvmPackages.clang}/bin/clang";
      LD="${pkgs.llvmPackages.lld}/bin/ld.lld";
      # Tell it to pull in all our specified deps (like autoconf).
      buildInputs = dependencies.devDeps;
    };
    mozjs_sys = {src, ...}: {
      # Expose libclang.
      extraRustcOpts=["-C" "linker=${pkgs.llvmPackages.clang}/bin/clang" "-C" "link-arg=-fuse-ld=${pkgs.llvmPackages.lld}/bin/ld.lld"];
      LIBCLANG_PATH = "${dependencies.libclang.lib}/lib";
      CLANGFLAGS="-isystem ${pkgs.clangStdenv.lib.getDev pkgs.clangStdenv.cc.cc}/lib/clang/${pkgs.clangStdenv.cc.cc.version}/include -isystem ${pkgs.clangStdenv.cc.cc.gcc}/include/c++/${pkgs.clangStdenv.cc.cc.gcc.version}/${pkgs.hostPlatform.config} -isystem ${pkgs.clangStdenv.cc.cc.gcc}/include/c++/${pkgs.clangStdenv.cc.cc.gcc.version} -isystem ${pkgs.clangStdenv.lib.getDev pkgs.clangStdenv.cc.libc}/include";
      CC="${pkgs.llvmPackages.clang}/bin/clang";
      CXX="${pkgs.llvmPackages.clang}/bin/clang";
      LD="${pkgs.llvmPackages.lld}/bin/ld.lld";
      # Tell it to pull in all our specified deps (like autoconf).
      buildInputs = dependencies.devDeps;
      prePatch = ''
        # Remove reference to /usr/bin/env from build scripts,
        # because that app doesn't actually exist in the Nix build sandbox.
        substituteInPlace makefile.cargo --replace '/usr/bin/env bash' '${pkgs.bash}/bin/bash'
      '';
      # Copy .h files from target directory to output directory.
      # mozjs_sys assumes that its include file in target/ will be
      # available to crates that depend on it. This is not true in Nix.
      postInstall = ''
        echo "export DEP_MOZJS_OUTDIR=$lib/lib/mozjs_sys.out/build/" > $lib/env
        cd $lib/lib/mozjs_sys.out/build/
        xd=$(pwd)
        find . | grep -v virtualenv | while read path; do
          target=`readlink $path || true`
          if [ -n "$target" ]; then
            dirname=`dirname $path`
            filename=`basename -s "" $path`
            cd "$dirname"
            echo "$target => $path"
            rm -f "$filename"
            cp -f "$target" "$filename"
            cd "$xd"
          fi
        done
      '';
    };
  };
}

