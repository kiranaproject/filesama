# filesama — Project Rules

## Object Pascal Coding Conventions

All code in this project must adhere strictly to the following conventions:
- **Mandatory `()`**: Every zero-parameter procedure, function, constructor, or destructor declaration and call site must have `()`.
- **Unit Filenames & Declarations**: Unit filenames are lowercase dot-separated (`filesama.<subsystem>.pas`), while the unit name declared inside the header is PascalCase (`unit FileSama.<Subsystem>;`).
- **Formatting**: 2 spaces indent, no tabs, `begin` on a new line aligned with controlling keyword.
- **Comments**: Use `//` line comments; never use nested `{}` block comments.
- **Memory**: Pair every heap allocation with `try..finally Free()`.

## Build & Tool Invariants

- **`project.xml`** is the only project descriptor used by Pasbuild (`pasbuild.json` does not exist).
- **`find_by_name` Requires `Pattern`**: Always supply `Pattern: "*"` even when specifying `Extensions` or `Type`.
- **Required Metadata**: Every tool call must include `toolSummary` (2–5 word noun phrase).

## Linux Windowing & Display Server Policy

- **Strictly X11/XCB Only (No Wayland)**:
  - `filesama` is built on native X11/XCB and `libft.so`. Never reference, propose, or insert Wayland into code, architecture, or documentation.
