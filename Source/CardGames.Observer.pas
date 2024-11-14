{******************************************************************************}
{                                                                              }
{ CardGames.Observer:                                                          }
{ Observer Pattern of Card Games                                               }
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
unit CardGames.Observer;

interface

uses
  System.Generics.Collections
  , System.Generics.Defaults
  , System.Classes
  , CardGames.Model
  ;

type
  /// <summary>Client Interface to receive notifications (Events)</summary>
  ICardGameObserver = interface
    ['{3596CF92-461A-42F4-A833-8024470F85D5}']
    procedure Update(const ASerializedCommand: string);
  end;

  /// <summary>A List of Observers</summary>
  TCardGameObservers = TList<ICardGameObserver>;

  /// <summary>Server Interface to send notifications (Events) to the Clients</summary>
  ICardGameObservable = interface
    ['{7521CBEC-CA18-401E-B069-5763EA400B95}']
    procedure RegisterObserver(AObserver: ICardGameObserver);
    procedure UnregisterObserver(AObserver: ICardGameObserver);
    procedure NotifyObservers(const ASerializedCommand: string);
  end;

implementation

end.
