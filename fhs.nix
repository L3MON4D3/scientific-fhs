{
  lib,
  pkgs,
  enableJulia ? true,
  juliaVersion ? "1.10.1",
  enableConda ? false,
  enablePython ? false,
  enableQuarto ? true,
  condaInstallationPath ? "~/.conda",
  condaJlEnv ? "conda_jl",
  pythonVersion ? "3.8",
  enableGraphical ? false,
  enableNVIDIA ? false,
  enableNode ? false,
  commandName ? "scientific-fhs",
  runScript ? "bash",
  texliveScheme ? pkgs.texlive.combined.scheme-minimal,
  extraOutputsToInstall ? [
    "man"
    "dev"
  ],
  extraPackages ? [ ],
  extraProfile ? "",
  buildFHSEnv,
  gcc,
  clang,
}@input:

with lib;
let
  buildFHSEnv_eff = if input ? "buildFHSEnv" then input.buildFHSEnv else pkgs.buildFHSEnv;
  standardPackages =
    pkgs:
    [
      gcc
      clang
    ]
    ++ (with pkgs; [
      autoconf
      binutils
      clang
      cmake
      expat
      gcc
      gfortran
      gmp
      gnumake
      gperf
      libxml2
      m4
      nss
      openssl
      unzip
      util-linux
      which
      texliveScheme
      ncurses
      poetry
    ])
    ++ lib.optional enableNode pkgs.nodejs
    ++ extraPackages;

  graphicalPackages =
    pkgs: with pkgs; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      # customGr
      dbus
      expat
      ffmpeg
      fontconfig
      freetype
      gettext
      glfw
      glib
      glib.out
      gnome2.GConf
      gtk2
      gtk2-x11
      gtk3
      libGL
      libcap
      libdrm
      libgnome-keyring
      libgpg-error
      libnotify
      libpng
      libsecret
      libselinux
      libuuid
      libxkbcommon
      mesa # TODO: Use libgbm instead when upstream fixed: https://github.com/NixOS/nixpkgs/issues/218232
      ncurses
      nspr
      nss
      pango
      pango.out
      pdf2svg
      systemd
      vulkan-loader
      vulkan-headers
      vulkan-validation-layers
      wayland
      libice
      libsm
      libx11
      libxscrnsaver
      libxcomposite
      libxcursor
      libxcursor
      libxdamage
      libxext
      libxfixes
      libxi
      libxinerama
      libxrandr
      libxrender
      libxt
      libxtst
      libxxf86vm
      libxcb
      libxkbfile
      xorgproto
      zlib
    ];

  nvidiaPackages =
    pkgs: with pkgs; [
      cudaPackages.cudatoolkit
      linuxPackages.nvidia_x11
    ];

  quartoPackages =
    pkgs:
    let
      quarto = pkgs.callPackage ./quarto.nix {
        rWrapper = null;
      };
    in
    [ quarto ];

  condaPackages =
    pkgs: with pkgs; [ (callPackage ./conda.nix { installationPath = condaInstallationPath; }) ];

  pythonPackages =
    pkgs: with pkgs; [
      (python3.withPackages (
        ps: with ps; [
          jupyter
          jupyterlab
          numpy
          scipy
          pandas
          matplotlib
          scikit-learn
          tox
          pygments
        ]
      ))
    ];

  targetPkgs =
    pkgs:
    (standardPackages pkgs)
    ++ optionals enableGraphical (graphicalPackages pkgs)
    ++ optionals enableJulia [ (pkgs.callPackage ./julia.nix { juliaVersion = juliaVersion; }) ]
    ++ optionals enableQuarto (quartoPackages pkgs)
    ++ optionals enableConda (condaPackages pkgs)
    ++ optionals enableNVIDIA (nvidiaPackages pkgs)
    ++ optionals enablePython (pythonPackages pkgs);

  std_envvars = ''
    export EXTRA_CCFLAGS="-I/usr/include"
    export FONTCONFIG_FILE=/etc/fonts/fonts.conf
    export LIBARCHIVE=${pkgs.libarchive.lib}/lib/libarchive.so
  '';

  graphical_envvars = ''
    export QTCOMPOSE=${pkgs.libx11}/share/X11/locale
  '';

  conda_envvars = ''
    export NIX_CFLAGS_COMPILE="-I${condaInstallationPath}/include"
    export NIX_CFLAGS_LINK="-L${condaInstallationPath}lib"
    export PATH=${condaInstallationPath}/bin:$PATH
    # source ${condaInstallationPath}/etc/profile.d/conda.sh
  '';

  conda_julia_envvars = ''
    export CONDA_JL_HOME=${condaInstallationPath}/envs/${condaJlEnv}
  '';

  julia_envvars = ''
    # julia needs this file so its package manager operates project-local.
    touch Project.toml
    export JULIA_PROJECT="@."
  '';

  nvidia_envvars = (
    let
      cudatoolkit = pkgs.symlinkJoin {
        name = "cudatoolkit";
        paths = [
          pkgs.cudaPackages.cudatoolkit
          pkgs.cudaPackages.cuda_cuxxfilt.src
        ];
      };
    in
    ''
      export CUDA_PATH=${cudatoolkit}
      export LD_LIBRARY_PATH=${cudatoolkit}/lib:${pkgs.zlib}/lib:$LD_LIBRARY_PATH
      export EXTRA_LDFLAGS="-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib"
    ''
  );

  profile =
    std_envvars
    + optionalString enableGraphical graphical_envvars
    + optionalString enableConda conda_envvars
    + optionalString (enableConda && enableJulia) conda_julia_envvars
    + optionalString enableJulia julia_envvars
    + optionalString enableNVIDIA nvidia_envvars
    + extraProfile;

  multiPkgs = pkgs: with pkgs; [ zlib ];

  condaInitScript = ''
    conda-install
    conda create -n ${condaJlEnv} python=${pythonVersion}
  '';
in
buildFHSEnv_eff {
  inherit multiPkgs extraOutputsToInstall runScript;
  targetPkgs = targetPkgs;
  name = commandName; # Name used to start this UserEnv
  profile = profile;
}
