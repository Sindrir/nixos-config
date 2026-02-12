{ lib
, stdenv
, fetchFromGitHub
, rustPlatform
, pkg-config
, openssl
, alsa-lib
, libxkbcommon
, wayland
, libGL
, udev
, perl
, cargo
, rustc
, cudaSupport ? true
, cudaPackages
}:

rustPlatform.buildRustPackage rec {
  pname = "super-stt";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "jorge-menjivar";
    repo = "super-stt";
    rev = "main"; # You can pin this to a specific commit or tag
    hash = "sha256-YKIvkdQKOrPbUbpUx0xxbSHDCFPibVIBV8sngX3/RmA=";
  };

  # Apply patch to add Norwegian Whisper models
  patches = [ ./add-norwegian-models.patch ];

  # Use cargoHash instead of cargoLock for easier maintenance
  cargoHash = "sha256-xuq8IcUmwM1f87XMW1RvmxFDieckUcofWC84gBWwb/8=";

  nativeBuildInputs = [
    pkg-config
    perl
    rustc
    cargo
  ] ++ lib.optionals cudaSupport [
    cudaPackages.cuda_nvcc
  ];

  buildInputs = [
    openssl
    alsa-lib
    libxkbcommon
    wayland
    libGL
    udev
  ] ++ lib.optionals cudaSupport [
    cudaPackages.cuda_cudart
    cudaPackages.cuda_nvrtc
    cudaPackages.libcurand
    cudaPackages.cudnn
    cudaPackages.libcublas
  ];

  # The workspace contains multiple binaries
  # Build all three: daemon, app, and applet
  cargoBuildFlags = [
    "--workspace"
  ] ++ lib.optionals cudaSupport [
    "--features"
    "cuda,cudnn"
  ];

  # Skip tests as they may require specific hardware or models
  doCheck = false;

  # Set up environment variables for the build
  LIBCLANG_PATH = "${stdenv.cc.cc.lib}/lib";

  # CUDA environment variables (when GPU support is enabled)
  # cudarc and candle-kernels look for CUDA in these paths during build
  preBuild = lib.optionalString cudaSupport ''
    export CUDA_PATH="${cudaPackages.cuda_cudart}"
    export CUDA_ROOT="${cudaPackages.cuda_cudart}"
    export CUDA_TOOLKIT_ROOT_DIR="${cudaPackages.cuda_cudart}"
    export CUDNN_PATH="${cudaPackages.cudnn}"
    # Set compute capability for RTX 30xx series (8.6)
    # Adjust this if you have a different GPU:
    # RTX 40xx: 8.9, RTX 20xx: 7.5, GTX 10xx: 6.1
    export CUDA_COMPUTE_CAP="86"
  '';

  # Provide git information for vergen crate
  # Since we're building from a fetched source without .git directory,
  # we need to manually set the environment variables that vergen expects
  VERGEN_GIT_SHA = src.rev;
  # Use a placeholder date since we don't have the actual commit date
  # This could be improved by using the actual commit date from GitHub API
  VERGEN_GIT_COMMIT_DATE = "2024-01-01T00:00:00Z";

  # Runtime dependencies
  postInstall = ''
        # The binaries should be in $out/bin already from cargo build
        # Install systemd service file
        mkdir -p $out/lib/systemd/user
        cat > $out/lib/systemd/user/super-stt.service <<EOF
    [Unit]
    Description=Super STT Daemon
    After=network.target

    [Service]
    Type=simple
    ExecStart=$out/bin/super-stt
    Restart=on-failure
    RestartSec=5

    [Install]
    WantedBy=default.target
    EOF

        # Install COSMIC applet desktop files (all three variants)
        mkdir -p $out/share/applications

        # Full visualization applet
        cat > $out/share/applications/super-stt-cosmic-applet-full.desktop <<EOF
    [Desktop Entry]
    Type=Application
    Name=Super STT Applet (Full)
    Comment=Speech-to-text panel applet - Full visualization display
    Icon=super-stt-cosmic-applet-symbolic
    Exec=$out/bin/super-stt-cosmic-applet --side full
    Terminal=false
    Categories=COSMIC;
    Keywords=COSMIC;Iced;Speech;STT;Super;
    NoDisplay=true
    X-CosmicApplet=true
    X-CosmicHoverPopup=Auto
    X-OverflowPriority=50
    EOF

        # Left side applet
        cat > $out/share/applications/super-stt-cosmic-applet-left.desktop <<EOF
    [Desktop Entry]
    Type=Application
    Name=Super STT Applet (Left Side)
    Comment=Speech-to-text panel applet - Left side visualization display
    Icon=super-stt-cosmic-applet-symbolic
    Exec=$out/bin/super-stt-cosmic-applet --side left
    Terminal=false
    Categories=COSMIC;
    Keywords=COSMIC;Iced;Speech;STT;Super;
    NoDisplay=true
    X-CosmicApplet=true
    X-CosmicHoverPopup=Auto
    X-OverflowPriority=50
    EOF

        # Right side applet
        cat > $out/share/applications/super-stt-cosmic-applet-right.desktop <<EOF
    [Desktop Entry]
    Type=Application
    Name=Super STT Applet (Right Side)
    Comment=Speech-to-text panel applet - Right side visualization display
    Icon=super-stt-cosmic-applet-symbolic
    Exec=$out/bin/super-stt-cosmic-applet --side right
    Terminal=false
    Categories=COSMIC;
    Keywords=COSMIC;Iced;Speech;STT;Super;
    NoDisplay=true
    X-CosmicApplet=true
    X-CosmicHoverPopup=Auto
    X-OverflowPriority=50
    EOF

        # Install applet icon
        mkdir -p $out/share/icons/hicolor/scalable/apps
        # Create a simple microphone icon as a placeholder
        # In a production setup, you'd copy the actual icon from the source
        cat > $out/share/icons/hicolor/scalable/apps/super-stt-cosmic-applet-symbolic.svg <<EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">
      <path d="M8 1a2 2 0 0 0-2 2v4a2 2 0 1 0 4 0V3a2 2 0 0 0-2-2zm0 9a3 3 0 0 1-3-3H4a4 4 0 0 0 3 3.87V13H5v1h6v-1H9v-2.13A4 4 0 0 0 12 7h-1a3 3 0 0 1-3 3z"/>
    </svg>
    EOF

        # Create wrapper script for convenience
        mkdir -p $out/bin
        cat > $out/bin/stt <<EOF
    #!/bin/sh
    exec $out/bin/super-stt "\$@"
    EOF
        chmod +x $out/bin/stt
  '';

  # Add runtime library paths
  postFixup =
    let
      daemonLibs = [
        alsa-lib
        libxkbcommon
        wayland
        libGL
        udev
      ] ++ lib.optionals cudaSupport [
        cudaPackages.cuda_cudart
        cudaPackages.cuda_nvrtc
        cudaPackages.libcurand
        cudaPackages.cudnn
        cudaPackages.libcublas
      ];
      guiLibs = [
        libxkbcommon
        wayland
        libGL
      ];
    in
    ''
      patchelf --add-rpath ${lib.makeLibraryPath daemonLibs} $out/bin/super-stt
      patchelf --add-rpath ${lib.makeLibraryPath guiLibs} $out/bin/super-stt-app
      patchelf --add-rpath ${lib.makeLibraryPath guiLibs} $out/bin/super-stt-cosmic-applet
    '';

  meta = with lib; {
    description = "High-performance speech-to-text service for Linux with real-time transcription";
    homepage = "https://github.com/jorge-menjivar/super-stt";
    license = licenses.unfree; # Check actual license from repository
    maintainers = [ ];
    platforms = platforms.linux;
    mainProgram = "super-stt";
  };
}
