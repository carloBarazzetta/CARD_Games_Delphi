unit Briscola.ServerForm;

interface

uses
  System.SysUtils
  , Vcl.Forms
  , System.Classes
  , Vcl.Menus
  ;

type
  TMainForm = class(TForm)
  private
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

initialization
{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}

end.

