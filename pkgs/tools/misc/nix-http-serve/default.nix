{ stdenv, fetchFromGitHub, callPackage, haskellPackages, gzip, pandoc }:

with stdenv.lib;

let
  name = "nix-http-serve";
  version = "0.1.0.0";
  src = fetchFromGitHub {
    owner = "Profpatsch";
    repo = name;
    rev = "6360bcd5bc4aeb2f5c31a0ed54f09e9cc3a6a45e";
    sha256 = "1gq1j34g0khfp4sabb8d9zff3rqhdk9ynh3gyf84hh29nyw6h611";
  };
  calledSrc = callPackage src {};


in
stdenv.mkDerivation {
  inherit name version src;
  inherit (calledSrc) buildInputs buildPhase installPhase;

  meta = {
    description = "Serves the result of a nix build as static http files";
    license = licenses.gpl3;
    maintainer = with maintainers; [ profpatsch ];
  };
}
