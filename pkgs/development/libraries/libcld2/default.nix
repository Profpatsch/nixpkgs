{ lib, stdenv, fetchFromGitHub, pkg-config }:

stdenv.mkDerivation rec {
  pname = "libcld2";
  version = "2.0.2";

  src = fetchFromGitHub {
    # We use a fork, because it has a Makefile
    # These are all clones of the original GOOG code from 2013, mostly unchanged
    owner = "datasift";
    repo = "libcld2";
    rev = "2.0.2";
    hash = "sha256-LEbSa1Wz1dShoAkhzWi5cJcg/4uvRSVwiVZoZEivxTA=";
  };

  outputs = [ "out" "dev" ];

  makeFlags = [ "PREFIX=$(out)" ];
  env.NIX_CFLAGS_COMPILE = "-Wno-error=narrowing";

  nativeBuildInputs = [ ];

  buildInputs = [ ];

  meta = with lib; {
    description = "CLD2 probabilistically detects over 80 languages in Unicode UTF-8 text, either plain text or HTML/XML.";
    homepage    = "https://github.com/datasift/libcld2/";
    license     = licenses.asl20;
    platforms   = platforms.all;
    maintainers = with maintainers; [ ];
  };
}
