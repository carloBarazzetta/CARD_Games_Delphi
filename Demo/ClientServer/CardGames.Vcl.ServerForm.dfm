object ServerMainForm: TServerMainForm
  Left = 540
  Top = 304
  Caption = 'CardGames - Server Form'
  ClientHeight = 559
  ClientWidth = 988
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 13
  object EventsMemo: TMemo
    Left = 0
    Top = 376
    Width = 988
    Height = 183
    Align = alBottom
    ScrollBars = ssVertical
    TabOrder = 0
    WordWrap = False
  end
  object ConnectionPanel: TPanel
    Left = 769
    Top = 0
    Width = 219
    Height = 376
    Align = alRight
    TabOrder = 1
    object ButtonSendString: TButton
      AlignWithMargins = True
      Left = 4
      Top = 119
      Width = 211
      Height = 25
      Align = alTop
      Caption = 'Send String to client'
      TabOrder = 0
    end
    object TCPServerMemo: TMemo
      AlignWithMargins = True
      Left = 4
      Top = 150
      Width = 211
      Height = 222
      Align = alClient
      TabOrder = 1
    end
    object gbConnection: TGroupBox
      Left = 1
      Top = 1
      Width = 217
      Height = 88
      Align = alTop
      Caption = 'Connection'
      TabOrder = 2
      object edHost: TLabeledEdit
        AlignWithMargins = True
        Left = 3
        Top = 29
        Width = 116
        Height = 21
        Margins.Top = 16
        EditLabel.Width = 24
        EditLabel.Height = 13
        EditLabel.Caption = 'Host'
        TabOrder = 0
        Text = '127.0.0.1'
      end
      object edPort: TLabeledEdit
        AlignWithMargins = True
        Left = 125
        Top = 29
        Width = 52
        Height = 21
        Margins.Top = 16
        EditLabel.Width = 21
        EditLabel.Height = 13
        EditLabel.Caption = 'Port'
        TabOrder = 1
        Text = '6000'
      end
      object btConnectDisconnect: TButton
        AlignWithMargins = True
        Left = 5
        Top = 58
        Width = 207
        Height = 25
        Align = alBottom
        Caption = 'Connect'
        TabOrder = 2
        OnClick = btConnectDisconnectClick
      end
    end
    object Edit1: TEdit
      AlignWithMargins = True
      Left = 4
      Top = 92
      Width = 211
      Height = 21
      Align = alTop
      TabOrder = 3
      Text = 'Write Text here'
    end
  end
  object SimulateButton: TButton
    Left = 24
    Top = 20
    Width = 97
    Height = 25
    Caption = 'Simulate Game'
    TabOrder = 2
    OnClick = SimulateButtonClick
  end
  object ActionList: TActionList
    Left = 280
    Top = 288
    object acStartBriscolaServer: TAction
      Caption = 'Start Briscola Servers'
    end
    object acStopBriscolaServer: TAction
      Caption = 'Stop Briscola Servers'
    end
  end
end
