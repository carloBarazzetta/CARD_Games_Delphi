{******************************************************************************}
{                                                                              }
{ CardGames.GameServer:                                                        }
{ Game Server of Card Games                                                    }
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
unit CardGames.GameServer;

interface

uses
  System.SysUtils
  , System.Generics.Collections
  , System.Generics.Defaults
  , System.Classes
  , CardGames.Types
  , CardGames.Model
  , CardGames.Events
  , CardGames.Engine
  , CardGames.Observer
  , CardGames.Interfaces
  ;

type
  /// <summary>
  ///  Server Class that contains an Engine for a specific Card Game
  ///  with specific Game Rules
  ///  collect clients and send Game Events to them
  /// </summary>
  TGameServer = class(TInterfacedObject, ICardGameObservable)
  private
    FObservers: TCardGameObservers;
    FGameEngine: TCardGameEngine;
    FCollectedEvents: TList<string>;
    procedure OnNewCardGameEvent(const AEvent: TCardGameElement);
  public
    constructor Create(const ACardGameEngineClass: TCardGameEngineClass);
    procedure InitServer(const ACardGameRulesClass: TCardGameRulesClass);
    destructor Destroy; override;

    //Implementation of ICardGameObservable
    procedure RegisterObserver(AObserver: ICardGameObserver);
    procedure UnregisterObserver(AObserver: ICardGameObserver);
    procedure NotifyObservers(const ASerializedEvent: string);

    procedure StartGameEngine;
    procedure StopGameEngine;
    procedure EvaluateRequest(const ARequest: string; out AResponse: string);
    function SerializeEngine: string;

    function SerializeCardForPlayer(const ACard: TCardGameCard;
      const APlayer: TCardGamePlayer): string;

    property GameEngine: TCardGameEngine read FGameEngine;
  end;

implementation

uses
  CardGames.JSONUtils
  ;

procedure TGameServer.InitServer(
  const ACardGameRulesClass: TCardGameRulesClass);
begin
  //initialize the Engines with Rules
  FGameEngine.InitRules(ACardGameRulesClass);
end;

procedure TGameServer.EvaluateRequest(const ARequest: string;
  out AResponse: string);
var
  LCollectFromNum, I: Integer;
  LPlayer: TCardGamePlayer;
  LValues: TList<string>;
  LGameEngineId: string;
begin
  AResponse := ERROR_MSG;
  Try
    //Evaluate Request
    if Pos('AddPlayerToGame', ARequest) > 0 then
    begin
      //AddPlayerToGame|%s|%s|%s', [PlayerName, PlayerType, PlayerOpponents]
      LValues := SplitStringByPipe(ARequest);
      LPlayer := GameEngine.AddPlayerToGame(LValues[1],
        StringToPlayerType(LValues[2]));
      AResponse := SerializeToString(LPlayer);
    end
    else if Pos('StartNewMatch', ARequest) > 0 then
    begin
      LGameEngineId := Copy(ARequest,15,maxint);
      if (GameEngine.Id = GameEngine.Id) then
      begin
        if GameEngine.CanStartNewMatch then
          GameEngine.CanStartNewMatch;
        AResponse := SerializeToString(GameEngine.Game);
      end
      else
        AResponse := Format('%s: %s',[ERROR_MSG, 'Cannot Start New Match']);
    end
    else if Pos('CollectEvents', ARequest) > 0 then
    begin
      //example: 'CollectEvents|123';
      LCollectFromNum := StrToInt(Copy(ARequest,15,maxint));
      AResponse := '';
      For I := 0 to FCollectedEvents.count -1 do
      begin
        if I >=LCollectFromNum then
          AResponse := AResponse + FCollectedEvents[I]+sLineBreak;
      end;
      AResponse := Format('[%s]', [AResponse]);
    end;
  Except
    On E:Exception do
      AResponse := Format('%s: %s', [ERROR_MSG, E.Message]);
  End;
end;

constructor TGameServer.Create(const ACardGameEngineClass: TCardGameEngineClass);
begin
  FCollectedEvents := TList<string>.Create;
  FObservers := TCardGameObservers.Create;
  //Create the engine
  FGameEngine := ACardGameEngineClass.Create;
  //Attach Event Handler
  FGameEngine.OnNewCardGameEvent := OnNewCardGameEvent;
end;

destructor TGameServer.Destroy;
begin
  FreeAndNil(FGameEngine);
  FreeAndNil(FObservers);
  FreeAndNil(FCollectedEvents);
  inherited;
end;

procedure TGameServer.RegisterObserver(AObserver: ICardGameObserver);
begin
  FObservers.Add(AObserver);
end;

procedure TGameServer.UnregisterObserver(AObserver: ICardGameObserver);
begin
  FObservers.Remove(AObserver);
end;

procedure TGameServer.NotifyObservers(const ASerializedEvent: string);
var
  Observer: ICardGameObserver;
begin
  for Observer in FObservers do
    Observer.Update(ASerializedEvent);
end;

function TGameServer.SerializeCardForPlayer(const ACard: TCardGameCard;
  const APlayer: TCardGamePlayer): string;
var
  Suit, Value: Integer;
begin
  // Nascondi il seme e il valore se il player non può vedere la carta
  if not FGameEngine.CanPlayerSeeCard(APlayer, ACard) then
  begin
    Suit := Integer(csHide);
    Value := Integer(cvHide);
  end
  else
  begin
    Suit := Integer(ACard.Suit);
    Value := Integer(ACard.Value);
  end;

  Result := Format('{ "Id": "%s", "Suit": %d, "Value": %d }',
    [ACard.Id, Suit, Value]);
end;

function TGameServer.SerializeEngine: string;
begin
  Result := SerializeToString(FGameEngine);
end;

procedure TGameServer.StartGameEngine;
begin
  FGameEngine.StartGame;
end;

procedure TGameServer.StopGameEngine;
begin
  FGameEngine.StopGame;
end;

procedure TGameServer.OnNewCardGameEvent(const AEvent: TCardGameElement);
var
  LSerializedEvent: string;
begin
  LSerializedEvent := SerializeToString(AEvent);
  FCollectedEvents.Add(LSerializedEvent);
  NotifyObservers(LSerializedEvent);
end;

end.
