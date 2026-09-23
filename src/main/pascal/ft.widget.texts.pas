unit Ft.Widget.Texts;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Math,
  Ft.Canvas.Agg, Ft.Widget, Ft.Font, Ft.Theme, Ft.Backend.X11, Ft.Widget.Menus, Ft.Css;

type
  TFtTextAlignment = (taLeft, taCenter, taRight);
  TFtTextChangeNotify = procedure(Sender: Pointer; UserData: Pointer); cdecl;

  TFtTextLine = record
    StartChar: Integer;   { 0-based character index in FText }
    CharLen: Integer;     { Number of Unicode characters in this line }
    Text: string;         { UTF-8 string content of this line }
    LineWidth: Double;    { Measured width of visible text (excluding trailing wrap spaces) }
    Y: Double;            { Baseline Y coordinate }
  end;
  TFtTextLineArray = array of TFtTextLine;

  TFtText = class(TFtWidget)
  private
    FText: string;
    FSelectable: Boolean;
    FAlignment: TFtTextAlignment;
    FWordWrap: Boolean;
    FCustomColor: Boolean;
    FTextColor: TFtRgbColor;

    FSelAnchor: Integer;   { 0-based character index where mouse was pressed }
    FSelCursor: Integer;   { 0-based character index where cursor currently is }
    FIsDragging: Boolean;
    FLastClickTime: QWord;
    FClickCount: Integer;

    FDefaultMenu: TFtPopupMenu;
    FItemSelectAll: TFtMenuItem;
    FItemCut: TFtMenuItem;
    FItemCopy: TFtMenuItem;
    FItemPaste: TFtMenuItem;
    FItemDelete: TFtMenuItem;

    FOnChange: TFtTextChangeNotify;
    FUserData: Pointer;

    procedure SetText(const AValue: string);
    procedure SetSelectable(AValue: Boolean);
    procedure SetAlignment(AValue: TFtTextAlignment);
    procedure SetWordWrap(AValue: Boolean);
    function GetSelectedText(): string;
    procedure SelectWordAt(ACharIdx: Integer);
    procedure CreateDefaultMenu();
    procedure UpdateDefaultMenu();
  protected
    function GetContextMenu(): TFtWidget; override;
  public
    constructor Create(AParent: TFtWidget; const AText: string = ''); reintroduce;
    destructor Destroy(); override;

    function CharCount(): Integer;
    function CharByteOffset(ACharIdx: Integer): Integer;
    function SubStrChars(ACharStart, ACharLen: Integer): string;
    function HasSelection(): Boolean;
    function BuildLines(AFont: TFtFont; AAvailWidth: Double): TFtTextLineArray;
    function HitTestChar(AX, AY: Integer): Integer; overload;
    function HitTestChar(AX: Integer): Integer; overload;
    function GetElementType(): string; override;
    function GetEffectiveHint(): string; override;

    procedure Draw(Canvas: TFtCanvasAgg); override;
    procedure MouseDown(AX, AY: Integer; AButton: Integer); override;
    procedure MouseUp(AX, AY: Integer; AButton: Integer); override;
    procedure MouseMove(AX, AY: Integer); override;
    procedure KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string); override;
    function GetCursor(): Integer; override;

    procedure SelectAll();
    procedure ClearSelection();
    procedure CopyToClipboard();
    procedure SetColor(R, G, B: Double);
    procedure ResetColor();

    property Text: string read FText write SetText;
    property Selectable: Boolean read FSelectable write SetSelectable;
    property Alignment: TFtTextAlignment read FAlignment write SetAlignment;
    property WordWrap: Boolean read FWordWrap write SetWordWrap;
    property Wrap: Boolean read FWordWrap write SetWordWrap;
    property SelectedText: string read GetSelectedText;
    property SelStart: Integer read FSelAnchor;
    property SelCursor: Integer read FSelCursor;
    property CustomColor: Boolean read FCustomColor;
    property TextColor: TFtRgbColor read FTextColor;
    property OnChange: TFtTextChangeNotify read FOnChange write FOnChange;
    property UserData: Pointer read FUserData write FUserData;
  end;

  TFtLabel = TFtText;

implementation

var
  gActiveSelectedTextWidget: TFtText = nil;

procedure FtClearActiveTextSelection();
begin
  if Assigned(gActiveSelectedTextWidget) then
  begin
    gActiveSelectedTextWidget.ClearSelection();
    gActiveSelectedTextWidget := nil;
  end;
end;

procedure TextMenuSelectAllCallback(MenuItem: Pointer; UserData: Pointer); cdecl;
begin
  if Assigned(UserData) and (TObject(UserData) is TFtText) then
    TFtText(UserData).SelectAll();
end;

procedure TextMenuCopyCallback(MenuItem: Pointer; UserData: Pointer); cdecl;
begin
  if Assigned(UserData) and (TObject(UserData) is TFtText) then
    TFtText(UserData).CopyToClipboard();
end;

type
  TFtTokenKind = (tkWord, tkSpace, tkNewline);
  TFtTextToken = record
    Kind: TFtTokenKind;
    StartChar: Integer;
    CharLen: Integer;
    Text: string;
  end;
  TFtTextTokenArray = array of TFtTextToken;

function IsCJK(code: Cardinal): Boolean;
begin
  Result := ((code >= $2E80) and (code <= $9FFF)) or  { CJK Radicals, Ideographs }
            ((code >= $AC00) and (code <= $D7AF)) or  { Hangul Syllables }
            ((code >= $F900) and (code <= $FAFF)) or  { CJK Compatibility }
            ((code >= $FF00) and (code <= $FFEF)) or  { Fullwidth Forms }
            ((code >= $3000) and (code <= $303F)) or  { CJK Symbols and Punctuation }
            ((code >= $3040) and (code <= $309F)) or  { Hiragana }
            ((code >= $30A0) and (code <= $30FF));    { Katakana }
end;

function TokenizeText(const S: string): TFtTextTokenArray;
var
  p, pTokenStart: PChar;
  chCode: Cardinal;
  chLen: LongInt;
  charIdx, tokenCharStart, tokenCharLen: Integer;
  tokCount: Integer;
  tokStr: string;

  procedure AddToken(AKind: TFtTokenKind; AStartChar, ACharLen: Integer; const AText: string);
  begin
    if Length(Result) <= tokCount then
      SetLength(Result, (tokCount + 1) * 2);
    Result[tokCount].Kind := AKind;
    Result[tokCount].StartChar := AStartChar;
    Result[tokCount].CharLen := ACharLen;
    Result[tokCount].Text := AText;
    Inc(tokCount);
  end;

begin
  Result := nil;
  tokCount := 0;
  if S = '' then Exit;
  p := PChar(S);
  charIdx := 0;
  while p^ <> #0 do
  begin
    chCode := UTF8CharToUnicode(p, chLen);
    tokenCharStart := charIdx;
    pTokenStart := p;

    if (chCode = 13) or (chCode = 10) then
    begin
      if (chCode = 13) and ((p + chLen)^ = #10) then
      begin
        AddToken(tkNewline, tokenCharStart, 2, #13#10);
        Inc(p, chLen + 1);
        Inc(charIdx, 2);
      end
      else
      begin
        if chCode = 13 then
          AddToken(tkNewline, tokenCharStart, 1, #13)
        else
          AddToken(tkNewline, tokenCharStart, 1, #10);
        Inc(p, chLen);
        Inc(charIdx, 1);
      end;
    end
    else if (chCode = 32) or (chCode = 9) then
    begin
      tokenCharLen := 0;
      while (p^ <> #0) do
      begin
        chCode := UTF8CharToUnicode(p, chLen);
        if (chCode <> 32) and (chCode <> 9) then Break;
        Inc(p, chLen);
        Inc(charIdx);
        Inc(tokenCharLen);
      end;
      SetString(tokStr, pTokenStart, p - pTokenStart);
      AddToken(tkSpace, tokenCharStart, tokenCharLen, tokStr);
    end
    else if IsCJK(chCode) then
    begin
      SetString(tokStr, p, chLen);
      AddToken(tkWord, tokenCharStart, 1, tokStr);
      Inc(p, chLen);
      Inc(charIdx);
    end
    else
    begin
      tokenCharLen := 0;
      while (p^ <> #0) do
      begin
        chCode := UTF8CharToUnicode(p, chLen);
        if (chCode = 13) or (chCode = 10) or (chCode = 32) or (chCode = 9) or IsCJK(chCode) then
          Break;
        Inc(p, chLen);
        Inc(charIdx);
        Inc(tokenCharLen);
      end;
      SetString(tokStr, pTokenStart, p - pTokenStart);
      AddToken(tkWord, tokenCharStart, tokenCharLen, tokStr);
    end;
  end;
  SetLength(Result, tokCount);
end;

{ TFtText }

constructor TFtText.Create(AParent: TFtWidget; const AText: string = '');
begin
  inherited Create(AParent);
  FText := AText;
  FSelectable := True; { Selectable by default }
  FAlignment := taLeft;
  FWordWrap := False;
  FCustomColor := False;
  FTextColor := MakeRgbColor(0.0, 0.0, 0.0);

  FSelAnchor := 0;
  FSelCursor := 0;
  FIsDragging := False;
  FLastClickTime := 0;
  FClickCount := 0;

  FDefaultMenu := nil;
  FItemSelectAll := nil;
  FItemCut := nil;
  FItemCopy := nil;
  FItemPaste := nil;
  FItemDelete := nil;

  FOnChange := nil;
  FUserData := nil;

  Width := 160;
  Height := 28;
  FFocusable := FSelectable;
end;

destructor TFtText.Destroy();
begin
  if Assigned(FDefaultMenu) then
  begin
    FDefaultMenu.Free();
    FDefaultMenu := nil;
  end;
  if gActiveSelectedTextWidget = Self then
  begin
    gActiveSelectedTextWidget := nil;
    FtClearPrimarySelection();
  end;
  inherited Destroy();
end;

procedure TFtText.SetText(const AValue: string);
begin
  if FText <> AValue then
  begin
    FText := AValue;
    ClearSelection();
    Invalidate();
    if Assigned(FOnChange) then
      FOnChange(Self, FUserData);
  end;
end;

procedure TFtText.SetSelectable(AValue: Boolean);
begin
  if FSelectable <> AValue then
  begin
    FSelectable := AValue;
    FFocusable := AValue;
    if not FSelectable then
    begin
      ClearSelection();
      if FFocused then
        KillFocus();
    end;
    Invalidate();
  end;
end;

procedure TFtText.SetAlignment(AValue: TFtTextAlignment);
begin
  if FAlignment <> AValue then
  begin
    FAlignment := AValue;
    Invalidate();
  end;
end;

procedure TFtText.SetWordWrap(AValue: Boolean);
begin
  if FWordWrap <> AValue then
  begin
    FWordWrap := AValue;
    Invalidate();
  end;
end;

procedure TFtText.SetColor(R, G, B: Double);
begin
  FCustomColor := True;
  FTextColor := MakeRgbColor(R, G, B);
  Invalidate();
end;

procedure TFtText.ResetColor();
begin
  if FCustomColor then
  begin
    FCustomColor := False;
    Invalidate();
  end;
end;

function TFtText.CharCount(): Integer;
var
  p: PChar;
  charLen: LongInt;
begin
  Result := 0;
  p := PChar(FText);
  while p^ <> #0 do
  begin
    UTF8CharToUnicode(p, charLen);
    Inc(p, charLen);
    Inc(Result);
  end;
end;

function TFtText.CharByteOffset(ACharIdx: Integer): Integer;
var
  p: PChar;
  charLen: LongInt;
  idx: Integer;
begin
  if ACharIdx <= 0 then Exit(1);
  idx := 0;
  p := PChar(FText);
  while (p^ <> #0) and (idx < ACharIdx) do
  begin
    UTF8CharToUnicode(p, charLen);
    Inc(p, charLen);
    Inc(idx);
  end;
  Result := (p - PChar(FText)) + 1;
end;

function TFtText.SubStrChars(ACharStart, ACharLen: Integer): string;
var
  bStart, bEnd: Integer;
begin
  if (ACharLen <= 0) or (ACharStart >= CharCount()) then Exit('');
  bStart := CharByteOffset(ACharStart);
  bEnd := CharByteOffset(ACharStart + ACharLen);
  Result := Copy(FText, bStart, bEnd - bStart);
end;

function TFtText.HasSelection(): Boolean;
begin
  Result := (FSelAnchor <> FSelCursor);
end;

function TFtText.GetSelectedText(): string;
var
  sMin, sMax: Integer;
begin
  if not HasSelection() then Exit('');
  sMin := Min(FSelAnchor, FSelCursor);
  sMax := Max(FSelAnchor, FSelCursor);
  Result := SubStrChars(sMin, sMax - sMin);
end;

function TFtText.BuildLines(AFont: TFtFont; AAvailWidth: Double): TFtTextLineArray;
var
  availW: Double;
  tokens: TFtTextTokenArray;
  tokIdx: Integer;
  curStartChar, curCharLen: Integer;
  curText: string;
  testW: Double;
  lineCount: Integer;
  lineHeight: Double;
  i: Integer;

  procedure PushLine();
  var
    visText: string;
  begin
    if Length(Result) <= lineCount then
      SetLength(Result, (lineCount + 1) * 2);
    Result[lineCount].StartChar := curStartChar;
    Result[lineCount].CharLen := curCharLen;
    Result[lineCount].Text := curText;
    visText := TrimRight(curText);
    if visText <> '' then
      Result[lineCount].LineWidth := AFont.GetTextWidth(visText)
    else
      Result[lineCount].LineWidth := 0.0;
    Result[lineCount].Y := 0.0;
    Inc(lineCount);
    curStartChar := curStartChar + curCharLen;
    curCharLen := 0;
    curText := '';
  end;

  procedure BreakWordAcrossLines(const ATok: TFtTextToken);
  var
    p: PChar;
    chLen: LongInt;
    chStr: string;
    testW: Double;
  begin
    p := PChar(ATok.Text);
    while p^ <> #0 do
    begin
      UTF8CharToUnicode(p, chLen);
      SetString(chStr, p, chLen);
      testW := AFont.GetTextWidth(TrimRight(curText + chStr));
      if (curCharLen > 0) and (testW > availW) then
      begin
        PushLine();
      end;
      curText := curText + chStr;
      Inc(curCharLen);
      Inc(p, chLen);
    end;
  end;

begin
  Result := nil;
  if FText = '' then Exit;
  if not Assigned(AFont) then
  begin
    AFont := GetFont();
    if not Assigned(AFont) then AFont := FtGetSystemFont();
  end;

  if not FWordWrap then
  begin
    SetLength(Result, 1);
    Result[0].StartChar := 0;
    Result[0].CharLen := CharCount();
    Result[0].Text := FText;
    Result[0].LineWidth := AFont.GetTextWidth(FText);
    Result[0].Y := Y + (Height / 2.0) + (AFont.Ascent - AFont.Descent) / 2.0;
    Exit;
  end;

  availW := AAvailWidth;
  if availW < 1.0 then availW := 1.0;

  tokens := TokenizeText(FText);
  if Length(tokens) = 0 then Exit;

  lineCount := 0;
  curStartChar := 0;
  curCharLen := 0;
  curText := '';
  tokIdx := 0;

  while tokIdx < Length(tokens) do
  begin
    case tokens[tokIdx].Kind of
      tkNewline:
        begin
          curCharLen := curCharLen + tokens[tokIdx].CharLen;
          PushLine();
          Inc(tokIdx);
        end;

      tkSpace:
        begin
          if curCharLen > 0 then
          begin
            curText := curText + tokens[tokIdx].Text;
            curCharLen := curCharLen + tokens[tokIdx].CharLen;
            Inc(tokIdx);
          end
          else
          begin
            testW := AFont.GetTextWidth(TrimRight(tokens[tokIdx].Text));
            if testW <= availW then
            begin
              curText := tokens[tokIdx].Text;
              curCharLen := tokens[tokIdx].CharLen;
              Inc(tokIdx);
            end
            else
            begin
              BreakWordAcrossLines(tokens[tokIdx]);
              Inc(tokIdx);
            end;
          end;
        end;

      tkWord:
        begin
          testW := AFont.GetTextWidth(TrimRight(curText + tokens[tokIdx].Text));
          if testW <= availW then
          begin
            curText := curText + tokens[tokIdx].Text;
            curCharLen := curCharLen + tokens[tokIdx].CharLen;
            Inc(tokIdx);
          end
          else if curCharLen > 0 then
          begin
            PushLine();
          end
          else
          begin
            BreakWordAcrossLines(tokens[tokIdx]);
            Inc(tokIdx);
          end;
        end;
    end;
  end;

  if curCharLen > 0 then
    PushLine();

  SetLength(Result, lineCount);
  if lineCount > 0 then
  begin
    lineHeight := AFont.Height;
    if lineHeight < (AFont.Ascent + AFont.Descent) then
      lineHeight := AFont.Ascent + AFont.Descent + 2.0;

    if (lineCount = 1) and (Height <= lineHeight + 8.0) then
      Result[0].Y := Y + (Height / 2.0) + (AFont.Ascent - AFont.Descent) / 2.0
    else
      for i := 0 to lineCount - 1 do
        Result[i].Y := Y + 2.0 + AFont.Ascent + i * lineHeight;
  end;
end;

function TFtText.HitTestChar(AX, AY: Integer): Integer;
var
  AFont: TFtFont;
  lines: TFtTextLineArray;
  targetLine, i, c: Integer;
  lineTop, lineBottom, lineTX: Double;
  wPrev, wNext, midX: Double;
  cnt: Integer;
begin
  cnt := CharCount();
  if cnt = 0 then Exit(0);
  AFont := GetFont();
  if not Assigned(AFont) then AFont := FtGetSystemFont();

  lines := BuildLines(AFont, Width - 4.0);
  if Length(lines) = 0 then Exit(0);

  if AY < (lines[0].Y - AFont.Ascent) then
    targetLine := 0
  else if AY >= (lines[High(lines)].Y + AFont.Descent) then
    targetLine := High(lines)
  else
  begin
    targetLine := High(lines);
    for i := 0 to High(lines) do
    begin
      if i = 0 then
        lineTop := -1e9
      else
        lineTop := (lines[i - 1].Y + lines[i].Y) / 2.0;

      if i = High(lines) then
        lineBottom := 1e9
      else
        lineBottom := (lines[i].Y + lines[i + 1].Y) / 2.0;

      if (AY >= lineTop) and (AY < lineBottom) then
      begin
        targetLine := i;
        Break;
      end;
    end;
  end;

  case FAlignment of
    taCenter: lineTX := X + (Width - lines[targetLine].LineWidth) / 2.0;
    taRight:  lineTX := X + Width - lines[targetLine].LineWidth - 2.0;
    else      lineTX := X + 2.0;
  end;

  if AX <= lineTX then
    Exit(lines[targetLine].StartChar);

  if AX >= (lineTX + lines[targetLine].LineWidth) then
    Exit(lines[targetLine].StartChar + lines[targetLine].CharLen);

  wPrev := 0.0;
  for c := 0 to lines[targetLine].CharLen - 1 do
  begin
    wNext := AFont.GetTextWidth(SubStrChars(lines[targetLine].StartChar, c + 1));
    midX := lineTX + (wPrev + wNext) / 2.0;
    if AX < midX then
      Exit(lines[targetLine].StartChar + c);
    wPrev := wNext;
  end;

  Result := lines[targetLine].StartChar + lines[targetLine].CharLen;
end;

function TFtText.HitTestChar(AX: Integer): Integer;
begin
  Result := HitTestChar(AX, Round(Y + Height / 2.0));
end;

procedure TFtText.SelectWordAt(ACharIdx: Integer);
var
  cnt, wStart, wEnd: Integer;
  ch: string;

  function IsWordChar(const S: string): Boolean;
  begin
    if Length(S) = 1 then
      Result := (S[1] in ['a'..'z', 'A'..'Z', '0'..'9', '_'])
    else
      Result := (Length(S) > 1);
  end;

begin
  cnt := CharCount();
  if cnt = 0 then Exit;
  if not FSelectable then Exit;
  if ACharIdx >= cnt then ACharIdx := cnt - 1;
  if ACharIdx < 0 then ACharIdx := 0;

  if (gActiveSelectedTextWidget <> nil) and (gActiveSelectedTextWidget <> Self) then
    gActiveSelectedTextWidget.ClearSelection();
  gActiveSelectedTextWidget := Self;

  wStart := ACharIdx;
  wEnd := ACharIdx + 1;

  ch := SubStrChars(ACharIdx, 1);
  if IsWordChar(ch) then
  begin
    while (wStart > 0) and IsWordChar(SubStrChars(wStart - 1, 1)) do
      Dec(wStart);
    while (wEnd < cnt) and IsWordChar(SubStrChars(wEnd, 1)) do
      Inc(wEnd);
  end
  else
  begin
    while (wStart > 0) and not IsWordChar(SubStrChars(wStart - 1, 1)) and (SubStrChars(wStart - 1, 1) <> ' ') do
      Dec(wStart);
    while (wEnd < cnt) and not IsWordChar(SubStrChars(wEnd, 1)) and (SubStrChars(wEnd, 1) <> ' ') do
      Inc(wEnd);
  end;

  FSelAnchor := wStart;
  FSelCursor := wEnd;
  Invalidate();
  if HasSelection() then
    FtClaimPrimarySelection(GetSelectedText());
end;

procedure TFtText.SelectAll();
begin
  if not FSelectable then Exit;
  if (gActiveSelectedTextWidget <> nil) and (gActiveSelectedTextWidget <> Self) then
    gActiveSelectedTextWidget.ClearSelection();
  gActiveSelectedTextWidget := Self;

  FSelAnchor := 0;
  FSelCursor := CharCount();
  Invalidate();
  if HasSelection() then
    FtClaimPrimarySelection(GetSelectedText());
end;

procedure TFtText.ClearSelection();
begin
  if (FSelAnchor <> 0) or (FSelCursor <> 0) then
  begin
    FSelAnchor := 0;
    FSelCursor := 0;
    Invalidate();
  end;
  if gActiveSelectedTextWidget = Self then
    gActiveSelectedTextWidget := nil;
end;

procedure TFtText.CopyToClipboard();
var
  sel: string;
begin
  if not FSelectable then Exit;
  sel := GetSelectedText();
  if sel <> '' then
    FtSetClipboardText(sel);
end;

procedure TFtText.CreateDefaultMenu();
begin
  if Assigned(FDefaultMenu) then Exit;
  FDefaultMenu := TFtPopupMenu.Create(Self);
  FItemSelectAll := FDefaultMenu.AddItem('Select All', @TextMenuSelectAllCallback, Pointer(Self));
  FItemSelectAll.Shortcut := 'Ctrl+A';
  FDefaultMenu.AddSeparator();
  FItemCut := FDefaultMenu.AddItem('Cut', nil, nil);
  FItemCut.Shortcut := 'Ctrl+X';
  FItemCopy := FDefaultMenu.AddItem('Copy', @TextMenuCopyCallback, Pointer(Self));
  FItemCopy.Shortcut := 'Ctrl+C';
  FItemPaste := FDefaultMenu.AddItem('Paste', nil, nil);
  FItemPaste.Shortcut := 'Ctrl+V';
  FItemDelete := FDefaultMenu.AddItem('Delete', nil, nil);
  FItemDelete.Shortcut := 'Del';
end;

procedure TFtText.UpdateDefaultMenu();
begin
  if not Assigned(FDefaultMenu) then Exit;
  FItemSelectAll.Enabled := (CharCount() > 0);
  FItemCut.Enabled := False;
  FItemCopy.Enabled := HasSelection();
  FItemPaste.Enabled := False;
  FItemDelete.Enabled := False;
end;

function TFtText.GetContextMenu(): TFtWidget;
begin
  if Assigned(FContextMenu) then
    Exit(FContextMenu);
  if not FSelectable then
    Exit(nil);
  if not Assigned(FDefaultMenu) then
    CreateDefaultMenu();
  UpdateDefaultMenu();
  Result := FDefaultMenu;
end;

procedure TFtText.MouseDown(AX, AY: Integer; AButton: Integer);
var
  nowTime: QWord;
  clickChar, sMin, sMax: Integer;
begin
  inherited MouseDown(AX, AY, AButton);
  if not FSelectable then
  begin
    if Assigned(gActiveSelectedTextWidget) then
    begin
      FtClearActiveTextSelection();
      FtClearPrimarySelection();
    end;
    Exit;
  end;

  if AButton = 3 then
  begin
    if HasSelection() then
    begin
      clickChar := HitTestChar(AX, AY);
      sMin := Math.Min(FSelAnchor, FSelCursor);
      sMax := Math.Max(FSelAnchor, FSelCursor);
      if (clickChar < sMin) or (clickChar > sMax) then
      begin
        ClearSelection();
        FtClearPrimarySelection();
      end;
    end;
    Exit;
  end;

  if AButton <> 1 then Exit;

  if (gActiveSelectedTextWidget <> nil) and (gActiveSelectedTextWidget <> Self) then
  begin
    gActiveSelectedTextWidget.ClearSelection();
  end;
  gActiveSelectedTextWidget := Self;

  nowTime := GetTickCount64();
  if (nowTime - FLastClickTime) < 400 then
    Inc(FClickCount)
  else
    FClickCount := 1;
  FLastClickTime := nowTime;

  if FClickCount = 1 then
  begin
    FSelAnchor := HitTestChar(AX, AY);
    FSelCursor := FSelAnchor;
    FIsDragging := True;
    Invalidate();
  end
  else if FClickCount = 2 then
  begin
    SelectWordAt(HitTestChar(AX, AY));
    FIsDragging := False;
  end
  else if FClickCount >= 3 then
  begin
    SelectAll();
    FIsDragging := False;
  end;
end;

procedure TFtText.MouseMove(AX, AY: Integer);
var
  newPos: Integer;
begin
  inherited MouseMove(AX, AY);
  if not FSelectable or not FIsDragging then Exit;

  newPos := HitTestChar(AX, AY);
  if newPos <> FSelCursor then
  begin
    FSelCursor := newPos;
    Invalidate();
    if HasSelection() then
    begin
      gActiveSelectedTextWidget := Self;
      FtClaimPrimarySelection(GetSelectedText());
    end;
  end;
end;

procedure TFtText.MouseUp(AX, AY: Integer; AButton: Integer);
begin
  inherited MouseUp(AX, AY, AButton);
  if not FSelectable or (AButton <> 1) then Exit;
  if FIsDragging then
  begin
    FIsDragging := False;
    if HasSelection() then
    begin
      gActiveSelectedTextWidget := Self;
      FtClaimPrimarySelection(GetSelectedText());
    end
    else
    begin
      ClearSelection();
      FtClearPrimarySelection();
    end;
  end;
end;

procedure TFtText.KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string);
const
  ControlMask = 4;
begin
  inherited KeyDown(AKeySym, AState, AChar);
  if not FSelectable then Exit;

  // Ctrl+C (Keysym $63 / $43)
  if ((AState and ControlMask) <> 0) and ((AKeySym = $63) or (AKeySym = $43)) then
  begin
    CopyToClipboard();
  end
  // Ctrl+A (Keysym $61 / $41)
  else if ((AState and ControlMask) <> 0) and ((AKeySym = $61) or (AKeySym = $41)) then
  begin
    SelectAll();
  end
  // Escape ($FF1B): Clear selection
  else if AKeySym = $FF1B then
  begin
    ClearSelection();
  end;
end;

function TFtText.GetCursor(): Integer;
begin
  if FSelectable then
    Result := 1 { I-beam }
  else
    Result := 0; { Default pointer }
end;

function TFtText.GetElementType(): string;
begin
  Result := 'label';
end;

function TFtText.GetEffectiveHint(): string;
var
  f: TFtFont;
  lines: TFtTextLineArray;
  lineHeight, totalH: Double;
  i: Integer;
begin
  if not FShowHint or not Visible then Exit('');
  if FHint <> '' then Exit(FHint);
  if FText = '' then Exit('');
  f := GetFont();
  if not Assigned(f) then f := FtGetSystemFont();
  if not Assigned(f) or (Width <= 0) or (Height <= 0) then Exit('');

  if not FWordWrap then
  begin
    if f.GetTextWidth(FText) > (Width - 4.0) then
      Result := FText
    else
      Result := '';
  end
  else
  begin
    lines := BuildLines(f, Width - 4.0);
    if Length(lines) = 0 then Exit('');
    lineHeight := f.Height;
    if lineHeight < (f.Ascent + f.Descent) then
      lineHeight := f.Ascent + f.Descent + 2.0;
    totalH := Length(lines) * lineHeight + 4.0;
    if totalH > Height then
      Exit(FText);
    for i := 0 to High(lines) do
      if lines[i].LineWidth > (Width - 4.0) then
        Exit(FText);
    Result := '';
  end;
end;

procedure TFtText.Draw(Canvas: TFtCanvasAgg);
var
  AFont: TFtFont;
  rad: Double;
  curTheme: TFtTheme;
  normCol, accentCol: TFtRgbColor;
  st: TFtWidgetStyle;
  lines: TFtTextLineArray;
  i: Integer;
  lineTX, lineTY: Double;
  selMin, selMax, lineStart, lineEnd: Integer;
  lineSelMin, lineSelMax, relMin, relMax: Integer;
  wBefore, wSel: Double;
  boxX, boxY, boxW, boxH: Double;
  strBefore, strSel, strAfter: string;
begin
  if not Visible or (FText = '') then Exit;

  st := GetResolvedStyle();
  curTheme := FtGetTheme();

  // Background and border if styled via CSS
  if st.HasBgColor or (st.HasBorderWidth and (st.BorderWidth > 0.0) and st.HasBorderColor) then
  begin
    if st.HasBorderRadius then rad := st.BorderRadius else rad := 0.0;
    if st.HasBgColor then
      Canvas.DrawRoundedRect(X, Y, Width, Height, rad, st.BgColor.R, st.BgColor.G, st.BgColor.B, st.BgColor.A);
    if st.HasBorderWidth and (st.BorderWidth > 0.0) and st.HasBorderColor then
      Canvas.DrawRoundedRectOutline(X, Y, Width, Height, rad, st.BorderWidth, st.BorderColor.R, st.BorderColor.G, st.BorderColor.B, st.BorderColor.A);
  end;

  AFont := GetFont();
  if not Assigned(AFont) then AFont := FtGetSystemFont();

  if FCustomColor then
    normCol := FTextColor
  else if st.HasTextColor then
    normCol := MakeRgbColor(st.TextColor.R, st.TextColor.G, st.TextColor.B)
  else
    normCol := curTheme.GetTextColor();

  accentCol := curTheme.GetAccentColor();

  Canvas.PushClipRect(X, Y, Width, Height);
  try
    lines := BuildLines(AFont, Width - 4.0);
    if HasSelection() then
    begin
      selMin := Min(FSelAnchor, FSelCursor);
      selMax := Max(FSelAnchor, FSelCursor);
    end
    else
    begin
      selMin := 0;
      selMax := 0;
    end;

    for i := 0 to High(lines) do
    begin
      lineTY := lines[i].Y;
      // Skip if completely out of vertical bounds
      if (lineTY + AFont.Descent < Y) or (lineTY - AFont.Ascent > Y + Height) then
        Continue;

      case FAlignment of
        taCenter: lineTX := X + (Width - lines[i].LineWidth) / 2.0;
        taRight:  lineTX := X + Width - lines[i].LineWidth - 2.0;
        else      lineTX := X + 2.0;
      end;

      lineStart := lines[i].StartChar;
      lineEnd := lineStart + lines[i].CharLen;

      if FSelectable and HasSelection() and (selMin < lineEnd) and (selMax > lineStart) then
      begin
        lineSelMin := Max(selMin, lineStart);
        lineSelMax := Min(selMax, lineEnd);
        relMin := lineSelMin - lineStart;
        relMax := lineSelMax - lineStart;

        strBefore := SubStrChars(lineStart, relMin);
        strSel := SubStrChars(lineSelMin, relMax - relMin);
        strAfter := SubStrChars(lineSelMax, lines[i].CharLen - relMax);

        wBefore := AFont.GetTextWidth(strBefore);
        wSel := AFont.GetTextWidth(strSel);

        boxX := lineTX + wBefore;
        boxY := lineTY - AFont.Ascent - 1.0;
        boxW := wSel;
        boxH := AFont.Ascent + AFont.Descent + 2.0;

        Canvas.DrawRoundedRect(boxX, boxY, boxW, boxH, 2.0, accentCol.R, accentCol.G, accentCol.B, 0.85);

        if strBefore <> '' then
          Canvas.DrawText(lineTX, lineTY, strBefore, AFont, normCol.R, normCol.G, normCol.B);
        if strSel <> '' then
          Canvas.DrawText(boxX, lineTY, strSel, AFont, 1.0, 1.0, 1.0);
        if strAfter <> '' then
          Canvas.DrawText(boxX + boxW, lineTY, strAfter, AFont, normCol.R, normCol.G, normCol.B);
      end
      else
      begin
        Canvas.DrawText(lineTX, lineTY, lines[i].Text, AFont, normCol.R, normCol.G, normCol.B);
      end;
    end;
  finally
    Canvas.PopClipRect();
  end;

  if FSelectable and FFocused and not HasSelection() then
    curTheme.DrawFocusRing(Canvas, X, Y, Width, Height, 3.0);

  inherited Draw(Canvas);
end;

initialization
  FtSetSelectionLostHandler(@FtClearActiveTextSelection);

end.
