# 编码检测和转换算法移除计划

## 1. 需要移除的文件

- [ ] UtilsEncodingUTF8Detector.pas
- [ ] UtilsEncodingUTF8Validator.pas
- [ ] UtilsJCLEncoding.pas
- [ ] JclEncodingUtils.pas（如果不再需要）

## 2. 需要移除的代码

- [ ] ControllerEncoding.pas 中的编码检测和转换代码：
  - [ ] HasBOM 方法
  - [ ] ConvertWithJCL 方法
  - [ ] ConvertFileEncoding 方法
  - [ ] ConvertFilesByName 方法

- [ ] HelperFiles.pas 中的编码检测和转换代码：
  - [ ] DetectFileEncoding 方法
  - [ ] ConvertFile 方法
  - [ ] BatchConvert 方法

- [ ] ModelEncoding.pas 中的编码转换代码：
  - [ ] 保留编码信息结构体和常量定义
  - [ ] 移除与旧编码检测和转换相关的代码

## 3. 需要保留的文件和代码

- [√] ImprovedEncodingDetector.pas
- [√] ImprovedEncodingConverter.pas
- [√] ViewMainCode.pas 中的新编码检测和转换代码
- [√] ModelEncoding.pas 中的编码信息结构体和常量定义

## 4. 移除步骤

1. 备份所有将要修改的文件
2. 检查每个文件中的依赖关系，确保移除代码不会破坏其他功能
3. 修改 ControllerEncoding.pas 文件，移除旧的编码检测和转换代码
4. 修改 HelperFiles.pas 文件，移除旧的编码检测和转换代码
5. 修改 ModelEncoding.pas 文件，保留编码信息结构体和常量定义
6. 移除不再需要的文件
7. 更新项目文件，移除对已删除文件的引用
8. 编译项目，修复可能出现的错误
9. 测试基本功能，确保移除操作没有破坏现有功能
