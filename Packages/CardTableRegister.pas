{
CardTable
Copyright © 2023 Ethea S.r.l.

Original code is Copyright © 2004/05/06/07/08 by David Mayne.
}
unit CardTableRegister;

interface

uses
  SysUtils;

  procedure Register;

implementation

uses
  CardTable,
  System.Classes;

procedure Register;
begin
  RegisterComponents('CardTable', [TCardTable]);
end;

initialization

finalization

end.
