# Skia在Delphi中的使用问题总结

## 问题背景

在`UtilsSVGConverter`单元中实现SVG到其他图像格式的转换功能时，遇到了多个与Skia组件相关的编译错误。主要问题集中在SVG渲染和类型转换方面。

## 正确的单元引用

```pascal
// 正确的Skia单元引用
uses
  System.SysUtils, System.Classes, Vcl.Graphics, // 必须包含Vcl.Graphics
  System.Skia, Vcl.Skia;  // 而非 Skia, Skia.VCL
```

## 主要问题与解决方案

### 1. SVG渲染方法问题

#### 错误表现
```
[dcc64 Error] UtilsSVGConverter.pas(150): E2003 Undeclared identifier: 'RenderTo'
[dcc64 Error] UtilsSVGConverter.pas(153): E2003 Undeclared identifier: 'SVGDOM'
[dcc64 Error] UtilsSVGConverter.pas(151): E2003 Undeclared identifier: 'SetSize'
[dcc64 Error] UtilsSVGConverter.pas(152): E2003 Undeclared identifier: 'PixelFormat'
[dcc64 Error] UtilsSVGConverter.pas(153): E2003 Undeclared identifier: 'Canvas'
[dcc64 Error] UtilsSVGConverter.pas(156): E2003 Undeclared identifier: 'MakeFromBitmap'
[dcc64 Error] UtilsSVGConverter.pas(161): E2003 Undeclared identifier: 'Flush'
```

#### 问题分析
- 最初尝试使用匿名方法语法调用`TSkCanvas.RenderTo`导致编译错误（旧版Delphi可能不支持匿名方法）
- 使用了不存在的类型`TSkSvg`和属性`Source`
- 尝试使用不存在的方法如`TSkSvgBrush.DrawTo`、`TSkCanvas.MakeFromBitmap`
- 由于缺少`Vcl.Graphics`单元，导致`TBitmap`的`PixelFormat`、`Canvas`、`SetSize`属性未识别
- 不正确使用了`Flush`方法（ISkCanvas不需要手动调用`Flush`）

#### 解决方案1：使用`TSkSvg`类
使用`TSkSvg`类来加载和渲染SVG：

```pascal
procedure RenderSVGToBitmap(const FilePath: string; const Bitmap: TBitmap; const Width, Height: Integer);
var
  SVG: TSkSvg;
begin
  SVG := TSkSvg.Create(nil);
  try
    // 载入SVG文件内容
    SVG.Source := TFile.ReadAllText(FilePath);
    // 设置尺寸
    SVG.Width := Width;
    SVG.Height := Height;
    // 直接绘制到位图画布
    SVG.PaintTo(Bitmap.Canvas.Handle, 0, 0);
  finally
    SVG.Free;
  end;
end;
```

#### 解决方案2：使用`ISkSVGDOM`接口（Delphi XE8及以上版本推荐）
使用更现代的`ISkSVGDOM`接口加载和渲染SVG：

```pascal
procedure RenderSVGToBitmap(const FilePath: string; const Bitmap: TBitmap; const Width, Height: Integer);
var
  SVGDOM: ISkSVGDOM;
  Stream: TStream;
begin
  Stream := TFileStream.Create(FilePath, fmOpenRead or fmShareDenyWrite);
  try
    SVGDOM := TSkSVGDOM.MakeFromStream(Stream);
    SVGDOM.SetContainerSize(TSizeF.Create(Width, Height));

    Bitmap.Width := Width;  // 使用Width属性而非SetSize
    Bitmap.Height := Height; // 使用Height属性而非SetSize
    Bitmap.PixelFormat := pf32bit; // 确保支持alpha通道
    Bitmap.Canvas.Lock;
    try
      TSkCanvas.RenderTo(Bitmap.Canvas.Handle,
        procedure(const ACanvas: ISkCanvas)
        begin
          SVGDOM.Render(ACanvas);
        end);
    finally
      Bitmap.Canvas.Unlock;
    end;
  finally
    Stream.Free;
  end;
end;
```

#### 解决方案3：针对旧版Delphi的实现（不支持匿名方法）
如果使用的是不支持匿名方法的旧版Delphi，可以尝试以下替代方案：

```pascal
// 注意：这需要在实际环境中测试，仅为一种可能的解决方案
procedure RenderSVGToBitmap(const FilePath: string; const Bitmap: TBitmap; const Width, Height: Integer);
var
  SVGDOM: ISkSVGDOM;
  Stream: TStream;
  DC: HDC;
begin
  Stream := TFileStream.Create(FilePath, fmOpenRead or fmShareDenyWrite);
  try
    SVGDOM := TSkSVGDOM.MakeFromStream(Stream);
    SVGDOM.SetContainerSize(TSizeF.Create(Width, Height));

    Bitmap.Width := Width;
    Bitmap.Height := Height;
    Bitmap.PixelFormat := pf32bit;
    
    DC := Bitmap.Canvas.Handle;
    
    // 注意：这里需要找一种在旧版本Delphi中直接渲染的方法
    // 可能需要调用特定的API或使用其他方式
    // 具体实现取决于Skia库的版本和API兼容性
  finally
    Stream.Free;
  end;
end;
```

### 2. 类型不兼容问题

#### 错误表现
```
[dcc64 Error] UtilsSVGConverter.pas(223): E2010 Incompatible types: 'tagBITMAP' and 'TBitmap'
[dcc64 Error] UtilsSVGConverter.pas(308): E2010 Incompatible types: 'tagBITMAP' and 'TBitmap'
```

#### 问题分析
在图像格式转换中，直接将`TBitmap`对象传递给`TPngImage.Assign`等方法时出现类型不兼容错误。这表明混用了Windows API的`tagBITMAP`和VCL的`TBitmap`类型。

#### 解决方案
使用显式类型转换，将`TBitmap`转换为`TGraphic`：

```pascal
PngImage := TPngImage.Create;
try
  // 使用显式转换解决类型兼容问题
  PngImage.Assign(Bitmap as TGraphic);
  PngImage.SaveToFile(FOutputPath);
  Result := True;
finally
  PngImage.Free;
end;
```

### 3. Format属性冲突问题

#### 问题分析
`TSVGConverter`类中的`Format`属性与Delphi内置的`Format`函数名称冲突。

#### 解决方案
将属性名更改为`OutputFormat`：

```pascal
property OutputFormat: TSVGOutputFormat read FFormat write FFormat;
```

## 最佳实践

1. **正确使用单元**：确保使用`System.Skia`和`Vcl.Skia`而非其他变体

2. **包含必要的单元**：始终包含`Vcl.Graphics`以支持`TBitmap`操作

3. **类型转换**：在图像对象之间转换时使用显式类型转换

4. **避免与内置函数冲突**：不要使用与Delphi内置函数相同的标识符

5. **SVG渲染**：推荐使用`ISkSVGDOM`接口加载和渲染SVG

6. **异常处理**：在SVG渲染和文件操作中包含适当的异常处理

7. **画布操作**：使用`Canvas.Lock`/`Unlock`保护画布操作

8. **版本兼容性**：注意匿名方法语法在旧版Delphi中不受支持

## 保存位图为PNG文件的辅助函数

除了使用`TPngImage`进行转换外，还可以使用Skia原生方法将位图直接保存为PNG：

```pascal
procedure SaveBitmapAsPNG(const Bitmap: TBitmap; const OutputPath: string);
var
  SkImage: ISkImage;
  Data: ISkData;
begin
  SkImage := TSkImage.MakeFromBitmap(Bitmap);
  Data := SkImage.Encode(TSkEncodedImageFormat.PNG, 100);
  if Assigned(Data) then
    TFile.WriteAllBytes(OutputPath, Data.ToBytes);
end;
```

## SVG渲染最终推荐实现

```pascal
procedure RenderSVGToBitmap(const FilePath: string; const Bitmap: TBitmap; const Width, Height: Integer);
var
  SVGDOM: ISkSVGDOM;
  Stream: TStream;
begin
  Stream := TFileStream.Create(FilePath, fmOpenRead or fmShareDenyWrite);
  try
    SVGDOM := TSkSVGDOM.MakeFromStream(Stream);
    SVGDOM.SetContainerSize(TSizeF.Create(Width, Height));

    Bitmap.Width := Width;
    Bitmap.Height := Height;
    Bitmap.PixelFormat := pf32bit; // 确保支持alpha通道
    Bitmap.Canvas.Lock;
    try
      TSkCanvas.RenderTo(Bitmap.Canvas.Handle,
        procedure(const ACanvas: ISkCanvas)
        begin
          SVGDOM.Render(ACanvas);
        end);
    finally
      Bitmap.Canvas.Unlock;
    end;
  finally
    Stream.Free;
  end;
end;
``` 