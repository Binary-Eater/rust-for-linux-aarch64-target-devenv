{ pkgs ? import <nixpkgs> {}, unstable ? import <nixos-unstable> {} }:

let
  binutils = unstable.binutils; # need binutils >=2.39 for DWARF5 debuginfo
  llvmPackages_14 = unstable.llvmPackages_17;

  sphinx = unstable.sphinx; # need sphinx >=5.x.x due to https://github.com/sphinx-doc/sphinx/issues/10495
in
pkgs.pkgsCross.aarch64-multiplatform.mkShell {
  SPHINXBUILD = "${pkgs.sphinx}/bin/sphinx-build";
  TERMINFO_DIRS = "/run/current-system/sw/share/terminfo"; # make menuconfig
	RUST_LIB_SRC = "${unstable.rust.packages.stable.rustPlatform.rustLibSrc}";
  C_INCLUDE_PATH = "${pkgs.openssl.dev}/include";
  LIBRARY_PATH = "${pkgs.openssl.out}/lib";

  # Disable things like clang stack protector
  hardeningDisable = [ "all" ]; # needed by make samples/bpf

  nativeBuildInputs = with pkgs; [
    bc
    bison
    binutils
    llvmPackages_14.clang
    flex
    gcc
    gnumake
    llvmPackages_14.llvm
    perl

    git # checkpatch

    elfutils # used by tools/ which is run on build host
    openssl  # used by certs/ which is run on build host

    # used by scripts/clang-tools/gen_compile_commands.py
    (python3.withPackages (p: with p; [
      # used by scripts/checkpatch.pl
      GitPython
      ply
    ]))

    # Used by make rpm-pkg and make binrpm-pkg.
    rpm
    rsync

    # Rust dev
    unstable.rustc
    unstable.rust-bindgen
    unstable.rustfmt
    unstable.clippy

    man
    mandoc

    pahole # BTF support
    which  # needed by make sample/bpf

    less

    # Used by make htmldocs and make pdfdocs.
    sphinx
    imagemagick
    graphviz
    librsvg
    (texlive.combine {
      inherit (texlive)
        scheme-full
        fontspec
        euenc
        # Used by make pdfdocs.
        xetex
        xetexref;
    })
  ];
}
