{******************************************************************************}
{                                                                              }
{ CardGames.Model:                                                             }
{ Model of Card Games                                                          }
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
unit CardGames.Model;

interface

uses
  System.Generics.Collections
  , System.Generics.Defaults
  , System.SysUtils
  , CardGames.Types
  ;

type
  //Forward declarations
  TCardGameElement = class;

  //Main Classes of Model
  TCardGame = class;
  TCardGameRules = class;
  TCardGameCard = class;
  TCardGamePlayer = class;
  TCardGameTeam = class;
  TCardGameTable = class;
  TCardGameDeck = class;

  //Group of Cards, for Move management
  TCardGameCardsGroup = class;
  TCardGameTableCards = class;
  TCardGamePlayerCards = class;
  TCardGameDeckCards = class;

  // Classes of
  TCardGameRulesClass = Class of TCardGameRules;
  TCardGameClass = Class of TCardGame;
  TCardGameCardClass = Class of TCardGameCard;
  TCardGamePlayerClass = Class of TCardGamePlayer;
  TCardGameTeamClass = Class of TCardGameTeam;
  TCardGameTableClass = Class of TCardGameTable;

  /// <summary>A List of Players of type TCardGamePlayer</summary>
  TCardGamePlayers = TList<TCardGamePlayer>;

  /// <summary>A List of Cards of type TCardGameCard</summary>
  TCardGameCards = TList<TCardGameCard>;

  /// <summary>A List of Teams of a TCardGame</summary>
  TCardGameTeams = TList<TCardGameTeam>;

  /// <summary>
  ///  A generic class of an element of the Model for a Card Game
  ///  with a Unique identifier
  /// </summary>
  TCardGameElement = class(TInterfacedObject)
    FId: string;
  protected
    constructor Create;
  public
    property Id: string read FId write FId;
  end;

  /// <summary>
  ///  A base Class of the CardGame Rules that defines
  ///  the Game Title, the Deck Type and the number of Players
  /// </summary>
  TCardGameRules = class(TCardGameElement)
  private
    FGameTitle: TGameTitle;
    FDescription: TGameDescription;
    FInstructions: TGameInstructions;
    FPlayersRotation: TPlayersRotationType;
    FPlayersCountType: TPlayersCountType;
    FPlayerTypes: TPlayerTypes;
    FTeamsCount: Integer;
    FDeckType: TCardDeckType;
    procedure SetPlayersRotation(const ARotation: TPlayersRotationType);
    procedure SetDeckType(const ADeckType: TCardDeckType);
    procedure SetPlayersCountType(const AValue: TPlayersCountType);
    procedure SetTeamsCount(const AValue: Integer);
    function GetPlayersCount: Integer;
    procedure SetPlayerTypes(const AValue: TPlayerTypes);
  protected
    /// <summary>
    ///  In descendant class you must implement this procedure
    ///  to initialize base game rules and other specific rules
    /// </summary>
    procedure InitRules(out AGameTitle: TGameTitle;
      out ADeckType: TCardDeckType;
      out APlayersCountType: TPlayersCountType); virtual; abstract;
    /// <summary>
    ///  The Calculation of the Score of a Card in the Game Context
    ///  used to calculate the Score of Handled, or Collected Cards
    /// </summary>
    function ScoreForCard(const ACard: TCardGameCard): Single; virtual;
    /// <summary>
    ///  The Score of a Card Played by a Player in the Game Context
    ///  used to calculate the Winner of the Hand
    /// </summary>
    function ScoreForCardPlayed(const APlayer: TCardGamePlayer;
      const ACard: TCardGameCard): Single; virtual;
    /// <summary>
    ///  The Comparison of two Cards of two Players to determinate
    ///  the Winner Player. Player1 has played before Player2.
    ///  Returns the WinnerPlayer
    /// </summary>
    function WinnerPlayerByCard(const APlayer1, APlayer2: TCardGamePlayer;
      const ACard1, ACard2: TCardGameCard): TCardGamePlayer; virtual;
    /// <summary>The Title of the Card Game</summary>
    property GameTitle: TGameTitle read FGameTitle;
    /// <summary>The Type of count of Players of the Game</summary>
    property PlayersCountType: TPlayersCountType read FPlayersCountType write SetPlayersCountType;
    /// <summary>The Types of Players available in the engine (human or IA)</summary>
    property PlayersTypes: TPlayerTypes read FPlayerTypes write SetPlayerTypes;
    /// <summary>The count of Teams of the Game: if Zero the Game is for individual opponents</summary>
    property TeamsCount: Integer read FTeamsCount write SetTeamsCount;
    /// <summary>The type of Rotation for a Game with Turns</summary>
    property PlayersRotation: TPlayersRotationType read FPlayersRotation write SetPlayersRotation;
    /// <summary>The type of the Deck for a Game</summary>
    property DeckType: TCardDeckType read FDeckType write SetDeckType;
    /// <summary>The Description of the Card Game</summary>
    property Description: TGameDescription read FDescription write FDescription;
    /// <summary>The Instructions of the Card Game</summary>
    property Instructions: TGameInstructions read FInstructions write FInstructions;
  public
    /// <summary>
    ///  Base Constructor for a TCardGameRules
    /// </summary>
    constructor Create;
    /// <summary>
    ///  function to check if an Engine can start a new Match
    /// </summary>
    function CanStartNewMatch(const AGame: TCardGame): Boolean;
    /// <summary>
    ///  function to check if a Game is Finished
    /// </summary>
    function GameIsFinished(const AGame: TCardGame): Boolean;
    /// <summary>
    ///  function to check if a Player can Play a Card based on Game Rules
    /// </summary>
    function CanPlayCard(const APlayer: TCardGamePlayer;
      const APlayerCardGroup: TCardGamePlayerCards; const ACard: TCardGameCard): boolean; virtual;
    /// <summary>
    ///  function to check if a Player can Pick a Card based on Game Rules
    /// </summary>
    function CanPickCard(const APlayer: TCardGamePlayer;
      const ADeckCardGroup: TCardGameDeckCards; const ACard: TCardGameCard): boolean; virtual;
    /// <summary>
    ///  function to check if a Card on the Table can be collected by a Player
    /// </summary>
    function CanCollectCard(const APlayer: TCardGamePlayer;
      const ACardGroup: TCardGameTableCards; const ACard: TCardGameCard): boolean; virtual;
    /// <summary>The Players count of the Game</summary>
    property PlayersCount: Integer read GetPlayersCount;
  end;

  /// <summary>
  /// A Card of a Deck of a Card Game
  /// </summary>
  TCardGameCard = class(TCardGameElement)
  private
    //Owner of the Card
    FDeck: TCardGameDeck;
    FSuit: TCardGameSuit;
    FValue: TCardGameValue;
    FState: TCardGameState;
    FHandlerGroup: TCardGameCardsGroup;
    procedure SetState(const AValue: TCardGameState);
    function GetScore: Single;
    /// <summary>
    ///  Constructor of the CardGame Card
    ///  Only a CardGameDeck can create a CardGame Card
    /// </summary>
    constructor Create(const AOwnerDeck: TCardGameDeck;
      const ASuit: TCardGameSuit;
      const AValue: TCardGameValue;
      const AState: TCardGameState = csFaceDown);
    /// <summary>
    ///  The only way to move a card from a group to another
    /// </summary>
    procedure MoveTo(const AFromGroup, ATargetGroup: TCardGameCardsGroup);
  public
    destructor Destroy; override;
    procedure FlipCardOnTable;
    property Deck: TCardGameDeck read FDeck;
    property Suit: TCardGameSuit read FSuit;
    property Value: TCardGameValue read FValue;
    property State: TCardGameState read FState write SetState default csFaceDown;
    property Score: Single read GetScore;
  end;

  /// <summary>
  ///  A generic Group of Cards
  /// </summary>
  TCardGameCardsGroup = class(TCardGameElement)
  private
    FOwner: TCardGameElement;
    //Cards of the Group
    FCards: TCardGameCards;
  protected
    procedure SortAscending;
    procedure SortDescending;
    /// <summary>
    ///  Constructor of the CardGame Card Group
    ///  Only a Class inside this unit can create a CardGame Group
    /// </summary>
    constructor Create(const AOwner: TCardGameElement);
  public
    procedure Shuffle;
    destructor Destroy; override;
    function RandomSelect: TCardGameCard;
    property Cards: TCardGameCards read FCards;
  end;

  /// <summary>
  ///  The CardGameTableCards, a special Group of Cards owned by the TCardGameTable
  ///  inherits from TCardGameCardsGroup to manage Moving a Card from
  ///  a group to another, for example from a Player to the cards
  ///  visible on the Table
  /// </summary>
  TCardGameTableCards = class(TCardGameCardsGroup)
  private
    //Owner of the Group of Cards when is a CardTable
    FOwnerTable: TCardGameTable;
    function GetOwnerTable: TCardGameTable;
    function GetCardGame: TCardGame;
    function CalculateScore: Single;
  protected
    property OwnerTable: TCardGameTable read GetOwnerTable;
    property CardGame: TCardGame read GetCardGame;
  public
    constructor Create(const AOwner: TCardGameTable);
    property CardsScore: Single read CalculateScore;
  end;

  /// <summary>
  ///  The Table of a Card Game, containing the Cards on it
  /// </summary>
  TCardGameTable = class(TCardGameElement)
  private
    /// <summary>Reference to the Card Game</summary>
    FCardGame: TCardGame;
    /// <summary>
    ///  References to the Cards present on the Table
    ///  inherits from TCardGameTableCards to manage Moving a Card from
    ///  a group to another, for example from the Player to the Table
    /// </summary>
    FCardsOnTable: TCardGameTableCards;
    FCardsDiscarded: TCardGameTableCards;
    /// <summary>
    ///  Constructor of the CardGame Table
    ///  Only a CardGame can create a CardGame Table
    /// </summary>
    constructor Create(const AOwner: TCardGame);
  protected
    property CardGame: TCardGame read FCardGame;
  public
    destructor Destroy; override;
    property CardsOnTable: TCardGameTableCards read FCardsOnTable;
    property CardsDiscarded: TCardGameTableCards read FCardsDiscarded;
  end;

  /// <summary>
  ///  The CardGameDeckCards, a special Group of Cards owned by the TCardGameDeck
  ///  inherits from TCardGameCardsGroup to manage Moving a Card from
  ///  a group to another, for example Picking a Card from a Deck
  ///  to a Player
  /// </summary>
  TCardGameDeckCards = class(TCardGameCardsGroup)
  private
    //Owner of the Group of Cards when is a CardDeck
    FOwnerDeck: TCardGameDeck;
    function GetOwnerDeck: TCardGameDeck;
  protected
    property OwnerDeck: TCardGameDeck read GetOwnerDeck;
  public
    constructor Create(const AOwner: TCardGameDeck);
  end;

  /// <summary>
  ///  The Deck, a special Group of Cards owned by the a TCardGame
  ///  that contains Two series of CardGroup:
  ///  - FaceDownCards: the "facedown" cards that can be Pickable by a Player
  ///  - FaceUpCards: the "faceup" cards that can be Pickable by a Player
  /// </summary>
  TCardGameDeck = class(TCardGameElement)
  private
    FOwnerCardGame: TCardGame;
    FDeckType: TCardDeckType;
    FAllCards: TCardGameDeckCards;
    FMainCards: TCardGameDeckCards;
    FDiscardedCards: TCardGameDeckCards;
    procedure GenerateDeck(const AType: TCardDeckType);
    function GetCardGame: TCardGame;
    procedure CreateNewCard(const ASuit: TCardGameSuit;
      const AValue: TCardGameValue);
    procedure ClearCards;
  protected
    property OwnerCardGame: TCardGame read GetCardGame;
  public
    constructor Create(const AOwner: TCardGame;
      const AType: TCardDeckType);
    destructor Destroy; override;
    function IsEmpty: Boolean;
    property MainCards: TCardGameDeckCards read FMainCards;
    property DiscardedCards: TCardGameDeckCards read FDiscardedCards;
    property DeckType: TCardDeckType read FDeckType;
  end;

  /// <summary>
  ///  The PlayerCards, a special Group of Cards owned by a CardPlayer
  ///  inherits from TCardGameCardsGroup to manage Moving a Card from
  ///  a group to another, for example from the Deck to the Handled
  ///  cards of a Player
  /// </summary>
  TCardGamePlayerCards = class(TCardGameCardsGroup)
  private
    //Owner of the Group of Cards when is a CardPlayer
    FOwnerPlayer: TCardGamePlayer;
    function GetOwnerPlayer: TCardGamePlayer;
    function GetCardGame: TCardGame;
    function CalculateScore: Single;
  protected
    property OwnerPlayer: TCardGamePlayer read GetOwnerPlayer;
    property CardGame: TCardGame read GetCardGame;
  public
    constructor Create(const AOwner: TCardGamePlayer);
    function ContainsCard(const ACard: TCardGameCard): boolean;
    property CardsScore: Single read CalculateScore;
  end;

  /// <summary>
  ///  A Player present in a Table of a Card Game
  /// </summary>
  TCardGamePlayer = class(TCardGameElement)
  private
    //Owner of the Player
    FCardGame: TCardGame;
    FPlayerType: TPlayerType;
    FState: TPlayerState;
    FPlayerName: TCardPlayerName;
    FHandledCards: TCardGamePlayerCards;
    FPlayedCards: TCardGamePlayerCards;
    FCollectedCards: TCardGamePlayerCards;
    procedure SetPlayerType(const AValue: TPlayerType);
    procedure SetCardPlayerName(const AValue: TCardPlayerName);
    /// <summary>
    ///  Constructor of the CardGame Player
    ///  Only a CardGame can create a CardGame Player
    /// </summary>
    constructor Create(const ACardGame: TCardGame);
    procedure SetPlayerState(const AValue: TPlayerState);
  protected
    property CardGame: TCardGame read FCardGame;
  public
    destructor Destroy; override;

    /// <summary>State Info for Pickable Cards In Deck by the Player</summary>
    function AllPickableCardsCount: Integer;
    function IsPickableCard(const ADeckCardsGroup: TCardGameDeckCards;
      const ACard: TCardGameCard): Boolean;
    function PickableCardsCount(const ADeckCardsGroup: TCardGameDeckCards): Integer;

    /// <summary>State Info for Collectible Cards by the Player</summary>
    function CollectibleTableCardsCount: Integer;
    function CollectibleCardsCount(const ATableCardGroup: TCardGameTableCards) : Integer;
    function IsCollectibleCard(const ATableCardsGroup: TCardGameTableCards;
      const ACard: TCardGameCard): Boolean;

    /// <summary>State Info for Playable Cards by the Player</summary>
    function AllPlayableCardsCount: Integer;
    function IsPlayableCard(const APlayerCardsGroup: TCardGamePlayerCards;
      const ACard: TCardGameCard): Boolean;
    function PlayableCardsCount(const APlayerCardsGroup: TCardGamePlayerCards): Integer;

    /// <summary>Pick a Card from Deck that moves cards</summary>
    function PickCardFromDeck(const AMode: TPickCardMode = pcFromTop): TCardGameCard;
    procedure PlayCard(const ACard: TCardGameCard;
      const AState: TCardGameState = csFaceUp);
    procedure CollectCardFromTable(const ACard: TCardGameCard;
      const AState: TCardGameState = csFaceDown);

    property PlayerType: TPlayerType read FPlayerType write SetPlayerType;
    property State: TPlayerState read FState write SetPlayerState;
    property Name: TCardPlayerName read FPlayerName write SetCardPlayerName;
    property HandledCards: TCardGamePlayerCards read FHandledCards;
    property CollectedCards: TCardGamePlayerCards read FCollectedCards;
    property PlayedCards: TCardGamePlayerCards read FPlayedCards;
  end;

  /// <summary>
  ///  The Team is a List of Players inside a TCardGame
  /// </summary>
  TCardGameTeam = class(TCardGameElement)
  private
    FOwner: TCardGame;
    FPlayers: TCardGamePlayers;
  public
    constructor Create(const AOwner: TCardGame);
    destructor Destroy; override;
    procedure AddPlayer(const APlayer: TCardGamePlayer);
    procedure RemovePlayer(const APlayer: TCardGamePlayer);
    property Players: TCardGamePlayers read FPlayers;
  end;

  /// <summary>
  ///  The base class of a Card Game with Table, Players, Teams and Cards
  ///  An instanca of a TCardGame contains the actual state of the Game
  ///  managed by the CardGameEngine
  /// </summary>
  TCardGame = class(TCardGameElement)
  private
    //A reference to GameRules
    FGameRulesRef: TCardGameRules;

    //Sub-Objects
    FCardTable: TCardGameTable;
    FPlayers: TCardGamePlayers;
    FDeck: TCardGameDeck;
    FTeams: TCardGameTeams;

    FCurrentDealer: TCardGamePlayer;
    FCurrentPlayer: TCardGamePlayer;
    procedure SetCardTable(const AValue: TCardGameTable);
    function DeckIsEmpty: Boolean;

    /// <summary>Pick a Card from the Deck</summary>
    function PickCardFromDeck(const AMode: TPickCardMode = pcFromTop): TCardGameCard;

    /// <summary>Pick a number of Cards from the Deck</summary>
    procedure PickCardsFromDeck(const ANumCards: Integer;
      const ACards: TCardGameCardsGroup;
      const AMode: TPickCardMode = pcFromTop;
      const AState: TCardGameState = csFaceUp);

  public
    /// <summary>Generic method to Move a Card from a Group to Another</summary>
    procedure MoveCard(const AFromGroup, AToGroup: TCardGameCardsGroup;
      const ACard: TCardGameCard; const AState: TCardGameState = csFaceUp);
    /// <summary>Generic method to Move a Group of Card from a Group to Another</summary>
    procedure MoveCards(const AFromGroup, AToGroup: TCardGameCardsGroup;
      const ACards: TCardGameCards; const AState: TCardGameState = csFaceUp);

    /// <summary>Move a single Card from the Deck to a Player</summary>
    function MoveCardFromDeckToPlayer(const APlayerCards: TCardGamePlayerCards;
      const AMode: TPickCardMode = pcFromTop;
      const AState: TCardGameState = csFaceUp): TCardGameCard;

    /// <summary>Move a single Card from the Main Deck to the Table</summary>
    function MoveCardFromMainDeckToTable(const ATableGroup: TCardGameCardsGroup;
      const AMode: TPickCardMode = pcFromTop;
      const AState: TCardGameState = csFaceUp): TCardGameCard;

    /// <summary>Move a single Card from the Deck to the Table</summary>
    function MoveCardFromDeckToTable(
      const AMode: TPickCardMode = pcFromTop;
      const AState: TCardGameState = csFaceUp): TCardGameCard;

    /// <summary>Move a single Card from a Player to the Table</summary>
    procedure MoveCardFromPlayerToTable(const APlayerCards: TCardGamePlayerCards;
      const ATableGroup: TCardGameCardsGroup; const ACard: TCardGameCard;
      const AState: TCardGameState = csFaceUp);

    /// <summary>Move a single Card from a Player to the Table</summary>
    procedure MoveCardFromTableToPlayer(const ATableGroup: TCardGameCardsGroup;
      const APlayerCards: TCardGamePlayerCards;
      const ACard: TCardGameCard);

    /// <summary>Move a List of Cards from the Deck to a Player</summary>
    procedure MoveCardsFromDeckToPlayer(const ANumCards: Integer;
      const APlayerCards: TCardGamePlayerCards;
      const AMode: TPickCardMode = pcFromTop);

    /// <summary>Move a List of Cards from the Deck to the Table</summary>
    procedure MoveCardsFromDeckToTable(const ANumCards: Integer;
      const ATableGroup: TCardGameCardsGroup;
      const AMode: TPickCardMode = pcFromTop;
      const AState: TCardGameState = csFaceUp);

    /// <summary>Move a List of Cards from a Player to the Table</summary>
    procedure MoveCardsFromPlayerToTable(const APlayerCards: TCardGamePlayerCards;
      const ATableGroup: TCardGameCardsGroup; const ACards: TCardGameCards;
      const AState: TCardGameState = csFaceUp);

    /// <summary>Move a List of Cards from the Table to a Player</summary>
    procedure MoveCardsFromTableToPlayer(const ATableGroup: TCardGameCardsGroup;
      const APlayerCards: TCardGamePlayerCards; const ACards: TCardGameCards);

    /// <summary>
    ///  Deal a number of Cards present in the Deck to
    ///  the Players of the Game
    /// </summary>
    procedure DealCardsToPlayers(const ANumCards: Integer;
      const AOneByOne: Boolean = True;
      const AMode: TPickCardMode = pcFromTop);

    /// <summary>Shuffle the Main Deck cards present in the Deck</summary>
    function ShuffleMainDeck: TCardGameDeckCards; virtual;

    /// <summary>The Title of the Game</summary>
    function GetTitle: TGameTitle;

    /// <summary>The short Description of the Game</summary>
    function GetDescription: TGameDescription;

    /// <summary>The Instructions of the Game</summary>
    function GetInstructions: TGameInstructions;

    /// <summary>The Calculation of the Score of a Card in the Game Context</summary>
    function ScoreForCard(const ACard: TCardGameCard): Single; virtual;

    /// <summary>Count Players in AState (default Active Players)</summary>
    function GetPlayersCount(const AStates: TPlayerStates = [psActive]) : Integer;

    /// <summary>Select a Player Randomly</summary>
    function SelectRandomPlayer(
      const AStates: TPlayerStates = [psActive]): Boolean;

    /// <summary>Select a Player Randomly</summary>
    function SelectRandomDealer(
      const AStates: TPlayerStates = [psActive]): Boolean;

    /// <summary>
    ///  Select the next Player based on PlayerRotation
    ///  that have the State required (by default Active Players)
    /// </summary>
    function SelectNextPlayerByRotation(var APlayer: TCardGamePlayer;
      const AStates: TPlayerStates = [psActive]): Boolean;
    /// <summary>
    ///  Select the Player at the Right of the Player
    ///  that have the State required (by default Active Players)
    /// </summary>
    function SelectPlayerAtRight(var APlayer: TCardGamePlayer;
      const AStates: TPlayerStates = [psActive]): Boolean;
    /// <summary>
    ///  Select the Player at the Left of the Player
    ///  that have the State required (by default Active Players)
    /// </summary>
    function SelectPlayerAtLeft(var APlayer: TCardGamePlayer;
      const AStates: TPlayerStates = [psActive]): Boolean;

    constructor Create(const AOwner: TCardGameElement;
      const ACardGameRules: TCardGameRules);
    destructor Destroy; override;

    /// <summary>Adds a Player to a Game</summary>
    function AddPlayer(const AName: TCardPlayerName;
      const AType: TPlayerType = ptHuman): TCardGamePlayer;

    /// <summary>Clear and Free the Players List</summary>
    procedure ClearAndFreePlayers;

    /// <summary>Clear and Free the Teams List</summary>
    procedure ClearAndFreeTeams;

    /// <summary>
    ///  Select the Dealer for a new Game.
    ///  The first is selected randomly
    ///  the next one based on PlayersRotation
    /// </summary>
    procedure SelectNextDealer(const AStartingFrom: TCardGamePlayer;
      const AStates: TPlayerStates = [psActive]);

    /// <summary>
    ///  Select next Player based on PlayersRotation.
    ///  The first is selected randomly
    ///  the next one based on PlayersRotation
    /// </summary>
    procedure SelectNextPlayer(const AStartFrom: TCardGamePlayer;
      const AStates: TPlayerStates = [psActive]);

    /// <summary>Functions to check if there are cards to play</summary>
    function PlaybleCardsByPlayersCount: Integer; virtual;
    /// <summary>Functions to check if there are cards to collect</summary>
    function CollectibleCardsOnTableCount: Integer; virtual;
    /// <summary>Functions to check if there are cards in Deck to Pickup</summary>
    function PickableCardsInDeckCount: Integer; virtual;
    /// <summary>Calculate the Winner Player of Hand
    ///  Comparing Score of Played Cards based on GameRules
    /// </summary>
    function CalcWinnerPlayerOfHand(
      const AFirstPlayerOfHand: TCardGamePlayer): TCardGamePlayer;

    /// <summary>Rules for the current Game</summary>
    property GameRules: TCardGameRules read FGameRulesRef write FGameRulesRef;
    property Title: TGameTitle read GetTitle;
    property Description: TGameDescription read GetDescription;
    property Instructions: TGameInstructions read GetInstructions;

    property CardTable: TCardGameTable read FCardTable write SetCardTable;
    property Players: TCardGamePlayers read FPlayers;
    property Deck: TCardGameDeck read FDeck;
    property Teams: TCardGameTeams read FTeams;

    property CurrentDealer: TCardGamePlayer read FCurrentDealer;
    property CurrentPlayer: TCardGamePlayer read FCurrentPlayer;
  end;

implementation

uses
  CardGames.Consts
  , CardGames.Utils
  , CardGames.JSONUtils
  ;

{ TCardGameElement }

constructor TCardGameElement.Create;
begin
  inherited Create;
  FId := TGuid.NewGuid.ToString;
end;

{ TCardPlayer }

constructor TCardGamePlayer.Create(const ACardGame: TCardGame);
begin
  inherited Create;
  FCardGame := ACardGame;
  FHandledCards := TCardGamePlayerCards.Create(Self);
  FPlayedCards := TCardGamePlayerCards.Create(Self);
  FCollectedCards := TCardGamePlayerCards.Create(Self);
  FState := psActive;
end;

destructor TCardGamePlayer.Destroy;
begin
  FreeAndNil(FHandledCards);
  FreeAndNil(FPlayedCards);
  FreeAndNil(FCollectedCards);
  inherited;
end;

function TCardGamePlayer.PickCardFromDeck(
  const AMode: TPickCardMode = pcFromTop): TCardGameCard;
begin
  Result := FCardGame.MoveCardFromDeckToPlayer(HandledCards, AMode);
end;

procedure TCardGamePlayer.CollectCardFromTable(const ACard: TCardGameCard;
  const AState: TCardGameState);
begin
  FCardGame.MoveCard(CollectedCards, FCardGame.CardTable.CardsOnTable, ACard);
  ACard.State := AState;
end;

function TCardGamePlayer.CollectibleCardsCount(
  const ATableCardGroup: TCardGameTableCards) : Integer;
var
  LCard: TCardGameCard;
begin
  Result := 0;
  for LCard in ATableCardGroup.Cards do
    if IsCollectibleCard(ATableCardGroup, LCard) then
      Inc(Result);
end;

function TCardGamePlayer.PlayableCardsCount(
  const APlayerCardsGroup: TCardGamePlayerCards): Integer;
var
  LCard: TCardGameCard;
begin
  Result := 0;
  for LCard in APlayerCardsGroup.Cards do
    if IsPlayableCard(APlayerCardsGroup, LCard) then
      Inc(Result);
end;

function TCardGamePlayer.IsPlayableCard(
  const APlayerCardsGroup: TCardGamePlayerCards;
  const ACard: TCardGameCard): boolean;
begin
  Result := CardGame.GameRules.CanPlayCard(Self, APlayerCardsGroup, ACard);
end;

function TCardGamePlayer.IsCollectibleCard(const ATableCardsGroup: TCardGameTableCards;
  const ACard: TCardGameCard): Boolean;
begin
  Result := CardGame.GameRules.CanCollectCard(Self, ATableCardsGroup, ACard);
end;

function TCardGamePlayer.AllPickableCardsCount: Integer;
begin
  Result := PickableCardsCount(CardGame.Deck.MainCards) +
    PickableCardsCount(CardGame.Deck.DiscardedCards);
end;

function TCardGamePlayer.AllPlayableCardsCount: Integer;
begin
  Result := PlayableCardsCount(HandledCards) +
    PlayableCardsCount(CollectedCards) +
    PlayableCardsCount(PlayedCards);
end;

function TCardGamePlayer.IsPickableCard(
  const ADeckCardsGroup: TCardGameDeckCards;
  const ACard: TCardGameCard): Boolean;
begin
  Result := CardGame.GameRules.CanPickCard(Self, ADeckCardsGroup, ACard);
end;

function TCardGamePlayer.PickableCardsCount(
  const ADeckCardsGroup: TCardGameDeckCards): Integer;
var
  LCard: TCardGameCard;
begin
  Result := 0;
  for LCard in ADeckCardsGroup.Cards do
    if IsPickableCard(ADeckCardsGroup, LCard) then
      Inc(Result);
end;

function TCardGamePlayer.CollectibleTableCardsCount: Integer;
begin
  Result := CollectibleCardsCount(CardGame.CardTable.CardsOnTable);
end;

procedure TCardGamePlayer.PlayCard(const ACard: TCardGameCard;
  const AState: TCardGameState = csFaceUp);
begin
  FCardGame.MoveCard(HandledCards, PlayedCards, ACard);
  ACard.State := AState;
end;

procedure TCardGamePlayer.SetCardPlayerName(const AValue: TCardPlayerName);
begin
  FPlayerName := AValue;
end;

procedure TCardGamePlayer.SetPlayerState(const AValue: TPlayerState);
begin
  FState := AValue;
end;

procedure TCardGamePlayer.SetPlayerType(const AValue: TPlayerType);
begin
  FPlayerType := AValue;
end;

{ TCardGame }

constructor TCardGame.Create(const AOwner: TCardGameElement;
  const ACardGameRules: TCardGameRules);
begin
  inherited Create;
  //a Reference to the Card Game Rules
  FGameRulesRef := ACardGameRules;
  //Creates CardTable
  FCardTable := TCardGameTable.Create(Self);
  //Creates Players List for the game
  FPlayers := TCardGamePlayers.Create;
  //Creates Teams List for the game
  FTeams := TCardGameTeams.Create;
  //Creates The Deck for the game
  FDeck := TCardGameDeck.Create(Self, ACardGameRules.DeckType);
end;

destructor TCardGame.Destroy;
begin
  FreeAndNil(FCardTable);
  if Assigned(FTeams) then
    ClearAndFreeTeams;
  if Assigned(FPlayers) then
    ClearAndFreePlayers;
  FreeAndNil(FDeck);
  inherited;
end;

function TCardGame.AddPlayer(const AName: TCardPlayerName;
  const AType: TPlayerType = ptHuman): TCardGamePlayer;
begin
  Result := TCardGamePlayer.Create(Self);
  try
    Result.PlayerType := AType;
    Result.Name := AName;
    FPlayers.Add(Result);

    //Check for maximum "active" Player Count
    if Players.Count > GameRules.PlayersCount then
      Result.State := psSpectator
    else
      Result.State := psActive;

  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TCardGame.CalcWinnerPlayerOfHand(
  const AFirstPlayerOfHand: TCardGamePlayer): TCardGamePlayer;
var
  LPlayer: TCardGamePlayer;
begin
  Result := FCurrentPlayer;
  for LPlayer in Players do
  begin
    Result := GameRules.WinnerPlayerByCard(Result, LPlayer,
      Result.PlayedCards.Cards[0], LPlayer.PlayedCards.Cards[0]);
  end;
end;

procedure TCardGame.ClearAndFreePlayers;
var
  LPlayer: TCardGamePlayer;
begin
  for LPlayer in FPlayers do
    FreeAndNil(LPlayer);
  FreeAndNil(FPlayers);
end;

procedure TCardGame.ClearAndFreeTeams;
var
  LTeam: TCardGameTeam;
begin
  for LTeam in FTeams do
    FreeAndNil(LTeam);
  FreeAndNil(FTeams);
end;

function TCardGame.CollectibleCardsOnTableCount: Integer;
var
  LPlayer: TCardGamePlayer;
begin
  Result := 0;
  for LPlayer in Players do
    Inc(Result, LPlayer.CollectibleTableCardsCount);
end;

procedure TCardGame.DealCardsToPlayers(const ANumCards: Integer;
  const AOneByOne: Boolean; const AMode: TPickCardMode);
var
  I: Integer;
  LPlayer: TCardGamePlayer;
begin
  if AOneByOne then
  begin
    for I := 1 to ANumCards do
      for LPlayer in FPlayers do
        MoveCardFromDeckToPlayer(LPlayer.HandledCards, AMode);
  end
  else
  begin
    for LPlayer in FPlayers do
      for I := 1 to ANumCards do
        MoveCardFromDeckToPlayer(LPlayer.HandledCards, AMode);
  end;
end;

function TCardGame.DeckIsEmpty: Boolean;
begin
  Assert(Assigned(FDeck), DECK_NOT_ASSIGNED);
  Result := FDeck.MainCards.Cards.Count = 0;
end;

function TCardGame.GetTitle: TGameTitle;
begin
  Assert(Assigned(FGameRulesRef), GAME_RULES_NOT_ASSIGNED);
  Result := FGameRulesRef.GameTitle;
end;

function TCardGame.GetDescription: TGameDescription;
begin
  Assert(Assigned(FGameRulesRef), DECK_NOT_ASSIGNED);
  Result := FGameRulesRef.Description;
end;

function TCardGame.GetInstructions: TGameInstructions;
begin
  Assert(Assigned(FGameRulesRef), DECK_NOT_ASSIGNED);
  Result := FGameRulesRef.Instructions;
end;

function TCardGame.GetPlayersCount(const AStates: TPlayerStates = [psActive]): Integer;
var
  LPlayer: TCardGamePlayer;
begin
  Result := 0;
  for LPlayer in FPlayers do
    if LPlayer.State in AStates then
      Inc(Result);
end;

procedure TCardGame.MoveCard(const AFromGroup, AToGroup: TCardGameCardsGroup;
  const ACard: TCardGameCard; const AState: TCardGameState = csFaceUp);
begin
  Assert(Assigned(ACard), CARD_NOT_ASSIGNED);
  ACard.MoveTo(AFromGroup, AToGroup);
end;

function TCardGame.MoveCardFromDeckToPlayer(
  const APlayerCards: TCardGamePlayerCards;
  const AMode: TPickCardMode = pcFromTop;
  const AState: TCardGameState = csFaceUp): TCardGameCard;
begin
  Result := PickCardFromDeck(AMode);
  MoveCard(FDeck.MainCards, APlayerCards, Result);
end;

function TCardGame.MoveCardFromMainDeckToTable(
  const ATableGroup: TCardGameCardsGroup;
  const AMode: TPickCardMode = pcFromTop;
  const AState: TCardGameState = csFaceUp): TCardGameCard;
begin
  Result := PickCardFromDeck(AMode);
  MoveCard(FDeck.MainCards, ATableGroup, Result, AState);
end;

function TCardGame.MoveCardFromDeckToTable(
  const AMode: TPickCardMode = pcFromTop;
  const AState: TCardGameState = csFaceUp): TCardGameCard;
begin
  Result := PickCardFromDeck(AMode);
  MoveCard(FDeck.MainCards, FCardTable.FCardsOnTable, Result, AState);
end;

procedure TCardGame.MoveCardFromPlayerToTable(
  const APlayerCards: TCardGamePlayerCards;
  const ATableGroup: TCardGameCardsGroup;
  const ACard: TCardGameCard;
  const AState: TCardGameState = csFaceUp);
begin
  MoveCard(APlayerCards, ATableGroup, ACard, AState);
end;

procedure TCardGame.MoveCardFromTableToPlayer(
  const ATableGroup: TCardGameCardsGroup;
  const APlayerCards: TCardGamePlayerCards;
  const ACard: TCardGameCard);
begin
  MoveCard(ATableGroup, APlayerCards, ACard);
end;

procedure TCardGame.MoveCards(const AFromGroup, AToGroup: TCardGameCardsGroup;
  const ACards: TCardGameCards;
  const AState: TCardGameState = csFaceUp);
var
  LCard: TCardGameCard;
begin
  for LCard in ACards do
    MoveCard(AFromGroup, AToGroup, LCard, AState);
end;

procedure TCardGame.MoveCardsFromDeckToPlayer(const ANumCards: Integer;
  const APlayerCards: TCardGamePlayerCards;
  const AMode: TPickCardMode = pcFromTop);
begin
  PickCardsFromDeck(ANumCards, APlayerCards, AMode);
end;

procedure TCardGame.MoveCardsFromDeckToTable(const ANumCards: Integer;
  const ATableGroup: TCardGameCardsGroup;
  const AMode: TPickCardMode = pcFromTop;
  const AState: TCardGameState = csFaceUp);
begin
  PickCardsFromDeck(ANumCards, ATableGroup, AMode, AState);
end;

procedure TCardGame.MoveCardsFromPlayerToTable(
  const APlayerCards: TCardGamePlayerCards;
  const ATableGroup: TCardGameCardsGroup;
  const ACards: TCardGameCards;
  const AState: TCardGameState = csFaceUp);
var
  LCard: TCardGameCard;
begin
  for LCard in ACards do
    MoveCard(APlayerCards, ATableGroup, LCard);
end;

procedure TCardGame.MoveCardsFromTableToPlayer(
  const ATableGroup: TCardGameCardsGroup;
  const APlayerCards: TCardGamePlayerCards;
  const ACards: TCardGameCards);
var
  LCard: TCardGameCard;
begin
  for LCard in ACards do
    MoveCard(ATableGroup, APlayerCards, LCard);
end;

function TCardGame.ScoreForCard(const ACard: TCardGameCard): Single;
begin
  Result := FGameRulesRef.ScoreForCard(ACard);
end;

function TCardGame.SelectNextPlayerByRotation(
  var APlayer: TCardGamePlayer;
  const AStates: TPlayerStates = [psActive]): Boolean;
begin
  Result := False;
  if FGameRulesRef.PlayersRotation = ttRandom then
    SelectRandomPlayer(AStates)
  else if FGameRulesRef.PlayersRotation = ttClockwiseRotation then
    Result := SelectPlayerAtLeft(APlayer, AStates)
  else if FGameRulesRef.PlayersRotation = ttCounterclockwiseRotation then
    Result := SelectPlayerAtRight(APlayer, AStates);
end;

function TCardGame.SelectPlayerAtLeft(var APlayer: TCardGamePlayer;
  const AStates: TPlayerStates): Boolean;
var
  LIndex: Integer;
  LPlayer: TCardGamePlayer;
begin
  LIndex := FPlayers.IndexOf(APlayer);
  Repeat
    if LIndex = 0 then
      LIndex := FPlayers.Count-1
    else
      Dec(LIndex);
    LPlayer := FPlayers[LIndex];
  Until LPlayer.State in AStates;
  Result := LPlayer <> APlayer;
  if Result then
    APlayer := LPlayer;
end;

function TCardGame.SelectPlayerAtRight(var APlayer: TCardGamePlayer;
  const AStates: TPlayerStates): Boolean;
var
  LIndex: Integer;
  LPlayer: TCardGamePlayer;
begin
  LIndex := FPlayers.IndexOf(APlayer);
  Repeat
    if LIndex = FPlayers.Count-1 then
      LIndex := 0
    else
      Inc(LIndex);
    LPlayer := FPlayers[LIndex];
  Until LPlayer.State in AStates;
  Result := LPlayer <> APlayer;
  if Result then
    APlayer := LPlayer;
end;

function TCardGame.SelectRandomPlayer(
  const AStates: TPlayerStates = [psActive]): Boolean;
var
  LPlayer: TCardGamePlayer;
begin
  Assert(FPlayers.Count > 0, PLAYERS_NOT_DEFINED);
  if GetPlayersCount(AStates) > 0 then
  begin
    Repeat
      LPlayer := FPlayers[Random(FPlayers.Count)];
    Until LPlayer.State in AStates;
  end
  else
    LPlayer := nil;
  Result := Assigned(LPlayer);
  if Result then
    FCurrentPlayer := LPlayer;
end;

function TCardGame.SelectRandomDealer(
  const AStates: TPlayerStates = [psActive]): Boolean;
var
  LDealer: TCardGamePlayer;
begin
  Assert(FPlayers.Count > 0, PLAYERS_NOT_DEFINED);
  if GetPlayersCount(AStates) > 0 then
  begin
    Repeat
      LDealer := FPlayers[Random(FPlayers.Count)];
    Until LDealer.State in AStates;
  end
  else
    LDealer := nil;
  Result := Assigned(LDealer);
  if Result then
    FCurrentDealer := LDealer;
end;

procedure TCardGame.SetCardTable(const AValue: TCardGameTable);
begin
  FCardTable := AValue;
end;

function TCardGame.ShuffleMainDeck: TCardGameDeckCards;
begin
  Result := FDeck.MainCards;
  Result.Shuffle;
end;

function TCardGame.PickableCardsInDeckCount: Integer;
var
  LPlayer: TCardGamePlayer;
begin
  Result := 0;
  for LPlayer in Players do
    Inc(Result, LPlayer.AllPickableCardsCount);
end;

function TCardGame.PickCardFromDeck(const AMode: TPickCardMode = pcFromTop): TCardGameCard;
begin
  Assert(not DeckIsEmpty, DECK_IS_EMPTY);
  //Select the card based on Mode
  case AMode of
    pcFromTop:
      Result := FDeck.MainCards.Cards.First;
    pcFromBottom:
      Result := FDeck.MainCards.Cards.Last;
  else // pcRandom:
      Result := FDeck.MainCards.RandomSelect;
  end;
end;

procedure TCardGame.PickCardsFromDeck(const ANumCards: Integer;
  const ACards: TCardGameCardsGroup;
  const AMode: TPickCardMode = pcFromTop;
  const AState: TCardGameState = csFaceUp);
var
  I: Integer;
begin
  for I := 1 to ANumCards do
    MoveCard(FDeck.MainCards, ACards, PickCardFromDeck(AMode), AState);
end;

function TCardGame.PlaybleCardsByPlayersCount: Integer;
var
  LPlayer: TCardGamePlayer;
begin
  Result := 0;
  for LPlayer in Players do
    Inc(Result, LPlayer.AllPlayableCardsCount);
end;

procedure TCardGame.SelectNextPlayer(const AStartFrom: TCardGamePlayer;
  const AStates: TPlayerStates = [psActive]);
begin
  if not Assigned(AStartFrom) then
    SelectRandomPlayer(AStates)
  else
  begin
    FCurrentPlayer := AStartFrom;
    SelectNextPlayerByRotation(FCurrentPlayer, AStates);
  end;
end;

procedure TCardGame.SelectNextDealer(const AStartingFrom: TCardGamePlayer;
  const AStates: TPlayerStates = [psActive]);
begin
  if not Assigned(FCurrentDealer) then
    SelectRandomDealer(AStates)
  else
  begin
    FCurrentPlayer := AStartingFrom;
    SelectNextPlayerByRotation(FCurrentDealer);
  end;
end;

{ TCardGameTable }

constructor TCardGameTable.Create(const AOwner: TCardGame);
begin
  inherited Create;
  FCardGame := AOwner;
  FCardsOnTable := TCardGameTableCards.Create(Self);
  FCardsDiscarded := TCardGameTableCards.Create(Self);
end;

destructor TCardGameTable.Destroy;
begin
  FreeAndNil(FCardsOnTable);
  FreeAndNil(FCardsDiscarded);
  inherited;
end;

{ TCardGameCardsGroup }

constructor TCardGameCardsGroup.Create(const AOwner: TCardGameElement);
begin
  inherited Create;
  FOwner := AOwner;
  FCards := TCardGameCards.Create;
end;

destructor TCardGameCardsGroup.Destroy;
begin
  FreeAndNil(FCards);
  inherited;
end;

function TCardGameCardsGroup.RandomSelect: TCardGameCard;
begin
  Assert(FCards.Count > 0, CARD_NOT_AVAILABLE);
  Result := FCards[Random(FCards.Count)];
end;

procedure TCardGameCardsGroup.Shuffle;
begin
  FCards.Sort(TComparer<TCardGameCard>.Construct(
    function(const L,R : TCardGameCard) : Integer
    begin
      //returns -1, 0 or 1 to Shuffle
      result := -1 + Random(3);
    end));
end;

procedure TCardGameCardsGroup.SortAscending;
begin
  FCards.Sort(TComparer<TCardGameCard>.Construct(
    function(const L,R : TCardGameCard) : Integer
    begin
      result := Round(L.Score - R.Score);
    end));
end;

procedure TCardGameCardsGroup.SortDescending;
begin
  FCards.Sort(TComparer<TCardGameCard>.Construct(
    function(const L,R : TCardGameCard) : Integer
    begin
      result := Round(R.Score - L.Score);
    end));
end;

{ TCardGameTableCards }

function TCardGameTableCards.CalculateScore: Single;
var
  LCard: TCardGameCard;
begin
  Result := 0;
  for LCard in Cards do
    Result := Result + CardGame.ScoreForCard(LCard);
end;

constructor TCardGameTableCards.Create(const AOwner: TCardGameTable);
begin
  inherited Create(AOwner);
  FOwnerTable := AOwner;
end;

function TCardGameTableCards.GetCardGame: TCardGame;
begin
  Result := FOwnerTable.CardGame;
end;

function TCardGameTableCards.GetOwnerTable: TCardGameTable;
begin
  Result := FOwnerTable;
end;

{ TCardGameDeck }

constructor TCardGameDeck.Create(const AOwner: TCardGame;
  const AType: TCardDeckType);
begin
  inherited Create;
  FAllCards := TCardGameDeckCards.Create(Self);
  FMainCards := TCardGameDeckCards.Create(Self);
  FDiscardedCards := TCardGameDeckCards.Create(Self);
  FOwnerCardGame := AOwner;
  GenerateDeck(AType);
end;

procedure TCardGameDeck.CreateNewCard(const ASuit: TCardGameSuit;
  const AValue: TCardGameValue);
var
  LNewCard: TCardGameCard;
begin
  LNewCard := TCardGameCard.Create(Self, ASuit, AValue);
  FAllCards.Cards.Add(LNewCard);
  FMainCards.Cards.Add(LNewCard);
end;

destructor TCardGameDeck.Destroy;
begin
  ClearCards;
  FreeAndNil(FAllCards);
  FreeAndNil(FMainCards);
  FreeAndNil(FDiscardedCards);
  inherited;
end;

procedure TCardGameDeck.ClearCards;
var
  LCard: TCardGameCard;
begin
  for LCard in FAllCards.Cards do
    LCard.Free;
  FAllCards.Cards.Clear;
end;

procedure TCardGameDeck.GenerateDeck(const AType: TCardDeckType);
var
  LSuit: TCardGameSuit;
  LValue: TCardGameValue;
  LAcceptCard: Boolean;
  LDeckCount: Integer;
begin
  for LDeckCount := 1 to 2 do
  begin
    if (LDeckCount > 1) and not (AType in [cd108FullSuitsPlusJokers, cd104FullSuits]) then
      Break;
    for LSuit := Low(TCardGameSuit) to High(TCardGameSuit) do
    begin
      for LValue := Low(TCardGameValue) to High(TCardGameValue) do
      begin
        case AType of
          cd54FullSuitsPlusJokers, cd108FullSuitsPlusJokers: LAcceptCard := LValue <> cvHide;
          cd52FullSuits, cd104FullSuits: LAcceptCard := not (LValue in [cvHide, cvJoker]);
          cd40UsingJ_Q_K: LAcceptCard := not (LValue in [cvHide, cvJoker, cvEight, cvNine, cvTen]);
          cd40Using8_9_10: LAcceptCard := not (LValue in [cvHide, cvJoker, cvJack, cvQueen, cvKing]);
        else
          LAcceptCard := False;
        end;
        if LAcceptCard then
        begin
          //Create the Card accepted to the Deck
          CreateNewCard(LSuit, LValue);
        end;
      end;
    end;
  end;
  FDeckType := AType;
end;

function TCardGameDeck.IsEmpty: Boolean;
begin
  Result := FMainCards.Cards.IsEmpty;
end;

function TCardGameDeck.GetCardGame: TCardGame;
begin
  Result := FOwnerCardGame;
end;

{ TCardGameCard }

constructor TCardGameCard.Create(
  const AOwnerDeck: TCardGameDeck;
  const ASuit: TCardGameSuit;
  const AValue: TCardGameValue;
  const AState: TCardGameState = csFaceDown);
begin
  inherited Create;
  FSuit := ASuit;
  FValue := AValue;
  FState := AState;
  FDeck := AOwnerDeck;
  //The Card is always created inside a Deck
  FHandlerGroup := FDeck.MainCards;
end;

destructor TCardGameCard.Destroy;
begin
  ;
  inherited;
end;

procedure TCardGameCard.FlipCardOnTable;
begin
  if FState = csFaceDown then
    FState := csFaceUp else
    FState := csFaceDown;
end;

function TCardGameCard.GetScore: Single;
begin
  Result := FDeck.OwnerCardGame.ScoreForCard(Self);
end;

procedure TCardGameCard.MoveTo(
  const AFromGroup, ATargetGroup: TCardGameCardsGroup);
begin
  //The only way to move a card from a group to another
  Assert(AFromGroup = FHandlerGroup, CARD_NOT_AVAILABLE);
  FHandlerGroup.Cards.Remove(Self);
  try
    ATargetGroup.Cards.Add(Self);
  except
    FHandlerGroup.Cards.Add(Self);
    raise;
  end;
  FHandlerGroup := ATargetGroup;
end;

procedure TCardGameCard.SetState(const AValue: TCardGameState);
begin
  FState := AValue;
end;

{ TCardGameRules }

function TCardGameRules.CanCollectCard(const APlayer: TCardGamePlayer;
  const ACardGroup: TCardGameTableCards; const ACard: TCardGameCard): boolean;
begin
  //By default a card can be Collected by any Player if the Card is FaceUp on Table
  //In descendant Games Rules you can specify if a Player can Collect the Card
  Result := ACard.State = csFaceUp;
end;

function TCardGameRules.CanPickCard(const APlayer: TCardGamePlayer;
  const ADeckCardGroup: TCardGameDeckCards;
  const ACard: TCardGameCard): boolean;
begin
  //By default a card can be picked if the Group is the Main Group of Deck
  //In descendant Games Rules you can specify if a Player can Pick a Discarded Card
  Result := ADeckCardGroup = APlayer.CardGame.Deck.MainCards;
end;

function TCardGameRules.CanPlayCard(const APlayer: TCardGamePlayer;
  const APlayerCardGroup: TCardGamePlayerCards; const ACard: TCardGameCard): boolean;
begin
  //By default a card can be played if the Group is the Handled Group of Cards
  //In descendant Games Rules you can specify if a Player can Play a Collected Card
  Result := APlayerCardGroup = APlayer.HandledCards;
end;

function TCardGameRules.CanStartNewMatch(const AGame: TCardGame): Boolean;
begin
  //By default a Match for a Game can start when all Players
  //are present and are ready to Play
  Result := AGame.GetPlayersCount = PlayersCount;
end;

constructor TCardGameRules.Create;
begin
  inherited Create;
  //FOwner := AOwner;
  InitRules(FGameTitle, FDeckType, FPlayersCountType);
end;

function TCardGameRules.GameIsFinished(const AGame: TCardGame): Boolean;
begin
  //By default a Game is finished when Player don't have Cards To Play
  //and a Table don't have a Card to Collect
  //and a Deck don't have a Card to PickUp
  Result := (AGame.PlaybleCardsByPlayersCount = 0) and
    (AGame.CollectibleCardsOnTableCount = 0) and
    (AGame.PickableCardsInDeckCount = 0);
end;

function TCardGameRules.GetPlayersCount: Integer;
begin
  Result := Ord(FPlayersCountType);
end;

function TCardGameRules.ScoreForCard(const ACard: TCardGameCard): Single;
begin
  //By default the Score of a Card is its Value
  Result := Ord(ACard.Value);
end;

function TCardGameRules.ScoreForCardPlayed(const APlayer: TCardGamePlayer;
  const ACard: TCardGameCard): Single;
begin
  //By default Score of a Card Played is the same Score of a Card
  Result := ScoreForCard(ACard);
end;

function TCardGameRules.WinnerPlayerByCard(
  const APlayer1, APlayer2: TCardGamePlayer;
  const ACard1, ACard2: TCardGameCard): TCardGamePlayer;
begin
  //By default the Winner is the Card with High Score
  //or the Player that Played first.
  //In case of same score, wins the Player1 (who played first)
  if ScoreForCardPlayed(APlayer2, ACard2) > ScoreForCardPlayed(APlayer1, ACard1) then
    Result := APlayer2
  else
    Result := APlayer1;
end;

procedure TCardGameRules.SetDeckType(const ADeckType: TCardDeckType);
begin
  FDeckType := ADeckType;
end;

procedure TCardGameRules.SetPlayersCountType(const AValue: TPlayersCountType);
begin
  FPlayersCountType := AValue;
end;

procedure TCardGameRules.SetPlayerTypes(const AValue: TPlayerTypes);
begin
  FPlayerTypes := AValue;
end;

procedure TCardGameRules.SetPlayersRotation(const ARotation: TPlayersRotationType);
begin
  FPlayersRotation := ARotation;
end;

procedure TCardGameRules.SetTeamsCount(const AValue: Integer);
begin
  FTeamsCount := AValue;
end;

{ TCardGamePlayerCards }

function TCardGamePlayerCards.CalculateScore: Single;
var
  LCard: TCardGameCard;
begin
  Result := 0;
  for LCard in Cards do
    Result := Result + CardGame.ScoreForCard(LCard);
end;

function TCardGamePlayerCards.ContainsCard(const ACard: TCardGameCard): boolean;
begin
  Result := FCards.Contains(ACard);
end;

constructor TCardGamePlayerCards.Create(const AOwner: TCardGamePlayer);
begin
  inherited Create(AOwner);
  FOwnerPlayer := AOwner;
end;

function TCardGamePlayerCards.GetCardGame: TCardGame;
begin
  Result := OwnerPlayer.CardGame;
end;

function TCardGamePlayerCards.GetOwnerPlayer: TCardGamePlayer;
begin
  Result := FOwnerPlayer;
end;

{ TCardGameTeam }

procedure TCardGameTeam.AddPlayer(const APlayer: TCardGamePlayer);
begin
  FPlayers.Add(APlayer);
end;

constructor TCardGameTeam.Create(const AOwner: TCardGame);
begin
  inherited Create;
  FOwner := AOwner;
end;

destructor TCardGameTeam.Destroy;
begin
  ;
  inherited;
end;

procedure TCardGameTeam.RemovePlayer(const APlayer: TCardGamePlayer);
begin
  Assert(FPlayers.Contains(APlayer), PLAYER_NOT_IN_TEAM);
  FPlayers.Remove(APlayer);
end;

{ TCardGameDeckCards }

constructor TCardGameDeckCards.Create(const AOwner: TCardGameDeck);
begin
  inherited Create(AOwner);
  FOwnerDeck := AOwner;
end;

function TCardGameDeckCards.GetOwnerDeck: TCardGameDeck;
begin
  Result := FOwnerDeck;
end;

initialization
  Randomize;

  RegisterClassToSerialize('TCardGameRules', TCardGameRules);
  RegisterClassToSerialize('TCardGame', TCardGame);
  RegisterClassToSerialize('TCardGamePlayer', TCardGamePlayer);
  RegisterClassToSerialize('TCardGameTable', TCardGameTable);
//  RegisterClassToSerialize('TCardGamePlayers', TCardGamePlayers);

end.
