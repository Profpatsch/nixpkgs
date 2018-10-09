{ stdenv, lib, fetchurl, writeText }:

let
  version = "0.75";
  sha256 = "1iajg55n47hqxcpdzmyq4g4aprx7bzxcp885i850h355k5vmf68r";
  # To update the docs, bump the version and run
  # $ bash $(nix-build -A cdb.update-docs '<nixpkgs>')
  # (we have to check in the docs, because djb doesn’t provide
  # them in the source distribution, only on his webserver)

in stdenv.mkDerivation {
  name = "cdb-${version}";

  src = fetchurl {
    url = "https://cr.yp.to/cdb/cdb-${version}.tar.gz";
    inherit sha256;
  };

  outputs = [ "bin" "doc" "out" ];

  postPatch = ''
    # A little patch, borrowed from Archlinux AUR, borrowed from Gentoo Portage
    sed -e 's/^extern int errno;$/#include <errno.h>/' -i error.h
  '';

  postInstall = ''
    # don't use make setup, but move the binaries ourselves
    mkdir -p $bin/bin
    install -m 755 -t $bin/bin/ cdbdump cdbget cdbmake cdbmake-12 cdbmake-sv cdbstats cdbtest
    mkdir -p $doc/share/cdb/html
    tar xvf ${./docs.tar.gz} -C $doc/share/cdb/html
  '';

  passthru.update-docs = writeText "cdb-update-docs" ''
    set -euo pipefail

    tmp=$(mktemp -d)

    wget \
        --recursive \
        --level=3 \
        --convert-links \
        --page-requisites \
        --include-directories "*cdb*" \
        --no-parent \
        --directory-prefix "$tmp" \
        https://cr.yp.to/cdb.html

    pushd "$tmp"/cr.yp.to
    # the source tar is always included, so remove
    rm cdb/cdb-${version}.tar.gz

    tar czvf "$tmp"/docs.tar.gz *
    mv "$tmp"/docs.tar.gz '${toString ./docs.tar.gz}'
  '';

  meta = {
    homepage = "https://cr.yp.to/cdb";
    license = lib.licenses.publicDomain;
    maintainer = [ lib.maintainers.Profpatsch ];
  };
}
