{******************************************************************************}
{                                                                              }
{ CardGames.Types                                                              }
{ Types for Card Games Classes                                                 }
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
unit CardGames.Types;

interface

uses
  System.Generics.Collections
  , System.Generics.Defaults
  , System.SysUtils
  ;

const
  ERROR_MSG = 'Error';

type
  /// <summary>
  ///  Specific Exception Class for Card Games
  /// </summary>
  ECardGameException = Exception;

  /// <summary>
  ///  TPlayerType defines a type of a Player that can be Human or IA
  /// </summary>
  TPlayerType = (ptHuman, ptAI);
  TPlayerTypes = set of TPlayerType;

  /// <summary>
  ///  TPlayerState defines a state of a Player during the Game
  /// </summary>
  TPlayerState = (psInactive, psActive, psSpectator, psDisqualified);
  TPlayerStates = set of TPlayerState;

  /// <summary>
  ///  TGameFamily defines a general type of Card Game (eg.Solitaire or Multiplayer)
  /// </summary>
  TGameFamily = (gfSolitaire, gfMultiplayer);

  /// <summary>
  ///  TPlayersCountType defines the quantity of Players in a Card Game
  /// </summary>
  TPlayersCountType = (pcUndefined, pcSolitaire, pcTwoPlayers, pcThreePlayers,
    pcFourPlayers, pcFivePlayers, pcSixPlayers, pcSevenPlayers);

  /// <summary>
  ///  TPlayersRotationType defines the type of Rotation for Players in a Card Game
  ///  for example to calculate the next Dealer in a new game or
  ///  the next Player in a Game Turn
  /// </summary>
  TPlayersRotationType = (ttNoRotation, ttClockwiseRotation, ttCounterclockwiseRotation, ttRandom);

  /// <summary>
  ///  TPickCardMode defines the position of a Card when picked from a TCardGameDeck
  /// </summary>
  TPickCardMode = (pcFromTop, pcFromBottom, pcRandom);

  /// <summary>
  ///  TCardDeckType defines the type of a TCardGameDeck
  /// </summary>
  TCardDeckType = (
    cd54FullSuitsPlusJokers, //Four Suits (13*4) + 2 Joker
    cd108FullSuitsPlusJokers, //Double Deck, Four Suits (13*4) + 2 Joker
    cd52FullSuits, //Four Suits (13*4)
    cd104FullSuits, //Double Deck, Four Suits (13*4)
    cd40UsingJ_Q_K, //Four Suits without 8,9,10 (10*4)
    cd40Using8_9_10); //Four Suits without J,Q,K (10*4)

  /// <summary>
  ///  TCardGameSuit defines the Suits of a Card in order:
  ///  0=csHide when the Suit of the card is not visibile to a Player
  ///  1=csSpade 2=csClub 3=csDiamond 4=csHeart
  /// </summary>
  TCardGameSuit = (csHide, csSpade, csClub, csDiamond, csHeart);
  /// <summary>
  ///  A set of TCardGameSuit
  /// </summary>
  TCardGameSuits = Set of TCardGameSuit;

  /// <summary>
  ///  TCardGameValue define the Value of a Card using an enumeration:
  ///  0=cvHide when the Value of the card is not visibile to a Player
  ///  Ord of cAce thru cKing ar the Values. Jokers has value = 14
  /// </summary>
  TCardGameValue = (cvHide, cvAce, cvTwo, cvThree, cvFour, cvFive, cvSix, cvSeven,
    cvEight, cvNine, cvTen, cvJack, cvQueen, cvKing, cvJoker);
  /// <summary>
  ///  A set of TCardGameValue
  /// </summary>
  TCardGameValues = Set of TCardGameValue;

  /// <summary>
  ///  TTurnStatus defines the Status of a Turn of a Game:
  /// </summary>
  TTurnStatus = (tsPending, tsActive, tsCompleted);
  /// <summary>
  ///  A Set of TTurnStatus
  /// </summary>
  TTurnStatuses = Set of TTurnStatus;

  /// <summary>TPlayerName defines the type of the name of a Player</summary>
  TCardPlayerName = string;

  /// <summary>TGameTitle defines the type of the name of a Game Title</summary>
  TGameTitle = string;

  /// <summary>TGameDescription defines the type of the name of a Game Description</summary>
  TGameDescription = string;

  /// <summary>TGameInstructions defines the type of the name of Game Instructions</summary>
  TGameInstructions = string;

  /// <summary>A Visible state of the Card on the Table</summary>
  TCardGameState = (csBlind, csFaceDown, csFaceUp);
  /// <summary>A Set of TCardGameState</summary>
  TCardGameStates = Set of TCardGameState;

implementation

uses
  CardGames.Consts
  , CardGames.Utils
  ;

end.
