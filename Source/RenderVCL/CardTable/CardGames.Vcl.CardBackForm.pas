{
CardTable
Copyright © 2024 Ethea S.r.l.
Author: Carlo Barazzetta
Contributors:

Original code is Copyright © 2004/05/06/07/08 by David Mayne.
}
unit CardGames.Vcl.CardBackForm;
//Selects a CardBack from all (1..9) options available.
interface

uses
  WinApi.Windows
  , System.Classes
  , Vcl.Controls
  , WinApi.Messages
  , System.SysUtils
  , Vcl.Graphics
  , Vcl.Forms
  , Vcl.Dialogs
  , CardGames.Vcl.CardTable
  ;

type
  TCardBackForm = class(TForm)
    procedure FormActivate(Sender: TObject);
    procedure CardClicked(ACard: TCard; Button: TMouseButton);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
    constructor Create(AOwner: TComponent; const Dir: String); reintroduce;
    procedure DrawBacks(AOwner: TComponent; const DeckType: String;
      const AltPath: string);
  end;

implementation

//uses uVistaFuncs;

{$R *.dfm}

var
  gCardTable: TCardTable;
  gSearchDir: string;

constructor TCardBackForm.Create(AOwner: TComponent; const Dir: String);
//Dir points to the cardsets directory.
begin
  inherited Create(AOwner);
  Self.Font.Assign(Screen.IconFont);
  gSearchDir := Dir;
end;

procedure TCardBackForm.FormActivate(Sender: TObject);
begin
  gCardTable.Show;
end;

procedure TCardBackForm.CardClicked(ACard: TCard;
  Button: TMouseButton);
//Returns value of back chosen 1-9.
begin
  ModalResult := ACard.NumericValue+ord(ACard.Suit)*10;
end;

procedure TCardBackForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  gCardTable.Free;
end;

procedure TCardBackForm.DrawBacks(AOwner: TComponent; const DeckType: String;
  const AltPath: string);
//AltPath points to alternate location for cardsets eg in My Docs.
var
  i,j: integer;
  Card: TCard;
  Back: Integer;
  CardValue: TCardValue;
  CardSuit: TCardSuit;
  S: string;
begin
//Creating a gCardTable. We know the location of the cardsets. But there is no
//way to inform gCardTable of this & we could be in any directory! But if the
//current dir is set to the dir that contains the cardsets all should be ok.
  for i := length(gSearchDir) downto 1 do
    if IsPathDelimiter(gSearchDir, i) then break;
  SetLength(gSearchDir, i-1);
  SetLength(S, MAX_PATH);
  SetLength(S, GetCurrentDirectory(MAX_PATH, PChar(S)));
  if not SameText(S, gSearchDir) then
    SetCurrentDirectory(PChar(gSearchDir));
  gCardTable := TCardTable.Create(Self);
  gCardTable.Hide;
  if AltPath <> '' then gCardTable.CardDeck.AltDeckDirectory := AltPath;
  gCardTable.CardDeck.DeckName := DeckType;
  gCardTable.Color := clSilver;
  gCardTable.OnCardClickEvent := CardClicked;
  gCardTable.Width := gCardTable.CardDeck.CardWidth * 3 + 10;
  gCardTable.Height := gCardTable.CardDeck.CardHeight * 3 + 24;
  gCardTable.Color := clSilver;
  //Note default gCardTable.MinWidth & Height MUST be specified here as the
  //defaults will mess up big time.
  gCardTable.MinWidth := 0;
  gCardTable.MinHeight := 0;
  Width := gCardTable.Width + 10;
  Height := gCardTable.Height + 20;
  Back := 1;
  CardValue := Low(TCardValue);
  CardSuit := Low(TCardSuit);
  for j:=0 to 2 do
    for i := 0 to 2 do
    begin
      Card := gCardTable.CardDeck.Draw;
      //Value & Suit indicate Back chosen.
      Card.Value := CardValue;
      Card.Suit := CardSuit;
      if CardValue <> cvTen then
        inc(CardValue)
      else begin
        CardValue := Low(TCardValue);
        inc(CardSuit);
      end;
      if gCardTable.CardDeck.CardBack = Back then
        gCardTable.PlaceCard(Card,8+i*gCardTable.CardDeck.CardWidth,
          8+J*gCardTable.CardDeck.CardHeight);
      if Back <> 9 then
      begin
        inc(Back);
        gCardTable.CardDeck.CardBack := Back;
      end;
    end;
  if not SameText(S, gSearchDir) then//Switch back to original dir.
    SetCurrentDirectory(PChar(S));
end;

end.
