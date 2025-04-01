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
    Top = 803
    Width = 690
    Height = 41
    Align = alBottom
    TabOrder = 0
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
    end
  end
end
