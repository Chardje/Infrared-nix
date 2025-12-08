{
  description = "A Minecraft Reverse Proxy flake of package+module";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: let
    systems = [ "x86_64-linux" "aarch64-linux" ];
  in {
    packages = nixpkgs.lib.genAttrs systems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (self: super: {
              infrared = super.callPackage ./package.nix {};
            })
          ];
        };
      in {
        infrared = pkgs.infrared;
      }
    );

    nixosModules.infrared = import ./module.nix;
  };
}
