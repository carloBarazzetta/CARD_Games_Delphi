{******************************************************************************}
{                                                                              }
{ CardGames.Interfaces:                                                        }
{ Interfaces for Views and Controller of Card Games                            }
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
unit CardGames.Interfaces;

interface

uses
  System.Generics.Collections
  , System.Generics.Defaults
  , System.Classes
  , CardGames.Model
  ;

type
  ICardGameCommand = interface
    ['{58006822-4404-46B6-9B33-8AEE669F2318}']
    procedure Execute(const AGame: TCardGame);
  end;

  ICardGameCommandList = TList<ICardGameCommand>;

  ICardGamePlayerAction = interface
    ['{4E9C8E59-2FC3-4862-8FD9-6E0F9DC01B7A}']
    procedure Execute(const AGame: TCardGame);
  end;

implementation

end.
