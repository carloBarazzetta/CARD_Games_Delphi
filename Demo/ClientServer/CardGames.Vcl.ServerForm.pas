unit CardGames.Vcl.ServerForm;

interface

uses
  //Delphi
  System.SysUtils
  , System.Classes
  , System.Actions
  //Vcl
  , Vcl.Forms
  , Vcl.ActnList
  , Vcl.Controls
  , Vcl.StdCtrls
  , Vcl.Mask
  , Vcl.ExtCtrls
  //CardGames
  , CardGame.Server.Data
  , CardGames.Types
  ;

type
  TServerMainForm = class(TForm)
    ActionList: TActionList;
    acStartBriscolaServer: TAction;
    EventsMemo: TMemo;
    acStopBriscolaServer: TAction;
    ConnectionPanel: TPanel;
    ButtonSendString: TButton;
    TCPServerMemo: TMemo;
    gbConnection: TGroupBox;
    edHost: TLabeledEdit;
    edPort: TLabeledEdit;
    Edit1: TEdit;
    btConnectDisconnect: TButton;
    SimulateButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btConnectDisconnectClick(Sender: TObject);
    procedure SimulateButtonClick(Sender: TObject);
  private
    CardGameServerData: TCardGameServerData;
    procedure UpdateEventList(const AEvent: string);
    procedure UpdateTCPServerList(const AEvent: string);
  public
    constructor Create(Ownert: TComponent); override;
    destructor Destroy; override;
  end;

var
  ServerMainForm: TServerMainForm;

implementation

uses
  CardGames.Events
  , Briscola.CardGame
  ;

{$R *.dfm}

procedure TServerMainForm.btConnectDisconnectClick(Sender: TObject);
begin
  btConnectDisconnect.Caption :=
    CardGameServerData.TCPServerConnectDisconnect(
      edHost.Text, StrToInt(edPort.Text));
end;

constructor TServerMainForm.Create(Ownert: TComponent);
begin
  inherited;
  CardGameServerData := TCardGameServerData.Create(Self);
  CardGameServerData.OnUpdateServerEvent := UpdateEventList;
  CardGameServerData.OnTCPServerEvent := UpdateTCPServerList;
end;

destructor TServerMainForm.Destroy;
begin
  CardGameServerData.OnUpdateServerEvent := nil;
  CardGameServerData.OnTCPServerEvent := nil;
  inherited;
end;

procedure TServerMainForm.FormCreate(Sender: TObject);
begin
  //Forse immediate start of TCP server
  btConnectDisconnect.OnClick(btConnectDisconnect);

  acStartBriscolaServer.Execute;
end;

procedure TServerMainForm.SimulateButtonClick(Sender: TObject);
var
  LResponse: string;
begin
  CardGameServerData.StartBriscolaServer(btBriscolaTwoPlayers,
    LResponse);
  CardGameServerData.NewBriscolaGame(btBriscolaTwoPlayers,
    'carlo', ptHuman, ptAI);
end;

procedure TServerMainForm.UpdateEventList(const AEvent: string);
begin
  EventsMemo.Lines.Add(AEvent);
end;

procedure TServerMainForm.UpdateTCPServerList(const AEvent: string);
begin
  TCPServerMemo.Lines.Add(AEvent);
end;

initialization
{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}

end.

