---
inclusion: always
---

# Delphi 13.1 全局规范 — DeepCharset

> 迁移总纲：`02Business/docs/delphi-13-migration/README.md`

## 环境

- **IDE**: Delphi 13.1 Florence (BDS 37.0)
- **入口脚本**: `02Business/scripts/env/delphi-13.1.bat`
- **回退脚本**: `02Business/scripts/env/delphi-12.3.bat`

所有 `build.bat` / `compile_*.bat` 首行必须 `call` 上述入口脚本。

## 目标平台

- Win64（主目标，`DeepCharset.dproj` 默认 Platform=Win64）

## 第三方组件

- **SynEdit** 13.1
- **VirtualTreeView** 13.1
- **Python4Delphi** 13.1
- **Skia4Delphi** 7.1.0（系统已注册）
- ~~madCollection~~ **不使用**（源码无 `madExcept` 实际引用，`madExcept.pas` 是空桩，`{.$DEFINE USE_MADEXCEPT}` 注释禁用）

## 分支与 tag

- 迁移分支：`upgrade/delphi-13`
- 回退 tag：`pre-d13-deepcharset`
- 完成 tag：`d13-deepcharset-done`
- Commit 前缀：`[d13]`

## JCL 说明

项目目录有大量 `Jcl*.pas`（`JclBOM.pas`、`JclFileUtils.pas` 等）。这些是**本地副本**，不依赖 JCL 包安装。13.1 下如有编译错误，优先改本地副本而不是升级 JCL 包。
