# Repository Guidelines

## Project Structure & Module Organization
The core sources live under `XSB/`, with C code in `XSB/emu`, Prolog sources in `XSB/cmplib`, `XSB/syslib`, and `XSB/lib`, optional add-ons in `XSB/packages`, and docs/examples in `XSB/docs` and `XSB/examples`. Test suites are separated: `xsbtests/` holds the primary regression scripts, while `mttests/` hosts multithreaded/concurrency tests. Build configuration and autoconf tooling live in `XSB/build`.

## Documentation
The XSB manuals are in `XSB/docs/userman` in word-processor (`.wd`) and plain-text (`.txt`) formats. The top-level overview in `XSB/README` is a quick map of key directories and packages. Link to these docs in PRs when behavior or interfaces change.

For tabled-evaluation, delay-list, incremental-maintenance, and stack-corruption
work, read `docs/internals_for_agents/README.md` before editing the emulator. It records
the relevant source map, lifetime invariants, and a workflow for separating an
upstream corruption from the instruction that eventually observes it.

## Build, Test, and Development Commands
Run builds from `XSB/build`:
- `./configure` configures the build for your platform (`./configure --help` for options).
- `./makexsb` builds XSB and configures packages.
- `./makexsb fast` skips package configuration; `./makexsb devel` rebuilds missing objects; `./makexsb superdevel` forces a full Prolog recompilation.
- `./makexsb clean` or `./makexsb distclean` removes generated artifacts.
After a successful build, launch with `XSB/bin/xsb`.

## Coding Style & Naming Conventions
Use the existing formatting in each file; avoid broad reformatting. Prolog source files use the `.P` extension and compiled artifacts (`.xwam`) are generated. C sources and headers (`.c`/`.h`) live under `XSB/emu` and follow the file’s established indentation and brace style. Keep headers and file comments intact, and prefer descriptive predicate/module names that align with their directory (for example, `XSB/syslib/*.P`). No repo-wide formatter or linter is configured.

## Testing Guidelines

Before running tests, read [../xsbtests/AGENTS.md](../xsbtests/AGENTS.md) for
environment setup, log interpretation, cache-dependent results, and
known-failure handling.

Primary test execution is in `xsbtests/`:
- `xsbtests/testsuite.sh /path/to/XSB` runs the full suite and writes logs to `/tmp/xsb_test_log.$USER`.
- `xsbtests/supertest.sh /path/to/XSB` runs across multiple configurations.
- `xsbtests/gctest.sh /path/to/XSB` focuses on garbage collector coverage.
For multithreaded scenarios, use scripts in `mttests/` (for example, `mttests/test_concurr.sh "XSB/bin/xsb" 4`). There is no explicit coverage threshold specified.

For emulator corruption bugs, test both a fresh process per query and the full
query sequence in one process. Fresh-process success establishes local query
behavior but does not exercise stale table, delay, IDG, trie, or choice-point
state carried across updates. When an ErgoAI workload is involved, rebuild XSB
first and verify which executable `ErgoAI/.ergo_paths` selects. Do not repair a
decoder or unification opcode merely because it encounters an impossible tag;
first find where the malformed cell or stale pointer was produced.

## Tooling & Automation
A minimal MCP server for stateless queries lives at `XSB/tools/mcp_xsb_server.py`. Example: `python3 XSB/tools/mcp_xsb_server.py --xsb-bin XSB/bin/xsb`. Set `XSB_BIN` to override the default executable path.

## Commit & Pull Request Guidelines
No strict commit message convention is documented in the repo; use concise, imperative subjects (for example, “Fix tabled evaluation regression”) and keep changes scoped. PRs should include a clear summary, the commands used to test (or a note if tests were skipped), and any relevant configuration details (such as `--config-tag` or `fast` builds). Link related issues or include screenshots when applicable.
