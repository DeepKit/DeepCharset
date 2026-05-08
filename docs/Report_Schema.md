# DeepCharset 报告 Schema

## JSON 格式

数组，每个元素：

- file: string，文件路�?
- success: bool，是否成�?
- source: string，源编码（可能为空）
- target: string，目标编码（可能为空�?
- bytes: number，处理字节数
- error: string，可选，错误信息

示例�?
```json
[
  {"file":"C:/a.txt","success":true,"source":"GBK","target":"UTF-8","bytes":2048},
  {"file":"C:/b.txt","success":false,"source":"","target":"","bytes":0,"error":"无法读取源文�?}
]
```

## XML 格式

根节�?results，子节点 entry，属性：

- file
- success
- source
- target
- bytes
- error（可选）

示例�?
```xml
<?xml version="1.0" encoding="UTF-8"?>
<results>
  <entry file="C:/a.txt" success="true" source="GBK" target="UTF-8" bytes="2048" />
  <entry file="C:/b.txt" success="false" source="" target="" bytes="0" error="无法读取源文�? />
</results>
```