object MemoForm: TMemoForm
  Left = 0
  Top = 0
  Caption = '文件查看器'
  ClientHeight = 750
  ClientWidth = 1400
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 15
  object Panel1: TPanel
    Left = 0
    Top = 709
    Width = 1400
    Height = 41
    Align = alBottom
    TabOrder = 0
    ExplicitTop = 285
    ExplicitWidth = 554
    object lblFileInfo: TLabel
      Left = 16
      Top = 14
      Width = 60
      Height = 15
      Caption = '文件信息'
    end
    object btnClose: TButton
      Left = 580
      Top = 10
      Width = 92
      Height = 25
      Caption = '关闭'
      TabOrder = 0
      OnClick = btnCloseClick
    end
  end
end