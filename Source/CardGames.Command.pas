{******************************************************************************}
{                                                                              }
{ CardGames.Command:                                                           }
{ Command Pattern of Card Games                                                }
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
unit CardGames.Command;

interface

uses
  CardGames.Model
  , CardGames.Controller
  , CardGames.View
  , CardGames.Observer
  ;

type
  TPickCardCommand = class(TInterfacedObject, ICardCommand)
  private
    FController: TGameController;
    FPickedCard: TCardGameCard;
    FMode: TPickCardMode;
  public
    constructor Create(const AController: TGameController;
      const AMode: TPickCardMode);
    procedure Execute;
    procedure Undo;
  end;

  TPlayCardCommand = class(TInterfacedObject, ICardCommand)
  private
    FController: TGameController;
    FPlayedCard: TCardGameCard;
  public
    constructor Create(const AController: TGameController;
      const ACard: TCardGameCard);
    procedure Execute;
    procedure Undo;
  end;

  TMoveCardCommand = class(TInterfacedObject, ICardCommand)
  private
    FController: TGameController;
    FCardToMove: TCardGameCard;
    FSourceView: TBaseView;
    FTargetView: TBaseView;
  public
    constructor Create(const AController: TGameController;
      const ACardToMove: TCardGameCard; const ASourceView, ATargetView: TBaseView);
    procedure Execute;
    procedure Undo;
  end;

implementation

{ TPickCardCommand }

constructor TPickCardCommand.Create(const AController: TGameController;
  const AMode: TPickCardMode);
begin
  FController := AController;
  FMode := AMode;
end;

procedure TPickCardCommand.Execute;
begin
  FPickedCard := FController.CurrentPlayer.PickCardFromDeck(FMode);
end;

procedure TPickCardCommand.Undo;
begin
(*
  if Assigned(FPickedCard) then
  begin
    FController.MoveCard(FPickedCard, );
    FController.GameTable.PutCardInDeck(FPickedCard);
  end;
*)
end;

{ TPlayCardCommand }

constructor TPlayCardCommand.Create(const AController: TGameController;
  const ACard: TCardGameCard);
begin
  FController := AController;
  FPlayedCard := ACard;
end;

procedure TPlayCardCommand.Execute;
begin
  FController.CurrentPlayer.PlayCard(FPlayedCard);
end;

procedure TPlayCardCommand.Undo;
begin
  (*
  FController.GameTable.RemoveCardFromTable(FPlayedCard);
  FController.CurrentPlayer.AddCardToHand(FPlayedCard);
  *)
end;

{ TMoveCardCommand }

constructor TMoveCardCommand.Create(const AController: TGameController;
  const ACardToMove: TCardGameCard; const ASourceView, ATargetView: TBaseView);
begin
  FCardToMove := ACardToMove;
  FSourceView := ASourceView;
  FTargetView := ATargetView;
  FController := AController;
end;

procedure TMoveCardCommand.Execute;
begin
  FController.MoveCard(FCardToMove, FSourceView, FTargetView);
end;

procedure TMoveCardCommand.Undo;
begin
  FController.MoveCard(FCardToMove, FTargetView, FSourceView);
end;

end.
