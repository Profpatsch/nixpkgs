{ lib, pkgs, ... }:

{
  options.tests = lib.mkOption {
    type = with lib.types; nestedOf attrsOf package;
    default = {};
    example = {
      services.awesomeService.test1 = "VM test for awesomeService";
      some.other.module = {
        testsuite = "…";
        miscTests.test1 = "testdrv";
        miscTests.test2 = "otherdrv";
      };
    };
    description = ''
      A nested attribute set of module tests.
      Modules should mirror their option namespace.
      Continuous integration (e.g. hydra) can define
      which tests to run by using the normal way of activating
      <literal>enable</literal>-Options and evaluating the
      <literal>config.tests</literal> attribute set generated
      by evaluation of the module system.
    '';
  };
}
