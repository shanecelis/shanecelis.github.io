{
  description = "Development environment for shanecelis.github.io";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";

  outputs = { nixpkgs, ... }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          gh-pages = pkgs.writeShellScriptBin "gh-pages" ''
            # gh-pages locates its clone cache with find-cache-dir, which gives up
            # unless it finds a package.json. This is a Zola site, so point it at
            # the user cache directory instead.
            export CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}"
            exec ${pkgs.nodejs}/bin/npx --yes gh-pages@5.0.0 "$@"
          '';
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              zola
              codebraid
              pandoc
              gnumake
              gnused
              gawk
              fswatch
              rustc
              cargo
              nodejs
              git
              gh-pages
            ];
          };
        });
    };
}
