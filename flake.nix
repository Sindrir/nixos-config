{
  description = "Nixos config flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvf.url = "github:notashelf/nvf";
    wezterm.url = "github:wezterm/wezterm?dir=nix";
    #nixgl = {
    #  url = "github:nix-community/nixGL";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};
  };

  outputs =
    inputs @ {
      #self,
      nixpkgs
    , nvf
    , home-manager
    , #nixgl,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      #overlays = [inputs.nixgl.overlay];
      configModule = {
        config.vim = {
          theme.enable = true;
        };
      };
      customNeovim = nvf.lib.neovimConfiguration {
        inherit pkgs;
        modules = [ configModule ];
      };
    in
    {
      packages.${system}.my-neovim = customNeovim.neovim;

      checks.${system} = {
        nixpkgs-fmt = pkgs.runCommand "check-nixpkgs-fmt" { } ''
          ${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt --check ${./.}
          touch $out
        '';
        statix = pkgs.runCommand "check-statix" { } ''
          ${pkgs.statix}/bin/statix check ${./.}
          touch $out
        '';
        deadnix = pkgs.runCommand "check-deadnix" { } ''
          ${pkgs.deadnix}/bin/deadnix --fail ${./.}
          touch $out
        '';
      };
      # use "nixos", or your hostname as the name of the configuration
      # it's a better practice than "default" shown in the video

      # NixOS 'nixos-rebuild --flake .#HOST
      nixosConfigurations = {
        home-desktop = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/home-desktop/configuration.nix
            home-manager.nixosModules.default
            {
              home-manager = {
                extraSpecialArgs = {
                  inherit inputs;
                };
                useGlobalPkgs = true;
                users.sindreo = import ./home-manager/sindreo.nix;
                backupFileExtension = "bak";
              };
            }
          ];
        };
        work-laptop = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/work-laptop/configuration.nix
            home-manager.nixosModules.default
            {
              home-manager = {
                extraSpecialArgs = {
                  inherit inputs;
                };
                useGlobalPkgs = true;
                users.sindreo = import ./home-manager/sindreo.nix;
                backupFileExtension = "bak";
              };
            }
          ];
        };
      };

      # Standalone home-manager 'home-manager --flake .#USERNAME
      homeConfigurations = {
        sindreo = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit inputs;
            #inherit nixgl;
          };
          modules = [
            { home.packages = [ customNeovim.neovim ]; }
            ./home-manager/sindreo.nix
          ];
        };
      };
    };
}
