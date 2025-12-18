{ lib
, python3
, python3Packages
, ...
}:

python3Packages.buildPythonApplication {
  pname = "nixos-mcp-server";
  version = "0.1.0";
  pyproject = true;

  src = ./.;

  nativeBuildInputs = with python3Packages; [
    setuptools
  ];

  propagatedBuildInputs = with python3Packages; [
    mcp
  ];

  # The server needs access to nix commands
  makeWrapperArgs = [
    "--prefix PATH : ${lib.makeBinPath [ ]}"
  ];

  meta = with lib; {
    description = "MCP server for NixOS system information";
    homepage = "https://github.com/yourusername/nixos-mcp-server";
    license = licenses.mit;
    maintainers = [ ];
  };
}
