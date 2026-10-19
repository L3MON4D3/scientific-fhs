{
  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.xz";
    jetls.url = "github:l3mon4d3/jetls-nix";
  };
  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      fhs = pkgs.callPackage ./fhs.nix {
        jetls = inputs.jetls.packages.${system}.jetls;
        enableNVIDIA = false;
        enableGraphical = true;
        juliaVersion = "1.12.5";
      };
    in
    {
      nixosModules.default = import ./module.nix;
      packages.x86_64-linux.scientific-fhs = fhs;
      devShells.x86_64-linux.default = fhs.env;
    };
}
