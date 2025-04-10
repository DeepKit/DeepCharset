# 转码软件国际化增强方案

## 需求背景

TransSuccess软件已实现基本的转码功能，当前支持8种语言界面（简体中文、英语、日语、韩语、西班牙语、法语、德语、意大利语）。新增需求要求增加8种语言支持，包括繁体中文在内。

## 当前国际化实现分析

### 现有实现方式
当前的国际化实现采用了以下方式：
1. 使用`TLanguageStrings`记录类型存储UI界面字符串
2. 使用`TAppLanguage`枚举类型定义支持的语言
3. 通过`GetLanguageStringsByLang`方法基于语言类型返回对应的字符串集
4. 所有字符串硬编码在源代码中
5. 通过RadioGroup控件提供用户语言选择界面

### 存在的限制
1. **硬编码字符串**：所有语言字符串直接写入代码，维护和扩展困难
2. **有限的可扩展性**：增加新语言需要修改源代码并重新编译
3. **资源利用不足**：未利用Delphi的资源机制或外部配置文件
4. **界面控件限制**：当前RadioGroup设计不利于支持更多语言选项
5. **缺少繁体中文编码支持**：编码列表中缺少Big5-HKSCS等繁体中文特有编码

## 国际化增强方案

### 1. 外部化语言资源

**方案设计**：将语言字符串从代码中分离，移至外部资源文件
- 创建语言资源文件夹 `languages`
- 每种语言一个独立的INI文件（如`zh-CN.ini`, `zh-TW.ini`）
- 使用UTF-8编码存储所有语言文件
- 采用以下结构设计INI文件：

```ini
[Meta]
LanguageName=繁體中文
LanguageCode=zh-TW
Version=1.0

[Strings]
WindowTitle=UTF-8 BOM 編碼轉換工具
BtnConvert=全部轉換
BtnSingleFile=單個文件
BtnRefresh=刷新
BtnClose=關閉
; ...其他字符串
```

**优势**：
- 无需重新编译即可添加新语言
- 可由翻译人员独立编辑语言文件
- 支持动态更新语言包

### 2. 语言管理模块设计

**方案设计**：创建专用的语言管理器类处理语言加载和切换

```delphi
// HelperLanguage.pas
unit HelperLanguage;

interface

uses
  System.SysUtils, System.Classes, System.IniFiles, System.Generics.Collections;

type
  TOnLanguageChangeEvent = procedure(const LangCode: string) of object;
  
  TLanguageInfo = record
    Code: string;         // 语言代码 (zh-CN, zh-TW, en-US...)
    Name: string;         // 显示名称 (简体中文, 繁體中文, English...)
    FileName: string;     // 资源文件名
  end;

  TLanguageManager = class
  private
    FCurrentLanguage: string;
    FLanguages: TDictionary<string, TLanguageStrings>;
    FLanguageInfoList: TList<TLanguageInfo>;
    FOnLanguageChange: TOnLanguageChangeEvent;
    
    function LoadFromFile(const FileName: string): TLanguageStrings;
    procedure SaveUserPreference(const LangCode: string);
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure LoadAvailableLanguages;
    function GetLanguageList: TArray<TLanguageInfo>;
    function GetLanguageStrings(const LangCode: string): TLanguageStrings;
    procedure SetLanguage(const LangCode: string);
    function GetSystemLanguage: string;
    
    property CurrentLanguage: string read FCurrentLanguage;
    property OnLanguageChange: TOnLanguageChangeEvent read FOnLanguageChange write FOnLanguageChange;
  end;
  
var
  LanguageManager: TLanguageManager;
  
implementation

// ...实现代码
end.
```

### 3. 新增支持的语言

将增加以下8种语言支持:

1. **繁体中文 (zh-TW)** - 主要为台湾、香港和澳门用户
2. **俄语 (ru-RU)** - 覆盖俄罗斯及周边国家
3. **葡萄牙语 (pt-BR)** - 服务巴西及葡萄牙用户
4. **阿拉伯语 (ar-SA)** - 右至左阅读布局支持
5. **荷兰语 (nl-NL)** - 服务荷兰及比利时部分地区
6. **泰语 (th-TH)** - 支持泰国市场
7. **越南语 (vi-VN)** - 服务越南用户
8. **波兰语 (pl-PL)** - 覆盖东欧市场

### 4. 界面优化设计

**方案设计**：重新设计语言选择界面
- 替换RadioGroup为下拉列表（ComboBox）
- 考虑添加国旗图标
- 布局优化：

```delphi
procedure TForm1.CreateLanguageSelector;
begin
  // 创建语言选择下拉框
  cmbLanguage := TComboBox.Create(Self);
  cmbLanguage.Parent := Panel1;
  cmbLanguage.Style := csDropDownList;
  cmbLanguage.Width := 150;
  cmbLanguage.OnChange := cmbLanguageChange;
  
  // 填充语言列表
  for var LangInfo in LanguageManager.GetLanguageList do
    cmbLanguage.Items.AddObject(LangInfo.Name, TObject(LangInfo.Code));
  
  // 设置当前语言
  var Index := cmbLanguage.Items.IndexOf(LanguageManager.CurrentLanguage);
  if Index >= 0 then
    cmbLanguage.ItemIndex := Index;
end;
```

### 5. 编码支持扩展

**方案设计**：针对新增语言扩展编码支持

```delphi
// 在初始化编码列表时添加对应语言编码
procedure TForm1.InitEncodingList;
begin
  // ...现有代码
  
  // 繁体中文编码支持
  AddEncodingGroup('繁体中文');
  AddEncodingOption('繁体中文(Big5)', 'big5', 950, False);
  AddEncodingOption('繁体中文(Big5-HKSCS)', 'big5-hkscs', 951, False);
  
  // 俄语编码支持
  AddEncodingOption('俄语(KOI8-R)', 'koi8-r', 20866, False);
  AddEncodingOption('俄语(CP-1251)', 'windows-1251', 1251, False);
  
  // 泰语编码支持
  AddEncodingOption('泰语(TIS-620)', 'tis-620', 874, False);
  
  // 越南语编码支持
  AddEncodingOption('越南语(Windows-1258)', 'windows-1258', 1258, False);
  
  // 阿拉伯语编码支持
  AddEncodingOption('阿拉伯语(Windows-1256)', 'windows-1256', 1256, False);
end;
```

### 6. 配置项与持久化

**方案设计**：保存用户语言偏好设置
- 创建配置文件 `config.ini`
- 存储用户语言设置
- 启动时加载上次使用的语言设置

```ini
[Settings]
Language=zh-TW
```

### 7. 实现步骤

1. **阶段一：基础框架重构**
   - 创建语言管理器类
   - 实现INI文件语言资源加载
   - 设计语言切换机制
   - 开发测试版本

2. **阶段二：多语言资源开发**
   - 提取现有8种语言字符串至INI文件
   - 翻译新增8种语言资源
   - 进行本地化测试和校对

3. **阶段三：界面优化与编码支持**
   - 重构语言选择界面
   - 添加新语言对应的编码支持
   - 实现用户语言偏好持久化
   - 系统语言自动检测

4. **阶段四：测试与发布**
   - 多语言环境测试
   - 边界情况测试
   - 用户体验优化
   - 发布新版本

## 风险评估与解决方案

1. **右至左语言(RTL)支持**
   - 风险：阿拉伯语需要右至左布局支持
   - 解决：使用BiDiMode属性调整控件布局方向

2. **字体显示问题**
   - 风险：某些语言字符可能无法正确显示
   - 解决：使用兼容性更好的字体，如Arial Unicode MS

3. **资源文件编码**
   - 风险：INI文件读取可能存在编码问题
   - 解决：统一使用UTF-8编码并使用TMemIniFile加载

4. **性能考虑**
   - 风险：外部资源加载可能影响启动性能
   - 解决：实现资源缓存机制，仅在需要时加载

## 总结

此国际化方案通过外部化语言资源、构建专用语言管理器、优化界面设计，将实现对8种新语言的支持，同时提高软件的可维护性和用户体验。采用模块化设计，使未来扩展语言支持变得简单高效。

# 开发文档：需求变更记录

## libiconv库集成需求

### 2024-05-15：初始需求
- 需要集成libiconv库，以支持更多的编码转换功能
- 需要支持不同平台（32位和64位）
- 需要能够检测并处理文件编码，特别是亚洲语言编码（GB2312、Big5等）

### 2024-05-20：需求调整
- 需要在UtilsIconv单元中处理动态加载libiconv库
- 32位和64位版本需要分别处理，函数名可能不同
- 64位版本中函数名前缀为"libiconv_"，而32位版本中函数名无前缀

### 2024-06-01：全面转向ICU库
- 决定全面转向使用ICU库替代libiconv，以获得更强大的国际化支持
- ICU库提供更完整的Unicode支持和编码转换功能
- ICU支持更多的编码格式和更准确的编码检测
- 提供更丰富的国际化API，包括区域设置、日期时间格式化等

## ICU集成实施方案

### 1. 架构变更
- 创建UtilsICU单元，提供ICU库的Delphi接口
- 删除UtilsIconv相关代码，全面转向ICU
- 重构ControllerEncoding单元，使用ICU提供的功能
- 保持公共API不变，确保应用程序其他部分不受影响

### 2. 核心功能迁移
- **编码检测**：使用ICU的ucsdet模块替代iconv的检测
- **编码转换**：使用ucnv转换函数替代iconv_convert
- **BOM处理**：统一BOM添加/检测逻辑

### 3. 新增功能
- 更准确的编码检测：ICU提供更高的检测准确率
- 更好的多语言支持：ICU原生支持几乎所有常见编码
- 更完善的错误处理：提供更详细的错误信息

### 4. 兼容性处理
- 创建setup.bat脚本，用于下载并安装ICU库
- 确保32位和64位环境都能正常运行
- 保持对旧数据的兼容性，确保已有文件能正确识别编码

## 性能优化计划

### 1. 内存使用优化
- 采用流式处理大文件，避免一次性加载大文件到内存
- 重用转换器对象，避免频繁创建销毁
- 优化内部缓冲区管理，减少内存碎片

### 2. 速度优化
- 使用ICU的更高效算法，提高编码检测和转换速度
- 并行处理多文件转换
- 增加缓存机制，避免重复检测相似文件

### 3. 用户体验提升
- 添加转换进度显示
- 提供更详细的日志信息
- 允许用户自定义转换参数

## 实施进度规划
1. 完成ICU库集成基础架构 - 2024-06-10
2. 完成核心功能迁移 - 2024-06-20
3. 实现新增功能 - 2024-06-30
4. 完成性能优化 - 2024-07-10
5. 进行全面测试和修复 - 2024-07-20
6. 发布新版本 - 2024-07-30

## SynEdit组件集成需求

### 2024-05-30：组件修改
- 需要解决SynEdit组件的编译问题
- 创建一个包装类来处理SynEdit组件的不兼容问题
- 确保ViewSynEdit能够正确使用包装类 