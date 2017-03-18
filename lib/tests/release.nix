{ nixpkgs }:

with import ../.. { };
with lib;

stdenv.mkDerivation {
  name = "nixpkgs-lib-tests";
  buildInputs = [ nix ];
  buildCommand = ''
    source ${import ./local-nix-store.nix { inherit nixpkgs nix writeText; }}

    cd ${nixpkgs}/lib/tests
    ./modules.sh

    touch $out
  '';
}
