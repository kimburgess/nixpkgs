{
  lib,
  stdenv,
  fetchFromGitHub,
  nix-update-script,
  runCommand,
  which,
  rustPlatform,
  emscripten,
  openssl,
  pkg-config,
  callPackage,
  linkFarm,
  substitute,
  installShellFiles,
  buildPackages,
  enableShared ? !stdenv.hostPlatform.isStatic,
  enableStatic ? stdenv.hostPlatform.isStatic,
  webUISupport ? false,
  extraGrammars ? { },

  # tests
  lunarvim,
}:

let
  /**
    Build a parser grammar and put the resulting shared object in `$out/parser`.

    # Example

    ```nix
    tree-sitter-foo = buildGrammar {
      language = "foo";
      version = "0.42.0";
      src = fetchFromGitHub { ... };
    };
    ```
  */
  buildGrammar = callPackage ./build-grammar.nix { };

  /**
    Attrset of grammar sources.
  */
  grammars =
    let
      grammars' = callPackage ./grammars.nix { };
      updateScript = nix-update-script {
        extraArgs = [
          "--override-filename pkgs/development/tools/parsing/tree-sitter/grammars.nix"
        ];
      };
      # FIXME: switch to builtins.parseFlakeRef when stable
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
    lib.pipe grammars' [
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
    ];

  /**
    Attrset of compiled grammars.
  */
  builtGrammars = lib.mapAttrs (_: buildGrammar) (grammars // extraGrammars);

  # Usage:
  # pkgs.tree-sitter.withPlugins (p: [ p.tree-sitter-c p.tree-sitter-java ... ])
  #
  # or for all grammars:
  # pkgs.tree-sitter.withPlugins (_: allGrammars)
  # which is equivalent to
  # pkgs.tree-sitter.withPlugins (p: builtins.attrValues p)
  withPlugins =
    grammarFn:
    let
      grammars = grammarFn builtGrammars;
    in
    linkFarm "grammars" (
      map (
        drv:
        let
          name = lib.strings.getName drv;
        in
        {
          name =
            (lib.strings.replaceStrings [ "-" ] [ "_" ] (
              lib.strings.removePrefix "tree-sitter-" (lib.strings.removeSuffix "-grammar" name)
            ))
            + ".so";
          path = "${drv}/parser";
        }
      ) grammars
    );

  allGrammars = builtins.attrValues builtGrammars;

in
rustPlatform.buildRustPackage (final: {
  pname = "tree-sitter";
  version = "0.25.3";

  src = fetchFromGitHub {
    owner = "tree-sitter";
    repo = "tree-sitter";
    tag = "v${final.version}";
    hash = "sha256-xafeni6Z6QgPiKzvhCT2SyfPn0agLHo47y+6ExQXkzE=";
    fetchSubmodules = true;
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-rjUn8F6WSxLQGrFzK23q4ClLePSpcMN2+i7rC02Fisk=";

  buildInputs =
    [ installShellFiles ]
    ++ lib.optionals webUISupport [
      openssl
    ];
  nativeBuildInputs =
    [ which ]
    ++ lib.optionals webUISupport [
      emscripten
      pkg-config
    ];

  patches = lib.optionals (!webUISupport) [
    (substitute {
      src = ./remove-web-interface.patch;
    })
  ];

  postPatch = lib.optionalString webUISupport ''
    substituteInPlace cli/loader/src/lib.rs \
        --replace-fail 'let emcc_name = if cfg!(windows) { "emcc.bat" } else { "emcc" };' 'let emcc_name = "${lib.getExe' emscripten "emcc"}";'
  '';

  # Compile web assembly with emscripten. The --debug flag prevents us from
  # minifying the JavaScript; passing it allows us to side-step more Node
  # JS dependencies for installation.
  preBuild = lib.optionalString webUISupport ''
    mkdir -p .emscriptencache
    export EM_CACHE=$(pwd)/.emscriptencache
    cargo run --package xtask -- build-wasm --debug
  '';

  postInstall =
    ''
      PREFIX=$out make install
      ${lib.optionalString (!enableShared) "rm $out/lib/*.so{,.*}"}
      ${lib.optionalString (!enableStatic) "rm $out/lib/*.a"}
    ''
    + lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
      installShellCompletion --cmd tree-sitter \
        --bash <("$out/bin/tree-sitter" complete --shell bash) \
        --zsh <("$out/bin/tree-sitter" complete --shell zsh) \
        --fish <("$out/bin/tree-sitter" complete --shell fish)
    ''
    + lib.optionalString (!stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
      installShellCompletion --cmd tree-sitter \
        --bash "${buildPackages.tree-sitter}"/share/bash-completion/completions/*.bash \
        --zsh "${buildPackages.tree-sitter}"/share/zsh/site-functions/* \
        --fish "${buildPackages.tree-sitter}"/share/fish/*/*
    '';

  # test result: FAILED. 120 passed; 13 failed; 0 ignored; 0 measured; 0 filtered out
  doCheck = false;

  passthru = {
    inherit
      grammars
      buildGrammar
      builtGrammars
      withPlugins
      allGrammars
      ;

    updateScript = nix-update-script { };

    tests = {
      # make sure all grammars build
      builtGrammars = lib.recurseIntoAttrs builtGrammars;

      inherit lunarvim;
    };
  };

  meta = {
    homepage = "https://github.com/tree-sitter/tree-sitter";
    description = "Parser generator tool and an incremental parsing library";
    mainProgram = "tree-sitter";
    changelog = "https://github.com/tree-sitter/tree-sitter/blob/v${final.version}/CHANGELOG.md";
    longDescription = ''
      Tree-sitter is a parser generator tool and an incremental parsing library.
      It can build a concrete syntax tree for a source file and efficiently update the syntax tree as the source file is edited.

      Tree-sitter aims to be:

      * General enough to parse any programming language
      * Fast enough to parse on every keystroke in a text editor
      * Robust enough to provide useful results even in the presence of syntax errors
      * Dependency-free so that the runtime library (which is written in pure C) can be embedded in any application
    '';
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      Profpatsch
      uncenter
    ];
  };
})
