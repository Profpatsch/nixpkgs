{ pkgs ? import ((import ../.).cleanSource ../..) {} }:

pkgs.stdenv.mkDerivation {
  name = "nixpkgs-lib-tests";
  buildInputs = [ pkgs.nix ];
  NIX_PATH="nixpkgs=${pkgs.path}";

  buildCommand = ''
    source ${pkgs.setupLocalNixStore}

    cd ${pkgs.path}/lib/tests
    ./modules.sh

    [[ "$(nix-instantiate --eval --strict misc.nix)" == "[ ]" ]]

    [[ "$(nix-instantiate --eval --strict systems.nix)" == "[ ]" ]]

    touch $out
  '';
}
