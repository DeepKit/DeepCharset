object Form1: TForm1
  Left = 0
  Top = 0
  Caption = #30721#21040#25104#21151#65306#25991#20214#32534#30721#36716#25442#24037#20855
  ClientHeight = 616
  ClientWidth = 1040
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
    Top = 65
    Width = 1040
    Height = 3
    Cursor = crVSplit
    Align = alTop
    ExplicitLeft = 1
    ExplicitTop = 1
    ExplicitWidth = 113
  end
  object Splitter2: TSplitter
    Left = 0
    Top = 613
    Width = 1040
    Height = 3
    Cursor = crVSplit
    Align = alBottom
    ExplicitTop = 49
    ExplicitWidth = 961
  end
  object Splitter3: TSplitter
    Left = 225
    Top = 68
    Height = 521
    ExplicitLeft = 0
    ExplicitTop = 44
    ExplicitHeight = 961
  end
  object Splitter4: TSplitter
    Left = 757
    Top = 68
    Height = 521
    Align = alRight
    ExplicitTop = 42
    ExplicitHeight = 409
  end
  object Splitter9: TSplitter
    Left = 0
    Top = 589
    Width = 1040
    Height = 3
    Cursor = crVSplit
    Align = alBottom
    ExplicitLeft = 754
    ExplicitTop = 44
    ExplicitWidth = 412
  end
  object Panel1: TPanel
    Left = 0
    Top = 592
    Width = 1040
    Height = 21
    Align = alBottom
    TabOrder = 0
    Visible = False
    object Splitter7: TSplitter
      Left = 1036
      Top = 1
      Height = 19
      Align = alRight
      ExplicitLeft = 600
      ExplicitHeight = 155
    end
    object Splitter8: TSplitter
      Left = 1
      Top = 1
      Height = 19
      ExplicitLeft = 778
      ExplicitTop = 47
      ExplicitHeight = 113
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 1040
    Height = 65
    Align = alTop
    TabOrder = 1
    DesignSize = (
      1040
      65)
    object lblProgress: TLabel
      Left = 12
      Top = 38
      Width = 52
      Height = 15
      Anchors = [akLeft, akTop, akRight]
      Caption = #20934#22791#23601#32490
      Visible = False
    end
    object ComboBox1: TComboBox
      Left = 11
      Top = 6
      Width = 78
      Height = 23
      TabOrder = 0
      Text = 'ComboBox1'
      OnChange = cmbLanguageChange
    end
    object Button2: TButton
      Left = 786
      Top = 92
      Width = 75
      Height = 25
      Caption = #36864#20986
      TabOrder = 1
    end
    object CBoxDirHistory: TComboBox
      Left = 104
      Top = 7
      Width = 646
      Height = 23
      TabOrder = 2
    end
    object ProgressBar1: TProgressBar
      Left = 104
      Top = 36
      Width = 265
      Height = 17
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 3
      Visible = False
    end
    object btnRefresh: TButton
      Left = 786
      Top = 7
      Width = 98
      Height = 22
      Anchors = [akTop, akRight]
      Caption = #21047#26032
      TabOrder = 4
      OnClick = btnRefreshClick
    end
    object btnCancel: TButton
      Left = 909
      Top = 37
      Width = 98
      Height = 22
      Anchors = [akTop, akRight]
      Caption = #21462#28040#25805#20316
      TabOrder = 5
      Visible = False
    end
    object btnClose: TButton
      Left = 909
      Top = 7
      Width = 98
      Height = 22
      Anchors = [akTop, akRight]
      Caption = #36864#20986#36719#20214
      TabOrder = 6
      OnClick = btnCloseClick
    end
  end
  object Panel3: TPanel
    Left = 0
    Top = 68
    Width = 225
    Height = 521
    Align = alLeft
    TabOrder = 2
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
      Top = 62
      Width = 203
      Height = 448
      Margins.Left = 10
      Margins.Top = 20
      Margins.Right = 10
      Margins.Bottom = 10
      Align = alClient
      TabOrder = 1
      OnChange = DirectoryListBox1Change
      OnMouseDown = DirectoryListBox1MouseDown
    end
  end
  object Panel4: TPanel
    Left = 760
    Top = 68
    Width = 280
    Height = 521
    Align = alRight
    TabOrder = 3
    object Splitter6: TSplitter
      Left = 1
      Top = 1
      Width = 278
      Height = 3
      Cursor = crVSplit
      Align = alTop
      ExplicitTop = 145
      ExplicitWidth = 183
    end
    object TreeViewEncodings: TTreeView
      AlignWithMargins = True
      Left = 4
      Top = 7
      Width = 269
      Height = 510
      Margins.Right = 6
      Align = alClient
      HideSelection = False
      Indent = 19
      ReadOnly = True
      RightClickSelect = True
      TabOrder = 0
      OnClick = TreeViewEncodingsClick
    end
  end
  object Panel5: TPanel
    Left = 228
    Top = 68
    Width = 529
    Height = 521
    Align = alClient
    TabOrder = 4
    object Splitter5: TSplitter
      Left = 1
      Top = 73
      Width = 527
      Height = 3
      Cursor = crVSplit
      Align = alTop
      ExplicitTop = 1
      ExplicitWidth = 583
    end
    object StringGrid1: TStringGrid
      Left = 73
      Top = 76
      Width = 455
      Height = 372
      Align = alClient
      ColCount = 3
      FixedCols = 0
      RowCount = 2
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goDrawFocusSelected, goRowSelect]
      PopupMenu = GridPopupMenu
      TabOrder = 0
      OnClick = StringGrid1Click
      OnContextPopup = StringGrid1ContextPopup
      OnSelectCell = StringGridSelectCell
    end
    object Panel7: TPanel
      Left = 1
      Top = 76
      Width = 72
      Height = 372
      Align = alLeft
      TabOrder = 1
      object CheckListBox1: TCheckListBox
        Left = 1
        Top = 1
        Width = 70
        Height = 370
        Align = alClient
        Columns = 1
        ItemHeight = 17
        TabOrder = 0
      end
    end
    object Panel8: TPanel
      Left = 1
      Top = 1
      Width = 527
      Height = 72
      Align = alTop
      TabOrder = 2
      object lblDepth: TLabel
        Left = 456
        Top = 13
        Width = 26
        Height = 15
        Caption = #23618#32423
      end
      object btnConvert: TButton
        Left = 183
        Top = 36
        Width = 162
        Height = 25
        Caption = #20840#37096#36716#25442
        TabOrder = 0
        OnClick = btnConvertClick
      end
      object btnSingleFile: TButton
        Left = 351
        Top = 36
        Width = 171
        Height = 25
        Caption = #21333#20010#25991#20214#36716#25442
        TabOrder = 1
        OnClick = btnSingleFileClick
      end
      object btnToggleSelect: TButton
        Left = 5
        Top = 36
        Width = 172
        Height = 25
        Caption = #20840#36873'/'#21462#28040
        TabOrder = 2
        OnClick = btnToggleSelectClick
      end
      object chkIncludeSubdirs: TCheckBox
        Left = 355
        Top = 13
        Width = 86
        Height = 17
        Caption = #21253#25324#23376#30446#24405
        TabOrder = 3
      end
      object SpinEditDepth: TSpinEdit
        Left = 488
        Top = 9
        Width = 33
        Height = 24
        MaxValue = 50
        MinValue = 1
        TabOrder = 6
        Value = 2
        Visible = False
      end
      object btnSelectAllExt: TButton
        Left = 5
        Top = 5
        Width = 172
        Height = 25
        Caption = #20840#36873#31867#22411
        TabOrder = 4
        OnClick = btnSelectAllExtClick
      end
      object btnShowContent: TButton
        Left = 183
        Top = 5
        Width = 162
        Height = 25
        Caption = #26597#30475#20869#23481
        TabOrder = 5
        OnClick = btnShowContentClick
      end
    end
    object MemLog: TMemo
      Left = 1
      Top = 448
      Width = 527
      Height = 72
      Align = alBottom
      Lines.Strings = (
        'MemLog')
      ScrollBars = ssVertical
      TabOrder = 3
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
    object MenuItemViewContent: TMenuItem
      Caption = #26597#30475#20869#23481
      OnClick = MenuItemViewContentClick
    end
    object N2: TMenuItem
      Caption = '-'
    end
    object MenuItemCopyFullPath: TMenuItem
      Caption = #22797#21046#20840#36335#24452#25991#20214#21517
      OnClick = MenuItemCopyFullPathClick
    end
  end
end
