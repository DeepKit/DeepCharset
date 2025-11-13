# 检测与批处理参数设置（UI）

本说明描述 UI 中后台“编码检测器”的可调参数，以及推荐取值。

- 配置文件：`ini/ui.ini`
- 配置节：`[Detection]`

可用键：
- `BatchSize`（整数，默认 64，范围 1–1024）
  - 单次批量检测的最大条目数。批越大，UI 刷新频率越低；批越小，首屏反馈更快。
- `FlushIntervalMS`（整数，默认 200，范围 20–5000）
  - 批量最久刷新间隔（毫秒）。超过此间隔，即使批未满也会投递一次。

示例：
```
[Detection]
BatchSize=64
FlushIntervalMS=200
```

调优建议：
- 小目录/更快反馈：BatchSize=16~32，FlushIntervalMS=100~150
- 大目录/减少主线程压力：BatchSize=64~128，FlushIntervalMS=200~400
- 如发现“...（编码占位）”显示停留较久，可适当减小 BatchSize 或 FlushIntervalMS。
