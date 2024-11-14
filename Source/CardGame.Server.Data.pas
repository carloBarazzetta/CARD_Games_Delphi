{******************************************************************************}
{                                                                              }
{ CardGames.Server.Data:                                                       }
{ DataModule with instances of Server Engines of Card Games                    }
{                                                                              }
{ Copyright (c) 2024                                                           }
{ Author: Carlo Barazzetta                                                     }
{ Contributor: Lorenzo Barazzetta                                              }
{                                                                              }
{ https://github.com/carloBarazzetta/CARD_Games_Delphi                         }
{                                                                              }
{******************************************************************************}
{                                                                              }
{  Licensed under the Apache License, Version 2.0 (the "License");             }
{  you may not use this file except in compliance with the License.            }
{  You may obtain a copy of the License at                                     }
{                                                                              }
{      http://www.apache.org/licenses/LICENSE-2.0                              }
{                                                                              }
{  Unless required by applicable law or agreed to in writing, software         }
{  distributed under the License is distributed on an "AS IS" BASIS,           }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    }
{  See the License for the specific language governing permissions and         }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}
unit CardGame.Server.Data;
{$WARNINGS OFF}
interface

uses
  //Delphi
  System.Generics.Collections
  , System.SysUtils
  , System.Classes
  //CardGames
  , CardGames.Types
  , CardGames.GameServer
  , CardGames.Engine
  , CardGames.Observer
  , Briscola.CardGame
  //Indy
  , IdContext
  , IdBaseComponent
  , IdComponent
  , IdCustomTCPServer
  , IdTCPServer
  , IdGlobal
  ;

type
  TOnUpdateEvent = procedure (const AEvent: string) of Object;

  TCardGameServerData = class(TDataModule, ICardGameObserver)
    IdTCPServer: TIdTCPServer;
    procedure DataModuleDestroy(Sender: TObject);
    procedure IdTCPServerConnect(AContext: TIdContext);
    procedure IdTCPServerDisconnect(AContext: TIdContext);
    procedure IdTCPServerException(AContext: TIdContext;
      AException: Exception);
    procedure IdTCPServerExecute(AContext: TIdContext);
    procedure DataModuleCreate(Sender: TObject);
  private
    //Event Handlers for Server Form
    FOnTCPServerEvent: TOnUpdateEvent;
    FOnUpdateServerEvent: TOnUpdateEvent;

    //The Server instance of Briscola game
    FBriscolaServer: TGameServer;
    //Implementation of ICardGameObserver
    procedure Update(const ASerializedEvent: string);

    //Server Message of Indy TCP Server
    procedure ShowStartServerMessage;
    procedure StopStartServerMessage;

    function GetServerReady: Boolean;

    procedure EvaluateRequest(const ARequest: string;
      out AResponse: string);
  public
    function TCPServerConnectDisconnect(const AHost: string;
      const APort: Integer): string;
    //Simulate Procedures called by the CardGameServer
    function StartBriscolaServer(
      const AVariantType: TBriscolaVariantType;
      out AResponse: string): string;
    //Simulate Procedures called by the CardGameServer
    procedure StopBriscolaServer;

    //Simulate Procedures called by the CardGameClient
    procedure NewBriscolaGame(const AVariantType: TBriscolaVariantType;
      const APlayerName: TCardPlayerName; APlayerType, AOpponentsType: TPlayerType);

    property OnUpdateServerEvent: TOnUpdateEvent read FOnUpdateServerEvent write FOnUpdateServerEvent;
    property OnTCPServerEvent: TOnUpdateEvent read FOnTCPServerEvent write FOnTCPServerEvent;

    property IsServerReady: Boolean read GetServerReady;
  end;

//var CardGameServerData: TCardGameServerData;

implementation

uses
  //Indy
  IdSync
  ;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

{ TCardGameServerData }

procedure TCardGameServerData.DataModuleCreate(Sender: TObject);
begin
  ;
end;

procedure TCardGameServerData.DataModuleDestroy(Sender: TObject);
begin
  FreeAndNil(FBriscolaServer);
end;

function TCardGameServerData.GetServerReady: Boolean;
begin
  Result := Assigned(FBriscolaServer);
end;

procedure TCardGameServerData.IdTCPServerConnect(AContext: TIdContext);
begin
  if Assigned(FOnTCPServerEvent) then
    FOnTCPServerEvent('A client connected');
end;

procedure TCardGameServerData.IdTCPServerDisconnect(AContext: TIdContext);
begin
  if Assigned(FOnTCPServerEvent) then
    FOnTCPServerEvent('A client disconnected');
end;

procedure TCardGameServerData.IdTCPServerException(AContext: TIdContext;
  AException: Exception);
begin
  if Assigned(FOnTCPServerEvent) then
    FOnTCPServerEvent('An exception occurred!');
end;

procedure TCardGameServerData.ShowStartServerMessage;
begin
  if Assigned(FOnTCPServerEvent) then
    FOnTCPServerEvent('START SERVER  @' + TimeToStr(now));
end;

procedure TCardGameServerData.StopStartServerMessage;
begin
  if Assigned(FOnTCPServerEvent) then
    FOnTCPServerEvent('STOP SERVER  @' + TimeToStr(now));
end;

procedure TCardGameServerData.EvaluateRequest(const ARequest: string;
  out AResponse: string);
var
  LVariantType: TBriscolaVariantType;
begin
  AResponse := ERROR_MSG;
  Try
    //Evaluate Request
    if Pos('StartNewServerEngine', ARequest) > 0 then
    begin
      if Pos('TBriscolaTwoPlayersRule', ARequest) > 0 then
        LVariantType := btBriscolaTwoPlayers
      else if Pos('TBriscolaInPairsRules', ARequest) > 0 then
        LVariantType := btBriscolaInPairs
      else if Pos('TBriscolaCalledRules', ARequest) > 0 then
        LVariantType := btBriscolaCalled
      else
        Exit;

      StopBriscolaServer;
      StartBriscolaServer(LVariantType, AResponse);
    end
    else if Assigned(FBriscolaServer) then
    begin
      FBriscolaServer.EvaluateRequest(ARequest, AResponse);
    end
  Except
    On E:Exception do
      AResponse := Format('%s: %s', [ERROR_MSG, E.Message]);
  End;
end;

procedure TCardGameServerData.IdTCPServerExecute(AContext: TIdContext);
var
  LLine, LResponseJSON: String;
begin
  TIdNotify.NotifyMethod( ShowStartServerMessage );
  LLine := AContext.Connection.IOHandler.ReadLn(IndyTextEncoding_UTF8);
  if Assigned(FOnTCPServerEvent) then
    FOnTCPServerEvent(LLine);

  //Evaluate Requesto from Client
  EvaluateRequest(LLine, LResponseJSON);

  //Respond to Client
  if LResponseJSON <> '' then
    AContext.Connection.IOHandler.WriteLn(LResponseJSON);

  TIdNotify.NotifyMethod( StopStartServerMessage );
end;

function TCardGameServerData.TCPServerConnectDisconnect(const AHost: string;
  const APort: Integer): string;
begin
  if not IdTCPServer.Active then
  begin
    IdTCPServer.Bindings.Add.IP := AHost;
    IdTCPServer.Bindings.Add.Port := APort;
    IdTCPServer.Active := True;
  end
  else
  begin
    IdTCPServer.Active := False;
  end;
  if IdTCPServer.Active then
    Result := 'Disconnect'
  else
    Result := 'Connect';
end;

procedure TCardGameServerData.NewBriscolaGame(const AVariantType: TBriscolaVariantType;
  const APlayerName: TCardPlayerName; APlayerType, AOpponentsType: TPlayerType);
var
  LBriscolaServer: TGameServer;
  LAIName: string;
  LAINum: Integer;
begin
  LBriscolaServer := FBriscolaServer;

  //Add Player as the first Player of the Game
  LBriscolaServer.GameEngine.AddPlayerToGame(APlayerName, ptHuman);

  //Se gli opponent sono di tipo AI li aggiungo e faccio partire subito il gioco
  if AOpponentsType = ptAI then
  begin
    LAINum := 0;
    repeat
      Inc(LAINum);
      LAIName := Format('AI number %d',[LAINum]);
      LBriscolaServer.GameEngine.AddPlayerToGame(APlayerName, ptAI);
    until LBriscolaServer.GameEngine.CanStartNewMatch;
    //Inizio subito il gioco
    LBriscolaServer.StartGameEngine;
  end;
end;

function TCardGameServerData.StartBriscolaServer(
  const AVariantType: TBriscolaVariantType;
  out AResponse: string): string;
begin
  FBriscolaServer := TGameServer.Create(TBriscolaEngine);
  FBriscolaServer.RegisterObserver(Self);
  FBriscolaServer.InitServer(TBriscolaEngine.VariantTypeToRules(AVariantType));
  AResponse := FBriscolaServer.SerializeEngine;
end;

procedure TCardGameServerData.StopBriscolaServer;
begin
  if Assigned(FBriscolaServer) then
  begin
    FBriscolaServer.UnregisterObserver(Self);
    FreeAndNil(FBriscolaServer);
  end;
end;

procedure TCardGameServerData.Update(const ASerializedEvent: string);
begin
  if Assigned(OnUpdateServerEvent) then
    OnUpdateServerEvent(ASerializedEvent);
end;

end.
