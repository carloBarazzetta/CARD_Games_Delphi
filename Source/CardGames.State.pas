{******************************************************************************}
{                                                                              }
{ CardGames.State:                                                             }
{ State Pattern of Card Games                                                  }
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
unit CardGames.State;

interface

uses
  System.Generics.Collections
  , System.Generics.Defaults
  , CardGames.Model
  , CardGames.Engine
  ;

type
  TGameState = class
  protected
    FEngine: TCardGameEngine;
  public
    constructor Create(const AEngine: TCardGameEngine);
    procedure EnterState; virtual; abstract;
    procedure PickCardFromDeck(const AMode: TPickCardMode); virtual; abstract;
    procedure PlayCard(const ACard: TCardGameCard); virtual; abstract;
    procedure EndTurn; virtual; abstract;
    procedure CalculateScore; virtual; abstract;
  end;

  TGameStateSetup = class(TGameState)
  public
    procedure EnterState; override;
    procedure PickCardFromDeck(const AMode: TPickCardMode); override;
    procedure PlayCard(const ACard: TCardGameCard); override;
    procedure EndTurn; override;
    procedure CalculateScore; override;
  end;

  TGameStatePlayerTurn = class(TGameState)
  public
    procedure EnterState; override;
    procedure PickCardFromDeck(const AMode: TPickCardMode); override;
    procedure PlayCard(const ACard: TCardGameCard); override;
    procedure EndTurn; override;
    procedure CalculateScore; override;
  end;

  TGameStateEndTurn = class(TGameState)
  public
    procedure EnterState; override;
    procedure PickCardFromDeck(const AMode: TPickCardMode); override;
    procedure PlayCard(const ACard: TCardGameCard); override;
    procedure EndTurn; override;
    procedure CalculateScore; override;
  end;

  TGameStateGameOver = class(TGameState)
  public
    procedure EnterState; override;
    procedure PickCardFromDeck(const AMode: TPickCardMode); override;
    procedure PlayCard(const ACard: TCardGameCard); override;
    procedure EndTurn; override;
    procedure CalculateScore; override;
  end;

implementation

{ TGameStateSetup }

procedure TGameStateSetup.PickCardFromDeck(const AMode: TPickCardMode);
begin
  // Nessuna azione in fase di setup
end;

procedure TGameStateSetup.PlayCard(const ACard: TCardGameCard);
begin
  // Nessuna azione in fase di setup
end;

procedure TGameStateSetup.EndTurn;
begin
  // Nessuna azione in fase di setup
end;

procedure TGameStateSetup.EnterState;
begin
//  FController.CardGame.DealCardsToPlayers(5);  // Distribuisce le carte
//  FController.ChangeState(TGameStatePlayerTurn.Create(FController));  // Passa al turno del giocatore
end;

procedure TGameStateSetup.CalculateScore;
begin
  // Nessuna azione in fase di setup
end;

{ TGameStatePlayerTurn }

procedure TGameStatePlayerTurn.EnterState;
begin
  // Visualizza il turno del giocatore nella view
  FController.NotifyObservers(FController.CurrentPlayer);
end;

procedure TGameStatePlayerTurn.PickCardFromDeck(const AMode: TPickCardMode);
begin
  FController.CurrentPlayer.PickCardFromDeck(AMode);
end;

procedure TGameStatePlayerTurn.PlayCard(const ACard: TCardGameCard);
begin
  FController.PlayCard(aCard);
end;

procedure TGameStatePlayerTurn.EndTurn;
begin
  FController.ChangeState(TGameStateEndTurn.Create(FController));  // Passa alla fine del turno
end;

procedure TGameStatePlayerTurn.CalculateScore;
begin
  // Nessuna azione durante il turno del giocatore
end;

{ TGameStateEndTurn }

procedure TGameStateEndTurn.EnterState;
begin
  if FController.IsGameOver then
    FController.ChangeState(TGameStateGameOver.Create(FController))  // Passa alla fine della partita
  else
  begin
    FController.NextTurn;
    FController.ChangeState(TGameStatePlayerTurn.Create(FController));  // Passa al prossimo giocatore
  end;
end;

procedure TGameStateEndTurn.PickCardFromDeck(const AMode: TPickCardMode);
begin
  // Nessuna azione alla fine del turno
end;

procedure TGameStateEndTurn.PlayCard(const ACard: TCardGameCard);
begin
  // Nessuna azione alla fine del turno
end;

procedure TGameStateEndTurn.EndTurn;
begin
  // Nessuna azione alla fine del turno
end;

procedure TGameStateEndTurn.CalculateScore;
begin
  FController.CalculateScore;
end;

{ TGameStateGameOver }

procedure TGameStateGameOver.EnterState;
begin
  FController.CalculateScore;  // Calcola il punteggio finale
  FController.NotifyObservers(FController.CardGame);
end;

procedure TGameStateGameOver.PickCardFromDeck(const AMode: TPickCardMode);
begin
  // Nessuna azione alla fine della partita
end;

procedure TGameStateGameOver.PlayCard(const ACard: TCardGameCard);
begin
  // Nessuna azione alla fine della partita
end;

procedure TGameStateGameOver.EndTurn;
begin
  // Nessuna azione alla fine della partita
end;

procedure TGameStateGameOver.CalculateScore;
begin
  // Già fatto in EnterState
end;

end.
