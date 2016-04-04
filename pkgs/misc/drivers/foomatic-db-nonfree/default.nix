{ stdenv, fetchurl, perl, libxml2 }:

stdenv.mkDerivation rec {
  name = "foomatic-db-nonfree";
  version = "20160331";

  src = fetchurl {
    url = "https://www.openprinting.org/download/foomatic/foomatic-db-nonfree-${version}.tar.gz";
    sha256 = "1kwcjs5yqg14bnq0ncclpajy3k209cfzils4qpcdxrdvnbhx0ybl";
  };

  preConfigure = ''
    ./make_configure
  '';

  buildInputs = [ perl libxml2 ];

  installFlags = "DESTDIR=$(out)";

  postFixup = ''
    mv $out/usr/share $out/share
    rmdir $out/usr
  '';
}
