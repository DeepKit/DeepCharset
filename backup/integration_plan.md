# 编码检测和转换算法集成计划

## 1. 修改项目文件

- [ ] 将 ImprovedEncodingDetector.pas 和 ImprovedEncodingConverter.pas 添加到项目中
- [ ] 确保项目引用了这两个新单元

## 2. 修改 ViewMainCode.pas

- [ ] 添加对 ImprovedEncodingDetector 和 ImprovedEncodingConverter 单元的引用
- [ ] 修改 TForm1 类中的 FImprovedEncodingDetector 和 FImprovedEncodingConverter 变量声明
- [ ] 修改 TForm1.Create 方法，正确初始化 FImprovedEncodingDetector 和 FImprovedEncodingConverter
- [ ] 修改 TForm1.Destroy 方法，正确释放 FImprovedEncodingDetector 和 FImprovedEncodingConverter

## 3. 替换编码检测功能

- [ ] 修改 DetectFileEncoding 方法，使用 ImprovedEncodingDetector 中的方法
- [ ] 修改 HasBOM 方法，使用 ImprovedEncodingDetector 中的方法
- [ ] 修改其他使用编码检测的方法，使用 ImprovedEncodingDetector 中的方法

## 4. 替换编码转换功能

- [ ] 修改 ConvertFileEncoding 方法，使用 ImprovedEncodingConverter 中的方法
- [ ] 修改 ConvertFilesByName 方法，使用 ImprovedEncodingConverter 中的方法
- [ ] 修改其他使用编码转换的方法，使用 ImprovedEncodingConverter 中的方法

## 5. 更新 UI 相关功能

- [ ] 修改 TreeViewEncodings 的初始化和更新方法，使用 ImprovedEncodingDetector 中的编码列表
- [ ] 修改编码选择相关的方法，使用 ImprovedEncodingDetector 中的方法
- [ ] 修改文件内容显示相关的方法，使用 ImprovedEncodingDetector 中的方法

## 6. 移除旧的编码检测和转换代码

- [ ] 移除 ControllerEncoding.pas 中的旧代码
- [ ] 移除其他不再需要的旧代码

## 7. 测试

- [ ] 测试编码检测功能
- [ ] 测试编码转换功能
- [ ] 测试 UI 相关功能
- [ ] 测试整体功能

## 8. 更新 better_progress.md

- [ ] 更新 better_progress.md 文件，记录集成进度
