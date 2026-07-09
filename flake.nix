{
  description = "Simple C++ bindings for the SoulverCore Swift library";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # libxml2 2.14+ bumped its soname to .so.16. the Swift binaries want libxml2.so.2.
    nixpkgs-libxml2.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-libxml2,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    libxml2-compat = nixpkgs-libxml2.legacyPackages.${system}.libxml2;

    # nixpkgs is still on v5 at the time of writing, 6.1.2 isn't the latest but it is the one that's used to build SoulcerCore
    swift-bin = pkgs.stdenv.mkDerivation rec {
      pname = "swift-bin";
      version = "6.1.2";

      src = pkgs.fetchurl {
        url = "https://download.swift.org/swift-${version}-release/ubuntu2404/swift-${version}-RELEASE/swift-${version}-RELEASE-ubuntu24.04.tar.gz";
        hash = "sha256-10nV/i1nCe6YjpaxbwK8p7UzBNCZJeMQY/1exWAZ3p8=";
      };

      nativeBuildInputs = [pkgs.autoPatchelfHook];

      buildInputs = with pkgs; [
        stdenv.cc.cc.lib
        zlib
        icu
        curl
        libxml2-compat
        ncurses
        libedit
        sqlite
        python312
        util-linux
      ];

      # only lldb wants this old soname
      autoPatchelfIgnoreMissingDeps = ["libedit.so.2"];

      installPhase = ''
        mkdir -p $out
        cp -a usr/* $out/
        rm $out/bin/clang $out/bin/clang++
        ln -s ${pkgs.clang}/bin/clang $out/bin/clang
        ln -s ${pkgs.clang}/bin/clang++ $out/bin/clang++
      '';
    };
  in
    {
      packages.${system}.default = pkgs.stdenv.mkDerivation {
        pname = "soulver-cpp";
        version = "1.0.0";

        src = ./.;

        nativeBuildInputs = with pkgs; [
          cmake
          ninja
          swift-bin
          autoPatchelfHook
        ];

        buildInputs = with pkgs; [
          nlohmann_json
          stdenv.cc.cc.lib
          # runtime deps of bundled Swift runtime libs.
          curl
          zlib
        ];

        preConfigure = ''
          export HOME=$TMPDIR
          mkdir -p $TMPDIR/sysroot/usr/lib
          ln -s ${pkgs.glibc.dev}/include $TMPDIR/sysroot/usr/include
          ln -s ${pkgs.glibc}/lib/* $TMPDIR/sysroot/usr/lib/
          ln -s ${swift-bin}/lib/swift $TMPDIR/sysroot/usr/lib/swift
          export SDKROOT=$TMPDIR/sysroot
          export CPATH=${pkgs.glibc.dev}/include
        '';

        preBuild = ''
          autoPatchelf swift/Vendor/SoulverCore-linux/
        '';

        postInstall = ''
          cp -a ${swift-bin}/lib/swift/linux/*.so* $out/lib/
          chmod -R u+w $out/lib
          rm -f $out/lib/libFoundationXML.so
        '';

        meta = with pkgs.lib; {
          description = "C++ bindings for the SoulverCore Swift library";
          homepage = "https://github.com/vicinaehq/soulver-cpp";
          platforms = platforms.linux;
          license = licenses.unfree;
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        inputsFrom = [self.packages.${system}.default];
        shellHook = ''
          export LD_LIBRARY_PATH=$PWD/swift/Vendor/SoulverCore-linux:$PWD/build/swift_output:$LD_LIBRARY_PATH
        '';
      };
    }
    // {
      overlays.default = final: prev: {
        soulver-cpp = self.packages.${prev.stdenv.hostPlatform.system}.default;
      };
    };
}
