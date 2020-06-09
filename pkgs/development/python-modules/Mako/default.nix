{ lib
, buildPythonPackage
, fetchPypi
, python
, markupsafe
, nose
, mock
, isPyPy
}:

buildPythonPackage rec {
  pname = "Mako";
  version = "1.1.2";

  src = fetchPypi {
    inherit pname version;
    sha256 = "3139c5d64aa5d175dbafb95027057128b5fbd05a40c53999f3905ceb53366d9d";
  };

  checkInputs = [ markupsafe nose mock ];
  propagatedBuildInputs = [ markupsafe ];

  doCheck = !isPyPy;  # https://bitbucket.org/zzzeek/mako/issue/238/2-tests-failed-on-pypy-24-25
  checkPhase = ''
    ${python.interpreter} -m unittest discover
  '';

  meta = {
    description = "Super-fast templating language";
    homepage = "http://www.makotemplates.org";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ domenkozar ];
  };
}
