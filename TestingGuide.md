# TransSuccess 测试指南

## 概述

本文档提供了 TransSuccess 项目的测试指南，包括如何运行单元测试、解释测试结果以及如何添加新的测试。

## 测试架构

TransSuccess 使用 DUnitX 测试框架进行单元测试。测试项目包含以下文件：

- `TestTransSuccess.dpr` - 测试项目主文件
- `TestEncodingController.pas` - 编码控制器的单元测试
- `TestFileGenerator.pas` - 用于生成各种编码的测试文件
- `RunTests.bat` - 用于编译和运行测试的批处理脚本

## 运行测试

### 方法 1：使用批处理脚本

1. 双击 `RunTests.bat` 文件
2. 脚本将自动编译测试项目并运行测试
3. 测试结果将显示在控制台窗口中

### 方法 2：在 Delphi IDE 中运行

1. 在 Delphi IDE 中打开 `TestTransSuccess.dpr` 项目
2. 按 F9 运行项目
3. 测试结果将显示在控制台窗口中

## 测试结果解释

测试运行完成后，将显示以下信息：

```
测试运行完成
总测试数: X
通过: Y
失败: Z
错误: W
忽略: V
```

- **总测试数**：运行的测试用例总数
- **通过**：成功通过的测试用例数
- **失败**：断言失败的测试用例数
- **错误**：执行过程中发生异常的测试用例数
- **忽略**：被标记为忽略的测试用例数

如果有任何测试失败或出错，将显示详细信息，包括失败的测试名称、失败的断言以及相关的错误消息。

## 测试覆盖范围

当前的测试套件覆盖以下功能：

1. **编码检测**
   - UTF-8 带 BOM
   - UTF-8 不带 BOM
   - ANSI
   - UTF-16 LE
   - UTF-16 BE
   - GB2312

2. **编码转换**
   - ANSI 到 UTF-8 带 BOM
   - UTF-8 不带 BOM 到 UTF-8 带 BOM
   - UTF-8 带 BOM 到 ANSI
   - 批量文件转换

3. **错误处理**
   - 不存在的文件
   - 无效的编码名称

## 添加新测试

要添加新的测试用例，请按照以下步骤操作：

1. 在 `TestEncodingController.pas` 文件中的 `TEncodingControllerTests` 类中添加新的测试方法
2. 使用 `[Test]` 属性标记该方法
3. 实现测试逻辑，包括准备、执行和验证步骤
4. 使用 `Assert` 类的方法验证预期结果

示例：

```pascal
[Test]
procedure TestNewFeature;
begin
  // 准备
  // ...

  // 执行
  // ...

  // 验证
  Assert.IsTrue(Result, '预期结果应为真');
  Assert.AreEqual(Expected, Actual, '预期值应等于实际值');
end;
```

## 测试文件生成

`TestFileGenerator` 类提供了生成各种编码测试文件的方法。如果需要生成特定编码的测试文件，可以使用以下方法：

```pascal
TTestFileGenerator.GenerateUTF8WithBOMFile(FilePath, Content);
TTestFileGenerator.GenerateUTF8WithoutBOMFile(FilePath, Content);
TTestFileGenerator.GenerateANSIFile(FilePath, Content);
TTestFileGenerator.GenerateUTF16LEFile(FilePath, Content);
TTestFileGenerator.GenerateUTF16BEFile(FilePath, Content);
TTestFileGenerator.GenerateGB2312File(FilePath, Content);
```

## 故障排除

如果测试运行失败，请检查以下几点：

1. 确保已安装 DUnitX 测试框架
2. 确保所有依赖的单元都可用
3. 检查测试文件目录是否有写入权限
4. 查看详细的错误消息以确定失败的原因

如果测试编译失败，请检查：

1. 编译器路径是否正确设置
2. 项目依赖关系是否正确
3. 是否有语法错误或缺少单元
