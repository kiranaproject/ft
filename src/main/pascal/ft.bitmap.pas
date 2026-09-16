unit Ft.Bitmap;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes,
  FPImage, fpreadpng, fpreadjpeg, fpreadbmp, fpwritepng,
  agg_basics,
  agg_rendering_buffer,
  agg_pixfmt,
  agg_pixfmt_rgba;

type
  TFtBitmap = class
  private
    FWidth: Integer;
    FHeight: Integer;
    FStride: Integer;
    FPixelBuffer: Pointer;
    FRenderingBuf: rendering_buffer;
    FPixFormat: pixel_formats;
    procedure AllocateBuffer(AWidth, AHeight: Integer);
    procedure CopyFromFPImage(AImg: TFPMemoryImage);
    procedure DetectAndLoadFromStream(AStream: TStream);
    function LoadFromSVGStream(AStream: TStream): Boolean;
    procedure LoadFromSVGFile(const AFileName: string; AWidth: Integer = 0; AHeight: Integer = 0);
    procedure LoadFromSVGString(const ASVGContent: string; AWidth: Integer = 0; AHeight: Integer = 0);
  public
    constructor Create(AWidth, AHeight: Integer);
    constructor CreateFromFile(const AFileName: string);
    constructor CreateFromStream(AStream: TStream);
    constructor CreateFromMemory(AData: Pointer; ASize: Integer);
    constructor CreateFromRGBA(AData: Pointer; AWidth, AHeight: Integer);
    constructor CreateFromBGRA(AData: Pointer; AWidth, AHeight: Integer);
    constructor CreateFromSVG(const ASVGContent: string; AWidth: Integer = 0; AHeight: Integer = 0);
    constructor CreateFromSVGFile(const AFileName: string; AWidth: Integer = 0; AHeight: Integer = 0);
    destructor Destroy(); override;

    procedure Clear(R, G, B, A: Byte);
    function PixFormatPtr(): pixel_formats_ptr;
    function RenderingBufPtr(): rendering_buffer_ptr;
    function Clone(): TFtBitmap;
    function CreateScaled(NewW, NewH: Integer): TFtBitmap;
    procedure SaveToFile(const AFileName: string);

    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property Stride: Integer read FStride;
    property PixelBuffer: Pointer read FPixelBuffer;
    property Data: Pointer read FPixelBuffer;
  end;

implementation

uses
  Ft.Svg;

constructor TFtBitmap.Create(AWidth, AHeight: Integer);
begin
  inherited Create();
  AllocateBuffer(AWidth, AHeight);
  Clear(0, 0, 0, 0);
end;

procedure TFtBitmap.AllocateBuffer(AWidth, AHeight: Integer);
begin
  FWidth := AWidth;
  FHeight := AHeight;
  if FWidth < 0 then FWidth := 0;
  if FHeight < 0 then FHeight := 0;
  FStride := FWidth * 4;

  if (FWidth > 0) and (FHeight > 0) then
  begin
    GetMem(FPixelBuffer, FHeight * FStride);
    FRenderingBuf.Construct();
    FRenderingBuf.attach(int8u_ptr(FPixelBuffer), FWidth, FHeight, FStride);
    pixfmt_bgra32(FPixFormat, @FRenderingBuf);
  end
  else
  begin
    FPixelBuffer := nil;
    FRenderingBuf.Construct();
  end;
end;

destructor TFtBitmap.Destroy();
begin
  if Assigned(FPixelBuffer) then
  begin
    FreeMem(FPixelBuffer);
    FPixelBuffer := nil;
  end;
  inherited Destroy();
end;

procedure TFtBitmap.Clear(R, G, B, A: Byte);
var
  p: PDWord;
  val: DWord;
  count, i: Integer;
begin
  if (FPixelBuffer = nil) or (FWidth <= 0) or (FHeight <= 0) then Exit;
  // BGRA in little-endian DWord: Byte 0=B, Byte 1=G, Byte 2=R, Byte 3=A
  val := (DWord(A) shl 24) or (DWord(R) shl 16) or (DWord(G) shl 8) or DWord(B);
  p := PDWord(FPixelBuffer);
  count := FWidth * FHeight;
  for i := 0 to count - 1 do
  begin
    p^ := val;
    Inc(p);
  end;
end;

procedure TFtBitmap.CopyFromFPImage(AImg: TFPMemoryImage);
var
  x, y: Integer;
  col: TFPColor;
  p: PDWord;
  a, r, g, b: Byte;
begin
  if not Assigned(AImg) or (AImg.Width <= 0) or (AImg.Height <= 0) then Exit;
  AllocateBuffer(AImg.Width, AImg.Height);
  p := PDWord(FPixelBuffer);
  for y := 0 to FHeight - 1 do
  begin
    for x := 0 to FWidth - 1 do
    begin
      col := AImg.Colors[x, y];
      a := col.Alpha shr 8;
      r := col.Red shr 8;
      g := col.Green shr 8;
      b := col.Blue shr 8;
      p^ := (DWord(a) shl 24) or (DWord(r) shl 16) or (DWord(g) shl 8) or DWord(b);
      Inc(p);
    end;
  end;
end;

function TFtBitmap.LoadFromSVGStream(AStream: TStream): Boolean;
var
  ss: TStringStream;
  tempBmp: TFtBitmap;
  s: string;
begin
  Result := False;
  ss := TStringStream.Create('');
  try
    ss.CopyFrom(AStream, AStream.Size - AStream.Position);
    s := ss.DataString;
    if (Pos('<svg', LowerCase(s)) > 0) then
    begin
      tempBmp := TFtSVGRenderer.RenderStringToBitmap(s);
      try
        AllocateBuffer(tempBmp.Width, tempBmp.Height);
        if (FPixelBuffer <> nil) and (tempBmp.FPixelBuffer <> nil) then
          Move(tempBmp.FPixelBuffer^, FPixelBuffer^, FHeight * FStride);
        Result := True;
      finally
        tempBmp.Free();
      end;
    end;
  finally
    ss.Free();
  end;
end;

procedure TFtBitmap.LoadFromSVGFile(const AFileName: string; AWidth: Integer = 0; AHeight: Integer = 0);
var
  tempBmp: TFtBitmap;
begin
  tempBmp := TFtSVGRenderer.RenderFileToBitmap(AFileName, AWidth, AHeight);
  try
    AllocateBuffer(tempBmp.Width, tempBmp.Height);
    if (FPixelBuffer <> nil) and (tempBmp.FPixelBuffer <> nil) then
      Move(tempBmp.FPixelBuffer^, FPixelBuffer^, FHeight * FStride);
  finally
    tempBmp.Free();
  end;
end;

procedure TFtBitmap.LoadFromSVGString(const ASVGContent: string; AWidth: Integer = 0; AHeight: Integer = 0);
var
  tempBmp: TFtBitmap;
begin
  tempBmp := TFtSVGRenderer.RenderStringToBitmap(ASVGContent, AWidth, AHeight);
  try
    AllocateBuffer(tempBmp.Width, tempBmp.Height);
    if (FPixelBuffer <> nil) and (tempBmp.FPixelBuffer <> nil) then
      Move(tempBmp.FPixelBuffer^, FPixelBuffer^, FHeight * FStride);
  finally
    tempBmp.Free();
  end;
end;

procedure TFtBitmap.DetectAndLoadFromStream(AStream: TStream);
var
  memImg: TFPMemoryImage;
  reader: TFPCustomImageReader;
  header: array[0..3] of Byte;
  oldPos: Int64;
  readBytes: Integer;
begin
  if not Assigned(AStream) or (AStream.Size <= 0) then
  begin
    AllocateBuffer(0, 0);
    Exit;
  end;

  oldPos := AStream.Position;
  FillChar(header, SizeOf(header), 0);
  readBytes := AStream.Read(header, 4);
  AStream.Position := oldPos;

  // Check for SVG
  if (readBytes >= 4) and (header[0] = ord('<')) then
  begin
    if LoadFromSVGStream(AStream) then Exit;
    AStream.Position := oldPos;
  end;

  reader := nil;
  if readBytes >= 4 then
  begin
    if (header[0] = $89) and (header[1] = $50) and (header[2] = $4E) and (header[3] = $47) then
      reader := TFPReaderPNG.Create()
    else if (header[0] = $FF) and (header[1] = $D8) and (header[2] = $FF) then
      reader := TFPReaderJPEG.Create()
    else if (header[0] = $42) and (header[1] = $4D) then
      reader := TFPReaderBMP.Create();
  end;

  if not Assigned(reader) then
    reader := TFPReaderPNG.Create(); // fallback attempt

  memImg := TFPMemoryImage.Create(0, 0);
  try
    try
      memImg.LoadFromStream(AStream, reader);
      CopyFromFPImage(memImg);
    except
      AllocateBuffer(0, 0);
    end;
  finally
    reader.Free();
    memImg.Free();
  end;
end;

constructor TFtBitmap.CreateFromFile(const AFileName: string);
var
  fs: TFileStream;
begin
  inherited Create();
  if not FileExists(AFileName) then
  begin
    AllocateBuffer(0, 0);
    Exit;
  end;

  if LowerCase(ExtractFileExt(AFileName)) = '.svg' then
  begin
    LoadFromSVGFile(AFileName);
    Exit;
  end;

  try
    fs := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
    try
      DetectAndLoadFromStream(fs);
    finally
      fs.Free();
    end;
  except
    AllocateBuffer(0, 0);
  end;
end;

constructor TFtBitmap.CreateFromStream(AStream: TStream);
begin
  inherited Create();
  DetectAndLoadFromStream(AStream);
end;

constructor TFtBitmap.CreateFromSVG(const ASVGContent: string; AWidth: Integer = 0; AHeight: Integer = 0);
begin
  inherited Create();
  LoadFromSVGString(ASVGContent, AWidth, AHeight);
end;

constructor TFtBitmap.CreateFromSVGFile(const AFileName: string; AWidth: Integer = 0; AHeight: Integer = 0);
begin
  inherited Create();
  LoadFromSVGFile(AFileName, AWidth, AHeight);
end;

constructor TFtBitmap.CreateFromMemory(AData: Pointer; ASize: Integer);
var
  ms: TMemoryStream;
begin
  inherited Create();
  if (AData = nil) or (ASize <= 0) then
  begin
    AllocateBuffer(0, 0);
    Exit;
  end;

  ms := TMemoryStream.Create();
  try
    ms.WriteBuffer(AData^, ASize);
    ms.Position := 0;
    DetectAndLoadFromStream(ms);
  finally
    ms.Free();
  end;
end;

constructor TFtBitmap.CreateFromRGBA(AData: Pointer; AWidth, AHeight: Integer);
var
  src, dst: PByte;
  i, count: Integer;
begin
  inherited Create();
  AllocateBuffer(AWidth, AHeight);
  if (FPixelBuffer = nil) or (AData = nil) then Exit;

  src := PByte(AData);
  dst := PByte(FPixelBuffer);
  count := AWidth * AHeight;
  for i := 0 to count - 1 do
  begin
    dst[0] := src[2]; // B <- B(2)
    dst[1] := src[1]; // G <- G(1)
    dst[2] := src[0]; // R <- R(0)
    dst[3] := src[3]; // A <- A(3)
    Inc(src, 4);
    Inc(dst, 4);
  end;
end;

constructor TFtBitmap.CreateFromBGRA(AData: Pointer; AWidth, AHeight: Integer);
begin
  inherited Create();
  AllocateBuffer(AWidth, AHeight);
  if (FPixelBuffer = nil) or (AData = nil) then Exit;
  Move(AData^, FPixelBuffer^, FHeight * FStride);
end;

function TFtBitmap.PixFormatPtr(): pixel_formats_ptr;
begin
  Result := @FPixFormat;
end;

function TFtBitmap.RenderingBufPtr(): rendering_buffer_ptr;
begin
  Result := @FRenderingBuf;
end;

function TFtBitmap.Clone(): TFtBitmap;
begin
  Result := TFtBitmap.CreateFromBGRA(FPixelBuffer, FWidth, FHeight);
end;

function TFtBitmap.CreateScaled(NewW, NewH: Integer): TFtBitmap;
var
  stepX_fp, stepY_fp: Int64;
  curSrcY_fp, curSrcX_fp: Int64;
  dx, dy, sx, sy: Integer;
  fx, fy, invFx, invFy: Integer;
  srcStride, dstStride: Integer;
  srcPixels, dstPixels, dstRow: PByte;
  p00, p10, p01, p11: PByte;
  b, g, r, a: Integer;
begin
  if (NewW <= 0) or (NewH <= 0) or (FWidth <= 0) or (FHeight <= 0) or (FPixelBuffer = nil) then
  begin
    Result := TFtBitmap.Create(0, 0);
    Exit;
  end;

  Result := TFtBitmap.Create(NewW, NewH);
  if (Result.PixelBuffer = nil) then Exit;

  stepX_fp := (Int64(FWidth) shl 16) div NewW;
  stepY_fp := (Int64(FHeight) shl 16) div NewH;
  srcStride := FStride;
  dstStride := Result.Stride;
  srcPixels := PByte(FPixelBuffer);
  dstPixels := PByte(Result.PixelBuffer);

  for dy := 0 to NewH - 1 do
  begin
    curSrcY_fp := Int64(dy) * stepY_fp;
    sy := curSrcY_fp shr 16;
    fy := (curSrcY_fp shr 8) and $FF;
    invFy := 255 - fy;

    if sy < 0 then sy := 0;
    if sy >= FHeight - 1 then sy := FHeight - 2;
    if sy < 0 then sy := 0;

    dstRow := dstPixels + dy * dstStride;

    for dx := 0 to NewW - 1 do
    begin
      curSrcX_fp := Int64(dx) * stepX_fp;
      sx := curSrcX_fp shr 16;
      fx := (curSrcX_fp shr 8) and $FF;
      invFx := 255 - fx;

      if sx < 0 then sx := 0;
      if sx >= FWidth - 1 then sx := FWidth - 2;
      if sx < 0 then sx := 0;

      p00 := srcPixels + sy * srcStride + sx * 4;
      p10 := p00 + 4;
      p01 := p00 + srcStride;
      p11 := p01 + 4;

      b := (p00[0] * invFx * invFy + p10[0] * fx * invFy + p01[0] * invFx * fy + p11[0] * fx * fy) shr 16;
      g := (p00[1] * invFx * invFy + p10[1] * fx * invFy + p01[1] * invFx * fy + p11[1] * fx * fy) shr 16;
      r := (p00[2] * invFx * invFy + p10[2] * fx * invFy + p01[2] * invFx * fy + p11[2] * fx * fy) shr 16;
      a := (p00[3] * invFx * invFy + p10[3] * fx * invFy + p01[3] * invFx * fy + p11[3] * fx * fy) shr 16;

      dstRow[0] := b;
      dstRow[1] := g;
      dstRow[2] := r;
      dstRow[3] := a;
      Inc(dstRow, 4);
    end;
  end;
end;

procedure TFtBitmap.SaveToFile(const AFileName: string);
var
  memImg: TFPMemoryImage;
  writer: TFPWriterPNG;
  x, y: Integer;
  p: PDWord;
  val: DWord;
  a, r, g, b: Byte;
  col: TFPColor;
begin
  if (FPixelBuffer = nil) or (FWidth <= 0) or (FHeight <= 0) then Exit;
  memImg := TFPMemoryImage.Create(FWidth, FHeight);
  writer := TFPWriterPNG.Create();
  try
    writer.Indexed := False;
    writer.UseAlpha := True;
    for y := 0 to FHeight - 1 do
    begin
      p := PDWord(PByte(FPixelBuffer) + y * FStride);
      for x := 0 to FWidth - 1 do
      begin
        val := p^;
        b := val and $FF;
        g := (val shr 8) and $FF;
        r := (val shr 16) and $FF;
        a := (val shr 24) and $FF;
        col.Red := (r shl 8) or r;
        col.Green := (g shl 8) or g;
        col.Blue := (b shl 8) or b;
        col.Alpha := (a shl 8) or a;
        memImg.Colors[x, y] := col;
        Inc(p);
      end;
    end;
    memImg.SaveToFile(AFileName, writer);
  finally
    writer.Free();
    memImg.Free();
  end;
end;

end.
