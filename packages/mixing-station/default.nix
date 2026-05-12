{ lib
, stdenv
, fetchurl
, makeWrapper
, unzip
, jdk21
, zenity
, libGL
}:

let
  version = "2.8.0";
in
stdenv.mkDerivation {
  pname = "mixing-station";
  inherit version;

  src = fetchurl {
    url = "https://mixingstation.app/backend/api/web/download/update/mixing-station-pc/release";
    hash = "sha256-mxA11UoluCFTn3FHZSfkj0qOL6xZEOzvY5GRjIo3JDs=";
  };

  nativeBuildInputs = [
    makeWrapper
    unzip
  ];

  sourceRoot = ".";

  unpackPhase = ''
    unzip $src
  '';

  installPhase = ''
        runHook preInstall

        mkdir -p $out/share/mixing-station
        install -m644 mixing-station-desktop.jar $out/share/mixing-station/

        mkdir -p $out/bin
        makeWrapper ${jdk21}/bin/java $out/bin/mixing-station \
          --add-flags "-DlegacyShaders=true" \
          --add-flags "-jar $out/share/mixing-station/mixing-station-desktop.jar" \
          --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ libGL ]}" \
          --suffix LD_LIBRARY_PATH : "/run/opengl-driver/lib" \
          --prefix PATH : "${lib.makeBinPath [ zenity ]}"

        mkdir -p $out/share/applications
        cat > $out/share/applications/mixing-station.desktop <<DESKTOP
    [Desktop Entry]
    Type=Application
    Name=Mixing Station
    Comment=Mixer remote control for multiple digital mixers
    Exec=mixing-station
    Icon=mixing-station
    Categories=Audio;Music;
    Terminal=false
    DESKTOP

        runHook postInstall
  '';

  meta = with lib; {
    description = "Mixer remote control for multiple digital mixers";
    homepage = "https://mixingstation.app/";
    license = licenses.unfree;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "mixing-station";
    sourceProvenance = [ sourceTypes.binaryBytecode ];
  };
}
