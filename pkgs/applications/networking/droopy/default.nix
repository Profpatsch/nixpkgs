{ lib, fetchFromGitHub, buildPythonApplication }:

with lib;

buildPythonApplication rec {
  name = "droopy-${version}";
  version = "20160830";

  src = fetchFromGitHub {
    owner = "stackp";
    repo = "Droopy";
    rev = "7a9c7bc46c4ff8b743755be86a9b29bd1a8ba1d9";
    sha256 = "03i1arwyj9qpfyyvccl21lbpz3rnnp1hsadvc0b23nh1z2ng9sff";
  };

  phases = [ "unpackPhase" "installPhase" "fixupPhase" ];

  installPhase = ''
    mkdir -p $out/bin
    shopt -s extglob
    # copy everything but these files
    cp -r !(Readme.md|img) $out
    shopt -u extglob

    cd $out/bin
    ln -s ../droopy .
  '';

  meta = {
    description = "Mini Web server that let others upload files to your computer";
    homepage = http://stackp.online.fr/droopy;
    license = licenses.bsd3;
    maintainers = maintainers.profpatsch;
  };

}
