{
  lib,
  fetchFromGitHub,
  fetchFromGitLab,
  fetchFromSourcehut,
  nix-update-script,
  callPackage,
}:

let
  /**
    List of grammar sources. See ./grammar-sources.nix to define a new grammar.

    Elements must be of the form
      { language, version, src, ... }
    or
      { language, version, url, hash, ... }
    with url being a flakeref style such as `github:tree-siter/tree-sitter-foo`
    that will be used to derive a source expression.
  */
  grammar-sources = callPackage ./grammar-sources.nix { };

  /**
    Attribute to be inserted as the default grammar updater.
  */
  updateScript = nix-update-script {
    extraArgs = [
      "--override-filename pkgs/development/tools/parsing/tree-sitter/grammar-sources.nix"
    ];
  };

  /**
    Parse a flakeref style string to { type, owner, repo }

    FIXME: switch to builtins.parseFlakeRef when stable
  */
  parseUrl =
    url:
    let
      parts = lib.match "(.+):(.+)\/(.+)" url;
    in
    {
      type = lib.elemAt parts 0;
      owner = lib.elemAt parts 1;
      repo = lib.elemAt parts 2;
    };

in

lib.pipe grammar-sources [
  (map (
    { language, version, ... }@attrs:
    {
      name = "tree-sitter-${language}";
      value =

        # Insert auto-update support
        {
          passthru = { inherit updateScript; };
        }

        # Expand flakeref style shorthand into a source expression
        // lib.optionalAttrs (attrs ? url && attrs ? hash) {
          src =
            let
              source = parseUrl attrs.url;
              fetch = lib.getAttr source.type {
                github = fetchFromGitHub;
                gitlab = fetchFromGitLab;
                sourcehut = fetchFromSourcehut;
                # NOTE: include other hosts here as required
              };
            in
            fetch {
              inherit (source)
                owner
                repo
                ;
              rev = "v${version}";
              inherit (attrs) hash;
            };
        }
        // removeAttrs attrs [
          "url"
          "hash"
        ];
    }
  ))

  lib.listToAttrs
]
