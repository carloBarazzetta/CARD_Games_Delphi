{******************************************************************************}
{                                                                              }
{ Briscola.CardGame:                                                           }
{ Engine del gioco Birscola basato sul framework Card Game                     }
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
unit Briscola.CardGame;

interface

uses
  CardGames.Types
  , CardGames.Model
  , CardGames.Engine
  , CardGames.Interfaces
  ;

resourcestring
  BRISCOLA_SIMPLE = 'Briscola a due';
  BRISCOLA_SIMPLE_DESC = 'Gioco della Briscola tra due giocatori';
  BRISCOLA_INPAIRS = 'Briscola a coppie';
  BRISCOLA_INPAIRS_DESC = 'Gioco della Briscola a coppie tra quattro giocatori';
  BRISCOLA_CALLED = 'Briscola chiamata';
  BRISCOLA_CALLED_DESC = 'Gioco della Briscola chiamata tra cinque giocatori';

type
  TBriscolaVariantType = (btBriscolaTwoPlayers, btBriscolaInPairs, btBriscolaCalled);

const
  ABriscolaVariantDesc: array[TBriscolaVariantType] of string =
    (BRISCOLA_SIMPLE, BRISCOLA_INPAIRS, BRISCOLA_CALLED);

type
  //Forward declarations
  TBriscolaGameRules = class;
  TBriscolaGameRulesClass = class of TBriscolaGameRules;

  /// <summary>
  ///  A base Class of a CardGame with some informations
  /// </summary>
  TBriscolaEngine = class(TCardGameEngine)
  private
    FBriscolaSuit: TCardGameSuit;
    FBriscolaValue: TCardGameValue;
    procedure SetBriscolaSuit(const AValue: TCardGameSuit);
    function GetGameRules: TBriscolaGameRules;
  protected
    function GetAIPlayerEngineClass: TAIPlayerEngineClass; override;
  public
    class function VariantTypeToRules(
      const ABriscolaType: TBriscolaVariantType): TBriscolaGameRulesClass; static;
    class function GetGameVariantsCount: Integer; override;
    class function GetGameVariantName(const AIndex: Integer): string; override;
    class function GetBriscolaRulesClass(
      const AType: TBriscolaVariantType): TCardGameRulesClass;
    procedure StartNewMatch; override;
    procedure ProcessEvent(const AGameEvent: ICardGameCommand);
    property BriscolaSuit: TCardGameSuit read FBriscolaSuit write SetBriscolaSuit;
    property GameRules: TBriscolaGameRules read GetGameRules;
  end;

  TBriscolaGameRules = class(TCardGameRules)
  private
    FEngine: TBriscolaEngine;
    FCardsToDeal: Integer;
    FPickBriscolaFromDeck: Boolean;
  protected
    procedure InitRules(out AGameTitle: TGameTitle;
      out ADeckType: TCardDeckType;
      out APlayersCountType: TPlayersCountType); override;
    function ScoreForCard(const ACard: TCardGameCard): Single; override;
    function ScoreForCardPlayed(const APlayer: TCardGamePlayer;
       const ACard: TCardGameCard): Single; override;
  public
    function CanPickCard(const APlayer: TCardGamePlayer;
      const ADeckCardGroup: TCardGameDeckCards; const ACard: TCardGameCard): boolean; override;
  end;

  TAIBriscolaPlayerEngine = class(TAIPlayerEngine)
  protected
    function SelectCardToPlay(const APlayer: TCardGamePlayer): TCardGameCard; override;
  end;

  TBriscolaTwoPlayersRules = class(TBriscolaGameRules)
  protected
    procedure InitRules(out AGameTitle: TGameTitle;
      out ADeckType: TCardDeckType;
      out APlayersCountType: TPlayersCountType); override;
  end;

  TBriscolaInPairsRules = class(TBriscolaGameRules)
  protected
    procedure InitRules(out AGameTitle: TGameTitle;
      out ADeckType: TCardDeckType;
      out APlayersCountType: TPlayersCountType); override;
  end;

  TBriscolaCalledRules = class(TBriscolaGameRules)
  protected
    procedure InitRules(out AGameTitle: TGameTitle;
      out ADeckType: TCardDeckType;
      out APlayersCountType: TPlayersCountType); override;
  end;

implementation

uses
  System.Classes
  , CardGames.Events
  , CardGames.JSONUtils
  ;

{ TBriscolaEngine }

class function TBriscolaEngine.VariantTypeToRules(
  const ABriscolaType: TBriscolaVariantType): TBriscolaGameRulesClass;
begin
  case ABriscolaType of
    btBriscolaInPairs: Result := TBriscolaInPairsRules;
    btBriscolaCalled: Result := TBriscolaCalledRules;
  else
    //btBriscolaTwoPlayers
    Result := TBriscolaTwoPlayersRules;
  end;
end;

function TBriscolaEngine.GetAIPlayerEngineClass: TAIPlayerEngineClass;
begin
  Result := TAIBriscolaPlayerEngine;
end;

class function TBriscolaEngine.GetBriscolaRulesClass(
  const AType: TBriscolaVariantType): TCardGameRulesClass;
begin
  case AType of
    btBriscolaInPairs: Result := TBriscolaInPairsRules;
    btBriscolaCalled: Result := TBriscolaCalledRules;
  else //btBriscolaTwoPlayers
    Result := TBriscolaTwoPlayersRules;
  end;
end;

function TBriscolaEngine.GetGameRules: TBriscolaGameRules;
begin
  Result := inherited GameRules as TBriscolaGameRules;
end;

class function TBriscolaEngine.GetGameVariantName(
  const AIndex: Integer): string;
begin
  Result := ABriscolaVariantDesc[TBriscolaVariantType(AIndex)];
end;

class function TBriscolaEngine.GetGameVariantsCount: Integer;
begin
  Result := Ord(high(TBriscolaVariantType));
end;

procedure TBriscolaEngine.ProcessEvent(const AGameEvent: ICardGameCommand);
begin
  //TODO: Process the Event to proceed in the Game
(*
  if AGameEvent is TPlayCardFromPlayerCommand then
  begin

  end;
*)
end;

procedure TBriscolaEngine.SetBriscolaSuit(const AValue: TCardGameSuit);
begin
  FBriscolaSuit := AValue;
end;

procedure TBriscolaEngine.StartNewMatch;
var
  LBriscolaCard: TCardGameCard;
begin
  inherited;
  //Scelgo il primo/prossimo mazziere della partita
  SelectFirstDealerRandomly;

  //Nella briscola il primo giocatore è quello successivo al mazziere
  SelectFirstPlayerAfterDealer;

  //Il mazziere mischia il mazzo
  ShuffleMainDeck;

  //Distribuisco le carte inziali ai giocatori, in base alle regole
  //del tipo di briscola che si sta giocando
  DealCardsToPlayers(GameRules.FCardsToDeal);

  //Prendo la carta di Briscola dal mazzo e la giro sul tavolo
  //se le regole del gioco lo prevedono
  if GameRules.FPickBriscolaFromDeck then
  begin
    LBriscolaCard := MoveCardFromDeckToTable;
    FBriscolaSuit := LBriscolaCard.Suit;
    FBriscolaValue := LBriscolaCard.Value;
  end;
end;

{ TBriscolaGameRules }

function TBriscolaGameRules.CanPickCard(const APlayer: TCardGamePlayer;
  const ADeckCardGroup: TCardGameDeckCards;
  const ACard: TCardGameCard): boolean;
begin
  //Default Rule: Pickable Card is Main Deck
  //or the Card present in DiscardedCards (is the Briscola card!)
  Result := inherited CanPickCard(APlayer, ADeckCardGroup, ACard) or
    (ADeckCardGroup = FEngine.Game.Deck.DiscardedCards);
end;

procedure TBriscolaGameRules.InitRules(out AGameTitle: TGameTitle;
  out ADeckType: TCardDeckType; out APlayersCountType: TPlayersCountType);
begin
  //Every Briscola Variants Games use the same Deck
  ADeckType := cd40UsingJ_Q_K;
  //Every Briscola Variants Games use same Counterclockwise Rotation
  PlayersRotation := ttCounterclockwiseRotation;
  //By default the Cards to Deal at start of Game are Three
  FCardsToDeal := 3;
  //By default the Card of "Briscola" is picked from the Deck
  FPickBriscolaFromDeck := True;
end;

function TBriscolaGameRules.ScoreForCard(const ACard: TCardGameCard): Single;
begin
  //Every Briscola Variants Games uses the same Score for Cards
  if ACard.Value = cvAce then
    Result := 11
  else if ACard.Value = cvThree then
    Result := 10
  else if ACard.Value = cvJack then
    Result := 2
  else if ACard.Value = cvQueen then
    Result := 3
  else if ACard.Value = cvKing then
    Result := 4
  else
    Result := 0;
end;

function TBriscolaGameRules.ScoreForCardPlayed(const APlayer: TCardGamePlayer;
  const ACard: TCardGameCard): Single;
begin
  //Calcolo valore carta
  Result := ScoreForCard(ACard);
  //Aggiungo il decimale del valore della carta che ha Score = 0
  if ACard.Value in [cvTwo, cvFour, cvFive, cvSix, cvSeven] then
    Result := Result + (Ord(ACard.Value) / 10);
  //Se è una briscola aggiungo 100
  if FEngine.FBriscolaSuit = ACard.Suit then
    Result := Result + 100;
end;

{ TBriscolaTwoPlayersRules }

procedure TBriscolaTwoPlayersRules.InitRules(out AGameTitle: TGameTitle;
  out ADeckType: TCardDeckType; out APlayersCountType: TPlayersCountType);
begin
  inherited InitRules(AGameTitle, ADeckType, APlayersCountType);
  //mandatory values
  AGameTitle := BRISCOLA_SIMPLE;
  APlayersCountType := pcTwoPlayers;
  //optional values
  Description := BRISCOLA_SIMPLE_DESC;
end;

{ TBriscolaInPairsRules }

procedure TBriscolaInPairsRules.InitRules(out AGameTitle: TGameTitle;
  out ADeckType: TCardDeckType; out APlayersCountType: TPlayersCountType);
begin
  inherited InitRules(AGameTitle, ADeckType, APlayersCountType);
  //mandatory values
  AGameTitle := BRISCOLA_INPAIRS;
  APlayersCountType := pcFourPlayers;
  //optional values
  TeamsCount := 2;
  Description := BRISCOLA_INPAIRS_DESC;
end;

{ TBriscolaCalledRules }

procedure TBriscolaCalledRules.InitRules(out AGameTitle: TGameTitle;
  out ADeckType: TCardDeckType; out APlayersCountType: TPlayersCountType);
begin
  inherited InitRules(AGameTitle, ADeckType, APlayersCountType);
  //mandatory values
  AGameTitle := BRISCOLA_CALLED;
  APlayersCountType := pcFivePlayers;
  //optional values
  TeamsCount := 2;
  Description := BRISCOLA_CALLED_DESC;
  //For Briscola Called, the Cards to Deal at start of Game are eight
  FCardsToDeal := 8;
  //For Briscola Called, By default the Card of "Briscola" is not picked from Deck
  FPickBriscolaFromDeck := False
end;

{ TAIBriscolaPlayerEngine }

function TAIBriscolaPlayerEngine.SelectCardToPlay(
  const APlayer: TCardGamePlayer): TCardGameCard;
begin
  Result := inherited SelectCardToPlay(APlayer);
end;

initialization
  //For Serialization/Deserialization
  RegisterClassToSerialize('TBriscolaEngine', TBriscolaEngine);
  RegisterClassToSerialize('TBriscolaGameRules', TBriscolaGameRules);
  RegisterClassToSerialize('TBriscolaTwoPlayersRules', TBriscolaTwoPlayersRules);
  RegisterClassToSerialize('TBriscolaInPairsRules', TBriscolaInPairsRules);
  RegisterClassToSerialize('TBriscolaCalledRules', TBriscolaCalledRules);
  RegisterClassToSerialize('TAIBriscolaPlayerEngine', TAIBriscolaPlayerEngine);

end.
