{ stdenv, lib, fetchFromGitHub
, autoreconfHook, pkgconfig, wrapGAppsHook
, gnome3, glib, intltool, gtk3, gnome-doc-utils
, at-spi2-core, dbus
, libxslt, libxml2
, speechSupport ? true, speechd ? null
}:

assert speechSupport -> speechd != null;

stdenv.mkDerivation {
  pname = "dasher";
  version = "2018-04-03";

  src = fetchFromGitHub {
    owner = "dasher-project";
    repo = "dasher";
    rev = "9ab12462e51d17a38c0ddc7f7ffe1cb5fe83b627";
    sha256 = "1r9xn966nx3pv2bidd6i3pxmprvlw6insnsb38zabmac609h9d9s";
  };

  prePatch = ''
    # tries to invoke git for something, probably fetching the ref
    echo "true" > build-aux/mkversion
  '';

  configureFlags = lib.optional (!speechSupport) "--disable-speech";

  nativeBuildInputs = [
    autoreconfHook
    wrapGAppsHook
    pkgconfig
    gnome3.gnome-common
    glib
    gnome-doc-utils
    intltool
    gtk3
    # at-spi2 needs dbus to be recognized by pkg-config
    at-spi2-core dbus
    # doc generation
    libxslt libxml2
  ]
  ++ lib.optional speechSupport speechd;

  meta = {
    homepage = http://www.inference.org.uk/dasher/;
    description = "Information-efficient text-entry interface, driven by natural continuous pointing gestures";
    license = lib.licenses.gpl2;
    maintainers = [ lib.maintainers.Profpatsch ];
    platforms = lib.platforms.all;
  };

}
