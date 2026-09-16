unit Ft.Blur;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Math;

type
  TBgraPixel = packed record
    B, G, R, A: Byte;
  end;
  PBgraPixel = ^TBgraPixel;

{ Fast multi-pass downsampled box blur with bilinear reconstruction and corner masking }
procedure FtFastBlurRoundedRect(buf: Pointer; bufWidth, bufHeight: Integer;
                                rx, ry, rw, rh: Integer;
                                cornerRadius: Double; blurRadius: Double);

procedure FtFastBlurRect(buf: Pointer; bufWidth, bufHeight: Integer;
                         rx, ry, rw, rh: Integer;
                         blurRadius: Double);

implementation

type
  TInterpCol = record
    x0, x1: Integer;
    wx: Integer; // 0..256
  end;

function Clamp(v, minv, maxv: Integer): Integer; inline;
begin
  if v < minv then Exit(minv);
  if v > maxv then Exit(maxv);
  Result := v;
end;

procedure FtFastBlurRect(buf: Pointer; bufWidth, bufHeight: Integer;
                         rx, ry, rw, rh: Integer;
                         blurRadius: Double);
begin
  FtFastBlurRoundedRect(buf, bufWidth, bufHeight, rx, ry, rw, rh, 0.0, blurRadius);
end;

procedure FtFastBlurRoundedRect(buf: Pointer; bufWidth, bufHeight: Integer;
                                rx, ry, rw, rh: Integer;
                                cornerRadius: Double; blurRadius: Double);
var
  pixels: PBgraPixel;
  scale, dw, dh, rSmall, D: Integer;
  smallBuf, tempBuf: PBgraPixel;
  x, y, dx, dy, sx, sy, p, i: Integer;
  entering, leaving: Integer;
  sumB, sumG, sumR, sumA: Integer;
  srcRow, dstRow: PBgraPixel;
  fx, fy: Double;
  y0, y1: Integer;
  wy: Integer; // 0..256
  c00, c10, c01, c11: TBgraPixel;
  interpB, interpG, interpR, interpA: Byte;
  rad: Double;
  maxDistSq, minDistSq: Double;
  cornerDx, cornerDy, distSq, dist, alphaFrac: Double;
  isOutside, isEdge: Boolean;
  cols: array of TInterpCol;
  r0, r1: PBgraPixel;
  invWy, invWx: Integer;
  w00, w10, w01, w11: Integer;
  origB, origG, origR, origA: Byte;
  curIdx: Integer;
begin
  if (buf = nil) or (bufWidth <= 0) or (bufHeight <= 0) or (rw <= 2) or (rh <= 2) or (blurRadius < 0.5) then Exit;

  pixels := PBgraPixel(buf);

  // Clamp rect to buffer boundaries
  if rx < 0 then
  begin
    rw := rw + rx;
    rx := 0;
  end;
  if ry < 0 then
  begin
    rh := rh + ry;
    ry := 0;
  end;
  if rx + rw > bufWidth then rw := bufWidth - rx;
  if ry + rh > bufHeight then rh := bufHeight - ry;
  if (rw <= 2) or (rh <= 2) then Exit;

  // Choose downscale factor based on blur radius for optimal speed and silky quality
  scale := 2;
  if blurRadius >= 14.0 then scale := 4;

  dw := rw div scale;
  dh := rh div scale;
  if (dw <= 1) or (dh <= 1) then Exit;

  rSmall := Max(1, Round(blurRadius / scale));
  D := rSmall * 2 + 1;

  GetMem(smallBuf, dw * dh * SizeOf(TBgraPixel));
  GetMem(tempBuf, dw * dh * SizeOf(TBgraPixel));
  SetLength(cols, rw);
  try
    // Precompute horizontal interpolation weights
    for x := 0 to rw - 1 do
    begin
      fx := (x / scale) - 0.5;
      if fx < 0.0 then fx := 0.0;
      cols[x].x0 := Min(dw - 1, Floor(fx));
      cols[x].x1 := Min(dw - 1, cols[x].x0 + 1);
      cols[x].wx := Round((fx - cols[x].x0) * 256);
    end;

    // 1. Downsample region into smallBuf
    for dy := 0 to dh - 1 do
    begin
      sy := ry + dy * scale;
      for dx := 0 to dw - 1 do
      begin
        sx := rx + dx * scale;
        smallBuf[dy * dw + dx] := pixels[sy * bufWidth + sx];
      end;
    end;

    // 2. Multi-pass separable box blur on small grid
    for p := 1 to 2 do
    begin
      // Horizontal pass: smallBuf -> tempBuf
      for y := 0 to dh - 1 do
      begin
        srcRow := @smallBuf[y * dw];
        dstRow := @tempBuf[y * dw];
        sumB := 0; sumG := 0; sumR := 0; sumA := 0;
        for i := -rSmall to rSmall do
        begin
          sx := Clamp(i, 0, dw - 1);
          Inc(sumB, srcRow[sx].B); Inc(sumG, srcRow[sx].G); Inc(sumR, srcRow[sx].R); Inc(sumA, srcRow[sx].A);
        end;
        for x := 0 to dw - 1 do
        begin
          dstRow[x].B := sumB div D; dstRow[x].G := sumG div D; dstRow[x].R := sumR div D; dstRow[x].A := sumA div D;
          entering := Clamp(x + rSmall + 1, 0, dw - 1);
          leaving := Clamp(x - rSmall, 0, dw - 1);
          Inc(sumB, srcRow[entering].B - srcRow[leaving].B);
          Inc(sumG, srcRow[entering].G - srcRow[leaving].G);
          Inc(sumR, srcRow[entering].R - srcRow[leaving].R);
          Inc(sumA, srcRow[entering].A - srcRow[leaving].A);
        end;
      end;

      // Vertical pass: tempBuf -> smallBuf
      for x := 0 to dw - 1 do
      begin
        sumB := 0; sumG := 0; sumR := 0; sumA := 0;
        for i := -rSmall to rSmall do
        begin
          sy := Clamp(i, 0, dh - 1);
          Inc(sumB, tempBuf[sy * dw + x].B); Inc(sumG, tempBuf[sy * dw + x].G); Inc(sumR, tempBuf[sy * dw + x].R); Inc(sumA, tempBuf[sy * dw + x].A);
        end;
        for y := 0 to dh - 1 do
        begin
          smallBuf[y * dw + x].B := sumB div D; smallBuf[y * dw + x].G := sumG div D; smallBuf[y * dw + x].R := sumR div D; smallBuf[y * dw + x].A := sumA div D;
          entering := Clamp(y + rSmall + 1, 0, dh - 1);
          leaving := Clamp(y - rSmall, 0, dh - 1);
          Inc(sumB, tempBuf[entering * dw + x].B - tempBuf[leaving * dw + x].B);
          Inc(sumG, tempBuf[entering * dw + x].G - tempBuf[leaving * dw + x].G);
          Inc(sumR, tempBuf[entering * dw + x].R - tempBuf[leaving * dw + x].R);
          Inc(sumA, tempBuf[entering * dw + x].A - tempBuf[leaving * dw + x].A);
        end;
      end;
    end;

    // 3. Bilinear upsample with anti-aliased rounded corner blending
    rad := cornerRadius;
    if rad < 0.0 then rad := 0.0;
    maxDistSq := rad * rad;
    minDistSq := Sqr(Max(0.0, rad - 1.0));

    for y := 0 to rh - 1 do
    begin
      fy := (y / scale) - 0.5;
      if fy < 0.0 then fy := 0.0;
      y0 := Min(dh - 1, Floor(fy));
      y1 := Min(dh - 1, y0 + 1);
      wy := Round((fy - y0) * 256);
      invWy := 256 - wy;

      r0 := @smallBuf[y0 * dw];
      r1 := @smallBuf[y1 * dw];

      for x := 0 to rw - 1 do
      begin
        isOutside := False;
        isEdge := False;
        alphaFrac := 1.0;

        if rad > 0.5 then
        begin
          distSq := 0.0;
          if (x < rad) and (y < rad) then
          begin
            cornerDx := rad - x - 0.5; cornerDy := rad - y - 0.5;
            distSq := cornerDx * cornerDx + cornerDy * cornerDy;
          end
          else if (x >= rw - rad) and (y < rad) then
          begin
            cornerDx := x - (rw - rad) + 0.5; cornerDy := rad - y - 0.5;
            distSq := cornerDx * cornerDx + cornerDy * cornerDy;
          end
          else if (x < rad) and (y >= rh - rad) then
          begin
            cornerDx := rad - x - 0.5; cornerDy := y - (rh - rad) + 0.5;
            distSq := cornerDx * cornerDx + cornerDy * cornerDy;
          end
          else if (x >= rw - rad) and (y >= rh - rad) then
          begin
            cornerDx := x - (rw - rad) + 0.5; cornerDy := y - (rh - rad) + 0.5;
            distSq := cornerDx * cornerDx + cornerDy * cornerDy;
          end;

          if distSq > maxDistSq then
            isOutside := True
          else if distSq > minDistSq then
          begin
            isEdge := True;
            dist := Sqrt(distSq);
            alphaFrac := Max(0.0, Min(1.0, rad - dist));
          end;

          if isOutside then Continue;
        end;

        invWx := 256 - cols[x].wx;
        w00 := (invWy * invWx) shr 8;
        w10 := (invWy * cols[x].wx) shr 8;
        w01 := (wy * invWx) shr 8;
        w11 := (wy * cols[x].wx) shr 8;

        c00 := r0[cols[x].x0];
        c10 := r0[cols[x].x1];
        c01 := r1[cols[x].x0];
        c11 := r1[cols[x].x1];

        interpB := (c00.B * w00 + c10.B * w10 + c01.B * w01 + c11.B * w11) shr 8;
        interpG := (c00.G * w00 + c10.G * w10 + c01.G * w01 + c11.G * w11) shr 8;
        interpR := (c00.R * w00 + c10.R * w10 + c01.R * w01 + c11.R * w11) shr 8;
        interpA := (c00.A * w00 + c10.A * w10 + c01.A * w01 + c11.A * w11) shr 8;

        curIdx := (ry + y) * bufWidth + (rx + x);
        if isEdge then
        begin
          origB := pixels[curIdx].B;
          origG := pixels[curIdx].G;
          origR := pixels[curIdx].R;
          origA := pixels[curIdx].A;
          pixels[curIdx].B := Round(interpB * alphaFrac + origB * (1.0 - alphaFrac));
          pixels[curIdx].G := Round(interpG * alphaFrac + origG * (1.0 - alphaFrac));
          pixels[curIdx].R := Round(interpR * alphaFrac + origR * (1.0 - alphaFrac));
          pixels[curIdx].A := Round(interpA * alphaFrac + origA * (1.0 - alphaFrac));
        end
        else
        begin
          pixels[curIdx].B := interpB;
          pixels[curIdx].G := interpG;
          pixels[curIdx].R := interpR;
          pixels[curIdx].A := interpA;
        end;
      end;
    end;
  finally
    FreeMem(smallBuf);
    FreeMem(tempBuf);
  end;
end;

end.
