{******************************************************************************}
{                                                                              }
{ CardGames.Consts:                                                            }
{ Consts for Card Games                                                       }
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
unit CardGames.Consts;

interface

uses
  System.SysUtils
  , CardGames.Types
  ;

const
  //For Assertions
  VALUE_NOT_ASSIGNED = 'Expected Value %s not Assigned';
  DECK_IS_EMPTY = 'The Deck is Empty';
  CARD_NOT_AVAILABLE = 'The Card is not available';
  PLAYERS_NOT_DEFINED = 'Players are not defined';
  PLAYER_NOT_IN_TEAM = 'The Player is not present in the Team';
  EVENT_PROC_NOT_ASSIGNED = 'Event Procedure not assigned';
  PLAYER_PROC_NOT_ASSIGNED = 'Player Procedure not assigned';
  ENGINE_NOT_ASSIGNED = 'Card Game Engine not assigned';
  PLAYER_NOT_ASSIGNED = 'Player not assigned';
  GAME_NOT_ASSIGNED = 'Card Game Context not assigned';
  GAME_RULES_NOT_ASSIGNED = 'Game Rules not assigned';
  TABLE_NOT_ASSIGNED = 'Card Table not assigned';
  DECK_NOT_ASSIGNED = 'Deck not assigned';
  DECKCARDS_NOT_ASSIGNED = 'Deck Cards not assigned';
  TABLECARDS_NOT_ASSIGNED = 'Table Cards not assigned';
  CARD_GROUP_NOT_ASSIGNED = 'Card group not assigned';
  CARD_NOT_ASSIGNED = 'Card not assigned';
  MATCH_NOT_ASSIGNED = 'Match not assigned';

  APlayerTypeNames: Array[TPlayerType] of string =
    ('Human Player', 'IA Player');

implementation

end.
