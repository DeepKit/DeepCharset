unit SvgToIcoConverter;

interface

uses
  System.SysUtils, System.Classes, System.Types, System.IOUtils,
  Vcl.Graphics, Vcl.Imaging.pngimage,
  Skia, Skia.Vcl, Skia.Canvas,
  Skia4Delphi.BaseTypes, Skia4Delphi.Api,
  Skia.Api;

type
  TSvgToIcoConverter = class
  private
    FSvgFilePath: string;
    FIcoFilePath: string;
    FIconSizes: TList<TSize>;
    
    function GetDefaultIcoFilePath: string;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure AddIconSize(const Width, Height: Integer);
    procedure ClearIconSizes;
    
    function Convert: Boolean;
    function SaveToFile(const FileName: string): Boolean;
    
    property SvgFilePath: string read FSvgFilePath write FSvgFilePath;
    property IcoFilePath: string read FIcoFilePath write FIcoFilePath;
  end;

implementation

{ TSvgToIcoConverter }

constructor TSvgToIcoConverter.Create;
begin
  inherited Create;
  FIconSizes := TList<TSize>.Create;
  
  // 添加默认图标尺寸
  AddIconSize(16, 16);
  AddIconSize(32, 32);
  AddIconSize(48, 48);
  AddIconSize(64, 64);
end;

destructor TSvgToIcoConverter.Destroy;
begin
  FIconSizes.Free;
  inherited;
end;

procedure TSvgToIcoConverter.AddIconSize(const Width, Height: Integer);
var
  Size: TSize;
begin
  Size.Width := Width;
  Size.Height := Height;
  if FIconSizes.IndexOf(Size) = -1 then
    FIconSizes.Add(Size);
end;

procedure TSvgToIcoConverter.ClearIconSizes;
begin
  FIconSizes.Clear;
end;

function TSvgToIcoConverter.GetDefaultIcoFilePath: string;
begin
  if FSvgFilePath <> '' then
    Result := ChangeFileExt(FSvgFilePath, '.ico')
  else
    Result := '';
end;

function TSvgToIcoConverter.Convert: Boolean;
begin
  Result := False;
  
  if FSvgFilePath = '' then
    raise Exception.Create('SVG文件路径未指定');
    
  if not FileExists(FSvgFilePath) then
    raise Exception.Create('SVG文件不存在：' + FSvgFilePath);
    
  if FIconSizes.Count = 0 then
    raise Exception.Create('图标尺寸列表为空');
  
  if FIcoFilePath = '' then
    FIcoFilePath := GetDefaultIcoFilePath;
    
  Result := SaveToFile(FIcoFilePath);
end;

function TSvgToIcoConverter.SaveToFile(const FileName: string): Boolean;
var
  Stream: TMemoryStream;
  IconCount: Word;
  IconDir: array of TIconDirEntry;
  IconDirHeader: TIconDir;
  I, DataOffset: Integer;
  IconImage: TSkBitmap;
  SvgBrush: TSkSvgBrush;
  Size: TSize;
  IconImageSize: Integer;
  PNG: TPngImage;
begin
  Result := False;
  Stream := TMemoryStream.Create;
  try
    IconCount := FIconSizes.Count;
    
    // 设置图标目录头
    FillChar(IconDirHeader, SizeOf(IconDirHeader), 0);
    IconDirHeader.idReserved := 0;
    IconDirHeader.idType := 1;
    IconDirHeader.idCount := IconCount;
    Stream.Write(IconDirHeader, SizeOf(IconDirHeader));
    
    // 设置图标目录项
    SetLength(IconDir, IconCount);
    DataOffset := SizeOf(IconDirHeader) + IconCount * SizeOf(TIconDirEntry);
    
    // 创建SVG画笔
    SvgBrush := TSkSvgBrush.Create;
    try
      SvgBrush.Source := TFile.ReadAllText(FSvgFilePath);
      
      // 处理每个图标尺寸
      for I := 0 to IconCount - 1 do
      begin
        Size := FIconSizes[I];
        
        // 创建位图并绘制SVG
        IconImage := TSkBitmap.Create(Size.Width, Size.Height);
        try
          IconImage.Canvas.Clear(TAlphaColors.Transparent);
          
          // 绘制SVG到位图上
          SvgBrush.Render(IconImage.Canvas, RectF(0, 0, Size.Width, Size.Height));
          
          // 保存为PNG格式
          PNG := TPngImage.Create;
          try
            IconImage.ToRaster.AssignToPng(PNG);
            
            // 保存PNG数据到内存流
            IconImageSize := Stream.Position;
            PNG.SaveToStream(Stream);
            IconImageSize := Stream.Position - IconImageSize;
            
            // 填写图标目录项
            IconDir[I].bWidth := Byte(Size.Width);
            IconDir[I].bHeight := Byte(Size.Height);
            IconDir[I].bColorCount := 0;
            IconDir[I].bReserved := 0;
            IconDir[I].wPlanes := 1;
            IconDir[I].wBitCount := 32;
            IconDir[I].dwBytesInRes := IconImageSize;
            IconDir[I].dwImageOffset := DataOffset;
            
            // 更新下一个图标的数据偏移量
            DataOffset := DataOffset + IconImageSize;
          finally
            PNG.Free;
          end;
        finally
          IconImage.Free;
        end;
      end;
      
      // 写入图标目录项
      Stream.Position := SizeOf(IconDirHeader);
      for I := 0 to IconCount - 1 do
        Stream.Write(IconDir[I], SizeOf(TIconDirEntry));
      
      // 保存到文件
      Stream.SaveToFile(FileName);
      Result := True;
    finally
      SvgBrush.Free;
    end;
  finally
    Stream.Free;
  end;
end;

end. 