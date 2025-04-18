object Form1: TForm1
  Left = 0
  Top = 0
  Caption = #32534#30721#26816#27979#27604#36739
  ClientHeight = 561
  ClientWidth = 784
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
    Width = 784
    Height = 41
    Align = alTop
    TabOrder = 0
    object btnSelectFolder: TButton
      Left = 16
      Top = 8
      Width = 121
      Height = 25
      Caption = #36873#25321#25991#20214#22841
      TabOrder = 0
      OnClick = btnSelectFolderClick
    end
    object btnDetect: TButton
      Left = 152
      Top = 8
      Width = 121
      Height = 25
      Caption = #24320#22987#26816#27979
      TabOrder = 1
      OnClick = btnDetectClick
    end
    object btnSaveResults: TButton
      Left = 288
      Top = 8
      Width = 121
      Height = 25
      Caption = #20445#23384#32467#26524
      TabOrder = 2
      OnClick = btnSaveResultsClick
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 41
    Width = 784
    Height = 520
    Align = alClient
    Caption = 'Panel2'
    TabOrder = 1
    object StringGrid1: TStringGrid
      Left = 1
      Top = 1
      Width = 782
      Height = 518
      Align = alClient
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goEditing]
      TabOrder = 0
    end
  end
end
