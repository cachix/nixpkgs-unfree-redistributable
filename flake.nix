{
  description = "Redistributable unfree packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    cachix.url = "github:cachix/cachix";
  };

  outputs = { self, darwin, nixpkgs, cachix }:
    let
      pkgs = import nixpkgs { system = "aarch64-darwin"; };
      systems = nixpkgs.lib.platforms.linux ++ nixpkgs.lib.platforms.darwin;

      # TODO: expose in lib
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
 
      # TODO: this should be in lib and deduplicated across all nixpkgs 
      packagesWith = cond: return: set:
        (nixpkgs.lib.flatten
        (nixpkgs.lib.mapAttrsToList
            (name: pkg:
            let
                result = builtins.tryEval
                (
                    if nixpkgs.lib.isDerivation pkg && cond name pkg then
                    # Skip packages whose closure fails on evaluation.
                    # This happens for pkgs like `python27Packages.djangoql`
                    # that have disabled Python pkgs as dependencies.
                    builtins.seq pkg.outPath
                        [ (return name pkg) ]
                    else if pkg.recurseForDerivations or false || pkg.recurseForRelease or false
                    then packagesWith cond return pkg
                    else [ ]
                );
            in
            if result.success then result.value
            else [ ]
            )
            set
        )
        );

      isRedistributable = pkg: 
        let
          pred = license: nixpkgs.lib.isAttrs license && (license.redistributable or true) && !(license.free or true);
        in
        if pkg ? meta.license 
        then if nixpkgs.lib.isList pkg.meta.license 
            then nixpkgs.lib.any pred pkg.meta.license 
            else pred pkg.meta.license
        else false;
      
    in {
      legacyPackages = forAllSystems (system: 
        let 
            pkgs = import nixpkgs {
                inherit system;
                config = { allowUnfreePredicate = isRedistributable; };
            };
        in nixpkgs.lib.listToAttrs (packagesWith (name: pkg: isRedistributable pkg) (name: pkg: { name = "${name}"; value = pkg; } ) pkgs)
      );

      defaultPackage = forAllSystems (system: 
        pkgs.writeText "cachix-agents.json" (builtins.toJSON {
          agents = {
            unfree-m1 = (darwin.lib.darwinSystem {
              system = "aarch64-darwin";
              modules = [ 
                ./agents/m1.nix 
                (darwin + "/pkgs/darwin-installer/installer.nix") 
                # get the latest cachix development version
                { services.cachix-agent.package = import cachix { inherit system; };
                } 
              ];
            }).system;
          };
        })
      );
    };
}
