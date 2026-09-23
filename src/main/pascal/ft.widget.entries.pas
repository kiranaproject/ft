unit Ft.Widget.Entries;

{$mode objfpc}{$H+}

interface

uses
  ctypes, SysUtils, Classes, Math, Floria.Canvas.Agg, Floria.Font, Ft.Widget, Ft.Theme, Ft.Window,
  Ft.Widget.ScrollBars, Ft.Widget.Containers, Ft.Widget.Menus, Ft.Css;

type
  TFtEntryChangeCallback = procedure(Sender: Pointer; Text: PChar; UserData: Pointer); cdecl;
  TFtEntrySubmitCallback = procedure(Sender: Pointer; Text: PChar; UserData: Pointer); cdecl;

  TFtEntry = class(TFtContainer)
  private
    FText: string;
    FPlaceholder: string;
    FCursorPos: Integer;     { 0-indexed char offset }
    FSelAnchor: Integer;     { Selection start char offset }
    FSelCursor: Integer;     { Selection end char offset }
    FScrollOffset: Double;   { Horizontal scroll in pixels }
    FReadOnly: Boolean;
    FIsDragging: Boolean;
    FLastClickTime: QWord;
    FClickCount: Integer;

    FDefaultMenu: TFtPopupMenu;
    FItemSelectAll: TFtMenuItem;
    FItemCut: TFtMenuItem;
    FItemCopy: TFtMenuItem;
    FItemPaste: TFtMenuItem;
    FItemDelete: TFtMenuItem;

    FOnChange: TFtEntryChangeCallback;
    FOnSubmit: TFtEntrySubmitCallback;

    procedure SetText(const AValue: string);
    procedure SetPlaceholder(const AValue: string);
    function CharCount(): Integer;
    function CharByteOffset(ACharIdx: Integer): Integer;
    function SubStrChars(ACharStart, ACharLen: Integer): string;
    function HitTestChar(AX: Integer): Integer;
    procedure EnsureCursorVisible();
    procedure CreateDefaultMenu();
    procedure UpdateDefaultMenu();
  protected
    procedure DrawContent(Canvas: TFtCanvasAgg); override;
    function GetContextMenu(): TFtWidget; override;
  public
    constructor Create(AParent: TFtWidget; const AText: string = ''); reintroduce;
    destructor Destroy(); override;

    function GetCursor(): Integer; override;
    procedure MouseDown(AX, AY: Integer; AButton: Integer); override;
    procedure MouseMove(AX, AY: Integer); override;
    procedure MouseUp(AX, AY: Integer; AButton: Integer); override;
    procedure KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string); override;
    procedure LostFocus(); override;

    function GetElementType(): string; override;
    function GetStatePseudoClass(): string; override;

    function HasSelection(): Boolean;
    function GetSelectedText(): string;
    procedure SelectAll();
    procedure ClearSelection();
    procedure SelectWordAt(ACharIdx: Integer);
    function DeleteSelection(): Boolean;
    procedure DeleteSelectedOrChar();
    procedure InsertText(const AInsert: string);
    procedure CopyToClipboard();
    procedure CutToClipboard();
    procedure PasteFromClipboard();

    property Text: string read FText write SetText;
    property Placeholder: string read FPlaceholder write SetPlaceholder;
    property CursorPos: Integer read FCursorPos;
    property SelStart: Integer read FSelAnchor;
    property SelCursor: Integer read FSelCursor;
    property ReadOnly: Boolean read FReadOnly write FReadOnly;
    property OnChange: TFtEntryChangeCallback read FOnChange write FOnChange;
    property OnSubmit: TFtEntrySubmitCallback read FOnSubmit write FOnSubmit;
  end;

implementation

function GetMilliSeconds(): QWord;
begin
  Result := GetTickCount64();
end;

procedure EntryMenuSelectAllCallback(MenuItem: Pointer; UserData: Pointer); cdecl;
begin
  if Assigned(UserData) and (TObject(UserData) is TFtEntry) then
    TFtEntry(UserData).SelectAll();
end;

procedure EntryMenuCutCallback(MenuItem: Pointer; UserData: Pointer); cdecl;
begin
  if Assigned(UserData) and (TObject(UserData) is TFtEntry) then
    TFtEntry(UserData).CutToClipboard();
end;

procedure EntryMenuCopyCallback(MenuItem: Pointer; UserData: Pointer); cdecl;
begin
  if Assigned(UserData) and (TObject(UserData) is TFtEntry) then
    TFtEntry(UserData).CopyToClipboard();
end;

procedure EntryMenuPasteCallback(MenuItem: Pointer; UserData: Pointer); cdecl;
begin
  if Assigned(UserData) and (TObject(UserData) is TFtEntry) then
    TFtEntry(UserData).PasteFromClipboard();
end;

procedure EntryMenuDeleteCallback(MenuItem: Pointer; UserData: Pointer); cdecl;
begin
  if Assigned(UserData) and (TObject(UserData) is TFtEntry) then
    TFtEntry(UserData).DeleteSelectedOrChar();
end;

{ TFtEntry }

constructor TFtEntry.Create(AParent: TFtWidget; const AText: string = '');
begin
  inherited Create(AParent);
  FFocusable := True;
  FAutoContentSize := False;
  FScrollBarMode := ftSbModeNone;
  FPaddingX := 8.0;
  FPaddingY := 4.0;
  FDrawFrame := True;
  FDrawFocusRing := True;

  FText := AText;
  FPlaceholder := '';
  FCursorPos := Length(AText);
  FSelAnchor := FCursorPos;
  FSelCursor := FCursorPos;
  FScrollOffset := 0.0;
  FReadOnly := False;
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
  FOnSubmit := nil;

  Width := 200;
  Height := 34;
end;

destructor TFtEntry.Destroy();
begin
  if Assigned(FDefaultMenu) then
  begin
    FDefaultMenu.Free();
    FDefaultMenu := nil;
  end;
  inherited Destroy();
end;

function TFtEntry.CharCount(): Integer;
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

function TFtEntry.CharByteOffset(ACharIdx: Integer): Integer;
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

function TFtEntry.SubStrChars(ACharStart, ACharLen: Integer): string;
var
  bStart, bEnd: Integer;
begin
  if ACharLen <= 0 then Exit('');
  bStart := CharByteOffset(ACharStart);
  bEnd := CharByteOffset(ACharStart + ACharLen);
  Result := Copy(FText, bStart, bEnd - bStart);
end;

procedure TFtEntry.SetText(const AValue: string);
begin
  FText := AValue;
  FCursorPos := CharCount();
  FSelAnchor := FCursorPos;
  FSelCursor := FCursorPos;
  EnsureCursorVisible();
  Invalidate();
  if Assigned(FOnChange) then
    FOnChange(Self, PChar(FText), FUserData);
end;

procedure TFtEntry.SetPlaceholder(const AValue: string);
begin
  if FPlaceholder <> AValue then
  begin
    FPlaceholder := AValue;
    Invalidate();
  end;
end;

procedure TFtEntry.EnsureCursorVisible();
var
  AFont: TFtFont;
  curX, visW, cx, cy, ch: Double;
begin
  AFont := GetFont();
  if not Assigned(AFont) then AFont := FtGetSystemFont();
  curX := AFont.GetTextWidth(SubStrChars(0, FCursorPos));
  GetClientRect(cx, cy, visW, ch);
  if visW <= 10.0 then Exit;

  if curX - FScrollOffset < 0.0 then
    FScrollOffset := curX
  else if curX + 4.0 - FScrollOffset > visW then
    FScrollOffset := curX + 4.0 - visW;

  if FScrollOffset < 0.0 then
    FScrollOffset := 0.0;
end;

function TFtEntry.HitTestChar(AX: Integer): Integer;
var
  AFont: TFtFont;
  cnt, i: Integer;
  relX, wPrev, wNext, midX: Double;
begin
  cnt := CharCount();
  if cnt = 0 then Exit(0);
  AFont := GetFont();
  if not Assigned(AFont) then AFont := FtGetSystemFont();

  relX := AX - (X + FPaddingX) + FScrollOffset;
  if relX <= 0.0 then Exit(0);

  wPrev := 0.0;
  for i := 1 to cnt do
  begin
    wNext := AFont.GetTextWidth(SubStrChars(0, i));
    midX := (wPrev + wNext) / 2.0;
    if relX < midX then
      Exit(i - 1);
    wPrev := wNext;
  end;
  Result := cnt;
end;

function TFtEntry.GetCursor(): Integer;
begin
  Result := 1; { I-Beam }
end;

function TFtEntry.HasSelection(): Boolean;
begin
  Result := FSelAnchor <> FSelCursor;
end;

function TFtEntry.GetSelectedText(): string;
var
  sMin, sMax: Integer;
begin
  if not HasSelection() then Exit('');
  sMin := Math.Min(FSelAnchor, FSelCursor);
  sMax := Math.Max(FSelAnchor, FSelCursor);
  Result := SubStrChars(sMin, sMax - sMin);
end;

procedure TFtEntry.SelectAll();
begin
  FSelAnchor := 0;
  FSelCursor := CharCount();
  FCursorPos := FSelCursor;
  EnsureCursorVisible();
  Invalidate();
end;

procedure TFtEntry.ClearSelection();
begin
  if HasSelection() then
  begin
    FSelAnchor := FCursorPos;
    FSelCursor := FCursorPos;
    Invalidate();
  end;
end;

procedure TFtEntry.SelectWordAt(ACharIdx: Integer);
var
  cnt, wStart, wEnd: Integer;
  ch: string;
  isSep: Boolean;
begin
  cnt := CharCount();
  if cnt = 0 then
  begin
    FSelAnchor := 0;
    FSelCursor := 0;
    Exit;
  end;
  if ACharIdx >= cnt then ACharIdx := cnt - 1;
  if ACharIdx < 0 then ACharIdx := 0;

  ch := SubStrChars(ACharIdx, 1);
  isSep := (ch = ' ') or (ch = #9) or (ch = ',') or (ch = '.') or (ch = ';') or (ch = ':');

  wStart := ACharIdx;
  while wStart > 0 do
  begin
    ch := SubStrChars(wStart - 1, 1);
    if isSep <> ((ch = ' ') or (ch = #9) or (ch = ',') or (ch = '.') or (ch = ';') or (ch = ':')) then
      Break;
    Dec(wStart);
  end;

  wEnd := ACharIdx + 1;
  while wEnd < cnt do
  begin
    ch := SubStrChars(wEnd, 1);
    if isSep <> ((ch = ' ') or (ch = #9) or (ch = ',') or (ch = '.') or (ch = ';') or (ch = ':')) then
      Break;
    Inc(wEnd);
  end;

  FSelAnchor := wStart;
  FSelCursor := wEnd;
  FCursorPos := wEnd;
end;

function TFtEntry.DeleteSelection(): Boolean;
var
  sMin, sMax, bMin, bMax: Integer;
begin
  Result := False;
  if FReadOnly or (not HasSelection()) then Exit;

  sMin := Math.Min(FSelAnchor, FSelCursor);
  sMax := Math.Max(FSelAnchor, FSelCursor);
  bMin := CharByteOffset(sMin);
  bMax := CharByteOffset(sMax);

  Delete(FText, bMin, bMax - bMin);
  FCursorPos := sMin;
  FSelAnchor := sMin;
  FSelCursor := sMin;
  EnsureCursorVisible();
  Invalidate();
  if Assigned(FOnChange) then
    FOnChange(Self, PChar(FText), FUserData);
  Result := True;
end;

procedure TFtEntry.InsertText(const AInsert: string);
var
  bPos: Integer;
  insLenChars: Integer;
  p: PChar;
  cLen: LongInt;
begin
  if FReadOnly or (AInsert = '') then Exit;
  DeleteSelection();

  bPos := CharByteOffset(FCursorPos);
  Insert(AInsert, FText, bPos);

  insLenChars := 0;
  p := PChar(AInsert);
  while p^ <> #0 do
  begin
    UTF8CharToUnicode(p, cLen);
    Inc(p, cLen);
    Inc(insLenChars);
  end;

  Inc(FCursorPos, insLenChars);
  FSelAnchor := FCursorPos;
  FSelCursor := FCursorPos;
  EnsureCursorVisible();
  Invalidate();
  if Assigned(FOnChange) then
    FOnChange(Self, PChar(FText), FUserData);
end;

procedure TFtEntry.CopyToClipboard();
var
  sel: string;
begin
  sel := GetSelectedText();
  if sel <> '' then
    FtSetClipboardText(sel);
end;

procedure TFtEntry.CutToClipboard();
begin
  if FReadOnly then Exit;
  CopyToClipboard();
  DeleteSelection();
end;

procedure TFtEntry.PasteFromClipboard();
var
  clip: string;
begin
  if FReadOnly then Exit;
  clip := FtGetClipboardText();
  if clip <> '' then
    InsertText(clip);
end;

procedure TFtEntry.CreateDefaultMenu();
begin
  if Assigned(FDefaultMenu) then Exit;
  FDefaultMenu := TFtPopupMenu.Create(Self);
  FItemSelectAll := FDefaultMenu.AddItem('Select All', @EntryMenuSelectAllCallback, Pointer(Self));
  FItemSelectAll.Shortcut := 'Ctrl+A';
  FDefaultMenu.AddSeparator();
  FItemCut := FDefaultMenu.AddItem('Cut', @EntryMenuCutCallback, Pointer(Self));
  FItemCut.Shortcut := 'Ctrl+X';
  FItemCopy := FDefaultMenu.AddItem('Copy', @EntryMenuCopyCallback, Pointer(Self));
  FItemCopy.Shortcut := 'Ctrl+C';
  FItemPaste := FDefaultMenu.AddItem('Paste', @EntryMenuPasteCallback, Pointer(Self));
  FItemPaste.Shortcut := 'Ctrl+V';
  FItemDelete := FDefaultMenu.AddItem('Delete', @EntryMenuDeleteCallback, Pointer(Self));
  FItemDelete.Shortcut := 'Del';
end;

procedure TFtEntry.UpdateDefaultMenu();
var
  hasSel: Boolean;
begin
  if not Assigned(FDefaultMenu) then Exit;
  hasSel := HasSelection();
  FItemSelectAll.Enabled := (CharCount() > 0);
  if FReadOnly then
  begin
    FItemCut.Enabled := False;
    FItemCopy.Enabled := hasSel;
    FItemPaste.Enabled := False;
    FItemDelete.Enabled := False;
  end
  else
  begin
    FItemCut.Enabled := hasSel;
    FItemCopy.Enabled := hasSel;
    FItemPaste.Enabled := (FtGetClipboardText() <> '');
    FItemDelete.Enabled := hasSel or (FCursorPos < CharCount());
  end;
end;

function TFtEntry.GetContextMenu(): TFtWidget;
begin
  if Assigned(FContextMenu) then
    Exit(FContextMenu);
  if not Assigned(FDefaultMenu) then
    CreateDefaultMenu();
  UpdateDefaultMenu();
  Result := FDefaultMenu;
end;

procedure TFtEntry.DeleteSelectedOrChar();
var
  cnt: Integer;
begin
  if FReadOnly then Exit;
  cnt := CharCount();
  if not DeleteSelection() then
  begin
    if FCursorPos < cnt then
    begin
      FSelAnchor := FCursorPos;
      FSelCursor := FCursorPos + 1;
      DeleteSelection();
    end;
  end;
end;

procedure TFtEntry.MouseDown(AX, AY: Integer; AButton: Integer);
var
  nowTime: QWord;
  clickChar, sMin, sMax: Integer;
begin
  inherited MouseDown(AX, AY, AButton);
  if AButton = 3 then
  begin
    SetFocus();
    clickChar := HitTestChar(AX);
    sMin := Math.Min(FSelAnchor, FSelCursor);
    sMax := Math.Max(FSelAnchor, FSelCursor);
    if not (HasSelection() and (clickChar >= sMin) and (clickChar <= sMax)) then
    begin
      FCursorPos := clickChar;
      FSelAnchor := FCursorPos;
      FSelCursor := FCursorPos;
      EnsureCursorVisible();
      Invalidate();
    end;
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
    FCursorPos := HitTestChar(AX);
    FSelAnchor := FCursorPos;
    FSelCursor := FCursorPos;
    FIsDragging := True;
  end
  else if FClickCount = 2 then
  begin
    FCursorPos := HitTestChar(AX);
    SelectWordAt(FCursorPos);
    FIsDragging := False;
  end
  else if FClickCount >= 3 then
  begin
    SelectAll();
    FIsDragging := False;
  end;

  EnsureCursorVisible();
  Invalidate();
end;

procedure TFtEntry.MouseMove(AX, AY: Integer);
begin
  inherited MouseMove(AX, AY);
  if FIsDragging then
  begin
    FSelCursor := HitTestChar(AX);
    FCursorPos := FSelCursor;
    EnsureCursorVisible();
    Invalidate();
  end;
end;

procedure TFtEntry.MouseUp(AX, AY: Integer; AButton: Integer);
begin
  inherited MouseUp(AX, AY, AButton);
  if AButton = 1 then
  begin
    FIsDragging := False;
    if HasSelection() then
      FtClaimPrimarySelection(GetSelectedText());
  end;
end;

procedure TFtEntry.KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string);
const
  ShiftMask = 1;
  ControlMask = 4;
var
  hasShift, hasCtrl: Boolean;
  cnt: Integer;
begin
  inherited KeyDown(AKeySym, AState, AChar);

  hasShift := (AState and ShiftMask) <> 0;
  hasCtrl := (AState and ControlMask) <> 0;
  cnt := CharCount();

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
  // Return / Enter ($FF0D / $FF8D): Submit
  else if (AKeySym = $FF0D) or (AKeySym = $FF8D) then
  begin
    if Assigned(FOnSubmit) then
      FOnSubmit(Self, PChar(FText), FUserData);
  end
  // BackSpace ($FF08)
  else if (AKeySym = $FF08) then
  begin
    if not FReadOnly then
    begin
      if not DeleteSelection() then
      begin
        if FCursorPos > 0 then
        begin
          FSelAnchor := FCursorPos - 1;
          FSelCursor := FCursorPos;
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
        if FCursorPos < cnt then
        begin
          FSelAnchor := FCursorPos;
          FSelCursor := FCursorPos + 1;
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
      if FCursorPos > 0 then
        Dec(FCursorPos);
      FSelCursor := FCursorPos;
    end
    else
    begin
      if HasSelection() then
        FCursorPos := Math.Min(FSelAnchor, FSelCursor)
      else if FCursorPos > 0 then
        Dec(FCursorPos);
      FSelAnchor := FCursorPos;
      FSelCursor := FCursorPos;
    end;
    EnsureCursorVisible();
    Invalidate();
  end
  // Right Arrow ($FF53)
  else if (AKeySym = $FF53) then
  begin
    if hasShift then
    begin
      if FCursorPos < cnt then
        Inc(FCursorPos);
      FSelCursor := FCursorPos;
    end
    else
    begin
      if HasSelection() then
        FCursorPos := Math.Max(FSelAnchor, FSelCursor)
      else if FCursorPos < cnt then
        Inc(FCursorPos);
      FSelAnchor := FCursorPos;
      FSelCursor := FCursorPos;
    end;
    EnsureCursorVisible();
    Invalidate();
  end
  // Home ($FF50)
  else if (AKeySym = $FF50) then
  begin
    FCursorPos := 0;
    if hasShift then
      FSelCursor := FCursorPos
    else
    begin
      FSelAnchor := FCursorPos;
      FSelCursor := FCursorPos;
    end;
    EnsureCursorVisible();
    Invalidate();
  end
  // End ($FF57)
  else if (AKeySym = $FF57) then
  begin
    FCursorPos := cnt;
    if hasShift then
      FSelCursor := FCursorPos
    else
    begin
      FSelAnchor := FCursorPos;
      FSelCursor := FCursorPos;
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

function TFtEntry.GetElementType(): string;
begin
  Result := 'entry';
end;

function TFtEntry.GetStatePseudoClass(): string;
begin
  if not FEnabled then
    Result := ':disabled'
  else if FReadOnly then
    Result := ':read-only'
  else if FFocused then
    Result := ':focus'
  else
    Result := '';
end;

procedure TFtEntry.LostFocus();
begin
  ClearSelection();
  inherited LostFocus();
end;

procedure TFtEntry.DrawContent(Canvas: TFtCanvasAgg);
var
  AFont: TFtFont;
  textX, textY, caretX, caretY, caretH: Double;
  curTheme: TFtTheme;
  textCol, accentCol, placeCol: TFtRgbColor;
  cnt, selMin, selMax: Integer;
  wBefore, wSel: Double;
  strBefore, strSel, strAfter: string;
  st: TFtWidgetStyle;
begin
  curTheme := FtGetTheme();
  st := GetResolvedStyle();
  AFont := GetFont();
  if not Assigned(AFont) then AFont := FtGetSystemFont();

  textX := X + FPaddingX - FScrollOffset;
  textY := Y + (Height / 2.0) + (AFont.Ascent - AFont.Descent) / 2.0;

  if st.HasTextColor then
    textCol := MakeRgbColor(st.TextColor.R, st.TextColor.G, st.TextColor.B)
  else
    textCol := curTheme.GetTextColor();

  if st.HasBorderColor and FFocused then
    accentCol := MakeRgbColor(st.BorderColor.R, st.BorderColor.G, st.BorderColor.B)
  else
    accentCol := curTheme.GetAccentColor();

  placeCol := curTheme.GetInputPlaceholderColor();

  cnt := CharCount();

  // Draw placeholder if text is empty
  if (cnt = 0) and (FPlaceholder <> '') then
  begin
    Canvas.DrawText(X + FPaddingX, textY, FPlaceholder, AFont, placeCol.R, placeCol.G, placeCol.B);
  end;

  // Draw selection highlight if present
  if HasSelection() then
  begin
    selMin := Math.Min(FSelAnchor, FSelCursor);
    selMax := Math.Max(FSelAnchor, FSelCursor);

    wBefore := AFont.GetTextWidth(SubStrChars(0, selMin));
    wSel := AFont.GetTextWidth(SubStrChars(selMin, selMax - selMin));

    // Draw selection background
    Canvas.DrawRoundedRect(textX + wBefore, textY - AFont.Ascent - 1.0, wSel, AFont.Ascent + AFont.Descent + 2.0, 1.5,
                           accentCol.R, accentCol.G, accentCol.B, 0.85);

    // Segment before selection
    strBefore := SubStrChars(0, selMin);
    if strBefore <> '' then
      Canvas.DrawText(textX, textY, strBefore, AFont, textCol.R, textCol.G, textCol.B);

    // Segment in selection (crisp high contrast white)
    strSel := SubStrChars(selMin, selMax - selMin);
    if strSel <> '' then
      Canvas.DrawText(textX + wBefore, textY, strSel, AFont, 1.0, 1.0, 1.0);

    // Segment after selection
    strAfter := SubStrChars(selMax, cnt - selMax);
    if strAfter <> '' then
      Canvas.DrawText(textX + wBefore + wSel, textY, strAfter, AFont, textCol.R, textCol.G, textCol.B);
  end
  else if cnt > 0 then
  begin
    // Normal text
    Canvas.DrawText(textX, textY, FText, AFont, textCol.R, textCol.G, textCol.B);
  end;

  // Draw caret if focused
  if FFocused then
  begin
    caretH := AFont.Ascent + AFont.Descent + 2.0;
    caretY := Y + (Height - caretH) / 2.0;
    caretX := textX + AFont.GetTextWidth(SubStrChars(0, FCursorPos));
    Canvas.DrawRoundedRect(caretX, caretY, 1.8, caretH, 0.5, accentCol.R, accentCol.G, accentCol.B, 1.0);
  end;
end;

end.
