{
  description = "OpenCode - A powerful terminal-based AI assistant for developers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forEachSystem =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f {
            pkgs = nixpkgs.legacyPackages.${system};
            inherit system;
          }
        );
    in
    {
      packages = forEachSystem (
        { pkgs, system }:
        let
          opencode = pkgs.callPackage ./package.nix { };
          openspec = pkgs.callPackage ./openspec.nix { };
        in
        {
          inherit opencode openspec;
          opencode-nvim = pkgs.callPackage ./opencode-nvim.nix { inherit opencode; };
          default = opencode;
        }
      );

      apps = forEachSystem (
        { pkgs, system }:
        {
          opencode = {
            type = "app";
            program = "${self.packages.${system}.opencode}/bin/opencode";
          };
          default = self.apps.${system}.opencode;
        }
      );

      devShells = forEachSystem (
        { pkgs, system }:
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              self.packages.${system}.opencode
              self.packages.${system}.openspec
              self.packages.${system}.opencode-nvim
            ];
          };
        }
      );

      checks = forEachSystem (
        { pkgs, system }:
        {
          opencode = self.packages.${system}.opencode;
          opencode-version = self.packages.${system}.opencode.passthru.tests.version;
          openspec = self.packages.${system}.openspec;
          openspec-version = self.packages.${system}.openspec.passthru.tests.version;
          opencode-nvim = self.packages.${system}.opencode-nvim;
        }
      );
    };
}
