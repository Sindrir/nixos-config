{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeBinaryWrapper
}:

let
  version = "0.95.0";
in
stdenv.mkDerivation {
  pname = "jcode";
  inherit version;

  src = fetchurl {
    url = "https://github.com/1jehuang/jcode/releases/download/v${version}/jcode-linux-x86_64.tar.gz";
    hash = "sha256-xskD3l6CEB8CSWIgRDLxosilu9hy8+Uvr58nb3+kz4w=";
  };

  nativeBuildInputs = [ autoPatchelfHook makeBinaryWrapper ];
  # libgcc_s.so.1
  buildInputs = [ stdenv.cc.cc.lib ];

  # The tarball extracts directly into the current directory
  sourceRoot = ".";

  unpackPhase = ''
    tar -xzf $src
  '';

  # The tarball also ships a jcode-linux-x86_64 sh launcher that only prepends
  # its own dir to LD_LIBRARY_PATH; autoPatchelf makes it unnecessary.
  installPhase = ''
    runHook preInstall
    install -D -m755 jcode-linux-x86_64.bin $out/bin/jcode
    # Opt out of usage telemetry and transcript uploads (see upstream TELEMETRY.md)
    wrapProgram $out/bin/jcode --set JCODE_NO_TELEMETRY 1
    runHook postInstall
  '';

  meta = with lib; {
    description = "High performance coding agent harness written in Rust";
    longDescription = ''
      This package is pinned to v${version}. The built-in `jcode update` /
      `/update` cannot replace a Nix store binary; bump version and hash in
      packages/jcode/default.nix instead.
    '';
    homepage = "https://github.com/1jehuang/jcode";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "jcode";
  };
}
