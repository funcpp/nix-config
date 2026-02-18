{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
    }:
    let
      system = "aarch64-darwin";
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#simple
      darwinConfigurations."sushi" = nix-darwin.lib.darwinSystem {
        inherit system;

        modules = [
          (
            { pkgs, ... }:
            {
              nix.enable = false;
              nix.settings.experimental-features = "nix-command flakes";
              system.configurationRevision = self.rev or self.dirtyRev or null;
              system.stateVersion = 6;
              system.primaryUser = "sushi";
              nixpkgs.hostPlatform = system;

              system.defaults = {
                NSGlobalDomain = {
                  ApplePressAndHoldEnabled = false;
                  KeyRepeat = 2;
                  InitialKeyRepeat = 15;
                  "com.apple.keyboard.fnState" = true;
                };
                dock = {
                  autohide = true;
                  show-recents = false;
                };
                trackpad = {
                  Clicking = true;
                };
              };

              homebrew = {
                enable = true;
                casks = [
                  "ghostty"
                  "discord"
                  "rectangle"
                  "jetbrains-toolbox"
                  "brave-browser"
                  "claude"
                  "karabiner-elements"
                ];
                masApps = {
                  WireGuard = 1451685025;
                };
              };
            }
          )

          home-manager.darwinModules.home-manager

          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "bak";

            home-manager.users.sushi =
              { pkgs, ... }:
              {
                home.stateVersion = "24.11";

                home.packages = with pkgs; [
                  nixfmt
                  tmux
                  rustup
                  bun
                  jq
                  gh
                  awscli2
                  postgresql
                  duckdb
                  typescript
                  typescript-language-server
                  glow
                  uv
                ];

                programs.tmux.enable = true;
                programs.zsh = {
                  enable = true;
                  shellAliases = {
                    ll = "ls -la";
                    rebuild = "darwin-rebuild switch --flake ~/.config/nix#sushi";
                    c = "clear";
                    cc = "claude";
                    w = "cd ~/workspace";
                    ".." = "cd ..";
                    "..." = "cd ../..";
                  };
                  initContent = builtins.readFile ./config/zsh/config;
                };
                home.file.".config/ghostty/config".source = ./config/ghostty/config;
              };

            users.users.sushi.home = "/Users/sushi";
          }
        ];
      };
    };
}
