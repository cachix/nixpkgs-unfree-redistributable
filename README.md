Currently fails with:


    $ nix --extra-experimental-features 'nix-command flakes' eval .#legacyPackages
    error: anonymous function at /nix/store/g5bl53zqkkc6pcr6izsbrhcs1fjkxdhd-source/pkgs/build-support/fetchurl/boot.nix:5:1 called with unexpected argument 'meta'

        at /nix/store/g5bl53zqkkc6pcr6izsbrhcs1fjkxdhd-source/pkgs/build-support/fetchzip/default.nix:22:2:

            21|
            22| (fetchurl (let
                |  ^
            23|   tmpFilename =
    (use '--show-trace' to show detailed location information)