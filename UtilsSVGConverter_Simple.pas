unit UtilsSVGConverter_Simple;

interface

uses
  System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Imaging.pngimage,
  Vcl.Imaging.jpeg, Vcl.Imaging.GIFImg, System.Types, System.IOUtils,
  Vcl.Skia, System.UITypes, Winapi.Windows, Vcl.Forms, Vcl.Controls, 
  System.Skia;

type
  // 定义支持的图像格式枚举
  TSVGOutputFormat = (sofICO, sofPNG, sofJPG, sofBMP, sofGIF);
  
  // SVG转换类
  TSVGConverter = class
  private
    FSVGFilePath: string;
    FOutputPath: string;
    FWidth: Integer;
    FHeight: Integer;
    FFormat: TSVGOutputFormat;
    FOnProgress: TProc<string>;
    FOnError: TProc<string>;
    FOnSuccess: TProc<string>;
    
    function GetFormatExtension: string;
    function ConvertSVGToBitmap(const SourceFile: string): Vcl.Graphics.TBitmap;
  public
    constructor Create;
    destructor Destroy; override;
    
    // 执行转换
    function Convert: Boolean;
    
    // 获取支持的格式名称数组
    class function GetSupportedFormats: TArray<string>;
    
    // 属性
    property SVGFilePath: string read FSVGFilePath write FSVGFilePath;
    property OutputPath: string read FOutputPath write FOutputPath;
    property Width: Integer read FWidth write FWidth;
    property Height: Integer read FHeight write FHeight;
    property Format: TSVGOutputFormat read FFormat write FFormat;
    
    // 事件回调
    property OnProgress: TProc<string> read FOnProgress write FOnProgress;
    property OnError: TProc<string> read FOnError write FOnError;
    property OnSuccess: TProc<string> read FOnSuccess write FOnSuccess;
  end;

// 辅助函数 - 将SVG文件加载到组件中
procedure LoadSVGToComponent(const SVGFilePath: string; SVGControl: TSkSvg);

implementation

{ TSVGConverter }

constructor TSVGConverter.Create;
begin
  inherited Create;
  FWidth := 256;
  FHeight := 256;
  FFormat := sofPNG;
end;

destructor TSVGConverter.Destroy;
begin
  inherited;
end;

function TSVGConverter.GetFormatExtension: string;
begin
  case FFormat of
    sofICO: Result := '.ico';
    sofPNG: Result := '.png';
    sofJPG: Result := '.jpg';
    sofBMP: Result := '.bmp';
    sofGIF: Result := '.gif';
    else Result := '.png';
  end;
end;

function TSVGConverter.ConvertSVGToBitmap(const SourceFile: string): Vcl.Graphics.TBitmap;
var
  TempForm: TForm;
  SVGComponent: TSkSvg;
  OutputBitmap: Vcl.Graphics.TBitmap;
begin
  Result := nil;
  
  // 检查文件是否存在
  if not FileExists(SourceFile) then
  begin
    if Assigned(FOnError) then
      FOnError('SVG文件不存在: ' + SourceFile);
    Exit;
  end;
  
  OutputBitmap := Vcl.Graphics.TBitmap.Create;
  try
    OutputBitmap.Width := FWidth;
    OutputBitmap.Height := FHeight;
    OutputBitmap.PixelFormat := pf32bit;
    
    TempForm := TForm.Create(nil);
    try
      TempForm.Width := FWidth;
      TempForm.Height := FHeight;
      TempForm.BorderStyle := bsNone;
      TempForm.Position := poScreenCenter;
      
      SVGComponent := TSkSvg.Create(TempForm);
      try
        SVGComponent.Parent := TempForm;
        SVGComponent.Align := alClient;
        SVGComponent.Width := FWidth;
        SVGComponent.Height := FHeight;
        
        try
          // 读取SVG文件内容
          SVGComponent.Svg.Source.Data := TFile.ReadAllText(SourceFile);
        except
          on E: Exception do
          begin
            if Assigned(FOnError) then
              FOnError('读取SVG文件时出错: ' + E.Message);
            Exit;
          end;
        end;
        
        TempForm.Visible := True;
        try
          TempForm.PaintTo(OutputBitmap.Canvas.Handle, 0, 0);
          Result := OutputBitmap;
          OutputBitmap := nil; // 避免在finally中释放Result
        finally
          TempForm.Visible := False;
        end;
      finally
        SVGComponent.Free;
      end;
    finally
      TempForm.Free;
    end;
  finally
    if OutputBitmap <> nil then
      OutputBitmap.Free; // 如果转换失败，则释放位图
  end;
end;

function TSVGConverter.Convert: Boolean;
var
  SourceBitmap: Vcl.Graphics.TBitmap;
  PNGConverter: TPngImage;
  JPGConverter: TJPEGImage;
  FormatName: string;
  TempBitmap: Vcl.Graphics.TBitmap;
begin
  Result := False;
  
  // 检查文件是否存在
  if not FileExists(FSVGFilePath) then
  begin
    if Assigned(FOnError) then
      FOnError('SVG文件不存在: ' + FSVGFilePath);
    Exit;
  end;
  
  // 设置默认输出路径
  if FOutputPath = '' then
    FOutputPath := ChangeFileExt(FSVGFilePath, GetFormatExtension);
  
  // 确保输出目录存在
  ForceDirectories(ExtractFilePath(FOutputPath));
  
  // 获取格式名称用于日志
  case FFormat of
    sofICO: FormatName := 'ICO';
    sofPNG: FormatName := 'PNG';
    sofJPG: FormatName := 'JPG';
    sofBMP: FormatName := 'BMP';
    sofGIF: FormatName := 'GIF';
    else FormatName := 'PNG';
  end;
  
  if Assigned(FOnProgress) then
    FOnProgress('正在转换为' + FormatName + '格式...');
  
  try
    // 将SVG转换为位图
    SourceBitmap := ConvertSVGToBitmap(FSVGFilePath);
    
    if SourceBitmap = nil then
      Exit;
    
    try
      // 根据目标格式保存
      case FFormat of
        sofPNG:
          begin
            PNGConverter := TPngImage.Create;
            try
              PNGConverter.Assign(SourceBitmap);
              
              // 为PNG图像启用透明度
              if SourceBitmap.PixelFormat = pf32bit then
                PNGConverter.TransparencyMode := ptmPartial;
              
              PNGConverter.SaveToFile(FOutputPath);
              Result := True;
            finally
              PNGConverter.Free;
            end;
          end;
          
        sofJPG:
          begin
            JPGConverter := TJPEGImage.Create;
            try
              // JPEG不支持透明度，所以如果需要可以先转换位图格式
              if SourceBitmap.PixelFormat = pf32bit then
              begin
                TempBitmap := Vcl.Graphics.TBitmap.Create;
                try
                  TempBitmap.Assign(SourceBitmap);
                  TempBitmap.PixelFormat := pf24bit;
                  JPGConverter.Assign(TempBitmap);
                finally
                  TempBitmap.Free;
                end;
              end
              else
                JPGConverter.Assign(SourceBitmap);
                
              JPGConverter.CompressionQuality := 90; // 高质量
              JPGConverter.SaveToFile(FOutputPath);
              Result := True;
            finally
              JPGConverter.Free;
            end;
          end;
          
        sofBMP:
          begin
            SourceBitmap.SaveToFile(FOutputPath);
            Result := True;
          end;
          
        sofICO, sofGIF:
          begin
            // 对于ICO和GIF格式，我们暂时简化为PNG处理
            // 实际应用中应该使用专门的转换逻辑
            PNGConverter := TPngImage.Create;
            try
              PNGConverter.Assign(SourceBitmap);
              PNGConverter.SaveToFile(FOutputPath);
              Result := True;
              
              if Assigned(FOnProgress) then
                FOnProgress('注意: ' + FormatName + 
                  '格式转换简化处理，实际保存为PNG文件并更改扩展名。');
            finally
              PNGConverter.Free;
            end;
          end;
      end;
      
      if Result and Assigned(FOnSuccess) then
        FOnSuccess(FormatName + '文件已保存到: ' + FOutputPath);
    finally
      SourceBitmap.Free;
    end;
  except
    on E: Exception do
    begin
      if Assigned(FOnError) then
        FOnError('转换失败: ' + E.Message);
      Result := False;
    end;
  end;
end;

class function TSVGConverter.GetSupportedFormats: TArray<string>;
begin
  SetLength(Result, 5);
  Result[0] := 'ICO';
  Result[1] := 'PNG';
  Result[2] := 'JPG';
  Result[3] := 'BMP';
  Result[4] := 'GIF';
end;

// 辅助函数 - 将SVG文件加载到组件中
procedure LoadSVGToComponent(const SVGFilePath: string; SVGControl: TSkSvg);
begin
  if not FileExists(SVGFilePath) then
    Exit;
    
  if not Assigned(SVGControl) then
    Exit;
    
  try
    SVGControl.Svg.Source.Data := TFile.ReadAllText(SVGFilePath);
    SVGControl.Invalidate;
  except
    // 忽略加载错误
  end;
end;

end. 