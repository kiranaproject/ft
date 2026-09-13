unit Ft.Widget.Texts;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Math,
  Ft.Canvas.Agg, Ft.Widget, Ft.Font, Ft.Theme, Ft.Backend.X11;

type
  TFtTextAlignment = (taLeft, taCenter, taRight);
  TFtTextChangeNotify = procedure(Sender: Pointer; UserData: Pointer); cdecl;

  TFtText = class(TFtWidget)
  private
    FText: string;
    FSelectable: Boolean;
    FAlignment: TFtTextAlignment;
    FCustomColor: Boolean;
    FTextColor: TFtRgbColor;

    FSelAnchor: Integer;   { 0-based character index where mouse was pressed }
    FSelCursor: Integer;   { 0-based character index where cursor currently is }
    FIsDragging: Boolean;
    FLastClickTime: QWord;
    FClickCount: Integer;

    FOnChange: TFtTextChangeNotify;
    FUserData: Pointer;

    procedure SetText(const AValue: string);
    procedure SetSelectable(AValue: Boolean);
    procedure SetAlignment(AValue: TFtTextAlignment);
    function GetSelectedText(): string;
    function HitTestChar(AX: Integer): Integer;
    procedure SelectWordAt(ACharIdx: Integer);
  public
    constructor Create(AParent: TFtWidget; const AText: string = ''); reintroduce;
    destructor Destroy(); override;

    function CharCount(): Integer;
    function CharByteOffset(ACharIdx: Integer): Integer;
    function SubStrChars(ACharStart, ACharLen: Integer): string;
    function HasSelection(): Boolean;

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

{ TFtText }

constructor TFtText.Create(AParent: TFtWidget; const AText: string = '');
begin
  inherited Create(AParent);
  FText := AText;
  FSelectable := True; { Selectable by default }
  FAlignment := taLeft;
  FCustomColor := False;
  FTextColor := MakeRgbColor(0.0, 0.0, 0.0);

  FSelAnchor := 0;
  FSelCursor := 0;
  FIsDragging := False;
  FLastClickTime := 0;
  FClickCount := 0;

  FOnChange := nil;
  FUserData := nil;

  Width := 160;
  Height := 28;
  FFocusable := FSelectable;
end;

destructor TFtText.Destroy();
begin
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

function TFtText.HitTestChar(AX: Integer): Integer;
var
  AFont: TFtFont;
  TW, TX: Double;
  cnt, i: Integer;
  wPrev, wNext, midX: Double;
begin
  cnt := CharCount();
  if cnt = 0 then Exit(0);
  AFont := GetFont();
  if not Assigned(AFont) then AFont := FtGetSystemFont();

  TW := AFont.GetTextWidth(FText);
  case FAlignment of
    taCenter: TX := X + (Width - TW) / 2.0;
    taRight:  TX := X + Width - TW - 2.0;
    else      TX := X + 2.0;
  end;

  if AX <= TX then Exit(0);
  if AX >= TX + TW then Exit(cnt);

  wPrev := 0.0;
  for i := 0 to cnt - 1 do
  begin
    wNext := AFont.GetTextWidth(SubStrChars(0, i + 1));
    midX := TX + (wPrev + wNext) / 2.0;
    if AX < midX then
      Exit(i);
    wPrev := wNext;
  end;
  Result := cnt;
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

procedure TFtText.MouseDown(AX, AY: Integer; AButton: Integer);
var
  nowTime: QWord;
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
    FSelAnchor := HitTestChar(AX);
    FSelCursor := FSelAnchor;
    FIsDragging := True;
    Invalidate();
  end
  else if FClickCount = 2 then
  begin
    SelectWordAt(HitTestChar(AX));
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

  newPos := HitTestChar(AX);
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

procedure TFtText.Draw(Canvas: TFtCanvasAgg);
var
  AFont: TFtFont;
  TW, TX, TY: Double;
  curTheme: TFtTheme;
  normCol, accentCol: TFtRgbColor;
  selMin, selMax: Integer;
  wBefore, wSel: Double;
  boxX, boxY, boxW, boxH: Double;
  strBefore, strSel, strAfter: string;
begin
  if not Visible or (FText = '') then Exit;

  AFont := GetFont();
  if not Assigned(AFont) then AFont := FtGetSystemFont();

  TW := AFont.GetTextWidth(FText);
  case FAlignment of
    taCenter: TX := X + (Width - TW) / 2.0;
    taRight:  TX := X + Width - TW - 2.0;
    else      TX := X + 2.0;
  end;

  TY := Y + (Height / 2.0) + (AFont.Ascent - AFont.Descent) / 2.0;

  curTheme := FtGetTheme();
  if FCustomColor then
    normCol := FTextColor
  else
    normCol := curTheme.GetTextColor();

  accentCol := curTheme.GetAccentColor();

  if FSelectable and HasSelection() then
  begin
    selMin := Min(FSelAnchor, FSelCursor);
    selMax := Max(FSelAnchor, FSelCursor);

    wBefore := AFont.GetTextWidth(SubStrChars(0, selMin));
    wSel := AFont.GetTextWidth(SubStrChars(selMin, selMax - selMin));

    boxX := TX + wBefore;
    boxY := TY - AFont.Ascent - 1.0;
    boxW := wSel;
    boxH := AFont.Ascent + AFont.Descent + 2.0;

    { Draw selection highlight box with theme accent }
    Canvas.DrawRoundedRect(boxX, boxY, boxW, boxH, 2.0, accentCol.R, accentCol.G, accentCol.B, 0.85);

    { Text segment before selection }
    strBefore := SubStrChars(0, selMin);
    if strBefore <> '' then
      Canvas.DrawText(TX, TY, strBefore, AFont, normCol.R, normCol.G, normCol.B);

    { Text segment inside selection (crisp high-contrast white) }
    strSel := SubStrChars(selMin, selMax - selMin);
    if strSel <> '' then
      Canvas.DrawText(boxX, TY, strSel, AFont, 1.0, 1.0, 1.0);

    { Text segment after selection }
    strAfter := SubStrChars(selMax, CharCount() - selMax);
    if strAfter <> '' then
      Canvas.DrawText(boxX + boxW, TY, strAfter, AFont, normCol.R, normCol.G, normCol.B);
  end
  else
  begin
    { Normal unselected text }
    Canvas.DrawText(TX, TY, FText, AFont, normCol.R, normCol.G, normCol.B);
  end;

  if FSelectable and FFocused and not HasSelection() then
    curTheme.DrawFocusRing(Canvas, X, Y, Width, Height, 3.0);

  inherited Draw(Canvas);
end;

initialization
  FtSetSelectionLostHandler(@FtClearActiveTextSelection);

end.
