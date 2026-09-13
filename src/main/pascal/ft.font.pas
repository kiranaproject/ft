unit Ft.Font;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Process,
  agg_gamma_functions,
  agg_font_freetype,
  agg_font_cache_manager;

type
  { Forward declarations }
  TFtFont = class;
  TFtFontManager = class;

  { TFtFont: Encapsulates a loaded FreeType font with metrics and cache }
  TFtFont = class
  private
    FFamilyName: string;
    FSize: Double;       { Font size in points (pt) }
    FDPI: Double;        { Monitor DPI }
    FGamma: Double;      { Stem gamma factor for FreeType rasterizer }
    FBold: Boolean;
    FItalic: Boolean;
    FFontPath: string;
    FFaceIndex: Cardinal;
    FFontDesc: string;
    FGamPower: gamma_power;
    FEngine: font_engine_freetype_int32;
    FCacheManager: font_cache_manager;
    FLoaded: Boolean;
    FAscent: Double;     { In device pixels }
    FDescent: Double;    { In device pixels }
    FHeight: Double;     { In device pixels }
    FFallbackFont: TFtFont;
    procedure LoadFont();
    procedure SetGamma(AValue: Double);
    function GetFallbackFont(): TFtFont;
  public
    constructor Create(const AFamily: string; ASize: Double; ABold, AItalic: Boolean; const APath: string; AFaceIndex: Cardinal = 0; ADPI: Double = 96.0; AGamma: Double = 0.75);
    destructor Destroy(); override;

    function GetTextWidth(const AText: string): Double;
    function CacheManagerPtr(): font_cache_manager_ptr;

    property FamilyName: string read FFamilyName;
    property Size: Double read FSize;
    property DPI: Double read FDPI;
    property Gamma: Double read FGamma write SetGamma;
    property Bold: Boolean read FBold;
    property Italic: Boolean read FItalic;
    property FontPath: string read FFontPath;
    property FaceIndex: Cardinal read FFaceIndex;
    property FontDesc: string read FFontDesc;
    property Loaded: Boolean read FLoaded;
    property Ascent: Double read FAscent;
    property Descent: Double read FDescent;
    property Height: Double read FHeight;
    property FallbackFont: TFtFont read GetFallbackFont write FFallbackFont;
  end;

  { TFtFontManager: Centralized font management, DPI scaling, and persistent cache }
  TFtFontManager = class
  private
    FCache: TFPList;
    FDefaultFontDesc: string;
    FSystemFont: TFtFont;
    FScreenDPI: Double;
    FFontGamma: Double;
    FFallbackFontFamily: string;
    function DetectScreenDPI(): Double;
    function DetectSystemFontDesc(): string;
    function DetectFallbackFontFamily(): string;
    function ResolveFontFile(const AFamily: string; ABold, AItalic: Boolean; out AFaceIndex: Cardinal): string;
    function BuildCanonicalDesc(const AFamily: string; ASize: Double; ABold, AItalic: Boolean; AFaceIndex: Cardinal): string;
    procedure ParseFontDesc(ADesc: string; out AFamily: string; out ASize: Double; out ABold, AItalic: Boolean);
    procedure SetScreenDPI(AValue: Double);
    procedure SetFontGamma(AValue: Double);
  public
    constructor Create();
    destructor Destroy(); override;

    function GetFont(const AFontDesc: string): TFtFont;
    function GetSystemFont(): TFtFont;
    function GetFallbackFont(ASize: Double): TFtFont;
    procedure SetSystemFontDesc(const AFontDesc: string);

    property SystemFont: TFtFont read GetSystemFont;
    property DefaultFontDesc: string read FDefaultFontDesc write SetSystemFontDesc;
    property ScreenDPI: Double read FScreenDPI write SetScreenDPI;
    property FontGamma: Double read FFontGamma write SetFontGamma;
    property FallbackFontFamily: string read FFallbackFontFamily write FFallbackFontFamily;
  end;

function UTF8CharToUnicode(p: PChar; out CharLen: LongInt): Cardinal;
function FtFontManager(): TFtFontManager;
function FtGetSystemFont(): TFtFont;
function FtGetScreenDPI(): Double;
procedure FtSetScreenDPI(ADPI: Double);
function FtGetFontGamma(): Double;
procedure FtSetFontGamma(AGamma: Double);

implementation

var
  uFontManager: TFtFontManager = nil;

function UTF8CharToUnicode(p: PChar; out CharLen: LongInt): Cardinal;
begin
  if p = nil then
  begin
    CharLen := 0;
    Exit(0);
  end;
  if Ord(p^) < %11000000 then
  begin
    Result := Ord(p^);
    CharLen := 1;
    Exit;
  end
  else if ((Ord(p^) and %11100000) = %11000000) then
  begin
    if (Ord(p[1]) and %11000000) = %10000000 then
    begin
      Result := ((Ord(p^) and %00011111) shl 6) or (Ord(p[1]) and %00111111);
      CharLen := 2;
      Exit;
    end;
  end
  else if ((Ord(p^) and %11110000) = %11100000) then
  begin
    if ((Ord(p[1]) and %11000000) = %10000000) and
       ((Ord(p[2]) and %11000000) = %10000000) then
    begin
      Result := ((Ord(p^) and %00001111) shl 12) or
                ((Ord(p[1]) and %00111111) shl 6) or
                (Ord(p[2]) and %00111111);
      CharLen := 3;
      Exit;
    end;
  end
  else if ((Ord(p^) and %11111000) = %11110000) then
  begin
    if ((Ord(p[1]) and %11000000) = %10000000) and
       ((Ord(p[2]) and %11000000) = %10000000) and
       ((Ord(p[3]) and %11000000) = %10000000) then
    begin
      Result := ((Ord(p^) and %00000111) shl 18) or
                ((Ord(p[1]) and %00111111) shl 12) or
                ((Ord(p[2]) and %00111111) shl 6) or
                (Ord(p[3]) and %00111111);
      CharLen := 4;
      Exit;
    end;
  end;
  Result := Ord(p^);
  CharLen := 1;
end;

function FindLastChar(const S: string; Ch: Char): Integer;
var
  i: Integer;
begin
  for i := Length(S) downto 1 do
    if S[i] = Ch then Exit(i);
  Result := 0;
end;

{ TFtFont }

constructor TFtFont.Create(const AFamily: string; ASize: Double; ABold, AItalic: Boolean; const APath: string; AFaceIndex: Cardinal = 0; ADPI: Double = 96.0; AGamma: Double = 0.75);
var
  px: Double;
begin
  inherited Create;
  FFamilyName := AFamily;
  FSize := ASize;
  FDPI := ADPI;
  FGamma := AGamma;
  FBold := ABold;
  FItalic := AItalic;
  FFontPath := APath;
  FFaceIndex := AFaceIndex;
  FFallbackFont := nil;
  FLoaded := False;

  px := FSize * (FDPI / 72.0);
  FAscent := px * 0.8;
  FDescent := px * 0.2;
  FHeight := px;

  FEngine.Construct();
  FCacheManager.Construct(@FEngine);

  if FFontPath <> '' then
    LoadFont();
end;

destructor TFtFont.Destroy();
begin
  FCacheManager.Destruct();
  FEngine.Destruct();
  inherited Destroy();
end;

procedure TFtFont.LoadFont();
var
  pixelHeight: Double;
begin
  if not FileExists(FFontPath) then Exit;

  FLoaded := FEngine.load_font(PChar(FFontPath), FFaceIndex, glyph_ren_agg_gray8);
  if FLoaded then
  begin
    { Convert point size (pt) to device pixel height based on screen DPI }
    pixelHeight := FSize * (FDPI / 72.0);
    FEngine.height_(pixelHeight);
    FEngine.flip_y_(True);
    FEngine.hinting_(True);

    { Stem darkening / gamma correction for solid font strokes matching desktop standards }
    if FGamma > 0.0 then
    begin
      FGamPower.Construct(FGamma);
      FEngine.gamma_(@FGamPower);
    end;

    FAscent := FEngine._ascender();
    FDescent := abs(FEngine._descender());
    FHeight := FEngine._height();
  end;
end;

procedure TFtFont.SetGamma(AValue: Double);
begin
  if (AValue <= 0.0) or (Abs(FGamma - AValue) < 0.001) then Exit;
  FGamma := AValue;
  if FLoaded then
  begin
    FGamPower.Construct(FGamma);
    FEngine.gamma_(@FGamPower);
    { Reset cache so existing glyphs are re-rasterized with the new gamma }
    FCacheManager.Destruct();
    FCacheManager.Construct(@FEngine);
  end;
end;

function TFtFont.GetFallbackFont(): TFtFont;
begin
  if Assigned(FFallbackFont) then
    Exit(FFallbackFont);

  // If this font itself is a CJK font or contains CJK glyphs, skip fallback recursion
  if (Pos('cjk', LowerCase(FFamilyName)) > 0) or
     (Pos('droid sans fallback', LowerCase(FFamilyName)) > 0) then
    Exit(nil);

  FFallbackFont := FtFontManager().GetFallbackFont(FSize);
  Result := FFallbackFont;
end;

function TFtFont.GetTextWidth(const AText: string): Double;
var
  str_: PChar;
  charLen: LongInt;
  charId: Cardinal;
  glyph: glyph_cache_ptr;
  first: Boolean;
  x, y: Double;
  fb: TFtFont;
  curCM: font_cache_manager_ptr;
begin
  if not FLoaded or (AText = '') then
    Exit(Length(AText) * (FSize * (FDPI / 72.0)) * 0.55);

  x := 0.0;
  y := 0.0;
  first := True;
  str_ := PChar(AText);

  while str_^ <> #0 do
  begin
    charId := UTF8CharToUnicode(str_, charLen);
    Inc(str_, charLen);

    glyph := FCacheManager.glyph(charId);
    curCM := @FCacheManager;
    if (glyph = nil) or (glyph^.glyph_index = 0) then
    begin
      fb := FallbackFont;
      if Assigned(fb) and fb.Loaded and (fb <> Self) then
      begin
        glyph := fb.CacheManagerPtr()^.glyph(charId);
        if (glyph <> nil) and (glyph^.glyph_index <> 0) then
          curCM := fb.CacheManagerPtr();
      end;
    end;

    if glyph <> nil then
    begin
      if not first then
        curCM^.add_kerning(@x, @y);
      first := False;
      x := x + glyph^.advance_x;
    end;
  end;

  Result := x;
end;

function TFtFont.CacheManagerPtr(): font_cache_manager_ptr;
begin
  Result := @FCacheManager;
end;

{ TFtFontManager }

constructor TFtFontManager.Create();
var
  envVal: string;
  valDbl: Double;
  code: Integer;
begin
  inherited Create();
  FCache := TFPList.Create();
  FScreenDPI := DetectScreenDPI();
  FDefaultFontDesc := DetectSystemFontDesc();
  FSystemFont := nil;
  FFontGamma := 0.75;

  envVal := GetEnvironmentVariable('FT_FONT_GAMMA');
  if envVal <> '' then
  begin
    Val(envVal, valDbl, code);
    if (code = 0) and (valDbl > 0.05) and (valDbl < 5.0) then
      FFontGamma := valDbl;
  end;
end;

destructor TFtFontManager.Destroy();
var
  i: Integer;
begin
  for i := 0 to FCache.Count - 1 do
    TFtFont(FCache[i]).Free();
  FCache.Free();
  inherited Destroy();
end;

function TFtFontManager.DetectScreenDPI(): Double;
var
  envVal: string;
  valDbl: Double;
  outStr: string;
  lines: TStringList;
  i, p: Integer;
  line, dpiStr: string;
  code: Integer;
begin
  Result := 96.0;

  // 1. Explicit environment overrides: FT_DPI or FT_SCALE_FACTOR
  envVal := GetEnvironmentVariable('FT_DPI');
  if envVal <> '' then
  begin
    Val(envVal, valDbl, code);
    if (code = 0) and (valDbl > 0) then Exit(valDbl);
  end;

  envVal := GetEnvironmentVariable('FT_SCALE_FACTOR');
  if envVal <> '' then
  begin
    Val(envVal, valDbl, code);
    if (code = 0) and (valDbl > 0) then Exit(96.0 * valDbl);
  end;

  envVal := GetEnvironmentVariable('GDK_SCALE');
  if envVal <> '' then
  begin
    Val(envVal, valDbl, code);
    if (code = 0) and (valDbl > 0) then Exit(96.0 * valDbl);
  end;

  envVal := GetEnvironmentVariable('QT_SCALE_FACTOR');
  if envVal <> '' then
  begin
    Val(envVal, valDbl, code);
    if (code = 0) and (valDbl > 0) then Exit(96.0 * valDbl);
  end;

  // 2. Query Xft.dpi from xrdb
  if RunCommand('xrdb', ['-query'], outStr) and (outStr <> '') then
  begin
    lines := TStringList.Create;
    try
      lines.Text := outStr;
      for i := 0 to lines.Count - 1 do
      begin
        line := lines[i];
        p := Pos('Xft.dpi:', line);
        if p > 0 then
        begin
          dpiStr := Trim(Copy(line, p + Length('Xft.dpi:'), Length(line)));
          Val(dpiStr, valDbl, code);
          if (code = 0) and (valDbl > 0) then
          begin
            Result := valDbl;
            Exit;
          end;
        end;
      end;
    finally
      lines.Free;
    end;
  end;
end;

procedure TFtFontManager.SetScreenDPI(AValue: Double);
var
  i: Integer;
begin
  if AValue <= 0 then Exit;
  if Abs(FScreenDPI - AValue) < 0.1 then Exit;
  FScreenDPI := AValue;
  for i := 0 to FCache.Count - 1 do
    TFtFont(FCache[i]).Free;
  FCache.Clear;
  FSystemFont := nil;
end;

function TFtFontManager.DetectSystemFontDesc: string;
var
  outStr: string;
  p: string;
begin
  Result := '';

  // 1. Try desktop settings (MATE / GNOME / Cinnamon)
  if RunCommand('gsettings', ['get', 'org.mate.interface', 'font-name'], outStr) and (Trim(outStr) <> '') then
    Result := Trim(outStr)
  else if RunCommand('gsettings', ['get', 'org.gnome.desktop.interface', 'font-name'], outStr) and (Trim(outStr) <> '') then
    Result := Trim(outStr);

  // Strip single/double quotes if present
  if (Length(Result) >= 2) and (Result[1] in ['''', '"']) and (Result[Length(Result)] = Result[1]) then
    Result := Copy(Result, 2, Length(Result) - 2);

  if Result <> '' then Exit;

  // 2. Try fontconfig default sans-serif
  if RunCommand('fc-match', ['-f', '%{family}-%{size}', 'sans-serif'], outStr) and (Trim(outStr) <> '') then
  begin
    p := Trim(outStr);
    if p <> '' then
    begin
      Result := p;
      Exit;
    end;
  end;

  // 3. Fallback default
  Result := 'Ubuntu-11';
end;

function TFtFontManager.BuildCanonicalDesc(const AFamily: string; ASize: Double; ABold, AItalic: Boolean; AFaceIndex: Cardinal): string;
begin
  Result := Format('%s-%.1f', [AFamily, ASize]);
  if AFaceIndex > 0 then Result := Result + Format(':face%d', [AFaceIndex]);
  if ABold then Result := Result + ':bold';
  if AItalic then Result := Result + ':italic';
end;

procedure TFtFontManager.ParseFontDesc(ADesc: string; out AFamily: string; out ASize: Double; out ABold, AItalic: Boolean);
var
  Parts: TStringList;
  Base: string;
  i, LastDash, LastSpace: Integer;
  Attr: string;
  SizeStr: string;
begin
  ADesc := Trim(ADesc);
  if (Length(ADesc) >= 2) and (ADesc[1] in ['''', '"']) and (ADesc[Length(ADesc)] = ADesc[1]) then
    ADesc := Copy(ADesc, 2, Length(ADesc) - 2);

  AFamily := 'Ubuntu';
  ASize := 11.0;
  ABold := False;
  AItalic := False;

  if ADesc = '' then Exit;

  Parts := TStringList.Create;
  try
    Parts.Delimiter := ':';
    Parts.StrictDelimiter := True;
    Parts.DelimitedText := ADesc;

    if Parts.Count > 0 then
    begin
      Base := Trim(Parts[0]);
      for i := 1 to Parts.Count - 1 do
      begin
        Attr := LowerCase(Trim(Parts[i]));
        if Pos('bold', Attr) > 0 then ABold := True;
        if Pos('italic', Attr) > 0 then AItalic := True;
      end;

      LastDash := FindLastChar(Base, '-');
      if LastDash > 0 then
      begin
        SizeStr := Copy(Base, LastDash + 1, Length(Base));
        if TryStrToFloat(SizeStr, ASize) then
          AFamily := Trim(Copy(Base, 1, LastDash - 1))
        else
          AFamily := Base;
      end
      else
      begin
        LastSpace := FindLastChar(Base, ' ');
        if LastSpace > 0 then
        begin
          SizeStr := Copy(Base, LastSpace + 1, Length(Base));
          if TryStrToFloat(SizeStr, ASize) then
            AFamily := Trim(Copy(Base, 1, LastSpace - 1))
          else
            AFamily := Base;
        end
        else
          AFamily := Base;
      end;
    end;
  finally
    Parts.Free;
  end;
end;

function TFtFontManager.ResolveFontFile(const AFamily: string; ABold, AItalic: Boolean; out AFaceIndex: Cardinal): string;
var
  Pattern: string;
  outPath, filePath, idxStr: string;
  colonPos: Integer;
  valIdx: LongInt;
const
  StandardDirs: array[0..4] of string = (
    '/usr/share/fonts/truetype/ubuntu/Ubuntu[wdth,wght].ttf',
    '/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc',
    '/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf',
    '/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
  );
var
  i: Integer;
begin
  Result := '';
  AFaceIndex := 0;
  Pattern := AFamily;
  if ABold then Pattern := Pattern + ':bold';
  if AItalic then Pattern := Pattern + ':italic';

  // Query fontconfig
  if RunCommand('fc-match', ['-f', '%{file}:%{index}', Pattern], outPath) then
  begin
    outPath := Trim(outPath);
    colonPos := FindLastChar(outPath, ':');
    if colonPos > 0 then
    begin
      idxStr := Copy(outPath, colonPos + 1, Length(outPath));
      filePath := Copy(outPath, 1, colonPos - 1);
      if TryStrToInt(idxStr, valIdx) and (valIdx >= 0) then
        AFaceIndex := Cardinal(valIdx)
      else
        AFaceIndex := 0;
      outPath := filePath;
    end;

    if (outPath <> '') and FileExists(outPath) then
      Exit(outPath);
  end;

  // Fallback to standard directories
  for i := Low(StandardDirs) to High(StandardDirs) do
    if FileExists(StandardDirs[i]) then
      Exit(StandardDirs[i]);
end;

function TFtFontManager.DetectFallbackFontFamily(): string;
var
  outStr: string;
begin
  Result := '';
  if RunCommand('fc-match', ['-f', '%{family}', 'Noto Sans CJK SC'], outStr) and (Trim(outStr) <> '') then
    Exit(Trim(outStr));
  if RunCommand('fc-match', ['-f', '%{family}', 'Droid Sans Fallback'], outStr) and (Trim(outStr) <> '') then
    Exit(Trim(outStr));
  if RunCommand('fc-match', ['-f', '%{family}', ':charset=4f60'], outStr) and (Trim(outStr) <> '') then
    Exit(Trim(outStr));
  Result := 'Noto Sans CJK SC';
end;

function TFtFontManager.GetFallbackFont(ASize: Double): TFtFont;
var
  Desc: string;
begin
  if FFallbackFontFamily = '' then
    FFallbackFontFamily := DetectFallbackFontFamily();
  Desc := Format('%s-%.1f', [FFallbackFontFamily, ASize]);
  Result := GetFont(Desc);
end;

function TFtFontManager.GetFont(const AFontDesc: string): TFtFont;
var
  Fam: string;
  Sz: Double;
  B, It: Boolean;
  CanonKey: string;
  i: Integer;
  FontPath: string;
  FaceIdx: Cardinal;
  NewFont: TFtFont;
begin
  if AFontDesc = '' then
    Exit(GetSystemFont());

  ParseFontDesc(AFontDesc, Fam, Sz, B, It);
  FontPath := ResolveFontFile(Fam, B, It, FaceIdx);
  CanonKey := BuildCanonicalDesc(Fam, Sz, B, It, FaceIdx);

  // Search cache
  for i := 0 to FCache.Count - 1 do
  begin
    NewFont := TFtFont(FCache[i]);
    if SameText(NewFont.FontDesc, CanonKey) and (Abs(NewFont.DPI - FScreenDPI) < 0.1) then
      Exit(NewFont);
  end;

  // Resolve font path and create
  NewFont := TFtFont.Create(Fam, Sz, B, It, FontPath, FaceIdx, FScreenDPI, FFontGamma);
  NewFont.FFontDesc := CanonKey;
  FCache.Add(NewFont);

  Result := NewFont;
end;

procedure TFtFontManager.SetFontGamma(AValue: Double);
var
  i: Integer;
begin
  if (AValue <= 0.0) or (Abs(FFontGamma - AValue) < 0.001) then Exit;
  FFontGamma := AValue;
  for i := 0 to FCache.Count - 1 do
    TFtFont(FCache[i]).Gamma := AValue;
end;

function TFtFontManager.GetSystemFont(): TFtFont;
begin
  if not Assigned(FSystemFont) then
    FSystemFont := GetFont(FDefaultFontDesc);
  Result := FSystemFont;
end;

procedure TFtFontManager.SetSystemFontDesc(const AFontDesc: string);
begin
  FDefaultFontDesc := AFontDesc;
  FSystemFont := nil; // Invalidate system font pointer to reload on next access
end;

function FtFontManager(): TFtFontManager;
begin
  if not Assigned(uFontManager) then
    uFontManager := TFtFontManager.Create();
  Result := uFontManager;
end;

function FtGetSystemFont(): TFtFont;
begin
  Result := FtFontManager().GetSystemFont();
end;

function FtGetScreenDPI(): Double;
begin
  Result := FtFontManager().ScreenDPI;
end;

procedure FtSetScreenDPI(ADPI: Double);
begin
  FtFontManager().ScreenDPI := ADPI;
end;

function FtGetFontGamma(): Double;
begin
  Result := FtFontManager().FontGamma;
end;

procedure FtSetFontGamma(AGamma: Double);
begin
  FtFontManager().FontGamma := AGamma;
end;

finalization
  if Assigned(uFontManager) then
  begin
    uFontManager.Free();
    uFontManager := nil;
  end;

end.
