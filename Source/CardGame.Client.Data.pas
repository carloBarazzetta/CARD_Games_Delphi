{******************************************************************************}
{                                                                              }
{ CardGames.Client.Data:                                                       }
{ DataModule with instances of Client Engines of Card Games                    }
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
unit CardGame.Client.Data;

interface

uses
  //Delphi
  System.Generics.Collections
  , System.SysUtils
  , System.Classes
  //CardGames
  , CardGames.Types
  , CardGames.Model
  , CardGames.GameClient
  , CardGames.Engine
  , CardGames.Observer
  , Briscola.CardGame
  //Indy
  , IdBaseComponent
  , IdComponent
  , IdTCPConnection
  , IdTCPClient
  , Vcl.ExtCtrls
  ;

type
  TOnUpdateEvent = procedure (const ASerializedCommand: string) of Object;

  TCardGameClientData = class(TDataModule, ICardGameObserver)
    IdTCPClient: TIdTCPClient;
    PollingTimer: TTimer;
    procedure DataModuleDestroy(Sender: TObject);
    procedure IdTCPClientConnected(Sender: TObject);
    procedure IdTCPClientDisconnected(Sender: TObject);
    procedure PollingTimerTimer(Sender: TObject);
  private
    FOnUpdateTCPClientEvent: TOnUpdateEvent;
    FOnUpdateClientEvent: TOnUpdateEvent;

    FPlayerId: string;
    FCollectedEventsNum: Integer;
    FRequestId: string;
    FBriscolaClient: TGameClient;

    //Implementation of ICardGameObserver
    procedure Update(const ASerializedCommand: string);
    function GetClientReady: Boolean;
  public
    //Indy Client procedures
    function ConnectDisconnect(const AHost: string; const APort: Integer): string;
    procedure SendRequestToServer(const ARequest: string);

    procedure NewBriscolaGame(const AVariantType: TBriscolaVariantType;
      const APlayerName: TCardPlayerName; APlayerType: TPlayerType);

    procedure RequestCardGameEvents;

    property OnUpdateClientEvent: TOnUpdateEvent read FOnUpdateClientEvent write FOnUpdateClientEvent;
    property OnUpdateTCPClientEvent: TOnUpdateEvent read FOnUpdateTCPClientEvent write FOnUpdateTCPClientEvent;

    property IsClientReady: Boolean read GetClientReady;
  end;

//var CardGameClientData: TCardGameClientData;

implementation

uses
  //Indy
  IdGlobal
  , System.TypInfo
  , CardGames.Events
  ;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

function TCardGameClientData.ConnectDisconnect(
  const AHost: string; const APort: Integer): string;
begin
  try
    if IdTCPClient.Connected then
    begin
      IdTCPClient.Disconnect;
    end
    else
    begin
      IdTCPClient.Host := AHost;
      IdTCPClient.Port := APort;
      IdTCPClient.Connect;
    end;
    if IdTCPClient.Connected then
      Result := 'Disconnect'
    else
      Result := 'Connect';
  except
    On E: Exception do
    begin
      if Assigned(FOnUpdateTCPClientEvent) then
        FOnUpdateTCPClientEvent(Format('Connection Error: %s',
          [E.Message]));
    end;
  End;
end;

procedure TCardGameClientData.SendRequestToServer(const ARequest: string);
var
  LRequest, LResponse: string;
begin
  LRequest := StringReplace(ARequest, sLineBreak, '', [rfReplaceAll]);
  IdTCPClient.IOHandler.WriteLn(LRequest, IndyTextEncoding_UTF8);
  LResponse := IdTCPClient.IOHandler.ReadLn();
  //Call the Client to Evaluate the Response
  FBriscolaClient.EvaluateResponse(LResponse);
  if Assigned(FOnUpdateTCPClientEvent) then
    FOnUpdateTCPClientEvent(LResponse);
end;

{ TCardGameServerData }

procedure TCardGameClientData.DataModuleDestroy(Sender: TObject);
begin
  ;
end;

function TCardGameClientData.GetClientReady: Boolean;
begin
  Result := IdTCPClient.Connected;
end;

procedure TCardGameClientData.IdTCPClientConnected(Sender: TObject);
begin
  if Assigned(FOnUpdateTCPClientEvent) then
    FOnUpdateTCPClientEvent('Client connected with server');
end;

procedure TCardGameClientData.IdTCPClientDisconnected(Sender: TObject);
begin
  if Assigned(FOnUpdateTCPClientEvent) then
    FOnUpdateTCPClientEvent('Client disconnected from server');
end;

procedure TCardGameClientData.NewBriscolaGame(const AVariantType: TBriscolaVariantType;
  const APlayerName: TCardPlayerName; APlayerType: TPlayerType);
var
  LGameRulesClass: TCardGameRulesClass;
  LRequestCommand: string;
begin
  LGameRulesClass := TBriscolaEngine.VariantTypeToRules(AVariantType);

  FBriscolaClient := TGameClient.Create(LGameRulesClass);
  FBriscolaClient.RegisterObserver(Self);

  //Request a New Briscola Engine/Game
  LRequestCommand := FBriscolaClient.GetNewServerEngineRequest(
    LGameRulesClass.ClassName);
  SendRequestToServer(LRequestCommand);

  //Add New Player to the Game
  LRequestCommand := FBriscolaClient.GetAddPlayerToGameRequest(
    APlayerName, APlayerType);
  SendRequestToServer(LRequestCommand);

  //Add New Player to the Game as AI
  LRequestCommand := FBriscolaClient.GetAddPlayerToGameRequest(
    'AI', ptAI);
  SendRequestToServer(LRequestCommand);

  //Start The Game
  if AVariantType = btBriscolaTwoPlayers then
  LRequestCommand := FBriscolaClient.GetStartGameRequest;
  SendRequestToServer(LRequestCommand);
end;

procedure TCardGameClientData.PollingTimerTimer(Sender: TObject);
begin
  //Request to Server the Game Events
  RequestCardGameEvents;
end;

procedure TCardGameClientData.RequestCardGameEvents;
var
  LRequestCommand: string;
  LCollectEvents: TList<string>;
begin
  //Request to Server the Game Events
  FRequestId := 'CollectEvents';
  LRequestCommand := Format('%s|%d',[FRequestId,FCollectedEventsNum]);
  SendRequestToServer(LRequestCommand);
end;

procedure TCardGameClientData.Update(const ASerializedCommand: string);
begin
  if Assigned(OnUpdateClientEvent) then
    OnUpdateClientEvent(ASerializedCommand);
end;

end.
