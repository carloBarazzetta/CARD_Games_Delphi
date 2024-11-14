{
Vcl.CardTableEngine
Copyright © 2024 Ethea S.r.l.
Author: Carlo Barazzetta
Contributors:
Original code is Copyright © 2004/05/06/07/08 by David Mayne.

DESCRIPTION:

VCL CardTable Engines (input and drawing)

TDrawingEngine: CardGames Drawing Engine

Sprite:
  CardTable sprite class. Draw & UnDraw. Lift, Rotate, Shrink and Grow.
  Add graphic with Sprite.BitMap.Assign.
  Properties include X,Y, Angle, Scale, and Displayed.
  SaveToFile method saves a transformed bitmap to a file.
  One instance is maintained & redrawn by cardtable.
}
unit CardGames.Vcl.CardGame.Engine;

interface

uses
  WinApi.Windows
  , Vcl.Graphics
  , Vcl.ExtCtrls
  , WinApi.Messages
  , Vcl.Controls
(*
  , System.Types
  , System.Classes
  , System.SysUtils
  , Vcl.Imaging.Jpeg
  , BackDrop
  , ImageArrayUnit
*)
  ;

type
  //Forward declarations.
  TDrawingEngine = class;

  TDrawingEngine = class(TObject)
  public
    constructor Create; virtual;
    function ScaleFactor: Single;
    function Scaled(const AValue: Integer): Integer;
    procedure StretchBlt(const DestDC: HDC; const X,Y,Width,Height: Integer;
      const SourceDC: HDC; const XSrc, YSrc, WidthSrc, HeightSrc: Integer; Rop: DWORD);
    procedure BitBlt(const DestDC: HDC; const X,Y,Width,Height: Integer;
      const SourceDC: HDC; const XSrc, YSrc, Rop: DWORD);
    procedure CopyBuffer(const DestDC: HDC; const X, Y, Width, Height: Integer;
      const SourceDC: HDC);
  end;

implementation

uses
  Vcl.Forms
  ;

{ TDrawingEngine }

constructor TDrawingEngine.Create;
begin
  inherited;
end;

function TDrawingEngine.Scaled(const AValue: Integer): Integer;
begin
  Result := Round(AValue * ScaleFactor);
end;

function TDrawingEngine.ScaleFactor: Single;
begin
(*
  if Assigned(FOwner) and (FOwner.Parent is TForm) then
    Result := TForm(FOwner.Parent).ScaleFactor
  else
*)
    Result := 1;
end;

procedure TDrawingEngine.CopyBuffer(const DestDC: HDC; const X, Y, Width, Height: Integer;
  const SourceDC: HDC);
begin
  Winapi.Windows.BitBlt(DestDC, Scaled(X), Scaled(Y), Scaled(Width), Scaled(Height),
      SourceDC, Scaled(X), Scaled(Y), SRCCOPY);
end;

procedure TDrawingEngine.StretchBlt(const DestDC: HDC; const X, Y, Width,
  Height: Integer; const SourceDC: HDC; const XSrc, YSrc, WidthSrc,
  HeightSrc: Integer; Rop: DWORD);
begin
  Winapi.Windows.StretchBlt(DestDC, Scaled(X), Scaled(Y), Scaled(Width), Scaled(Height), SourceDC,
    XSrc, YSrc, WidthSrc, HeightSrc, Rop);
end;

procedure TDrawingEngine.BitBlt(const DestDC: HDC; const X, Y, Width,
  Height: Integer; const SourceDC: HDC; const XSrc, YSrc, Rop: DWORD);
begin
  //Winapi.Windows.StretchBlt(DestDC, Scaled(X), Scaled(Y), Scaled(Width), Scaled(Height), SourceDC,
  //  XSrc, YSrc, Width, Height, Rop);
  Winapi.Windows.BitBlt(DestDC, Scaled(X), Scaled(Y), Scaled(Width), Scaled(Height), SourceDC,
    Scaled(XSrc), Scaled(YSrc), Rop);
end;

initialization

finalization

end.
