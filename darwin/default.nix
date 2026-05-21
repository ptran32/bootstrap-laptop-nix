{ pkgs, lib, username, ... }:

{
  system.stateVersion = 5;

  # Terraform is BSL-licensed (unfree in nixpkgs). tfenv may pull multiple versions.
  nixpkgs.config.allowUnfreePredicate = pkg:
    lib.hasPrefix "terraform" (lib.getName pkg);

  networking.hostName = "patricetran-mac";

  users.users.${username} = {
    shell = pkgs.zsh;
    home = "/Users/${username}";
  };

  environment.systemPackages = [ ];

  # Applied after the first darwin-rebuild. Before that, enable in /etc/nix/nix.conf
  # (sudo does not read ~/.config/nix/nix.conf — see README step 2).
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
