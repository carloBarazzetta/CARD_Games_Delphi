{******************************************************************************}
{                                                                              }
{ CardGames.Engine:                                                            }
{ Base Engine for Card Games                                                   }
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
{  Unless required by applicable law or agreed to in writing, software         }
{  distributed under the License is distributed on an "AS IS" BASIS,           }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    }
{  See the License for the specific language governing permissions and         }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}
unit CardGames.Engine;

interface

uses
  System.SysUtils
  , System.Generics.Collections
  , System.Generics.Defaults
  , System.Classes
  , CardGames.Types
  , CardGames.Model
  , CardGames.Interfaces
  ;

type
  //Forward declarations
  TCardGameEngine = class;
  TAIPlayerEngine = class;
  TCardGameTurn = class;
  TCardGamePhase = class;
  TCardGameMatch = class;

  TAIPlayerEngineClass = class of TAIPlayerEngine;
  TCardGameEngineClass = class of TCardGameEngine;
  TCardGameTurnClass = class of TCardGameTurn;

  /// <summary>A List of Turns of a TCardGameEngine</summary>
  TCardGameTurns = TObjectList<TCardGameTurn>;

  /// <summary>A List of Phases of a TCardGameEngine</summary>
  TCardGamePhases = TObjectList<TCardGamePhase>;

  /// <summary>A List of Matches of a TCardGameEngine</summary>
  TCardGameMatches = TObjectList<TCardGameMatch>;

  TPlayerProc = reference to procedure(APlayer: TCardGamePlayer);

  /// <summary>
  ///  A base Class of a Game Match of a TCardGameEngine with Matches
  /// </summary>
  TCardGameMatch = class
  private
    FEngine: TCardGameEngine;
    FMatchIndex: Integer;
    FStartDealer: TCardGamePlayer;
    constructor Create(const AOwner: TCardGameEngine;
      const AMatchIndex: Integer);
  protected
    procedure StartMatch(const AStartDealer: TCardGamePlayer); virtual;
  end;

  /// <summary>
  ///  A base Class of a Game Phases of a TCardGameEngine with Turns
  /// </summary>
  TCardGamePhase = class
  private
    FEngine: TCardGameEngine;
    FPhaseIndex: Integer;
    constructor Create(const AOwner: TCardGameEngine;
      const APhaseIndex: Integer);
  protected
    procedure Execute; virtual;
  end;

  /// <summary>
  ///  A base Class of a Turn of a TCardGameEngine with Rotation Turns
  /// </summary>
  TCardGameTurn = class(TCardGameElement)
  private
    FEngine: TCardGameEngine;
    FTurnIndex: Integer;
    FCurrentPlayer: TCardGamePlayer;
    FTurnStatus: TTurnStatus;
    constructor Create(const AOwner: TCardGameEngine;
      const ATurnIndex: Integer;
      const ACurrentPlayer: TCardGamePlayer); reintroduce;
  protected
    procedure Execute; virtual;
  public
    destructor Destroy; override;
    property TurnIndex: Integer read FTurnIndex;
    property CurrentPlayer: TCardGamePlayer read FCurrentPlayer;
    property TurnStatus: TTurnStatus read FTurnStatus;
  end;

  /// <summary>
  ///  A base Class of an Artificial Intelligent Engine that can impersonate
  ///   a Player in the context of the CardGameEngine based on CardGameRules
  /// </summary>
  TAIPlayerEngine = class(TCardGameElement)
  private
    FEngine: TCardGameEngine;
    function GetCardsOnTable: TCardGameTableCards;
  protected
    constructor Create(const AEngine: TCardGameEngine); reintroduce;
    function SelectCardToPlay(const APlayer: TCardGamePlayer): TCardGameCard; virtual;
    function SelectCardToGetFromTable(const APlayer: TCardGamePlayer): TCardGameCard; virtual;
    property CardsOnTable: TCardGameTableCards read GetCardsOnTable;
  public
  end;

  TNotifySerializedCommand = procedure(const ACommand: string) of Object;
  TNotifyCardGameEvent = procedure(const ACommand: TCardGameElement) of Object;

  /// <summary>
  ///  A base Class of a CardGame Engine that manage a Card Game instance,
  ///  perform Actions to the Game and manage Games Turns
  /// </summary>
  TCardGameEngine = class(TCardGameElement)
  private
    FGameRules: TCardGameRules;
    FGame: TCardGame;
    FAIPlayerEngine: TAIPlayerEngine;
    FCommandHistory: ICardGameCommandList;
    FCurrentCommand: ICardGameCommand;
    FTurns: TCardGameTurns;
    FPhases: TCardGamePhases;
    FMatches: TCardGameMatches;
    FCurrentMatch: TCardGameMatch;
    FCurrentPhase: TCardGamePhase;
    FCurrentTurn: TCardGameTurn;
    FMaxMatchCount: Integer;
    FOnNewCardGameEvent: TNotifyCardGameEvent;
    function GetDescription: TGameDescription;
    function GetInstructions: TGameInstructions;
    function GetTitle: TGameTitle;
    procedure StopCurrentMatch;
  protected
    class function GetGameVariantsCount: Integer; virtual;
    class function GetGameVariantName(const AIndex: Integer): string; virtual;
    function GetAIPlayerEngineClass: TAIPlayerEngineClass; virtual;
    procedure ForEachPlayerUsignRotation(
      const APlayerProc: TPlayerProc;
      const AStates: TPlayerStates = [psActive]);

    /// <summary>Select the First Dealer, randomly</summary>
    procedure SelectFirstDealerRandomly;

    /// <summary>Select the First Player after the Delaer</summary>
    procedure SelectFirstPlayerAfterDealer;

    /// <summary>Select the First Player, randomly</summary>
    procedure SelectFirstPlayerRandomly;

    /// <summary>
    ///  Deal ANumCards to every Player based on PlayersRotation
    /// </summary>
    procedure DealCardsToPlayers(const ANumCards: Integer;
      const APlayerToStart: TCardGamePlayer = nil);
    /// <summary>
    ///  Move a Card from Deck to Table
    ///  By default the Card is FacedUp
    /// </summary>
    function MoveCardFromDeckToTable(
      const AMode: TPickCardMode = pcFromTop;
      const AState: TCardGameState = csFaceUp): TCardGameCard;
    /// <summary>
    ///  Calculate the Winner Player of an Hand
    /// </summary>
    function CalcWinnerOfHand: TCardGamePlayer;
    /// <summary>
    ///  Ask to Players to Play ANumCards (by default one card)
    /// </summary>
    procedure AskPlayersToPlayCards(const ANumCards: Integer = 1;
      const APlayerToStart: TCardGamePlayer = nil);
    /// <summary>
    ///  Ask to Game To Shuffle the main Deck
    /// </summary>
    procedure ShuffleMainDeck;
    procedure StartNewMatch; virtual;
    procedure StartNewPhase(ADealer: TCardGamePlayer);
    procedure StartNewTurn(APlayer: TCardGamePlayer);
    procedure PushCommand(const ACommand: ICardGameCommand);
  public
    class procedure FillVariantList(const AList: TStrings);
    class procedure FillOpponentsType(const AList: TStrings);

    procedure InitRules(const ACardGameRulesClass: TCardGameRulesClass); virtual;


    destructor Destroy; override;

    function GetCommandFromIndex(const ACommandIndex: integer): TCardGameElement;
    /// <summary>Returns True if the Engine is ready to start a new Match<summary>
    function CanStartNewMatch: Boolean; virtual;
    /// <summary>Returns True if the Game is finished<summary>
    function IsGameFinished: Boolean; virtual;
    /// <summary>Returns True if the Match is finished<summary>
    function IsMatchFinished: Boolean; virtual;
    /// <summary>Start the Game<summary>
    procedure StartGame;
    /// <summary>Stop the Current Game<summary>
    procedure StopGame;

    function AddPlayerToGame(const AName: TCardPlayerName;
      const AType: TPlayerType): TCardGamePlayer;

    function CanPlayerSeeCard(const APlayer: TCardGamePlayer;
      const ACard: TCardGameCard): Boolean;

    procedure ExecuteCommand(const ACommand: ICardGameCommand);

    property Title: TGameTitle read GetTitle;
    property Description: TGameDescription read GetDescription;
    property Instructions: TGameInstructions read GetInstructions;

    /// <summary>The Calculation of the Score of a Card based on Game Rules<summary>
    function ScoreForCard(const ACard: TCardGameCard): Single; virtual;

    /// <summary>Returns the instance of the Game<summary>
    property Game: TCardGame read FGame write FGame;
    property GameRules: TCardGameRules read FGameRules;
    property Turns: TCardGameTurns read FTurns;
    property AIPlayerEngine: TAIPlayerEngine read FAIPlayerEngine write FAIPlayerEngine;
    property CurrentTurn: TCardGameTurn read FCurrentTurn write FCurrentTurn;
    property CurrentPhase: TCardGamePhase read FCurrentPhase write FCurrentPhase;
    property MaxMatchCount: Integer read FMaxMatchCount write FMaxMatchCount;
    property OnNewCardGameEvent: TNotifyCardGameEvent read FOnNewCardGameEvent write FOnNewCardGameEvent;
  end;

implementation

uses
  CardGames.Consts
  , CardGames.Events
  ;

{ TCardGameEngine }

function TCardGameEngine.AddPlayerToGame(const AName: TCardPlayerName;
  const AType: TPlayerType): TCardGamePlayer;
begin
  //Initialize the AI Engine for AI Players
  if (AType = ptAI) and not assigned(FAIPlayerEngine) then
    FAIPlayerEngine := GetAIPlayerEngineClass.Create(Self);

  //Execute Event to Add a Player to a Game
  ExecuteCommand(TAddPlayerToGameCommand.Create(AName,AType));
  Result := TAddPlayerToGameCommand(FCurrentCommand).AddedPlayer;
end;

function TCardGameEngine.CalcWinnerOfHand: TCardGamePlayer;
begin
  //Calc the Score of Every Player of Played Cards
  ForEachPlayerUsignRotation(
    procedure(APlayer: TCardGamePlayer)
    begin
      ExecuteCommand(TCalcScoreOfPlayedCardsCommand.Create(APlayer));
    end);

  //Calc the Winner Player of the Hand
  ExecuteCommand(TCalcWinnerPlayerOfHand.Create(Game.CurrentPlayer));
  Result := TCalcWinnerPlayerOfHand(FCurrentCommand).WinnerPlayer;
end;

function TCardGameEngine.CanPlayerSeeCard(const APlayer: TCardGamePlayer;
  const ACard: TCardGameCard): Boolean;
begin
  // Verifica se il giocatore è il proprietario della carta o se la carta è visibile sul tavolo
  Result := (APlayer.HandledCards.ContainsCard(ACard)) or (ACard.State = csFaceUp);
end;

procedure TCardGameEngine.InitRules(
  const ACardGameRulesClass: TCardGameRulesClass);
begin
  FMaxMatchCount := 1; //Almost one Match
  FGameRules := ACardGameRulesClass.Create;
  try
    FCommandHistory := TList<ICardGameCommand>.Create;
    FTurns := TCardGameTurns.Create(True);
    FPhases := TCardGamePhases.Create(True);
    FMatches := TCardGameMatches.Create(True);
    ExecuteCommand(TCreateCardGame.Create(Self, FGameRules));
  except
    FreeAndNil(FGameRules);
    raise;
  end;
end;

procedure TCardGameEngine.AskPlayersToPlayCards(
  const ANumCards: Integer = 1;
  const APlayerToStart: TCardGamePlayer = nil);
var
  I: Integer;
begin
  for I := 1 to ANumCards do
  begin
    //Ask to Player to Deal a Card
    ForEachPlayerUsignRotation(
      procedure(APlayer: TCardGamePlayer)
      begin
        ExecuteCommand(TPlayCardFromPlayerCommand.Create(APlayer));
      end
    );
  end;
end;

procedure TCardGameEngine.SelectFirstDealerRandomly;
begin
  //If not passed to command, the First Dealer is calculated Randomly
  ExecuteCommand(TSelectNextDealerCommand.Create(nil));
end;

procedure TCardGameEngine.SelectFirstPlayerAfterDealer;
begin
  //The next Player is the first after the Delaer, based on Rotation
  ExecuteCommand(TSelectNextPlayerCommand.Create(
    Game.CurrentDealer));
end;

procedure TCardGameEngine.SelectFirstPlayerRandomly;
begin
  //If not passed to command, the First Dealer is calculated Randomly
  ExecuteCommand(TSelectNextPlayerCommand.Create(nil));
end;

procedure TCardGameEngine.DealCardsToPlayers(const ANumCards: Integer;
  const APlayerToStart: TCardGamePlayer = nil);
var
  I: Integer;
begin
  for I := 1 to ANumCards do
  begin
    //Deal Cards to Players, starting the APlayer
    ForEachPlayerUsignRotation(
      procedure(APlayer: TCardGamePlayer)
      begin
        ExecuteCommand(TDealCardToPlayerCommand.Create(APlayer));
      end
    );
  end;
end;

destructor TCardGameEngine.Destroy;
begin
  if Assigned(FTurns) then
  begin
    FTurns.Clear;
    FreeAndNil(FTurns);
  end;
  if Assigned(FPhases) then
  begin
    FPhases.Clear;
    FreeAndNil(FPhases);
  end;
  if Assigned(FMatches) then
  begin
    FMatches.Clear;
    FreeAndNil(FMatches);
  end;
  if Assigned(FCommandHistory) then
  begin
    FCommandHistory.Clear;
    FreeAndNil(FCommandHistory);
  end;
  FreeAndNil(FGame);
  FreeAndNil(FGameRules);
  FreeAndNil(FAIPlayerEngine);
  inherited Destroy;
end;

function TCardGameEngine.MoveCardFromDeckToTable(
  const AMode: TPickCardMode; const AState: TCardGameState): TCardGameCard;
begin
  ExecuteCommand(TMoveCardFromDeckToTable.Create(AMode, AState));
  Result := TMoveCardFromDeckToTable(FCurrentCommand).FMovedCard;
end;

procedure TCardGameEngine.ExecuteCommand(
  const ACommand: ICardGameCommand);
begin
  FCurrentCommand := ACommand;
  FCurrentCommand.Execute(Game);
  PushCommand(FCurrentCommand);
  PushCommand(ACommand);
  if Assigned(OnNewCardGameEvent) then
    OnNewCardGameEvent(TCardGameCommand(FCurrentCommand));
end;

class procedure TCardGameEngine.FillOpponentsType(const AList: TStrings);
var
  I: TPlayerType;
begin
  AList.Clear;
  //Fill list with Game Opponents Types Available
  for I := Low(TPlayerType) to High(TPlayerType) do
    AList.Add(APlayerTypeNames[I]);
end;

class procedure TCardGameEngine.FillVariantList(const AList: TStrings);
var
  I: Integer;
begin
  AList.Clear;
  //Fill list with Game Variants
  for I := 0 to GetGameVariantsCount do
    AList.Add(GetGameVariantName(I));
end;

procedure TCardGameEngine.ForEachPlayerUsignRotation(
  const APlayerProc: TPlayerProc;
  const AStates: TPlayerStates = [psActive]);
var
  LSelectedPlayer: TCardGamePlayer;
begin
  Assert(Assigned(APlayerProc), PLAYER_PROC_NOT_ASSIGNED);
  Assert(Assigned(Game.CurrentPlayer), PLAYER_NOT_ASSIGNED);
  LSelectedPlayer := Game.CurrentPlayer;
  repeat
    APlayerProc(LSelectedPlayer);
    FGame.SelectNextPlayerByRotation(LSelectedPlayer, AStates);
  until LSelectedPlayer = Game.CurrentPlayer;
end;

class function TCardGameEngine.GetGameVariantName(const AIndex: Integer): string;
begin
  Result := Self.ClassName;
end;

class function TCardGameEngine.GetGameVariantsCount: Integer;
begin
  Result := 1;
end;

function TCardGameEngine.GetAIPlayerEngineClass: TAIPlayerEngineClass;
begin
  Result := TAIPlayerEngine;
end;

function TCardGameEngine.GetCommandFromIndex(const ACommandIndex: integer): TCardGameElement;
var
  I: Integer;
begin
  Result := nil;
  for I := ACommandIndex to FCommandHistory.Count -1 do
  begin
    if FCommandHistory.Items[I] is TCardGameCommand then
    begin
      Result := TCardGameCommand(FCommandHistory.Items[I]);
      Break;
    end;
  end;
end;

function TCardGameEngine.GetDescription: TGameDescription;
begin
  Result := FGame.Description;
end;

function TCardGameEngine.GetInstructions: TGameInstructions;
begin
  Result := FGame.Instructions;
end;

function TCardGameEngine.GetTitle: TGameTitle;
begin
  Result := FGame.GetTitle;
end;

function TCardGameEngine.IsGameFinished: Boolean;
begin
  Result := FGameRules.GameIsFinished(FGame);
end;

function TCardGameEngine.IsMatchFinished: Boolean;
begin
  Result := (FMaxMatchCount = FMatches.Count) and
    IsGameFinished;
end;

function TCardGameEngine.CanStartNewMatch: Boolean;
begin
  Result := FGameRules.CanStartNewMatch(FGame);
end;

procedure TCardGameEngine.PushCommand(const ACommand: ICardGameCommand);
begin
  //Add new event on the event list
 FCommandHistory.Add(ACommand);
end;

function TCardGameEngine.ScoreForCard(const ACard: TCardGameCard): Single;
begin
  Result := FGame.ScoreForCard(ACard);
end;

procedure TCardGameEngine.ShuffleMainDeck;
begin
  ExecuteCommand(TShuffleMainDeckCommand.Create(Game.Deck.MainCards));
end;

procedure TCardGameEngine.StartGame;
begin
  if FGameRules.CanStartNewMatch(FGame) then
    StartNewMatch;
end;

procedure TCardGameEngine.StopGame;
begin
  StopCurrentMatch;
end;

procedure TCardGameEngine.StopCurrentMatch;
begin
  if Assigned(FCurrentMatch) then
    FCurrentMatch := nil;
end;

procedure TCardGameEngine.StartNewMatch;
begin
  FCurrentMatch := TCardGameMatch.Create(Self, FMatches.Count+1);
  try
    ExecuteCommand(TStartNewMatchCommand.Create(FCurrentMatch));
    FMatches.Add(FCurrentMatch);
  except
    FCurrentMatch.Free;
  end;
end;

procedure TCardGameEngine.StartNewPhase(ADealer: TCardGamePlayer);
begin
  FCurrentPhase := TCardGamePhase.Create(Self, FPhases.Count+1);
  FPhases.Add(FCurrentPhase);
end;

procedure TCardGameEngine.StartNewTurn(APlayer: TCardGamePlayer);
begin
  FCurrentTurn := TCardGameTurn.Create(Self, FTurns.Count+1, APlayer);
  FTurns.Add(FCurrentTurn);
end;

{ TCardGameTurn }

constructor TCardGameTurn.Create(const AOwner: TCardGameEngine;
  const ATurnIndex: Integer; const ACurrentPlayer: TCardGamePlayer);
begin
  FEngine := AOwner;
  FTurnIndex := ATurnIndex;
  FCurrentPlayer := ACurrentPlayer;
  FTurnStatus := tsPending;
end;

destructor TCardGameTurn.Destroy;
begin
  inherited;
end;
procedure TCardGameTurn.Execute;
begin
  ;
end;

{ TCardGamePhase }

constructor TCardGamePhase.Create(const AOwner: TCardGameEngine;
  const APhaseIndex: Integer);
begin
  FEngine := AOwner;
  FPhaseIndex := APhaseIndex;
end;

procedure TCardGamePhase.Execute;
begin
  ;
end;

{ TAIPlayerEngine }

constructor TAIPlayerEngine.Create(const AEngine: TCardGameEngine);
begin
  inherited Create;
  FEngine := AEngine;
end;

function TAIPlayerEngine.GetCardsOnTable: TCardGameTableCards;
begin
  Result := FEngine.FGame.CardTable.CardsOnTable;
end;

function TAIPlayerEngine.SelectCardToGetFromTable(
  const APlayer: TCardGamePlayer): TCardGameCard;
begin
  Result := CardsOnTable.RandomSelect;
end;

function TAIPlayerEngine.SelectCardToPlay(
  const APlayer: TCardGamePlayer): TCardGameCard;
begin
  Result := APlayer.HandledCards.RandomSelect;
end;

{ TCardGameMatch }

constructor TCardGameMatch.Create(const AOwner: TCardGameEngine;
  const AMatchIndex: Integer);
begin
  inherited Create;
  FEngine := AOwner;
  FMatchIndex := AMatchIndex;
end;

procedure TCardGameMatch.StartMatch(const AStartDealer: TCardGamePlayer);
begin
  FStartDealer := AStartDealer;
  FEngine.StartNewPhase(FStartDealer);
end;

end.
