unit CardGames.WinApi.MyGrphx;
{
     MyGrphx unit v1.00
     ------------------
 -------------------------

    (c) Filip Sobalski

    http://403.t35.com
    http://fite.prv.pl

      no_thing@o2.pl
  nothing@twoje-sudety.pl

 -------------------------

 adapted from MyUtils.pas
      on 13.03.2005

 modified by David for CardTable.
}

interface

uses
  WinApi.Windows
  , WinApi.Messages
  , System.SysUtils
  , System.Variants
  , System.Classes
  , System.UITypes
  , Vcl.Graphics
(*
  , Vcl.Controls
  , Vcl.Forms
  , Vcl.Dialogs
  , Vcl.StdCtrls
  , Vcl.ExtCtrls
  , Vcl.Imaging.jpeg
  , Vcl.Consts
*)
  , System.math
  ;

 type TMyRGB = record
  r : byte;
  g : byte;
  b : byte;
 end;

 type TMRGB = record
  r : byte;
  g : byte;
  b : byte;
  f : byte;
 end;

 type TRGBArray = array[0..32767] of TRGBTriple;
 type pRGBArray = ^TRGBArray;
 type TMRGBArray = array[0..32767] of TMyRgb;
 type pMRGBArray = ^TMRGBArray;
 type PBitmap = ^TBitmap;

 type TDarkenParams = array[0..255, 0..255] of byte;
 type TRadialParams = array of array of byte;
 type TLightData = array of array of smallint;
 type TOpaqueParams = array[0..255, 0..255] of byte;

const
  Count = 100;

var
  cC : array[0..255, 0..Count] of byte;

 {
  precalculates the parameters for radial darkening and writes them to the variables passed as dp and rp,
  which are needed to run DarkenRadial later;
  darkestAmount is the the amount of darkness on the edges of the circle - use values 0 - 255
 }
 procedure RadialPreCalc(var dp : TDarkenParams; var rp : TRadialParams; sizex, sizey : Integer; darkestAmount : byte);


 {
  does precalculated (quite fast) radial darkening;
  firstly you have to precalculate the need parameters by using RadialPreCalc;
  note: the size that you used to compute the parameters earlier MUST be identical to the size
  of the bitmap you are darkening by DarkenRadial, otherwise there will be surely an 'Access Violation' error
 }
 procedure DarkenRadial(bm : PBitmap; const dp : TDarkenParams; const rp : TRadialParams);

 {
  darkens the whole picture by amount set in initialization method Initc.
 }
 procedure Darken(bm : PBitmap; const Soft, TopDown: Boolean;
  const colour: Integer = 0);

 {
  precalculates the parameters for adding 'light effect' to bitmap, what speeds up the whole process
  significantly; r is the radius of the 'light'
 }
 procedure PrepareLight(r : Integer; var a : TLightData);

 {
  adds the 'radial light effect' to the bitmap at the selected coords sx, sy with radius r (it must be
  identical with the value passed when precalculating TLightData) of color lcolor and intensity lstr
 }
 procedure Light(sx, sy, r : Integer; lcolor : TColor; lstr : byte; a : TLightData; surf : TBitmap);

 {
  does bit blitting with transparency; it's as fast as BitBlt but you don't have to use it twice,
  when want to achieve transaprency (opposite from BitBlt where you need a mask too)
 }
 procedure MBlt(src, dst : TBitmap; dstx, dsty : integer; trans : TColor);


 {
  precalculates parameters to speed up the opaue blitting procedure
  opacity - use values 0 - 255
 }
 procedure PrepareOpaqueBlt(opacity : byte; var params : TOpaqueParams);

 {
  does bit blitting with transparency; it's as fast as BitBlt but you don't have to use it twice,
  when want to achieve transaprency (opposite from BitBlt where you need a mask too);
  it's intended to blit also with opacity, firstly precalculated by PrepareOpaqueBlt
 }
 procedure MBltOpaque(src, dst : TBitmap; dstx, dsty : integer; trans : TColor; const params : TOpaqueParams);

 procedure Initc(Amount: Integer);

implementation

procedure PrepareOpaqueBlt(opacity : byte; var params : TOpaqueParams);
var i, j : byte;
begin

 for i := 0 to 255 do
  for j := 0 to 255 do
   params[i, j] := trunc((i * opacity / 255) + ((255 - opacity) * j / 255));

end;

procedure MBltOpaque(src, dst : TBitmap; dstx, dsty : integer; trans : TColor; const params : TOpaqueParams);
var srcs, dsts : Integer;
    srca, dsta : pRGBArray;
    i, j, ti, tj, si, sj, pm : integer;
    tc : TMRGB;
begin
   TColor(tc) := trans;
   srcs := integer(src.scanline[1]) - integer(src.scanline[0]);
   dsts := integer(dst.scanline[1]) - integer(dst.scanline[0]);
   if (src.Width + dstx) > dst.Width then ti := dst.Width - dstx - 1 else ti := src.Width - 1;
   if (src.Height + dsty) > dst.Height then tj := dst.Height - dsty  - 1 else tj := src.Height - 1;
   if dstx < 0 then si := - dstx else si := 0;
   if dsty < 0 then sj := - dsty else sj := 0;
   if ti < 0 then exit;
   if tj < 0 then exit;
   integer(srca) := sj * srcs + integer(src.scanline[0]);
   integer(dsta) := (sj + dsty) * dsts + integer(dst.scanline[0]);
   for j := sj to tj do
    begin
     pm := dstx + si;
     for i := si to ti do
      begin
       if not((tc.r = srca^[i].rgbtRed) and (tc.g = srca^[i].rgbtGreen) and (tc.b = srca^[i].rgbtBlue)) then
        begin
         dsta^[pm].rgbtBlue := params[srca^[i].rgbtBlue, dsta^[pm].rgbtBlue];
         dsta^[pm].rgbtGreen := params[srca^[i].rgbtGreen, dsta^[pm].rgbtGreen];
         dsta^[pm].rgbtRed := params[srca^[i].rgbtRed, dsta^[pm].rgbtRed];
        end;
       inc(pm);
      end;
     integer(srca) := integer(srca) + srcs;
     integer(dsta) := integer(dsta) + dsts;
    end;
end;

procedure MBlt(src, dst : TBitmap; dstx, dsty : integer; trans :TColor);
 var srcs, dsts : Integer;
     srca, dsta : pRGBArray;
     i, j, ti, tj, si, sj : integer;
     tc : TMRGB;
 begin
   TColor(tc) := trans;
   srcs := Integer(src.scanline[1]) - Integer(src.scanline[0]);
   dsts := Integer(dst.scanline[1]) - Integer(dst.scanline[0]);
   if (src.Width + dstx) > dst.Width then ti := dst.Width - dstx - 1 else ti := src.Width - 1;
   if (src.Height + dsty) > dst.Height then tj := dst.Height - dsty  - 1 else tj := src.Height - 1;
   if dstx < 0 then si := - dstx else si := 0;
   if dsty < 0 then sj := - dsty else sj := 0;
   if ti < 0 then exit;
   if tj < 0 then exit;
   Integer(srca) := sj * srcs + Integer(src.scanline[0]);
   Integer(dsta) := (sj + dsty) * dsts + Integer(dst.scanline[0]);
   for j := sj to tj do
    begin
     for i := si to ti do
      if not((tc.r = srca^[i].rgbtRed) and (tc.g = srca^[i].rgbtGreen) and (tc.b = srca^[i].rgbtBlue)) then
       dsta^[i + dstx] := srca^[i];
     Integer(srca) := Integer(srca) + srcs;
     Integer(dsta) := Integer(dsta) + dsts;
    end;
end;

procedure PrepareLight(r : Integer; var a : TLightData);
var x, y : integer;
begin
  SetLength(a, 2*r + 1, 2*r + 1);
  for y := -r to r do begin
   for x :=  -r to r do begin
    a[x + r, y + r] := Round(Sqrt(Sqr(x) + Sqr(y)));
   end;
  end;
end;

procedure Light(sx, sy, r : Integer; lcolor : TColor; lstr : byte; a : TLightData; surf : TBitmap);
var pa : pRgbArray;
    step, x, y, od : integer;
    pp : Pointer;
    c : TMRgb;
    stPr, akPr : double;
begin
  surf.PixelFormat := pf24bit;
  Integer(c) := Integer(lcolor);
  stPr := lstr / 100;
  step := Integer(Surf.ScanLine[1]) - Integer(Surf.ScanLine[0]);
  Integer(pp) := Integer(Surf.ScanLine[0]) + ((sy - r) * step);
  for y := -r to r do begin
   for x := -r to r do begin
    if ((x + sx) >= 0) and ((y + sy) >= 0) and ((x + sx) < surf.Width) and ((y + sy) < surf.Height) then
     begin
       pa := pp;
       od := a[x + r, y + r];
      if od <= r then begin
       akPr := (1 - (od / r)) * stPr;
       pa^[sx + x].rgbtRed := Trunc((akPr * c.r) + (1 - akPr) * pa^[sx + x].rgbtRed);
       pa^[sx + x].rgbtGreen := Trunc((akPr * c.g)+ (1 - akPr) * pa^[sx + x].rgbtGreen);
       pa^[sx + x].rgbtBlue := Trunc((akPr * c.b) + (1 - akPr) * pa^[sx + x].rgbtBlue);
      end;
     end;
    end;
    Integer(pp) := Integer(pp) + step;
  end;
end;

procedure RadialPreCalc(var dp : TDarkenParams; var rp : TRadialParams; sizex, sizey : Integer; darkestAmount : byte);
var amount, value : byte;
    maxodl, odl, cx, cy, x, y : Integer;
begin
  for amount := 0 to 255 do begin
   for value := 0 to 255 do begin
    dp[value, amount] := Trunc((value/255)*(255-amount));
   end;
  end;
  cx := sizex div 2;
  cy := sizey div 2;
  maxodl := Round(Sqrt(Sqr(cx) + Sqr(cy)));
  SetLength(rp, sizex, sizey);
  for x := 0 to (sizex-1) do begin
   for y := 0 to (sizey-1) do begin
    odl := Round(Sqrt(Sqr(cx - x) + Sqr(cy - y)));
    rp[x, y] := Round((DarkestAmount/maxodl) * odl);
   end;
  end;
end;

procedure DarkenRadial(bm : PBitmap; const dp : TDarkenParams; const rp : TRadialParams);
var x, y, maxx, maxy : integer;
    i : pRGBArray;
    step : Integer;
begin
 if bm^.PixelFormat <> pf24bit then bm^.PixelFormat := pf24bit;
  step := Integer(bm^.ScanLine[1]) - Integer(bm^.ScanLine[0]);
  maxx := bm^.Width; maxy := bm^.Height;
  i := bm^.ScanLine[0];
  for y := 0 to (maxy - 1) do begin
   for x := 0 to (maxx - 1) do begin
    i^[x].rgbtBlue := dp[i^[x].rgbtBlue, rp[x,y]];
    i^[x].rgbtGreen := dp[i^[x].rgbtGreen, rp[x,y]];
    i^[x].rgbtRed := dp[i^[x].rgbtRed, rp[x,y]];
   end;
   if y < (maxy - 1) then Integer(i) := Integer(i) + step;
  end;
end;

procedure Darken(bm : PBitmap; const Soft, TopDown: Boolean;
  const Colour: Integer = 0);
//Colour 0 is default grey. 1 red 2 green 3 blue 4 yellow 5 pink 6 turquoise.
//7 is used a simple way of drawing no shades.
var x, y, y2, maxx, maxy , High: integer;
    i : pRGBArray;
    step : Integer;
    step2: single;
    c: TMyRgb;
begin
  if bm^.PixelFormat <> pf24bit Then bm^.PixelFormat := pf24bit;
  step := Integer(bm^.ScanLine[1]) - Integer(bm^.ScanLine[0]);
  maxx := bm^.Width; maxy := bm^.Height;
  i := bm^.ScanLine[0];
  if TopDown then
  begin
    High := maxy - Count;
    step2 := Count / maxx;
  end
  else
    begin
      High := maxx - Count - 20;
      step2 := Count / maxy;
    end;
  Y2 := Count;//Just to remove the warning.
  for y := 1 to maxy do begin
    if TopDown then
      if y > High then
        y2 := y - High
      else
        y2 := 0;
    for x := 1 to maxx do begin
      if Soft then
      begin
        if not TopDown then
        begin
          if x > High then
          begin
            y2 := x - High;
            if y2 > Count then y2 := Count;
          end
          else
            y2 := 0;
//If y grad is lighter than y2 then use y.
          if trunc(y*step2) > y2 then
            y2 := trunc(y*step2);
        end
        else
          if trunc(x*step2) > y2 then
            y2 := trunc(x*step2);
      end
      else
        y2 := 20;//Hard shadow.

      if Colour = 0 then
      begin
        i^[x - 1].rgbtBlue := cC[i^[x - 1].rgbtBlue, y2];
        i^[x - 1].rgbtGreen := cC[i^[x - 1].rgbtGreen, y2];
        i^[x - 1].rgbtRed := cC[i^[x - 1].rgbtRed, y2];
      end
      else
        begin
          c.r:=1;
          c.g:=1;
          c.b:=1;
          case Colour of
            1: c.r:=0;
            2: c.g:=0;
            3: c.b:=0;
            4: begin c.r:=0;c.g:=0;end;
            5: begin c.r:=0;c.b:=0;end;
            6: begin c.g:=0;c.b:=0;end;
            7: begin c.r:=0;c.g:=0;c.b:=0;end;
          end;
          if c.b=1 then
            i^[x - 1].rgbtBlue := cC[i^[x - 1].rgbtBlue, 60];
          if c.g=1 then
            i^[x - 1].rgbtGreen := cC[i^[x - 1].rgbtGreen, 60];
          if c.r=1 then
            i^[x - 1].rgbtRed := cC[i^[x - 1].rgbtRed, 60];
        end;

    end;
    if y < maxy Then Integer(i) := Integer(i) + step;
  end;
end;

procedure Initc(amount: integer);
var
  amount2, x, y: Integer;
begin
  for y := 0 to Count do
  begin
    amount2 := 255 - (amount - y);
    for x := 0 to 255 do
      cC[x,y] := Round((x/255) * amount2);
  end;
end;


initialization
  Initc(Count);

finalization


end.
