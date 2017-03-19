{ nixpkgs }:

with import ../.. { };
with lib;

stdenv.mkDerivation {
  name = "nixpkgs-lib-tests";
  buildInputs = [ nix ];
  buildCommand = ''
    source ${callPackage ./local-nix-store { inherit nixpkgs; }}

    cd ${nixpkgs}/lib/tests
    ./modules.sh

    touch $out
  '';
}
