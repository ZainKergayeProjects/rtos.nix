{
  description = "Nix RTOS devshell flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.freertos = {
    url = "git+https://github.com/raspberrypi/FreeRTOS-Kernel.git?submodules=1";
    flake = false;
  };

  outputs =
    {
      self,
      nixpkgs,
      freertos,
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgs = forAllSystems (system: nixpkgs.legacyPackages.${system});
    in
    {
      templates.default = {
        path = ./template;
        description = "Nix RTOS flake template";
      };

      packages = forAllSystems (system: {
        default = pkgs.${system}.hello;
      });

      devShells = forAllSystems (system: {
        default = pkgs.${system}.mkShellNoCC {
          packages = with pkgs.${system}; [
            cmake
            gcc-arm-embedded
            picotool
            openocd
            python314Packages.robotframework # Test framework
            renode
            pico-sdk
          ];
          shellHook = ''
						export PICO_SDK_PATH=${pkgs.${system}.pico-sdk}/lib/pico-sdk
						export FREERTOS_PATH=${freertos}
						export OPENOCD_PATH=${pkgs.${system}.openocd}

						echo "Welcome to dev shell. Imported PICO_SDK_PATH, FREERTOS_PATH, and OPENOCD_PATH"
          '';
        };
      });
    };
}
