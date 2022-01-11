{ pkgs, ... }:

{
  environment.systemPackages = [ 
    pkgs.vim
    pkgs.git
  ];

  nix.extraOptions = ''
    experimental-features = flakes nix-command
  '';

  # required on M1
  programs.zsh.enable = true;

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;
}