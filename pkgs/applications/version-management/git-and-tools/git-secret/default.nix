{ stdenv, lib, fetchFromGitHub, makeWrapper, git, gnupg }:

let
  version = "0.2.3";
  repo = "git-secret";

in stdenv.mkDerivation {
  name = "${repo}-${version}";

  src = fetchFromGitHub {
    inherit repo;
    owner = "sobolevn";
    rev = "v${version}";
    sha256 = "1swgw91zzs9n582500a34cppyngrqrqrnl80d1vd7i93xx1lkmv6";
  };

  buildInputs = [ makeWrapper ];

  installPhase = ''
    install -D git-secret $out/bin/git-secret

    wrapProgram $out/bin/git-secret \
      --prefix PATH : "${lib.makeBinPath [ git gnupg ]}"

    mkdir $out/share
    cp -r man $out/share
  '';

  meta = {
    description = "A bash-tool to store your private data inside a git repository";
    homepage = http://git-secret.io;
    license = stdenv.lib.licenses.mit;
    maintainers = [ stdenv.lib.maintainers.lo1tuma ];
    platforms = stdenv.lib.platforms.all;
  };
}
