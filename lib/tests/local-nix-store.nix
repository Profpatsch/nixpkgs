# Shell code to set up a local nix store
# for executing nix commands from a derivation.
# Intended for testing purposes.
{ nixpkgs, nix, writeText }:

writeText "local-nix-store.sh" ''
  datadir="${nix}/share"
  export NIX_PATH="nixpkgs=${nixpkgs}"
  export TEST_ROOT=$(pwd)/test-tmp
  export NIX_BUILD_HOOK=
  export NIX_CONF_DIR=$TEST_ROOT/etc
  export NIX_DB_DIR=$TEST_ROOT/db
  export NIX_LOCALSTATE_DIR=$TEST_ROOT/var
  export NIX_LOG_DIR=$TEST_ROOT/var/log/nix
  export NIX_MANIFESTS_DIR=$TEST_ROOT/var/nix/manifests
  export NIX_STATE_DIR=$TEST_ROOT/var/nix
  export NIX_STORE_DIR=$TEST_ROOT/store
  export PAGER=cat
  cacheDir=$TEST_ROOT/binary-cache
  ${nix}/bin/nix-store --init
''
