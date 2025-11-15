{
  lib,
  vimUtils,
  fetchFromGitHub,
  curl,
  gnugrep,
  lsof,
  opencode,
  procps,
  util-linux,
}:

vimUtils.buildVimPlugin {
  pname = "opencode.nvim";
  version = "main-2025-11-10";

  src = fetchFromGitHub {
    owner = "NickvanDyke";
    repo = "opencode.nvim";
    rev = "217d363bf1263d18ecd00cbb618b74e8553432e2";
    hash = "sha256-axnHVD76ABliyEHD2VD+HOJFn5UA0YrSmk/saerZg8U=";
  };

  postPatch = ''
    substituteInPlace lua/opencode/config.lua \
      --replace 'cmd = "opencode"' 'cmd = "${lib.getExe opencode}"'
  '';

  runtimeDeps = [
    curl
    gnugrep
    lsof
    opencode
    procps
    util-linux
  ];

  meta = {
    description = "Neovim integration for OpenCode AI assistant";
    longDescription = ''
      Integrate the OpenCode AI assistant with Neovim — streamline editor-aware
      research, reviews, and requests. Features auto-connect to OpenCode instances,
      prompt input with completions, editor context injection, and real-time buffer
      auto-reload.
    '';
    homepage = "https://github.com/NickvanDyke/opencode.nvim";
    license = lib.licenses.mit;
    maintainers = [
      {
        email = "sebastien.pahl@gmail.com";
        github = "spahl";
        name = "Sebastien Pahl";
      }
    ];
  };
}
