object SynEditForm: TSynEditForm
  Left = 0
  Top = 0
  Caption = #25991#20214#26597#30475#22120
  ClientHeight = 500
  ClientWidth = 700
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  TextHeight = 15
  object Memo1: TMemo
    Left = 0
    Top = 0
    Width = 700
    Height = 460
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object Panel1: TPanel
    Left = 0
    Top = 460
    Width = 700
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object lblFileName: TLabel
      Left = 8
      Top = 12
      Width = 257
      Height = 15
      AutoSize = False
      Caption = '#25991#20214:'
    end
    object lblEncoding: TLabel
      Left = 264
      Top = 12
      Width = 257
      Height = 15
      AutoSize = False
      Caption = '#32534#30721:'
    end
    object lblBOM: TLabel
      Left = 520
      Top = 12
      Width = 177
      Height = 15
      AutoSize = False
      Caption = 'BOM:'
    end
  end
end
