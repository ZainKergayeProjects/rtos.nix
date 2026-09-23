{
  description = "Nix RTOS devshell flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    freertos = {
      url = "git+https://github.com/raspberrypi/FreeRTOS-Kernel.git?submodules=1";
      flake = false;
    };
    unity = {
      url = "git+https://github.com/ThrowTheSwitch/Unity.git";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      freertos,
      unity,
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
        default = self.packages.${system}.pico-sdk-overriden;
        pico-sdk-overriden = pkgs.${system}.pico-sdk.override { withSubmodules = true; };
      });

      devShells = forAllSystems (system: {
        default = pkgs.${system}.mkShellNoCC {
          packages = with pkgs.${system}; [
            cmake
            gcc-arm-embedded
            picotool
            openocd-rp2040
            picotool
            pioasm
            self.packages.${system}.pico-sdk-overriden
          ];
          shellHook = ''
            export PICO_SDK_PATH=${self.packages.${system}.pico-sdk-overriden}/lib/pico-sdk
            export FREERTOS_PATH=${freertos}
            export OPENOCD_PATH=${pkgs.${system}.openocd}
            export UNITY_PATH=${unity}


            echo "Welcome to dev shell. Imported PICO_SDK_PATH, FREERTOS_PATH, and OPENOCD_PATH"
          '';
        };
      });

      # To limit flake inputs on other projects
      freertos = freertos;

      unity = unity;

      nixpkgs = nixpkgs;
    };
}
