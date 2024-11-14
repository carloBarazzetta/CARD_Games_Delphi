{******************************************************************************}
{                                                                              }
{ CardGames.Render:                                                            }
{ Base Render Classes of Card Games                                            }
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
unit CardGames.Render;

interface

uses
  System.Generics.Collections
  , System.Generics.Defaults
  , System.Classes
  , System.Types
  , CardGames.Model
  , CardGames.ViewModel
  , CardGames.Interfaces
  , CardGames.Observer
  , CardGames.Engine
  ;

type
  TRenderPosition = class(TObject)
    FId: string;
    FPosX, FPosY: Integer;
  public
    function PositionStr: string;
    constructor Create(const AId: string; const APosX, APosY: Integer);
  end;

  TBaseRenderView = class(TInterfacedObject)
  private
    FId: String;
    FView: TBaseView; //The Logical View
  protected
  public
    constructor Create(const AOwner: TBaseView);
    property Id: string read FId;
  end;

  TTableRenderView = class(TBaseRenderView)
  private
    FDeckPosition: TRenderPosition;
    FPlayedCardsPosition: TRenderPosition;
    FRemovedCardsPosition: TRenderPosition;
    FTableView: TTableView;
  public
    constructor Create(AOwner: TTableView);
    property DeckPosition: TRenderPosition read FDeckPosition;
    property PlayedCardsPosition: TRenderPosition read FPlayedCardsPosition;
    property RemovedCardsPosition: TRenderPosition read FRemovedCardsPosition;
    property TableView: TTableView read FTableView;
  end;

  TPlayerRenderView = class(TBaseRenderView, ICardGameBaseView, ICardGameObserverView)
  private
    FId: string;
    FPlayerView: TPlayerView;
    FHandPosition: TRenderPosition;
    FOpponentHandPositions: TList<TRenderPosition>;
    //Implementation of ICardGameTableView
    function GetId: string;
    //Implementation of ICardGameTableView
    procedure AddCard(const ACard: TCardGameCard);
    procedure RemoveCard(const ACard: TCardGameCard);
  public
    procedure UpdateView(const AEventData: TCardGameEvent);
    constructor Create(AOwner: TPlayerView);
    property PlayerView: TPlayerView read FPlayerView;
    property HandPosition: TRenderPosition read FHandPosition;
    property OpponentHandPositions: TList<TRenderPosition> read FOpponentHandPositions;
  end;

  TCardRenderMode = (rmVisible, rmBack, rmInvisible);

  TRenderingEngine = class
  private
    FScreenWidth, FScreenHeight: Integer;
  protected
    function GetRealPosition(LogicalPosition: TRenderPosition): TPoint; virtual; abstract;
    procedure RenderCardAtPosition(const ACard: TCardGameCard;
      const APosition: TRenderPosition; const AMode: TCardRenderMode); virtual; Abstract;
  public
    constructor Create(const AScreenWidth, AScreenHeight: Integer);
    procedure RenderTable(const ARenderTableView: TTableRenderView);
    procedure RenderPlayerView(const ARenderPlayerView: TPlayerRenderView);
  end;

implementation

uses
  System.SysUtils
  , CardGames.Consts
  , CardGames.Utils
  ;

{ TTableRenderView }

constructor TTableRenderView.Create(AOwner: TTableView);
begin
  inherited Create(AOwner);
  FTableView := AOwner;
  FDeckPosition := TRenderPosition.Create('DeckPosition', 10, 10);
  FPlayedCardsPosition := TRenderPosition.Create('PlaydCards', 50, 50);
  FRemovedCardsPosition := TRenderPosition.Create('RemovedCards', 90, 90);
end;

constructor TRenderPosition.Create(const AId: string;
  const APosX, APosY: Integer);
begin
  inherited Create;
  FId := AId;
  FPosX := APosX;
  FPosX := APosY;
end;

function TRenderPosition.PositionStr: string;
begin
  Result := Format('%s (%d, %d)', [FId, FPosX, FPosY]);
end;

{ TPlayerRenderView }

procedure TPlayerRenderView.AddCard(const ACard: TCardGameCard);
begin

end;

constructor TPlayerRenderView.Create(AOwner: TPlayerView);
var
  I: Integer;
begin
  inherited Create(AOwner);
  FId := CreateNewGUID;
  FPlayerView := AOwner;
  FHandPosition := TRenderPosition.Create('HandledCards', 10, 150);
  for I := 1 to FPlayerView.OpponentsCount do
    FOpponentHandPositions.add(TRenderPosition.Create(Format('Opponents[%d]',[I]),10*I, 10));
end;

function TPlayerRenderView.GetId: string;
begin
  Result := FId;
end;

procedure TPlayerRenderView.RemoveCard(const ACard: TCardGameCard);
begin

end;

procedure TPlayerRenderView.UpdateView;
begin
  ;
end;

{ TRenderingEngine }

constructor TRenderingEngine.Create(const AScreenWidth, AScreenHeight: Integer);
begin
  inherited Create;
  FScreenWidth := AScreenWidth;
  FScreenHeight := AScreenHeight;
end;

procedure TRenderingEngine.RenderTable(const ARenderTableView: TTableRenderView);
var
  LCard: TCardGameCard;
begin
  // Renderizza le carte del mazzo
  for LCard in ARenderTableView.TableView.CardTable.CardGame.Deck.Cards do
    RenderCardAtPosition(LCard, ARenderTableView.DeckPosition, rmBack);
  // Renderizza le carte del tavolo visibili a tutti
  for LCard in ARenderTableView.TableView.CardTable.CardsOnTable.Cards do
    RenderCardAtPosition(LCard, ARenderTableView.DeckPosition, rmVisible);
end;

procedure TRenderingEngine.RenderPlayerView(
  const ARenderPlayerView: TPlayerRenderView);
var
  LCard: TCardGameCard;
  LOppoentHandPosition: TRenderPosition;
begin
  // Renderizza le carte del giocatore (visibili)
  for LCard in ARenderPlayerView.PlayerView.Player.HandledCards.Cards do
    RenderCardAtPosition(LCard, ARenderPlayerView.HandPosition, rmVisible);
  // Renderizza le carte degli avversari (invisibili)
(*
  for LOppoentHandPosition in ARenderPlayerView.OpponentHandPositions do
  begin
    for LCard in LOpponent.Cards do
    RenderCardAtPosition(LCard, ARenderPlayerView.OpponentHandPositions, rmBack);
  end;
*)
end;

{ TBaseRenderView }

constructor TBaseRenderView.Create(const AOwner: TBaseView);
begin
  inherited Create;
  FId := CreateNewGUID;
end;

end.
