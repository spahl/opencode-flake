{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
  autoPatchelfHook,
  stdenv,
  nix-update-script,
  testers,
}:

let
  version = "1.0.37";
  
  # Map Nix system to OpenCode platform naming
  platformMap = {
    "x86_64-linux" = {
      platform = "linux";
      arch = "x64";
    };
    "aarch64-linux" = {
      platform = "linux";
      arch = "arm64";
    };
    "x86_64-darwin" = {
      platform = "darwin";
      arch = "x64";
    };
    "aarch64-darwin" = {
      platform = "darwin";
      arch = "arm64";
    };
  };

  # Platform-specific hashes for the pre-built binaries
  hashes = {
    "x86_64-linux" = "sha256-1siSi3cqA4VLD8Ake7F6srWXq7unHINOeasrMEEWdG0=";
    "aarch64-linux" = "sha256-JbF+YQvrdf0AxPEiC8pIn9eCSneESzeUerqWGVxjQGg=";
    "x86_64-darwin" = "sha256-C2RFlexW/0oVxN4lMhEtAY/bldoQh9A5h0TCoRNdYvc=";
    "aarch64-darwin" = "sha256-0KgDKXdbnZkvbGla+nETtWD7jLkhW0Z918m1SHd8s48=";
  };

  system = stdenvNoCC.hostPlatform.system;
  platformInfo = platformMap.${system} or (throw "Unsupported system: ${system}");
  hash = hashes.${system} or (throw "No hash for system: ${system}");

in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "opencode";
  inherit version;

  src = fetchurl {
    url = "https://github.com/sst/opencode/releases/download/v${version}/opencode-${platformInfo.platform}-${platformInfo.arch}.zip";
    inherit hash;
  };

  nativeBuildInputs = [
    unzip
  ] ++ lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
  ];

  unpackPhase = ''
    runHook preUnpack
    
    unzip -q $src
    
    runHook postUnpack
  '';

  dontStrip = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 opencode $out/bin/opencode

    runHook postInstall
  '';

  passthru = {
    tests.version = testers.testVersion {
      package = finalAttrs.finalPackage;
      command = "HOME=$(mktemp -d) opencode --version";
      inherit (finalAttrs) version;
    };
    updateScript = nix-update-script { };
  };

  meta = {
    description = "AI coding agent built for the terminal";
    longDescription = ''
      OpenCode is a terminal-based agent that can build anything.
      It combines TypeScript/JavaScript with native UI components
      to provide an interactive AI coding experience.
    '';
    homepage = "https://github.com/sst/opencode";
    license = lib.licenses.mit;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    maintainers = [
      {
        email = "sebastien.pahl@gmail.com";
        github = "spahl";
        name = "Sebastien Pahl";
      }
    ];
    mainProgram = "opencode";
  };
})
