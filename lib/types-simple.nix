# A simple type system to check plain nix values
# and get detailed error messages on type mismatch.
#
# Contains support for
# scalars (simple values)
# recursive types (lists of t and attrs of t)
# products (attribute sets with named fields)
# sums (tagged unions where you can match on the different cases)
# unions (untagged unions of the specified types)
# We can’t type functions (lambda expressions). Maybe in the future.
#
# What is the difference to `./types.nix`? / Why another type system?
#
# `./types.nix` is deeply entangled with the module system,
# in order to use it on plain nix values, you have to invoke the
# module system, which is pretty heavyweight and hard/verbose to do.
# Contrary to popular opinion, the `check` functions on module types
# does *not* do a recursive check for complex types/values.
# Plus, it is not possible to catch a type error, since the module
# system always instantly aborts nix evaluation on type error.
# The `checkType` function in this module returns a detailed,
# structured # error for each part of the substructure that
# does not match the given expected type.
# Concerning expressibility, an attrset with fixed fields can
# be given as easy as `product { field1 = type; … }`, whereas
# in `./types.nix` you need to use the complictated `submodule`
# mechanism. We also support tagged unions (`./types.nix` does not)
# and untagged unions of an arbitrary set of types (can be emulated
# with nested `either`s in `./types.nix`).
#
# In short: if you want to check a module option, use `./types.nix`.
# If you want to check a plain (possibly complex) nix value,
# use this module.
#
# The main function is `checkType`.
# Tests can be found in './tests/types-simple.nix`.

{ lib }:
let

  # The type functor.
  # t is the recursion “not yet inserted”.
  #
  # data Type t
  #   = Scalar
  #   | Recursive (Rec t)
  #   | Sum (Map String t)
  #   | Product (Map String t)
  #   | Union (List t)
  #  deriving (Functor)
  #
  # Fix Type is every t replaced with Type, recursively.

  # The alternatives above are tagged manually, by this variant enum:
  variants = {
    scalar = 0;
    recursive = 1;
    sum = 2;
    product = 3;
    # TODO: it feels like union (or sum or product) is not axiomatic
    union = 4;
  };

  ## -- HELPERS --

  unimplemented = abort "unimplemented";
  unreachable = abort "should not be reached";

  # Functor instance of Type
  # fmap :: (a -> b) -> (Type a) -> (Type b)
  fmap = f: t:
         if t.variant == variants.scalar    then t
    else if t.variant == variants.recursive then
      t // { nested = f t.nested; }
    else if t.variant == variants.sum       then
      t // { alts   = lib.mapAttrs (lib.const f) t.alts; }
    else if t.variant == variants.product   then
      t // { opt = lib.mapAttrs (lib.const f) t.opt;
             req = lib.mapAttrs (lib.const f) t.req; }
    else if t.variant == variants.union     then
      t // { altList = map f t.altList; }
    else unreachable;

  # cata :: (Type a -> a) -> Fix Type -> a
  # collapses the structure Fix Type (nested types) into an a,
  # by collapsing one layer at a time with the function (/algebra)
  # alg :: (Type a -> a)
  cata = alg: t: alg (fmap (cata alg) t);


  ## -- MAIN --

  # Main type checking function.
  # Example:
  # > checkType (list string) [ "foo" "bar" ]
  # { }
  # > checkType (list string) [ "foo" 42 ]
  # { "1" = { should = "string"; val = 42; }; }
  #
  # checkType :: Fix Type -> Value -> (Nested Attrs) Errors
  #
  # where { } means no error
  # or { should : String, val : Value } for a type mismatch.
  checkType =
    let
      # filters out non-error messages
      mapAndFilter = f: vals:
        lib.filterAttrs (_: v: v != {}) (lib.mapAttrs f vals);
      # alg :: Type (Value -> Errors) -> (Value -> Errors)
      alg = t: v:
            # TODO: some errors should throw some more context.
            # e.g. putting more than one field in a sum value.
            if !(t.check v) then { should = t.description; val = v; }
        else if t.variant == variants.scalar    then {}
        else if t.variant == variants.recursive then
          mapAndFilter (_: el: t.nested el) (t.each v)
        else if t.variant == variants.sum       then
              # we already tested length == 1 in .check
          let alt = builtins.head (builtins.attrNames v);
          in t.alts.${alt} v.${alt}
        else if t.variant == variants.product   then
          mapAndFilter (n: f: if v ? ${n} then f v.${n} else {})
                       (t.req // t.opt)
        else if t.variant == variants.union     then
          # unions are awkward, the type checker can’t do much here
          if lib.all (res: res != {}) (map (f: f v) t.altList)
          then { should = t.description; val = v; }
          else {}
        else unreachable;
    in t: v: cata alg t v;


  ## -- TYPE SETUP STUFF --

  mkBaseType = {
    # unique name (for matching on the type)
    name,
    # the (displayable) type description
    description,
    # a function to check the outermost type, given a value (Val -> Bool)
    # TODO: this is value-specific, maybe this should be inside the type checker
    # logic instead of the type definiton? There’s some repetition.
    check,
    # the variant of this type
    variant,
    # extra fields belonging to the variant
    extraFields
  }: { inherit name description check variant; } // extraFields;

  mkScalar = { name, description, check }: mkBaseType {
    inherit name description check;
    variant = variants.scalar;
    extraFields = {};
  };

  mkRecursive = { name, description, check,
    # return all children for a value of this type T t,
    # give each child (of type t) a displayable name.
    # (T -> Map Name t)
    each,
    # The nested value t of the type functor
    nested
  }: mkBaseType {
    inherit name description check;
    variant = variants.recursive;
    extraFields = { inherit each nested; };
  };


  ## -- TYPES --

  # the type with no inhabitants (kind of useless …)
  void = mkScalar {
    name = "void";
    description = "void";
    # there are no values of type void
    check = lib.const false;
  };

  # the any type, every value is an inhabitant
  # tt basically turns of the type system, use with care
  any = mkScalar {
    name = "any";
    description = "any type";
    check = lib.const true;
  };

  # the type with exactly one inhabitant
  unit = mkScalar {
    name = "unit";
    description = "unit";
    # there is exactly one unit value, we represent it with {};
    check = v: v == {};
  };

  # the type with two inhabitants
  bool = mkScalar {
    name = "bool";
    description = "boolean";
    check = builtins.isBool;
  };

  # a nix string
  string = mkScalar {
    name = "string";
    description = "string";
    check = builtins.isString;
  };

  # a signed nix integer
  int = mkScalar {
    name = "int";
    description = "integer";
    check = builtins.isInt;
  };

  # a nix floating point number
  float = mkScalar {
    name = "float";
    description = "float";
    check = builtins.isFloat;
  };

  # helper for descriptions of recursive types
  # TODO: descriptions need to assume t is a type,
  # which is only true for Fix Type. How to make nice?
  describe = t: t.description or "<non-type>";

  # list with children of type t
  # list bool: [ true false false ]
  # list (attrs unit):
  #   [ { a = {}; } { b = {}; } ]
  #   []
  list = t: mkRecursive {
    name = "list";
    description = "list of ${describe t}";
    check = builtins.isList;
    # each child gets named by its index
    each = l: builtins.listToAttrs
      (lib.imap0 (i: v: lib.nameValuePair (toString i) v) l);
    nested = t;
  };

  # attrset with children of type t
  # attrs int: { foo = 23; bar = 42; }
  # attrs (attrs string):
  #  { foo.bar = "hello"; baz.quux = "x"; }
  #  { x = { y = "wow"; }; }
  attrs = t: mkRecursive {
    name = "attrs";
    description = "attrset of ${describe t}";
    check = builtins.isAttrs;
    each = lib.id;
    nested = t;
  };

  # TODO: nonempty list and attrs

  # product type with fields of the specified types
  # product { x = int; y = unit; }:
  #   { x = 23; y = {}; }
  #   { x = 42; y = {}; }
  # product {}: <- yeah, that’s isomorphic to unit
  #   { }
  # product { foo = void; }:
  #   just kidding. :)
  product = fields: productOpt { req = fields; opt = {}; };

  # product type with the possibility of optional fields
  # actually the more generic type of product, BUT:
  # code with a fixed number of fields is less brittle.
  # choose wisely.
  # productOpt { req = {}; opt = { a = unit; b = int; }:
  #   { }
  #   { a = {}; }
  #   { a = {}; b = 23; }
  productOpt = { req, opt }: mkBaseType {
    name = "product";
    description = "{ " +
      lib.concatStringsSep ", "
        (  lib.mapAttrsToList (n: t: "${n}: ${describe t}") req
        ++ lib.mapAttrsToList (n: t: "[${n}: ${describe t}]") opt)
      + " }";
    check = v:
      let reqfs = builtins.attrNames req;
          optfs = builtins.attrNames opt;
          vfs   = builtins.attrNames v;
      in builtins.isAttrs v &&
      # all fields have to exist in the value
      # reqfs - vfs
      (if opt == {}
      # if there’s only required fields, this is an optimization
      then reqfs == vfs
      else lib.subtractLists vfs reqfs == []
        # whithout req, only opt fields must be in the value
        # (vfs - reqfs) - otfs
        && lib.subtractLists optfs (lib.subtractLists reqfs vfs) == []);
    variant = variants.product;
    extraFields = {
      inherit opt req;
    };
  };

  # sum type with alternatives of the specified types
  # sum { left = string; right = bool; }:
  #   { left = "work it"; }
  #   { right = false; }
  # sum { true = unit; false = unit; } <- that’s isomorphic to bool
  #   { true = {}; }
  #   { false = {}; }
  # sum { X = product { name = string; age = int; }; Y = list unit; }
  #   { X = { name = "peter shaw"; age = 22; }; }
  #   { Y = [ {} {} {} {} {} {} {} {} ]; }
  sum = alts: assert alts != {}; mkBaseType {
    name = "sum";
    description = "< " +
      lib.concatStringsSep " | "
        (lib.mapAttrsToList (n: t: "${n}: ${describe t}") alts)
      + " >";
    check = v:
      let alt = builtins.attrNames v;
      in builtins.isAttrs v
      # exactly one of the alts has to be used by the value
      && builtins.length alt == 1
      && alts ? ${lib.head alt};
    variant = variants.sum;
    extraFields = {
      inherit alts;
    };
  };

  # untagged union type
  # ATTENTION: this leads to *bad* type checker errors in practice,
  # you also can’t do pattern matching; use sum if possible.
  # union [ bool int ]
  #   3
  #   true
  # list (union [ int string ])
  #   [ "foo" 34 "bar" ]
  # please don’t use this.
  union = altList: assert altList != []; mkBaseType {
    name = "union";
    description = "one of [ "
      + lib.concatMapStringsSep ", " describe altList
      + " ]";
    check = v: lib.any (t: t.check v) altList;
    variant = variants.union;
    extraFields = {
      inherit altList;
    };
  };

  # TODO: should scalars be allowed as nest types?
  # TODO: how to implement?
  # nested = nest: t: mkBaseType {
  #   description = "nested ${describe nest} of ${describe t}";
  #   check = nest.check ;
  #   variant = nest.variant;
  #   extraFields = {


  ## -- FUNCTIONS --

  # match =

  # Default values for some types, chosen pretty arbitrarily.
  # Can be used to populate products which might have less fields
  # than originally specified:
  # let t = product { foo : string, bar = product { baz = int; }; }
  #     def = defaults t; # { foo = ""; bar.baz = 0; };
  #     val = { foo = "hello"; };
  # in checkType t (defaults t // val)
  # or even recursiveUpdate if you want to be naughty.
  defaults = t:
    let
      defs = {
        # void = haha, right
        # any = better not
        unit = {};
        bool = false;
        string = "";
        int = 0;
        float = 0.0;
        list = [];
        attrs = {};
        product = lib.mapAttrs (lib.const defaults) t.req;
        # sum and union those are *really* arbitrary
        sum =
          let first = builtins.head (builtins.attrNames t.alts);
          in { ${first} = defaults t.alts.${first}; };
        union =
          let first = builtins.head t.altList;
          in defaults first;
      };
    in if defs ? ${t.name}
       then defs.${t.name}
       else abort "types-simple: no default value for type ${describe t} defined";

  prettyPrintErrors =
    let
      join = lib.foldl lib.concat [];
      isLeaf = v: {} == checkType (product { should = string; val = any; }) v;
      recurse = path: errs:
        if isLeaf errs
        then [{ inherit path; inherit (errs) should val; }]
        else join (lib.mapAttrsToList
          (p: errs': recurse (path ++ [p]) errs') errs);
      pretty = { path, should, val }:
        "${lib.concatStringsSep "." path} should be: ${
          should}\nbut is: ${lib.generators.toPretty {} val}";
    in errs: lib.concatMapStringsSep "\n" pretty (recurse [] errs);

in {
  # The type of nix types, as non-recursive functor.
  # fmap and cata are specialized to Type.
  Type = { inherit variants fmap cata; };
  # Constructor functions for types.
  # Their internal structure/fields are an *implementation detail*.
  inherit void any unit bool string int float
          list attrs product productOpt sum union;
  # Type checking.
  inherit checkType;
  # Functions.
  inherit defaults prettyPrintErrors;
}
