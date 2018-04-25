{ lib }:
with lib.types-simple;

let
  # TODO: use the types from lib/systems/parse.nix
  # any should be lib.systems.parsed.types.system
  systemT = any;
  platformT = union [ string any ];

  derivationPredicate = t: restrict {
    description = "<δ>";#: ${t.description}";
    type = t;
    check = v: lib.isDerivation v
      # TODO it would be nice to have a custom
      # type error when this check fails.
      # `impureEnvVars` only makes sense in a
      # fixed-output derivation.
      # since we don’t check that all three
      # `outputHash*` attributes need exist, we use
      # one of them arbitrarily to check whether
      # this is a fixed-output derivation.
      && (v ? impureEnvVars -> v ? outputHashAlgo);
  };

  metaT = productOpt {
    req = {};
    opt = {
      # These keys are documented
      description = string;
      homepage = union [ (list string) string ];
      longDescription = string;
      branch = string;
      downloadPage = string;
      license =
        let
          licenseT = productOpt {
            req = {
              shortName = string;
              fullName = string;
              free = bool;
            };
            opt = {
              spdxId = string;
              url = string;
            };
          };
        in union [ licenseT (list licenseT) string ];
      maintainers = list (productOpt {
        req = {
          name = string;
          email = string;
        };
        opt = {
          github = string;
        };
      });
      priority = int;
      platforms = list platformT;
      hydraPlatforms = list platformT;
      broken = bool;
      tests =
        let
          testT = derivationPredicate (productOpt {
            open = true;
            opt = {};
            req = {
              name = string;
              passthru = product {
                isVmTest = bool;
              };
              # TODO: meta should reuse metaT and add some
              # fields to the req attribute
              meta = productOpt {
                open = true;
                req.description = string;
                opt.platforms = list platformT;
              };
            };
          });
        in attrs testT;

      # Weirder stuff that doesn't appear in the documentation?
      knownVulnerabilities = list string;
      name = string;
      version = string;
      tag = string;
      updateWalker = bool;
      executables = list string;
      outputsToInstall = list string;
      position = string;
      available = bool;
      repositories = attrs string;
      isBuildPythonPackage = list platformT;
      schedulingPriority = int;
      downloadURLRegexp = string;
      isFcitxEngine = bool;
      isIbusEngine = bool;
      isGutenprint = bool;
    };
  };

  storePathT = restrict {
    description = "storepath";
    type = string;
    check = lib.hasPrefix (toString builtins.storeDir);
  };

  # fields and types taken from the manual
  derivationTArgs = {
    open = true;
    req = {
      name = string;
    system = string;
      builder = union [ storePathT path ];
    };
    opt = {
      args = let u = union [ string path ];
             in union [ u (list u) ];
      outputs = list string;
      meta = metaT;
      allowedReferences = list storePathT;
      allowedRequisites = list storePathT;
      # this type is crazy and we can’t check it correctly (see manual)
      exportReferencesGraph = list (union [ string storePathT ]);
      # see also `derivationPedicate.check`
      impureEnvVars = list string;
      passAsFile = list string;
      preferLocalBuild = bool;
    };
  };

  derivationT = derivationPredicate (productOpt derivationTArgs);

  derivationOnlyMetaT = derivationPredicate (productOpt {
    open = true;
    req = {};
    opt.meta = metaT;
  });

  mkDerivationT = derivationPredicate (productOpt {
    req = derivationTArgs.req;
    opt = derivationTArgs.opt // {
      buildInputs = list mkDerivationT;
      nativeBuildInputs = list (union [ mkDerivationT path ]);
      propagatedBuildInput = list mkDerivationT;
      propagatedNativeBuildInputs = list mkDerivationT;
    };
    inherit (derivationTArgs) open;
  });

in { inherit derivationT derivationOnlyMetaT mkDerivationT; }
