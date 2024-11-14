object CardGameClientData: TCardGameClientData
  OnDestroy = DataModuleDestroy
  Height = 306
  Width = 382
  object IdTCPClient: TIdTCPClient
    OnDisconnected = IdTCPClientDisconnected
    OnConnected = IdTCPClientConnected
    ConnectTimeout = 0
    Port = 0
    ReadTimeout = -1
    Left = 24
    Top = 16
  end
  object PollingTimer: TTimer
    Enabled = False
    OnTimer = PollingTimerTimer
    Left = 144
    Top = 48
  end
end
