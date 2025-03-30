object Form2: TForm2
  Left = 0
  Top = 0
  Caption = #25991#20214#20869#23481#26597#30475#22120
  ClientHeight = 844
  ClientWidth = 690
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 690
    Height = 41
    Align = alTop
    TabOrder = 0
    ExplicitWidth = 1191
    DesignSize = (
      690
      41)
    object lblFileInfo: TLabel
      Left = 16
      Top = 14
      Width = 465
      Height = 15
      AutoSize = False
      Caption = #25991#20214#20449#24687
    end
    object btnClose: TButton
      Left = 579
      Top = 10
      Width = 89
      Height = 25
      Anchors = [akTop, akRight]
      Caption = #20851#38381
      TabOrder = 0
      OnClick = btnCloseClick
      ExplicitLeft = 1080
    end
  end
  object SynEdit1: TSynEdit
    Left = 0
    Top = 41
    Width = 690
    Height = 803
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Consolas'
    Font.Style = []
    Font.Quality = fqClearTypeNatural
    TabOrder = 1
    UseCodeFolding = False
    Gutter.Font.Charset = DEFAULT_CHARSET
    Gutter.Font.Color = clWindowText
    Gutter.Font.Height = -11
    Gutter.Font.Name = 'Courier New'
    Gutter.Font.Style = []
    Gutter.Font.Quality = fqClearTypeNatural
    Gutter.ShowLineNumbers = True
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
      '')
    Options = [eoAutoIndent, eoDragDropEditing, eoEnhanceEndKey, eoGroupUndo, eoScrollPastEol, eoShowScrollHint, eoSmartTabDelete, eoTabIndent, eoTabsToSpaces]
    SelectedColor.Alpha = 0.400000005960464500
    TabWidth = 2
    ExplicitWidth = 1191
  end
end
