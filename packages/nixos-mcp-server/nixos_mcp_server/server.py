#!/usr/bin/env python3
"""
NixOS MCP Server - Provides NixOS system information to Claude via MCP protocol
"""

import asyncio
import json
import subprocess
import os
from pathlib import Path
from typing import Any

from mcp.server.models import InitializationOptions
from mcp.server import NotificationOptions, Server
from mcp.server.stdio import stdio_server
from mcp.types import (
    Resource,
    Tool,
    TextContent,
    ImageContent,
    EmbeddedResource,
    LoggingLevel
)


server = Server("nixos-mcp-server")


def run_command(cmd: list[str], check: bool = True) -> dict[str, Any]:
    """Run a command and return the result"""
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=check,
            timeout=30
        )
        return {
            "success": True,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "returncode": result.returncode
        }
    except subprocess.CalledProcessError as e:
        return {
            "success": False,
            "stdout": e.stdout,
            "stderr": e.stderr,
            "returncode": e.returncode,
            "error": str(e)
        }
    except subprocess.TimeoutExpired:
        return {
            "success": False,
            "error": "Command timed out after 30 seconds"
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }


@server.list_resources()
async def handle_list_resources() -> list[Resource]:
    """List available NixOS resources"""
    return [
        Resource(
            uri="nixos://system/configuration",
            name="Current NixOS Configuration",
            description="The current system configuration",
            mimeType="text/plain",
        ),
        Resource(
            uri="nixos://system/generation",
            name="Current System Generation",
            description="Information about the current system generation",
            mimeType="text/plain",
        ),
        Resource(
            uri="nixos://flake/metadata",
            name="Flake Metadata",
            description="Metadata about the current NixOS flake",
            mimeType="application/json",
        ),
    ]


@server.read_resource()
async def handle_read_resource(uri: str) -> str:
    """Read a NixOS resource"""
    if uri == "nixos://system/configuration":
        # Get the current system configuration path
        result = run_command(["readlink", "-f", "/run/current-system"])
        if result["success"]:
            return f"Current system: {result['stdout'].strip()}\n"
        return "Could not read system configuration"

    elif uri == "nixos://system/generation":
        result = run_command(["nixos-rebuild", "list-generations", "--json"])
        if result["success"]:
            return result["stdout"]
        return "Could not list generations"

    elif uri == "nixos://flake/metadata":
        # Try to get flake metadata from common config location
        config_dirs = [
            os.path.expanduser("~/nixos-config"),
            "/etc/nixos",
        ]
        for config_dir in config_dirs:
            if os.path.exists(f"{config_dir}/flake.nix"):
                result = run_command(["nix", "flake", "metadata", "--json", config_dir])
                if result["success"]:
                    return result["stdout"]
        return json.dumps({"error": "No flake found"})

    return "Resource not found"


@server.list_tools()
async def handle_list_tools() -> list[Tool]:
    """List available NixOS tools"""
    return [
        Tool(
            name="search_packages",
            description="Search for NixOS packages",
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "Package name or search term",
                    }
                },
                "required": ["query"],
            },
        ),
        Tool(
            name="get_package_info",
            description="Get detailed information about a package",
            inputSchema={
                "type": "object",
                "properties": {
                    "package": {
                        "type": "string",
                        "description": "Package attribute path (e.g., 'nixpkgs#firefox')",
                    }
                },
                "required": ["package"],
            },
        ),
        Tool(
            name="list_installed_packages",
            description="List packages installed in the current environment",
            inputSchema={
                "type": "object",
                "properties": {
                    "profile": {
                        "type": "string",
                        "description": "Profile to query (default: current user profile)",
                        "default": "~/.nix-profile"
                    }
                },
            },
        ),
        Tool(
            name="get_system_info",
            description="Get NixOS system information",
            inputSchema={
                "type": "object",
                "properties": {},
            },
        ),
        Tool(
            name="search_options",
            description="Search NixOS configuration options",
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "Option name or search term",
                    }
                },
                "required": ["query"],
            },
        ),
        Tool(
            name="get_flake_info",
            description="Get information about the NixOS flake configuration",
            inputSchema={
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "Path to flake directory",
                        "default": "~/nixos-config"
                    }
                },
            },
        ),
        Tool(
            name="list_generations",
            description="List NixOS system generations",
            inputSchema={
                "type": "object",
                "properties": {
                    "limit": {
                        "type": "integer",
                        "description": "Maximum number of generations to show",
                        "default": 10
                    }
                },
            },
        ),
        Tool(
            name="build_flake_config",
            description="Build a flake configuration (dry-run)",
            inputSchema={
                "type": "object",
                "properties": {
                    "flake_path": {
                        "type": "string",
                        "description": "Path to the flake",
                        "default": "~/nixos-config"
                    },
                    "config": {
                        "type": "string",
                        "description": "Configuration to build (e.g., 'home-desktop')",
                    }
                },
                "required": ["config"],
            },
        ),
    ]


@server.call_tool()
async def handle_call_tool(name: str, arguments: dict | None) -> list[TextContent]:
    """Handle tool calls for NixOS operations"""
    if arguments is None:
        arguments = {}

    try:
        if name == "search_packages":
            query = arguments.get("query", "")
            result = run_command(["nix", "search", "nixpkgs", query, "--json"])
            if result["success"]:
                try:
                    packages = json.loads(result["stdout"])
                    formatted = json.dumps(packages, indent=2)
                    return [TextContent(type="text", text=f"Found packages:\n{formatted}")]
                except json.JSONDecodeError:
                    return [TextContent(type="text", text=result["stdout"])]
            return [TextContent(type="text", text=f"Error: {result.get('error', result.get('stderr', 'Unknown error'))}")]

        elif name == "get_package_info":
            package = arguments.get("package", "")
            result = run_command(["nix", "eval", package, "--json"])
            if result["success"]:
                return [TextContent(type="text", text=result["stdout"])]
            return [TextContent(type="text", text=f"Error: {result.get('error', result.get('stderr', 'Unknown error'))}")]

        elif name == "list_installed_packages":
            profile = arguments.get("profile", "~/.nix-profile")
            profile = os.path.expanduser(profile)
            result = run_command(["nix", "profile", "list", "--profile", profile])
            if result["success"]:
                return [TextContent(type="text", text=result["stdout"])]
            return [TextContent(type="text", text=f"Error: {result.get('error', result.get('stderr', 'Unknown error'))}")]

        elif name == "get_system_info":
            info = {}

            # Get NixOS version
            version_result = run_command(["nixos-version"], check=False)
            if version_result["success"]:
                info["nixos_version"] = version_result["stdout"].strip()

            # Get current system
            system_result = run_command(["readlink", "-f", "/run/current-system"], check=False)
            if system_result["success"]:
                info["current_system"] = system_result["stdout"].strip()

            # Get hostname
            hostname_result = run_command(["hostname"], check=False)
            if hostname_result["success"]:
                info["hostname"] = hostname_result["stdout"].strip()

            return [TextContent(type="text", text=json.dumps(info, indent=2))]

        elif name == "search_options":
            query = arguments.get("query", "")
            result = run_command(["nixos-option", query], check=False)
            if result["success"]:
                return [TextContent(type="text", text=result["stdout"])]
            return [TextContent(type="text", text=f"Error: {result.get('error', result.get('stderr', 'Option not found'))}")]

        elif name == "get_flake_info":
            path = os.path.expanduser(arguments.get("path", "~/nixos-config"))
            result = run_command(["nix", "flake", "metadata", path, "--json"])
            if result["success"]:
                try:
                    metadata = json.loads(result["stdout"])
                    formatted = json.dumps(metadata, indent=2)
                    return [TextContent(type="text", text=formatted)]
                except json.JSONDecodeError:
                    return [TextContent(type="text", text=result["stdout"])]
            return [TextContent(type="text", text=f"Error: {result.get('error', result.get('stderr', 'Unknown error'))}")]

        elif name == "list_generations":
            limit = arguments.get("limit", 10)
            result = run_command(["nixos-rebuild", "list-generations"], check=False)
            if result["success"]:
                lines = result["stdout"].strip().split('\n')
                limited = '\n'.join(lines[-limit:])
                return [TextContent(type="text", text=limited)]
            return [TextContent(type="text", text=f"Error: {result.get('error', result.get('stderr', 'Unknown error'))}")]

        elif name == "build_flake_config":
            flake_path = os.path.expanduser(arguments.get("flake_path", "~/nixos-config"))
            config = arguments.get("config")
            flake_ref = f"{flake_path}#{config}"
            result = run_command(["nixos-rebuild", "build", "--flake", flake_ref, "--dry-run"])
            if result["success"]:
                return [TextContent(type="text", text=f"Dry-run successful:\n{result['stdout']}")]
            return [TextContent(type="text", text=f"Error: {result.get('error', result.get('stderr', 'Unknown error'))}")]

        return [TextContent(type="text", text=f"Unknown tool: {name}")]

    except Exception as e:
        return [TextContent(type="text", text=f"Error executing tool: {str(e)}")]


async def async_main():
    """Run the MCP server"""
    async with stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="nixos-mcp-server",
                server_version="0.1.0",
                capabilities=server.get_capabilities(
                    notification_options=NotificationOptions(),
                    experimental_capabilities={},
                ),
            ),
        )


def main():
    """Entry point for the MCP server"""
    asyncio.run(async_main())


if __name__ == "__main__":
    main()
