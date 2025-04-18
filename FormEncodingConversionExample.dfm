object frmEncodingConversion: TfrmEncodingConversion
  Left = 0
  Top = 0
  Caption = #25991#20214#32534#30721#26816#27979#19982#36716#25442#24037#20855
  ClientHeight = 562
  ClientWidth = 784
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 784
    Height = 49
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitLeft = 8
    ExplicitWidth = 776
    object lblFiles: TLabel
      Left = 167
      Top = 17
      Width = 417
      Height = 15
      Caption = #36873#25321#25991#20214#36827#34892#26816#27979#25110#36716#25442
    end
    object btnSelectFiles: TButton
      Left = 16
      Top = 13
      Width = 145
      Height = 25
      Caption = #36873#25321#25991#20214'...'
      TabOrder = 0
      OnClick = btnSelectFilesClick
    end
    object btnClear: TButton
      Left = 664
      Top = 13
      Width = 105
      Height = 25
      Caption = #28165#31354
      TabOrder = 1
      OnClick = btnClearClick
    end
  end
  object pnlCenter: TPanel
    Left = 0
    Top = 49
    Width = 784
    Height = 352
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitLeft = 8
    ExplicitTop = 16
    ExplicitWidth = 776
    ExplicitHeight = 441
    object lstFiles: TListBox
      Left = 0
      Top = 0
      Width = 784
      Height = 177
      Align = alTop
      ItemHeight = 15
      TabOrder = 0
    end
    object mmoLog: TMemo
      Left = 0
      Top = 177
      Width = 784
      Height = 175
      Align = alClient
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssBoth
      TabOrder = 1
      ExplicitTop = 145
      ExplicitHeight = 232
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 401
    Width = 784
    Height = 161
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    ExplicitTop = 425
    ExplicitWidth = 772
    object lblTargetEncoding: TLabel
      Left = 16
      Top = 21
      Width = 60
      Height = 15
      Caption = #30446#26631#32534#30721':'
    end
    object lblBackupExt: TLabel
      Left = 512
      Top = 21
      Width = 60
      Height = 15
      Caption = #22791#20221#21518#32512':'
    end
    object cboTargetEncoding: TComboBox
      Left = 82
      Top = 17
      Width = 145
      Height = 23
      Style = csDropDownList
      TabOrder = 0
    end
    object chkAddBOM: TCheckBox
      Left = 248
      Top = 19
      Width = 113
      Height = 17
      Caption = #28155#21152'BOM'#26631#35760
      TabOrder = 1
    end
    object chkCreateBackup: TCheckBox
      Left = 384
      Top = 19
      Width = 113
      Height = 17
      Caption = #21019#24314#22791#20221
      Checked = True
      State = cbChecked
      TabOrder = 2
    end
    object edtBackupExt: TEdit
      Left = 578
      Top = 17
      Width = 65
      Height = 23
      TabOrder = 3
      Text = '.bak'
    end
    object chkForceConversion: TCheckBox
      Left = 664
      Top = 19
      Width = 105
      Height = 17
      Caption = #24378#21046#36716#25442
      TabOrder = 4
    end
    object btnDetectEncodings: TButton
      Left = 16
      Top = 56
      Width = 145
      Height = 33
      Caption = #26816#27979#25991#20214#32534#30721
      TabOrder = 5
      OnClick = btnDetectEncodingsClick
    end
    object btnConvertFiles: TButton
      Left = 624
      Top = 56
      Width = 145
      Height = 33
      Caption = #36716#25442#25991#20214#32534#30721
      TabOrder = 6
      OnClick = btnConvertFilesClick
    end
    object ProgressBar: TProgressBar
      Left = 16
      Top = 112
      Width = 753
      Height = 25
      TabOrder = 7
    end
  end
  object dlgOpen: TOpenDialog
    Filter = #25152#26377#25991#20214'|*.*|'#25991#26412#25991#20214'|*.txt|Delphi '#28304#25991#20214'|*.pas;*.dfm;*.dpr'
    Options = [ofHideReadOnly, ofAllowMultiSelect, ofEnableSizing]
    Title = #36873#25321#35201#36716#25442#32534#30721#30340#25991#20214
    Left = 728
    Top = 24
  end
end 