unit CardGames.Vcl.Backdrop;
//Modified Gradient Backdrop. RefreshEvent needs to be handled and paint called
//when it ocurrs by the calling class. When the Enabled property is set to False
//no redrawing on the bitmap occurs so the calling class must redraw it. Colors
//not used tint the bitmap, the properties Change r,g or b are set to false if
//not used. Otherwise they are changed from 0 to 255 to affect the gradient.
//Likewise the Start color value is meaningfull only if the color is not used ie
//set to false.
//
//IMORTANT NOTE.
//Now two different methods can be used to draw gradient. Original & new with
//different properties used to set them. Its not too messy.
//New method is generalised and can be used outside of CardTable.
//Procedure DrawGradient(ABitmap: TBitmap; ACanvas: TCanvas; ARect: TRect;
//  ColorFrom, ColorTo: TColor;  Style: TGradientStyle);
//To use within TBackDrop set New Backdrop properties:
//  NewMode       - Boolean default false set true to enable new gradient
//  NewColorFrom  - Start colour
//  NewColorTo    - End colour
//  NewType       - gradient direction of TGradientStyle.

interface

uses
  WinApi.Windows
  , WinApi.Messages
  , System.UITypes
  , Vcl.Graphics
  , System.Classes
  ;

type
//New gradient mode.////////////////////////////////////////////////////////////
  TLargeColorQuad = record
    Red, Green, Blue, Alpha: Longint;
  end;
  TColorQuad = record
    Red, Green, Blue, Alpha: Byte;
  end;
  T32bitScanLineElement = record
    Blue, Green, Red, Alpha: Byte;
  end;
  P32bitQuadScanLine = ^T32bitQuadScanLine;
  T32bitQuadScanLine = array[0..High(Word) div 3] of T32bitScanLineElement;
  TGradientStyle  = (gsHorizontal, gsVertical, gsDiagonalLeftRight,
    gsDiagonalRightLeft);
////////////////////////////////////////////////////////////////////////////////

  TFillDirection = (drLeftRight, drRightLeft, drUpDown, drDownUp);
  TRefreshEvent = procedure of object;
  TBackdrop = class(TPersistent)
  private
    { Private declarations }
    FBitMap: TBitMap;
    FStartR: Byte;
    FStartG: Byte;
    FStartB: Byte;
    FChangeR: Boolean;
    FChangeG: Boolean;
    FChangeB: Boolean;
    FDirection: TFillDirection;
    FEnabled: Boolean;
    FRefreshEvent: TRefreshEvent;
    FNewMode: Boolean;
    FNewColorFrom: TColor;
    FNewColorTo: TColor;
    FNewType: TGradientStyle;
    procedure FillBackdrop;
    function RectLeftRight(i, w2: Integer; w: Real): TRect;
    function RectRightLeft(i, w2: Integer; w: Real): TRect;
    function RectUpDown(i, w2: Integer; w: Real): TRect;
    function RectDownUp(i, w2: Integer; w: Real): TRect;
    procedure ChangeDrawR(NewVal: Boolean);
    procedure ChangeDrawG(NewVal: Boolean);
    procedure ChangeDrawB(NewVal: Boolean);
    procedure ChangeStartR(NewVal: Byte);
    procedure ChangeStartG(NewVal: Byte);
    procedure ChangeStartB(NewVal: Byte);
    procedure ChangeDirection(NewVal: TFillDirection);
    procedure ChangeEnabled(NewVal: Boolean);
    procedure SetNewColorFrom(Color: TColor);
    procedure SetNewColorTo(Color: TColor);
    procedure SetNewType(NewType: TGradientStyle);
    procedure SetNewMode(Mode: Boolean);
  protected
    { Protected declarations }
    procedure RefreshNeeded;
  public
    { Public declarations }
    constructor Create;
    destructor Destroy; override;
    procedure Paint(BitMap: TBitMap);
  published
    { Published declarations }
    property Enabled: Boolean read FEnabled write ChangeEnabled;
    property NewMode: Boolean read FNewMode write SetNewMode;
    property ChangeRColour: Boolean Read FChangeR Write ChangeDrawR;
    property ChangeGColour: Boolean Read FChangeG Write ChangeDrawG;
    property ChangeBColour: Boolean Read FChangeB Write ChangeDrawB;
    property Direction: TFillDirection Read FDirection Write ChangeDirection;
    property StartR: Byte Read FStartR Write ChangeStartR;
    property StartG: Byte Read FStartG Write ChangeStartG;
    property StartB: Byte Read FStartB Write ChangeStartB;
    property RefreshEvent: TRefreshEvent read FRefreshEvent write FRefreshEvent;
    property NewColorFrom: TColor read FNewColorFrom write SetNewColorFrom;
    property NewColorTo: TColor read FNewColorTo write SetNewColorTo;
    property NewType: TGradientStyle read FNewType write SetNewType;
  end;

//New gradient mode.////////////////////////////////////////////////////////////
  procedure DrawGradient(ABitmap: TBitmap; ACanvas: TCanvas; ARect: TRect;
    ColorFrom, ColorTo: TColor;  Style: TGradientStyle);
  function RGB2(Red, Green, Blue: Byte; Alpha: Byte = $00): TColor;
////////////////////////////////////////////////////////////////////////////////

implementation

constructor TBackdrop.Create;
begin
  FDirection := drLeftRight;
  FChangeR := True;
  FChangeG := True;
  FChangeB := True;
  FEnabled := False;
  FNewMode := False;
end;

destructor TBackdrop.Destroy;
begin
  inherited Destroy;
end;

procedure TBackdrop.Paint(BitMap: TBitMap);
begin
  if FEnabled then
  begin
    FBitmap := BitMap;
    if not FNewMode then
      FillBackdrop
    else
      begin
        DrawGradient(FBitMap, nil, rect(0,0, FBitMap.Width, FBitMap.Height),
          FNewColorFrom, FNewColorTo, FNewType);
      end;
  end;
end;

procedure TBackdrop.FillBackdrop;
var
  W: Real;
  W2: Integer;
  R,G,B: Integer;
  i: Integer;
  RectArea: TRect;
begin
  // Calculate the size of each strip of colour (there will be 256 of them)
  if FDirection <= drRightLeft then
    W := FBitMap.Width / 256
  else
    W := FBitMap.Height / 256;
  W2 := Round(W + 0.5);
  // The starting values for each colour.  If a colour is not used then the
  // starting value will tint the entire control in a funky fashion
  R := FStartR;
  G := FStartG;
  B := FStartB;
  // Display 256 different coloured rectangles along the component to display
  // a smooth gradient
  for i := 0 to 255 do
  begin
    if FChangeR then R := i;
    if FChangeG then G := i;
    if FChangeB then B := i;
    FBitMap.Canvas.Brush.Color := RGB(R, G, B);
    // Figure out which part of the image to fill
    case FDirection of
      drLeftRight: RectArea := RectLeftRight(i,w2,w);
      drRightLeft: RectArea := RectRightLeft(i,w2,w);
      drUpDown   : RectArea := RectUpDown(i,w2,w);
      drDownUp   : RectArea := RectDownUp(i,w2,w);
    end;
    FBitMap.Canvas.FillRect(RectArea);
  end;
end;

function TBackdrop.RectLeftRight(i, w2: Integer; w: Real): TRect;
begin
  Result := Bounds(Round(w * i), 0, w2, FBitMap.Height);
end;

function TBackdrop.RectRightLeft(i, w2: Integer; w: Real): TRect;
begin
  Result := Bounds(Round(w * (255 - i)), 0, w2, FBitMap.HEIGHT);
end;

function TBackdrop.RectUpDown(i, w2: Integer; w: Real): TRect;
begin
  Result := Bounds(0, Round(w * i), FBitMap.Width, w2);
end;

function TBackdrop.RectDownUp(i, w2: Integer; w: Real): TRect;
begin
  Result := Bounds(0, Round(w * (255 - i)), FBitMap.Width, w2);
end;

procedure TBackdrop.ChangeDrawR(NewVal: Boolean);
begin
  if NewVal <> FChangeR then
  begin
    FChangeR := NewVal;
    if not FNewMode then RefreshNeeded;
  end;
end;

procedure TBackdrop.ChangeDrawG(NewVal: Boolean);
begin
  if NewVal <> FChangeG then
  begin
    FChangeG := NewVal;
    if not FNewMode then RefreshNeeded;
  end;
end;

procedure TBackdrop.ChangeDrawB(NewVal: Boolean);
begin
  if NewVal <> FChangeB then
  begin
    FChangeB := NewVal;
    if not FNewMode then RefreshNeeded;
  end;
end;

procedure TBackdrop.ChangeStartR(NewVal: Byte);
begin
  if FStartR <> NewVal then
  begin
    FStartR := NewVal;
    if not FNewMode then RefreshNeeded;
  end;
end;

procedure TBackdrop.ChangeStartG(NewVal: Byte);
begin
  if FStartG <> NewVal then
  begin
    FStartG := NewVal;
    if not FNewMode then RefreshNeeded;
  end;
end;

procedure TBackdrop.ChangeStartB(NewVal: Byte);
begin
  if FStartB <> NewVal then
  begin
    FStartB := NewVal;
    if not FNewMode then RefreshNeeded;
  end;
end;

procedure TBackdrop.ChangeDirection(NewVal: TFillDirection);
begin
  if NewVal <> FDirection then
  begin
    FDirection := NewVal;
    if not FNewMode then RefreshNeeded;
  end;
end;

procedure TBackdrop.ChangeEnabled(NewVal: Boolean);
begin
  If NewVal <> FEnabled then
  begin
    FEnabled := NewVal;
//Does not update disable in design state but causes no flicker when running.
    if NewVal = True then RefreshNeeded;
  end;
end;

procedure TBackdrop.RefreshNeeded;
begin
  if Assigned(FRefreshEvent) then
    FRefreshEvent;
end;

procedure TBackdrop.SetNewColorFrom(Color: TColor);
begin
  if Color <> FNewColorFrom then
  begin
    FNewColorFrom := Color;
    if FNewMode then RefreshNeeded;
  end;
end;

procedure TBackdrop.SetNewColorTo(Color: TColor);
begin
  if Color <> FNewColorTo then
  begin
    FNewColorTo := Color;
    if FNewMode then RefreshNeeded;
  end;
end;

procedure TBackdrop.SetNewType(NewType: TGradientStyle);
begin
  if NewType <> FNewType then
  begin
    FNewType := NewType;
    if FNewMode then RefreshNeeded;
  end;
end;

procedure TBackdrop.SetNewMode(Mode: Boolean);
begin
  if Mode <> FNewMode then
  begin
    FNewMode := Mode;
    RefreshNeeded;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

//Draws gradient bar to the bitmap or canvas with given parameters. Does not
//support negative rects. Switch ColorFrom/ColorTo to acheive same effect. ARect
//should be inside valid ABitmap. Set ABitmap to nil if you want to use ACanvas.
//Using TBitmap is faster but not always possible.
procedure DrawGradient(ABitmap: TBitmap; ACanvas: TCanvas; ARect: TRect;
  ColorFrom, ColorTo: TColor; Style: TGradientStyle);
var
  UseBitmap: Boolean;
  DrawCanvas: TCanvas;
  OldBrushHandle, NewBrushHandle: HBRUSH;
  GradientWidth, GradientHeight: Integer;
  DrawFrom, DrawTo, I, X, Y: Integer;
  ColorFromQuad, ColorToQuad: TLargeColorQuad;
  ColorValue: TColor;
  P, PF: P32bitQuadScanLine;

  procedure FillScanLine(AColor: TColor);
  var X: Integer;
  begin
    if UseBitmap then
    begin
      for X := ARect.Left to ARect.Right - 1 do
      begin
        {$R-}
        P^[X].Red := TColorQuad(AColor).Red;
        P^[X].Green := TColorQuad(AColor).Green;
        P^[X].Blue := TColorQuad(AColor).Blue;
        P^[X].Alpha := $00;
      end;
    end else
    begin
      NewBrushHandle := CreateSolidBrush(AColor);
      OldBrushHandle := SelectObject(DrawCanvas.Handle, NewBrushHandle);
      try
        PatBlt(DrawCanvas.Handle, ARect.Left, Y, GradientWidth, 1, PATCOPY);
      finally
        SelectObject(DrawCanvas.Handle, OldBrushHandle);
        DeleteObject(NewBrushHandle);
      end;
    end;
  end;

begin
  UseBitmap := Assigned(ABitmap);
  if UseBitmap then
  begin
    DrawCanvas := ABitmap.Canvas;
    ABitmap.PixelFormat := pf32bit;
  end else
    DrawCanvas := ACanvas;
  with DrawCanvas do
  begin
    GradientWidth := ARect.Right - ARect.Left;
    GradientHeight := ARect.Bottom - ARect.Top;
    DrawFrom := ARect.Top;
    DrawTo := ARect.Bottom - 1;
    if (ColorFrom = ColorTo) then{ same color, just one drawing phase required }
    begin
      if UseBitmap then
      begin
        for I := DrawFrom to DrawTo do
        begin
          P := ABitmap.ScanLine[I];
          FillScanLine(ColorFrom);
        end;
      end else
      begin
        NewBrushHandle := CreateSolidBrush(ColorFrom);
        OldBrushHandle := SelectObject(Handle, NewBrushHandle);
        try
          PatBlt(Handle, 0, ARect.Top, GradientWidth, ARect.Bottom, PATCOPY);
        finally
          SelectObject(Handle, OldBrushHandle);
          DeleteObject(NewBrushHandle);
        end;
      end;
    end else
    begin
      ColorValue := ColorToRGB(ColorFrom);
      ColorFromQuad.Red := TColorQuad(ColorValue).Red;
      ColorFromQuad.Green := TColorQuad(ColorValue).Green;
      ColorFromQuad.Blue := TColorQuad(ColorValue).Blue;
      ColorValue := ColorToRGB(ColorTo);
      ColorToQuad.Red := TColorQuad(ColorValue).Red - ColorFromQuad.Red;
      ColorToQuad.Green := TColorQuad(ColorValue).Green - ColorFromQuad.Green;
      ColorToQuad.Blue := TColorQuad(ColorValue).Blue - ColorFromQuad.Blue;
      if GradientHeight > 0 then
      begin
        case Style of
          gsVertical:
            begin
              for Y := DrawFrom to DrawTo do
              begin
                I := Y - DrawFrom;
                ColorValue := RGB2(
                  (ColorFromQuad.Red + ((ColorToQuad.Red * I) div
                    GradientHeight)),
                  (ColorFromQuad.Green + ((ColorToQuad.Green * I) div
                    GradientHeight)),
                  (ColorFromQuad.Blue + ((ColorToQuad.Blue * I) div
                    GradientHeight)));
                if UseBitmap then
                  P := ABitmap.ScanLine[Y];
                try
                  FillScanLine(ColorValue);
                except
                  Exit;
                end;
              end;
            end;
          gsDiagonalLeftRight, gsDiagonalRightLeft:
            begin
              { draw first line of the gradient }
              for Y := DrawFrom to DrawTo do
              begin
                if UseBitmap then
                  P := ABitmap.ScanLine[Y];
                for X := ARect.Left to ARect.Right - 1 do
                begin
{ I is Integer so to get decimal precision we use 1024 as multiplier. Formula is
"(a + b) / 2" (where a,b are percents) the precision 1024 is pre-divided. }
                  I := Trunc(((Y - DrawFrom) / GradientHeight + (X - ARect.Left)
                     / GradientWidth) * 512);
                  ColorValue := RGB2(
                    (ColorFromQuad.Red + ((ColorToQuad.Red * I) div 1024)),
                    (ColorFromQuad.Green + ((ColorToQuad.Green * I) div 1024)),
                    (ColorFromQuad.Blue + ((ColorToQuad.Blue * I) div 1024)));
                  try
                    if Style = gsDiagonalRightLeft then
                      I := (ARect.Right - 1) - X + ARect.Left // flip on X axis
                    else
                      I := X;
                    if UseBitmap then
                    begin
                      P^[I].Red := TColorQuad(ColorValue).Red;
                      P^[I].Green := TColorQuad(ColorValue).Green;
                      P^[I].Blue := TColorQuad(ColorValue).Blue;
                      P^[I].Alpha := $00;
                    end else
                      Pixels[I, Y] := ColorValue;
                  except
                    Exit;
                  end;
                end;
              end;
            end;
          gsHorizontal:
            begin
              PF := nil;
              if UseBitmap then
                PF := ABitmap.ScanLine[DrawFrom];
              for X := ARect.Left to ARect.Right - 1 do
              begin
                I := X - ARect.Left;
                ColorValue := RGB2(
                  (ColorFromQuad.Red + ((ColorToQuad.Red * I) div
                    GradientWidth)),
                  (ColorFromQuad.Green + ((ColorToQuad.Green * I) div
                    GradientWidth)),
                  (ColorFromQuad.Blue + ((ColorToQuad.Blue * I) div
                    GradientWidth)));
                try
                  if UseBitmap and Assigned(PF) then
                  begin
                    PF^[X].Red := TColorQuad(ColorValue).Red;
                    PF^[X].Green := TColorQuad(ColorValue).Green;
                    PF^[X].Blue := TColorQuad(ColorValue).Blue;
                    PF^[X].Alpha := $00;
                  end else
                    Pixels[X, DrawFrom] := ColorValue;
                except
                  Exit;
                end;
              end;
              { copy the first line till end }
              if UseBitmap then
              begin
                for Y := DrawFrom + 1 to DrawTo do
                  for X := ARect.Left to ARect.Right - 1 do
                  begin
                    P := ABitmap.ScanLine[Y];
                    P^[X].Red := PF^[X].Red;
                    P^[X].Green := PF^[X].Green;
                    P^[X].Blue := PF^[X].Blue;
                    P^[X].Alpha := PF^[X].Alpha;
                  end;
              end else
              begin
                CopyRect(Rect(ARect.Left, DrawFrom + 1, ARect.Right, DrawTo + 1)
                  , DrawCanvas, Rect(ARect.Left, DrawFrom, ARect.Right,
                  DrawFrom + 1));
              end;
            end;
        end;
      end;
    end;
  end;
end;

function RGB2(Red, Green, Blue: Byte; Alpha: Byte = $00): TColor;
begin
  Result := (Alpha shl 24) or (Blue shl 16) or (Green shl 8) or Red;
end;

end.
