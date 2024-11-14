unit CardGames.WinApi.ImageArray;
//24bit bitmap transformation.

interface

uses
  WinApi.Windows
  , System.SysUtils
  , System.UITypes
  , System.Types
  , Vcl.Graphics
(*
  , Vcl.dialogs
*)
  , System.Classes
  , System.Math
  ;

type

  TRGBTripleArray = array[0..10000] of TRGBTriple;
  PRGBTripleArray = ^TRGBTripleArray;
  SiCoDiType = record
	  si, co, di : Single;//sine, cosine, distance.
  end;
 
  TImageArray = Class(TObject)
  private
    FWidth: SmallInt;
    FHeight: SmallInt;
    FTransparentColor: TColor;
    procedure SetWidth(AWidth: SmallInt);
    procedure SetHeight(AHeight: SmallInt);
    function SiCoDiPoint(const p1, p2: TPoint): SiCoDiType;
  public
    Pixels24: array of array of TRGBTriple;
    Palette: HPalette;
    constructor Create;
    procedure Assign(const AImage: TImageArray);
    procedure AssignFromBitmap(const ABitmap: TBitmap);
    procedure RotateBitmap(
		  out   BitMapRotated: TBitMap;//output bitmap
		  const theta: Single;   //rotn angle in radians counterclockwise in windows
		  const oldAxis: TPoint; //center of rotation in pixels, rel to bmp origin
		  var   newAxis: TPoint; //center of rotated bitmap, relative to bmp origin
      const Scale: Single;   //resize ratio
      const Flip: boolean;  //horizontal flip flag
      const UseWhite: boolean = false);  //Use white as transparent color.
    procedure SaveToStream(AStream: TMemoryStream);
    procedure LoadFromStream(AStream: TMemoryStream);
    property Width: SmallInt read FWidth write SetWidth;
    property Height: SmallInt read FHeight write SetHeight;
    property TransparentColor: TColor read FTransparentColor write
      FTransparentColor;
    procedure ChangeBlack(BitMap: TBitMap);
  end;

implementation

constructor TImageArray.Create;
begin
  inherited Create;
  FWidth := 0;
  FHeight := 0;
  SetLength(Pixels24, 0);
end;

procedure TImageArray.SetHeight(AHeight: SmallInt);
var
  Lx: SmallInt;
begin
  if AHeight = FHeight then Exit;
  FHeight := AHeight;                           
  if Width = 0 then Exit;
  for Lx := 0 to Width - 1 do
    SetLength(Pixels24[Lx], AHeight);
end;

procedure TImageArray.SetWidth(AWidth: SmallInt);
Var
  Lx: SmallInt;
begin
  if AWidth = FWidth then Exit;
  SetLength(Pixels24, AWidth);
  if AWidth > FWidth then
    for Lx := FWidth to AWidth - 1 do
      SetLength(Pixels24[Lx], FHeight);
  FWidth := AWidth;
end;

procedure TImageArray.Assign(const AImage: TImageArray);
var
  Lx, Ly: SmallInt;
begin
  Height := AImage.Height;
  Width := AImage.Width;
  TransParentColor := AImage.TransparentColor;
  for Ly := 0 to Height - 1 do for Lx := 0 to Width - 1 do
    Pixels24[Lx,Ly] := AImage.Pixels24[Lx,Ly];
end;

procedure TImageArray.AssignFromBitmap(const ABitmap: TBitmap);
var
  LRow24: pRGBTripleArray;
  Lx, Ly: SmallInt;
begin
  if ABitmap.PixelFormat <> pf24bit then ABitmap.PixelFormat := pf24bit;
  Width := ABitmap.Width;
  Height := ABitmap.Height;
  TransparentColor := ABitmap.Canvas.Pixels[0, Height-1];
  for Ly := 0 to Height - 1 do
  begin
    LRow24 := ABitmap.ScanLine[Ly];
    for Lx := 0 to Width - 1 do
      Pixels24[Lx,Ly] := LRow24[Lx];
  end;
end;

//Calculate sine/cosine/distance from Integer coordinates.
//This is MUCH faster than using angle functions such as arctangent.
function TImageArray.SiCoDiPoint(const p1, p2: TPoint): SiCoDiType;
var
 	dx, dy: Integer;
begin
	dx := ( p2.x - p1.x );
  dy := ( p2.y - p1.y );
	with result do
  begin
		di := HYPOT(dx, dy);
		if abs(di) < 1 then
    begin
      si := 0.0;
      co := 1.0
    end // Zero length line
		else
      begin
        si := dy/di;
        co := dx/di;
      end;
	end;
end;

//Rotate bitmap about an arbritray center point.
//Original image is an array. This makes the algorithm much faster since
//scanline does not need to be called for each pixel of the rotated bitmap.
procedure TImageArray.RotateBitmap(
		out   BitMapRotated: TBitMap;//Output bitmap.
		const theta: Single;//Rotn angle in radians counterclockwise in windows.
		const oldAxis: TPoint;//Center of rotation in pixels, rel to bmp origin.
		var   newAxis: TPoint;//Center of rotated bitmap, relative to bmp origin.
    const Scale : Single;
    const Flip : boolean;//Mask of rotated bitmap.
    const UseWhite: boolean = false);//Use white as transparent color.
var
	cosTheta,sinTheta: single;//In windows.
	i,j,iPrime,jPrime: Integer;
	iOriginal,jOriginal: Integer;
	NewWidth,NewHeight: Integer;
	Oht,Owi,Rht,Rwi: Integer;//Original and Rotated subscripts to bottom/right.
	RowRotatedT: pRGBtripleArray;//3 bytes.
	TransparentT: TRGBTriple;
  SiCoPhi: SiCoDiType;//Sine, cosine, distance.
  LBmpRowBytes : Integer;
  ScaleInv : Single;
  T: Boolean;
begin
  T := BitMapRotated.Transparent;
  BitMapRotated.Transparent := False;//Fixes some problems.
  BitmapRotated.PixelFormat := pf24Bit;
//COUNTERCLOCKWISE rotation angle in radians.
	sinTheta := SIN( theta ); cosTheta := COS( theta );
  ScaleInv := 1 / Scale;
//Calculate the enclosing rectangle.
	NewWidth  := abs(Round(Height*sinTheta*Scale)) +
    abs(Round( Width*cosTheta*Scale));                     
	NewHeight := abs( Round(Width*sinTheta*Scale )) +
    abs(Round( Height*cosTheta*Scale));
//Local constants for loop, each was hit at least width*height times.
	Rwi := NewWidth - 1;//right column index.
	Rht := NewHeight - 1;//bottom row index.
	Owi := Width - 1;//transp color column index.
	Oht := Height - 1;//transp color row  index.
//Transparent pixel color used for out of range pixels unless UseWhite set.
  if UseWhite then
  begin
    TransparentT.rgbtBlue := 255;
    TransparentT.rgbtGreen := 255;
    TransparentT.rgbtRed := 255;
  end
  else
    TransparentT := Pixels24[0,Oht];
//Diff size bitmaps have diff resolution of angle, ie r*sin(theta)<1 pixel.
  if {abs(sinTheta) * MAX(Width, Height) > 1}Theta <> 0 then
  begin//Non-zero rotation.
//Set output bitmap formats; we do not assume a fixed format or size.
    BitmapRotated.Width  := NewWidth;//Resize it for rotation.
    BitmapRotated.Height := NewHeight;
    RowRotatedT := BitmapRotated.ScanLine[0];
    LBmpRowBytes := Integer(BitmapRotated.ScanLine[1]) - Integer(RowRotatedT);
//Step through each row of rotated image.
	  for j := 0 to Rht do
    begin
//Offset origin by the growth factor.
		  jPrime := 2*j - Rht;
//Step through each column of rotated image.
		  for i := Rwi downto 0 do
      begin
//Offset origin by the growth factor.
        iPrime := 2*i - Rwi;
//Rotate (iPrime, jPrime) to location of desired pixel	(iPrimeRotated,
//jPrimeRotated). Transform back to pixel coordinates of image, including
//translation of origin from axis of rotation to origin of image.
			  iOriginal := ( Round( ScaleInv*(iPrime*CosTheta - jPrime*sinTheta) ) -1
          + Width ) div 2;
			  jOriginal := ( Round( ScaleInv*(iPrime*sinTheta + jPrime*cosTheta) ) -1
          + Height) div 2 ;
        if Flip then iOriginal := Owi - iOriginal;
//Make sure (iOriginal, jOriginal) is in ImageOriginal. If not assign
//background color to corner points.
			  if ( iOriginal >= 0 ) and ( iOriginal <= Owi ) and
           ( jOriginal >= 0 ) and ( jOriginal <= Oht ) then
//Inside.
//Assign pixel from rotated space to current pixel in BitmapRotated (nearest
//neighbor interpolation).
          RowRotatedT[i] := Pixels24[iOriginal,jOriginal]
			  else
//Outside.
//Set background corner color to transparent (lower left corner).
          RowRotatedT[i] := TransparentT;
		  end;
//Increment scanline position - faster than calling scanline for every row.
      inc(Integer(RowRotatedT), LBmpRowBytes);
    end;
  end
  else
    begin//Zero rotation.
//Set output bitmap formats; we do not assume a fixed format or size.
   	  BitmapRotated.Width  := NewWidth;//Resize it for rotation.
   	  BitmapRotated.Height := NewHeight;
//Create destination bitmap.
      RowRotatedT := BitmapRotated.ScanLine[0];
      LBmpRowBytes := Integer(BitmapRotated.ScanLine[1]) - Integer(RowRotatedT);
      for j := 0 to Rht do
      begin
        jOriginal := Trunc(ScaleInv*j);
        for i := Rwi downto 0 do
        begin
          iOriginal := Trunc(ScaleInv*i);
          if Flip then iOriginal := Owi - iOriginal;
          RowRotatedT[i] := Pixels24[iOriginal, jOriginal];
        end;
        Inc(Integer(RowRotatedT), LBmpRowBytes);
      end;
    end;
//Offset to the apparent center of rotation.
//Rotate/translate the old bitmap origin to the new bitmap origin.
  sicoPhi := sicodiPoint(Point(width div 2, height div 2), oldaxis);
//Sine/cosine/dist of axis point from center point.
  with sicoPhi do begin
    NewAxis.x := newWidth div 2 + Round( Scale*di*(CosTheta*co - SinTheta*si));
//Flip yaxis.
    NewAxis.y := newHeight div 2- Round( Scale*di*(SinTheta*co + CosTheta*si));
  end;
  BitMapRotated.Transparent := T;
end;

procedure TImageArray.SaveToStream(AStream : TMemoryStream);
var
  Lx, Ly: SmallInt;
begin
  with AStream do begin
    Write(FWidth, SizeOf(SmallInt));
    Write(FHeight, SizeOf(SmallInt));
    Write(FTransparentColor, SizeOf(TColor));
    for Ly := 0 to FHeight - 1 do for Lx := 0 to FWidth - 1 do
      Write(Pixels24[Lx,Ly], SizeOf(TRGBTriple));
  end;
end;

procedure TImageArray.LoadFromStream(AStream : TMemoryStream);
Var
  Lx, Ly: SmallInt;
begin
  with AStream do begin
    Read(Lx, SizeOf(SmallInt));
    Read(Ly, SizeOf(SmallInt));
    Width := Lx;
    Height := Ly;
    Read(FTransparentColor, SizeOf(TColor));
    for Ly := 0 to FHeight - 1 do for Lx := 0 to FWidth - 1 do
      Read(Pixels24[Lx,Ly], SizeOf(TRGBTriple));
  end;
end;

procedure TImageArray.ChangeBlack(BitMap: TBitMap);
//Change black thru image.
var
  Lx, Ly: Integer;
  P: PRGBTripleArray;
begin
  if Bitmap.PixelFormat <> pf24bit then Bitmap.PixelFormat := pf24bit;
  for Ly := 0 to BitMap.Height - 1 do
  begin
    P := Bitmap.ScanLine[Ly];
    for Lx := 0 to BitMAp.Width - 1 do
    begin
     if (P[Lx].rgbtBlue + P[Lx].rgbtGreen + P[Lx].rgbtRed < 30) then
      P[Lx].rgbtRed := 30;
    end;
  end;
end;

end.
