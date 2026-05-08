object FrmChart: TFrmChart
  Left = 0
  Top = 0
  Caption = '图表显示主窗'
  ClientHeight = 600
  ClientWidth = 800
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
  object PnlTop: TPanel
    Left = 0
    Top = 0
    Width = 800
    Height = 41
    Align = alTop
    TabOrder = 0
    ExplicitWidth = 624
    object LblTitle: TLabel
      Left = 16
      Top = 13
      Width = 52
      Height = 15
      Caption = '图表标题: '
    end
    object LblChartType: TLabel
      Left = 240
      Top = 13
      Width = 52
      Height = 15
      Caption = '图表类型: '
    end
  end
end
