{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "0.40.2";
  sources = {
    x86_64-linux = {
      url = "https://github.com/docker/mcp-gateway/releases/download/v${version}/docker-mcp-linux-amd64.tar.gz";
      hash = "sha256-UOI4gcKWgftGwzzebDvc8UztTOcpl2acE5ObNHJdFvc=";
    };
    aarch64-linux = {
      url = "https://github.com/docker/mcp-gateway/releases/download/v${version}/docker-mcp-linux-arm64.tar.gz";
      hash = "sha256-ev9RqRoUjBqGYzhVA0dJ4zOSekTNr1ii+1Ed2scdlIA=";
    };
  };
  source = sources.${stdenv.hostPlatform.system} or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "docker-mcp";
  inherit version;

  src = fetchurl {
    inherit (source) url hash;
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  # The tarball extracts directly into the current directory
  sourceRoot = ".";

  unpackPhase = ''
    tar -xzf $src
  '';

  installPhase = ''
    runHook preInstall
    install -D -m755 docker-mcp $out/bin/docker-mcp
    runHook postInstall
  '';

  meta = with lib; {
    description = "Docker MCP Gateway - Docker CLI plugin for orchestrating Model Context Protocol servers";
    longDescription = ''
      Docker MCP Gateway is an open source solution for orchestrating Model Context
      Protocol (MCP) servers. It acts as a centralized proxy managing configuration,
      credentials, and access control between AI clients and MCP servers.

      This package is pinned to v${version}. To check for updates, run:
        docker mcp --version
      Or use the check-docker-mcp-update fish function.
    '';
    homepage = "https://github.com/docker/mcp-gateway";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    mainProgram = "docker-mcp";
  };
}
