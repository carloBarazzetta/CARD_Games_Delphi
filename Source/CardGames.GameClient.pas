{******************************************************************************}
{                                                                              }
{ CardGames.GameClient:                                                        }
{ Game Client of Card Games                                                    }
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
unit CardGames.GameClient;

interface

uses
  System.Generics.Collections
  , System.Generics.Defaults
  , System.SysUtils
  , System.Classes
  , CardGames.Types
  , CardGames.Model
  , CardGames.Engine
  , CardGames.Events
  , CardGames.Observer
  ;

type
 // Implementazione del client
  TGameClient = class(TInterfacedObject, ICardGameObservable)
  private
    FObservers: TCardGameObservers;
    FEngineId: string;
    FPlayerId: string;
    FMyPlayerName: string;
    FCollectedEventsNum: Integer;
    procedure NewCardGameEvent(const AEvent: TCardGameCommand);
    procedure DeserializeEvent(const ASerializedGameState: string);
  public
    //Implementation of ICardGameObservable
    procedure RegisterObserver(AObserver: ICardGameObserver);
    procedure UnregisterObserver(AObserver: ICardGameObserver);
    procedure NotifyObservers(const ASerializedCommand: string);

    constructor Create(const ACardGameRulesClass: TCardGameRulesClass);
    destructor Destroy; override;

    function GetNewServerEngineRequest(
      const AGameRulesClassName: string): string;

    function GetAddPlayerToGameRequest(
      const APlayerName: TCardPlayerName;
      APlayerType: TPlayerType): string;

    function GetStartGameRequest: string;

    procedure EvaluateResponse(const AResponse: string);
  end;

implementation

uses
  System.TypInfo
  , CardGames.JSONUtils
  ;

constructor TGameClient.Create(const ACardGameRulesClass: TCardGameRulesClass);
begin
  //Create an Engine for Client Interaction whith the Server Engine
  FObservers := TCardGameObservers.Create;
end;

procedure TGameClient.DeserializeEvent(const ASerializedGameState: string);
begin
  ;
end;

destructor TGameClient.Destroy;
begin
  FreeAndNil(FObservers);
  inherited;
end;

function TGameClient.GetStartGameRequest: string;
begin
  Result := Format('StartNewMatch|%s', [FEngineId]);
end;

function TGameClient.GetAddPlayerToGameRequest(const APlayerName: TCardPlayerName;
  APlayerType: TPlayerType): string;
var
  LPlayerTypeStr: string;
  LRequestCommand: string;
begin
  FMyPlayerName := APlayerName;
  LPlayerTypeStr := GetEnumName(TypeInfo(TPlayerType), Ord(APlayerType));
  LRequestCommand := Format('AddPlayerToGame|%s|%s',
    [APlayerName, LPlayerTypeStr]);

  Result := LRequestCommand;
end;

function TGameClient.GetNewServerEngineRequest(
  const AGameRulesClassName: string): string;
var
  LRequestCommand: string;
begin
  LRequestCommand := Format('StartNewServerEngine|%s',
      [AGameRulesClassName]);

  Result := LRequestCommand;
end;

procedure TGameClient.EvaluateResponse(const AResponse: string);
var
  LResponse, LResponseLine: string;
  LSerializedObject: string;
  LObject: TObject;
  LArray: TObjectList<TObject>;
  I: Integer;
begin
  if ( Pos(ERROR_MSG, AResponse) = 0 ) then
  begin
    //Response ad Array
    if Pos('[',AResponse)=1 then
    begin
      LArray := DeserializeArrayOfObjects(AResponse);
      For I := 0 to LArray.Count-1 do
      begin
        LResponseLine := SerializeToString(LArray[I]);
        LResponse := LResponseLine + sLineBreak;
      end;
        NotifyObservers(LResponse);
    end;
    //Response as Object
    if Pos('{',AResponse)=1 then
    begin
      LObject := DeSerializeFromJSON(AResponse);
      try
        if Assigned(LObject) then
        begin
          if LObject is TCardGameEngine then
          begin
            //Save Engine Id for further Requests
            FEngineId := TCardGameEngine(LObject).Id;
            FCollectedEventsNum := 0;
          end
          else if LObject is TCardGamePlayer then
          begin
            //Save Player Id for further Requests
            if TCardGamePlayer(LObject).Name = FMyPlayerName then
              FPlayerId := TCardGamePlayer(LObject).Id;
          end;
          LSerializedObject := SerializeToString(LObject);
            NotifyObservers(LSerializedObject);
        end;
      finally
        LObject.Free;
      end;
    end;
  end;
end;

procedure TGameClient.NewCardGameEvent(const AEvent: TCardGameCommand);
var
  LSerializedCommand: string;
begin
  LSerializedCommand := SerializeToString(AEvent);
  NotifyObservers(LSerializedCommand);
end;

procedure TGameClient.RegisterObserver(AObserver: ICardGameObserver);
begin
  FObservers.Add(AObserver);
end;

procedure TGameClient.UnregisterObserver(AObserver: ICardGameObserver);
begin
  FObservers.Remove(AObserver);
end;

procedure TGameClient.NotifyObservers(const ASerializedCommand: string);
var
  Observer: ICardGameObserver;
begin
  for Observer in FObservers do
    Observer.Update(ASerializedCommand);
end;

end.
