{******************************************************************************}
{                                                                              }
{ CardGames.ViewModel:                                                         }
{ ViewModel of Card Games                                                      }
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
unit CardGames.ViewModel;

interface

uses
  System.SysUtils
  , System.Generics.Collections
  , System.Generics.Defaults
  , System.Classes
  , CardGames.Types
  , CardGames.Model
  , CardGames.Interfaces
  , CardGames.Engine
  , CardGames.Events
  ;

type
  TCardGameViewModel = class
  private
    FCardGame: TCardGame;
  public
    constructor Create(const ACardGame: TCardGameEngine);

    procedure UpdateView; // aggiorna la View in base allo stato dell'Engine
    procedure ProcessEventFromServer(const ASerializedEvent: string);

    property CardGame: TCardGame read FCardGame;
  end;

implementation

constructor TCardGameViewModel.Create(const AEngine: TCardGameEngine);
begin
  FCardGameEngine := AEngine;
end;

procedure TCardGameViewModel.UpdateView;
begin
  // Aggiorna la vista in base allo stato corrente del CardGameEngine.
  // Codice per sincronizzare la View con l’Engine...
end;

procedure TCardGameViewModel.ProcessEventFromServer(const ASerializedEvent: string);
begin
  // Delega la deserializzazione e l'elaborazione dell'evento all'Engine
end;

end.
