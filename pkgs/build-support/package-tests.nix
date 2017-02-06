{ runCommand, lib }:

{

  /* Takes a derivation and an attribute set of
   * test names to tests.
   * Tests are shell fragments which test the
   * derivation and should result in failure if
   * the functionality is not as expected. */
  withTests = tests: drv: let
    drvOutputs = drv.outputs or ["out"];
  in
    assert (drv ? drvAttrs); # not a derivation!
    runCommand drv.name {
    # we inherit all attributes in order to replicate
    # the original derivation as much as possible
    outputs = drvOutputs;
    passthru = drv.drvAttrs;
    # depend on each test (by putting in builder context)
    tests = lib.mapAttrsToList
      (name: testScript:
        runCommand "${drv.name}-test-${name}" {} ''
          ${testScript}
          touch "$out"
        '')
      tests;
  }
    # the outputs of the original derivation are replicated
    # by creating a symlink
    (lib.concatMapStrings (output: ''
      ln -s ${lib.escapeShellArg drv.${output}} "${"$"}${output}"
    '') drvOutputs);

}
