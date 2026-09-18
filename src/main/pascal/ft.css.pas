unit Ft.Css;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, Classes, Math,
  Floria.CSS.Types, Floria.CSS.AST, Floria.CSS.Parser,
  Floria.CSS.Values, Floria.CSS.Properties, Floria.CSS.Cascade;

type
  { RGBA Color representation (0.0 .. 1.0) }
  TFtRgbaColor = record
    R, G, B, A: Double;
  end;

  { Resolved style properties for a widget }
  TFtWidgetStyle = record
    HasBgColor: Boolean;
    BgColor: TFtRgbaColor;

    HasTextColor: Boolean;
    TextColor: TFtRgbaColor;

    HasBorderColor: Boolean;
    BorderColor: TFtRgbaColor;

    HasBorderWidth: Boolean;
    BorderWidth: Double;

    HasBorderRadius: Boolean;
    BorderRadius: Double;

    HasShadow: Boolean;
    EnableShadow: Boolean;

    HasFontSize: Boolean;
    FontSize: Double;

    HasFontWeight: Boolean;
    FontBold: Boolean;

    HasOpacity: Boolean;
    Opacity: Double;

    HasBackdropBlur: Boolean;
    BackdropBlur: Double;

    HasTransition: Boolean;
    TransitionProp: string;
    TransitionDurationMs: Integer;
    TransitionTiming: string;

    procedure Init();
    procedure Merge(const Other: TFtWidgetStyle);
  end;

type
  TFtStyleSheetChangeNotify = procedure() of object;

  { Stylesheet manager backed by Floria.CSS }
  TFtStyleSheet = class
  private
    FResolver: TCSSStyleResolver;
    FOnChange: TFtStyleSheetChangeNotify;
    FRootNormalBlock: TCSSStyleBlock;
    FRootDarkBlock: TCSSStyleBlock;
    FRootHoverBlock: TCSSStyleBlock;
    FRootDisabledBlock: TCSSStyleBlock;
    FRootDarkHoverBlock: TCSSStyleBlock;
    FRootDarkDisabledBlock: TCSSStyleBlock;

    procedure ClearRootBlocks();
    function GetRootBlock(const AClasses, APseudo: string): TCSSStyleBlock;
    function GetCustomVarValue(const AVarName: string; ALocalBlock: TCSSStyleBlock; const AClasses, APseudo: string): string;
    function ResolveVarsInString(const S: string; ALocalBlock: TCSSStyleBlock; const AClasses, APseudo: string; ADepth: Integer = 0): string;
    procedure ApplyStyleBlock(ABlock: TCSSStyleBlock; var AStyle: TFtWidgetStyle; const AClasses: string = ''; const APseudo: string = '');
    procedure ApplyBaselineDefaults(var AStyle: TFtWidgetStyle; const AElementType, AClasses, APseudo: string);
  public
    constructor Create();
    destructor Destroy(); override;

    procedure Clear();
    function LoadFromFile(const APath: string): Boolean;
    function LoadFromString(const ACss: string): Boolean;

    function ResolveStyle(const AElementType, AId, AClasses, APseudo: string; const AInlineCss: string = ''): TFtWidgetStyle;
    function ParseInlineStyle(const AInlineCss: string; const AClasses: string = ''; const APseudo: string = ''): TFtWidgetStyle;

    function GetVariable(const AVarName: string; const AClasses: string = ''; const APseudo: string = ''): string;
    function ResolveString(const S: string; const AClasses: string = ''; const APseudo: string = ''): string;

    property OnChange: TFtStyleSheetChangeNotify read FOnChange write FOnChange;
  end;

{ Helper functions }
function FtRgba(R, G, B: Double; A: Double = 1.0): TFtRgbaColor;
function FtParseColor(const S: string; out Col: TFtRgbaColor): Boolean;
function FtParseLength(const S: string; out Val: Double): Boolean;
function FtParseOpacity(const S: string; out Val: Double): Boolean;
function FtParseTimeMs(const S: string; out Ms: Integer): Boolean;
function FtParseTransition(const S: string; out Prop: string; out DurationMs: Integer; out Timing: string): Boolean;

{ Global default stylesheet }
function FtGetStyleSheet(): TFtStyleSheet;
function FtLoadStyleSheet(const APath: string): Boolean;
function FtLoadStyleSheetString(const ACss: string): Boolean;
procedure FtSetCssDarkMode(AValue: Boolean);
function FtGetCssDarkMode(): Boolean;

implementation

var
  GStyleSheet: TFtStyleSheet = nil;
  GCssDarkMode: Boolean = False;

procedure FtSetCssDarkMode(AValue: Boolean);
begin
  GCssDarkMode := AValue;
end;

function FtGetCssDarkMode(): Boolean;
begin
  Result := GCssDarkMode;
end;

function FtRgba(R, G, B: Double; A: Double = 1.0): TFtRgbaColor;
begin
  Result.R := R;
  Result.G := G;
  Result.B := B;
  Result.A := A;
end;

procedure TFtWidgetStyle.Init();
begin
  HasBgColor := False;
  BgColor := FtRgba(0.0, 0.0, 0.0, 1.0);

  HasTextColor := False;
  TextColor := FtRgba(0.0, 0.0, 0.0, 1.0);

  HasBorderColor := False;
  BorderColor := FtRgba(0.0, 0.0, 0.0, 1.0);

  HasBorderWidth := False;
  BorderWidth := 0.0;

  HasBorderRadius := False;
  BorderRadius := 0.0;

  HasShadow := False;
  EnableShadow := False;

  HasFontSize := False;
  FontSize := 13.0;

  HasFontWeight := False;
  FontBold := False;

  HasOpacity := False;
  Opacity := 1.0;

  HasBackdropBlur := False;
  BackdropBlur := 0.0;

  HasTransition := False;
  TransitionProp := '';
  TransitionDurationMs := 0;
  TransitionTiming := 'ease';
end;

procedure TFtWidgetStyle.Merge(const Other: TFtWidgetStyle);
begin
  if Other.HasBgColor then
  begin
    HasBgColor := True;
    BgColor := Other.BgColor;
  end;
  if Other.HasTextColor then
  begin
    HasTextColor := True;
    TextColor := Other.TextColor;
  end;
  if Other.HasBorderColor then
  begin
    HasBorderColor := True;
    BorderColor := Other.BorderColor;
  end;
  if Other.HasBorderWidth then
  begin
    HasBorderWidth := True;
    BorderWidth := Other.BorderWidth;
  end;
  if Other.HasBorderRadius then
  begin
    HasBorderRadius := True;
    BorderRadius := Other.BorderRadius;
  end;
  if Other.HasShadow then
  begin
    HasShadow := True;
    EnableShadow := Other.EnableShadow;
  end;
  if Other.HasFontSize then
  begin
    HasFontSize := True;
    FontSize := Other.FontSize;
  end;
  if Other.HasFontWeight then
  begin
    HasFontWeight := True;
    FontBold := Other.FontBold;
  end;
  if Other.HasOpacity then
  begin
    HasOpacity := True;
    Opacity := Other.Opacity;
  end;
  if Other.HasBackdropBlur then
  begin
    HasBackdropBlur := True;
    BackdropBlur := Other.BackdropBlur;
  end;
  if Other.HasTransition then
  begin
    HasTransition := True;
    TransitionProp := Other.TransitionProp;
    TransitionDurationMs := Other.TransitionDurationMs;
    TransitionTiming := Other.TransitionTiming;
  end;
end;

function ParseHexNibble(C: Char): Integer;
begin
  case C of
    '0'..'9': Result := Ord(C) - Ord('0');
    'a'..'f': Result := Ord(C) - Ord('a') + 10;
    'A'..'F': Result := Ord(C) - Ord('A') + 10;
  else
    Result := -1;
  end;
end;

function FtParseColor(const S: string; out Col: TFtRgbaColor): Boolean;
var
  cssCol: TCSSColor;
  clean: string;
  n1, n2, n3, n4, n5, n6, n7, n8: Integer;
  p1, p2: Integer;
  inside: string;
  parts: TStringList;
  v1, v2, v3, v4: Double;
begin
  Result := False;
  clean := Trim(S);
  if Length(clean) = 0 then Exit;

  // 1. Try Floria.CSS color parser
  if TCSSColor.TryParse(clean, cssCol) then
  begin
    Col := FtRgba(cssCol.R / 255.0, cssCol.G / 255.0, cssCol.B / 255.0, cssCol.A / 255.0);
    Exit(True);
  end;

  // 2. Fallback parsers for robustness
  clean := LowerCase(clean);
  if clean[1] = '#' then
  begin
    Delete(clean, 1, 1);
    case Length(clean) of
      3: // #rgb
      begin
        n1 := ParseHexNibble(clean[1]);
        n2 := ParseHexNibble(clean[2]);
        n3 := ParseHexNibble(clean[3]);
        if (n1 >= 0) and (n2 >= 0) and (n3 >= 0) then
        begin
          Col := FtRgba(n1 / 15.0, n2 / 15.0, n3 / 15.0, 1.0);
          Exit(True);
        end;
      end;
      4: // #rgba
      begin
        n1 := ParseHexNibble(clean[1]);
        n2 := ParseHexNibble(clean[2]);
        n3 := ParseHexNibble(clean[3]);
        n4 := ParseHexNibble(clean[4]);
        if (n1 >= 0) and (n2 >= 0) and (n3 >= 0) and (n4 >= 0) then
        begin
          Col := FtRgba(n1 / 15.0, n2 / 15.0, n3 / 15.0, n4 / 15.0);
          Exit(True);
        end;
      end;
      6: // #rrggbb
      begin
        n1 := ParseHexNibble(clean[1]); n2 := ParseHexNibble(clean[2]);
        n3 := ParseHexNibble(clean[3]); n4 := ParseHexNibble(clean[4]);
        n5 := ParseHexNibble(clean[5]); n6 := ParseHexNibble(clean[6]);
        if (n1 >= 0) and (n2 >= 0) and (n3 >= 0) and (n4 >= 0) and (n5 >= 0) and (n6 >= 0) then
        begin
          Col := FtRgba((n1 * 16 + n2) / 255.0,
                        (n3 * 16 + n4) / 255.0,
                        (n5 * 16 + n6) / 255.0, 1.0);
          Exit(True);
        end;
      end;
      8: // #rrggbbaa
      begin
        n1 := ParseHexNibble(clean[1]); n2 := ParseHexNibble(clean[2]);
        n3 := ParseHexNibble(clean[3]); n4 := ParseHexNibble(clean[4]);
        n5 := ParseHexNibble(clean[5]); n6 := ParseHexNibble(clean[6]);
        n7 := ParseHexNibble(clean[7]); n8 := ParseHexNibble(clean[8]);
        if (n1 >= 0) and (n2 >= 0) and (n3 >= 0) and (n4 >= 0) and
           (n5 >= 0) and (n6 >= 0) and (n7 >= 0) and (n8 >= 0) then
        begin
          Col := FtRgba((n1 * 16 + n2) / 255.0,
                        (n3 * 16 + n4) / 255.0,
                        (n5 * 16 + n6) / 255.0,
                        (n7 * 16 + n8) / 255.0);
          Exit(True);
        end;
      end;
    end;
  end;

  if (Copy(clean, 1, 4) = 'rgb(') or (Copy(clean, 1, 5) = 'rgba(') then
  begin
    p1 := Pos('(', clean);
    p2 := Pos(')', clean);
    if (p1 > 0) and (p2 > p1) then
    begin
      inside := Copy(clean, p1 + 1, p2 - p1 - 1);
      parts := TStringList.Create();
      try
        parts.Delimiter := ',';
        parts.StrictDelimiter := True;
        parts.DelimitedText := inside;
        if parts.Count >= 3 then
        begin
          v1 := StrToFloatDef(Trim(parts[0]), 0.0) / 255.0;
          v2 := StrToFloatDef(Trim(parts[1]), 0.0) / 255.0;
          v3 := StrToFloatDef(Trim(parts[2]), 0.0) / 255.0;
          v4 := 1.0;
          if parts.Count >= 4 then
            v4 := StrToFloatDef(Trim(parts[3]), 1.0);
          Col := FtRgba(Max(0.0, Min(1.0, v1)),
                        Max(0.0, Min(1.0, v2)),
                        Max(0.0, Min(1.0, v3)),
                        Max(0.0, Min(1.0, v4)));
          Exit(True);
        end;
      finally
        parts.Free();
      end;
    end;
  end;
end;

function FtParseLength(const S: string; out Val: Double): Boolean;
var
  len: TCSSLength;
  clean: string;
begin
  Result := False;
  clean := Trim(S);
  if Length(clean) = 0 then Exit;

  // 1. Try Floria.CSS length parser
  if TCSSLength.TryParse(clean, len) then
  begin
    Val := len.ToPixels();
    Exit(True);
  end;

  // 2. Direct numeric fallback
  clean := LowerCase(clean);
  if (Length(clean) > 2) and (Copy(clean, Length(clean) - 1, 2) = 'px') then
    clean := Trim(Copy(clean, 1, Length(clean) - 2))
  else if (Length(clean) > 2) and (Copy(clean, Length(clean) - 1, 2) = 'pt') then
    clean := Trim(Copy(clean, 1, Length(clean) - 2));

  Val := StrToFloatDef(clean, -99999.0);
  if Val <> -99999.0 then
    Result := True;
end;

function FtParseOpacity(const S: string; out Val: Double): Boolean;
var
  clean: string;
  fs: TFormatSettings;
  num: Double;
  isPercent: Boolean;
begin
  Result := False;
  Val := 1.0;
  clean := Trim(S);
  if Length(clean) = 0 then Exit;

  isPercent := False;
  if clean[Length(clean)] = '%' then
  begin
    isPercent := True;
    clean := Trim(Copy(clean, 1, Length(clean) - 1));
  end;

  fs := DefaultFormatSettings;
  fs.DecimalSeparator := '.';
  if TryStrToFloat(clean, num, fs) then
  begin
    if isPercent then
      num := num / 100.0;
    if num < 0.0 then num := 0.0;
    if num > 1.0 then num := 1.0;
    Val := num;
    Result := True;
  end;
end;

function FtParseTimeMs(const S: string; out Ms: Integer): Boolean;
var
  clean: string;
  val: Double;
begin
  Result := False;
  clean := LowerCase(Trim(S));
  if Length(clean) = 0 then Exit;

  if (Length(clean) > 2) and (Copy(clean, Length(clean) - 1, 2) = 'ms') then
  begin
    val := StrToFloatDef(Trim(Copy(clean, 1, Length(clean) - 2)), -1.0);
    if val >= 0.0 then
    begin
      Ms := Round(val);
      Exit(True);
    end;
  end
  else if (Length(clean) > 1) and (clean[Length(clean)] = 's') then
  begin
    val := StrToFloatDef(Trim(Copy(clean, 1, Length(clean) - 1)), -1.0);
    if val >= 0.0 then
    begin
      Ms := Round(val * 1000.0);
      Exit(True);
    end;
  end
  else
  begin
    val := StrToFloatDef(clean, -1.0);
    if val >= 0.0 then
    begin
      Ms := Round(val);
      Exit(True);
    end;
  end;
end;

function NormalizeCssWhitespace(const S: string): string;
var
  i: Integer;
  inParen: Boolean;
begin
  Result := '';
  inParen := False;
  for i := 1 to Length(S) do
  begin
    if S[i] = '(' then inParen := True
    else if S[i] = ')' then inParen := False;

    if inParen and (S[i] = ' ') then
      Continue;
    Result := Result + S[i];
  end;
end;

function SplitCssClauses(const S: string): TStringList;
var
  i, startIdx: Integer;
  inParen: Boolean;
  clause: string;
begin
  Result := TStringList.Create();
  inParen := False;
  startIdx := 1;
  for i := 1 to Length(S) do
  begin
    if S[i] = '(' then inParen := True
    else if S[i] = ')' then inParen := False
    else if (S[i] = ',') and not inParen then
    begin
      clause := Trim(Copy(S, startIdx, i - startIdx));
      if clause <> '' then
        Result.Add(clause);
      startIdx := i + 1;
    end;
  end;
  if startIdx <= Length(S) then
  begin
    clause := Trim(Copy(S, startIdx, Length(S) - startIdx + 1));
    if clause <> '' then
      Result.Add(clause);
  end;
end;

function ParseSingleTransitionClause(const S: string; out Prop: string; out DurationMs: Integer; out Timing: string): Boolean;
var
  parts: TStringList;
  i, parsedMs: Integer;
  tok, cleanTok: string;
  lastWasNumber: Boolean;
begin
  Result := False;
  Prop := '';
  DurationMs := 0;
  Timing := 'ease';
  lastWasNumber := False;

  parts := TStringList.Create();
  try
    parts.Delimiter := ' ';
    parts.StrictDelimiter := True;
    parts.DelimitedText := NormalizeCssWhitespace(S);
    for i := 0 to parts.Count - 1 do
    begin
      tok := Trim(parts[i]);
      if tok = '' then Continue;
      cleanTok := LowerCase(tok);

      if cleanTok = 'ms' then
      begin
        lastWasNumber := False;
        Continue;
      end
      else if cleanTok = 's' then
      begin
        if lastWasNumber and (DurationMs > 0) then
          DurationMs := DurationMs * 1000;
        lastWasNumber := False;
        Continue;
      end
      else if FtParseTimeMs(cleanTok, parsedMs) then
      begin
        DurationMs := parsedMs;
        lastWasNumber := True;
        Result := True;
      end
      else if (cleanTok = 'ease') or (cleanTok = 'linear') or (cleanTok = 'ease-in') or
              (cleanTok = 'ease-out') or (cleanTok = 'ease-in-out') or
              (Pos('cubic-bezier', cleanTok) = 1) then
      begin
        Timing := cleanTok;
        lastWasNumber := False;
      end
      else
      begin
        Prop := cleanTok;
        lastWasNumber := False;
      end;
    end;
  finally
    parts.Free();
  end;

  if Prop = '' then Prop := 'all';
end;

function FtParseTransition(const S: string; out Prop: string; out DurationMs: Integer; out Timing: string): Boolean;
var
  clauses: TStringList;
  i, curDur: Integer;
  curProp, curTiming, collectedProps: string;
begin
  Result := False;
  collectedProps := '';
  DurationMs := 0;
  Timing := 'ease';

  clauses := SplitCssClauses(S);
  try
    for i := 0 to clauses.Count - 1 do
    begin
      if ParseSingleTransitionClause(clauses[i], curProp, curDur, curTiming) then
      begin
        Result := True;
        if curDur > DurationMs then DurationMs := curDur;
        if curTiming <> 'ease' then Timing := curTiming;
        if curProp = 'all' then
          collectedProps := 'all'
        else if collectedProps <> 'all' then
        begin
          if (collectedProps <> '') and (Pos(curProp, collectedProps) = 0) then
            collectedProps := collectedProps + ',' + curProp
          else if collectedProps = '' then
            collectedProps := curProp;
        end;
      end;
    end;
  finally
    clauses.Free();
  end;

  if collectedProps = '' then collectedProps := 'all';
  Prop := collectedProps;
end;

type
  { Adapter implementing ICSSElement for Floria.CSS cascade matching }
  TFtCSSElementAdapter = class(TInterfacedObject, ICSSElement)
  private
    FTagName: AnsiString;
    FId: AnsiString;
    FClasses: TStringList;
    FHovered: Boolean;
    FFocused: Boolean;
    FActive: Boolean;
    FDisabled: Boolean;
    FChecked: Boolean;
    FParent: ICSSElement;
  public
    constructor Create(const AElementType, AId, AClasses, APseudo: string; const AParent: ICSSElement = nil);
    destructor Destroy(); override;

    function GetTagName(): AnsiString;
    function GetId(): AnsiString;
    function HasClass(const AClass: AnsiString): Boolean;
    function HasAttribute(const AName: AnsiString): Boolean;
    function GetAttribute(const AName: AnsiString): AnsiString;
    function GetParent(): ICSSElement;
    function GetPreviousSibling(): ICSSElement;
    function GetChildIndex(): Integer;
    function GetSiblingCount(): Integer;
    function IsHovered(): Boolean;
    function IsFocused(): Boolean;
    function IsActive(): Boolean;
    function IsDisabled(): Boolean;
    function IsChecked(): Boolean;
  end;

constructor TFtCSSElementAdapter.Create(const AElementType, AId, AClasses, APseudo: string; const AParent: ICSSElement);
var
  cleanPseudo: string;
  sl: TStringList;
  i: Integer;
begin
  inherited Create();
  FTagName := AElementType;
  if SameText(FTagName, ':root') or SameText(FTagName, 'root') then
    FTagName := 'window';
  FId := AId;
  FClasses := TStringList.Create();
  FParent := AParent;

  if AClasses <> '' then
  begin
    sl := TStringList.Create();
    try
      sl.Delimiter := ' ';
      sl.StrictDelimiter := False;
      sl.DelimitedText := AClasses;
      for i := 0 to sl.Count - 1 do
        if Trim(sl[i]) <> '' then
          FClasses.Add(Trim(sl[i]));
    finally
      sl.Free();
    end;
  end;

  cleanPseudo := LowerCase(Trim(APseudo));
  if (cleanPseudo <> '') and (cleanPseudo[1] = ':') then
    Delete(cleanPseudo, 1, 1);

  FHovered  := cleanPseudo = 'hover';
  FFocused  := cleanPseudo = 'focus';
  FActive   := cleanPseudo = 'active';
  FDisabled := cleanPseudo = 'disabled';
  FChecked  := cleanPseudo = 'checked';

  // If element is not root, provide a virtual window parent
  // so descendant rules like "window button" or ".dark button" match as well as compound selectors
  if (FParent = nil) and (not SameText(FTagName, 'window')) then
  begin
    if HasClass('dark') then
      FParent := TFtCSSElementAdapter.Create('window', '', 'dark', '', nil)
    else
      FParent := TFtCSSElementAdapter.Create('window', '', '', '', nil);
  end;
end;

destructor TFtCSSElementAdapter.Destroy();
begin
  FClasses.Free();
  inherited Destroy();
end;

function TFtCSSElementAdapter.GetTagName(): AnsiString;
begin
  Result := FTagName;
end;

function TFtCSSElementAdapter.GetId(): AnsiString;
begin
  Result := FId;
end;

function TFtCSSElementAdapter.HasClass(const AClass: AnsiString): Boolean;
var
  i: Integer;
begin
  for i := 0 to FClasses.Count - 1 do
    if SameText(FClasses[i], AClass) then
      Exit(True);
  Result := False;
end;

function TFtCSSElementAdapter.HasAttribute(const AName: AnsiString): Boolean;
begin
  Result := False;
end;

function TFtCSSElementAdapter.GetAttribute(const AName: AnsiString): AnsiString;
begin
  Result := '';
end;

function TFtCSSElementAdapter.GetParent(): ICSSElement;
begin
  Result := FParent;
end;

function TFtCSSElementAdapter.GetPreviousSibling(): ICSSElement;
begin
  Result := nil;
end;

function TFtCSSElementAdapter.GetChildIndex(): Integer;
begin
  Result := 1;
end;

function TFtCSSElementAdapter.GetSiblingCount(): Integer;
begin
  Result := 1;
end;

function TFtCSSElementAdapter.IsHovered(): Boolean;
begin
  Result := FHovered;
end;

function TFtCSSElementAdapter.IsFocused(): Boolean;
begin
  Result := FFocused;
end;

function TFtCSSElementAdapter.IsActive(): Boolean;
begin
  Result := FActive;
end;

function TFtCSSElementAdapter.IsDisabled(): Boolean;
begin
  Result := FDisabled;
end;

function TFtCSSElementAdapter.IsChecked(): Boolean;
begin
  Result := FChecked;
end;

{ TFtStyleSheet }

constructor TFtStyleSheet.Create();
begin
  inherited Create();
  FResolver := TCSSStyleResolver.Create();
  FRootNormalBlock := nil;
  FRootDarkBlock := nil;
  FRootHoverBlock := nil;
  FRootDisabledBlock := nil;
  FRootDarkHoverBlock := nil;
  FRootDarkDisabledBlock := nil;
end;

procedure TFtStyleSheet.ClearRootBlocks();
begin
  FreeAndNil(FRootNormalBlock);
  FreeAndNil(FRootDarkBlock);
  FreeAndNil(FRootHoverBlock);
  FreeAndNil(FRootDisabledBlock);
  FreeAndNil(FRootDarkHoverBlock);
  FreeAndNil(FRootDarkDisabledBlock);
end;

destructor TFtStyleSheet.Destroy();
begin
  Clear();
  FResolver.Free();
  inherited Destroy();
end;

procedure TFtStyleSheet.Clear();
begin
  ClearRootBlocks();
  if Assigned(FResolver) then
    FResolver.Clear();
end;

function TFtStyleSheet.LoadFromFile(const APath: string): Boolean;
var
  fs: TFileStream;
  ss: TStringStream;
begin
  Result := False;
  if not FileExists(APath) then Exit;

  try
    fs := TFileStream.Create(APath, fmOpenRead or fmShareDenyNone);
    try
      ss := TStringStream.Create('');
      try
        ss.CopyFrom(fs, fs.Size);
        Result := LoadFromString(ss.DataString);
      finally
        ss.Free();
      end;
    finally
      fs.Free();
    end;
  except
    Result := False;
  end;
end;

function TFtStyleSheet.LoadFromString(const ACss: string): Boolean;
begin
  Result := False;
  Clear();
  try
    FResolver.AddCSS(ACss);
    Result := True;
    if Assigned(FOnChange) then
      FOnChange();
  except
    Clear();
    Result := False;
  end;
end;

function TFtStyleSheet.GetRootBlock(const AClasses, APseudo: string): TCSSStyleBlock;
var
  isDark, isHover, isDisabled: Boolean;
  adapter: ICSSElement;
begin
  isDark := (Pos('dark', LowerCase(AClasses)) > 0);
  isHover := SameText(APseudo, 'hover') or (APseudo = ':hover');
  isDisabled := SameText(APseudo, 'disabled') or (APseudo = ':disabled');

  if isDark then
  begin
    if isHover then
    begin
      if FRootDarkHoverBlock = nil then
      begin
        adapter := TFtCSSElementAdapter.Create('window', '', 'dark', 'hover', nil);
        FRootDarkHoverBlock := FResolver.ResolveStyle(adapter);
      end;
      Result := FRootDarkHoverBlock;
    end
    else if isDisabled then
    begin
      if FRootDarkDisabledBlock = nil then
      begin
        adapter := TFtCSSElementAdapter.Create('window', '', 'dark', 'disabled', nil);
        FRootDarkDisabledBlock := FResolver.ResolveStyle(adapter);
      end;
      Result := FRootDarkDisabledBlock;
    end
    else
    begin
      if FRootDarkBlock = nil then
      begin
        adapter := TFtCSSElementAdapter.Create('window', '', 'dark', '', nil);
        FRootDarkBlock := FResolver.ResolveStyle(adapter);
      end;
      Result := FRootDarkBlock;
    end;
  end
  else
  begin
    if isHover then
    begin
      if FRootHoverBlock = nil then
      begin
        adapter := TFtCSSElementAdapter.Create('window', '', '', 'hover', nil);
        FRootHoverBlock := FResolver.ResolveStyle(adapter);
      end;
      Result := FRootHoverBlock;
    end
    else if isDisabled then
    begin
      if FRootDisabledBlock = nil then
      begin
        adapter := TFtCSSElementAdapter.Create('window', '', '', 'disabled', nil);
        FRootDisabledBlock := FResolver.ResolveStyle(adapter);
      end;
      Result := FRootDisabledBlock;
    end
    else
    begin
      if FRootNormalBlock = nil then
      begin
        adapter := TFtCSSElementAdapter.Create('window', '', '', '', nil);
        FRootNormalBlock := FResolver.ResolveStyle(adapter);
      end;
      Result := FRootNormalBlock;
    end;
  end;
end;

function TFtStyleSheet.GetCustomVarValue(const AVarName: string; ALocalBlock: TCSSStyleBlock; const AClasses, APseudo: string): string;
var
  dashName, noDashName: string;
  blk: TCSSStyleBlock;
  isDark: Boolean;

  function LookupInBlock(ABlk: TCSSStyleBlock): string;
  var
    d: TCSSStyleDeclaration;
  begin
    Result := '';
    if ABlk = nil then Exit;
    d := ABlk.GetCustom(dashName);
    if d = nil then d := ABlk.GetCustom(noDashName);
    if d <> nil then
      Result := Trim(d.Value.ToString());
  end;

begin
  Result := '';
  if AVarName = '' then Exit;

  if (Length(AVarName) >= 2) and (AVarName[1] = '-') and (AVarName[2] = '-') then
  begin
    dashName := AVarName;
    noDashName := Copy(AVarName, 3, Length(AVarName));
  end
  else
  begin
    dashName := '--' + AVarName;
    noDashName := AVarName;
  end;

  // 1. Check local declaration block first (highest specificity)
  if ALocalBlock <> nil then
  begin
    Result := LookupInBlock(ALocalBlock);
    if Result <> '' then Exit;
  end;

  isDark := (Pos('dark', LowerCase(AClasses)) > 0);

  // 2. If dark mode, check state root or dark base root
  if isDark then
  begin
    if (APseudo <> '') and not SameText(APseudo, 'normal') then
    begin
      blk := GetRootBlock('dark', APseudo);
      Result := LookupInBlock(blk);
      if Result <> '' then Exit;
    end;

    blk := GetRootBlock('dark', '');
    Result := LookupInBlock(blk);
    if Result <> '' then Exit;
  end;

  // 3. Check light state root (if pseudo state specified)
  if (APseudo <> '') and not SameText(APseudo, 'normal') then
  begin
    blk := GetRootBlock('', APseudo);
    Result := LookupInBlock(blk);
    if Result <> '' then Exit;
  end;

  // 4. Check base normal root
  blk := GetRootBlock('', '');
  Result := LookupInBlock(blk);
end;

function TFtStyleSheet.ResolveVarsInString(const S: string; ALocalBlock: TCSSStyleBlock; const AClasses, APseudo: string; ADepth: Integer): string;
var
  i, pVar, openParen, closeParen, depth, commaPos: Integer;
  res, prefix, varName, fallbackVal, resolvedVal: string;
  foundComma: Boolean;
begin
  if ADepth > 10 then Exit(S);
  res := S;
  while True do
  begin
    pVar := Pos('var(', LowerCase(res));
    if pVar = 0 then Break;

    openParen := pVar + 3; // points to '('
    depth := 1;
    commaPos := 0;
    foundComma := False;
    closeParen := 0;

    for i := openParen + 1 to Length(res) do
    begin
      if res[i] = '(' then
        Inc(depth)
      else if res[i] = ')' then
      begin
        Dec(depth);
        if depth = 0 then
        begin
          closeParen := i;
          Break;
        end;
      end
      else if (res[i] = ',') and (depth = 1) and not foundComma then
      begin
        commaPos := i;
        foundComma := True;
      end;
    end;

    if closeParen = 0 then Break;

    prefix := Copy(res, 1, pVar - 1);

    if foundComma then
    begin
      varName := Trim(Copy(res, openParen + 1, commaPos - openParen - 1));
      fallbackVal := Trim(Copy(res, commaPos + 1, closeParen - commaPos - 1));
    end
    else
    begin
      varName := Trim(Copy(res, openParen + 1, closeParen - openParen - 1));
      fallbackVal := '';
    end;

    resolvedVal := GetCustomVarValue(varName, ALocalBlock, AClasses, APseudo);
    if resolvedVal <> '' then
    begin
      if Pos('var(', LowerCase(resolvedVal)) > 0 then
        resolvedVal := ResolveVarsInString(resolvedVal, ALocalBlock, AClasses, APseudo, ADepth + 1);
    end
    else if fallbackVal <> '' then
    begin
      if Pos('var(', LowerCase(fallbackVal)) > 0 then
        resolvedVal := ResolveVarsInString(fallbackVal, ALocalBlock, AClasses, APseudo, ADepth + 1)
      else
        resolvedVal := fallbackVal;
    end
    else
      resolvedVal := '';

    res := prefix + resolvedVal + Copy(res, closeParen + 1, Length(res) - closeParen);
  end;

  Result := res;
end;

function TFtStyleSheet.GetVariable(const AVarName: string; const AClasses: string; const APseudo: string): string;
begin
  Result := GetCustomVarValue(AVarName, nil, AClasses, APseudo);
end;

function TFtStyleSheet.ResolveString(const S: string; const AClasses: string; const APseudo: string): string;
begin
  Result := ResolveVarsInString(S, nil, AClasses, APseudo, 0);
end;

procedure ParseBorderShorthand(const S: string; var AStyle: TFtWidgetStyle);
var
  parts: TStringList;
  i: Integer;
  tok: string;
  lenVal: Double;
  col: TFtRgbaColor;
begin
  parts := TStringList.Create();
  try
    parts.Delimiter := ' ';
    parts.StrictDelimiter := False;
    parts.DelimitedText := S;
    for i := 0 to parts.Count - 1 do
    begin
      tok := Trim(parts[i]);
      if tok = '' then Continue;
      if SameText(tok, 'none') or SameText(tok, 'hidden') then
      begin
        AStyle.HasBorderWidth := True;
        AStyle.BorderWidth := 0.0;
      end
      else if FtParseLength(tok, lenVal) then
      begin
        AStyle.HasBorderWidth := True;
        AStyle.BorderWidth := lenVal;
      end
      else if FtParseColor(tok, col) then
      begin
        AStyle.HasBorderColor := True;
        AStyle.BorderColor := col;
      end;
    end;
  finally
    parts.Free();
  end;
end;

procedure TFtStyleSheet.ApplyStyleBlock(ABlock: TCSSStyleBlock; var AStyle: TFtWidgetStyle; const AClasses: string; const APseudo: string);
var
  decl: TCSSStyleDeclaration;
  col: TFtRgbaColor;
  s, subStr, resolvedStr: string;
  pIdx: Integer;
  lenVal, opacVal: Double;
begin
  if ABlock = nil then Exit;

  // Background Color
  decl := ABlock.GetDeclaration(cpiBackgroundColor);
  if (decl <> nil) and (decl.Value.Kind = cvkColor) then
  begin
    AStyle.HasBgColor := True;
    AStyle.BgColor := FtRgba(decl.Value.Color.R / 255.0,
                             decl.Value.Color.G / 255.0,
                             decl.Value.Color.B / 255.0,
                             decl.Value.Color.A / 255.0);
  end
  else if (decl <> nil) and FtParseColor(ResolveVarsInString(decl.Value.ToString(), ABlock, AClasses, APseudo), col) then
  begin
    AStyle.HasBgColor := True;
    AStyle.BgColor := col;
  end
  else
  begin
    decl := ABlock.GetCustom('background');
    if (decl <> nil) and FtParseColor(ResolveVarsInString(decl.Value.Str, ABlock, AClasses, APseudo), col) then
    begin
      AStyle.HasBgColor := True;
      AStyle.BgColor := col;
    end;
  end;

  // Text Color
  decl := ABlock.GetDeclaration(cpiColor);
  if (decl <> nil) and (decl.Value.Kind = cvkColor) then
  begin
    AStyle.HasTextColor := True;
    AStyle.TextColor := FtRgba(decl.Value.Color.R / 255.0,
                              decl.Value.Color.G / 255.0,
                              decl.Value.Color.B / 255.0,
                              decl.Value.Color.A / 255.0);
  end
  else if (decl <> nil) and FtParseColor(ResolveVarsInString(decl.Value.ToString(), ABlock, AClasses, APseudo), col) then
  begin
    AStyle.HasTextColor := True;
    AStyle.TextColor := col;
  end;

  // Border Color
  decl := ABlock.GetDeclaration(cpiBorderColor);
  if decl = nil then decl := ABlock.GetDeclaration(cpiBorderTopColor);
  if (decl <> nil) and (decl.Value.Kind = cvkColor) then
  begin
    AStyle.HasBorderColor := True;
    AStyle.BorderColor := FtRgba(decl.Value.Color.R / 255.0,
                                decl.Value.Color.G / 255.0,
                                decl.Value.Color.B / 255.0,
                                decl.Value.Color.A / 255.0);
  end
  else if (decl <> nil) and FtParseColor(ResolveVarsInString(decl.Value.ToString(), ABlock, AClasses, APseudo), col) then
  begin
    AStyle.HasBorderColor := True;
    AStyle.BorderColor := col;
  end;

  // Border Width
  decl := ABlock.GetDeclaration(cpiBorderWidth);
  if decl = nil then decl := ABlock.GetDeclaration(cpiBorderTopWidth);
  if decl <> nil then
  begin
    if decl.Value.Kind = cvkLength then
    begin
      AStyle.HasBorderWidth := True;
      AStyle.BorderWidth := decl.Value.Length.ToPixels();
    end
    else if decl.Value.Kind = cvkBox then
    begin
      AStyle.HasBorderWidth := True;
      AStyle.BorderWidth := decl.Value.Box.Top.ToPixels();
    end
    else if decl.Value.Kind = cvkNumber then
    begin
      AStyle.HasBorderWidth := True;
      AStyle.BorderWidth := decl.Value.Number;
    end
    else if FtParseLength(ResolveVarsInString(decl.Value.ToString(), ABlock, AClasses, APseudo), lenVal) then
    begin
      AStyle.HasBorderWidth := True;
      AStyle.BorderWidth := lenVal;
    end;
  end;

  // Border Shorthand: border: 1px solid var(--border-color)
  decl := ABlock.GetDeclaration(cpiBorder);
  if decl = nil then decl := ABlock.GetCustom('border');
  if decl <> nil then
  begin
    resolvedStr := ResolveVarsInString(decl.Value.ToString(), ABlock, AClasses, APseudo);
    ParseBorderShorthand(resolvedStr, AStyle);
  end;

  // Border Radius
  decl := ABlock.GetDeclaration(cpiBorderRadius);
  if decl = nil then decl := ABlock.GetDeclaration(cpiBorderTopLeftRadius);
  if decl <> nil then
  begin
    if decl.Value.Kind = cvkLength then
    begin
      AStyle.HasBorderRadius := True;
      AStyle.BorderRadius := decl.Value.Length.ToPixels();
    end
    else if decl.Value.Kind = cvkBox then
    begin
      AStyle.HasBorderRadius := True;
      AStyle.BorderRadius := decl.Value.Box.Top.ToPixels();
    end
    else if decl.Value.Kind = cvkNumber then
    begin
      AStyle.HasBorderRadius := True;
      AStyle.BorderRadius := decl.Value.Number;
    end
    else if FtParseLength(ResolveVarsInString(decl.Value.ToString(), ABlock, AClasses, APseudo), lenVal) then
    begin
      AStyle.HasBorderRadius := True;
      AStyle.BorderRadius := lenVal;
    end;
  end;

  // Shadow
  decl := ABlock.GetCustom('box-shadow');
  if decl = nil then decl := ABlock.GetCustom('shadow');
  if decl <> nil then
  begin
    s := LowerCase(Trim(ResolveVarsInString(decl.Value.ToString(), ABlock, AClasses, APseudo)));
    if (s = 'none') or (s = '0') or (s = 'false') then
    begin
      AStyle.HasShadow := True;
      AStyle.EnableShadow := False;
    end
    else if s <> '' then
    begin
      AStyle.HasShadow := True;
      AStyle.EnableShadow := True;
    end;
  end;

  // Font Size
  decl := ABlock.GetDeclaration(cpiFontSize);
  if decl <> nil then
  begin
    if decl.Value.Kind = cvkLength then
    begin
      AStyle.HasFontSize := True;
      AStyle.FontSize := decl.Value.Length.ToPixels();
    end
    else if decl.Value.Kind = cvkNumber then
    begin
      AStyle.HasFontSize := True;
      AStyle.FontSize := decl.Value.Number;
    end
    else if FtParseLength(ResolveVarsInString(decl.Value.ToString(), ABlock, AClasses, APseudo), lenVal) then
    begin
      AStyle.HasFontSize := True;
      AStyle.FontSize := lenVal;
    end;
  end;

  // Font Weight
  decl := ABlock.GetDeclaration(cpiFontWeight);
  if decl <> nil then
  begin
    AStyle.HasFontWeight := True;
    if decl.Value.Kind = cvkKeyword then
      AStyle.FontBold := (decl.Value.Keyword = 'bold') or (decl.Value.Keyword = 'bolder')
    else if decl.Value.Kind = cvkNumber then
      AStyle.FontBold := decl.Value.Number >= 700.0
    else
    begin
      s := LowerCase(Trim(ResolveVarsInString(decl.Value.ToString(), ABlock, AClasses, APseudo)));
      AStyle.FontBold := (s = 'bold') or (s = '700') or (s = '800') or (s = '900');
    end;
  end;

  // Opacity
  decl := ABlock.GetDeclaration(cpiOpacity);
  if decl = nil then decl := ABlock.GetCustom('opacity');
  if decl <> nil then
  begin
    if decl.Value.Kind = cvkNumber then
    begin
      AStyle.HasOpacity := True;
      AStyle.Opacity := Max(0.0, Min(1.0, decl.Value.Number));
    end
    else if decl.Value.Kind = cvkLength then
    begin
      AStyle.HasOpacity := True;
      if decl.Value.Length.Unit_ = cuPercent then
        AStyle.Opacity := Max(0.0, Min(1.0, decl.Value.Length.Value / 100.0))
      else
        AStyle.Opacity := Max(0.0, Min(1.0, decl.Value.Length.Value));
    end
    else if FtParseOpacity(ResolveVarsInString(decl.Value.ToString(), ABlock, AClasses, APseudo), opacVal) then
    begin
      AStyle.HasOpacity := True;
      AStyle.Opacity := opacVal;
    end;
  end;

  // Backdrop Filter (Blur)
  decl := ABlock.GetCustom('backdrop-filter');
  if decl = nil then decl := ABlock.GetCustom('-webkit-backdrop-filter');
  if decl <> nil then
  begin
    s := ResolveVarsInString(decl.Value.ToString(), ABlock, AClasses, APseudo);
    pIdx := Pos('blur(', LowerCase(s));
    if pIdx > 0 then
    begin
      subStr := Copy(s, pIdx + 5, Length(s));
      pIdx := Pos(')', subStr);
      if pIdx > 0 then
        subStr := Trim(Copy(subStr, 1, pIdx - 1));
      if FtParseLength(subStr, lenVal) then
      begin
        AStyle.HasBackdropBlur := True;
        AStyle.BackdropBlur := lenVal;
      end;
    end;
  end;

  // Transitions
  decl := ABlock.GetCustom('transition');
  if decl <> nil then
  begin
    resolvedStr := ResolveVarsInString(decl.Value.ToString(), ABlock, AClasses, APseudo);
    if FtParseTransition(resolvedStr, AStyle.TransitionProp, AStyle.TransitionDurationMs, AStyle.TransitionTiming) then
      AStyle.HasTransition := True;
  end;

  decl := ABlock.GetCustom('transition-duration');
  if decl <> nil then
  begin
    resolvedStr := ResolveVarsInString(decl.Value.ToString(), ABlock, AClasses, APseudo);
    if FtParseTimeMs(resolvedStr, AStyle.TransitionDurationMs) then
      AStyle.HasTransition := True;
  end;

  decl := ABlock.GetCustom('transition-property');
  if decl <> nil then
  begin
    AStyle.HasTransition := True;
    AStyle.TransitionProp := LowerCase(Trim(ResolveVarsInString(decl.Value.ToString(), ABlock, AClasses, APseudo)));
  end;

  decl := ABlock.GetCustom('transition-timing-function');
  if decl <> nil then
  begin
    AStyle.HasTransition := True;
    AStyle.TransitionTiming := LowerCase(Trim(ResolveVarsInString(decl.Value.ToString(), ABlock, AClasses, APseudo)));
  end;
end;

procedure TFtStyleSheet.ApplyBaselineDefaults(var AStyle: TFtWidgetStyle; const AElementType, AClasses, APseudo: string);
var
  isRootElem, isDark, isHover, isDisabled: Boolean;
  rootBlk, rootHoverBlk, rootDisabledBlk: TCSSStyleBlock;
  rootNormalStyle, rootStateStyle: TFtWidgetStyle;
  varVal: string;
  col: TFtRgbaColor;
begin
  isRootElem := SameText(AElementType, 'window') or SameText(AElementType, 'root') or SameText(AElementType, ':root');
  if isRootElem then Exit;

  isDark := (Pos('dark', LowerCase(AClasses)) > 0) or GCssDarkMode;
  isHover := SameText(APseudo, 'hover') or (APseudo = ':hover');
  isDisabled := SameText(APseudo, 'disabled') or (APseudo = ':disabled');

  rootNormalStyle.Init();
  if isDark then
    rootBlk := GetRootBlock('dark', '')
  else
    rootBlk := GetRootBlock('', '');
  ApplyStyleBlock(rootBlk, rootNormalStyle, AClasses, '');

  rootStateStyle.Init();
  if isHover then
  begin
    if isDark then
      rootHoverBlk := GetRootBlock('dark', 'hover')
    else
      rootHoverBlk := GetRootBlock('', 'hover');
    ApplyStyleBlock(rootHoverBlk, rootStateStyle, AClasses, 'hover');
  end
  else if isDisabled then
  begin
    if isDark then
      rootDisabledBlk := GetRootBlock('dark', 'disabled')
    else
      rootDisabledBlk := GetRootBlock('', 'disabled');
    ApplyStyleBlock(rootDisabledBlk, rootStateStyle, AClasses, 'disabled');
  end;

  // 1. Text Color baseline inheritance
  if not AStyle.HasTextColor then
  begin
    if isHover then
    begin
      if rootStateStyle.HasTextColor then
      begin
        AStyle.HasTextColor := True;
        AStyle.TextColor := rootStateStyle.TextColor;
      end
      else
      begin
        varVal := GetCustomVarValue('--hover-text-color', nil, AClasses, APseudo);
        if varVal = '' then varVal := GetCustomVarValue('--color-hover-text', nil, AClasses, APseudo);
        if varVal = '' then varVal := GetCustomVarValue('--hover-color', nil, AClasses, APseudo);
        if (varVal <> '') and FtParseColor(varVal, col) then
        begin
          AStyle.HasTextColor := True;
          AStyle.TextColor := col;
        end
        else if rootNormalStyle.HasTextColor then
        begin
          AStyle.HasTextColor := True;
          AStyle.TextColor := rootNormalStyle.TextColor;
        end;
      end;
    end
    else if isDisabled then
    begin
      if rootStateStyle.HasTextColor then
      begin
        AStyle.HasTextColor := True;
        AStyle.TextColor := rootStateStyle.TextColor;
      end
      else
      begin
        varVal := GetCustomVarValue('--disabled-text-color', nil, AClasses, APseudo);
        if varVal = '' then varVal := GetCustomVarValue('--text-disabled', nil, AClasses, APseudo);
        if varVal = '' then varVal := GetCustomVarValue('--color-disabled-text', nil, AClasses, APseudo);
        if varVal = '' then varVal := GetCustomVarValue('--disabled-color', nil, AClasses, APseudo);
        if (varVal <> '') and FtParseColor(varVal, col) then
        begin
          AStyle.HasTextColor := True;
          AStyle.TextColor := col;
        end
        else if rootNormalStyle.HasTextColor then
        begin
          AStyle.HasTextColor := True;
          AStyle.TextColor := rootNormalStyle.TextColor;
        end;
      end;
    end
    else
    begin
      if rootNormalStyle.HasTextColor then
      begin
        AStyle.HasTextColor := True;
        AStyle.TextColor := rootNormalStyle.TextColor;
      end
      else
      begin
        varVal := GetCustomVarValue('--text-color', nil, AClasses, APseudo);
        if varVal = '' then varVal := GetCustomVarValue('--color-text', nil, AClasses, APseudo);
        if (varVal <> '') and FtParseColor(varVal, col) then
        begin
          AStyle.HasTextColor := True;
          AStyle.TextColor := col;
        end;
      end;
    end;
  end;

  // 2. Border Color baseline (only for elements that specify a border width > 0)
  if (AStyle.HasBorderWidth and (AStyle.BorderWidth > 0.0)) and (not AStyle.HasBorderColor) then
  begin
    if isHover and rootStateStyle.HasBorderColor then
    begin
      AStyle.HasBorderColor := True;
      AStyle.BorderColor := rootStateStyle.BorderColor;
    end
    else if isDisabled and rootStateStyle.HasBorderColor then
    begin
      AStyle.HasBorderColor := True;
      AStyle.BorderColor := rootStateStyle.BorderColor;
    end
    else if rootNormalStyle.HasBorderColor then
    begin
      AStyle.HasBorderColor := True;
      AStyle.BorderColor := rootNormalStyle.BorderColor;
    end
    else
    begin
      varVal := GetCustomVarValue('--border-color', nil, AClasses, APseudo);
      if varVal = '' then varVal := GetCustomVarValue('--color-border', nil, AClasses, APseudo);
      if (varVal <> '') and FtParseColor(varVal, col) then
      begin
        AStyle.HasBorderColor := True;
        AStyle.BorderColor := col;
      end;
    end;
  end;

  // 3. Hover / Disabled Background Color baseline
  if not AStyle.HasBgColor then
  begin
    if isHover then
    begin
      if rootStateStyle.HasBgColor then
      begin
        AStyle.HasBgColor := True;
        AStyle.BgColor := rootStateStyle.BgColor;
      end
      else
      begin
        varVal := GetCustomVarValue('--hover-bg-color', nil, AClasses, APseudo);
        if varVal = '' then varVal := GetCustomVarValue('--color-hover-bg', nil, AClasses, APseudo);
        if (varVal <> '') and FtParseColor(varVal, col) then
        begin
          AStyle.HasBgColor := True;
          AStyle.BgColor := col;
        end;
      end;
    end
    else if isDisabled then
    begin
      if rootStateStyle.HasBgColor then
      begin
        AStyle.HasBgColor := True;
        AStyle.BgColor := rootStateStyle.BgColor;
      end
      else
      begin
        varVal := GetCustomVarValue('--disabled-bg-color', nil, AClasses, APseudo);
        if varVal = '' then varVal := GetCustomVarValue('--color-disabled-bg', nil, AClasses, APseudo);
        if (varVal <> '') and FtParseColor(varVal, col) then
        begin
          AStyle.HasBgColor := True;
          AStyle.BgColor := col;
        end;
      end;
    end;
  end;
end;

function TFtStyleSheet.ResolveStyle(const AElementType, AId, AClasses, APseudo: string; const AInlineCss: string): TFtWidgetStyle;
var
  adapter: ICSSElement;
  resolvedBlock: TCSSStyleBlock;
  inlineStyle: TFtWidgetStyle;
begin
  Result.Init();
  adapter := TFtCSSElementAdapter.Create(AElementType, AId, AClasses, APseudo);
  resolvedBlock := FResolver.ResolveStyle(adapter);
  try
    ApplyStyleBlock(resolvedBlock, Result, AClasses, APseudo);
  finally
    resolvedBlock.Free();
  end;

  if Trim(AInlineCss) <> '' then
  begin
    inlineStyle := ParseInlineStyle(AInlineCss, AClasses, APseudo);
    Result.Merge(inlineStyle);
  end;

  ApplyBaselineDefaults(Result, AElementType, AClasses, APseudo);
end;

function TFtStyleSheet.ParseInlineStyle(const AInlineCss: string; const AClasses: string; const APseudo: string): TFtWidgetStyle;
var
  block: TCSSStyleBlock;
begin
  Result.Init();
  if Trim(AInlineCss) = '' then Exit;

  try
    block := TCSSStyleBlock.FromCSS(AInlineCss, True);
    try
      ApplyStyleBlock(block, Result, AClasses, APseudo);
    finally
      block.Free();
    end;
  except
    // ignore parse errors in inline CSS
  end;
end;

function FtGetStyleSheet(): TFtStyleSheet;
begin
  if not Assigned(GStyleSheet) then
    GStyleSheet := TFtStyleSheet.Create();
  Result := GStyleSheet;
end;

function FtLoadStyleSheet(const APath: string): Boolean;
begin
  Result := FtGetStyleSheet().LoadFromFile(APath);
end;

function FtLoadStyleSheetString(const ACss: string): Boolean;
begin
  Result := FtGetStyleSheet().LoadFromString(ACss);
end;

finalization
  if Assigned(GStyleSheet) then
  begin
    GStyleSheet.Free();
    GStyleSheet := nil;
  end;

end.
