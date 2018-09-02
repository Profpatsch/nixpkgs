{ stdenv, fetchgit, skalibs }:

let

  version = "2.5.0.1";

in stdenv.mkDerivation rec {

  name = "execline-${version}";

  src = fetchgit {
    url = "git://git.skarnet.org/execline";
    rev = "refs/tags/v${version}";
    sha256 = "0d4gvixz7xja03hnwc2bf13xrgh1jq27ij4m1jlrpgrzhfpqz37q";
  };

  outputs = [ "bin" "lib" "dev" "doc" "out" ];

  dontDisableStatic = true;

  enableParallelBuilding = true;

  # TODO: nsss support
  configureFlags = [
    "--enable-absolute-paths"
    "--libdir=\${lib}/lib"
    "--dynlibdir=\${lib}/lib"
    "--bindir=\${bin}/bin"
    "--includedir=\${dev}/include"
    "--with-sysdeps=${skalibs.lib}/lib/skalibs/sysdeps"
    "--with-include=${skalibs.dev}/include"
    "--with-lib=${skalibs.lib}/lib"
    "--with-dynlib=${skalibs.lib}/lib"
  ]
  ++ (if stdenv.isDarwin then [ "--disable-shared" ] else [ "--enable-shared" ])
  ++ (stdenv.lib.optional stdenv.isDarwin "--build=${stdenv.hostPlatform.system}");

  postInstall = ''
    mkdir -p $doc/share/doc/execline
    mv doc $doc/share/doc/execline/html
    mv examples $doc/share/doc/execline/examples
  '';

  meta = {
    homepage = http://skarnet.org/software/execline/;
    description = "A small scripting language, to be used in place of a shell in non-interactive scripts";
    platforms = stdenv.lib.platforms.all;
    license = stdenv.lib.licenses.isc;
    maintainers = with stdenv.lib.maintainers; [ pmahoney Profpatsch ];
  };

}
