{
  lib,
  stdenv,
  stdenvNoCC,
  bun,
  fetchFromGitHub,
  makeBinaryWrapper,
  nix-update-script,
  testers,
  writableTmpDirAsHomeHook,
}:

let
  bun-target = {
    "aarch64-darwin" = "bun-darwin-arm64";
    "aarch64-linux" = "bun-linux-arm64";
    "x86_64-darwin" = "bun-darwin-x64";
    "x86_64-linux" = "bun-linux-x64";
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "openspec";
  version = "0.14.0";
  
  src = fetchFromGitHub {
    owner = "Fission-AI";
    repo = "OpenSpec";
    tag = "v${finalAttrs.version}";
    hash = "sha256-jURQ/vr1CTzyS9I9/ksyH9JL6BRi/gSmJvYhOpR6jNg=";
  };

  node_modules = stdenvNoCC.mkDerivation {
    pname = "openspec-node_modules";
    inherit (finalAttrs) version src;

    impureEnvVars = lib.fetchers.proxyImpureEnvVars ++ [
      "GIT_PROXY_COMMAND"
      "SOCKS_SERVER"
    ];

    nativeBuildInputs = [
      bun
      writableTmpDirAsHomeHook
    ];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild

      export BUN_INSTALL_CACHE_DIR=$(mktemp -d)

      # Install dependencies
      bun install \
        --force \
        --ignore-scripts \
        --no-progress

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/node_modules
      cp -R ./node_modules $out

      runHook postInstall
    '';

    # Required else we get errors that our fixed-output derivation references store paths
    dontFixup = true;

    outputHash =
      {
        x86_64-linux = "sha256-W0CZkQPNtc9u9cbKoES9i9VEbWhwZqwqDmuLXRn5R14=";
      }
      .${stdenvNoCC.hostPlatform.system};
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };

  nativeBuildInputs = [
    bun
    makeBinaryWrapper
  ];

  configurePhase = ''
    runHook preConfigure

    cp -R ${finalAttrs.node_modules}/node_modules .

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    # Inject version into the CLI before TypeScript compilation
    # This replaces the dynamic package.json import with a static version
    sed -i "s/const { version } = require('..\/..\/package.json');/const version = '${finalAttrs.version}';/" src/cli/index.ts

    # Build TypeScript to JavaScript
    bun --bun node_modules/typescript/bin/tsc

    # Remove openspec directory to avoid conflict
    rm -rf openspec

    # Compile the CLI entry point to standalone binary
    bun build \
      --compile \
      --compile-exec-argv="--" \
      --target=${bun-target.${stdenvNoCC.hostPlatform.system}} \
      --outfile=openspec-bin \
      ./dist/cli/index.js

    runHook postBuild
  '';

  dontStrip = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 openspec-bin $out/bin/openspec

    runHook postInstall
  '';

  # Add libstdc++.so.6 manually to LD_LIBRARY_PATH for linux
  postFixup = lib.optionalString stdenv.isLinux ''
    wrapProgram $out/bin/openspec \
      --set LD_LIBRARY_PATH "${lib.makeLibraryPath [ stdenv.cc.cc.lib ]}"
  '';

  passthru = {
    tests.version = testers.testVersion {
      package = finalAttrs.finalPackage;
      command = "HOME=$(mktemp -d) openspec --version";
      inherit (finalAttrs) version;
    };
    updateScript = nix-update-script {
      extraArgs = [
        "--subpackage"
        "node_modules"
      ];
    };
  };

  meta = {
    description = "Spec-driven development for AI coding assistants";
    longDescription = ''
      OpenSpec is an AI-native system for spec-driven development.
      It provides a structured workflow for capturing requirements,
      creating change proposals, and validating implementations
      before writing code. Integrates with OpenCode, Cursor, Claude Code,
      and other AI coding assistants.
    '';
    homepage = "https://github.com/Fission-AI/OpenSpec";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    maintainers = [
      {
        email = "sebastien.pahl@gmail.com";
        github = "spahl";
        name = "Sebastien Pahl";
      }
    ];
    mainProgram = "openspec";
  };
})
