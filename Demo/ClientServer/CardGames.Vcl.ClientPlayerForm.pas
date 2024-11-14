{******************************************************************************}
{                                                                              }
{ VCL Client PlayerView                                                        }
{ Client View for Card Games using TCardTable Render                           }
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
unit CardGames.Vcl.ClientPlayerForm;

interface

uses
  System.SysUtils
  , System.Variants
  , System.Classes
  , System.Types
  , System.Math
  , System.Actions
  , WinApi.Messages
  //Vcl Components
  , Vcl.Forms
  , Vcl.ToolWin
  , Vcl.Menus
  , Vcl.ComCtrls
  , Vcl.Controls
  , Vcl.StdCtrls
  , Vcl.ActnList
  , Vcl.ExtCtrls
  , Vcl.Mask
  //CardGames Model
  , CardGames.GameClient
  , CardGames.Types
  , CardGames.Model
  //CardGame Briscola Engine
  , Briscola.CardGame
  , CardGame.Client.Data
  //CardGame Render by CardTable Library
  , CardGames.Vcl.CardTable
  ;

const
  cCardWidth  = 150; // larghezza di una singola carta in pixel
  cCardHeight = 256; // altezza di una singola carta in pixel

  cSpaceFromBorder = 10; // spazio delle carte dal bordo della finestra
  cCardSpacingX = 10; // spazio tra le 3 carte disegnate
  cCardSpacingY = 10; // spazio tra il mazzo e la carta di briscola

type
  TPlayer = (plComputer,plHuman);
  TCardOfPlayer = 1..3; // posizione della carta (da 1 a 3) che ha in mano il computer o il giocatore umano
  TC64CardNumber = 0..15; // dove 0=carta vuota, 1=asso, 2=due .. 11=fante, 12=donna, 13=re, 14=jolly, 15=carta coperta

type
  TClientPlayerForm = class(TForm)
    ActionList: TActionList;
    acNewGame: TAction;
    PlayerPanel: TPanel;
    PlayerLabel: TLabel;
    PlayerNameEdit: TLabeledEdit;
    NewGameButton: TButton;
    rgGameType: TRadioGroup;
    AttachToGameButton: TButton;
    acAttachToGame: TAction;
    AvailGamesListBox: TListBox;
    AvailGamesLabel: TLabel;
    acAbandonGame: TAction;
    AbandonGameButton: TButton;
    rgOpponentsType: TRadioGroup;
    EventsMemo: TMemo;
    MessagePanel: TPanel;
    ConnectionPanel: TPanel;
    TCPClientMemo: TMemo;
    RefreshButton: TButton;
    gbConnection: TGroupBox;
    edHost: TLabeledEdit;
    edPort: TLabeledEdit;
    btConnectDisconnect: TButton;
    procedure CardTableCardClickEvent(ACard: TCard; Button: TMouseButton);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure acNewGameExecute(Sender: TObject);
    procedure acCanPlay(Sender: TObject);
    procedure acGameInProgress(Sender: TObject);
    procedure ActionListUpdate(Action: TBasicAction; var Handled: Boolean);
    procedure btConnectDisconnectClick(Sender: TObject);
    procedure RefreshButtonClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    //Variabili per Motore di Rendering:
    // posizione sullo schermo delle carte da gioco dei giocatori
    gDeckX, gDeckY: Integer; // posizione X e Y del mazzo
    gBriscolaX, gBriscolaY : Integer; // posizione X e Y della carta della briscola
    gCard1ComputerX, gCard1ComputerY: Integer; // posizione X e Y della prima carta del computer
    gCard1HumanX, gCard1HumanY: Integer; // posizione X e Y della prima carta del giocatore umano
    gPartitaIniziata: Boolean;
    gPosition: array[TPlayer,TCardOfPlayer] of TPoint; // posizione sullo schermo delle carte da gioco dei giocatori
    gPositionPlayedCards: array[TPlayer] of TPoint; // posizione sullo schermo delle carte giocate sul tavolo dai giocatori
    gHand: array[TPlayer,TCardOfPlayer] of TCard; // carte che hanno in mano il computer ed il giocatore umano
    gCardTable: TCardTable;
    gCartaBriscola: TCard; // carta della briscola
    gLastGamePlayer, gCurrentPlayer, gFirstCardPlayer: TPlayer;
    gHumanMove: Integer;    // carta giocata dal giocatore umano (da 1 a 3; può essere -1)
    gComputerMove: Integer; // carta giocata dal computer (da 1 a 3; può essere -1)
    gPoints: array[TPlayer] of Integer; // punteggio del computer e del giocatore umano
    gMT: array[TC64CardNumber,TCardSuit] of Byte; // flags (0 o 1) delle carte già giocate

    FClosing: Boolean; // indica se la Form si sta chiudendo
  
    CardGameClientData: TCardGameClientData;
    FClientEngine: TBriscolaEngine;

    procedure NuovaPartita;
    procedure EseguiPartita;
    procedure FinePartita;
    procedure BuildCardTable;
    procedure Inizializzazione;
    function ClientAreaHeight: Integer;
    function ClientAreaWidth: Integer;
    procedure DrawCardOfPlayer( ACard: TCard; APlayer: TPlayer; ACardOfPlayer: TCardOfPlayer );
    procedure GiraCarta(ACard: TCard);
    procedure MoveCardOfPlayer( ACard: TCard; APlayer: TPlayer; ACardOfPlayer: TCardOfPlayer );
    function GetMossaDelComputer( AComputerIsFirstToPlay: Boolean ): Integer;
    procedure MossaDelComputer( AComputerIsFirstToPlay: Boolean );
    procedure EliminaCarteGiocate;
    procedure DistribuisciNuoveCarte( AFirstPlayerToMove: TPlayer );
    procedure ElaboraCarteGiocate( AFirstCardPlayer: TPlayer; out ATotalPoints: Integer; out AWhoWinThePlay: TPlayer );
    function GetPointsOfCard(ACard: TCard): Integer;
    function GetForceOfCard(ACard: TCard): Integer;
    procedure DrawPlayerCards(APlayer: TPlayer);
    procedure WaitForHumanPlay;
    procedure WaitForComputerPlay( AComputerIsFirstToPlay: Boolean );
    function NumCardsOfPlayer(APlayer: TPlayer): Integer;
    procedure DropCardSound;
    procedure ShowTempMessage( const AMessage: string; AMilliSec: Integer = 1000 );
    procedure SalvaLaCartaComeGiocata( ACard: TCard );
    function GetC64CardNumberFromCardValue( ACardValue: TCardValue ): TC64CardNumber;
    function ChiHaVintoLaManoCorrente( AFirstCardPlayed, ASecondCardPlayed: TCard ): Integer;
    function GetOpponentsType: TPlayerType;
    procedure SetOpponentsType(const AValue: TPlayerType);
    procedure UpdateEventList(const AEvent: string);
    //Indy Client
    procedure UpdateTCPClientEvent(const AEvent: string);
  public
    property OpponentsType: TPlayerType read GetOpponentsType write SetOpponentsType;
  end;

var
  ClientPlayerForm: TClientPlayerForm;

implementation

{$R *.dfm}

uses
  System.IniFiles
  , System.StrUtils
  , Vcl.Dialogs
  ;

// Ritorna il numero di carte che ha APlayer
function TClientPlayerForm.NumCardsOfPlayer( APlayer: TPlayer ): Integer;
begin
  Result := 0;
  for var I := 1 to 3 do
    if Assigned( gHand[APlayer,I] ){c'è la carta} then
      Inc(Result);
end;

procedure TClientPlayerForm.SetOpponentsType(const AValue: TPlayerType);
begin
  rgOpponentsType.ItemIndex := Ord(AValue);
end;

// Pesca le 3 carte per APlayer e le mostra sul tavolo
procedure TClientPlayerForm.DrawPlayerCards( APlayer: TPlayer );
var
  LCard : TCard;
begin
  for var C := 1 to 3 do
  begin
    LCard := gCardTable.DrawCardFromDeck;
    gHand[APlayer,C] := LCard;
    DrawCardOfPlayer( LCard, APlayer, C );
    if APlayer = plHuman then
      GiraCarta(LCard); // avrà le carte scoperte
  end;
end;

// Esegue il suono della carta
procedure TClientPlayerForm.DropCardSound;
begin
  {$IFDEF GLSCENE}
  CardGames.WinApi.SoundUnit.Sound('drop.wav');
  {$ENDIF}
end;

// Esegue una nuova partita.
// Se al termine della partita, l'utente vuole giocarne un'altra, ricomincia dall'inizio, altrimenti chiude la Form.
procedure TClientPlayerForm.NuovaPartita;
var
  LUnAltraSfida: Integer;
begin
  gPartitaIniziata := True;
//  repeat
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

    // azzera i punti
    gPoints[plComputer] := 0;
    gPoints[plHuman]    := 0;

    // azzera i flags delle carte già giocate
    for var LCardSuit: TCardSuit := Low(TCardSuit) to High(TCardSuit) do
      for var LCardNumber: TC64CardNumber := Low(TC64CardNumber) to High(TC64CardNumber) do
        gMT[LCardNumber,LCardSuit] := 0;

    // inizia a giocare chi ha giocato per secondo nell'ultima partita
    if gLastGamePlayer = plComputer then
      gCurrentPlayer := plHuman
    else
      gCurrentPlayer := plComputer;

    gLastGamePlayer := gCurrentPlayer;

    if gCurrentPlayer = plHuman then
      ShowTempMessage('MISCHI IL MAZZO', 3000)
    else
      ShowTempMessage('MISCHIO IL MAZZO', 3000);

    //Mischia il mazzo
    gCardTable.CardDeck.Shuffle;

    //Posiziona il mazzo mischiato
    gCardTable.PlaceDeck(gDeckX,gDeckY);

    //Prende la carta che farà da briscola e la disegna
    gCartaBriscola := gCardTable.DrawCardFromDeck;
    gCardTable.MoveTo( gCartaBriscola, gBriscolaX, gBriscolaY );
    gCardTable.TurnOverCard(gCartaBriscola);

    // disegna prima le carte del giocatore corrente e poi dell'avversario
    if gCurrentPlayer = plHuman then
    begin
      DrawPlayerCards( plHuman );
      DrawPlayerCards( plComputer );
    end
    else
    begin
      DrawPlayerCards( plComputer );
      DrawPlayerCards( plHuman );
    end;

(*
    EseguiPartita;

    if FClosing then
      Exit;

    LUnAltraSfida := MessageDlg( 'UN''ALTRA SFIDA?', mtCustom, [mbYes,mbNo], 0, mbYes, ['Si','No'] );
  until LUnAltraSfida <> mrYes;

  ShowTempMessage('CIAO',2000);
  Self.Close;
*)
end;

// Salva la carta ACard come giocata
procedure TClientPlayerForm.SalvaLaCartaComeGiocata(ACard: TCard);
begin
  if Assigned(ACard) then
    gMT[ GetC64CardNumberFromCardValue(ACard.Value), ACard.Suit ] := 1;
end;

// Mostra il messaggio AMessage per AMilliSec millisecondi
procedure TClientPlayerForm.ShowTempMessage(const AMessage: string; AMilliSec: Integer = 1000);
begin
  MessagePanel.Caption := AMessage;
  Application.ProcessMessages;
  Sleep(AMilliSec);
  MessagePanel.Caption := '';
  Application.ProcessMessages;

(*
  var LForm: TForm := CreateMessageDialog( AMessage, mtCustom, [] );
  LForm.Show;
  try
    Application.ProcessMessages;
    Sleep(AMilliSec);
  finally
    FreeAndNil(LForm);
  end;
*)
end;

// Attende la mossa del giocatore umano ed esce
procedure TClientPlayerForm.WaitForHumanPlay;
begin
  gHumanMove := -1;
  ShowTempMessage('TOCCA A TE, CARTA ?',1000);
  // attende la mossa del giocatore umano (il click sulla sua carta e l'assegnazione della variabile gHumanMove)
  while gHumanMove < 0 do
  begin
    Application.ProcessMessages;
    if FClosing then
      Exit;
    Sleep(10);
  end;
end;

// Attende la mossa del computer ed esce
procedure TClientPlayerForm.WaitForComputerPlay( AComputerIsFirstToPlay: Boolean );
begin
  // tocca al computer giocare la propria carta
  ShowTempMessage('TOCCA A ME... ATTENDI',1000);
  // il computer gioca la sua mossa
  MossaDelComputer( AComputerIsFirstToPlay );
end;

// Esegue la partita fino alla visualizzazione del punteggio finale o della chiusura della Form
procedure TClientPlayerForm.EseguiPartita;
var
  LPoints: Integer;
  LWhoWinThePlay: TPlayer;
begin
  repeat
    gFirstCardPlayer := gCurrentPlayer;

    if gFirstCardPlayer = plHuman then
    begin
      WaitForHumanPlay;
      if FClosing then
        Exit;
      WaitForComputerPlay(False);
    end
    else
    begin
      WaitForComputerPlay(True);
      WaitForHumanPlay;
      if FClosing then
        Exit;
    end;

    ElaboraCarteGiocate( gFirstCardPlayer, LPoints, LWhoWinThePlay );
    gPoints[LWhoWinThePlay] := gPoints[LWhoWinThePlay] + LPoints;
    gCurrentPlayer := LWhoWinThePlay;

    EliminaCarteGiocate;
    DistribuisciNuoveCarte(gCurrentPlayer);
  until (NumCardsOfPlayer(plHuman) = 0) and (NumCardsOfPlayer(plComputer) = 0);

  FinePartita;
end;

// Visualizza il punteggio finale della partita
procedure TClientPlayerForm.FinePartita;
var
  LMessage: string;
begin
  ShowTempMessage('FINE PARTITA',2000);

  if gPoints[plComputer] > gPoints[plHuman] then
    LMessage := Format( 'HO VINTO IO! %d - %d', [ gPoints[plComputer], gPoints[plHuman] ] )
  else if gPoints[plHuman] > gPoints[plComputer] then
    LMessage := Format( 'HAI VINTO TU %d - %d', [ gPoints[plHuman], gPoints[plComputer] ] )
  else
    LMessage := Format( 'PARITA'' %d - %d', [ gPoints[plComputer], gPoints[plHuman] ] );

  ShowTempMessage(LMessage, 5000);
end;

// Disegna la carta ACard che ha il giocatore APlayer in posizione ACardOfPlayer, tra le carte che ha il giocatore APlayer
procedure TClientPlayerForm.DrawCardOfPlayer( ACard: TCard; APlayer: TPlayer; ACardOfPlayer: TCardOfPlayer );
begin
  gCardTable.MoveTo( ACard, gPosition[APlayer,ACardOfPlayer].X, gPosition[APlayer,ACardOfPlayer].Y );
  DropCardSound;
end;

// Muove sul tavolo la carta ACard che ha il giocatore APlayer in posizione ACardOfPlayer
procedure TClientPlayerForm.MoveCardOfPlayer( ACard: TCard; APlayer: TPlayer; ACardOfPlayer: TCardOfPlayer );
begin
  gCardTable.MoveTo( ACard, gPositionPlayedCards[APlayer].X, gPositionPlayedCards[APlayer].Y );
  DropCardSound;
end;

procedure TClientPlayerForm.GiraCarta( ACard: TCard );
begin
  gCardTable.TurnOverCard(ACard);
end;

function TClientPlayerForm.GetOpponentsType: TPlayerType;
begin
  Result := TPlayerType(rgOpponentsType.ItemIndex);
end;

procedure TClientPlayerForm.RefreshButtonClick(Sender: TObject);
begin
  CardGameClientData.RequestCardGameEvents;
end;

procedure TClientPlayerForm.CardTableCardClickEvent(ACard: TCard;
  Button: TMouseButton);
begin
  if gHumanMove < 0 then // è attesa la mossa del giocatore umano
  begin
    if Button = mbLeft then
    begin
      // scorre le carte del giocatore umano
      for var LNumCard := 1 to 3 do
      begin
        if ACard = gHand[plHuman,LNumCard] then // è stata cliccata una carta del giocatore umano
        begin
          MoveCardOfPlayer( ACard, plHuman, LNumCard );
          gHumanMove := LNumCard;
        end;
      end;
    end;
  end;
end;

// Ritorna il numero della carta nel C64 corrispondente ad ACardValue.
function TClientPlayerForm.GetC64CardNumberFromCardValue(ACardValue: TCardValue): TC64CardNumber;
begin
  case ACardValue of
    cvAce:   Result :=  1;
    cvTwo:   Result :=  2;
    cvThree: Result :=  3;
    cvFour:  Result :=  4;
    cvFive:  Result :=  5;
    cvSix:   Result :=  6;
    cvSeven: Result :=  7;
    cvEight: Result :=  8;
    cvNine:  Result :=  9;
    cvTen:   Result := 10;
    cvJack:  Result := 11;
    cvQueen: Result := 12;
    cvKing:  Result := 13;
  else
    Result := 0; // mai ritornato
  end;
end;

// Ritorna il numero della carta (da 1 a 3) corrispondente alla successiva mossa del computer.
// Ritorna 0 se il computer non ha più mosse da fare.
function TClientPlayerForm.GetMossaDelComputer( AComputerIsFirstToPlay: Boolean ): Integer;
type
  TPunteggioCarte = array[1..3] of Single;
var
  BC: Integer;
  PT: TPunteggioCarte;

  // Ritorna in BC quante carte di briscola ha in mano il computer
  procedure ContaBriscoleInMano( out BC: Integer );
  begin
    BC := 0;
    for var C1: TCardOfPlayer := 1 to 3 do
    begin
      var LCartaDelComputer: TCard := gHand[plComputer,C1];
      if Assigned(LCartaDelComputer) and (LCartaDelComputer.Suit = gCartaBriscola.Suit) then
        Inc(BC);
    end;
  end;

  // Questa procedura prende in input C1 (da 1 a 3)
  // e assegna in PT[C1] il punteggio che ha la carta del computer in posizione C1 (da 1 a 3)
  procedure Routine_Megagalattica( C1: TCardOfPlayer );
  var
    NN: Integer;
  begin
    var LCartaDelComputer: TCard := gHand[plComputer,C1];
    if Assigned(LCartaDelComputer) then
      NN := GetC64CardNumberFromCardValue( LCartaDelComputer.Value )
    else
      NN := 0;

    if NN=0 then
    begin
      PT[C1]:=-100;
      Exit;
    end;

    if NN=1 then NN:=15;
    if NN=3 then NN:=14;

    PT[C1]:=0;

    if (NN=14) or (NN=15) then PT[C1]:=-20-NN;
    if (BC<2) and (gHand[plComputer,C1].Suit = gCartaBriscola.Suit) then PT[C1]:=-17-NN;
    if gMT[ 1, gHand[plComputer,C1].Suit ] = 0 then PT[C1]:=PT[C1]-5;
    if gMT[ 3, gHand[plComputer,C1].Suit ] = 0 then PT[C1]:=PT[C1]-4;
  end;
begin
  if NumCardsOfPlayer(plComputer) = 0 then
    Exit(0);

  Sleep(500); // simula che il computer sta pensando... in realtà muoverà molto velocemente

  if AComputerIsFirstToPlay then // gioca il computer per primo
  begin
    // calcola in BC quante carte di briscola ha in mano il computer
    ContaBriscoleInMano(BC);

    (* la variabile BA non viene usata neanche nella Briscola del C64
    // calcola in BA (che varrà 0 o 1) se qualche carta di briscola è già stata giocata
    var BA: Integer := 0;
    for var W := 1 to 10 do
    begin
      if gMT[W,gCartaBriscola.Suit]=0 then
        BA := 1;
    end;
    *)

    // esegue la Routine_Megagalattica per ogni carta che ha in mano il computer
    for var C1: TCardOfPlayer := 1 to 3 do
    begin
      Routine_Megagalattica(C1);
    end;

    // calcola in CX la posizione (da 1 a 3) della carta del computer che ha il miglior punteggio
    var CX: TCardOfPlayer := 1;
    for var W := 2 to 3 do
    begin
      if PT[W]>PT[CX] then CX:=W;
    end;

    Result := CX; // la carta in posizione CX (da 1 a 3) è la carta che il computer deve giocare
  end
  else // il computer risponde al gioco
  begin
    // calcola in BC quante carte di briscola ha in mano il computer
    ContaBriscoleInMano(BC);

    var LFirstCardPlayed:  TCard := gHand[plHuman,gHumanMove]; // siccome è il computer che risponde al gioco, la prima carta giocata è quella del giocatore umano
    var LSecondCardPlayed: TCard;

    // prova a giocare ogni carta che il computer ha in mano e ne calcola il punteggio in PT
    for var C1: TCardOfPlayer := 1 to 3 do
    begin
      if not Assigned( gHand[plComputer,C1] ) then
      begin
        PT[C1]:=-100;
        Continue;
      end;

      LSecondCardPlayed := gHand[plComputer,C1]; // siccome è il computer che risponde al gioco, la seconda carta giocata è quella del computer

      var V: Integer := ChiHaVintoLaManoCorrente( LFirstCardPlayed, LSecondCardPlayed );
      if V=2 then V:=0; // per rendere il contenuto della variabile V come nella briscola del C64

      var PP: Integer := GetPointsOfCard( LFirstCardPlayed ) + GetPointsOfCard( LSecondCardPlayed );

      if V=1 then
        PT[C1]:=-PP
      else
        PT[C1]:=PP-0.01;

      var Y1: Integer := GetForceOfCard( gHand[plComputer,C1] );

      if (Y1=15) and (gHand[plComputer,C1].Suit = gCartaBriscola.Suit) then PT[C1]:=PT[C1]-20;
      if (gHand[plComputer,C1].Suit = gCartaBriscola.Suit) and (BC<2) then PT[C1]:=-5;
      if (gHand[plComputer,C1].Suit = gCartaBriscola.Suit) then PT[C1]:=PT[C1]-0.7-(0.1*(Y1-8));
    end;

    // calcola in MX la posizione (da 1 a 3) della carta del computer che ha il miglior punteggio
    var MX: TCardOfPlayer := 1;
    for var W := 2 to 3 do
    begin
      if PT[W]>PT[MX] then MX:=W;
    end;

    Result := MX; // la carta in posizione MX (da 1 a 3) è la carta che il computer deve giocare
  end;
end;

procedure TClientPlayerForm.acCanPlay(Sender: TObject);
begin
  (Sender as TAction).Enabled := (PlayerNameEdit.Text <> '');
end;

// Il computer sceglie la propria carta e la visualizza sul tavolo
procedure TClientPlayerForm.MossaDelComputer( AComputerIsFirstToPlay: Boolean );
begin
  var LMossaDelComputer: Integer := GetMossaDelComputer( AComputerIsFirstToPlay );
  if LMossaDelComputer = 0 then // non ci sono più carte da giocare per il computer
  begin
    gComputerMove := -1;
  end
  else
  begin
    gComputerMove := LMossaDelComputer;
    MoveCardOfPlayer( gHand[plComputer,gComputerMove], plComputer, gComputerMove );
    GiraCarta( gHand[plComputer,gComputerMove] );
  end;
end;

// Ritorna il punteggio della carta ACard nel gioco della briscola
function TClientPlayerForm.GetPointsOfCard(ACard: TCard): Integer;
begin
  Assert( Assigned(ACard), 'Nessuna carta dalla quale calcolare il punteggio.' );

  case ACard.Value of
    cvAce:   Exit(11);
    cvThree: Exit(10);
    cvKing:  Exit(4);
    cvQueen: Exit(3);
    cvJack:  Exit(2);
  else
    Exit(0);
  end;
end;

// Ritorna la forza della carta ACard nel gioco della briscola.
// La forza indica se una carta è più forte di un'altra (ignorando il seme), non il suo punteggio (per il quale si deve chiamare la GetPointsOfCard).
function TClientPlayerForm.GetForceOfCard(ACard: TCard): Integer;
begin
  Assert( Assigned(ACard), 'Nessuna carta dalla quale calcolare la forza.' );

  case ACard.Value of
    cvAce:   Exit(15);
    cvThree: Exit(14);
    cvKing:  Exit(13);
    cvQueen: Exit(12);
    cvJack:  Exit(11);
  else
    Exit( GetC64CardNumberFromCardValue(ACard.Value) );
  end;
end;

// Calcola chi ha vinto la mano corrente:
// ritorna 1 se ha vinto il giocatore che ha giocato la carta per primo (AFirstCardPlayed)
// ritorna 2 se ha vinto il giocatore che ha giocato la carta per secondo (ASecondCardPlayed)
function TClientPlayerForm.ChiHaVintoLaManoCorrente( AFirstCardPlayed, ASecondCardPlayed: TCard ): Integer;
var
  LWinnerPlayer: Integer;
begin
  Assert( Assigned(AFirstCardPlayed),  'Non è stata specificata la carta giocata per prima.' );
  Assert( Assigned(ASecondCardPlayed), 'Non è stata specificata la carta giocata per seconda.' );

  if (AFirstCardPlayed.Suit <> ASecondCardPlayed.Suit) then // i semi delle carte giocate sono diversi
  begin
    if ASecondCardPlayed.Suit <> gCartaBriscola.Suit then // se la carta giocata per seconda non è di briscola, vince chi ha giocato per primo (i semi sono diversi)
      LWinnerPlayer := 1
    else // se la carta giocata per seconda è di briscola, vince chi ha giocato per secondo (i semi sono diversi)
      LWinnerPlayer := 2;
  end
  else // i semi delle carte giocate sono uguali
  begin
    if GetForceOfCard(AFirstCardPlayed) > GetForceOfCard(ASecondCardPlayed) then // se la carta giocata per prima è più forte della carta giocata per seconda, vince chi ha giocato per primo (i semi sono uguali)
      LWinnerPlayer := 1
    else // se la carta giocata per prima è meno forte della carta giocata per seconda, vince chi ha giocato per secondo (i semi sono uguali)
      LWinnerPlayer := 2;
  end;

  Result := LWinnerPlayer;
end;

function TClientPlayerForm.ClientAreaHeight: Integer;
begin
  Result := ClientHeight - MessagePanel.Height - EventsMemo.Height;
end;

function TClientPlayerForm.ClientAreaWidth: Integer;
begin
  Result := ClientWidth - ConnectionPanel.Width - PlayerPanel.Width;
end;

procedure TClientPlayerForm.acGameInProgress(Sender: TObject);
begin
(*
  (Sender as TAction).Enabled := Assigned(FClientEngine) and
    (FClientEngine.GameInProgress);
*)
end;

// Elabora le carte giocate sul tavolo.
// Specificare in AFirstCardPlayer il giocatore (computer o umano) che ha giocato la carta sul tavolo per primo.
// Ritorna in ATotalPoints i punti totali delle carte giocate.
// Ritorna in AWhoWinThePlay il giocatore che ha vinto (computer o umano).
procedure TClientPlayerForm.ElaboraCarteGiocate( AFirstCardPlayer: TPlayer; out ATotalPoints: Integer; out AWhoWinThePlay: TPlayer );
var
  LComputerPlayedCard, LHumanPlayedCard: TCard;
  LWinnerPlayer: Integer;
  LFirstCardPlayed, LSecondCardPlayed: TCard;
begin
  Assert( gComputerMove > 0, 'Il computer non ha giocato la sua carta.' );
  LComputerPlayedCard := gHand[plComputer,gComputerMove];
  Assert( Assigned(LComputerPlayedCard), 'Il computer non ha la sua carta in mano.' );

  Assert( gHumanMove > 0, 'Il giocatore umano non ha giocato la sua carta.' );
  LHumanPlayedCard := gHand[plHuman,gHumanMove];
  Assert( Assigned(LHumanPlayedCard), 'Il giocatore umano non ha la sua carta in mano.' );

  // calcola i punti totali delle carte giocate sul tavolo
  ATotalPoints := GetPointsOfCard( LComputerPlayedCard ) + GetPointsOfCard( LHumanPlayedCard );

  if AFirstCardPlayer = plComputer then
  begin
    LFirstCardPlayed  := LComputerPlayedCard;
    LSecondCardPlayed := LHumanPlayedCard;
  end
  else
  begin
    LFirstCardPlayed  := LHumanPlayedCard;
    LSecondCardPlayed := LComputerPlayedCard;
  end;

  // calcola chi ha vinto la mano corrente:
  //   LWinnerPlayer = 1 => ha vinto il giocatore che ha giocato la carta per primo
  //   LWinnerPlayer = 2 => ha vinto il giocatore che ha giocato la carta per secondo
  LWinnerPlayer := ChiHaVintoLaManoCorrente( LFirstCardPlayed, LSecondCardPlayed );

  if LWinnerPlayer = 1 then // ha vinto chi ha giocato la carta per primo
    AWhoWinThePlay := AFirstCardPlayer
  else
  begin // ha vinto chi ha giocato la carta per secondo
    if AFirstCardPlayer = plComputer then
      AWhoWinThePlay := plHuman
    else
      AWhoWinThePlay := plComputer;
  end;

  var LMessage: string;
  if AWhoWinThePlay = plHuman then
    LMessage := 'PRENDI TU'
  else
    LMessage := 'PRENDO IO';

  ShowTempMessage( LMessage+' '+ATotalPoints.ToString+' PUNTI', 2000 );

  SalvaLaCartaComeGiocata(LFirstCardPlayed);
  SalvaLaCartaComeGiocata(LSecondCardPlayed);
end;

// Elimina le carte giocate sul tavolo ed anche la relativa carta che ha giocato il computer ed il giocatore umano.
procedure TClientPlayerForm.EliminaCarteGiocate;
begin
  gCardTable.PickUpCard( gHand[plComputer,gComputerMove] );
  gHand[plComputer,gComputerMove] := nil;

  gCardTable.PickUpCard( gHand[plHuman,gHumanMove] );
  gHand[plHuman,gHumanMove] := nil;
end;

procedure TClientPlayerForm.DistribuisciNuoveCarte( AFirstPlayerToMove: TPlayer );
var
  LNuovaCarta: TCard;
begin
  LNuovaCarta := gCardTable.DrawCardFromDeck;
  if not Assigned(LNuovaCarta) then // non ci sono più carte nel mazzo
    Exit;

  if AFirstPlayerToMove = plHuman then
  begin
    gHand[plHuman,gHumanMove] := LNuovaCarta;
    DrawCardOfPlayer( LNuovaCarta, plHuman, gHumanMove );
    // la carta del giocatore umano deve essere scoperta
    GiraCarta(LNuovaCarta);
  end
  else
  begin
    gHand[plComputer,gComputerMove] := LNuovaCarta;
    DrawCardOfPlayer( LNuovaCarta, plComputer, gComputerMove );
  end;

  LNuovaCarta := gCardTable.DrawCardFromDeck;
  if not Assigned(LNuovaCarta) then // se non ci sono più carte nel mazzo, prende la carta di briscola
    LNuovaCarta := gCartaBriscola;

  Assert( Assigned(LNuovaCarta), 'Non c''è la carta di briscola.' );

  if AFirstPlayerToMove = plComputer then // il giocatore che ha giocato la carta per primo è stato il computer, quindi ora tocca al giocatore umano prendere la nuova carta
  begin
    gHand[plHuman,gHumanMove] := LNuovaCarta;
    DrawCardOfPlayer( LNuovaCarta, plHuman, gHumanMove );
    // la carta del giocatore umano deve essere scoperta ma se ha pescato la briscola è già scoperta
    if LNuovaCarta <> gCartaBriscola then
      GiraCarta(LNuovaCarta);
  end
  else
  begin
    gHand[plComputer,gComputerMove] := LNuovaCarta;
    DrawCardOfPlayer( LNuovaCarta, plComputer, gComputerMove );
    // la carta del computer deve essere coperta e se ha pescato la briscola la deve coprire
    if LNuovaCarta = gCartaBriscola then
      GiraCarta(LNuovaCarta);
  end;
end;

procedure TClientPlayerForm.FormActivate(Sender: TObject);
begin
  if not Assigned(gCardTable) then
    Exit;

//Load gCardTable status if saved.
  gCardTable.LoadStatus;
end;

procedure TClientPlayerForm.BuildCardTable;
begin
  if gCardTable = nil then
  begin
    gCardTable := TCardTable.Create(self);
    gCardTable.Align := alClient;
    gCardTable.CardDeck.DeckName := 'Bresciane';
    gCardTable.CardDeck.ScaleDeck := 1;
    gCardTable.DragAndDrop := False;
    gCardTable.OnMouseMove := OnMouseMove;
    gCardTable.OnCardClickEvent := CardTableCardClickEvent;
    gCardTable.PlaceDeckOffset := 7;
  end;
end;

procedure TClientPlayerForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if MessageDlg( 'Vuoi uscire dal gioco?', mtCustom, [mbYes,mbNo], 0, mbNo, ['Si','No'] ) = mrYes then
  begin
    Action := caHide;
    FClosing := True;
  end
  else
    Action := caNone;
end;

procedure TClientPlayerForm.FormCreate(Sender: TObject);
begin
  CardGameClientData := TCardGameClientData.Create(Self);
  CardGameClientData.OnUpdateTCPClientEvent := UpdateTCPClientEvent;
  CardGameClientData.OnUpdateClientEvent := UpdateEventList;
  PlayerNameEdit.Text := GetEnvironmentVariable('USERNAME');
  //Crea la lista dei tipo di giochi di Briscola
  TBriscolaEngine.FillVariantList(rgGameType.Items);
  rgGameType.ItemIndex := 0;

  TBriscolaEngine.FillOpponentsType(rgOpponentsType.Items);
  OpponentsType := ptAI;


end;

procedure TClientPlayerForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(gCardTable);
  FreeAndNil(FClientEngine);
end;

procedure TClientPlayerForm.FormResize(Sender: TObject);
begin
  if Self.WindowState = wsNormal then
  begin
    if Assigned(gCardTable) then
      gCardTable.DeckOrBackChanged;
  end;
end;

procedure TClientPlayerForm.Inizializzazione;
{$IFDEF GLSCENE}
var
  LIniFile: TInifile;
  LIniFileName, LSoundPath: string;
{$ENDIF}
begin
  Randomize;

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
  //Stream only works with DirectSound. If not available no music.
  //if fileExists('Angelica-Machi.mp3') then
  //    CardGames.WinApi.SoundUnit.Stream('Angelica-Machi.mp3');

  BuildCardTable;

  // sceglie casualmente chi ha iniziato la partita precedente (perché in realtà non c'è una partita precedente)
  gLastGamePlayer := TPlayer(Random(2));

  // calcola la posizione del mazzo
  gDeckX := Self.ClientAreaWidth - cSpaceFromBorder - cCardWidth;
  gDeckY := (Self.ClientAreaHeight - (cCardHeight+cCardSpacingY+cCardHeight) ) div 2;

  // calcola la posizione della carta di briscola
  gBriscolaX := gDeckX;
  gBriscolaY := gDeckY + cCardHeight + cCardSpacingY;

  // calcola la posizione della prima carta del computer
  gCard1ComputerX := cSpaceFromBorder;
  gCard1ComputerY := cSpaceFromBorder;

  // calcola la posizione della prima carta del giocatore umano
  gCard1HumanX := gCard1ComputerX;
  gCard1HumanY := Self.ClientAreaHeight - cSpaceFromBorder - cCardHeight;

  // calcola la posizione delle carte del computer
  with gPosition[plComputer,1] do
  begin
    X := gCard1ComputerX;
    Y := gCard1ComputerY;
  end;
  with gPosition[plComputer,2] do
  begin
    X := gCard1ComputerX + cCardWidth + cCardSpacingX;
    Y := gCard1ComputerY;
  end;
  with gPosition[plComputer,3] do
  begin
    X := gCard1ComputerX + (cCardWidth + cCardSpacingX) * 2;
    Y := gCard1ComputerY;
  end;

  // calcola la posizione delle carte del giocatore umano
  with gPosition[plHuman,1] do
  begin
    X := gCard1HumanX;
    Y := gCard1HumanY;
  end;
  with gPosition[plHuman,2] do
  begin
    X := gCard1HumanX + cCardWidth + cCardSpacingX;
    Y := gCard1HumanY;
  end;
  with gPosition[plHuman,3] do
  begin
    X := gCard1HumanX + (cCardWidth + cCardSpacingX) * 2;
    Y := gCard1HumanY;
  end;

  // calcola la posizione della carta giocata dal computer
  with gPositionPlayedCards[plComputer] do
  begin
    X := gPosition[plComputer,3].X + cCardWidth + cCardWidth div 4 * 3 {un po' a destra};
    Y := Self.ClientAreaHeight div 2 - cCardHeight div 2 - cCardHeight div 4{un po' in alto};
  end;

  // calcola la posizione della carta giocata dal giocatore umano
  with gPositionPlayedCards[plHuman] do
  begin
    X := gPosition[plHuman,3].X + cCardWidth + cCardWidth div 4 {un po' a sinistra};
    Y := Self.ClientAreaHeight div 2 - cCardHeight div 2 + cCardHeight div 4{un po' in basso};
  end;
end;

procedure TClientPlayerForm.UpdateEventList(const AEvent: string);
begin
  EventsMemo.Lines.Add(AEvent);
  if Pos('{"ClassName":"TBriscolaEngine"', AEvent) > 0 then
    Inizializzazione
  else if Pos('{"ClassName":"TCardGame"', AEvent) > 0 then
    NuovaPartita;
end;

procedure TClientPlayerForm.UpdateTCPClientEvent(const AEvent: string);
begin
  TCPClientMemo.Lines.Add(AEvent);
end;

procedure TClientPlayerForm.acNewGameExecute(Sender: TObject);
var
  LBriscolaType: TBriscolaVariantType;
  LPlayerName: TCardPlayerName;
begin
  LBriscolaType := TBriscolaVariantType(rgGameType.ItemIndex);
  LPlayerName := PlayerNameEdit.Text;

  //Richiedo al server di creare una nuova partita agganciando il mio player
  //e un altro Player come IA
  CardGameClientData.NewBriscolaGame(LBriscolaType,
    LPlayerName, ptHuman);
end;

procedure TClientPlayerForm.ActionListUpdate(Action: TBasicAction;
  var Handled: Boolean);
begin
  PlayerPanel.Enabled := CardGameClientData.IsClientReady;
end;

procedure TClientPlayerForm.btConnectDisconnectClick(Sender: TObject);
begin
  btConnectDisconnect.Caption := CardGameClientData.ConnectDisconnect(
    edHost.Text, StrToInt(edPort.Text));

end;

initialization
{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}

end.

