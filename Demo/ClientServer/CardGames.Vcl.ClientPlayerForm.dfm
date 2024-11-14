object ClientPlayerForm: TClientPlayerForm
  Left = 540
  Top = 304
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  Caption = 'CardGames - Client - PlayerView'
  ClientHeight = 757
  ClientWidth = 1073
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnActivate = FormActivate
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  TextHeight = 13
  object MessagePanel: TPanel
    Left = 0
    Top = 609
    Width = 1073
    Height = 41
    Align = alBottom
    Color = clBlack
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -21
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentBackground = False
    ParentFont = False
    TabOrder = 3
    StyleElements = [seFont, seBorder]
    ExplicitLeft = -8
    ExplicitTop = 424
    ExplicitWidth = 851
  end
  object PlayerPanel: TPanel
    Left = 0
    Top = 0
    Width = 185
    Height = 609
    Align = alLeft
    TabOrder = 0
    ExplicitHeight = 439
    object PlayerLabel: TLabel
      Left = 1
      Top = 1
      Width = 183
      Height = 13
      Align = alTop
      Alignment = taCenter
      Caption = 'Player'
      ExplicitWidth = 30
    end
    object AvailGamesLabel: TLabel
      Left = 1
      Top = 262
      Width = 183
      Height = 13
      Align = alTop
      Alignment = taCenter
      Caption = 'Available Games'
      ExplicitWidth = 83
    end
    object PlayerNameEdit: TLabeledEdit
      AlignWithMargins = True
      Left = 4
      Top = 34
      Width = 177
      Height = 21
      Margins.Top = 20
      Align = alTop
      EditLabel.Width = 62
      EditLabel.Height = 13
      EditLabel.Caption = 'Player Name'
      TabOrder = 0
      Text = ''
    end
    object NewGameButton: TButton
      AlignWithMargins = True
      Left = 4
      Top = 203
      Width = 177
      Height = 25
      Action = acNewGame
      Align = alTop
      TabOrder = 1
    end
    object rgGameType: TRadioGroup
      Left = 1
      Top = 58
      Width = 183
      Height = 85
      Align = alTop
      Caption = 'Tipo di gioco'
      TabOrder = 2
    end
    object AttachToGameButton: TButton
      AlignWithMargins = True
      Left = 4
      Top = 381
      Width = 177
      Height = 25
      Action = acAttachToGame
      Align = alTop
      TabOrder = 3
    end
    object AvailGamesListBox: TListBox
      AlignWithMargins = True
      Left = 4
      Top = 278
      Width = 177
      Height = 97
      Align = alTop
      ItemHeight = 13
      TabOrder = 4
    end
    object AbandonGameButton: TButton
      AlignWithMargins = True
      Left = 4
      Top = 412
      Width = 177
      Height = 25
      Action = acAbandonGame
      Align = alTop
      TabOrder = 5
    end
    object rgOpponentsType: TRadioGroup
      Left = 1
      Top = 143
      Width = 183
      Height = 57
      Align = alTop
      Caption = 'Opponents Type'
      TabOrder = 6
    end
    object RefreshButton: TButton
      AlignWithMargins = True
      Left = 4
      Top = 234
      Width = 177
      Height = 25
      Align = alTop
      Caption = 'Refresh Game'
      TabOrder = 7
      OnClick = RefreshButtonClick
    end
  end
  object EventsMemo: TMemo
    Left = 0
    Top = 650
    Width = 1073
    Height = 107
    Align = alBottom
    ScrollBars = ssVertical
    TabOrder = 1
    WordWrap = False
    ExplicitTop = 439
    ExplicitWidth = 851
  end
  object ConnectionPanel: TPanel
    Left = 876
    Top = 0
    Width = 197
    Height = 609
    Align = alRight
    TabOrder = 2
    ExplicitLeft = 696
    ExplicitHeight = 489
    object TCPClientMemo: TMemo
      AlignWithMargins = True
      Left = 4
      Top = 92
      Width = 189
      Height = 513
      Align = alClient
      TabOrder = 0
      ExplicitLeft = -4
      ExplicitTop = 76
    end
    object gbConnection: TGroupBox
      Left = 1
      Top = 1
      Width = 195
      Height = 88
      Align = alTop
      Caption = 'Connection'
      TabOrder = 1
      ExplicitLeft = 2
      ExplicitTop = 9
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
        Width = 185
        Height = 25
        Align = alBottom
        Caption = 'Connect'
        TabOrder = 2
        OnClick = btConnectDisconnectClick
      end
    end
  end
  object ActionList: TActionList
    OnUpdate = ActionListUpdate
    Left = 280
    Top = 288
    object acNewGame: TAction
      Caption = 'Nuova Partita'
      OnExecute = acNewGameExecute
      OnUpdate = acCanPlay
    end
    object acAttachToGame: TAction
      Caption = 'Partecipa alla partita'
      OnExecute = acNewGameExecute
      OnUpdate = acCanPlay
    end
    object acAbandonGame: TAction
      Caption = 'Abbandona partita'
      OnUpdate = acGameInProgress
    end
  end
end
