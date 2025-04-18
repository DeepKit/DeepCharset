object Form1: TForm1
  Left = 0
  Top = 0
  Caption = #25991#20214#36716#25442#24037#20855
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
    Top = 41
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
    Top = 44
    Height = 409
    ExplicitLeft = 0
    ExplicitHeight = 961
  end
  object Splitter4: TSplitter
    Left = 757
    Top = 44
    Height = 409
    Align = alRight
    ExplicitLeft = 778
    ExplicitTop = 47
    ExplicitHeight = 425
  end
  object Splitter9: TSplitter
    Left = 0
    Top = 453
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
    Top = 456
    Width = 1040
    Height = 157
    Align = alBottom
    TabOrder = 0
    object Splitter7: TSplitter
      Left = 606
      Top = 1
      Height = 155
      Align = alRight
      ExplicitLeft = 600
    end
    object Splitter8: TSplitter
      Left = 1
      Top = 1
      Height = 155
      ExplicitLeft = 778
      ExplicitTop = 47
      ExplicitHeight = 113
    end
    object Panel6: TPanel
      Left = 609
      Top = 1
      Width = 430
      Height = 155
      Align = alRight
      TabOrder = 0
      DesignSize = (
        430
        155)
      object SkSvg1: TSkSvg
        Left = 1
        Top = 1
        Width = 169
        Height = 153
        Margins.Left = 5
        Margins.Top = 5
        Margins.Right = 5
        Margins.Bottom = 5
        Align = alLeft
      end
      object btnSVG2ICON: TButton
        Left = 175
        Top = 116
        Width = 138
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'SVG'#22270#20687#36716#25442
        TabOrder = 0
        OnClick = btnSVG2ICONClick
      end
      object rgPicType: TRadioGroup
        Left = 176
        Top = 21
        Width = 233
        Height = 76
        Caption = #22270#20687#26684#24335
        Columns = 4
        ItemIndex = 0
        Items.Strings = (
          'ICO'
          'PNG'
          'JPG'
          'BMP'
          'GIF'
          'TIFF'
          'WebP')
        TabOrder = 1
      end
      object btnClose: TButton
        Left = 336
        Top = 115
        Width = 72
        Height = 25
        Anchors = [akTop, akRight]
        Caption = #36864#20986#36719#20214
        TabOrder = 2
        OnClick = btnCloseClick
      end
    end
    object PageControl1: TPageControl
      Left = 4
      Top = 1
      Width = 602
      Height = 155
      ActivePage = TabSheet1
      Align = alClient
      MultiLine = True
      TabOrder = 1
      TabPosition = tpRight
      object TabSheet1: TTabSheet
        Caption = 'Log'
        object MemLog: TMemo
          Left = 0
          Top = 0
          Width = 571
          Height = 147
          Align = alClient
          Lines.Strings = (
            'MemLog')
          TabOrder = 0
        end
      end
      object TabSheet2: TTabSheet
        Caption = 'SVG'
        ImageIndex = 1
        object meoSVG: TMemo
          Left = 0
          Top = 0
          Width = 571
          Height = 147
          Align = alClient
          ScrollBars = ssBoth
          TabOrder = 0
        end
      end
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 1040
    Height = 41
    Align = alTop
    TabOrder = 1
    object Label1: TLabel
      Left = 520
      Top = 8
      Width = 3
      Height = 15
    end
    object ComboBox1: TComboBox
      Left = 11
      Top = 5
      Width = 217
      Height = 23
      TabOrder = 0
      Text = 'ComboBox1'
      OnChange = cmbLanguageChange
    end
    object btnShowContent: TButton
      Left = 415
      Top = 4
      Width = 188
      Height = 25
      Caption = #26597#30475#20869#23481
      TabOrder = 3
      OnClick = btnShowContentClick
    end
    object Button2: TButton
      Left = 786
      Top = 92
      Width = 75
      Height = 25
      Caption = #36864#20986
      TabOrder = 1
    end
    object btnSelectAllExt: TButton
      Left = 234
      Top = 4
      Width = 175
      Height = 25
      Caption = #20840#36873#31867#22411
      TabOrder = 2
      OnClick = btnSelectAllExtClick
    end
    object chkIncludeSubdirs: TCheckBox
      Left = 609
      Top = 8
      Width = 151
      Height = 17
      Caption = 'chkIncludeSubdirs'
      TabOrder = 4
    end
  end
  object Panel3: TPanel
    Left = 0
    Top = 44
    Width = 225
    Height = 409
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
      Top = 52
      Width = 203
      Height = 346
      Margins.Left = 10
      Margins.Top = 10
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
    Top = 44
    Width = 280
    Height = 409
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
      Height = 398
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
    Top = 44
    Width = 529
    Height = 409
    Align = alClient
    TabOrder = 4
    object Splitter5: TSplitter
      Left = 1
      Top = 49
      Width = 527
      Height = 3
      Cursor = crVSplit
      Align = alTop
      ExplicitTop = 1
      ExplicitWidth = 583
    end
    object StringGrid1: TStringGrid
      Left = 73
      Top = 52
      Width = 455
      Height = 356
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
      Top = 52
      Width = 72
      Height = 356
      Align = alLeft
      TabOrder = 1
      object CheckListBox1: TCheckListBox
        Left = 1
        Top = 1
        Width = 70
        Height = 354
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
      Height = 48
      Align = alTop
      TabOrder = 2
      object btnConvert: TButton
        Left = 258
        Top = 5
        Width = 128
        Height = 25
        Caption = #20840#37096#36716#25442
        TabOrder = 0
        OnClick = btnConvertClick
      end
      object btnSingleFile: TButton
        Left = 392
        Top = 5
        Width = 130
        Height = 25
        Caption = #21333#20010#25991#20214#36716#25442
        TabOrder = 1
        OnClick = btnSingleFileClick
      end
      object btnRefresh: TButton
        Left = 167
        Top = 5
        Width = 85
        Height = 25
        Caption = #21047#26032
        TabOrder = 2
        OnClick = btnRefreshClick
      end
      object btnToggleSelect: TButton
        Left = 5
        Top = 5
        Width = 156
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
