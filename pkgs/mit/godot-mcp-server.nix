# pi-mcp-adapter integration for Godot MCP server.
#
# This is configured in modules/programs/programs-godot-mcp.nix and
# registered in modules/home/home-nathan.nix via imports.
#
# Setup:
# 1. Ensure `programs.pi-coding-agent.enable = true`
# 2. The `pi-mcp-adapter` package is automatically added to settings.packages
# 3. When Godot runs, it automatically exposes WebSocket :6505 for MCP connections
#
# The godot-mcp-server npm package (v0.6.1+) runs inside Godot as the
# Godlink MCP plugin - no separate installation needed.
#
# See programs-godot.nix for base Godot packages, and
# programs-godot-mcp.nix for pi-coding-agent integration.

{ inputs, ... }: { }
