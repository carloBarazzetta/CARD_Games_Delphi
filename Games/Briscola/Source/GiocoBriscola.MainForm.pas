{******************************************************************************}
{                                                                              }
{ GiocoBriscola.MainForm:                                                      }
{ VCL Main View unit                                                           }
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
unit GiocoBriscola.MainForm;
interface

uses
  System.SysUtils
  , System.Variants
  , WinApi.Messages
  , System.Classes
  , System.Types
  , Vcl.Forms
  , CardGames.Vcl.CardTable
  , Vcl.ToolWin
  , System.Math
  , Vcl.Menus
  , Vcl.ComCtrls
  , Vcl.Controls
  , Vcl.StdCtrls
  , CardGames.WinApi.SoundUnit
  , CardGames.Model
  , Briscola.CardGame
  , CardGames.Render
  ;

type
  TMainForm = class(TForm)
    mmMainMenu: TMainMenu;
    miGioco: TMenuItem;
    miOpzioni: TMenuItem;
    ChooseBack1: TMenuItem;
    ChooseDeck1: TMenuItem;
    miAiuto: TMenuItem;
    miNuovaPartita: TMenuItem;
    miEsci: TMenuItem;
    miInformazioni: TMenuItem;
    procedure CardTableCardClickEvent(ACard: TCard; Button: TMouseButton);
    procedure CardTableCardRestoredEvent;
    procedure miEsciClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure miNuovaPartitaClick(Sender: TObject);
    procedure miInformazioniClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
  private
    FBriscolaTable: TCardGameTable;
    FBriscolaGame: TBriscolaGame;
    procedure StartGame;
    procedure NuovaPartita;
    procedure BuildCardTable;
    procedure Inizializzazione;
    procedure DisegnaCartaDelGiocatore(ACard: TCard; APlayer, ACardOfPlayer: Integer);
    procedure GiraCarta(ACard: TCard);
    procedure MuoviCartaDelGiocatore(ACard: TCard; APlayer,
      ACardOfPlayer: Integer);
  public
    { Public declarations }
  end;

const
  cPlayers = 2; // numero di giocatori
  cCardsPerPlayer = 3; // carte per giocatore

  cDeckX = 430; // posizione X del mazzo
  cDeckY = 150; // posizione Y del mazzo

  // spazio tra le carte
  cXCardSpacing = 102;
  cYCardSpacing = 125;

  // posizione della prima carta del giocatore 1
  cCard1X = 10;
  cCard1Y = 10;
  // posizione della prima carta del giocatore 2
  cCard2X = 10;
  cCard2Y = 400;

var
  MainForm: TMainForm;

  gPosition: array[1..cPlayers,1..cCardsPerPlayer] of TPoint; // posizione sullo schermo delle carte da gioco dei giocatori
  gPositionPlayedCards: array[1..cPlayers] of TPoint;
  gHand: array[1..cPlayers,1..cCardsPerPlayer] of TCard;
  gCardTable: TCardTable;
  gCartaBriscola: TCard;
  gHumanPlayer: Integer;
  gMuoveIlGiocatore: Integer;

implementation

{$R *.dfm}

uses
  System.IniFiles
  , Vcl.Dialogs
  , CardGames.Controller
  , CardGames.State
  ;

procedure TMainForm.StartGame;
var
  LCard : TCard;
begin
  gCardTable.ClearTable;
  gCardTable.CardDeck.ResetDeck;
  gCardTable.CardDeck.NoOfCards := 52;

  // dalle 52 carte toglie gli 8,9,10 non usati nella briscola

  var LStripCardList : TCardList;
  SetLength( LStripCardList, 3{carte 8,9,10}*4{4 semi} );
  var LIndex := 0;
  for var S := Low(TCardSuit) to High(TCardSuit) do
  begin
    if S <> csJoker then
    begin
      LStripCardList[LIndex] := TCard.Create(nil);
      with LStripCardList[LIndex] do
      begin
        Suit := S;
        Value := cvEight;
      end;
      Inc(LIndex);

      LStripCardList[LIndex] := TCard.Create(nil);
      with LStripCardList[LIndex] do
      begin
        Suit := S;
        Value := cvNine;
      end;
      Inc(LIndex);

      LStripCardList[LIndex] := TCard.Create(nil);
      with LStripCardList[LIndex] do
      begin
        Suit := S;
        Value := cvTen;
      end;
      Inc(LIndex);
    end;
  end;

  gCardTable.CardDeck.StripDeck(LStripCardList);

  for var I := Low(LStripCardList) to High(LStripCardList) do
    FreeAndNil( LStripCardList[I] );

  //Disabilita le animazioni mentre mischia le carte
  gCardTable.TurnAnimations := False;
  //Disabilita anche slow move region alla fine del movimento
  gCardTable.SlowMoveRegion := False;

  (*
  //Aggiunge i marker dove è possibile posizionare le carte da gioco
  for var i := Low(gPosition) to High(gPosition) do
    gCardTable.PlaceCardMarker(cmMark, gPosition[i].X, gPosition[i].Y, i+1);
  *)

  //Mischia il mazzo
  gCardTable.CardDeck.Shuffle;

  //Posiziona il mazzo mischiato
  gCardTable.PlaceDeck(cDeckX,cDeckY);

  //Prende la carta che farà da briscola e la disegna
  gCartaBriscola := gCardTable.DrawCardFromDeck;
  gCardTable.MoveTo( gCartaBriscola, cDeckX, cDeckY + cYCardSpacing);
  gCardTable.TurnOverCard(gCartaBriscola);

  for var P := 1 to cPlayers do
    for var C := 1 to cCardsPerPlayer do
    begin
      LCard := gCardTable.DrawCardFromDeck;
      gHand[P,C] := LCard;
      DisegnaCartaDelGiocatore( LCard, P, C );
      if P = gHumanPlayer{giocatore umano} then
        GiraCarta(LCard); // avrà le carte scoperte
    end;
end;

procedure TMainForm.DisegnaCartaDelGiocatore( ACard: TCard; APlayer: Integer; ACardOfPlayer: Integer );
begin
  gCardTable.MoveTo( ACard, gPosition[APlayer,ACardOfPlayer].X, gPosition[APlayer,ACardOfPlayer].Y );
end;

procedure TMainForm.MuoviCartaDelGiocatore( ACard: TCard; APlayer: Integer; ACardOfPlayer: Integer );
begin
  gCardTable.MoveTo( ACard, gPositionPlayedCards[APlayer].X, gPositionPlayedCards[APlayer].Y )
end;

procedure TMainForm.GiraCarta( ACard: TCard );
begin
  gCardTable.TurnOverCard(ACard);
end;

procedure TMainForm.miEsciClick(Sender: TObject);
begin
  Self.Close;
end;

procedure TMainForm.NuovaPartita;
begin
  Inizializzazione;
  StartGame;
end;

procedure TMainForm.miInformazioniClick(Sender: TObject);
begin
  ShowMessage(Application.Title+sLineBreak+
              'by Carlo & Lorenzo Barazzetta'+sLineBreak+
              'Copyright (c) 2024 Ethea S.r.l.'
             );
end;

procedure TMainForm.CardTableCardClickEvent(ACard: TCard;
  Button: TMouseButton);
begin
  if gMuoveIlGiocatore = gHumanPlayer then
  begin
    if Button = mbLeft then
    begin
      // scorre le carte del giocatore umano
      for var CartaGiocatore := 1 to cCardsPerPlayer do
        if ACard = gHand[gHumanPlayer,CartaGiocatore] then // è stata cliccata una carta del giocatore umano
        begin
          MuoviCartaDelGiocatore( ACard, gHumanPlayer, CartaGiocatore );
          gMuoveIlGiocatore := 1; // giocherà il giocatore 1 (il computer)
          //MuoviCartaDelGiocatore( gHand[gMuoveIlGiocatore,1], gMuoveIlGiocatore, 1 );
        end;
    end;
  end;
end;

procedure TMainForm.miNuovaPartitaClick(Sender: TObject);
begin
  NuovaPartita;
end;

procedure TMainForm.FormActivate(Sender: TObject);
begin
  if not Assigned(gCardTable) then
    Exit;

//Load gCardTable status if saved.
  gCardTable.LoadStatus;
//Now gCardTable public properties are restored & program menu items need to
//reflect this.
(*
  if gCardTable.StretchBackground = True then
  begin
    StretchPicture1.Checked := True;
    TilePicture1.Checked := False;
  end
  else begin
    StretchPicture1.Checked := False;
    TilePicture1.Checked := True;
  end;
*)
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if gCardTable <> nil then
  begin
    gCardTable.Free;
    gCardTable := nil;
  end;
end;

procedure TMainForm.BuildCardTable;
begin
  if gCardTable = nil then
  begin
    gCardTable := TCardTable.Create(self);
    gCardTable.Align := alClient;
    gCardTable.CardDeck.DeckName := 'C_1';
    gCardTable.CardDeck.ScaleDeck := 1;
    gCardTable.DragAndDrop := False;
    gCardTable.OnMouseMove := OnMouseMove;
    gCardTable.OnCardClickEvent := CardTableCardClickEvent;
    gCardTable.PlaceDeckOffset := 7;
    gCardTable.OnCardRestoredEvent := CardTableCardRestoredEvent;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  LIniFile: TInifile;
  LIniFileName, LSoundPath: string;
  LController: TGameController;
begin
  Caption := Format('%s', [Application.Title]);

  FBriscolaGame := TBriscolaGame.Create;
  FBriscolaTable := FBriscolaGame.CardTable;

  LController := TGameController.Create(FBriscolaTable);
  LController.ChangeState(TGameStateSetup.Create(LController));

  BuildCardTable;

//Initialize DirectSound if possible.
{$IFDEF GLSCENE}
  LIniFileName := ExtractFilePath(Application.ExeName)+'CardSettings.ini';
  LIniFile := TInifile.Create(LIniFileName);
  try
    LSoundPath := LIniFile.ReadString('Sound','Path','');
    CardGames.WinApi.SoundUnit.InitializeBass(LSoundPath);
  finally
    LIniFile.Free;
  end;
{$ENDIF}
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FBriscolaGame.Free;
end;

procedure TMainForm.CardTableCardRestoredEvent;
//A card has been restored to its original position. Just play a drop sound.
//This sound can also be used within the CardDropEvent etc.
//Keeping score or points can also be done within the sound routine as depending
//upon the sound played the points or score can be calculated.
begin
  CardGames.WinApi.SoundUnit.Sound('drop.wav');//By default mode 1.
end;

procedure TMainForm.Inizializzazione;
begin
  gHumanPlayer := cPlayers; // il giocatore umano è l'ultimo dei giocatori
  gMuoveIlGiocatore := gHumanPlayer; // muove per primo il giocatore umano

  // calcola la posizione delle carte del giocatore 1
  with gPosition[1,1] do
  begin
    X := cCard1X;
    Y := cCard1Y;
  end;
  with gPosition[1,2] do
  begin
    X := cCard1X + cXCardSpacing;
    Y := cCard1Y;
  end;
  with gPosition[1,3] do
  begin
    X := cCard1X + cXCardSpacing*2;
    Y := cCard1Y;
  end;

  // calcola la posizione delle carte del giocatore 2
  with gPosition[2,1] do
  begin
    X := cCard2X;
    Y := cCard2Y;
  end;
  with gPosition[2,2] do
  begin
    X := cCard2X + cXCardSpacing;
    Y := cCard2Y;
  end;
  with gPosition[2,3] do
  begin
    X := cCard2X + cXCardSpacing*2;
    Y := cCard2Y;
  end;

  // calcola la posizione della carta giocata dal giocatore 1
  with gPositionPlayedCards[1] do
  begin
    X := gPosition[1,2].X + 30{un po' a destra};
    Y := gPosition[1,2].Y + cYCardSpacing + 30{un po' più in basso};
  end;

  // calcola la posizione della carta giocata dal giocatore 2
  with gPositionPlayedCards[2] do
  begin
    X := gPosition[2,2].X - 30{un po' a sinistra};
    Y := gPosition[2,2].Y - cYCardSpacing - 30{un po' più in alto};
  end;
end;

initialization
{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}

end.

