{
  description = "linkray";

  inputs = {
    # NixOS 23.11 has recent enough versions of capnproto and protobuf to
    # develop on Veilid.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    ddcp.url = "github:cmars/ddcp";
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, ddcp }:
    (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            rust-overlay.overlays.default
          ];
        };

        libraries = with pkgs; [
          webkitgtk
          gtk3
          cairo
          gdk-pixbuf
          glib
          dbus
          openssl_3
          librsvg
        ];

        packages = with pkgs; [
          curl
          wget
          pkg-config
          dbus
          openssl_3
          glib
          gtk3
          libsoup
          webkitgtk
          librsvg

          nodejs_20
        ];

        arch = flake-utils.lib.system.system;

      in {

        devShells.default = pkgs.mkShell {
          buildInputs = packages ++ (with pkgs; [
            # Inherit DDCP development environment
            ddcp.devShells.${system}.default.buildInputs
          ]);
          
          shellHook =
            ''
              export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath libraries}:$LD_LIBRARY_PATH
              export XDG_DATA_DIRS=${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS
            '';
        };
      }
    ));
}
