object Form1: TForm1
  Left = 0
  Top = 0
  Caption = #25991#20214#36716#25442#24037#20855
  ClientHeight = 587
  ClientWidth = 961
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 15
  object Splitter1: TSplitter
    Left = 0
    Top = 41
    Width = 961
    Height = 3
    Cursor = crVSplit
    Align = alTop
    ExplicitLeft = 1
    ExplicitTop = 1
    ExplicitWidth = 113
  end
  object Splitter2: TSplitter
    Left = 0
    Top = 469
    Width = 961
    Height = 3
    Cursor = crVSplit
    Align = alBottom
    ExplicitTop = 49
  end
  object Splitter3: TSplitter
    Left = 225
    Top = 44
    Height = 425
    ExplicitLeft = 0
    ExplicitHeight = 961
  end
  object Splitter4: TSplitter
    Left = 741
    Top = 44
    Height = 425
    Align = alRight
    ExplicitLeft = 778
    ExplicitTop = 47
  end
  object Panel1: TPanel
    Left = 0
    Top = 472
    Width = 961
    Height = 115
    Align = alBottom
    TabOrder = 0
    ExplicitTop = 455
    ExplicitWidth = 955
    object Splitter7: TSplitter
      Left = 738
      Top = 1
      Height = 113
      Align = alRight
      ExplicitLeft = 778
      ExplicitTop = 47
    end
    object Splitter8: TSplitter
      Left = 1
      Top = 1
      Height = 113
      ExplicitLeft = 778
      ExplicitTop = 47
    end
    object Panel6: TPanel
      Left = 741
      Top = 1
      Width = 219
      Height = 113
      Align = alRight
      TabOrder = 0
      Visible = False
      ExplicitLeft = 735
    end
    object MemLog: TMemo
      Left = 4
      Top = 1
      Width = 734
      Height = 113
      Align = alClient
      Lines.Strings = (
        'MemLog')
      TabOrder = 1
      ExplicitWidth = 728
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 961
    Height = 41
    Align = alTop
    TabOrder = 1
    ExplicitWidth = 955
    DesignSize = (
      961
      41)
    object Label1: TLabel
      Left = 520
      Top = 8
      Width = 3
      Height = 15
    end
    object ComboBox1: TComboBox
      Left = 11
      Top = 5
      Width = 265
      Height = 23
      TabOrder = 0
      Text = 'ComboBox1'
      OnChange = cmbLanguageChange
    end
    object btnShowContent: TButton
      Left = 439
      Top = 4
      Width = 98
      Height = 25
      Caption = #26174#31034#25991#20214#20869#23481
      TabOrder = 1
      OnClick = btnShowContentClick
    end
    object Button2: TButton
      Left = 786
      Top = 92
      Width = 75
      Height = 25
      Caption = #36864#20986
      TabOrder = 2
    end
    object btnSelectAllExt: TButton
      Left = 296
      Top = 4
      Width = 129
      Height = 25
      Caption = #20840#36873'/'#19981#36873
      TabOrder = 3
    end
    object btnClose: TButton
      Left = 824
      Top = 4
      Width = 121
      Height = 25
      Anchors = [akTop, akRight]
      Caption = #20851#38381
      TabOrder = 4
      OnClick = btnCloseClick
    end
  end
  object Panel3: TPanel
    Left = 0
    Top = 44
    Width = 225
    Height = 425
    Align = alLeft
    TabOrder = 2
    ExplicitHeight = 408
    object DriveComboBox1: TDriveComboBox
      AlignWithMargins = True
      Left = 11
      Top = 11
      Width = 203
      Height = 21
      Margins.Left = 10
      Margins.Top = 10
      Margins.Right = 10
      Margins.Bottom = 10
      Align = alTop
      TabOrder = 0
      OnChange = DriveComboBox1Change
    end
    object DirectoryListBox1: TDirectoryListBox
      AlignWithMargins = True
      Left = 11
      Top = 52
      Width = 203
      Height = 362
      Margins.Left = 10
      Margins.Top = 10
      Margins.Right = 10
      Margins.Bottom = 10
      Align = alClient
      TabOrder = 1
      OnChange = DirectoryListBox1Change
      OnMouseDown = DirectoryListBox1MouseDown
      ExplicitHeight = 345
    end
  end
  object Panel4: TPanel
    Left = 744
    Top = 44
    Width = 217
    Height = 425
    Align = alRight
    TabOrder = 3
    ExplicitLeft = 738
    ExplicitHeight = 408
    object Splitter6: TSplitter
      Left = 1
      Top = 1
      Width = 215
      Height = 3
      Cursor = crVSplit
      Align = alTop
      ExplicitTop = 145
      ExplicitWidth = 183
    end
    object ListBox1: TListBox
      AlignWithMargins = True
      Left = 4
      Top = 7
      Width = 206
      Height = 414
      Margins.Right = 6
      Style = lbOwnerDrawFixed
      Align = alClient
      ItemHeight = 28
      TabOrder = 0
      OnClick = ListBox1Click
      OnDrawItem = ListBox1DrawItem
      ExplicitHeight = 397
    end
  end
  object Panel5: TPanel
    Left = 228
    Top = 44
    Width = 513
    Height = 425
    Align = alClient
    TabOrder = 4
    ExplicitWidth = 507
    ExplicitHeight = 408
    object Splitter5: TSplitter
      Left = 1
      Top = 121
      Width = 511
      Height = 3
      Cursor = crVSplit
      Align = alTop
      ExplicitTop = 1
      ExplicitWidth = 583
    end
    object StringGrid1: TStringGrid
      Left = 1
      Top = 124
      Width = 511
      Height = 300
      Align = alClient
      ColCount = 3
      DefaultColWidth = 220
      FixedCols = 0
      Options = [goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goColSizing, goRowSelect, goFixedRowDefAlign]
      TabOrder = 0
      OnClick = StringGrid1Click
      OnContextPopup = StringGrid1ContextPopup
      ExplicitWidth = 505
      ExplicitHeight = 283
      ColWidths = (
        40
        500
        180)
    end
    object Panel7: TPanel
      Left = 1
      Top = 1
      Width = 511
      Height = 72
      Align = alTop
      TabOrder = 1
      ExplicitWidth = 505
      object CheckListBox1: TCheckListBox
        Left = 1
        Top = 1
        Width = 509
        Height = 70
        Align = alClient
        Columns = 5
        ItemHeight = 17
        TabOrder = 0
        ExplicitWidth = 503
      end
    end
    object Panel8: TPanel
      Left = 1
      Top = 73
      Width = 511
      Height = 48
      Align = alTop
      TabOrder = 2
      ExplicitWidth = 505
      object btnConvert: TButton
        Left = 262
        Top = 17
        Width = 120
        Height = 25
        Caption = #20840#37096#36716#25442
        TabOrder = 0
        OnClick = btnConvertClick
      end
      object btnSingleFile: TButton
        Left = 386
        Top = 17
        Width = 120
        Height = 25
        Caption = #21333#20010#25991#20214#36716#25442
        TabOrder = 1
        OnClick = btnSingleFileClick
      end
      object btnRefresh: TButton
        Left = 139
        Top = 17
        Width = 120
        Height = 25
        Caption = #21047#26032
        TabOrder = 2
        OnClick = btnRefreshClick
      end
      object btnToggleSelect: TButton
        Left = 16
        Top = 17
        Width = 120
        Height = 25
        Caption = #20840#36873'/'#21462#28040
        TabOrder = 3
        OnClick = btnToggleSelectClick
      end
    end
  end
  object GridPopupMenu: TPopupMenu
    Left = 344
    Top = 248
    object MenuItemConvert: TMenuItem
      Caption = #36716#25442#36873#20013#25991#20214
      OnClick = MenuItemConvertClick
    end
    object MenuItemConvertCurrent: TMenuItem
      Caption = #36716#25442#24403#21069#25991#20214
      OnClick = MenuItemConvertCurrentClick
    end
    object MenuItemConvertAllFiles: TMenuItem
      Caption = #36716#25442#25972#20010#30446#24405
      OnClick = MenuItemConvertAllFilesClick
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object MenuItemToggleSelect: TMenuItem
      Caption = #20840#36873'/'#21462#28040
      OnClick = MenuItemToggleSelectClick
    end
  end
end
