# CONTRIBUTING.md

Thank you for your interest in contributing to DeepCharset!

## Development Environment

- **IDE**: Embarcadero Delphi 13.x (RAD Studio 13.1)
- **Platform**: Windows 64-bit (Win64)
- **Branch**: `upgrade/delphi-13` for active development; `master` for stable releases
- **Dependencies**: See `build.bat` and `DeepCharset.dproj` for required packages

## Building

```bash
# Install Delphi 13.1 toolchain first
# Then open DeepCharset.dproj in the IDE and press F9, or:

build.bat            # Debug build
build.bat Release    # Release build
```

## Test Suite

```bash
tests_run.bat /quick        # Smoke test (<10s)
tests_run.bat /crit /perf   # Critical regression + performance
tests_run.bat /cp           # Cross-codepage regression (GBK/Big5)
```

## Architecture Principles

Please read `CLAUDE.md` before contributing — it defines:

- Layer separation (View → Controller → Helper/Model → Utils → Interfaces)
- Naming conventions (`View*`, `Controller*`, `Model*`, `Helper*`, `Utils*`)
- Global variable elimination rules
- Configuration management via `TAppConfig`
- Logging policy
- Memory safety rules

### Key rules

1. **View does not make business decisions** — button clicks call Controllers
2. **Controller does not know UI** — no `Vcl.Forms` / `ShowMessage` in Controllers
3. **Utils is pure** — no business logic, no Model/Controller references
4. **No new globals** — use constructor injection
5. **No bare `except`** — always log the exception
6. **New files must be UTF-8 with BOM** — never leave default names (Unit1, Form1)

## Commit Convention

```
<type>: <short Chinese description>

Types: feat | fix | refactor | docs | test | chore
```

## License

By contributing, you agree your contributions will be licensed under the project's [MIT License](LICENSE).
