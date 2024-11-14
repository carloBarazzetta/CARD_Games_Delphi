unit Patience.MainForm;
{
Patience Game (demo)
Freeware - Copyright © 2024 Ethea S.r.l.
Author: Carlo Barazzetta
Contributors:

Original code is Copyright © 2004/05/06/07/08 by David Mayne.

Version 2.2.
Patience.
Freeware copyright © 2004 by David Mayne.

Barebones demonstration of using CardTable to make Patience/Solitaire games. The
idea behind the implementation is that many patience games differ in only a few
respects from each other. Thus rules are defined for each game and the game
engine takes account of the rules when managing the game. Adding new games will
often need new rules to be introduced and additional code written often in the
StartGame procedure and the card drop event. The rules are mainly described by
sets. This generalised system is not suitable for some games. Streets game
requires at least 1024 x 768 resolution.
}
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
  ;

type

//Enumerated rules.
  TRule = (
  //Build sequence and special cases.
    rAscending, rDescending, rAscendingOrDescending, rKingOnAce, rAceOnKing,
  //Build on this type of card.
    rSuits, rAlternates, rAny,
  //Physically deal on or offset from card.
    rOntop, rOffset,
  //If rOffset then offset upwards instead of down, rOffset must be set.
    rUp,
  //Where does the base card comes from or has it a specific value. Important:
  //rDealt is for when the foundation base card is defined by dealing from the
  //deck, rFromxxx is for when a space in the tableau can be filled by any card
  //from the corresponding pile.
    rDealt, rFromReserve, rFromTableau, rFromWastepile, rAce, rKing,
  //Additional rules describing the tableau.
  //A stack of cards can be moved, rOffset will also need to be set.
    rSequence,
  //Only a full pile of cards can be moved.
    rFullSequence,
  //Is the tableau as originally DEALT formed of several OVERLAPPING rows? If it
  //only has 1 row at start but later may grow to many rows this should not be
  //used. TTableau.ColumnSizes is an array used in conjunction with this rule
  //that describes the column sizes from 1..n.
    rRows,
  //In a tableau of several rows are lower cards faceup?
    rFaceUp
    );
  TRules = set of TRule;
  //Some games call a reserve a stock.
  TPile = (pStock, pReserve, pTableau, pFoundation, pWastepile);
  //A game defines the DealMode set if it wants the cards dealt fast, for when
  //there a lot of cards to be dealt, or dealt close together in the y plane.
  TDealMode = (dmFast, dmClose);

  TMainForm = class(TForm)
    MainMenu: TMainMenu;
    ChooseGame1: TMenuItem;
    Canfield1: TMenuItem;
    RedealButton: TButton;
    FourSeasons1: TMenuItem;
    Streets1: TMenuItem;
    Options1: TMenuItem;
    ChooseBack1: TMenuItem;
    ChooseDeck1: TMenuItem;
    ShadeMode1: TMenuItem;
    CardBased1: TMenuItem;
    MouseBased1: TMenuItem;
    BackgroundPicture1: TMenuItem;
    SaveOptions1: TMenuItem;
    G1: TMenuItem;
    NewGame1: TMenuItem;
    QuitProgram1: TMenuItem;
    Yukon1: TMenuItem;
    Klondike11: TMenuItem;
    Klondike21: TMenuItem;
    BackgroundMode1: TMenuItem;
    StretchPicture1: TMenuItem;
    TilePicture1: TMenuItem;
    FullScreen1: TMenuItem;
    procedure Canfield1Click(Sender: TObject);
    procedure SetLists;
    procedure CardTableCardDropEvent(ACard: TCard; X, Y, RelX, RelY,
      Index: Integer);
    function ValidDrop(const ACard: TCard; const Target: TPile;
      const Index: TPoint; const Origin: TPile; const SIndex: TPoint): Boolean;
    function SpecialCase(const R: TRules; const ACard, TCard: TCard): Boolean;
    procedure CardTableCardClickEvent(ACard: TCard; Button: TMouseButton);
    procedure RedealButtonClick(Sender: TObject);
    procedure FourSeasons1Click(Sender: TObject);
    procedure Streets1Click(Sender: TObject);
    procedure ClearRules;
    procedure Klondike(const Version: Integer);
    procedure ChooseBack1Click(Sender: TObject);
    procedure ChooseDeck1Click(Sender: TObject);
    procedure CardBased1Click(Sender: TObject);
    procedure MouseBased1Click(Sender: TObject);
    procedure BackgroundPicture1Click(Sender: TObject);
    procedure SaveOptions1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure QuitProgram1Click(Sender: TObject);
    procedure NewGame1Click(Sender: TObject);
    procedure Yukon1Click(Sender: TObject);
    procedure Klondike11Click(Sender: TObject);
    procedure Klondike21Click(Sender: TObject);
    procedure StretchPicture1Click(Sender: TObject);
    procedure TilePicture1Click(Sender: TObject);
    procedure FullScreen1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure CardTableCardRestoredEvent;
    procedure FormShow(Sender: TObject);
  private
    procedure StartGame;
    procedure BuildCardTable;
  public
    { Public declarations }
  end;

  //Records for tableau, foundation, stock and reserve.
  TTableau = record
    BaseSize: Integer;//The base size of the tableau.
    Rules: TRules;
    //If rRows rule is used then ColumnSizes describes the size of each column
    //as originally dealt 1..n.
    ColumnSizes: array of Integer;
    //Some games with rows have a tableau with cards that are not all face up or
    //down but mixed with the face down at the base eg Yukon. To describe this
    //tableau type we need an additional array detailing the number of cards
    //dealt face down.
    FaceDown: array of Integer;
  end;
  TFoundation = record
    StartNo: Integer;//Original start no.
    Size: Integer;//Full  size of the foundation.
    Card: TCard;//Foundation card if dealt.
    Rules: TRules;
  end;
  TReserve = record
    StartNo: Integer;//No in the reserve.
    FaceUp: Boolean;//Is the reserve face up?
  end;
  TStock = record
    Packs: Integer;//If value 2 then uses 2 packs, any other value is 1 pack.
    MoveNo: Integer;//No of cards moved from stock to top of wastepile.
    Thru: Integer;//How many times can the stock be gone thru. 0 = infinity.
    ThruCount: Integer;//How many times has it been gone thru.
  end;

const
  cCardSpacing = 102;
  cYCardSpacing = 155;
  cDeckX = 15;
  cDeckY = 15;
  cReserveX = cDeckX;
  cReserveY = cDeckY+cYCardSpacing;
  cWastepileX = cDeckX+cCardSpacing;
  cWastepileY = cDeckY;
  cCardYOffset = 20;//For when cards are offset in tableau in y plane.

var
  MainForm: TMainForm;
  TableauData: TTableau;
  FoundationData: TFoundation;
  ReserveData: TReserve;
  StockData: TStock;
  FPosition: Array of TPoint;//Position of foundation cards.
  TPosition: Array of TPoint;//Base position of tableau cards.
  Foundation: TCardList;//TCardList is a dynamic array of TCards.
  Reserve: TCardList;//Reserve if used.
  Wastepile: TCardList;
  Tableau: Array of TCardList;//Multidimensional dynamic array.
  GameName, LastGameName: string;
  DealMode: set of TDealMode;
//CardList is assigned to CardTable.CardList. This a dynamic array of cards that
//can be dragged with the mouse. Nulls are allowed.
  CardList: TCardList;
//DropPoints is assigned to CardTable.DropPoints. This is a dynamic array
//holding the x,y data which determines where shades are drawn during dragging.
  DropPoints: TDropPoints;
  CardYOffset: Integer;
  OldHeight, OldWidth, OldTop, OldLeft: Integer;//Stores previous size of form.
//CardTable now created in realtime for Turbo Explorer compatability.
  CardTable: TCardTable;

implementation

{$R *.dfm}

uses
  System.IniFiles
  , Vcl.Dialogs  
  ;

procedure TMainForm.StartGame;
var
  i, HighRow, Row, Offset: Integer;
begin
//Play deal sound loop - mode 3. SoundStop will need to be called later.
  CardGames.WinApi.SoundUnit.Sound('deal.wav', 3);

//Disable the redeal button if enabled.
  if RedealButton.Enabled then
  begin
    RedealButton.Enabled := False;
    RedealButton.Visible := False;
  end;
//Clear the arrays.
  Reserve := nil;
  Foundation := nil;
  Tableau := nil;
  Wastepile := nil;
  CardYOffset := cCardYOffset;
  if rUp in TableauData.Rules then CardYOffset := - cCardYOffset;
  CardTable.ClearTable;
  if GameName <> LastGameName then CardTable.PickUpAllMarkers;
  LastGameName := GameName;
  CardTable.CardDeck.ResetDeck;
//Are One or two packs used.
  if StockData.Packs = 2 then
    CardTable.CardDeck.NoOfCards := 104
  else
    CardTable.CardDeck.NoOfCards := 52;
//In some games columns can get long so reduce the offset to try to avoid probs.
  if dmClose in DealMode then CardYOffset := CardYOffset - 6;
//Speed up the movement for games dealing out a lot of cards.
  if dmFast in DealMode then
  begin
    CardTable.CardSpeed := CardTable.CardSpeed + 15;
    CardTable.TurnOverAnimationSpeed := CardTable.TurnOverAnimationSpeed + 8;
  end;
//Disable all card turn animations when dealing.
  CardTable.TurnAnimations := False;
//Also disable the slow move region at end of movement.
  CardTable.SlowMoveRegion := False;
  Caption := Format('%s - %s', [Application.Title, GameName]);
//Place card markers. First the foundation.
  for i := 1 to FoundationData.Size do
    CardTable.PlaceCardMarker(cmMark, FPosition[i-1].X, FPosition[i-1].Y, i);
//Now tableau.
  for i := 1 to TableauData.BaseSize do
    CardTable.PlaceCardMarker(cmOutline, TPosition[i-1].X, TPosition[i-1].Y,
      i);
  CardTable.CardDeck.Shuffle;
  CardTable.PlaceDeck(cDeckX,cDeckY);
  SetLength(Reserve, ReserveData.StartNo);
  for i := 1 to ReserveData.StartNo do
  Begin
    Reserve[i-1] := CardTable.DrawCardFromDeck();
    CardTable.MoveTo(Reserve[i-1], cReserveX, cReserveY);
    CardTable.TurnOverCard(Reserve[i-1]);
  end;
//Note elements in Foundation, Tableau and Reserve may be null.
  SetLength(Tableau, TableauData.BaseSize, 1);
  SetLength(Foundation, FoundationData.Size);
//Get high row no in the tableau.
  HighRow := 1;
  if rRows in TableauData.Rules then
    for i := 1 to TableauData.BaseSize do
      if TableauData.ColumnSizes[i-1] > HighRow then HighRow :=
        TableauData.ColumnSizes[i-1];

  for Row := 1 to HighRow do
    for i := 1 to TableauData.BaseSize do
//In compiler options complete boolean eval must be unchecked. Does a card
//belong in this row at this column position.
      if (Length(TableauData.ColumnSizes) = 0) or
        (TableauData.ColumnSizes[i-1] >= Row) then
        begin
//If Row > 1 we will have to extend the array.
          if Row > 1 then SetLength(Tableau[i-1], Length(Tableau[i-1])+1);
          Tableau[i-1, Row-1] := CardTable.DrawCardFromDeck();
          Offset := 0;
          if Row > 1 then Offset := CardYOffset * (Row - 1);
          CardTable.MoveTo(Tableau[i-1, Row-1], TPosition[i-1].X,
          TPosition[i-1].Y + Offset);
//If cards are dealt face up or if it is a top card in the tableau then turn it
//over.
          if (rFaceUp in TableauData.Rules) or//if rule rFaceUp
            (Length(TableauData.ColumnSizes) = 0) or//ColumnSizes not defined
            (TableauData.ColumnSizes[i-1] = Row) or//the end of a column
            ((Length(TableauData.FaceDown) <> 0) and//FaceDown defined
            (Row > TableauData.FaceDown[i-1])) then//row > the no of facedown
                CardTable.TurnOverCard(Tableau[i-1, Row-1]);
        end;
//If no cards are dealt to form the foundation base StartNo must be zero.
  for i := 1 to FoundationData.StartNo do
  begin
    Foundation[i-1] := CardTable.DrawCardFromDeck();
    CardTable.MoveTo(Foundation[i-1], FPosition[i-1].X, FPosition[i-1].Y);
    CardTable.TurnOverCard(Foundation[i-1]);
  end;

//Stop sound loop.
  CardGames.WinApi.SoundUnit.SoundStop('deal.wav');

//If the foundation card is dealt then store its value.
  if rDealt in FoundationData.Rules then FoundationData.Card := Foundation[0];
//Restore default speeds.
  if dmFast in DealMode then
  begin
    CardTable.CardSpeed := CardTable.CardSpeed - 15;
    CardTable.TurnOverAnimationSpeed := CardTable.TurnOverAnimationSpeed - 8;
  end;
//Enable turn animations.
  CardTable.TurnAnimations := True;
//Enable slow move region at end of all movemet if speed > 1.
  CardTable.SlowMoveRegion := True;
//Enable lift card offset.
  CardTable.LiftOffset := True;
  SetLists;
  NewGame1.Enabled := True;
end;

procedure TMainForm.SetLists;
//Populate the two dynamic arrays that are assigned to CardTable properties that
//regulate what cards can be picked up and where shades are placed to show where
//they might be dropped.
var
  i, j, Index, L: Integer;
begin
//First lets populate the CardList detailing cards that can be dragged.
  Index := 0;
  L := 0;
  if not (rSequence in TableauData.Rules) then
  begin
//Only the top cards in the tableau can be dragged unless rFullSequence;
    L := TableauData.BaseSize;
    if Length(Reserve) > 0 then inc(L);
    if Length(Wastepile) >0 then inc(L);
    SetLength(CardList, L);
    for i := 0 to High(Tableau) do
    begin
      CardList[Index] := Tableau[i,High(Tableau[i])];
      inc(Index);
    end;
    if rFullSequence in TableauData.Rules then
//when the base card can be dragged as well.
      for i := 0 to High(Tableau) do
        if Tableau[i,Low(Tableau[i])] <> Tableau[i,High(Tableau[i])] then
        begin
          inc(L);
          SetLength(CardList, L);
          CardList[Index] := Tableau[i,Low(Tableau[i])];
          inc(Index);
        end;
  end
  else
    begin
//All cards in the tableau have a potential to be dragged. Note somecards may be
//facedown but they cant be picked up anyway.
      for i := 0 to High(Tableau) do
        L := L + Length(Tableau[i]);
      if Length(Reserve) > 0 then inc(L);
      if Length(Wastepile) > 0 then inc(L);
      SetLength(CardList, L);
      for i := 0 to High(Tableau) do
        for j := 0 to High(Tableau[i]) do
        begin
          CardList[Index] := Tableau[i,j];
          inc(Index);
        end;
    end;
  If Length(Reserve) > 0 then
  begin
    CardList[Index] := Reserve[High(Reserve)];
    inc(Index);
  end;
  if Length(Wastepile) > 0 then CardList[Index] := Wastepile[High(Wastepile)];
//Assign to the property.
  CardTable.DragCards := CardList;
//Now lets populate the DropPoints array.
  L := FoundationData.Size + Length(TPosition);
  SetLength(DropPoints, L);
  Index := 0;
  for i := 0 to High(Tableau) do
  begin
    if Assigned(Tableau[i, High(Tableau[i])]) then
    begin
//Find the drop point from the card.
      DropPoints[Index].X := Tableau[i,High(Tableau[i])].X;
      DropPoints[Index].Y := Tableau[i, High(Tableau[i])].Y;
    end
    else
      begin
//Find the drop point from its base position.
        DropPoints[Index].X := TPosition[i].X;
        DropPoints[Index].Y := TPosition[i].Y;
      end;
    inc(Index);
  end;
  for i := 0 to FoundationData.Size-1 do
  begin
    DropPoints[Index].X := FPosition[i].X;
    DropPoints[Index].Y := FPosition[i].Y;
    inc(Index);
  end;
//Assisgn to the property.
  CardTable.DropPoints := DropPoints;
end;

procedure TMainForm.CardTableCardDropEvent(ACard: TCard; X, Y, RelX, RelY,
  Index: Integer);
//This event must be handled if drag & drop is enabled. Index is a reference to
//the DropPoints property if used. If -1 then it was not released over a point
//else it was released over DropPoints[Index]. This function has become rather
//complex! In part because of the requirement that the tableau arrays must
//be > 0 in length giving rise to special cases when the array is 1 in length
//because it may actually be size 1 or null and really size 0! Probably should
//have allowed 0 length arrays but its done now and I don`t like the thought of
//undoing it. This is the reason that strange variables like k are in the code
//which takes account of the anomoly.
var
  i, j, k: Integer;
  Origin, Target: TPile;
  SIndex, TIndex: TPoint;
begin
  Target := TPile(0); // per togliere il warning
  k := 0;
  if Index = -1 then CardTable.RestoreCardByMove
  else
    begin
//First lets find the origin of the card. Where is it from? We will need this
//information later. Note in following lines that in compiler options complete
//boolean eval must be unchecked for it to work.
      if (Length(Reserve) > 0) and (Reserve[High(Reserve)] = ACard) then
        Origin := pReserve
      else
        if (Length(Wastepile) > 0) and (Wastepile[High(Wastepile)] = ACard) then
          Origin := pWastepile
        else
          begin
            Origin := pTableau;
            SIndex.X := -1;//Allowing  us to break out of outer loop.
//Now where in the tableau is it from?
            for i := 0 to High(Tableau) do
            begin
              for j := High(Tableau[i]) downto 0 do
                if Tableau[i,j] = ACard then
                begin
                  SIndex.X := i;
                  SIndex.Y := j;
                  break;
                end;
              if SIndex.X <> -1 then break;
            end;
          end;
//Can this card be dropped here? And where is here? Has it been dropped on the
//foundation?
      for i := 0 to FoundationData.Size-1 do
        if (DropPoints[Index].X = FPosition[i].X) and
          (DropPoints[Index].Y = FPosition[i].Y) then
        begin
//Card has been dropped on foundation[i].
          Target := pFoundation;
          TIndex.X := i;
          break;
        end;
//No so will need to search the tableau.
      if Target <> pFoundation then
        for i := 0 to High(Tableau) do
//This is a rather nasty if statement isn`t it?
          if (Assigned(Tableau[i, High(Tableau[i])]) and
            ((DropPoints[Index].X = Tableau[i,High(Tableau[i])].X) and
            (DropPoints[Index].Y = Tableau[i,High(Tableau[i])].Y)))
            or
            ((not Assigned(Tableau[i, High(Tableau[i])])) and
            ((DropPoints[Index].X = TPosition[i].X) and
            (DropPoints[Index].Y = TPosition[i].Y))) then
            begin
              Target := pTableau;
              TIndex.X := i;
              TIndex.Y := High(Tableau[i]);
              break;
            end;
//First ensure that stacks of cards cant be dropped on to the foundation.
      if (rSequence in TableauData.Rules) and (Origin = pTableau) then
        if (Target = pFoundation) and (SIndex.Y <> High(Tableau[SIndex.X]))
          then begin
            CardTable.RestoreCardByMove;//Restore card is done here and again below.
            exit;
          end;
      if ValidDrop(ACard, Target, TIndex, Origin, SIndex) then
      begin
//Stacks of cards cant be placed on the foundation or from reserve or wastepile.
        if (Target = pFoundation) or not (rSequence in TableauData.Rules) or
          (Origin = pReserve) or (Origin = pWastepile) then
        begin
          if (Target = pTableau) and (rOffset in TableauData.Rules) and
            not ((TIndex.Y = 0) and not Assigned(Tableau[TIndex.X, 0])) then
            CardTable.DropCard(DropPoints[Index].X,
              DropPoints[Index].Y+CardYOffset)
          else begin
//Cards once dropped on the foundation cant be moved again [not in these games
//anyway]. We dont need the lower cards so we will pick them up first.
            if (Target = pFoundation) and Assigned(Foundation[TIndex.X]) then
              CardTable.PickUpCard(Foundation[TIndex.X]);
//Note that although auto and not manual shade drawing is being done it is still
//ok to use DropCardOnShade without error even though technically there is no
//shade on the table at this point.
            CardTable.DropCardOnShade(cmDragShade);
          end;
//Make required changes to dynamic arrays.
          if Origin = pReserve then
            SetLength(Reserve, Length(Reserve)-1)
          else
            if Origin = pWastepile then
              SetLength(Wastepile, Length(Wastepile)-1)
            else
//Tableau must always have length > 0.
              if SIndex.Y = 0 then
                Tableau[SIndex.X, 0] := nil
              else begin
//Turn over base card if not face up.
                if not Tableau[SIndex.X, SIndex.Y-1].FaceUp then
                  CardTable.TurnOverCard(Tableau[SIndex.X, SIndex.Y-1]);
                SetLength(Tableau[SIndex.X], SIndex.Y);
              end;
          if Target = pFoundation then
//We will simply replace the foundation card.
            Foundation[TIndex.X] := ACard
          else
            if (TIndex.Y = 0) and (not Assigned(Tableau[TIndex.X, 0])) then
                Tableau[Tindex.X, 0] := ACard
            else
              begin
//We will have to make space for it in the array.
                SetLength(Tableau[TIndex.X], TIndex.Y+2);
                Tableau[TIndex.X, TIndex.Y+1] := ACard;
              end;
        end
        else
          begin
//Card placed is offset in the y plane. Also it may be the base card of a stack
//of cards that need to be moved as well.
            j := TIndex.Y;
            for i := SIndex.Y to High(Tableau[SIndex.X]) do
            begin
              if (j = 0) and (not Assigned(Tableau[TIndex.X, 0])) then
              begin
                Tableau[Tindex.X, 0] := ACard;
                k := 1;//Needed to work with the anomoly.
              end
              else
                begin
//We will have to make space for it in the array.
                  SetLength(Tableau[TIndex.X], j+2-k);
                  Tableau[TIndex.X, j+1-k] := Tableau[SIndex.X, i];
                end;
              if j = TIndex.Y then
//Drop the card on the target. This is the dragged card.
                if k = 1 then
//Dropped on an empty space.
                  CardTable.DropCardOnShade(cmDragShade)
                else
//Dropped om another card.
                  CardTable.DropCard(DropPoints[Index].X,
                    DropPoints[Index].Y+CardYOffset)
              else
//With version 1.x we needed to pick up and put down cards before moving them.
//Version 2 allows you to move cards out from below any covering ones as below.
                CardTable.MoveTo(Tableau[SIndex.X, i], DropPoints[Index].X,
                  DropPoints[Index].Y+CardYOffset*((i-SIndex.Y)+1-k));
              inc(j);
            end;
//Finally amend the source array.
            if SIndex.Y = 0 then
            begin
              SetLength(Tableau[SIndex.X], 1);
              Tableau[SIndex.X, 0] := nil
            end
            else begin
//Turn over base card if not face up.
              if not Tableau[SIndex.X, SIndex.Y-1].FaceUp then
                CardTable.TurnOverCard(Tableau[SIndex.X, SIndex.Y-1]);
              SetLength(Tableau[SIndex.X], SIndex.Y);
            end;
          end;
//Now reset the CardList and DropPoints arrays to reflect the changes made.
        SetLists;
      end
      else
        CardTable.RestoreCardByMove;
    end;
end;

function TMainForm.ValidDrop(const ACard: TCard; const Target: TPile;
  const Index: TPoint; const Origin: TPile; const SIndex: TPoint): Boolean;
//Is it valid to drop the card on the target. Target may be a card or null.
var
  TargetCard: TCard;
  R: TRules;
begin
  Result := false;
  if Target = pFoundation then
  begin
    TargetCard := Foundation[Index.X];
    R := FoundationData.Rules;
  end
  else
    begin
      TargetCard := Tableau[Index.X, Index.Y];
      R := TableauData.Rules;
    end;
//First deal with dropping on an empty space.
  if not Assigned(TargetCard) then
  begin
    if rDealt in R then
    begin
//Is the target the foundation and the card of the type already dealt?
      if (Target = pFoundation) and (FoundationData.Card.Value = ACard.Value)
        then Result := True;
//All other cases fail.
      exit;
    end;
//Is the Base built from the reserve & is it a reserve card?
    if (rFromReserve in R) and (Origin = pReserve) then Result := True;
//Is the base built from the wastepile & is it a wastepile card?
    if (rFromWastepile in R) and (origin = pWastepile) and (length(Reserve) = 0)
      then Result := True;
//And again fro the tableau.
    if (rFromTableau in R) and (Origin = pTableau) then Result := True;
//Is the card the correct value?
    if (rAce in R) and (ACard.Value = cvAce) then Result := True;
    if (rKing in R) and (ACard.Value = cvKing) then Result := True;
    exit;
  end;
//Ok we are dropping on another card. We need to check the order unless the
//special cases are true.
  if not SpecialCase(R, ACard, TargetCard) then
  begin
    if rAscending in R then
      if (ord(ACard.Value)-ord(TargetCard.Value)) <> 1 then exit;
    if rDescending in R then
      if (ord(ACard.Value)-ord(TargetCard.Value)) <> -1 then exit;
    if rAscendingOrDescending in R then
      if abs(ord(ACard.Value)-ord(TargetCard.Value)) <> 1 then exit;
  end;
//Now check the color sequence.
  if rSuits in R then
    if (ACard.Suit <> TargetCard.Suit) then exit;
  if rAlternates in R then
    case TargetCard.Suit of
      csDiamond, csHeart:
        if (ACard.Suit <> csClub) and (ACard.Suit <> csSpade) then exit;
      csClub, csSpade:
        if (ACard.Suit <> csHeart) and (ACard.Suit <> csDiamond) then exit;
    end;
//Finally ensure that if target is tableau that we are not attempting to drop in
//the same column.
  if Target = pTableau then
    if SIndex.X = Index.X then exit;
  Result := True;
end;

function TMainForm.SpecialCase(const R: TRules; const ACard, TCard: TCard):
  Boolean;
//Are any special drop cases true?
begin
  result := false;
  if (rAceOnKing in R) and (ACard.Value = cvAce) and (TCard.Value = cvKing) then
    result := true;
  if (rKingOnAce in R) and (ACard.Value = cvKing) and (TCard.Value = cvAce) then
    result := true;
end;

procedure TMainForm.CardTableCardClickEvent(ACard: TCard;
  Button: TMouseButton);
//We will use this event to determine if the deck has been clicked on, meaning
//that some more cards need to be dealt from the stock. Also if right clicked on
//card on table we will lift it out from covering cards to show it clearly.
var
  i, L, No, S: integer;
  ClickCard: TCard;
  T1, T2: Boolean;
begin
  if (ACard.Status = 0) and (Button = mbLeft) then//Status 0 means in deck.
  begin
    if CardTable.CardDeck.NoOfCardsInDeck < StockData.MoveNo then
      No := CardTable.CardDeck.NoOfCardsInDeck
    else
      No := StockData.MoveNo;
    L := Length(Wastepile);
    SetLength(Wastepile, L+No);
//Now when moving to the wastepile we want a quick & simple movement so we
//disable any lifts or turnover movement.
    T1 := CardTable.LiftOffset;
    T2 := CardTable.TurnOverAnimationLift;
    S := CardTable.TurnOverAnimationSpeed;
    CardTable.LiftOffset := False;
    CardTable.TurnOverAnimationLift := False;
    CardTable.TurnOverAnimationSpeed := 0;
    for i := 1 to No do
    Begin
      Wastepile[L+i-1] := CardTable.DrawCardFromDeck();
      CardTable.MoveTo(Wastepile[L+i-1], cWastepileX, cWastepileY);
      CardTable.TurnOverCard(Wastepile[L+i-1]);
    end;
    CardTable.LiftOffset := T1;
    CardTable.TurnOverAnimationLift := T2;
    CardTable.TurnOverAnimationSpeed := S;
    SetLists;
    if CardTable.CardDeck.NoOfCardsInDeck = 0 then
//Enable the redeal redeal wastepile buttons if allowed.
    begin
      inc(StockData.ThruCount);
      if (StockData.Thru = 0) or (StockData.ThruCount < StockData.Thru) then
      begin
        RedealButton.Enabled := True;
        RedealButton.Visible := True;
      end;
    end;
  end
  else
    if (Button = mbLeft) and ACard.FaceUp then //Sound('drag.wav')
    else
      if (Button = mbRight) and ACard.FaceUp then
      begin
//Show clearly the clicked card. One possible way would be to lift off all the
//covering cards in the tableau. This is another easier way.
        ClickCard := TCard.Create(ACard.Owner);
        try
          ClickCard.Assign(ACard);
//CardTable wont draw a card flagged as displayed on the table so.
          ClickCard.Displayed := False;
          CardTable.PlaceCard(ClickCard, ClickCard.X, ClickCard.Y);
          Sleep(750);
          CardTable.PickUpCard(ClickCard);
        finally
          ClickCard.Free;
        end;
      end;
end;

procedure TMainForm.RedealButtonClick(Sender: TObject);
var
  i: Integer;
begin
//Disable the button.
  RedealButton.Enabled := False;
  RedealButton.Visible := False;
//Pick up the wastepile and turn over the cards.
  for i := High(Wastepile) downto 0 do
  begin
    CardTable.PickUpCard(Wastepile[i]);
    CardTable.CardDeck.FaceUp := False;
  end;
//Add the wastepile back to the stock.
  CardTable.CardDeck.AddCardsToDeck(Wastepile);
//Reset the wastepile.
  Wastepile := nil;
  CardTable.PlaceDeck(cDeckX,cDeckY);
end;

procedure TMainForm.ClearRules;
//Clear all rule variables.
begin
  TableauData.BaseSize := 0;
  TableauData.Rules := [];
  TableauData.ColumnSizes := nil;
  TableauData.FaceDown := nil;
  FoundationData.StartNo := 0;
  FoundationData.Size := 0;
  FoundationData.Card := nil;
  FoundationData.Rules := [];
  ReserveData.StartNo := 0;
  ReserveData.FaceUp := false;
  StockData.Packs := 0;
  StockData.MoveNo := 0;
  StockData.Thru := 0;
  StockData.ThruCount := 0;
  DealMode := [];
end;

procedure TMainForm.ChooseBack1Click(Sender: TObject);
begin
  CardTable.CardDeck.SelectBack;
  CardTable.DeckOrBackChanged;
end;

procedure TMainForm.ChooseDeck1Click(Sender: TObject);
begin
  CardTable.CardDeck.SelectDeck;
  CardTable.DeckOrBackChanged;
end;

procedure TMainForm.CardBased1Click(Sender: TObject);
begin
  CardTable.AutoShadeMode := 1;
  CardBased1.Checked := True;
  MouseBased1.Checked := False;
end;

procedure TMainForm.MouseBased1Click(Sender: TObject);
begin
  CardTable.AutoShadeMode := 2;
  CardBased1.Checked := False;
  MouseBased1.Checked := True;
end;

procedure TMainForm.BackgroundPicture1Click(Sender: TObject);
begin
  CardTable.SelectBackgroundPicture;
end;

procedure TMainForm.SaveOptions1Click(Sender: TObject);
begin
  CardTable.SaveStatus;
end;

procedure TMainForm.FormActivate(Sender: TObject);
begin
  if not Assigned(CardTable) then
    Exit;

//Load cardtable status if saved.
  CardTable.LoadStatus;
//Now CardTable public properties are restored & program menu items need to
//reflect this.
  if CardTable.AutoShadeMode = 1 then
  begin
    CardBased1.Checked := True;
    MouseBased1.Checked := False;
  end
  else Begin
    CardBased1.Checked := False;
    MouseBased1.Checked := True;
  end;
  if CardTable.StretchBackground = True then
  begin
    StretchPicture1.Checked := True;
    TilePicture1.Checked := False;
  end
  else begin
    StretchPicture1.Checked := False;
    TilePicture1.Checked := True;
  end;
end;

procedure TMainForm.QuitProgram1Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TMainForm.NewGame1Click(Sender: TObject);
begin
  StartGame;
end;

procedure TMainForm.StretchPicture1Click(Sender: TObject);
begin
  CardTable.StretchBackground := True;
  StretchPicture1.Checked := True;
  TilePicture1.Checked := False;
end;

procedure TMainForm.TilePicture1Click(Sender: TObject);
begin
  CardTable.StretchBackground := False;
  StretchPicture1.Checked := False;
  TilePicture1.Checked := True;
end;

procedure TMainForm.FullScreen1Click(Sender: TObject);
//Slightly different order of setting of Toolbar & BorderStyle properties was
//required to get this to work ok in Turbo Explorer.
begin
  if WindowState <> wsMaximized then
  begin
    OldHeight := Height;
    OldWidth := Width;
    OldLeft := Left;
    OldTop := Top;
    WindowState := wsMaximized;
  end
  else
    WindowState := wsNormal;
  Hide;
  if CardTable.Top <> 0 then
  begin
    CardTable.Top := 0;
    BorderStyle := bsNone;
  end
  else
    begin
      BorderStyle := bsSizeable;
      Height := OldHeight;
      Width := OldWidth;
      Left := OldLeft;
      Top := OldTop;
      CardTable.Top := 32;
    end;
  Show;
end;


//Game data.


procedure TMainForm.Canfield1Click(Sender: TObject);
//Define rules and positions for Canfield.
//Reserve of 13. 4 dealt to tableau. 1 to foundation as others of the same rank
//turn up deal to foundation. Build on foundation in ascending order & suit the
//ace plays on the king. On the tableau build in descending sequence & alternate
//colors the king plays on the ace. Fill spaces from the reserve. Turn over
//stock 3 cards at a time, play thru without limit.
var
  i: Integer;
begin
  if GameName = 'Canfield' then exit;
  ClearRules;
  GameName := 'Canfield';
  TableauData.Rules := [rOffset, rDescending, rAlternates, rFromReserve,
    rFromWastepile, rKingOnAce, rFullSequence];
  TableauData.BaseSize := 4;
  FoundationData.Rules := [rAscending, rSuits, rDealt, rAceOnKing];
  FoundationData.StartNo := 1;
  FoundationData.Size := 4;
  ReserveData.StartNo := 13;
  ReserveData.FaceUp := True;
  StockData.MoveNo := 3;
  StockData.Thru := 0;//Zero value represents infinity.
  SetLength(FPosition, 4);
//Set base position of tableau and foundation cards.
  for i := 2 to 5 do
  begin
    FPosition[i-2].X := cDeckX+cCardSpacing*i;
    Fposition[i-2].Y := cDeckY;
  end;
  SetLength(TPosition, 4);
  for i := 2 to 5 do
  begin
    TPosition[i-2].X := cDeckX+cCardSpacing*i;
    TPosition[i-2].Y := cReserveY;
  end;
  StartGame;
end;

procedure TMainForm.FourSeasons1Click(Sender: TObject);
//Define rules and positions for Four Seasons.
//A tableau of five cards in the form of a cross. Deal a card in a corner of the
//cross to form the foundation. As others of the same rank turn up deal them to
//the other corners of the cross to form the foundation. Build on them in suit &
//ascending sequence the ace plays on the king. Build in descending order on the
//tableau regardless of suit or color. Turn over stock 1 card at a time. A space
//may be filled from wastepile or tableau.
begin
  if GameName = 'Four Seasons' then exit;
  ClearRules;
  GameName := 'Four Seasons';
  TableauData.Rules := [rOntop, rDescending, rAny, rFromWastepile, rFromTableau,
    rKingonAce];
  TableauData.BaseSize := 5;
  FoundationData.Rules := [rAscending, rSuits, rDealt, rAceOnKing];
  FoundationData.StartNo := 1;
  FoundationData.Size := 4;
  ReserveData.StartNo := 0;
  StockData.MoveNo := 1;
  StockData.Thru := 1;//Zero value represents infinity.
  SetLength(FPosition, 4);
//Set base position of tableau and foundation cards.
  FPosition[0].X := cDeckX+cCardSpacing*2;
  Fposition[0].Y := cDeckY;
  FPosition[1].X := cDeckX+cCardSpacing*4;
  FPosition[1].Y := cDeckY;
  FPosition[2].X := cDeckX+cCardSpacing*2;
  FPosition[2].Y := cDeckY+cYCardSpacing*2;
  FPosition[3].X := cDeckX+cCardSpacing*4;
  FPosition[3].Y := cDeckY+cYCardSpacing*2;
  SetLength(TPosition, 5);
  TPosition[0].X := cDeckX+cCardSpacing*3;
  TPosition[0].Y := cDeckY;
  TPosition[1].X := cDeckX+cCardSpacing*2;
  TPosition[1].Y := cDeckY+cYCardSpacing;
  TPosition[2].X := cDeckX+cCardSpacing*3;
  TPosition[2].Y := cDeckY+cYCardSpacing;
  TPosition[3].X := cDeckX+cCardSpacing*4;
  TPosition[3].Y := cDeckY+cYCardSpacing;
  TPosition[4].X := cDeckX+cCardSpacing*3;
  TPosition[4].Y := cDeckY+cYCardSpacing*2;
  StartGame;
end;

procedure TMainForm.Streets1Click(Sender: TObject);
//Define rules and positions for streets 2 pack patience.
//Deal 40 cards to form a tableau. Only exposed cards can be moved. As aces turn
//up deal them above the tablaue to form the foundation. Build on aces in suit
//and ascending sequence. Build on tableau in descending sequence and alternate
//colors. Turn over stock 1 card at a time and once only.
var
  i: Integer;
begin
  if GameName = 'Streets' then exit;
  ClearRules;
  GameName := 'Streets';
  TableauData.Rules := [rOffset, rUp, rDescending, rAlternates, rFromTableau,
    rFromWastepile, rRows, rFaceUp];
  TableauData.BaseSize := 10;
  FoundationData.Rules := [rAscending, rSuits, rAce];
  FoundationData.Size := 8;
  StockData.Packs := 2;
  StockData.MoveNo := 1;
  StockData.Thru := 1;
  SetLength(FPosition, 8);
//Set base position of tableau and foundation cards.
  for i := 2 to 9 do
  begin
    FPosition[i-2].X := cDeckX+cCardSpacing*i;
    Fposition[i-2].Y := cDeckY;
  end;
  SetLength(TPosition, 10);
  SetLength(TableauData.ColumnSizes, 10);
  for i := 1 to 10 do
  begin
    TPosition[i-1].X := cDeckX+cCardSpacing*(i-1);
    TPosition[i-1].Y := 555;
//Must set column sizes.
    TableauData.ColumnSizes[i-1] := 4;
  end;
  DealMode := [dmFast];
  StartGame;
end;

procedure TMainForm.Klondike(const Version: Integer);
//Define rules & positions for Klondike.
//Two versions of the rules are defined here. Deal a tableau of 28 cards. As
//aces are uncovered move them above the tableau to form the foundation. Build
//on each in suits and ascending sequence. Build on the tableau in descending
//sequence and alternate colors. Spaces can only be filled by a king. Stacks of
//cards within the tableau can be moved. Version 1: Stock turned over 1 card at
//a time and go through once only. Version 2: Stock turned over 3 cards at a
//time and stock without limit, a much easier version.
var
  i: Integer;
begin
  if (Version = 1) and (GameName = 'Klondike 1') then exit;
  if (Version = 2) and (GameName = 'Klondike 2') then exit;
  ClearRules;
  GameName := 'Klondike';
  TableauData.Rules := [rOffset, rDescending, rAlternates, rRows, rKing,
    rSequence];
  TableauData.BaseSize := 7;
  FoundationData.Rules := [rAscending, rSuits, rAce];
  FoundationData.Size := 4;
//Handle 2 versions of rules.
  if Version = 1 then
  begin
    StockData.MoveNo := 1;
    StockData.Thru := 1;
    GameName := GameName + ' 1';
  end else
    Begin
      StockData.MoveNo := 3;
      StockData.Thru := 0;
      GameName := GameName + ' 2';
    end;
  SetLength(FPosition, 4);
//Set base position of tableau and foundation cards.
  for i := 3 to 6 do
  begin
    FPosition[i-3].X := cDeckX+cCardSpacing*i;
    Fposition[i-3].Y := cDeckY;
  end;
  SetLength(TPosition, 7);
  SetLength(TableauData.ColumnSizes, 7);
  for i := 1 to 7 do
  begin
    TPosition[i-1].X := cDeckX+cCardSpacing*(i-1);
    TPosition[i-1].Y := cReserveY;
//Must set column sizes.
    TableauData.ColumnSizes[i-1] := i;
  end;
  StartGame;
end;

procedure TMainForm.Yukon1Click(Sender: TObject);
//4 foundation piles (top right) - build up in suit from Ace to King. 7 tableau
//piles (below foundations) - build down by alternate color. Move groups of
//cards regardless of any sequence. Fill spaces with Kings or groups of cards
//headed by a King.
var
  i: Integer;
begin
  if GameName = 'Yukon' then exit;
  ClearRules;
  GameName := 'Yukon';
  TableauData.Rules := [rOffset, rDescending, rAlternates, rRows, rKing,
    rSequence];
  TableauData.BaseSize := 7;
  FoundationData.Rules := [rAscending, rSuits, rAce];
  FoundationData.Size := 4;
  SetLength(FPosition, 4);
//Set base position of tableau and foundation cards.
  for i := 3 to 6 do
  begin
    FPosition[i-3].X := cDeckX+cCardSpacing*i;
    Fposition[i-3].Y := cDeckY;
  end;
  SetLength(TPosition, 7);
  SetLength(TableauData.ColumnSizes, 7);
  SetLength(TableauData.FaceDown, 7);//Face down cards in each column.
  for i := 1 to 7 do
  begin
    TPosition[i-1].X := cDeckX+cCardSpacing*(i-1);
    TPosition[i-1].Y := cReserveY;
//Set the no of face down cards..
    TableauData.FaceDown[i-1] := i - 1;
  end;
//Set column sizes.
  TableauData.ColumnSizes[0] := 1;
  for i := 1 to 6 do
    TableauData.ColumnSizes[i] := i + 5;
  DealMode := [dmFast, dmClose];
  StartGame;
end;

procedure TMainForm.Klondike11Click(Sender: TObject);
begin
  Klondike(1);
end;

procedure TMainForm.Klondike21Click(Sender: TObject);
begin
  Klondike(2);
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if CardTable <> nil then
  begin
    CardTable.Free;
    CardTable := nil;
  end;
end;

procedure TMainForm.BuildCardTable;
begin
  if CardTable = nil then
  begin
    CardTable := TCardTable.Create(self);
    CardTable.Align := alClient;
    CardTable.CardDeck.DeckName := 'C_1';
    CardTable.CardDeck.ScaleDeck := 1;
    CardTable.DragAndDrop := True;
    CardTable.OnMouseMove := OnMouseMove;
    CardTable.OnCardClickEvent := CardTableCardClickEvent;
    CardTable.OnCardDropEvent := CardTableCardDropEvent;
    CardTable.PlaceDeckOffset := 7;
    CardTable.OnCardRestoredEvent := CardTableCardRestoredEvent;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  LIniFile: TInifile;
  LIniFileName, LSoundPath: string;
begin
  OldHeight := Round(500 * ScaleFactor);//Default smaller size of form.
  OldWidth := Round(700 * ScaleFactor);

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
//Stream only works with DirectSound. If not available no music.
//if fileExists('Angelica-Machi.mp3') then
//    CardGames.WinApi.SoundUnit.Stream('Angelica-Machi.mp3');

end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  ;
end;

procedure TMainForm.CardTableCardRestoredEvent;
//A card has been restored to its original position. Just play a drop sound.
//This sound can also be used within the CardDropEvent etc.
//Keeping score or points can also be done within the sound routine as depending
//upon the sound played the points or score can be calculated.
begin
  CardGames.WinApi.SoundUnit.Sound('drop.wav');//By default mode 1.
end;

initialization
{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}

end.

