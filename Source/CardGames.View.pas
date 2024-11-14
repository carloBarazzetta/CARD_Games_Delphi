{******************************************************************************}
{                                                                              }
{ CardGames.View:                                                              }
{ Player View of Card Games Client Server Demo                                 }
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
unit CardGames.View;

interface

uses
  System.Generics.Collections
  , System.Generics.Defaults
  , System.Classes
  , CardGames.Model
  , CardGames.Interfaces
  , CardGames.Observer
  , CardGames.Engine
  ;

type
  TBaseView = class(TInterfacedObject, ICardGameBaseView, ICardGameObserverView)
  private
    FId: string;
    FOwner: TObject;
    //ICardBaseView implementation
    function GetId: string;
  protected
    //ICardGameObserverView implementation
    procedure UpdateView(const AEventData: TCardGameEvent); virtual; abstract;
    procedure AddCard(const ACard: TCardGameCard); virtual; abstract;
    procedure RemoveCard(const ACard: TCardGameCard); virtual; abstract;
  public
    constructor Create(const AOwner: TObject; const AId: string);

    property Id: string read GetId;
  end;

  TPlayerView = class(TBaseView, ICardGamePlayerView)
  private
    FPlayer: TCardGamePlayer;
    //ICardPlayerView implementation
    function GetOpponentsCount: Integer;
    function GetPlayer: TCardGamePlayer;
  protected
  public
    constructor Create(const AOwner: TCardGamePlayer; const AId: string);
    property Player: TCardGamePlayer read GetPlayer;
    property OpponentsCount: Integer read GetOpponentsCount;
  end;

  TTableView = class(TBaseView, ICardGameTableView)
  private
    FCardTable: TCardGameTable;
    //ICardTableView implementation
    procedure AddCard(const ACard: TCardGameCard); override;
    procedure RemoveCard(const ACard: TCardGameCard); override;
    function GetCardTable: TCardGameTable;
  protected
  public
    constructor Create(const AOwner: TCardGameTable; const AId: string);
  property
    CardTable: TCardGameTable read GetCardTable;
  end;

  TGameView = class(TBaseView)
  private
    FPlayerViews: TList<TPlayerView>;
    FTableView: TTableView;
    procedure UpdateView(Sender: TObject);
    constructor Create;
    procedure SetupUI;
    procedure DisplayPlayerHand(const APlayer: TCardGamePlayer;
      const APanel: TPlayerView);
    procedure DisplayTable;
  end;

implementation

{ TBaseView }

constructor TBaseView.Create(const AOwner: TObject; const AId: string);
begin
  inherited Create;
  FOwner := AOwner;
  FId := AId;
end;

function TBaseView.GetId: string;
begin
  Result := FId;
end;

{ TPlayerView }

constructor TPlayerView.Create(const AOwner: TCardGamePlayer; const AId: string);
begin
  inherited Create(AOwner, AId);
  FPlayer := AOwner;
end;

function TPlayerView.GetPlayer: TCardGamePlayer;
begin
  Result := FPlayer;
end;

function TPlayerView.GetOpponentsCount: Integer;
begin
  Result := FPlayer.CardGame.Players.Count -1;
end;

{ TTableView }

constructor TTableView.Create(const AOwner: TCardGameTable; const AId: string);
begin
  inherited Create(AOwner, AId);
  FCardTable := AOwner;
end;

procedure TTableView.AddCard(const ACard: TCardGameCard);
begin
  FCardTable.CardsOnTable.Cards.Add(ACard);
end;

function TTableView.GetCardTable: TCardGameTable;
begin
  Result := FCardTable;
end;

procedure TTableView.RemoveCard(const ACard: TCardGameCard);
begin
  FCardTable.CardsOnTable.Cards.Remove(ACard);
end;

{ TGameView }

constructor TGameView.Create;
begin
  inherited Create(nil, '');
end;

procedure TGameView.SetupUI;
begin
  // Configura UI per giocatori e tavolo
end;

procedure TGameView.UpdateView(Sender: TObject);
begin
  // Aggiorna la visualizzazione dei giocatori e del tavolo
(*
  DisplayPlayerHand(FController.CurrentPlayer,
    FPlayerViews[FController.CurrentPlayerIndex]);
*)
  DisplayTable;
end;

procedure TGameView.DisplayPlayerHand(const APlayer: TCardGamePlayer;
  const APanel: TPlayerView);
begin
  // Mostra le carte del giocatore
end;

procedure TGameView.DisplayTable;
begin
  // Mostra lo stato del tavolo
end;

end.
