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
}:

rustPlatform.buildRustPackage rec {
  pname = "super-stt";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "jorge-menjivar";
    repo = "super-stt";
    rev = "main"; # You can pin this to a specific commit or tag
    hash = "sha256-pcwflO3ecL9Zp5z6FFu+ERFk1RhEfyxRdVe1F/NL4hM=";
  };

  # Apply patch to add Norwegian Whisper models
  patches = [ ./add-norwegian-models.patch ];

  # Use cargoHash instead of cargoLock for easier maintenance
  cargoHash = "sha256-K1oNMP0E3d0vhB2Lt22sRHTIXKSqNLginbZJYjIC4yk=";

  nativeBuildInputs = [
    pkg-config
    perl
    rustc
    cargo
  ];

  buildInputs = [
    openssl
    alsa-lib
    libxkbcommon
    wayland
    libGL
    udev
  ];

  # The workspace contains multiple binaries
  # Build all three: daemon, app, and applet
  cargoBuildFlags = [
    "--workspace"
  ];

  # Skip tests as they may require specific hardware or models
  doCheck = false;

  # Set up environment variables for the build
  LIBCLANG_PATH = "${stdenv.cc.cc.lib}/lib";

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

        # Install COSMIC applet desktop file
        mkdir -p $out/share/applications
        cat > $out/share/applications/super-stt-cosmic-applet.desktop <<EOF
    [Desktop Entry]
    Type=Application
    Name=Super STT
    Comment=Speech-to-text applet
    Icon=audio-input-microphone
    Exec=$out/bin/super-stt-cosmic-applet
    Categories=Utility;
    Keywords=speech;transcription;stt;voice;
    NoDisplay=false
    X-COSMIC-Applet=true
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
  postFixup = ''
    patchelf --add-rpath ${lib.makeLibraryPath [
      alsa-lib
      libxkbcommon
      wayland
      libGL
      udev
    ]} $out/bin/super-stt
    patchelf --add-rpath ${lib.makeLibraryPath [
      libxkbcommon
      wayland
      libGL
    ]} $out/bin/super-stt-app
    patchelf --add-rpath ${lib.makeLibraryPath [
      libxkbcommon
      wayland
      libGL
    ]} $out/bin/super-stt-cosmic-applet
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
