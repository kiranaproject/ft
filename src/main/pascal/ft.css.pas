unit Ft.Css;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, Classes, Math, fpcsstree, fpcssscanner, fpcssparser;

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

    HasTransition: Boolean;
    TransitionProp: string;
    TransitionDurationMs: Integer;
    TransitionTiming: string;

    procedure Init();
    procedure Merge(const Other: TFtWidgetStyle);
  end;

  { Parsed CSS rule item }
  TFtCssRule = record
    Specificity: Integer;
    Order: Integer;
    RuleElement: TCSSRuleElement;
  end;

type
  TFtStyleSheetChangeNotify = procedure() of object;

  { Stylesheet manager backed by fcl-css }
  TFtStyleSheet = class
  private
    FRoot: TCSSElement;
    FRules: array of TFtCssRule;
    FRuleCount: Integer;
    FOnChange: TFtStyleSheetChangeNotify;
    procedure RebuildRuleCache();
    function MatchSelector(Sel: TCSSElement; const AElementType, AId, AClasses, APseudo: string; out Spec: Integer): Boolean;
    function ApplyDeclarationToStyle(Decl: TCSSDeclarationElement; var Style: TFtWidgetStyle): Boolean;
  public
    constructor Create();
    destructor Destroy(); override;

    procedure Clear();
    function LoadFromFile(const APath: string): Boolean;
    function LoadFromString(const ACss: string): Boolean;

    function ResolveStyle(const AElementType, AId, AClasses, APseudo: string; const AInlineCss: string = ''): TFtWidgetStyle;
    function ParseInlineStyle(const AInlineCss: string): TFtWidgetStyle;

    property OnChange: TFtStyleSheetChangeNotify read FOnChange write FOnChange;
  end;

{ Helper functions }
function FtRgba(R, G, B: Double; A: Double = 1.0): TFtRgbaColor;
function FtParseColor(const S: string; out Col: TFtRgbaColor): Boolean;
function FtParseLength(const S: string; out Val: Double): Boolean;
function FtParseTimeMs(const S: string; out Ms: Integer): Boolean;
function FtParseTransition(const S: string; out Prop: string; out DurationMs: Integer; out Timing: string): Boolean;

{ Global default stylesheet }
function FtGetStyleSheet(): TFtStyleSheet;
function FtLoadStyleSheet(const APath: string): Boolean;
function FtLoadStyleSheetString(const ACss: string): Boolean;

implementation

var
  GStyleSheet: TFtStyleSheet = nil;

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
  clean: string;
  n1, n2, n3, n4, n5, n6, n7, n8: Integer;
  p1, p2: Integer;
  inside: string;
  parts: TStringList;
  v1, v2, v3, v4: Double;
begin
  Result := False;
  clean := LowerCase(Trim(S));
  if Length(clean) = 0 then Exit;

  // Named colors
  if clean = 'transparent' then
  begin
    Col := FtRgba(0.0, 0.0, 0.0, 0.0);
    Exit(True);
  end
  else if clean = 'black' then
  begin
    Col := FtRgba(0.0, 0.0, 0.0, 1.0);
    Exit(True);
  end
  else if clean = 'white' then
  begin
    Col := FtRgba(1.0, 1.0, 1.0, 1.0);
    Exit(True);
  end
  else if clean = 'red' then
  begin
    Col := FtRgba(0.9, 0.1, 0.1, 1.0);
    Exit(True);
  end
  else if clean = 'green' then
  begin
    Col := FtRgba(0.1, 0.7, 0.2, 1.0);
    Exit(True);
  end
  else if clean = 'blue' then
  begin
    Col := FtRgba(0.1, 0.4, 0.9, 1.0);
    Exit(True);
  end
  else if (clean = 'gray') or (clean = 'grey') then
  begin
    Col := FtRgba(0.5, 0.5, 0.5, 1.0);
    Exit(True);
  end
  else if (clean = 'lightgray') or (clean = 'lightgrey') then
  begin
    Col := FtRgba(0.8, 0.8, 0.8, 1.0);
    Exit(True);
  end
  else if (clean = 'darkgray') or (clean = 'darkgrey') then
  begin
    Col := FtRgba(0.25, 0.25, 0.25, 1.0);
    Exit(True);
  end;

  // Hex colors: #rgb, #rgba, #rrggbb, #rrggbbaa
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

  // rgb(...) or rgba(...)
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
  clean: string;
begin
  Result := False;
  clean := LowerCase(Trim(S));
  if Length(clean) = 0 then Exit;

  if (Length(clean) > 2) and (Copy(clean, Length(clean) - 1, 2) = 'px') then
    clean := Trim(Copy(clean, 1, Length(clean) - 2))
  else if (Length(clean) > 2) and (Copy(clean, Length(clean) - 1, 2) = 'pt') then
    clean := Trim(Copy(clean, 1, Length(clean) - 2));

  Val := StrToFloatDef(clean, -99999.0);
  if Val <> -99999.0 then
    Result := True;
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

{ TFtStyleSheet }

constructor TFtStyleSheet.Create();
begin
  inherited Create();
  FRoot := nil;
  SetLength(FRules, 0);
  FRuleCount := 0;
end;

destructor TFtStyleSheet.Destroy();
begin
  Clear();
  inherited Destroy();
end;

procedure TFtStyleSheet.Clear();
begin
  if Assigned(FRoot) then
  begin
    FRoot.Free();
    FRoot := nil;
  end;
  SetLength(FRules, 0);
  FRuleCount := 0;
end;

procedure TFtStyleSheet.RebuildRuleCache();
var
  i, j: Integer;
  children: TCSSChildrenElement;
  ruleEl: TCSSRuleElement;
  orderCounter: Integer;
begin
  SetLength(FRules, 0);
  FRuleCount := 0;
  if not Assigned(FRoot) or not (FRoot is TCSSChildrenElement) then Exit;

  children := TCSSChildrenElement(FRoot);
  orderCounter := 0;

  for i := 0 to children.ChildCount - 1 do
  begin
    if children.Children[i] is TCSSRuleElement then
    begin
      ruleEl := TCSSRuleElement(children.Children[i]);
      for j := 0 to ruleEl.SelectorCount - 1 do
      begin
        Inc(orderCounter);
        if FRuleCount = Length(FRules) then
          SetLength(FRules, Max(16, FRuleCount * 2));

        FRules[FRuleCount].Specificity := 0; // calculated during match
        FRules[FRuleCount].Order := orderCounter;
        FRules[FRuleCount].RuleElement := ruleEl;
        Inc(FRuleCount);
      end;
    end;
  end;
end;

function TFtStyleSheet.LoadFromFile(const APath: string): Boolean;
var
  fs: TFileStream;
  parser: TCSSParser;
begin
  Result := False;
  if not FileExists(APath) then Exit;

  Clear();
  try
    fs := TFileStream.Create(APath, fmOpenRead or fmShareDenyNone);
    try
      parser := TCSSParser.Create(fs);
      try
        FRoot := parser.Parse();
        RebuildRuleCache();
        Result := True;
        if Assigned(FOnChange) then
          FOnChange();
      finally
        parser.Free();
      end;
    finally
      fs.Free();
    end;
  except
    Clear();
    Result := False;
  end;
end;

function TFtStyleSheet.LoadFromString(const ACss: string): Boolean;
var
  ss: TStringStream;
  parser: TCSSParser;
begin
  Result := False;
  Clear();
  try
    ss := TStringStream.Create(ACss);
    try
      parser := TCSSParser.Create(ss);
      try
        FRoot := parser.Parse();
        RebuildRuleCache();
        Result := True;
        if Assigned(FOnChange) then
          FOnChange();
      finally
        parser.Free();
      end;
    finally
      ss.Free();
    end;
  except
    Clear();
    Result := False;
  end;
end;

function HasWord(const Text, Word: string): Boolean;
var
  list: TStringList;
  i: Integer;
begin
  Result := False;
  list := TStringList.Create();
  try
    list.Delimiter := ' ';
    list.DelimitedText := Text;
    for i := 0 to list.Count - 1 do
    begin
      if SameText(list[i], Word) then
        Exit(True);
    end;
  finally
    list.Free();
  end;
end;

function TFtStyleSheet.MatchSelector(Sel: TCSSElement; const AElementType, AId, AClasses, APseudo: string; out Spec: Integer): Boolean;
var
  list: TCSSListElement;
  sub: TCSSElement;
  i: Integer;
  partSpec: Integer;
  s: string;
begin
  Result := False;
  Spec := 0;

  if Sel is TCSSClassNameElement then
  begin
    s := Trim(Sel.AsString);
    if (Length(s) > 0) and (s[1] = '.') then Delete(s, 1, 1);
    if HasWord(AClasses, s) then
    begin
      Spec := 10;
      Exit(True);
    end;
  end
  else if Sel is TCSSHashIdentifierElement then
  begin
    s := Trim(Sel.AsString);
    if (Length(s) > 0) and (s[1] = '#') then Delete(s, 1, 1);
    if SameText(s, AId) then
    begin
      Spec := 100;
      Exit(True);
    end;
  end
  else if Sel is TCSSPseudoClassElement then
  begin
    s := LowerCase(Trim(Sel.AsString));
    if SameText(s, APseudo) then
    begin
      Spec := 10;
      Exit(True);
    end;
  end
  else if Sel is TCSSIdentifierElement then
  begin
    s := LowerCase(Trim(Sel.AsString));
    if (s = '*') or (s = LowerCase(AElementType)) then
    begin
      if s = '*' then Spec := 0 else Spec := 1;
      Exit(True);
    end;
  end
  else if Sel is TCSSListElement then
  begin
    list := TCSSListElement(Sel);
    partSpec := 0;
    for i := 0 to list.ChildCount - 1 do
    begin
      sub := list.Children[i];
      if sub is TCSSClassNameElement then
      begin
        s := Trim(sub.AsString);
        if (Length(s) > 0) and (s[1] = '.') then Delete(s, 1, 1);
        if not HasWord(AClasses, s) then Exit(False);
        Inc(partSpec, 10);
      end
      else if sub is TCSSHashIdentifierElement then
      begin
        s := Trim(sub.AsString);
        if (Length(s) > 0) and (s[1] = '#') then Delete(s, 1, 1);
        if not SameText(s, AId) then Exit(False);
        Inc(partSpec, 100);
      end
      else if sub is TCSSPseudoClassElement then
      begin
        s := LowerCase(Trim(sub.AsString));
        if not SameText(s, APseudo) then Exit(False);
        Inc(partSpec, 10);
      end
      else if sub is TCSSIdentifierElement then
      begin
        s := LowerCase(Trim(sub.AsString));
        if (s <> '*') and not SameText(s, AElementType) then Exit(False);
        if s <> '*' then Inc(partSpec, 1);
      end;
    end;
    Spec := partSpec;
    Exit(True);
  end;
end;

function TFtStyleSheet.ApplyDeclarationToStyle(Decl: TCSSDeclarationElement; var Style: TFtWidgetStyle): Boolean;
var
  key, valStr: string;
  col: TFtRgbaColor;
  lenVal: Double;
  parts: TStringList;
  i: Integer;
begin
  Result := False;
  if (Decl.KeyCount = 0) or (Decl.ChildCount = 0) then Exit;

  key := LowerCase(Trim(Decl.Keys[0].AsString));
  valStr := Trim(Decl.Children[0].AsString);

  if (key = 'background-color') or (key = 'background') then
  begin
    if FtParseColor(valStr, col) then
    begin
      Style.HasBgColor := True;
      Style.BgColor := col;
      Result := True;
    end;
  end
  else if key = 'color' then
  begin
    if FtParseColor(valStr, col) then
    begin
      Style.HasTextColor := True;
      Style.TextColor := col;
      Result := True;
    end;
  end
  else if key = 'border-color' then
  begin
    if FtParseColor(valStr, col) then
    begin
      Style.HasBorderColor := True;
      Style.BorderColor := col;
      Result := True;
    end;
  end
  else if key = 'border-width' then
  begin
    if FtParseLength(valStr, lenVal) then
    begin
      Style.HasBorderWidth := True;
      Style.BorderWidth := lenVal;
      Result := True;
    end;
  end
  else if (key = 'border-radius') or (key = 'border-top-left-radius') then
  begin
    if FtParseLength(valStr, lenVal) then
    begin
      Style.HasBorderRadius := True;
      Style.BorderRadius := lenVal;
      Result := True;
    end;
  end
  else if (key = 'box-shadow') or (key = 'shadow') then
  begin
    if (valStr = 'none') or (valStr = '0') or (valStr = 'false') then
    begin
      Style.HasShadow := True;
      Style.EnableShadow := False;
      Result := True;
    end
    else
    begin
      Style.HasShadow := True;
      Style.EnableShadow := True;
      Result := True;
    end;
  end
  else if key = 'font-size' then
  begin
    if FtParseLength(valStr, lenVal) then
    begin
      Style.HasFontSize := True;
      Style.FontSize := lenVal;
      Result := True;
    end;
  end
  else if key = 'font-weight' then
  begin
    Style.HasFontWeight := True;
    Style.FontBold := (valStr = 'bold') or (valStr = '700') or (valStr = '800') or (valStr = '900');
    Result := True;
  end
  else if key = 'transition' then
  begin
    valStr := '';
    for i := 0 to Decl.ChildCount - 1 do
    begin
      if valStr <> '' then valStr := valStr + ', ';
      valStr := valStr + Decl.Children[i].AsString;
    end;
    if FtParseTransition(valStr, Style.TransitionProp, Style.TransitionDurationMs, Style.TransitionTiming) then
    begin
      Style.HasTransition := True;
      Result := True;
    end;
  end
  else if key = 'transition-duration' then
  begin
    if FtParseTimeMs(valStr, Style.TransitionDurationMs) then
    begin
      Style.HasTransition := True;
      Result := True;
    end;
  end
  else if key = 'transition-property' then
  begin
    valStr := '';
    for i := 0 to Decl.ChildCount - 1 do
    begin
      if valStr <> '' then valStr := valStr + ', ';
      valStr := valStr + Decl.Children[i].AsString;
    end;
    Style.HasTransition := True;
    Style.TransitionProp := LowerCase(Trim(valStr));
    Result := True;
  end
  else if key = 'transition-timing-function' then
  begin
    Style.HasTransition := True;
    Style.TransitionTiming := LowerCase(Trim(valStr));
    Result := True;
  end;
end;

function TFtStyleSheet.ParseInlineStyle(const AInlineCss: string): TFtWidgetStyle;
var
  ss: TStringStream;
  parser: TCSSParser;
  rootEl: TCSSElement;
  decl: TCSSDeclarationElement;
  i: Integer;
begin
  Result.Init();
  if Trim(AInlineCss) = '' then Exit;

  try
    ss := TStringStream.Create(AInlineCss);
    try
      parser := TCSSParser.Create(ss);
      try
        rootEl := parser.ParseInline();
        try
          if Assigned(rootEl) and (rootEl is TCSSChildrenElement) then
          begin
            for i := 0 to (rootEl as TCSSChildrenElement).ChildCount - 1 do
            begin
              if (rootEl as TCSSChildrenElement).Children[i] is TCSSDeclarationElement then
              begin
                decl := TCSSDeclarationElement((rootEl as TCSSChildrenElement).Children[i]);
                ApplyDeclarationToStyle(decl, Result);
              end;
            end;
          end;
        finally
          if Assigned(rootEl) then rootEl.Free();
        end;
      finally
        parser.Free();
      end;
    finally
      ss.Free();
    end;
  except
    // ignore parse errors in inline CSS
  end;
end;

type
  TMatchEntry = record
    Specificity: Integer;
    Order: Integer;
    RuleEl: TCSSRuleElement;
  end;

function TFtStyleSheet.ResolveStyle(const AElementType, AId, AClasses, APseudo: string; const AInlineCss: string): TFtWidgetStyle;
var
  i, j, k: Integer;
  matches: array of TMatchEntry;
  matchCount: Integer;
  spec: Integer;
  ruleEl: TCSSRuleElement;
  matched: Boolean;
  decl: TCSSDeclarationElement;
  temp: TMatchEntry;
  inlineStyle: TFtWidgetStyle;
begin
  Result.Init();
  SetLength(matches, 0);
  matchCount := 0;

  if Assigned(FRoot) and (FRoot is TCSSChildrenElement) then
  begin
    for i := 0 to (FRoot as TCSSChildrenElement).ChildCount - 1 do
    begin
      if (FRoot as TCSSChildrenElement).Children[i] is TCSSRuleElement then
      begin
        ruleEl := TCSSRuleElement((FRoot as TCSSChildrenElement).Children[i]);
        matched := False;
        spec := 0;

        for j := 0 to ruleEl.SelectorCount - 1 do
        begin
          if MatchSelector(ruleEl.Selectors[j], AElementType, AId, AClasses, APseudo, spec) then
          begin
            matched := True;
            Break;
          end;
        end;

        if matched then
        begin
          if matchCount = Length(matches) then
            SetLength(matches, Max(8, matchCount * 2));
          matches[matchCount].Specificity := spec;
          matches[matchCount].Order := i;
          matches[matchCount].RuleEl := ruleEl;
          Inc(matchCount);
        end;
      end;
    end;
  end;

  // Sort matching rules by specificity, then order (cascade precedence)
  for i := 0 to matchCount - 2 do
    for j := i + 1 to matchCount - 1 do
    begin
      if (matches[i].Specificity > matches[j].Specificity) or
         ((matches[i].Specificity = matches[j].Specificity) and (matches[i].Order > matches[j].Order)) then
      begin
        temp := matches[i];
        matches[i] := matches[j];
        matches[j] := temp;
      end;
    end;

  // Apply matched rules in cascade order
  for i := 0 to matchCount - 1 do
  begin
    ruleEl := matches[i].RuleEl;
    for k := 0 to ruleEl.ChildCount - 1 do
    begin
      if ruleEl.Children[k] is TCSSDeclarationElement then
      begin
        decl := TCSSDeclarationElement(ruleEl.Children[k]);
        ApplyDeclarationToStyle(decl, Result);
      end;
    end;
  end;

  // Finally apply inline style (highest specificity: 1000)
  if Trim(AInlineCss) <> '' then
  begin
    inlineStyle := ParseInlineStyle(AInlineCss);
    Result.Merge(inlineStyle);
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
