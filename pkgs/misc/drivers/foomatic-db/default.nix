{ stdenv, fetchurl, perl, libxml2 }:

stdenv.mkDerivation rec {
  name = "foomatic-db";
  version = "4.0-20160331";

  src = fetchurl {
    url = "https://www.openprinting.org/download/foomatic/foomatic-db-${version}.tar.gz";
    sha256 = "0c0viv92sf7wj6zymp7p61m1f93wg9m744phq61f6hsbnddxqzwk";
  };

  buildInputs = [ perl libxml2 ];

  preConfigure = ''
    ./make_configure
  '';
  

}
