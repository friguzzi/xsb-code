# XSB Tools

## MCP Server (xsb -e)
`mcp_xsb_server.py` is a minimal MCP server that runs stateless XSB queries via `xsb -e`.

Example:
```
python3 XSB/tools/mcp_xsb_server.py --xsb-bin XSB/bin/xsb
```

Environment variables:
- `XSB_BIN` overrides the default XSB executable path.

Inputs:
- `query` (string) required; Prolog goal to execute.
- `timeout_seconds` (number) optional; defaults to 30.

Output includes exit code, stdout, and stderr for each query.
