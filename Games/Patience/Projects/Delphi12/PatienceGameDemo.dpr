{
Patience Game (demo)
Copyright © 2024 Ethea S.r.l.
Author: Carlo Barazzetta
Contributors:

Original code is Copyright © 2004/05/06/07/08 by David Mayne.
}
program PatienceGameDemo;

uses
  Vcl.Forms,
  Patience.MainForm in '..\..\Source\Patience.MainForm.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskBar := True;
  Application.ActionUpdateDelay := 50;
  Application.Title := 'Patience Game - Demo';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
