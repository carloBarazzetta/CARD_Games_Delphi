{
Briscola
Copyright © 2024 Ethea S.r.l.
Authors: Carlo & Lorenzo Barazzetta
Contributors:

Original code (Patience Game) is Copyright © 2004/05/06/07/08 by David Mayne.
}
program Briscola;

uses
  Vcl.Forms,
  Vcl.Themes,
  Vcl.Styles,
  Briscola.MainForm in '..\..\Source\Briscola.MainForm.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskBar := True;
  Application.ActionUpdateDelay := 50;
  Application.Title := 'Briscola';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
