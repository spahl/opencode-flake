{
  lib,
  vimUtils,
  fetchFromGitHub,
}:

vimUtils.buildVimPlugin {
  pname = "opencode-nvim";
  version = "main-2025-11-09";
  
  src = fetchFromGitHub {
    owner = "NickvanDyke";
    repo = "opencode.nvim";
    rev = "d815c315f8c824aad3597f71421c798ad206f7ea";
    hash = "sha256-e9aL79GfIzaiBS8GhTP68T7OrA2tpo+07Vjas4ebDHo=";
  };

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
