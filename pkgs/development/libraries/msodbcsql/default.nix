{ stdenv, fetchurl, dpkg
, utillinux, glibc, curl, unixODBC, libkrb5, openssl }:

with stdenv.lib;

stdenv.mkDerivation rec {
  name = "msodbcsql-${version}";
  version = "13.0.1.0";

  src = fetchurl {
    # this link might change on new ubuntu releases, sorry. :(
    url = "https://apt-mo.trafficmanager.net/repos/mssql-ubuntu-xenial-release/pool/main/m/msodbcsql/msodbcsql_${version}-1_amd64.deb";
    sha256 = "0pvp8ckwz0wzdf2c90ii4ccmgw0imf5nh16b6vi5brcnq3nf3y3h";
  };

  dontBuild = true;

  unpackCmd = "${getBin dpkg}/bin/dpkg-deb --extract $curSrc ./pkg";

  patchPhase = ''
    sed -e '/Driver=/ s|.*|Driver=lib/libmsodbcsql.so/|' \
        -i opt/microsoft/msodbcsql/etc/odbcinst.ini
  '';

  installPhase = ''
    mkdir -p $out/lib
    mv opt/microsoft/msodbcsql/{etc,share,include} $out
    # only first two parts of version, like 13.0
    VER=$(echo ${version} | cut -d'.' -f1,2)
    mv "opt/microsoft/msodbcsql/lib64/libmsodbcsql-$VER.so.1.0" \
          $out/lib/libmsodbcsql.so
    mv usr/share/doc $out/share/doc
  '';

  postFixup = ''
    patchelf --set-rpath "${makeLibraryPath
      [ stdenv.cc.cc.lib utillinux glibc curl unixODBC libkrb5 openssl ]}" \
      $out/lib/libmsodbcsql.so
  '';

}
