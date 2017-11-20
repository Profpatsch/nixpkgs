{ lib, pkgs, config, ... }:

{
  _module.args = {
    utils = import ../../lib/utils.nix pkgs;
    testing = import ../../lib/testing.nix { inherit (pkgs) system; };
  };
}
