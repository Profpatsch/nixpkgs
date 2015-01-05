{ stdenv, newScope, callAutonixPackage, mkDerivation, isDepAttr }:

with stdenv.lib;

let

  oneList = x: if builtins.isList x then x else [x];

  # Resolve inputs, turning a list of dependency names into a list of
  # derivations. 'collection' is the set of packages in the current collection,
  # 'extra' is the set of extra inputs, and 'names' is a set of name->dependency
  # mappings. Names are resolved first from 'names', then from 'extra' and
  # finally from 'collection'.
  resolveInputs = collection: extra: names: inputs:
    let resolveInOrder = input: oneList
          (names."${input}" or extra."${input}" or collection."${input}" or []);
    in concatMap resolveInOrder inputs;
in
dir:

{ names
  # 'names' maps dependency strings to derivations. It is a set of the form:
  # {
  #   <dependency name> = <derivation>
  # }
  # '<derivation>' may also be a list of derivations.
, packages
  # {
  #   <package name> = {
  #     name = <package name and version>;
  #     src = <src via fetchurl or similar>;
  #
  #     buildInputs = [ <list of strings> ];
  #     nativeBuildInputs = [ <list of strings> ];
  #     propagatedBuildInputs = [ <list of strings> ];
  #     propagatedNativeBuildInputs = [ <list of strings> ];
  #     propagatedUserEnvPkgs = [ <list of strings> ];
  #   };
  #   ...
  # }
, extraInputs ? {}
  # 'extraInputs' are attributes in the default scope (through callPackage) to
  # the expressions in the collection. They are not included in the final
  # set.
, extraOutputs ? {}
  # 'extraOutputs' are extra attributes to include in the final set of the
  # collection. They are also used as extraInputs, so there is no need to
  # list packages twice.
, deriver ? mkDerivation
  # 'deriver' is a function of two arguments. The first argument is an
  # attribute set of the form passed to stdenv.mkDerivation; these are the
  # default derivation attributes. The second argument is a list of attribute
  # sets which should be merged to produce additional arguments for the
  # derivation. The first arguments should override the merge arguments.
, overrides ? {}
  # 'overrides' is a set of extra attributes passed to the deriver for each
  # package, i.e., it is a set of the form:
  # {
  #    <package name> = { <extra attributes> };
  # }
  # The extra attributes can be any extra attributes for the deriver, such
  # as buildInputs, cmakeFlags, etc. They will be merged with attributes from
  # other sources.
}:
let dev = { inherit names; };
in
let
  extraIn = extraOutputs // extraInputs // {
    inherit callPackage;
    mkDerivation = deriver;
    dev = dev // { inherit callPackage; };
  };
  extraOut = extraOutputs // {
    dev = dev // {
      inherit callPackage;
      mkDerivation = deriver;
      callAutonixPackage = callAutonixPackage callAutonixAttrs;
    };
  };

  resolveAllInputs =
    let scope = collection // extraIn // names;
        resolveInputs = concatMap (dep: oneList (scope."${dep}" or []));
    in mapAttrs (n: if isDepAttr n then resolveInputs else id);

  packagesWithInputs = mapAttrs (pkg: resolveAllInputs) packages;

  callPackage = newScope (collection // extraIn);

  callAutonixAttrs = {
    inherit callPackage deriver overrides;
    packages = packagesWithInputs;
  };

  collection =
    let callPkg = n: p: callAutonixPackage callAutonixAttrs dir n {};
    in mapAttrs callPkg packagesWithInputs;
in
  collection // extraOut
