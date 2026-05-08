object SynEditForm: TSynEditForm
  Left = 0
  Top = 0
  Caption = '文件查看器'
  ClientHeight = 750
  ClientWidth = 1149
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnKeyDown = FormKeyDown
  OnResize = FormResize
  TextHeight = 15
  object PanelTop: TPanel
    Left = 0
    Top = 0
    Width = 1149
    Height = 33
    Align = alTop
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 0
    DesignSize = (
      1149
      33)
    object LabelFileName: TLabel
      Left = 10
      Top = 10
      Width = 48
      Height = 15
      Caption = '文件名: '
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object LabelEncoding: TLabel
      Left = 1010
      Top = 9
      Width = 32
      Height = 15
      Anchors = [akTop, akRight]
      Caption = '编码: '
    end
    object LabelFileSize: TLabel
      Left = 800
      Top = 9
      Width = 58
      Height = 15
      Anchors = [akTop, akRight]
      Caption = '文件大小: '
    end
  end
  object PanelButtons: TPanel
    Left = 0
    Top = 690
    Width = 1149
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 2
    DesignSize = (
      1149
      40)
    object btnClose: TButton
      Left = 1059
      Top = 5
      Width = 80
      Height = 30
      Anchors = [akTop, akRight]
      Caption = '关闭'
      TabOrder = 0
      OnClick = btnCloseClick
    end
    object btnCopy: TButton
      Left = 969
      Top = 5
      Width = 80
      Height = 30
      Anchors = [akTop, akRight]
      Caption = '复制'
      TabOrder = 1
      OnClick = btnCopyClick
    end
    object btnWordWrap: TButton
      Left = 869
      Top = 5
      Width = 90
      Height = 30
      Anchors = [akTop, akRight]
      Caption = '自动换行'
      TabOrder = 2
      OnClick = btnWordWrapClick
    end
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 730
    Width = 1149
    Height = 20
    Panels = <
      item
        Width = 200
      end
      item
        Width = 200
      end
      item
        Width = 200
      end>
  end
  object RichEdit1: TRichEdit
    Left = 0
    Top = 33
    Width = 1149
    Height = 657
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    PopupMenu = PopupMenu
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 1
    WordWrap = False
    OnChange = RichEdit1Change
    OnClick = RichEdit1Click
    OnKeyUp = RichEdit1KeyUp
  end
  object PopupMenu: TPopupMenu
    Left = 100
    Top = 100
    object MenuItemCopy: TMenuItem
      Caption = '复制'
      OnClick = MenuItemCopyClick
    end
    object MenuItemSelectAll: TMenuItem
      Caption = '全选'
      OnClick = MenuItemSelectAllClick
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object MenuItemWordWrap: TMenuItem
      Caption = '自动换行'
      OnClick = MenuItemWordWrapClick
    end
  end
end
