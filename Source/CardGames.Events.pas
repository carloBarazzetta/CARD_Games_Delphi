{******************************************************************************}
{                                                                              }
{ CardGames.Events:                                                            }
{ Base Commands/Events for Card Games                                          }
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
unit CardGames.Events;

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
  ;

type
  //Forward declarations
  TCardGameCommand = class;
  TCardGameCommandClass = class of TCardGameCommand;

  TCardGamePlayerAction = class;
  TCardGamePlayerActionClass = class of TCardGamePlayerAction;

  TCommandProc = reference to procedure(ACommand: TCardGameCommand);
  TPlayerActionProc = reference to procedure(APlayerAction: TCardGamePlayerAction);

  /// <summary>A List of Commands of a TCardGameEngine</summary>
  TCardGameCommands = TList<TCardGameCommand>;

  TCardGameCommand = class(TCardGameElement, ICardGameCommand)
  private
    FGame: TCardGame;
  strict protected
  protected
    constructor Create;
    //Implementation of ICardGameCommand Interface
    procedure Execute(const AGame: TCardGame); virtual;
  public
    property Game: TCardGame read FGame;
    destructor Destroy; override;
  end;

  TCreateCardGame = class(TCardGameCommand)
  strict private
    //input value
    FRules: TCardGameRules;
    //output value
    FGame: TCardGame;
  public
    constructor Create(const AEngine: TCardGameEngine;
      const ARules: TCardGameRules);
    property Rules: TCardGameRules read FRules;
    //output value
    property Game: TCardGame read FGame;
  end;

  TCardGamePlayerAction = class(TCardGameElement)
  strict private
    FGame: TCardGame;
    FCommand: TCardGameCommand;
    FPlayer: TCardGamePlayer;
  protected
    constructor Create(const ACommand: TCardGameCommand;
      const AInitProc: TPlayerActionProc = nil);
    procedure Execute(const APlayer: TCardGamePlayer); virtual; abstract;
  public
    property Game: TCardGame read FGame;
    property Command: TCardGameCommand read FCommand;
    property Player: TCardGamePlayer read FPlayer;
  end;

  TSelectCardToPlayAction = class(TCardGamePlayerAction)
  private
    FSelectedCard: TCardGameCard;
  strict protected
    procedure Execute(const APlayer: TCardGamePlayer); override;
  public
    property SelectedCard: TCardGameCard read FSelectedCard write FSelectedCard;
  end;

  TCalcWinnerPlayerOfHand  = class(TCardGameCommand)
  private
    //input value
    FFirstPlayerOfHand: TCardGamePlayer;
    //output value
    FWinnerPlayer: TCardGamePlayer;
  protected
    procedure Execute(const AGame: TCardGame); override;
  public
    constructor Create(const AFirstPlayerOfHand: TCardGamePlayer);
    property WinnerPlayer: TCardGamePlayer read FWinnerPlayer;
  end;

  TCalcScoreOfPlayedCardsCommand = class(TCardGameCommand)
  private
    //input value
    FPlayer: TCardGamePlayer;
    //output value
    FPlayedCardScore: Single;
  protected
    procedure Execute(const AGame: TCardGame); override;
  public
    constructor Create(const APlayer: TCardGamePlayer);
    property Player: TCardGamePlayer read FPlayer;
    property PlayedCardScore: Single read FPlayedCardScore;
  end;

  TStartNewMatchCommand = class(TCardGameCommand)
  private
    //input value
    FNewMatch: TCardGameMatch;
  protected
    procedure Execute(const AGame: TCardGame); override;
  public
    constructor Create(const ANewMatch: TCardGameMatch);
    property NewMatch: TCardGameMatch read FNewMatch write FNewMatch;
  end;

  TAddPlayerToGameCommand = class(TCardGameCommand)
  private
    //input values
    FName: TCardPlayerName;
    FType: TPlayerType;
    //output value
    FAddedPlayer: TCardGamePlayer;
  protected
    procedure Execute(const AGame: TCardGame); override;
  public
    constructor Create(const AName: TCardPlayerName;
      const AType: TPlayerType);
    property AddedPlayer: TCardGamePlayer read FAddedPlayer write FAddedPlayer;
    property PlayerName: TCardPlayerName read FName write FName;
    property PlayerType: TPlayerType read FType write FType;
  end;

  TSelectNextDealerCommand = class(TCardGameCommand)
  private
    //input value
    FStartingFrom: TCardGamePlayer;
    //output value
    FSelectedDealer: TCardGamePlayer;
  strict protected
    procedure Execute(const AGame: TCardGame); override;
  public
    constructor Create(AStartingFrom: TCardGamePlayer);
    property SelectedDealer: TCardGamePlayer read FSelectedDealer;
  end;

  TSelectNextPlayerCommand = class(TCardGameCommand)
  private
    //input value
    FStartingFrom: TCardGamePlayer;
    //output value
    FSelectedPlayer: TCardGamePlayer;
  protected
    procedure Execute(const AGame: TCardGame); override;
  public
    constructor Create(AStartingFrom: TCardGamePlayer);
    property SelectedPlayer: TCardGamePlayer read FSelectedPlayer;
  end;

  TPickCardFromDeck = class(TCardGameCommand)
    //input value
    FPlayer: TCardGamePlayer;
    FMode: TPickCardMode;
    //output value
    FPickedCard: TCardGameCard;
  protected
    procedure Execute(const AGame: TCardGame); override;
  public
    constructor Create(const APlayer: TCardGamePlayer;
      const AMode: TPickCardMode);
    property Player: TCardGamePlayer read FPlayer write FPlayer;
    property Mode: TPickCardMode read FMode write FMode;
    property PickedCard: TCardGameCard read FPickedCard write FPickedCard;
  end;

  TMoveCardFromDeckToTable = class(TCardGameCommand)
    //input value
    FMode: TPickCardMode;
    FState: TCardGameState;
    //output value
    FMovedCard: TCardGameCard;
  protected
    procedure Execute(const AGame: TCardGame); override;
  public
    constructor Create(const AMode: TPickCardMode; const AState: TCardGameState);
    property Mode: TPickCardMode read FMode write FMode;
    property State: TCardGameState read FState write FState;
    property MovedCard: TCardGameCard read FMovedCard write FMovedCard;
  end;

  TMoveCardCommand = class(TCardGameCommand)
    //input value
    FSenderGroup: TCardGameCardsGroup;
    FTargetGroup: TCardGameCardsGroup;
    FCardToMove: TCardGameCard;
    FState: TCardGameState;
  protected
    procedure Execute(const AGame: TCardGame); override;
  public
    constructor Create(const ASenderGroup: TCardGameCardsGroup;
      const ATargetGroup: TCardGameCardsGroup;
      const ACardToMove: TCardGameCard;
      const AState: TCardGameState = csFaceUp);
    property SenderGroup: TCardGameCardsGroup read FSenderGroup write FTargetGroup;
    property TargetGroup: TCardGameCardsGroup read FTargetGroup write FTargetGroup;
    property CardToMoved: TCardGameCard read FCardToMove write FCardToMove;
    property State: TCardGameState read FState write FState;
  end;

  TDealCardToPlayerCommand = class(TCardGameCommand)
  private
    //input value
    FTargetPlayer: TCardGamePlayer;
    //output value
    FCardToDeal: TCardGameCard;
  protected
    procedure Execute(const AGame: TCardGame); override;
  public
    constructor Create(const ATargetPlayer: TCardGamePlayer);
    property TargetPlayer: TCardGamePlayer read FTargetPlayer write FTargetPlayer;
    property CardToDeal: TCardGameCard read FCardToDeal;
  end;

  TPlayCardFromPlayerCommand = class(TCardGameCommand)
  private
    //input value
    FPlayer: TCardGamePlayer;
    //output value
    FSelectedCard: TCardGameCard;
  protected
    procedure Execute(const AGame: TCardGame); override;
  public
    constructor Create(const APlayer: TCardGamePlayer);
    property Player: TCardGamePlayer read FPlayer write FPlayer;
    property SelectedCard: TCardGameCard read FSelectedCard;
  end;

  TCalcTableCardsScoreCommand = class(TCardGameCommand)
  private
    //input value
    FCardTable: TCardGameTable;
    FCardGroup: TCardGameTableCards;
    //output value
    FTableCardsScore: Single;
  public
    procedure Execute(const AGame: TCardGame); override;
    property CardTable: TCardGameTable read FCardTable write FCardTable;
    property TableCardsScore: Single read FTableCardsScore;
  end;

  TShuffleMainDeckCommand = class(TCardGameCommand)
  private
    //input value
    FDeckCards: TCardGameDeckCards;
    //output value
    FNumCardsInDeck: Integer;
  public
    constructor Create(ADeckCards: TCardGameDeckCards);
    procedure Execute(const AGame: TCardGame); override;
    property DeckCards: TCardGameDeckCards read FDeckCards write FDeckCards;
    property NumCardsInDeck: Integer read FNumCardsInDeck;
  end;

implementation

uses
  CardGames.Consts
  , CardGames.JSONUtils
  ;

{ TCardGameCommand }

constructor TCardGameCommand.Create;
begin
  inherited Create;
end;

destructor TCardGameCommand.Destroy;
begin
  //FreeAndNil(FActionToExecute);
  inherited;
end;

procedure TCardGameCommand.Execute(const AGame: TCardGame);
begin
  Assert(Assigned(AGame), GAME_NOT_ASSIGNED);
  FGame := AGame;
end;

{ TShuffleMainDeckCommand }

constructor TShuffleMainDeckCommand.Create(ADeckCards: TCardGameDeckCards);
begin
  inherited Create;
  FDeckCards := ADeckCards;
end;

procedure TShuffleMainDeckCommand.Execute;
begin
  Assert(Assigned(FDeckCards), DECKCARDS_NOT_ASSIGNED);
  FDeckCards.Shuffle;
  FNumCardsInDeck := FDeckCards.Cards.Count;
end;

{ TSelectNextDealerCommand }

constructor TSelectNextDealerCommand.Create(AStartingFrom: TCardGamePlayer);
begin
  inherited Create;
  FStartingFrom := AStartingFrom;
end;

procedure TSelectNextDealerCommand.Execute;
begin
  inherited;
  Game.SelectNextDealer(FStartingFrom);
  FSelectedDealer := Game.CurrentDealer;
end;

{ TDealCardToPlayerCommand }

constructor TDealCardToPlayerCommand.Create(
  const ATargetPlayer: TCardGamePlayer);
begin
  inherited Create;
  FTargetPlayer := ATargetPlayer;
end;

procedure TDealCardToPlayerCommand.Execute;
begin
  inherited;
  Assert(Assigned(FTargetPlayer), PLAYER_NOT_ASSIGNED);
  FCardToDeal := FTargetPlayer.PickCardFromDeck;
end;

{ TPlayCardFromPlayerCommand }

constructor TPlayCardFromPlayerCommand.Create(
  const APlayer: TCardGamePlayer);
begin
  inherited Create;
  FPlayer := APlayer;
end;

procedure TPlayCardFromPlayerCommand.Execute;
begin
  inherited;
  Assert(Assigned(FPlayer), PLAYER_NOT_ASSIGNED);
(*
  WaitForAction(FPlayer, TSelectCardToPlayAction,
    nil,
    procedure(APlayerAction: TCardGamePlayerAction)
    begin
      FSelectedCard := TSelectCardToPlayAction(APlayerAction).FSelectedCard;
    end);
*)
  FPlayer.PlayCard(FSelectedCard);
end;

{ TSelectNextPlayerCommand }

constructor TSelectNextPlayerCommand.Create(AStartingFrom: TCardGamePlayer);
begin
  inherited Create;
  FStartingFrom := AStartingFrom;
end;

procedure TSelectNextPlayerCommand.Execute;
begin
  inherited;
  Game.SelectNextPlayer(FStartingFrom);
  FSelectedPlayer := Game.CurrentPlayer;
end;

{ TSelectCardToPlayAction }

procedure TSelectCardToPlayAction.Execute(const APlayer: TCardGamePlayer);
begin
  inherited;
  Assert(Assigned(APlayer), PLAYER_NOT_ASSIGNED);
  FSelectedCard := APlayer.HandledCards.RandomSelect;
end;

{ TCalcTableCardsScoreCommand }

procedure TCalcTableCardsScoreCommand.Execute;
begin
  inherited;
  Assert(Assigned(FCardTable), TABLE_NOT_ASSIGNED);
  if not Assigned(FCardGroup) then
    FCardGroup := FCardTable.CardsOnTable;
  FTableCardsScore := FCardGroup.CardsScore;
end;

{ TMoveCardCommand }

constructor TMoveCardCommand.Create(
  const ASenderGroup: TCardGameCardsGroup;
  const ATargetGroup: TCardGameCardsGroup;
  const ACardToMove: TCardGameCard;
  const AState: TCardGameState = csFaceUp);
begin
  inherited Create;
  FSenderGroup := ASenderGroup;
  FTargetGroup := ATargetGroup;
  FCardToMove := ACardToMove;
  FState := AState;
end;

procedure TMoveCardCommand.Execute;
begin
  inherited;
  Assert(Assigned(FSenderGroup), CARD_GROUP_NOT_ASSIGNED);
  Assert(Assigned(FTargetGroup), CARD_GROUP_NOT_ASSIGNED);
  Assert(Assigned(FCardToMove), CARD_NOT_ASSIGNED);
  Game.MoveCard(FSenderGroup, FTargetGroup, FCardToMove, FState);
end;

{ TAddPlayerToGameCommand }

constructor TAddPlayerToGameCommand.Create(const AName: TCardPlayerName;
  const AType: TPlayerType);
begin
  inherited Create;
  FName := AName;
  FType := AType;
end;

procedure TAddPlayerToGameCommand.Execute;
begin
  inherited;
  //Add a new Player to the Game
  FAddedPlayer := Game.AddPlayer(FName, FType);
end;

{ TStartNewMatchCommand }

constructor TStartNewMatchCommand.Create(const ANewMatch: TCardGameMatch);
begin
  inherited Create;
  FNewMatch := ANewMatch;
end;

procedure TStartNewMatchCommand.Execute;
begin
  inherited;
  Assert(Assigned(FNewMatch), MATCH_NOT_ASSIGNED);
end;

{ TCardGamePlayerAction }

constructor TCardGamePlayerAction.Create(const ACommand: TCardGameCommand;
  const AInitProc: TPlayerActionProc);
begin
  inherited Create;
  FCommand := ACommand;
  FGame := ACommand.FGame;
  if Assigned(AInitProc) then
    AInitProc(Self);
end;

{ TCalcScoreOfPlayedCardsCommand }

constructor TCalcScoreOfPlayedCardsCommand.Create(
  const APlayer: TCardGamePlayer);
begin
  inherited Create;
  FPlayer := APlayer;
end;

procedure TCalcScoreOfPlayedCardsCommand.Execute(const AGame: TCardGame);
begin
  inherited;
  Assert(Assigned(FPlayer), PLAYER_NOT_ASSIGNED);
  FPlayedCardScore := Player.PlayedCards.CardsScore;
end;

{ TCalcWinnerPlayerOfHand }

constructor TCalcWinnerPlayerOfHand.Create(
  const AFirstPlayerOfHand: TCardGamePlayer);
begin
  inherited Create;
  FFirstPlayerOfHand := AFirstPlayerOfHand;
end;

procedure TCalcWinnerPlayerOfHand.Execute(const AGame: TCardGame);
begin
  inherited;
  Assert(Assigned(FFirstPlayerOfHand), PLAYER_NOT_ASSIGNED);
  FWinnerPlayer := Game.CalcWinnerPlayerOfHand(FFirstPlayerOfHand);
end;

{ TPickCardFromDeck }

constructor TPickCardFromDeck.Create(const APlayer: TCardGamePlayer;
  const AMode: TPickCardMode);
begin
  inherited Create;
  FPlayer := APlayer;
  FMode := AMode;
end;

procedure TPickCardFromDeck.Execute(const AGame: TCardGame);
begin
  inherited;
  Assert(Assigned(FPlayer), PLAYER_NOT_ASSIGNED);
  FPickedCard := Game.MoveCardFromDeckToPlayer(FPlayer.HandledCards,
    FMode);
end;

{ TMoveCardFromDeckToTable }

constructor TMoveCardFromDeckToTable.Create(
  const AMode: TPickCardMode; const AState: TCardGameState);
begin
  inherited Create;
  FMode := AMode;
  FState := AState;
end;

procedure TMoveCardFromDeckToTable.Execute(const AGame: TCardGame);
begin
  inherited;
  FMovedCard := Game.MoveCardFromDeckToTable(FMode, FState);
end;

{ TCardGameEventsList }

{ TCreateCardGame }

constructor TCreateCardGame.Create(const AEngine: TCardGameEngine;
  const ARules: TCardGameRules);
begin
  inherited Create;
  FRules := ARules;
  FGame := TCardGame.Create(AEngine, FRules);
  AEngine.Game := FGame;
end;

initialization
  RegisterClassToSerialize('TCardGameCommand', TCardGameCommand);
  RegisterClassToSerialize('TCardGamePlayerAction', TCardGamePlayerAction);
  RegisterClassToSerialize('TSelectCardToPlayAction', TSelectCardToPlayAction);
  RegisterClassToSerialize('TCalcWinnerPlayerOfHand', TCalcWinnerPlayerOfHand);
  RegisterClassToSerialize('TStartNewMatchCommand', TStartNewMatchCommand);
  RegisterClassToSerialize('TAddPlayerToGameCommand', TAddPlayerToGameCommand);
  RegisterClassToSerialize('TSelectNextDealerCommand', TSelectNextDealerCommand);
  RegisterClassToSerialize('TSelectNextPlayerCommand', TSelectNextPlayerCommand);
  RegisterClassToSerialize('TPickCardFromDeck', TPickCardFromDeck);
  RegisterClassToSerialize('TMoveCardFromDeckToTable', TMoveCardFromDeckToTable);
  RegisterClassToSerialize('TMoveCardCommand', TMoveCardCommand);
  RegisterClassToSerialize('TDealCardToPlayerCommand', TDealCardToPlayerCommand);
  RegisterClassToSerialize('TPlayCardFromPlayerCommand', TPlayCardFromPlayerCommand);
  RegisterClassToSerialize('TCalcTableCardsScoreCommand', TCalcTableCardsScoreCommand);
  RegisterClassToSerialize('TShuffleMainDeckCommand', TShuffleMainDeckCommand);

end.
