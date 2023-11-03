{ stdenv, lib, fetchFromGitHub
, qmake, wrapQtAppsHook, qtbase, pkg-config, taglib, libbass, libbass_fx, libcld2 }:

# TODO: get rid of (unfree) libbass
# issue:https://github.com/UltraStar-Deluxe/UltraStar-Creator/issues/3
# there’s a WIP branch here:
# https://github.com/UltraStar-Deluxe/UltraStar-Creator/commits/BASS_removed

stdenv.mkDerivation {
  pname = "ultrastar-creator";
  version = "1.3.1-unreleased";

  src = fetchFromGitHub {
    owner = "UltraStar-Deluxe";
    repo = "UltraStar-Creator";
    rev = "36e0d88565dcd28ee1ef23194d0b9db0b8326bb8";
    sha256 = "sha256-OqpivLbn49r+gVZsaTXW8YYI7aBerQxcruj7WW6TQeU=";
  };

  postPatch = with lib; ''
    # we don’t want prebuild binaries checked into version control!
    rm -rf lib
    # we provide these ourselves
    rm -rf include/bass
    rm -rf include/bass_fx
    rm -rf include/cld2
    sed -e "s|DESTDIR =.*$|DESTDIR = $out/bin|" \
        -e 's|-L".*unix"||' \
        -e "/QMAKE_POST_LINK/d" \
        -e "s|../include/bass|${getLib libbass}/include|g" \
        -e "s|../include/bass_fx|${getLib libbass_fx}/include|g" \
        -e "s|../include/taglib|${getLib taglib}/include|g" \
        -e "s|../include/cld2/public|${getDev libcld2}/include/cld2/public|g" \
        -i src/UltraStar-Creator.pro
  '';

  preConfigure = ''
    cd src
  '';

  nativeBuildInputs = [ qmake pkg-config wrapQtAppsHook ];
  buildInputs = [ qtbase taglib libbass libbass_fx libcld2 ];

  meta = with lib; {
    description = "Ultrastar karaoke song creation tool";
    homepage = "https://github.com/UltraStar-Deluxe/UltraStar-Creator";
    license = licenses.gpl2;
    maintainers = with maintainers; [ Profpatsch ];
  };
}
