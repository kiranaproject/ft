unit Ft.Widget.TextAreas;

{$mode objfpc}{$H+}

interface

uses
  ctypes, SysUtils, Classes, Math, Ft.Canvas.Agg, Ft.Font, Ft.Widget, Ft.Theme, Ft.Backend.X11,
  Ft.Widget.ScrollBars, Ft.Widget.Containers;

type
  TFtTextAreaChangeCallback = procedure(Sender: Pointer; Text: PChar; UserData: Pointer); cdecl;

  TFtTextArea = class(TFtContainer)
  private
    FLines: TStringList;
    FPlaceholder: string;
    FCursorLine: Integer;
    FCursorCol: Integer;
    FSelAnchorLine: Integer;
    FSelAnchorCol: Integer;
    FSelCursorLine: Integer;
    FSelCursorCol: Integer;
    FReadOnly: Boolean;
    FIsDragging: Boolean;
    FLastClickTime: QWord;
    FClickCount: Integer;
    FOnChange: TFtTextAreaChangeCallback;

    function GetText(): string;
    procedure SetText(const AValue: string);
    procedure SetPlaceholder(const AValue: string);

    function LineCharCount(ALineIdx: Integer): Integer;
    function LineCharByteOffset(ALineIdx, ACharIdx: Integer): Integer;
    function LineSubStrChars(ALineIdx, ACharStart, ACharLen: Integer): string;
    function HitTestCol(ALineIdx: Integer; AX: Double): Integer;
    procedure HitTestPosition(AX, AY: Integer; out ALine, ACol: Integer);
    procedure EnsureCursorVisible();
    function GetLineHeight(): Double;
    procedure NotifyChange();
  protected
    procedure DrawContent(Canvas: TFtCanvasAgg); override;
  public
    constructor Create(AParent: TFtWidget; const AText: string = ''); reintroduce;
    destructor Destroy(); override;

    procedure UpdateScrollBars(); override;
    function GetCursor(): Integer; override;
    procedure MouseDown(AX, AY: Integer; AButton: Integer); override;
    procedure MouseMove(AX, AY: Integer); override;
    procedure MouseUp(AX, AY: Integer; AButton: Integer); override;
    procedure KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string); override;
    procedure LostFocus(); override;

    function HasSelection(): Boolean;
    function GetSelectedText(): string;
    procedure SelectAll();
    procedure ClearSelection();
    procedure SelectWordAt(ALineIdx, ACharIdx: Integer);
    function DeleteSelection(): Boolean;
    procedure InsertText(const AInsert: string);
    procedure CopyToClipboard();
    procedure CutToClipboard();
    procedure PasteFromClipboard();

    property Text: string read GetText write SetText;
    property Placeholder: string read FPlaceholder write SetPlaceholder;
    property CursorLine: Integer read FCursorLine;
    property CursorCol: Integer read FCursorCol;
    property ReadOnly: Boolean read FReadOnly write FReadOnly;
    property OnChange: TFtTextAreaChangeCallback read FOnChange write FOnChange;
  end;

implementation

function GetMilliSeconds(): QWord;
begin
  Result := GetTickCount64();
end;

function NormalizeText(const S: string): string;
var
  res: string;
begin
  res := StringReplace(S, #13#10, #10, [rfReplaceAll]);
  res := StringReplace(res, #13, #10, [rfReplaceAll]);
  Result := res;
end;

{ TFtTextArea }

constructor TFtTextArea.Create(AParent: TFtWidget; const AText: string = '');
begin
  inherited Create(AParent);
  FFocusable := True;
  FAutoContentSize := False;
  FScrollBarMode := ftSbModeAutoBoth;
  FPaddingX := 8.0;
  FPaddingY := 6.0;
  FDrawFrame := True;
  FDrawFocusRing := True;

  FLines := TStringList.Create();
  FLines.Text := NormalizeText(AText);
  if FLines.Count = 0 then
    FLines.Add('');

  FPlaceholder := '';
  FCursorLine := 0;
  FCursorCol := 0;
  FSelAnchorLine := 0;
  FSelAnchorCol := 0;
  FSelCursorLine := 0;
  FSelCursorCol := 0;
  FReadOnly := False;
  FIsDragging := False;
  FLastClickTime := 0;
  FClickCount := 0;
  FOnChange := nil;

  Width := 240;
  Height := 140;

  UpdateScrollBars();
end;

destructor TFtTextArea.Destroy();
begin
  FLines.Free();
  FLines := nil;
  inherited Destroy();
end;

procedure TFtTextArea.UpdateScrollBars();
var
  i: Integer;
  AFont: TFtFont;
  maxLineW, totalH, lineH: Double;
begin
  if (not Assigned(FVScrollBar)) or (not Assigned(FHScrollBar)) then Exit;

  AFont := GetFont();
  if not Assigned(AFont) then AFont := FtGetSystemFont();
  lineH := GetLineHeight();
  totalH := FLines.Count * lineH;
  maxLineW := 0.0;
  for i := 0 to FLines.Count - 1 do
    maxLineW := Math.Max(maxLineW, AFont.GetTextWidth(FLines[i]));

  FContentWidth := maxLineW + 16.0;
  FContentHeight := totalH;

  inherited UpdateScrollBars();

  if Assigned(FVScrollBar) and FVScrollBar.Visible then
    FVScrollBar.Step := lineH * 2.0;
  if Assigned(FHScrollBar) and FHScrollBar.Visible then
    FHScrollBar.Step := 25.0;
end;

function TFtTextArea.GetText(): string;
begin
  Result := FLines.Text;
  if (Length(Result) >= 2) and (Result[Length(Result) - 1] = #13) and (Result[Length(Result)] = #10) then
    Delete(Result, Length(Result) - 1, 2);
end;

procedure TFtTextArea.SetText(const AValue: string);
begin
  FLines.Text := NormalizeText(AValue);
  if FLines.Count = 0 then
    FLines.Add('');
  FCursorLine := FLines.Count - 1;
  FCursorCol := LineCharCount(FCursorLine);
  FSelAnchorLine := FCursorLine;
  FSelAnchorCol := FCursorCol;
  FSelCursorLine := FCursorLine;
  FSelCursorCol := FCursorCol;
  EnsureCursorVisible();
  Invalidate();
  NotifyChange();
end;

procedure TFtTextArea.SetPlaceholder(const AValue: string);
begin
  if FPlaceholder <> AValue then
  begin
    FPlaceholder := AValue;
    Invalidate();
  end;
end;

function TFtTextArea.GetLineHeight(): Double;
var
  AFont: TFtFont;
begin
  AFont := GetFont();
  if not Assigned(AFont) then AFont := FtGetSystemFont();
  Result := AFont.Ascent + AFont.Descent + 5.0;
end;

function TFtTextArea.LineCharCount(ALineIdx: Integer): Integer;
var
  p: PChar;
  charLen: LongInt;
  strLine: string;
begin
  Result := 0;
  if (ALineIdx < 0) or (ALineIdx >= FLines.Count) then Exit(0);
  strLine := FLines[ALineIdx];
  p := PChar(strLine);
  while p^ <> #0 do
  begin
    UTF8CharToUnicode(p, charLen);
    Inc(p, charLen);
    Inc(Result);
  end;
end;

function TFtTextArea.LineCharByteOffset(ALineIdx, ACharIdx: Integer): Integer;
var
  p: PChar;
  charLen: LongInt;
  idx: Integer;
  strLine: string;
begin
  if (ALineIdx < 0) or (ALineIdx >= FLines.Count) or (ACharIdx <= 0) then Exit(1);
  strLine := FLines[ALineIdx];
  idx := 0;
  p := PChar(strLine);
  while (p^ <> #0) and (idx < ACharIdx) do
  begin
    UTF8CharToUnicode(p, charLen);
    Inc(p, charLen);
    Inc(idx);
  end;
  Result := (p - PChar(strLine)) + 1;
end;

function TFtTextArea.LineSubStrChars(ALineIdx, ACharStart, ACharLen: Integer): string;
var
  bStart, bEnd: Integer;
  strLine: string;
begin
  Result := '';
  if (ALineIdx < 0) or (ALineIdx >= FLines.Count) or (ACharLen <= 0) then Exit;
  strLine := FLines[ALineIdx];
  bStart := LineCharByteOffset(ALineIdx, ACharStart);
  bEnd := LineCharByteOffset(ALineIdx, ACharStart + ACharLen);
  Result := Copy(strLine, bStart, bEnd - bStart);
end;

function TFtTextArea.HasSelection(): Boolean;
begin
  Result := (FSelAnchorLine <> FSelCursorLine) or (FSelAnchorCol <> FSelCursorCol);
end;

function TFtTextArea.GetSelectedText(): string;
var
  sLine1, sCol1, sLine2, sCol2: Integer;
  i: Integer;
  sb: string;
begin
  Result := '';
  if not HasSelection() then Exit;

  if (FSelAnchorLine < FSelCursorLine) or ((FSelAnchorLine = FSelCursorLine) and (FSelAnchorCol <= FSelCursorCol)) then
  begin
    sLine1 := FSelAnchorLine;
    sCol1 := FSelAnchorCol;
    sLine2 := FSelCursorLine;
    sCol2 := FSelCursorCol;
  end
  else
  begin
    sLine1 := FSelCursorLine;
    sCol1 := FSelCursorCol;
    sLine2 := FSelAnchorLine;
    sCol2 := FSelAnchorCol;
  end;

  if sLine1 = sLine2 then
  begin
    Result := LineSubStrChars(sLine1, sCol1, sCol2 - sCol1);
    Exit;
  end;

  sb := LineSubStrChars(sLine1, sCol1, LineCharCount(sLine1) - sCol1) + #10;
  for i := sLine1 + 1 to sLine2 - 1 do
    sb := sb + FLines[i] + #10;
  sb := sb + LineSubStrChars(sLine2, 0, sCol2);
  Result := sb;
end;

procedure TFtTextArea.SelectAll();
begin
  FSelAnchorLine := 0;
  FSelAnchorCol := 0;
  FSelCursorLine := FLines.Count - 1;
  FSelCursorCol := LineCharCount(FSelCursorLine);
  FCursorLine := FSelCursorLine;
  FCursorCol := FSelCursorCol;
  EnsureCursorVisible();
  Invalidate();
end;

procedure TFtTextArea.ClearSelection();
begin
  if HasSelection() then
  begin
    FSelAnchorLine := FCursorLine;
    FSelAnchorCol := FCursorCol;
    FSelCursorLine := FCursorLine;
    FSelCursorCol := FCursorCol;
    Invalidate();
  end;
end;

procedure TFtTextArea.SelectWordAt(ALineIdx, ACharIdx: Integer);
var
  cnt, wStart, wEnd: Integer;
  strLine, ch: string;
  isSep: Boolean;
begin
  cnt := LineCharCount(ALineIdx);
  if cnt = 0 then
  begin
    FSelAnchorLine := ALineIdx;
    FSelAnchorCol := 0;
    FSelCursorLine := ALineIdx;
    FSelCursorCol := 0;
    Exit;
  end;
  if ACharIdx >= cnt then ACharIdx := cnt - 1;
  if ACharIdx < 0 then ACharIdx := 0;

  strLine := FLines[ALineIdx];
  ch := LineSubStrChars(ALineIdx, ACharIdx, 1);
  isSep := (ch = ' ') or (ch = #9) or (ch = ',') or (ch = '.') or (ch = ';') or (ch = ':') or (ch = '(') or (ch = ')');

  wStart := ACharIdx;
  while wStart > 0 do
  begin
    ch := LineSubStrChars(ALineIdx, wStart - 1, 1);
    if isSep <> ((ch = ' ') or (ch = #9) or (ch = ',') or (ch = '.') or (ch = ';') or (ch = ':') or (ch = '(') or (ch = ')')) then
      Break;
    Dec(wStart);
  end;

  wEnd := ACharIdx + 1;
  while wEnd < cnt do
  begin
    ch := LineSubStrChars(ALineIdx, wEnd, 1);
    if isSep <> ((ch = ' ') or (ch = #9) or (ch = ',') or (ch = '.') or (ch = ';') or (ch = ':') or (ch = '(') or (ch = ')')) then
      Break;
    Inc(wEnd);
  end;

  FSelAnchorLine := ALineIdx;
  FSelAnchorCol := wStart;
  FSelCursorLine := ALineIdx;
  FSelCursorCol := wEnd;
  FCursorLine := ALineIdx;
  FCursorCol := wEnd;
end;

function TFtTextArea.DeleteSelection(): Boolean;
var
  sLine1, sCol1, sLine2, sCol2: Integer;
  headPart, tailPart: string;
  i: Integer;
begin
  Result := False;
  if FReadOnly or (not HasSelection()) then Exit;

  if (FSelAnchorLine < FSelCursorLine) or ((FSelAnchorLine = FSelCursorLine) and (FSelAnchorCol <= FSelCursorCol)) then
  begin
    sLine1 := FSelAnchorLine;
    sCol1 := FSelAnchorCol;
    sLine2 := FSelCursorLine;
    sCol2 := FSelCursorCol;
  end
  else
  begin
    sLine1 := FSelCursorLine;
    sCol1 := FSelCursorCol;
    sLine2 := FSelAnchorLine;
    sCol2 := FSelAnchorCol;
  end;

  headPart := LineSubStrChars(sLine1, 0, sCol1);
  tailPart := LineSubStrChars(sLine2, sCol2, LineCharCount(sLine2) - sCol2);

  if sLine1 = sLine2 then
  begin
    FLines[sLine1] := headPart + tailPart;
  end
  else
  begin
    FLines[sLine1] := headPart + tailPart;
    for i := sLine2 downto sLine1 + 1 do
      FLines.Delete(i);
  end;

  FCursorLine := sLine1;
  FCursorCol := sCol1;
  FSelAnchorLine := FCursorLine;
  FSelAnchorCol := FCursorCol;
  FSelCursorLine := FCursorLine;
  FSelCursorCol := FCursorCol;

  EnsureCursorVisible();
  Invalidate();
  NotifyChange();
  Result := True;
end;

procedure TFtTextArea.InsertText(const AInsert: string);
var
  norm: string;
  insertLines: TStringList;
  headPart, tailPart: string;
  i, startLine, startCol: Integer;
begin
  if FReadOnly or (AInsert = '') then Exit;
  DeleteSelection();

  norm := NormalizeText(AInsert);
  insertLines := TStringList.Create();
  try
    insertLines.Text := norm;
    if (norm <> '') and (norm[Length(norm)] = #10) then
      insertLines.Add('');

    startLine := FCursorLine;
    startCol := FCursorCol;
    headPart := LineSubStrChars(startLine, 0, startCol);
    tailPart := LineSubStrChars(startLine, startCol, LineCharCount(startLine) - startCol);

    if insertLines.Count <= 1 then
    begin
      FLines[startLine] := headPart + norm + tailPart;
      FCursorCol := 0;
      while (FCursorCol < LineCharCount(startLine)) and 
            (LineCharByteOffset(startLine, FCursorCol) <= Length(headPart + norm)) do
        Inc(FCursorCol);
    end
    else
    begin
      FLines[startLine] := headPart + insertLines[0];
      for i := 1 to insertLines.Count - 2 do
        FLines.Insert(startLine + i, insertLines[i]);

      FLines.Insert(startLine + insertLines.Count - 1, insertLines[insertLines.Count - 1] + tailPart);

      FCursorLine := startLine + insertLines.Count - 1;
      FCursorCol := 0;
      while (FCursorCol < LineCharCount(FCursorLine)) and 
            (LineCharByteOffset(FCursorLine, FCursorCol) <= Length(insertLines[insertLines.Count - 1])) do
        Inc(FCursorCol);
    end;
  finally
    insertLines.Free();
  end;

  FSelAnchorLine := FCursorLine;
  FSelAnchorCol := FCursorCol;
  FSelCursorLine := FCursorLine;
  FSelCursorCol := FCursorCol;
  EnsureCursorVisible();
  Invalidate();
  NotifyChange();
end;

procedure TFtTextArea.CopyToClipboard();
var
  sel: string;
begin
  sel := GetSelectedText();
  if sel <> '' then
    FtSetClipboardText(sel);
end;

procedure TFtTextArea.CutToClipboard();
begin
  if FReadOnly then Exit;
  CopyToClipboard();
  DeleteSelection();
end;

procedure TFtTextArea.PasteFromClipboard();
var
  clip: string;
begin
  if FReadOnly then Exit;
  clip := FtGetClipboardText();
  if clip <> '' then
    InsertText(clip);
end;

function TFtTextArea.HitTestCol(ALineIdx: Integer; AX: Double): Integer;
var
  AFont: TFtFont;
  cnt, i: Integer;
  relX, wPrev, wNext, midX: Double;
begin
  cnt := LineCharCount(ALineIdx);
  if cnt = 0 then Exit(0);
  AFont := GetFont();
  if not Assigned(AFont) then AFont := FtGetSystemFont();

  relX := AX - (X + FPaddingX) + FScrollX;
  if relX <= 0.0 then Exit(0);

  wPrev := 0.0;
  for i := 1 to cnt do
  begin
    wNext := AFont.GetTextWidth(LineSubStrChars(ALineIdx, 0, i));
    midX := (wPrev + wNext) / 2.0;
    if relX < midX then
      Exit(i - 1);
    wPrev := wNext;
  end;
  Result := cnt;
end;

procedure TFtTextArea.HitTestPosition(AX, AY: Integer; out ALine, ACol: Integer);
var
  lineH: Double;
  lineIdx: Integer;
begin
  lineH := GetLineHeight();
  lineIdx := Floor((AY - (Y + FPaddingY) + FScrollY) / lineH);
  if lineIdx < 0 then lineIdx := 0;
  if lineIdx >= FLines.Count then lineIdx := FLines.Count - 1;
  ALine := lineIdx;
  ACol := HitTestCol(ALine, AX);
end;

procedure TFtTextArea.EnsureCursorVisible();
var
  AFont: TFtFont;
  lineH, visH, visW, curY, curX, cx, cy: Double;
begin
  lineH := GetLineHeight();
  GetClientRect(cx, cy, visW, visH);
  if (visH <= 10.0) or (visW <= 10.0) then Exit;

  // Vertical scroll
  curY := FCursorLine * lineH;
  if curY - FScrollY < 0.0 then
    SetScrollY(curY)
  else if curY + lineH - FScrollY > visH then
    SetScrollY(curY + lineH - visH);

  // Horizontal scroll
  AFont := GetFont();
  if not Assigned(AFont) then AFont := FtGetSystemFont();
  curX := AFont.GetTextWidth(LineSubStrChars(FCursorLine, 0, FCursorCol));

  if curX - FScrollX < 0.0 then
    SetScrollX(curX)
  else if curX + 4.0 - FScrollX > visW then
    SetScrollX(curX + 4.0 - visW);

  UpdateScrollBars();
end;

procedure TFtTextArea.NotifyChange();
var
  txt: string;
begin
  if Assigned(FOnChange) then
  begin
    txt := GetText();
    FOnChange(Self, PChar(txt), FUserData);
  end;
end;

function TFtTextArea.GetCursor(): Integer;
begin
  Result := 1; { I-Beam }
end;

procedure TFtTextArea.MouseDown(AX, AY: Integer; AButton: Integer);
var
  nowTime: QWord;
  lineH: Double;
begin
  lineH := GetLineHeight();

  // Mouse wheel up
  if AButton = 4 then
  begin
    SetScrollY(FScrollY - lineH * 3.0);
    Exit;
  end;
  // Mouse wheel down
  if AButton = 5 then
  begin
    SetScrollY(FScrollY + lineH * 3.0);
    Exit;
  end;
  // Mouse wheel left
  if AButton = 6 then
  begin
    SetScrollX(FScrollX - 30.0);
    Exit;
  end;
  // Mouse wheel right
  if AButton = 7 then
  begin
    SetScrollX(FScrollX + 30.0);
    Exit;
  end;

  if AButton <> 1 then Exit;
  SetFocus();

  nowTime := GetMilliSeconds();
  if (nowTime - FLastClickTime) < 350 then
    Inc(FClickCount)
  else
    FClickCount := 1;
  FLastClickTime := nowTime;

  if FClickCount = 1 then
  begin
    HitTestPosition(AX, AY, FCursorLine, FCursorCol);
    FSelAnchorLine := FCursorLine;
    FSelAnchorCol := FCursorCol;
    FSelCursorLine := FCursorLine;
    FSelCursorCol := FCursorCol;
    FIsDragging := True;
  end
  else if FClickCount = 2 then
  begin
    HitTestPosition(AX, AY, FCursorLine, FCursorCol);
    SelectWordAt(FCursorLine, FCursorCol);
    FIsDragging := False;
  end
  else if FClickCount >= 3 then
  begin
    HitTestPosition(AX, AY, FCursorLine, FCursorCol);
    FSelAnchorLine := FCursorLine;
    FSelAnchorCol := 0;
    FSelCursorLine := FCursorLine;
    FSelCursorCol := LineCharCount(FCursorLine);
    FCursorCol := FSelCursorCol;
    FIsDragging := False;
  end;

  EnsureCursorVisible();
  Invalidate();
end;

procedure TFtTextArea.MouseMove(AX, AY: Integer);
begin
  inherited MouseMove(AX, AY);
  if FIsDragging then
  begin
    HitTestPosition(AX, AY, FSelCursorLine, FSelCursorCol);
    FCursorLine := FSelCursorLine;
    FCursorCol := FSelCursorCol;
    EnsureCursorVisible();
    Invalidate();
  end;
end;

procedure TFtTextArea.MouseUp(AX, AY: Integer; AButton: Integer);
begin
  inherited MouseUp(AX, AY, AButton);
  if AButton = 1 then
  begin
    FIsDragging := False;
    if HasSelection() then
      FtClaimPrimarySelection(GetSelectedText());
  end;
end;

procedure TFtTextArea.KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string);
const
  ShiftMask = 1;
  ControlMask = 4;
var
  hasShift, hasCtrl: Boolean;
  lineLen: Integer;
begin
  inherited KeyDown(AKeySym, AState, AChar);

  hasShift := (AState and ShiftMask) <> 0;
  hasCtrl := (AState and ControlMask) <> 0;
  lineLen := LineCharCount(FCursorLine);

  // Ctrl+A: Select All
  if hasCtrl and ((AKeySym = $61) or (AKeySym = $41)) then
  begin
    SelectAll();
  end
  // Ctrl+C: Copy
  else if hasCtrl and ((AKeySym = $63) or (AKeySym = $43)) then
  begin
    CopyToClipboard();
  end
  // Ctrl+X: Cut
  else if hasCtrl and ((AKeySym = $78) or (AKeySym = $58)) then
  begin
    CutToClipboard();
  end
  // Ctrl+V: Paste
  else if hasCtrl and ((AKeySym = $76) or (AKeySym = $56)) then
  begin
    PasteFromClipboard();
  end
  // Return / Enter: Insert newline ($FF0D / $FF8D)
  else if (AKeySym = $FF0D) or (AKeySym = $FF8D) then
  begin
    if not FReadOnly then
      InsertText(#10);
  end
  // BackSpace ($FF08)
  else if (AKeySym = $FF08) then
  begin
    if not FReadOnly then
    begin
      if not DeleteSelection() then
      begin
        if FCursorCol > 0 then
        begin
          FSelAnchorLine := FCursorLine;
          FSelAnchorCol := FCursorCol - 1;
          FSelCursorLine := FCursorLine;
          FSelCursorCol := FCursorCol;
          DeleteSelection();
        end
        else if FCursorLine > 0 then
        begin
          FSelAnchorLine := FCursorLine - 1;
          FSelAnchorCol := LineCharCount(FCursorLine - 1);
          FSelCursorLine := FCursorLine;
          FSelCursorCol := 0;
          DeleteSelection();
        end;
      end;
    end;
  end
  // Delete ($FFFF)
  else if (AKeySym = $FFFF) then
  begin
    if not FReadOnly then
    begin
      if not DeleteSelection() then
      begin
        if FCursorCol < lineLen then
        begin
          FSelAnchorLine := FCursorLine;
          FSelAnchorCol := FCursorCol;
          FSelCursorLine := FCursorLine;
          FSelCursorCol := FCursorCol + 1;
          DeleteSelection();
        end
        else if FCursorLine < FLines.Count - 1 then
        begin
          FSelAnchorLine := FCursorLine;
          FSelAnchorCol := lineLen;
          FSelCursorLine := FCursorLine + 1;
          FSelCursorCol := 0;
          DeleteSelection();
        end;
      end;
    end;
  end
  // Left Arrow ($FF51)
  else if (AKeySym = $FF51) then
  begin
    if hasShift then
    begin
      if FCursorCol > 0 then
        Dec(FCursorCol)
      else if FCursorLine > 0 then
      begin
        Dec(FCursorLine);
        FCursorCol := LineCharCount(FCursorLine);
      end;
      FSelCursorLine := FCursorLine;
      FSelCursorCol := FCursorCol;
    end
    else
    begin
      if HasSelection() then
      begin
        ClearSelection();
      end
      else if FCursorCol > 0 then
        Dec(FCursorCol)
      else if FCursorLine > 0 then
      begin
        Dec(FCursorLine);
        FCursorCol := LineCharCount(FCursorLine);
      end;
      FSelAnchorLine := FCursorLine;
      FSelAnchorCol := FCursorCol;
      FSelCursorLine := FCursorLine;
      FSelCursorCol := FCursorCol;
    end;
    EnsureCursorVisible();
    Invalidate();
  end
  // Right Arrow ($FF53)
  else if (AKeySym = $FF53) then
  begin
    if hasShift then
    begin
      if FCursorCol < lineLen then
        Inc(FCursorCol)
      else if FCursorLine < FLines.Count - 1 then
      begin
        Inc(FCursorLine);
        FCursorCol := 0;
      end;
      FSelCursorLine := FCursorLine;
      FSelCursorCol := FCursorCol;
    end
    else
    begin
      if HasSelection() then
      begin
        ClearSelection();
      end
      else if FCursorCol < lineLen then
        Inc(FCursorCol)
      else if FCursorLine < FLines.Count - 1 then
      begin
        Inc(FCursorLine);
        FCursorCol := 0;
      end;
      FSelAnchorLine := FCursorLine;
      FSelAnchorCol := FCursorCol;
      FSelCursorLine := FCursorLine;
      FSelCursorCol := FCursorCol;
    end;
    EnsureCursorVisible();
    Invalidate();
  end
  // Up Arrow ($FF52)
  else if (AKeySym = $FF52) then
  begin
    if hasShift then
    begin
      if FCursorLine > 0 then
      begin
        Dec(FCursorLine);
        FCursorCol := Math.Min(FCursorCol, LineCharCount(FCursorLine));
      end
      else
        FCursorCol := 0;
      FSelCursorLine := FCursorLine;
      FSelCursorCol := FCursorCol;
    end
    else
    begin
      if HasSelection() then
        ClearSelection();
      if FCursorLine > 0 then
      begin
        Dec(FCursorLine);
        FCursorCol := Math.Min(FCursorCol, LineCharCount(FCursorLine));
      end
      else
        FCursorCol := 0;
      FSelAnchorLine := FCursorLine;
      FSelAnchorCol := FCursorCol;
      FSelCursorLine := FCursorLine;
      FSelCursorCol := FCursorCol;
    end;
    EnsureCursorVisible();
    Invalidate();
  end
  // Down Arrow ($FF54)
  else if (AKeySym = $FF54) then
  begin
    if hasShift then
    begin
      if FCursorLine < FLines.Count - 1 then
      begin
        Inc(FCursorLine);
        FCursorCol := Math.Min(FCursorCol, LineCharCount(FCursorLine));
      end
      else
        FCursorCol := LineCharCount(FCursorLine);
      FSelCursorLine := FCursorLine;
      FSelCursorCol := FCursorCol;
    end
    else
    begin
      if HasSelection() then
        ClearSelection();
      if FCursorLine < FLines.Count - 1 then
      begin
        Inc(FCursorLine);
        FCursorCol := Math.Min(FCursorCol, LineCharCount(FCursorLine));
      end
      else
        FCursorCol := LineCharCount(FCursorLine);
      FSelAnchorLine := FCursorLine;
      FSelAnchorCol := FCursorCol;
      FSelCursorLine := FCursorLine;
      FSelCursorCol := FCursorCol;
    end;
    EnsureCursorVisible();
    Invalidate();
  end
  // Home ($FF50)
  else if (AKeySym = $FF50) then
  begin
    FCursorCol := 0;
    if hasShift then
    begin
      FSelCursorLine := FCursorLine;
      FSelCursorCol := FCursorCol;
    end
    else
    begin
      FSelAnchorLine := FCursorLine;
      FSelAnchorCol := FCursorCol;
      FSelCursorLine := FCursorLine;
      FSelCursorCol := FCursorCol;
    end;
    EnsureCursorVisible();
    Invalidate();
  end
  // End ($FF57)
  else if (AKeySym = $FF57) then
  begin
    FCursorCol := lineLen;
    if hasShift then
    begin
      FSelCursorLine := FCursorLine;
      FSelCursorCol := FCursorCol;
    end
    else
    begin
      FSelAnchorLine := FCursorLine;
      FSelAnchorCol := FCursorCol;
      FSelCursorLine := FCursorLine;
      FSelCursorCol := FCursorCol;
    end;
    EnsureCursorVisible();
    Invalidate();
  end
  // Escape ($FF1B)
  else if (AKeySym = $FF1B) then
  begin
    if HasSelection() then
      ClearSelection()
    else
      KillFocus();
  end
  // Printable text character input
  else if (AChar <> '') and (AChar[1] >= #32) and not hasCtrl then
  begin
    if not FReadOnly then
      InsertText(AChar);
  end;
end;

procedure TFtTextArea.LostFocus();
begin
  ClearSelection();
  inherited LostFocus();
end;

procedure TFtTextArea.DrawContent(Canvas: TFtCanvasAgg);
var
  AFont: TFtFont;
  lineH, curY, textX, textY, caretX, caretY, caretH: Double;
  curTheme: TFtTheme;
  textCol, accentCol, placeCol: TFtRgbColor;
  i, cnt: Integer;
  sLine1, sCol1, sLine2, sCol2: Integer;
  lineSelStart, lineSelEnd: Integer;
  strBefore, strSel, strAfter: string;
  wBefore, wSel: Double;
begin
  curTheme := FtGetTheme();
  AFont := GetFont();
  if not Assigned(AFont) then AFont := FtGetSystemFont();

  lineH := GetLineHeight();
  textCol := curTheme.GetTextColor();
  accentCol := curTheme.GetAccentColor();
  placeCol := curTheme.GetInputPlaceholderColor();

  cnt := FLines.Count;

  // Draw placeholder if text is completely empty
  if (cnt = 1) and (FLines[0] = '') and (FPlaceholder <> '') then
  begin
    textY := Y + FPaddingY + AFont.Ascent;
    Canvas.DrawText(X + FPaddingX, textY, FPlaceholder, AFont, placeCol.R, placeCol.G, placeCol.B);
  end;

  // Selection order
  if (FSelAnchorLine < FSelCursorLine) or ((FSelAnchorLine = FSelCursorLine) and (FSelAnchorCol <= FSelCursorCol)) then
  begin
    sLine1 := FSelAnchorLine;
    sCol1 := FSelAnchorCol;
    sLine2 := FSelCursorLine;
    sCol2 := FSelCursorCol;
  end
  else
  begin
    sLine1 := FSelCursorLine;
    sCol1 := FSelCursorCol;
    sLine2 := FSelAnchorLine;
    sCol2 := FSelAnchorCol;
  end;

  // Render visible lines
  for i := 0 to cnt - 1 do
  begin
    curY := Y + FPaddingY + (i * lineH) - FScrollY;
    if (curY + lineH < Y) or (curY > Y + Height) then
      Continue;

    textX := X + FPaddingX - FScrollX;
    textY := curY + AFont.Ascent;

    // Check selection on this line
    if HasSelection() and (i >= sLine1) and (i <= sLine2) then
    begin
      if i = sLine1 then
        lineSelStart := sCol1
      else
        lineSelStart := 0;

      if i = sLine2 then
        lineSelEnd := sCol2
      else
        lineSelEnd := LineCharCount(i);

      wBefore := AFont.GetTextWidth(LineSubStrChars(i, 0, lineSelStart));
      wSel := AFont.GetTextWidth(LineSubStrChars(i, lineSelStart, lineSelEnd - lineSelStart));
      if (i < sLine2) and (lineSelEnd = LineCharCount(i)) then
        wSel := wSel + 6.0; // indicate line break selection

      // Draw selection background
      Canvas.DrawRoundedRect(textX + wBefore, textY - AFont.Ascent - 1.0, wSel, lineH, 1.5,
                             accentCol.R, accentCol.G, accentCol.B, 0.85);

      // Before
      strBefore := LineSubStrChars(i, 0, lineSelStart);
      if strBefore <> '' then
        Canvas.DrawText(textX, textY, strBefore, AFont, textCol.R, textCol.G, textCol.B);

      // Selection
      strSel := LineSubStrChars(i, lineSelStart, lineSelEnd - lineSelStart);
      if strSel <> '' then
        Canvas.DrawText(textX + wBefore, textY, strSel, AFont, 1.0, 1.0, 1.0);

      // After
      strAfter := LineSubStrChars(i, lineSelEnd, LineCharCount(i) - lineSelEnd);
      if strAfter <> '' then
        Canvas.DrawText(textX + wBefore + wSel, textY, strAfter, AFont, textCol.R, textCol.G, textCol.B);
    end
    else
    begin
      // Normal line
      if FLines[i] <> '' then
        Canvas.DrawText(textX, textY, FLines[i], AFont, textCol.R, textCol.G, textCol.B);
    end;

    // Draw caret on cursor line
    if FFocused and (i = FCursorLine) then
    begin
      caretH := lineH - 2.0;
      caretY := curY + 1.0;
      caretX := textX + AFont.GetTextWidth(LineSubStrChars(i, 0, FCursorCol));
      Canvas.DrawRoundedRect(caretX, caretY, 1.8, caretH, 0.5, accentCol.R, accentCol.G, accentCol.B, 1.0);
    end;
  end;
end;

end.
