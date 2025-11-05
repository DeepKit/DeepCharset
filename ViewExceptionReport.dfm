object ExceptionReportForm: TExceptionReportForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #24322#24120#25253#21578
  ClientHeight = 500
  ClientWidth = 700
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object PanelTop: TPanel
    Left = 0
    Top = 0
    Width = 700
    Height = 65
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object LabelTitle: TLabel
      Left = 16
      Top = 16
      Width = 225
      Height = 16
      Caption = #31243#24207#21457#29983#20102#19968#20010#26410#22788#29702#30340#24322#24120
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object ImageIcon: TImage
      Left = 656
      Top = 8
      Width = 32
      Height = 32
      Stretch = True
    end
  end
  object PanelBottom: TPanel
    Left = 0
    Top = 459
    Width = 700
    Height = 41
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnClose: TButton
      Left = 608
      Top = 8
      Width = 75
      Height = 25
      Caption = #20851#38381
      TabOrder = 0
      OnClick = btnCloseClick
    end
    object btnCopyToClipboard: TButton
      Left = 440
      Top = 8
      Width = 120
      Height = 25
      Caption = #22797#21046#21040#21098#36148#26495
      TabOrder = 1
      OnClick = btnCopyToClipboardClick
    end
    object btnSaveToFile: TButton
      Left = 304
      Top = 8
      Width = 120
      Height = 25
      Caption = #20445#23384#21040#25991#20214'...'
      TabOrder = 2
      OnClick = btnSaveToFileClick
    end
  end
  object PanelCenter: TPanel
    Left = 0
    Top = 65
    Width = 700
    Height = 394
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object PageControl1: TPageControl
      Left = 0
      Top = 0
      Width = 700
      Height = 394
      ActivePage = TabSheetException
      Align = alClient
      TabOrder = 0
      object TabSheetException: TTabSheet
        Caption = #24322#24120#20449#24687
        object MemoException: TMemo
          Left = 0
          Top = 0
          Width = 692
          Height = 366
          Align = alClient
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Courier New'
          Font.Style = []
          ParentFont = False
          ReadOnly = True
          ScrollBars = ssVertical
          TabOrder = 0
        end
      end
      object TabSheetStackTrace: TTabSheet
        Caption = #35843#29992#26632
        ImageIndex = 1
        object MemoStackTrace: TMemo
          Left = 0
          Top = 0
          Width = 692
          Height = 366
          Align = alClient
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Courier New'
          Font.Style = []
          ParentFont = False
          ReadOnly = True
          ScrollBars = ssVertical
          TabOrder = 0
        end
      end
      object TabSheetSystem: TTabSheet
        Caption = #31995#32479#20449#24687
        ImageIndex = 2
        object MemoSystemInfo: TMemo
          Left = 0
          Top = 0
          Width = 692
          Height = 366
          Align = alClient
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Courier New'
          Font.Style = []
          ParentFont = False
          ReadOnly = True
          ScrollBars = ssVertical
          TabOrder = 0
        end
      end
    end
  end
  object MemoDetails: TMemo
    Left = 312
    Top = 184
    Width = 185
    Height = 89
    Lines.Strings = (
      'MemoDetails')
    TabOrder = 3
    Visible = False
  end
  object SaveDialog1: TSaveDialog
    DefaultExt = 'txt'
    Filter = #25991#26412#25991#20214' (*.txt)|*.txt|'#26085#24535#25991#20214' (*.log)|*.log|'#25152#26377#25991#20214' (*.*)|*.*'
    Left = 24
    Top = 416
  end
end
