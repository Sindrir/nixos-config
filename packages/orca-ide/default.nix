{ lib
, appimageTools
, fetchurl
}:

let
  pname = "orca-ide";
  version = "1.4.224";

  src = fetchurl {
    url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-linux.AppImage";
    hash = "sha256-sf6RAtmH012X622cJ0qT2elRqtvoZPwiUaMVAj9gx0Y=";
  };

  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # The bundled desktop entry launches AppRun, which only exists inside the AppImage
  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/orca-ide.desktop -t $out/share/applications
    substituteInPlace $out/share/applications/orca-ide.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=orca-ide'
    cp -r ${appimageContents}/usr/share/icons $out/share
  '';

  meta = with lib; {
    description = "Agentic development environment for running coding agents in parallel worktrees";
    longDescription = ''
      Named orca-ide to avoid clashing with the GNOME screen reader `orca` in nixpkgs.
      This package is pinned to v${version}. The in-app auto-updater cannot replace a
      Nix store AppImage; bump version and hash in packages/orca-ide/default.nix instead.
    '';
    homepage = "https://github.com/stablyai/orca";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    mainProgram = "orca-ide";
  };
}
