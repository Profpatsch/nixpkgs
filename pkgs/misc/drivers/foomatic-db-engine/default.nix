{ stdenv, fetchurl, makeWrapper, symlinkJoin
, perl, perlPackages
, libxml2, file, cups, foomatic-db
, nonfreeDrivers ? false, foomatic-db-nonfree
}:

with stdenv.lib;

let
  perldir = "/lib/perl5/site_perl";
  perlPkgs = with perlPackages; [ libxml_perl Clone DBI ];

in
stdenv.mkDerivation rec {
  name = "foomatic-db-engine";
  version = "4.0.12";

  src = fetchurl {
    url = "https://www.openprinting.org/download/foomatic/foomatic-db-engine-${version}.tar.gz";
    sha256 = "08bwrv5216j8snay99nhqqsfagalgf8ssqg24mq5ncjvxmv3n536";
  };

  patches = [ ./configure.patch ];
  postPatch = "cat ./configure.ac | grep FILEUTIL";

  configureFlagsArray = [ (
    "PERL=${perl}/bin/perl"
  ) ];

  buildInputs = [ perl libxml2 file makeWrapper ] ++ perlPkgs;
  installFlags = [
    "INSTALLARCHLIB=$(out)${perldir}"
    "INSTALLSITELIB=$(out)${perldir}"
    "INSTALLSITEARCH=$(out)${perldir}"
    "ETCDIR=$(out)/etc"
    "MANDIR=$(out)/share/man"
    "LIBDIR=$(out)/lib"
    #TODO: Define more variables, so they are set in /makeDefaults.in
  ];

  preConfigure = ''
    ./make_configure
  '';

  postInstall =
    let driverPkgs = [ foomatic-db ] ++ optional nonfreeDrivers foomatic-db-nonfree;
        db = symlinkJoin "foomatic-combined-database" driverPkgs;
    in ''
    for p in $out/bin/*; do
      if cat "$p" | head -n 1 | grep '#!.*/bin/perl'; then
        echo "TESTPERL"
        cat "$p" | head -n 1 | grep '#!.*/bin/perl'
        echo DONE
        wrapProgram "$p" \
          --prefix PERL5LIB : "${makePerlPath perlPkgs}:$out${perldir}" \
          --set FOOMATICDB "${db}/share/foomatic"
      fi
      echo "FIRST 3 LINEs OF $p:"
      cat "$p" | head -n3
      echo
    done

    # # mkdir -p $out/etc/cups
    # ln -s $out/bin/foomatic-ppdfile $out/etc/cups/foomatic.conf
  '';

}
