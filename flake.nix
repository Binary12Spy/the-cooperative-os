{
  description = "the-cooperative-os — reproducible dev environment for rendering the paper";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          name = "the-cooperative-os";

          packages = with pkgs; [
            pandoc        # render the paper (.md) to a self-contained static HTML
            zip           # bundle the rendered page for static hosting
          ];

          shellHook = ''
            echo "the-cooperative-os dev shell"
            echo "  pandoc: $(pandoc --version | head -1)"
            echo "  build:  ./site/build.sh && ./site/package.sh"
          '';
        };
      });
}
