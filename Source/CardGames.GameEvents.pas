{******************************************************************************}
{                                                                              }
{ CardGames.GameEvents:                                                        }
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
unit CardGames.GameEvents;

interface

uses
  System.Generics.Collections
  , System.Generics.Defaults
  , System.Classes
  , CardGames.Observer
  ;

type
  TGameEventData = class(TObject)
  private
    FEventName: string;
    FEventDetails: string;
  public
    constructor Create(const EventName, EventDetails: string);
    function Serialize: string;
    class function Deserialize(const SerializedData: string): TGameEventData;
    property EventName: string read FEventName;
    property EventDetails: string read FEventDetails;
  end;

implementation

uses
  System.SysUtils
  ;

constructor TGameEventData.Create(const EventName, EventDetails: string);
begin
  FEventName := EventName;
  FEventDetails := EventDetails;
end;

function TGameEventData.Serialize: string;
begin
  Result := Format('%s|%s', [FEventName, FEventDetails]);
end;

class function TGameEventData.Deserialize(const SerializedData: string): TGameEventData;
var
  EventParts: TArray<string>;
begin
  EventParts := SerializedData.Split(['|']);
  Result := TGameEventData.Create(EventParts[0], EventParts[1]);
end;

end.
