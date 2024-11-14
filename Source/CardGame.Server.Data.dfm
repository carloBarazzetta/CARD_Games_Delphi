object CardGameServerData: TCardGameServerData
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Height = 218
  Width = 270
  object IdTCPServer: TIdTCPServer
    Bindings = <>
    DefaultPort = 0
    OnConnect = IdTCPServerConnect
    OnDisconnect = IdTCPServerDisconnect
    OnException = IdTCPServerException
    OnExecute = IdTCPServerExecute
    Left = 32
    Top = 26
  end
end
