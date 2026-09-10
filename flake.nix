{
  description = "A native, sandboxed build recipe using a local cloned tree";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        microtex = pkgs.fetchFromGitHub {
          owner = "kpeeters";
          repo = "MicroTeX";
          rev = "7944eb496dec1b7ff8af4c13e0cfee279eea30b8";
          sha256 = "0imzv2c8byqnl26ragh38vx3krwbfzglvmbgmrmqkvrw5ycvjg88";
        };
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "cadabra2-local";
          version = "dev";

          src = ./.;

          preConfigure = ''
            mkdir -p submodules
            rm -rf submodules/microtex
            cp -r ${microtex} submodules/microtex
            chmod -R u+w submodules/microtex
          '';

          enableParallelBuilding = true;
          nativeBuildInputs = [
            pkgs.cmake
            pkgs.pkg-config
            pkgs.wrapGAppsHook3 # Configures GTK schema hooks cleanly
          ];

          buildInputs = [
            pkgs.openssl
            pkgs.boost
            pkgs.gmp
            pkgs.sqlite
            pkgs.libuuid
            pkgs.fontconfig
            pkgs.glib
            pkgs.glibmm
            pkgs.gtk3
            pkgs.gtkmm3
            pkgs.adwaita-icon-theme
            pkgs.cairo
            pkgs.pango

            (pkgs.python3.withPackages (ps: [
              ps.sympy
              ps.gmpy2
              ps.matplotlib
              ps.pyzmq
            ]))
          ];

          cmakeFlags = [
            "-DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF"
            "-DPYTHON_SITE_PATH=lib/${pkgs.python3.libPrefix}/site-packages"
          ]
          ++ (
            if pkgs.stdenv.isDarwin then
              [
                # These flags will ONLY be appended when building on macOS
                "-DENABLE_MATHEMATICA=OFF"
              ]
            else
              [
                # These flags will ONLY be appended when building on Linux/other platforms
              ]
          );

          meta = {
            description = "Local compilation sandbox for Cadabra2";
            homepage = "https://cadabra.science";
            license = pkgs.lib.licenses.gpl3Plus;
          };
        };
      }
    );
}
