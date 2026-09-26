#!/usr/bin/env python3
"""Minimal MCP server for running XSB queries via -e."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict, Optional

PROTOCOL_VERSION = "2024-11-05"
SERVER_NAME = "xsb-mcp"
SERVER_VERSION = "0.1.0"
DEFAULT_TIMEOUT_SECONDS = 30


def read_message(stream) -> Optional[Dict[str, Any]]:
    header_line = stream.readline()
    if not header_line:
        return None

    stripped = header_line.strip()
    if stripped.startswith(b"{"):
        try:
            return json.loads(stripped.decode("utf-8"))
        except json.JSONDecodeError:
            return None

    headers = {}
    line = header_line
    while line:
        if line in (b"\r\n", b"\n"):
            break
        if b":" in line:
            name, value = line.split(b":", 1)
            headers[name.strip().lower()] = value.strip()
        line = stream.readline()

    length_value = headers.get(b"content-length")
    if not length_value:
        return None

    try:
        content_length = int(length_value)
    except ValueError:
        return None

    body = stream.read(content_length)
    if not body:
        return None

    try:
        return json.loads(body.decode("utf-8"))
    except json.JSONDecodeError:
        return None


def write_message(stream, payload: Dict[str, Any]) -> None:
    body = json.dumps(payload, ensure_ascii=True).encode("utf-8")
    stream.write(f"Content-Length: {len(body)}\r\n\r\n".encode("ascii"))
    stream.write(body)
    stream.flush()


def jsonrpc_error(request_id, code: int, message: str) -> Dict[str, Any]:
    return {"jsonrpc": "2.0", "id": request_id, "error": {"code": code, "message": message}}


def jsonrpc_result(request_id, result: Any) -> Dict[str, Any]:
    return {"jsonrpc": "2.0", "id": request_id, "result": result}


def tool_result(text: str, is_error: bool = False) -> Dict[str, Any]:
    return {"content": [{"type": "text", "text": text}], "isError": is_error}


def resolve_xsb_bin(cli_value: Optional[str]) -> Path:
    if cli_value:
        return Path(cli_value).expanduser()
    env_value = os.getenv("XSB_BIN")
    if env_value:
        return Path(env_value).expanduser()
    xsb_root = Path(__file__).resolve().parents[1]
    return xsb_root / "bin" / "xsb"


def handle_tools_list() -> Dict[str, Any]:
    return {
        "tools": [
            {
                "name": "xsb_query",
                "description": "Run a stateless XSB query using `xsb -e`.",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "query": {"type": "string", "description": "Prolog goal to execute."},
                        "timeout_seconds": {
                            "type": "number",
                            "description": "Command timeout in seconds (default 30).",
                        },
                    },
                    "required": ["query"],
                },
            }
        ]
    }


def handle_tools_call(params: Dict[str, Any], xsb_bin: Path, cwd: Optional[Path]) -> Dict[str, Any]:
    name = params.get("name")
    arguments = params.get("arguments") or {}

    if name != "xsb_query":
        return tool_result(f"Unknown tool: {name}", is_error=True)

    query = arguments.get("query")
    if not query:
        return tool_result("Missing required argument: query", is_error=True)

    timeout = arguments.get("timeout_seconds", DEFAULT_TIMEOUT_SECONDS)

    if not xsb_bin.exists():
        return tool_result(f"XSB binary not found at {xsb_bin}", is_error=True)

    try:
        completed = subprocess.run(
            [str(xsb_bin), "-e", query],
            capture_output=True,
            text=True,
            cwd=str(cwd) if cwd else None,
            timeout=timeout,
        )
    except subprocess.TimeoutExpired:
        return tool_result(f"Query timed out after {timeout} seconds", is_error=True)
    except FileNotFoundError:
        return tool_result(f"XSB binary not found at {xsb_bin}", is_error=True)

    output = (
        f"exit_code: {completed.returncode}\n"
        f"stdout:\n{completed.stdout}\n"
        f"stderr:\n{completed.stderr}"
    )
    return tool_result(output, is_error=completed.returncode != 0)


def handle_request(message: Dict[str, Any], xsb_bin: Path, cwd: Optional[Path]):
    request_id = message.get("id")
    method = message.get("method")
    params = message.get("params") or {}

    if method == "initialize":
        result = {
            "protocolVersion": PROTOCOL_VERSION,
            "serverInfo": {"name": SERVER_NAME, "version": SERVER_VERSION},
            "capabilities": {"tools": {}},
        }
        return jsonrpc_result(request_id, result)

    if method == "tools/list":
        return jsonrpc_result(request_id, handle_tools_list())

    if method == "tools/call":
        result = handle_tools_call(params, xsb_bin, cwd)
        return jsonrpc_result(request_id, result)

    if method == "shutdown":
        return jsonrpc_result(request_id, None)

    return jsonrpc_error(request_id, -32601, f"Method not found: {method}")


def main() -> int:
    parser = argparse.ArgumentParser(description="MCP server for XSB.")
    parser.add_argument("--xsb-bin", help="Path to XSB executable.")
    parser.add_argument("--cwd", help="Working directory for XSB execution.")
    args = parser.parse_args()

    xsb_bin = resolve_xsb_bin(args.xsb_bin)
    cwd = Path(args.cwd).expanduser() if args.cwd else None

    while True:
        message = read_message(sys.stdin.buffer)
        if message is None:
            break

        if message.get("method") == "exit":
            break

        if "id" not in message:
            continue

        response = handle_request(message, xsb_bin, cwd)
        write_message(sys.stdout.buffer, response)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
