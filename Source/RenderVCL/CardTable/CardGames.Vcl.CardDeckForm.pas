unit CardGames.Vcl.CardDeckForm;
//Selects index for a string of available CardDecks.
//Modified runtime cardtable to work with turbo explorer + larger decks.
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
  , Vcl.StdCtrls
  , CardGames.Vcl.CardTable
  ;

type
  TCardDeckForm = class(TForm)
    ListBox1: TListBox;
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
    procedure ListBox1KeyPress(Sender: TObject; var Key: Char);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    CardTable: TCardTable;
    procedure ShowCards;
    procedure DrawCards;
    procedure GetDirList(SearchDir: TFileName; var Files: TStringList);
  public
    { Public declarations }
    constructor Create(AOwner: TComponent; const Current: String = 'Standard';
      const User: boolean = False; const AltPath: string = ''); reintroduce;
  end;

implementation

//uses uVistaFuncs;

{$R *.dfm}

var
  CurrentDeck, APath: String;
  LimitedToUser: Boolean;

constructor TCardDeckForm.Create(AOwner: TComponent;
  const Current: String = 'Standard'; const User: boolean = False;
  const AltPath: string = '');
//If User is True only displays user U_ cardsets.
var
  CardSetList: TStringList;
  I: integer;
begin
  inherited Create(AOwner);
  Self.Font.Assign(Screen.IconFont);
  CardTable := TCardTable.Create(self);
  CardTable.Color := clBtnFace;
  CardTable.Left := 232;
  CardTable.Top := 5;
  CardTable.Width := self.Width - 250;
  CardTable.Height := self.Height - 60;
  CurrentDeck := Current;
  LimitedToUser := User;
  APath := AltPath;
  CardSetList := TStringList.Create;
  try
    GetDirList(CardTable.CardDeck.DeckDirectory, CardSetList);
    ListBox1.Items.Assign(CardSetList);
  finally
    CardSetList.Free;
  end;
  if ListBox1.Items.Count <> 0 then
  begin
    if not LimitedToUser then
    begin
      I := ListBox1.Items.IndexOf(CurrentDeck);
      if i <> -1 then
        ListBox1.Selected[I] := True
      else
        ListBox1.Selected[ListBox1.Items.IndexOf('Standard')] := True;
    end
    else
    begin
      if ListBox1.Items.IndexOf(CurrentDeck) = -1 then
        ListBox1.Selected[0] := True
      else
        ListBox1.Selected[ListBox1.Items.IndexOf(CurrentDeck)] := True;
    end;
    CardTable.CardDeck.AltDeckDirectory := AltPath;
    DrawCards;
    ShowCards;
  end;
end;

procedure TCardDeckForm.Button1Click(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TCardDeckForm.DrawCards;
var
  i: Integer;
  ACard: TCard;
begin
  for i := 1 to 24 do
    ACard := CardTable.CardDeck.Draw;
  CardTable.TurnOverCard(ACard);
  CardTable.PlaceCard(ACard, 10, 20);
  for i := 1 to 28 do
    ACard := CardTable.CardDeck.Draw;
  CardTable.TurnOverCard(ACard);
  CardTable.PlaceCard(ACard, 155, 20);
end;

procedure TCardDeckForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  CardTable := nil;
  CardTable.Free;
end;

procedure TCardDeckForm.ShowCards;
begin
  if CardTable.CardDeck.DeckName <> ListBox1.Items[ListBox1.ItemIndex] then
  begin
    CardTable.CardDeck.DeckName := ListBox1.Items[ListBox1.ItemIndex];
    CardTable.DeckOrBackChanged;
  end;
end;

procedure TCardDeckForm.ListBox1Click(Sender: TObject);
begin
  ShowCards;
end;

procedure TCardDeckForm.ListBox1KeyPress(Sender: TObject; var Key: Char);
begin
  if Ord(Key) = 13 then
    ModalResult := mrOk;
end;

procedure TCardDeckForm.GetDirList(SearchDir: TFileName; var Files:
  TStringList);
var
  SearchRec: TSearchRec;
  DosError: Integer;
begin
 	Files.Clear;
  Files.CaseSensitive := False;
  Files.Sorted := True;
  Files.Duplicates := dupIgnore;
	SearchDir := SearchDir + '\*.*';
	try
		DosError := FindFirst(SearchDir, faDirectory, SearchRec);
		while DosError = 0 do
		begin
			if (SearchRec.Attr and faDirectory = faDirectory) and
        (SearchRec.Name[1] <> '.') then
          if LimitedToUser then
          begin
            if Pos('U_', SearchRec.Name) = 1 then
              Files.Add(SearchRec.Name);
          end
          else
            Files.Add(SearchRec.Name);
			DosError := FindNext(SearchRec);
		end;
    if APath <> '' then
    begin
      SearchDir := APath + '\*.*';
      DosError := FindFirst(SearchDir, faDirectory, SearchRec);
		  while DosError = 0 do
		  begin
			  if (SearchRec.Attr and faDirectory = faDirectory) and
          (SearchRec.Name[1] <> '.') then
            if LimitedToUser then
            begin
              if Pos('U_', SearchRec.Name) <> 0 then
                Files.Add(SearchRec.Name);
            end
            else
              Files.Add(SearchRec.Name);
			  DosError := FindNext(SearchRec);
      end;
    end;   
	finally
	  System.SysUtils.FindClose(SearchRec);
  end;
end;

end.
