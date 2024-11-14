unit CardGames.Vcl.DeckPathForm;
//Very basic request for a directory path.
interface

uses
  WinApi.Windows
  , WinApi.Messages
  , System.SysUtils
  , System.Variants
  , System.Classes
  , Vcl.Graphics
  , Vcl.Controls
  , Vcl.Forms
  , Vcl.Dialogs
  , Vcl.StdCtrls;

type
  TDeckPathForm = class(TForm)
    Label1: TLabel;
    Edit1: TEdit;
    Button1: TButton;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Edit1KeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}

procedure TDeckPathForm.Button1Click(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TDeckPathForm.Button2Click(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TDeckPathForm.Edit1KeyPress(Sender: TObject; var Key: Char);
begin
  if Ord(Key) = 13 then
    ModalResult := mrOk;
end;

end.
