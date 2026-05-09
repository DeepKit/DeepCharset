---
inclusion: manual
---

# DeepCharset 迁移检查清单（手动引用）

## 阶段 0
- [ ] DeepBase 阶段 1 完成
- [ ] SynEdit / VTV / P4D 13.1 就绪
- [x] madCollection 决策（不使用）
- [x] `pre-d13-deepcharset` tag
- [x] `upgrade/delphi-13` 分支
- [x] `.dproj` 备份

## 阶段 1
- [x] build 脚本切到 `delphi-13.1.bat`
- [x] `MADPATHS` 清除
- [ ] 13.1 IDE 升级 dproj
- [ ] Search Path 无 23.0 残留

## 阶段 2
- [ ] Clean + Build
- [x] madCollection 迁移（不适用）
- [ ] SynEdit/VTV/P4D API 修复
- [ ] Skia 路径确认（已验证 unit 名未变）

## 阶段 3
- [x] 语法现代化样板（ModelConfig.pas）

## 阶段 4
- [ ] 冒烟测试：检测 UTF-8/GBK/Shift-JIS/EUC-KR 各一文件
- [ ] Warning ≤ 基线
- [ ] 合并分支，打 `d13-deepcharset-done`
