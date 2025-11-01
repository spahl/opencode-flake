{
  lib,
  vimUtils,
  fetchFromGitHub,
}:

vimUtils.buildVimPlugin {
  pname = "opencode-nvim";
  version = "main-2025-11-01";
  
  src = fetchFromGitHub {
    owner = "NickvanDyke";
    repo = "opencode.nvim";
    rev = "d0593a0ca06a089471051fc0517106538065ee0d";
    hash = "sha256-xmvcnGnHPMmycKy7/2TYdLBv6t1N/lZ6LilPPPcrzIk=";
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
