object Form2: TForm2
  Left = 0
  Top = 0
  Caption = '文件内容查看器'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 15
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 624
    Height = 41
    Align = alTop
    TabOrder = 0
    ExplicitLeft = 72
    ExplicitTop = 32
    ExplicitWidth = 185
    object lblFileInfo: TLabel
      Left = 16
      Top = 14
      Width = 465
      Height = 15
      AutoSize = False
      Caption = '文件信息'
    end
    object btnClose: TButton
      Left = 520
      Top = 9
      Width = 89
      Height = 25
      Caption = '关闭'
      TabOrder = 0
      OnClick = btnCloseClick
    end
  end
  object SynEdit1: TSynEdit
    Left = 0
    Top = 41
    Width = 624
    Height = 400
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -20
    Font.Name = 'Consolas'
    Font.Style = []
    Font.Quality = fqClearTypeNatural
    TabOrder = 1
    UseCodeFolding = False
    Gutter.Font.Charset = DEFAULT_CHARSET
    Gutter.Font.Color = clWindowText
    Gutter.Font.Height = -16
    Gutter.Font.Name = 'Consolas'
    Gutter.Font.Style = []
    Gutter.Bands = <
      item
        Kind = gbkMarks
        Width = 13
      end
      item
        Kind = gbkLineNumbers
      end
      item
        Kind = gbkFold
      end
      item
        Kind = gbkTrackChanges
      end
      item
        Kind = gbkMargin
        Width = 3
      end>
    Lines.Strings = (
      'SynEdit1')
    SelectedColor.Alpha = 0.400000005960464500
    ExplicitLeft = 8
    ExplicitTop = 64
    ExplicitWidth = 200
    ExplicitHeight = 150
  end
end
