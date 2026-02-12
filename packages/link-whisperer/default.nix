{ lib, stdenv, makeWrapper, fish }:

stdenv.mkDerivation {
  pname = "link-whisperer";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
        # Install the dispatcher script
        mkdir -p $out/bin
        cat > $out/bin/link-whisperer <<'DISPATCHER'
    #!/usr/bin/env bash
    URL="$1"
    case "$URL" in
      *code-with-me.global.jetbrains.com/*)
        exec fish -c "join_code_with_me '$URL'"
        ;;
      *)
        exec ''${BROWSER:-firefox} "$URL"
        ;;
    esac
    DISPATCHER
        chmod +x $out/bin/link-whisperer

        # Install desktop entry
        mkdir -p $out/share/applications
        cat > $out/share/applications/link-whisperer.desktop <<EOF
    [Desktop Entry]
    Type=Application
    Name=The Link Whisperer
    Comment=Routes URLs to appropriate handlers
    Exec=$out/bin/link-whisperer %u
    Icon=link-whisperer
    Categories=Network;
    NoDisplay=true
    MimeType=x-scheme-handler/http;x-scheme-handler/https;
    EOF

        # Install fish function
        mkdir -p $out/share/fish/vendor_functions.d
        cp $src/join_code_with_me.fish $out/share/fish/vendor_functions.d/join_code_with_me.fish

        # Install icons
        mkdir -p $out/share/icons/hicolor/256x256/apps
        mkdir -p $out/share/icons/hicolor/128x128/apps
        cp $src/icon-256.png $out/share/icons/hicolor/256x256/apps/link-whisperer.png
        cp $src/icon-128.png $out/share/icons/hicolor/128x128/apps/link-whisperer.png
  '';

  postFixup = ''
    wrapProgram $out/bin/link-whisperer \
      --prefix PATH : ${lib.makeBinPath [ fish ]}
  '';

  meta = with lib; {
    description = "The Link Whisperer - custom URL dispatcher that routes links to the right place";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "link-whisperer";
  };
}
