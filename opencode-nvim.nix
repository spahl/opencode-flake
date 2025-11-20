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
  version = "main-2025-11-19";

  src = fetchFromGitHub {
    owner = "NickvanDyke";
    repo = "opencode.nvim";
    rev = "c3d1bdbb064f407b8ea12800b947d6d69390d66f";
    hash = "sha256-CMX8XF7aIEjB0QgR4C4dQwmjGeEK2xZQp2TWOavwHHg=";
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
