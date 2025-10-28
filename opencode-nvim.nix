{
  lib,
  vimUtils,
  fetchFromGitHub,
}:

vimUtils.buildVimPlugin {
  pname = "opencode-nvim";
  version = "main-2025-10-28";
  
  src = fetchFromGitHub {
    owner = "NickvanDyke";
    repo = "opencode.nvim";
    rev = "3d534e2fdc734f510d5e667f0360501ab4470255";
    hash = "sha256-4y0z1BDPzTrIuXQRh1DELjcFCPghlu0VW13YUz1H6uE=";
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
