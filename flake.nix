{
  description = "LogiOps fork with the ToggleSmartHires scroll-mode action";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Mirrors the `src/ipcgull` submodule. A git flake source does not
    # include submodule contents, so the package splices this tree in.
    ipcgull = {
      url = "github:PixlOne/ipcgull/cd0f9a8cefb5b2545e163fceb249fdbcbaf666aa";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    ipcgull,
  }: let
    systems = ["x86_64-linux" "aarch64-linux"];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

    logiopsFor = pkgs:
      pkgs.logiops.overrideAttrs (old: {
        pname = "logiops";
        version = "0.3.5-unstable-2026-10-27";

        # `path:` inputs copy the working tree as-is, including the local
        # CMake `build/` directory. Drop it (and local caches) so CMake does
        # not reuse a cache generated from a different checkout path.
        src = pkgs.lib.cleanSourceWith {
          src = self.outPath;
          filter = path: type: let
            base = builtins.baseNameOf (toString path);
          in
            base != "build" && base != ".cache" && base != ".sisyphus";
        };

        postPatch =
          (old.postPatch or "")
          + ''
            rm -rf src/ipcgull
            cp -r ${ipcgull} src/ipcgull
          '';
      });
  in {
    packages = forAllSystems (pkgs: {
      default = logiopsFor pkgs;
      logiops = logiopsFor pkgs;
    });

    overlays.default = final: prev: {
      logiops = logiopsFor prev;
    };
  };
}
