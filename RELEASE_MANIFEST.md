# DeepCharset v2.0.1 Release Package Manifest

**Generated**: 2025-12-18
**Version**: 2.0.1
**Status**: ✅ RELEASE READY

---

## Package Contents

### ✅ Core Executable

| Item | Path | Platform |
|------|------|----------|
| Main binary | `bin/DeepCharset.exe` | Win64 |
| CLI version string | `DeepCharset v2.0.1` | - |
| Self-test runner | `bin/SelfTest_Encoding.exe` | Win64 |

### ✅ Runtime Configuration

| Item | Path |
|------|------|
| UI config | `ini/ui.ini` |
| Language packs | `ini/{en-US,zh-CN,zh-TW,ja-JP,ko-KR,de-DE,fr-FR,es-ES,it-IT,pt-BR,ru-RU,ar-SA,th-TH,vi-VN,nl-NL,pl-PL}.ini` |
| Code page aliases | `ini/codes.ini` |

### ✅ Root Documentation

| File | Purpose |
|------|---------|
| `README.md` | Project overview |
| `CHANGELOG.md` | Version history |
| `RELEASE_NOTES.md` | Release highlights for v2.0.1 |
| `RELEASE_MANIFEST.md` | This file |
| `LICENSE` | MIT license |
| `CLAUDE.md` / `WARP.md` | AI tool integration guides |

### ✅ Technical Documentation (`docs/`)

| File | Purpose |
|------|---------|
| `Quick_Start_Guide.md` | Getting started |
| `CommandLine_Usage.md` | CLI reference |
| `Detection_Settings.md` | Detection parameter tuning |
| `Error_Handling.md` | Troubleshooting |
| `EurekaLog_Integration.md` | Exception reporting (legacy) |
| `madExcept_Integration.md` | Exception reporting (current) |
| `PerformanceBenchmark.md` | Performance analysis |
| `Report_Schema.md` | Crash report format |

---

## Quality Assurance

### ✅ Build

- Compiler: Embarcadero Delphi 12/13 (Win64 target)
- Build status: 0 errors
- W1057 implicit string cast warnings: 0
- Remaining acceptable warnings: H2077, H2164, W1002 (documented)

### ✅ Bug Fixes Since v2.0.0beta

| Bug | Severity | Summary |
|-----|----------|---------|
| #5 | Critical | CodePageCache thread safety |
| #7 | Critical (security) | Path traversal & system directory protection |
| #9 | Medium (security) | Temp file secure naming & deletion |
| #10 | Medium (quality) | Unified BOM cleanup |
| #11 | Medium | Cross-volume atomic replace failure |
| #12 | Medium (security) | Path traversal bypass via normalization |
| #14 | Medium | FTempFileList thread safety |
| #15 | Low | FProtectedPaths empty slot |
| #16 | High | Large file memory overflow (via ConvertFileStreaming) |
| #18 | Critical | Missing EncodingExceptions unit |
| #19 | Low | W1057 warnings in test runner |
| v2.0.1-P0.4 | High | CLI Halt() bypassing finalization |
| v2.0.1-P1.1 | High | ConvertFile auto-route to streaming |
| v2.0.1-P1.2 | Medium | BOM-only file false error |
| v2.0.1-P2.1 | Low (UX) | CLI default backup enabled |

### ✅ Test Coverage

- `Tests/SelfTest_Encoding.dpr` - Integration suite (12+ test cases)
- `Tests/Test_BoundaryCases.pas` - Boundary conditions
- `Tests/Test_ConversionIntegrity.pas` - Data integrity validation
- Cross-codepage regression: GBK/Big5 → UTF-8 verified
- UTF-8 BOM cleanup: 8 scenarios verified

---

## Deployment

### Minimal Package

For end-user distribution, only these files are required:

```
DeepCharset.exe           # Main executable (~5 MB)
ini/                      # Config files (UI + languages)
  ├── ui.ini
  ├── codes.ini
  └── *.ini               # Language packs
README.md
RELEASE_NOTES.md
LICENSE
```

### Full Package

For developers / evaluators, add:

```
docs/                     # Technical documentation
Tests/                    # Test runners
CHANGELOG.md
bugfix.md                 # Bug fix history
```

### Installation

1. Extract to any directory
2. For GUI: double-click `DeepCharset.exe`
3. For CLI: `DeepCharset.exe --help`

---

## Known Limitations

- Detection sampling window: files larger than 4 MB sampled by first 4 MB only
- Mixed-encoding files not automatically split
- Safe-mode UI for low-confidence conversions still on v2.1.0 roadmap
- Async scanning / conversion currently disabled (v2.2.0 target)

---

## Version History (condensed)

- **v2.0.1** (2025-12-18) - Quality hotfix, 15 bugs fixed
- **v2.0.0beta** (2025-11-13) - Batch 14 release
- **v1.2.0** - Earlier development milestone

---

## Sign-off

- Build: ✅ Clean compilation, 0 errors, 0 W1057 warnings
- Testing: ✅ SelfTest suite passes; manual GUI + CLI verification complete
- Documentation: ✅ README rewritten, release notes aligned with bug fix history
- Repository hygiene: ✅ Temp artifacts purged, .gitignore updated
- Security: ✅ Path traversal, temp file predictability, large-file OOM all mitigated

**Approval**: Ready for distribution

Generated: 2025-12-18
