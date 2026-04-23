{
  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-25.11/nixexprs.tar.xz";
  };
  outputs = { self, nixpkgs, ... }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
    in
    {
      nixosModules.default = import ./module.nix;
      packages.x86_64-linux.scientific-fhs = pkgs.callPackage ./fhs.nix {
        enableNVIDIA = false;
        enableGraphical = true;
        juliaVersion = "1.10.1";
      };
      devShells.x86_64-linux.scientific-fhs = (pkgs.callPackage ./fhs.nix {
        enableNVIDIA = false;
        enableGraphical = true;
        juliaVersion = "1.12.5";
      }).env;
    };
}
