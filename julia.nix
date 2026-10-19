{ pkgs, juliaVersion }:
let
  # These are hashes of the official x86_64-linux binary archives.
  versionShas = {
    "1.13.0" = "sha256-iXXaYcEopeXe0+cZ6GjajIeB3reteRPTf7mb4CqBkEs=";
    "1.12.5" = "sha256-QbhNcn5Olvvz7Z6S+hlddz0ke5CX9z+taI+LaZdYuuc=";
    "1.12.1" = "sha256-fSrdnudO4vErXCaLwZR5TMUupED4aH+6sp22r++/abc=";
    "1.11.6" = "sha256-6Z5S4gKdhFCXxo8jctg2GG8Os/uJep3eC9+e6SUNA9U=";
    "1.11.1" = "sha256-zKjRPcRQfk9ioSkyIpMxPuV08wDU3559swt7QcX4qPM=";
    "1.11.0-rc1" = "sha256-2dfKgQhxhau7ijdcQfc03upuomrvLcQNmUZ/jFx8yNY=";
    "1.10.4" = "sha256-/pJCWOVdB0QQsTQZXPa4XL6PMH/NBaT90j+JRMWUGnA=";
    "1.10.1" = "sha256-/pJCWOVdB0QQsTQZXPa4XL6PMH/NBaT90j+JRMWUGnA=";
    "1.10.0" = "sha256-pymCB/cvKyeyqxzjkqbqN6+9H77g8fjRkLBU3KuoeP4=";
    "1.10.0-beta2" = "sha256-8aF/WlKYDBZ0Fsvk7aFEGdgY87dphUARVKOlZ4edZHc=";
    "1.10.0-beta1" = "sha256-zaOKLdWw7GBcwH/6RO/T6f4QctsmUllT0eJPtDLgv08=";
    "1.9.3" = "sha256-12ZwzJuj4P1MFUXdPQAmnAaUl2oRdjEnlevOFpLTI9E=";
    "1.9.2" = "sha256-TC15n0Qtf+cYgnsZ2iusty6gQbnOVfJO7nsTE/V8Q4M=";
    "1.9.0" = "sha256-AMYURm75gJwusjSA440ZaixXf/8nMMT4PRNbkT1HM1k=";
    "1.8.3" = "sha256-M8Owk1b/qiXTMxw2RrHy1LCZROj5P8uZSVeAG4u/WKk=";
    "1.7.2" = "sha256-p1JEck87LeDnJJyGH79kB4JXwW+0IDvnjxz03VlzupU=";
    "1.6.7" = "sha256-bEUi1ZXky80AFXrEWKcviuwBdXBT0gc/mdqjnkQrKjY=";
  };

  baseJulia = pkgs.callPackage (import
    (pkgs.path + "/pkgs/development/compilers/julia/generic-bin.nix")
    {
      version = juliaVersion;
      sha256.x86_64-linux = versionShas.${juliaVersion};
    }
  ) { };

  julia = baseJulia.overrideAttrs (old: {
    passthru = (old.passthru or { }) // {
      withPackages = pkgs.callPackage (pkgs.path + "/pkgs/development/julia-modules") { inherit julia; };
    };
  });
in
assert pkgs.lib.assertMsg (
  pkgs.stdenv.hostPlatform.system == "x86_64-linux"
) "julia.nix currently provides archive hashes only for x86_64-linux";
assert pkgs.lib.assertMsg (builtins.hasAttr juliaVersion versionShas)
  "No Julia archive hash configured for ${juliaVersion}";
julia
