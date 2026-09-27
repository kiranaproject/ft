unit Ft.Widget.UrlEntries;

{$mode objfpc}{$H+}

interface

uses
  ctypes, SysUtils, Classes, Math, Floria.Canvas.Agg, Floria.Font,
  Ft.Widget, Ft.Window, Ft.Theme, Ft.Widget.Containers, Ft.Widget.ScrollBars, Ft.Widget.Entries, Ft.Css;

type
  TFtUrlSecurityState = (
    ussSecure,      { HTTPS / padlock icon }
    ussInsecure,    { HTTP / warning triangle }
    ussInternal,    { floria:// or chrome:// page icon }
    ussFile,        { file:/// document icon }
    ussCustom       { custom badge }
  );

  TFtUrlActionId = (
    uaBookmark = 1,
    uaCopy = 2,
    uaClear = 3
  );

  TFtUrlEntrySubmitCallback = procedure(Sender: Pointer; const AUrl: PChar; UserData: Pointer); cdecl;
  TFtUrlEntrySecurityClickCallback = procedure(Sender: Pointer; ASecurityState: cint32; UserData: Pointer); cdecl;
  TFtUrlEntryBookmarkClickCallback = procedure(Sender: Pointer; ABookmarked: cint32; UserData: Pointer); cdecl;
  TFtUrlEntryActionClickCallback = procedure(Sender: Pointer; AActionId: cint32; UserData: Pointer); cdecl;

  TFtUrlParts = record
    Scheme: string;
    Host: string;
    PathEtc: string;
    SecurityState: TFtUrlSecurityState;
  end;

  TFtUrlEntry = class;

  { Internal sub-entry for focused URL editing }
  TFtUrlSubEntry = class(TFtEntry)
  private
    FUrlEntry: TFtUrlEntry;
  protected
    procedure KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string); override;
    procedure LostFocus(); override;
  public
    constructor Create(AUrlEntry: TFtUrlEntry); reintroduce;
  end;

  { Google Chrome-Style Omnibox / URL Entry with security chip & domain contrast }
  TFtUrlEntry = class(TFtContainer)
  private
    FUrl: string;
    FParts: TFtUrlParts;
    FIsEditing: Boolean;
    FSubEntry: TFtUrlSubEntry;
    FSwitchingEdit: Boolean;
    FLastCommitTime: QWord;

    FSecurityState: TFtUrlSecurityState;
    FShowSecurityChip: Boolean;
    FShowSecurityBadgeText: Boolean;
    FBookmarked: Boolean;
    FShowBookmarkButton: Boolean;
    FShowClearButton: Boolean;
    FShowCopyButton: Boolean;
    FAutoPrefixHttps: Boolean;

    FHoverChip: Boolean;
    FPressedChip: Boolean;
    FHoverBookmark: Boolean;
    FPressedBookmark: Boolean;
    FHoverCopy: Boolean;
    FPressedCopy: Boolean;
    FHoverClear: Boolean;
    FPressedClear: Boolean;

    FOnSubmit: TFtUrlEntrySubmitCallback;
    FOnSecurityClick: TFtUrlEntrySecurityClickCallback;
    FOnBookmarkClick: TFtUrlEntryBookmarkClickCallback;
    FOnActionClick: TFtUrlEntryActionClickCallback;

    procedure SetUrl(const AValue: string);
    procedure SetSecurityState(AValue: TFtUrlSecurityState);
    procedure SetBookmarked(AValue: Boolean);
    procedure SetShowSecurityChip(AValue: Boolean);
    procedure SetShowSecurityBadgeText(AValue: Boolean);
    procedure SetShowBookmarkButton(AValue: Boolean);
    procedure SetShowClearButton(AValue: Boolean);
    procedure SetShowCopyButton(AValue: Boolean);

    procedure ParseUrlString(const AUrl: string);
    procedure UpdateSubEntryBounds();

    function GetSecurityChipRect(out AX, AY, AW, AH: Double): Boolean;
    function GetBookmarkButtonRect(out AX, AY, AW, AH: Double): Boolean;
    function GetCopyButtonRect(out AX, AY, AW, AH: Double): Boolean;
    function GetClearButtonRect(out AX, AY, AW, AH: Double): Boolean;

    procedure DrawSecurityChip(Canvas: TFtCanvasAgg);
    procedure DrawDomainContrastText(Canvas: TFtCanvasAgg);
    procedure DrawActionButtons(Canvas: TFtCanvasAgg);
  protected
    procedure DrawContent(Canvas: TFtCanvasAgg); override;
  public
    constructor Create(AParent: TFtWidget; const AInitialUrl: string = ''); reintroduce;
    destructor Destroy(); override;

    function GetElementType(): string; override;
    function GetCursor(): Integer; override;

    procedure MouseDown(AX, AY: Integer; AButton: Integer); override;
    procedure MouseMove(AX, AY: Integer); override;
    procedure MouseUp(AX, AY: Integer; AButton: Integer); override;
    procedure MouseLeave(); override;
    procedure KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string); override;

    procedure SetEditing(AValue: Boolean);
    procedure CommitEdit();
    procedure CancelEdit();
    procedure CopyToClipboard();

    property Url: string read FUrl write SetUrl;
    property SecurityState: TFtUrlSecurityState read FSecurityState write SetSecurityState;
    property Bookmarked: Boolean read FBookmarked write SetBookmarked;
    property ShowSecurityChip: Boolean read FShowSecurityChip write SetShowSecurityChip;
    property ShowSecurityBadgeText: Boolean read FShowSecurityBadgeText write SetShowSecurityBadgeText;
    property ShowBookmarkButton: Boolean read FShowBookmarkButton write SetShowBookmarkButton;
    property ShowClearButton: Boolean read FShowClearButton write SetShowClearButton;
    property ShowCopyButton: Boolean read FShowCopyButton write SetShowCopyButton;
    property AutoPrefixHttps: Boolean read FAutoPrefixHttps write FAutoPrefixHttps;
    property IsEditing: Boolean read FIsEditing write SetEditing;
    property SubEntry: TFtUrlSubEntry read FSubEntry;

    property OnSubmit: TFtUrlEntrySubmitCallback read FOnSubmit write FOnSubmit;
    property OnSecurityClick: TFtUrlEntrySecurityClickCallback read FOnSecurityClick write FOnSecurityClick;
    property OnBookmarkClick: TFtUrlEntryBookmarkClickCallback read FOnBookmarkClick write FOnBookmarkClick;
    property OnActionClick: TFtUrlEntryActionClickCallback read FOnActionClick write FOnActionClick;
  end;

implementation

{ TFtUrlSubEntry }

constructor TFtUrlSubEntry.Create(AUrlEntry: TFtUrlEntry);
begin
  inherited Create(AUrlEntry, '');
  FUrlEntry := AUrlEntry;
  DrawFrame := False;
  DrawFocusRing := False;
  ScrollBarMode := ftSbModeNone;
  Visible := False;
end;

procedure TFtUrlSubEntry.KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string);
begin
  // Enter ($FF0D / $FF8D) -> commit edit & submit
  if (AKeySym = $FF0D) or (AKeySym = $FF8D) then
  begin
    if Assigned(FUrlEntry) then
      FUrlEntry.CommitEdit();
    Exit;
  end;

  // Escape ($FF1B) -> cancel edit & revert
  if (AKeySym = $FF1B) then
  begin
    if Assigned(FUrlEntry) then
      FUrlEntry.CancelEdit();
    Exit;
  end;

  inherited KeyDown(AKeySym, AState, AChar);
end;

procedure TFtUrlSubEntry.LostFocus();
begin
  inherited LostFocus();
  if Assigned(FUrlEntry) and not FUrlEntry.FSwitchingEdit then
    FUrlEntry.CommitEdit();
end;

{ TFtUrlEntry }

constructor TFtUrlEntry.Create(AParent: TFtWidget; const AInitialUrl: string);
begin
  inherited Create(AParent);
  FFocusable := True;
  FDrawFrame := True;
  FDrawFocusRing := True;
  FPaddingX := 8.0;
  FPaddingY := 3.0;
  FCornerRadius := 18.0; { Signature Chrome full pill curve }
  FScrollBarMode := ftSbModeNone;
  FIsEditing := False;
  FSwitchingEdit := False;
  FLastCommitTime := 0;

  FSecurityState := ussSecure;
  FShowSecurityChip := True;
  FShowSecurityBadgeText := False;
  FBookmarked := False;
  FShowBookmarkButton := True;
  FShowClearButton := True;
  FShowCopyButton := True;
  FAutoPrefixHttps := True;

  FHoverChip := False;
  FPressedChip := False;
  FHoverBookmark := False;
  FPressedBookmark := False;
  FHoverCopy := False;
  FPressedCopy := False;
  FHoverClear := False;
  FPressedClear := False;

  FOnSubmit := nil;
  FOnSecurityClick := nil;
  FOnBookmarkClick := nil;
  FOnActionClick := nil;

  FSubEntry := TFtUrlSubEntry.Create(Self);
  SetUrl(AInitialUrl);
end;

destructor TFtUrlEntry.Destroy();
begin
  inherited Destroy();
end;

function TFtUrlEntry.GetElementType(): string;
begin
  Result := 'urlentry';
end;

procedure TFtUrlEntry.SetUrl(const AValue: string);
begin
  FUrl := AValue;
  if Assigned(FSubEntry) and not FSwitchingEdit then
    FSubEntry.Text := FUrl;
  ParseUrlString(FUrl);
  Invalidate();
end;

procedure TFtUrlEntry.SetSecurityState(AValue: TFtUrlSecurityState);
begin
  if FSecurityState <> AValue then
  begin
    FSecurityState := AValue;
    Invalidate();
  end;
end;

procedure TFtUrlEntry.SetBookmarked(AValue: Boolean);
begin
  if FBookmarked <> AValue then
  begin
    FBookmarked := AValue;
    Invalidate();
  end;
end;

procedure TFtUrlEntry.SetShowSecurityChip(AValue: Boolean);
begin
  if FShowSecurityChip <> AValue then
  begin
    FShowSecurityChip := AValue;
    UpdateSubEntryBounds();
    Invalidate();
  end;
end;

procedure TFtUrlEntry.SetShowSecurityBadgeText(AValue: Boolean);
begin
  if FShowSecurityBadgeText <> AValue then
  begin
    FShowSecurityBadgeText := AValue;
    UpdateSubEntryBounds();
    Invalidate();
  end;
end;

procedure TFtUrlEntry.SetShowBookmarkButton(AValue: Boolean);
begin
  if FShowBookmarkButton <> AValue then
  begin
    FShowBookmarkButton := AValue;
    UpdateSubEntryBounds();
    Invalidate();
  end;
end;

procedure TFtUrlEntry.SetShowClearButton(AValue: Boolean);
begin
  if FShowClearButton <> AValue then
  begin
    FShowClearButton := AValue;
    UpdateSubEntryBounds();
    Invalidate();
  end;
end;

procedure TFtUrlEntry.SetShowCopyButton(AValue: Boolean);
begin
  if FShowCopyButton <> AValue then
  begin
    FShowCopyButton := AValue;
    UpdateSubEntryBounds();
    Invalidate();
  end;
end;

procedure TFtUrlEntry.ParseUrlString(const AUrl: string);
var
  clean: string;
  schemePos: Integer;
  schemePart: string;
  rest: string;
  slashPos: Integer;
begin
  clean := Trim(AUrl);
  FParts.Scheme := '';
  FParts.Host := '';
  FParts.PathEtc := '';

  if clean = '' then
  begin
    FParts.SecurityState := ussSecure;
    FSecurityState := ussSecure;
    Exit;
  end;

  schemePos := Pos('://', clean);
  if schemePos > 0 then
  begin
    schemePart := Copy(clean, 1, schemePos + 2);
    rest := Copy(clean, schemePos + 3, Length(clean));
    FParts.Scheme := schemePart;

    if LowerCase(schemePart) = 'https://' then
      FParts.SecurityState := ussSecure
    else if LowerCase(schemePart) = 'http://' then
      FParts.SecurityState := ussInsecure
    else if LowerCase(schemePart) = 'file://' then
      FParts.SecurityState := ussFile
    else
      FParts.SecurityState := ussInternal;
  end
  else if (Pos('about:', clean) = 1) or (Pos('floria:', clean) = 1) or (Pos('chrome:', clean) = 1) then
  begin
    schemePos := Pos(':', clean);
    FParts.Scheme := Copy(clean, 1, schemePos);
    rest := Copy(clean, schemePos + 1, Length(clean));
    FParts.SecurityState := ussInternal;
  end
  else
  begin
    rest := clean;
    FParts.SecurityState := ussSecure;
  end;

  FSecurityState := FParts.SecurityState;

  // Split rest into Host and PathEtc
  slashPos := Pos('/', rest);
  if slashPos > 0 then
  begin
    FParts.Host := Copy(rest, 1, slashPos - 1);
    FParts.PathEtc := Copy(rest, slashPos, Length(rest));
  end
  else
  begin
    // Check for query or anchor if no slash
    slashPos := Pos('?', rest);
    if slashPos = 0 then
      slashPos := Pos('#', rest);

    if slashPos > 0 then
    begin
      FParts.Host := Copy(rest, 1, slashPos - 1);
      FParts.PathEtc := Copy(rest, slashPos, Length(rest));
    end
    else
    begin
      FParts.Host := rest;
      FParts.PathEtc := '';
    end;
  end;
end;

function TFtUrlEntry.GetSecurityChipRect(out AX, AY, AW, AH: Double): Boolean;
var
  chipH, chipW: Double;
  fnt: TFtFont;
begin
  if not FShowSecurityChip then
  begin
    AX := 0.0; AY := 0.0; AW := 0.0; AH := 0.0;
    Exit(False);
  end;

  chipH := Math.Max(18.0, Height - (FPaddingY * 2.0));
  chipW := 28.0;

  if FShowSecurityBadgeText and (FSecurityState = ussInsecure) then
  begin
    fnt := GetFont();
    if not Assigned(fnt) then fnt := FtGetSystemFont();
    chipW := 28.0 + fnt.GetTextWidth('Not secure') + 8.0;
  end;

  AX := X + FPaddingX + 2.0;
  AY := Y + (Height - chipH) / 2.0;
  AW := chipW;
  AH := chipH;
  Result := True;
end;

function TFtUrlEntry.GetClearButtonRect(out AX, AY, AW, AH: Double): Boolean;
var
  btnSize: Double;
  rightX: Double;
begin
  if not FShowClearButton or not FIsEditing or (FUrl = '') then
  begin
    AX := 0.0; AY := 0.0; AW := 0.0; AH := 0.0;
    Exit(False);
  end;

  btnSize := Math.Max(16.0, Height - (FPaddingY * 2.0));
  rightX := X + Width - FPaddingX - btnSize - 2.0;

  if FShowBookmarkButton then
    rightX := rightX - btnSize - 4.0;
  if FShowCopyButton then
    rightX := rightX - btnSize - 4.0;

  AX := rightX;
  AY := Y + (Height - btnSize) / 2.0;
  AW := btnSize;
  AH := btnSize;
  Result := True;
end;

function TFtUrlEntry.GetCopyButtonRect(out AX, AY, AW, AH: Double): Boolean;
var
  btnSize: Double;
  rightX: Double;
begin
  if not FShowCopyButton then
  begin
    AX := 0.0; AY := 0.0; AW := 0.0; AH := 0.0;
    Exit(False);
  end;

  btnSize := Math.Max(16.0, Height - (FPaddingY * 2.0));
  rightX := X + Width - FPaddingX - btnSize - 2.0;

  if FShowBookmarkButton then
    rightX := rightX - btnSize - 4.0;

  AX := rightX;
  AY := Y + (Height - btnSize) / 2.0;
  AW := btnSize;
  AH := btnSize;
  Result := True;
end;

function TFtUrlEntry.GetBookmarkButtonRect(out AX, AY, AW, AH: Double): Boolean;
var
  btnSize: Double;
begin
  if not FShowBookmarkButton then
  begin
    AX := 0.0; AY := 0.0; AW := 0.0; AH := 0.0;
    Exit(False);
  end;

  btnSize := Math.Max(16.0, Height - (FPaddingY * 2.0));
  AX := X + Width - FPaddingX - btnSize - 2.0;
  AY := Y + (Height - btnSize) / 2.0;
  AW := btnSize;
  AH := btnSize;
  Result := True;
end;

procedure TFtUrlEntry.UpdateSubEntryBounds();
var
  chipX, chipY, chipW, chipH: Double;
  leftX, rightX: Double;
  bmX, bmY, bmW, bmH: Double;
  cpX, cpY, cpW, cpH: Double;
  clX, clY, clW, clH: Double;
begin
  if not Assigned(FSubEntry) then Exit;

  leftX := X + FPaddingX;
  if GetSecurityChipRect(chipX, chipY, chipW, chipH) then
    leftX := chipX + chipW + 6.0;

  rightX := X + Width - FPaddingX;
  if GetBookmarkButtonRect(bmX, bmY, bmW, bmH) then
    rightX := Math.Min(rightX, bmX - 4.0);
  if GetCopyButtonRect(cpX, cpY, cpW, cpH) then
    rightX := Math.Min(rightX, cpX - 4.0);
  if GetClearButtonRect(clX, clY, clW, clH) then
    rightX := Math.Min(rightX, clX - 4.0);

  FSubEntry.X := Round(leftX);
  FSubEntry.Y := Round(Y + FPaddingY);
  FSubEntry.Width := Math.Max(0, Round(rightX - leftX));
  FSubEntry.Height := Math.Max(0, Round(Height - (FPaddingY * 2.0)));
end;

procedure TFtUrlEntry.SetEditing(AValue: Boolean);
begin
  if FIsEditing <> AValue then
  begin
    FSwitchingEdit := True;
    try
      FIsEditing := AValue;
      if FIsEditing then
      begin
        UpdateSubEntryBounds();
        FSubEntry.Text := FUrl;
        FSubEntry.Visible := True;
        FSubEntry.SelectAll();
        FSubEntry.SetFocus();
      end
      else
      begin
        FSubEntry.Visible := False;
        FSubEntry.KillFocus();
        ParseUrlString(FUrl);
      end;
    finally
      FSwitchingEdit := False;
    end;
    Invalidate();
  end;
end;

procedure TFtUrlEntry.CommitEdit();
var
  newText: string;
begin
  FLastCommitTime := GetTickCount64();
  if FIsEditing then
  begin
    newText := Trim(FSubEntry.Text);
    if (newText <> '') and FAutoPrefixHttps and (Pos('://', newText) = 0) and
       (Pos('about:', newText) = 0) and (Pos('floria:', newText) = 0) then
    begin
      // Auto-prefix https:// if string contains dot and no spaces
      if (Pos('.', newText) > 0) and (Pos(' ', newText) = 0) then
        newText := 'https://' + newText;
    end;

    SetUrl(newText);
    SetEditing(False);
    if Assigned(FOnSubmit) then
      FOnSubmit(Self, PChar(FUrl), FUserData);
  end;
end;

procedure TFtUrlEntry.CancelEdit();
begin
  FLastCommitTime := GetTickCount64();
  if FIsEditing then
  begin
    FSubEntry.Text := FUrl;
    SetEditing(False);
  end;
end;

procedure TFtUrlEntry.CopyToClipboard();
begin
  if FUrl <> '' then
    FtClaimPrimarySelection(FUrl);
end;

function TFtUrlEntry.GetCursor(): Integer;
begin
  if FHoverChip or FHoverBookmark or FHoverCopy or FHoverClear then
    Exit(FT_CURSOR_HAND);

  if not FIsEditing then
    Exit(FT_CURSOR_IBEAM);

  Result := FT_CURSOR_DEFAULT;
end;

procedure TFtUrlEntry.MouseMove(AX, AY: Integer);
var
  oldChip, oldBm, oldCp, oldCl: Boolean;
  cX, cY, cW, cH: Double;
begin
  inherited MouseMove(AX, AY);

  oldChip := FHoverChip;
  oldBm := FHoverBookmark;
  oldCp := FHoverCopy;
  oldCl := FHoverClear;

  FHoverChip := GetSecurityChipRect(cX, cY, cW, cH) and (AX >= cX) and (AX <= cX + cW) and (AY >= cY) and (AY <= cY + cH);
  FHoverBookmark := GetBookmarkButtonRect(cX, cY, cW, cH) and (AX >= cX) and (AX <= cX + cW) and (AY >= cY) and (AY <= cY + cH);
  FHoverCopy := GetCopyButtonRect(cX, cY, cW, cH) and (AX >= cX) and (AX <= cX + cW) and (AY >= cY) and (AY <= cY + cH);
  FHoverClear := GetClearButtonRect(cX, cY, cW, cH) and (AX >= cX) and (AX <= cX + cW) and (AY >= cY) and (AY <= cY + cH);

  if (oldChip <> FHoverChip) or (oldBm <> FHoverBookmark) or
     (oldCp <> FHoverCopy) or (oldCl <> FHoverClear) then
    Invalidate();
end;

procedure TFtUrlEntry.MouseLeave();
begin
  inherited MouseLeave();
  if FHoverChip or FHoverBookmark or FHoverCopy or FHoverClear then
  begin
    FHoverChip := False;
    FHoverBookmark := False;
    FHoverCopy := False;
    FHoverClear := False;
    Invalidate();
  end;
end;

procedure TFtUrlEntry.MouseDown(AX, AY: Integer; AButton: Integer);
var
  cX, cY, cW, cH: Double;
begin
  inherited MouseDown(AX, AY, AButton);

  if AButton <> 1 then Exit;

  // Security chip click
  if GetSecurityChipRect(cX, cY, cW, cH) and (AX >= cX) and (AX <= cX + cW) and (AY >= cY) and (AY <= cY + cH) then
  begin
    FPressedChip := True;
    Invalidate();
    if Assigned(FOnSecurityClick) then
      FOnSecurityClick(Self, cint32(FSecurityState), FUserData);
    Exit;
  end;

  // Bookmark button click
  if GetBookmarkButtonRect(cX, cY, cW, cH) and (AX >= cX) and (AX <= cX + cW) and (AY >= cY) and (AY <= cY + cH) then
  begin
    FPressedBookmark := True;
    SetBookmarked(not FBookmarked);
    if Assigned(FOnBookmarkClick) then
      FOnBookmarkClick(Self, cint32(Ord(FBookmarked)), FUserData);
    if Assigned(FOnActionClick) then
      FOnActionClick(Self, cint32(Ord(uaBookmark)), FUserData);
    Exit;
  end;

  // Copy button click
  if GetCopyButtonRect(cX, cY, cW, cH) and (AX >= cX) and (AX <= cX + cW) and (AY >= cY) and (AY <= cY + cH) then
  begin
    FPressedCopy := True;
    CopyToClipboard();
    if Assigned(FOnActionClick) then
      FOnActionClick(Self, cint32(Ord(uaCopy)), FUserData);
    Invalidate();
    Exit;
  end;

  // Clear button click
  if GetClearButtonRect(cX, cY, cW, cH) and (AX >= cX) and (AX <= cX + cW) and (AY >= cY) and (AY <= cY + cH) then
  begin
    FPressedClear := True;
    FSubEntry.Text := '';
    if Assigned(FOnActionClick) then
      FOnActionClick(Self, cint32(Ord(uaClear)), FUserData);
    Invalidate();
    Exit;
  end;

  // Click on main URL area: enter edit mode & select all text
  if not FIsEditing then
    SetEditing(True);
end;

procedure TFtUrlEntry.MouseUp(AX, AY: Integer; AButton: Integer);
begin
  inherited MouseUp(AX, AY, AButton);
  if AButton <> 1 then Exit;

  FPressedChip := False;
  FPressedBookmark := False;
  FPressedCopy := False;
  FPressedClear := False;
  Invalidate();
end;

procedure TFtUrlEntry.KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string);
const
  ControlMask = 4;
var
  hasCtrl: Boolean;
begin
  hasCtrl := (AState and ControlMask) <> 0;

  // Ctrl+L: switch to edit mode & select all (standard browser Omnibox shortcut)
  if hasCtrl and ((AKeySym = $6C) or (AKeySym = $4C)) then
  begin
    SetEditing(True);
    Exit;
  end;

  inherited KeyDown(AKeySym, AState, AChar);
end;

procedure TFtUrlEntry.DrawSecurityChip(Canvas: TFtCanvasAgg);
var
  cX, cY, cW, cH: Double;
  midX, midY: Double;
  curTheme: TFtTheme;
  txtCol: TFtRgbColor;
  accentCol: TFtRgbColor;
  isDark: Boolean;
  chipRad: Double;
  fnt: TFtFont;
begin
  if not GetSecurityChipRect(cX, cY, cW, cH) then Exit;

  curTheme := FtGetTheme();
  isDark := curTheme.DarkMode;
  txtCol := curTheme.GetTextColor();
  accentCol := curTheme.GetAccentColor();
  chipRad := Math.Min(6.0, cH / 2.0);

  // Background on hover/press
  if FPressedChip then
  begin
    if isDark then
      Canvas.DrawRoundedRect(cX, cY, cW, cH, chipRad, 1.0, 1.0, 1.0, 0.20)
    else
      Canvas.DrawRoundedRect(cX, cY, cW, cH, chipRad, 0.0, 0.0, 0.0, 0.14);
  end
  else if FHoverChip then
  begin
    if isDark then
      Canvas.DrawRoundedRect(cX, cY, cW, cH, chipRad, 1.0, 1.0, 1.0, 0.10)
    else
      Canvas.DrawRoundedRect(cX, cY, cW, cH, chipRad, 0.0, 0.0, 0.0, 0.06);
  end;

  if FShowSecurityBadgeText and (FSecurityState = ussInsecure) then
    midX := cX + 14.0
  else
    midX := cX + (cW / 2.0);
  midY := cY + (cH / 2.0);

  case FSecurityState of
    ussSecure:
    begin
      // Padlock shackle
      Canvas.DrawRoundedRectOutline(midX - 3.5, midY - 6.0, 7.0, 7.0, 3.5, 1.3, txtCol.R, txtCol.G, txtCol.B, 0.75);
      // Padlock body
      Canvas.DrawRoundedRect(midX - 5.0, midY - 1.5, 10.0, 8.0, 2.0, txtCol.R, txtCol.G, txtCol.B, 0.85);
      // Keyhole dot
      if isDark then
        Canvas.DrawCircle(midX, midY + 2.0, 1.1, 0.15, 0.15, 0.15, 1.0)
      else
        Canvas.DrawCircle(midX, midY + 2.0, 1.1, 0.95, 0.95, 0.95, 1.0);
    end;

    ussInsecure:
    begin
      // Amber Warning Triangle
      Canvas.DrawLine(midX, midY - 6.0, midX - 6.0, midY + 5.0, 1.5, 0.96, 0.62, 0.04, 1.0);
      Canvas.DrawLine(midX - 6.0, midY + 5.0, midX + 6.0, midY + 5.0, 1.5, 0.96, 0.62, 0.04, 1.0);
      Canvas.DrawLine(midX + 6.0, midY + 5.0, midX, midY - 6.0, 1.5, 0.96, 0.62, 0.04, 1.0);
      // Exclamation point
      Canvas.DrawLine(midX, midY - 2.5, midX, midY + 1.0, 1.5, 0.96, 0.62, 0.04, 1.0);
      Canvas.DrawCircle(midX, midY + 3.2, 0.8, 0.96, 0.62, 0.04, 1.0);

      if FShowSecurityBadgeText then
      begin
        fnt := GetFont();
        if not Assigned(fnt) then fnt := FtGetSystemFont();
        Canvas.DrawText(cX + 24.0, midY + (fnt.Ascent - fnt.Descent) / 2.0, 'Not secure', fnt, 0.96, 0.62, 0.04);
      end;
    end;

    ussFile:
    begin
      // Document / File icon
      Canvas.DrawRoundedRectOutline(midX - 4.5, midY - 6.0, 9.0, 12.0, 1.5, 1.3, txtCol.R, txtCol.G, txtCol.B, 0.75);
      Canvas.DrawLine(midX - 2.5, midY - 2.0, midX + 2.5, midY - 2.0, 1.2, txtCol.R, txtCol.G, txtCol.B, 0.75);
      Canvas.DrawLine(midX - 2.5, midY + 1.5, midX + 2.5, midY + 1.5, 1.2, txtCol.R, txtCol.G, txtCol.B, 0.75);
    end;

    ussInternal:
    begin
      // Compass / Gear circle for internal browser pages
      Canvas.DrawCircleOutline(midX, midY, 5.5, 1.3, txtCol.R, txtCol.G, txtCol.B, 0.75);
      Canvas.DrawLine(midX - 3.0, midY + 3.0, midX + 3.0, midY - 3.0, 1.2, txtCol.R, txtCol.G, txtCol.B, 0.75);
    end;

    ussCustom:
    begin
      Canvas.DrawCircle(midX, midY, 4.0, accentCol.R, accentCol.G, accentCol.B, 0.85);
    end;
  end;
end;

procedure TFtUrlEntry.DrawActionButtons(Canvas: TFtCanvasAgg);
var
  bX, bY, bW, bH: Double;
  midX, midY: Double;
  curTheme: TFtTheme;
  txtCol: TFtRgbColor;
  isDark: Boolean;
  btnRad: Double;
  pt: Integer;
  r, ang: Double;
  starPts: array[0..9, 0..1] of Double;
begin
  curTheme := FtGetTheme();
  isDark := curTheme.DarkMode;
  txtCol := curTheme.GetTextColor();

  // 1. Bookmark / Star Button
  if GetBookmarkButtonRect(bX, bY, bW, bH) then
  begin
    btnRad := Math.Min(6.0, bH / 2.0);
    if FPressedBookmark then
    begin
      if isDark then
        Canvas.DrawRoundedRect(bX, bY, bW, bH, btnRad, 1.0, 1.0, 1.0, 0.20)
      else
        Canvas.DrawRoundedRect(bX, bY, bW, bH, btnRad, 0.0, 0.0, 0.0, 0.14);
    end
    else if FHoverBookmark then
    begin
      if isDark then
        Canvas.DrawRoundedRect(bX, bY, bW, bH, btnRad, 1.0, 1.0, 1.0, 0.10)
      else
        Canvas.DrawRoundedRect(bX, bY, bW, bH, btnRad, 0.0, 0.0, 0.0, 0.06);
    end;

    midX := bX + (bW / 2.0);
    midY := bY + (bH / 2.0);

    // Compute 5-pointed star points
    for pt := 0 to 9 do
    begin
      if (pt mod 2) = 0 then r := 5.8 else r := 2.6;
      ang := -Pi / 2.0 + pt * (Pi / 5.0);
      starPts[pt, 0] := midX + r * Cos(ang);
      starPts[pt, 1] := midY + r * Sin(ang);
    end;

    if FBookmarked then
    begin
      // Filled vibrant gold star
      for pt := 0 to 9 do
      begin
        Canvas.DrawLine(midX, midY, starPts[pt, 0], starPts[pt, 1], 1.6, 0.92, 0.70, 0.03, 1.0);
        Canvas.DrawLine(starPts[pt, 0], starPts[pt, 1], starPts[(pt + 1) mod 10, 0], starPts[(pt + 1) mod 10, 1], 1.5, 0.92, 0.70, 0.03, 1.0);
      end;
    end
    else
    begin
      // Outlined star
      for pt := 0 to 9 do
        Canvas.DrawLine(starPts[pt, 0], starPts[pt, 1], starPts[(pt + 1) mod 10, 0], starPts[(pt + 1) mod 10, 1], 1.3, txtCol.R, txtCol.G, txtCol.B, 0.65);
    end;
  end;

  // 2. Copy URL Button
  if GetCopyButtonRect(bX, bY, bW, bH) then
  begin
    btnRad := Math.Min(6.0, bH / 2.0);
    if FPressedCopy then
    begin
      if isDark then
        Canvas.DrawRoundedRect(bX, bY, bW, bH, btnRad, 1.0, 1.0, 1.0, 0.20)
      else
        Canvas.DrawRoundedRect(bX, bY, bW, bH, btnRad, 0.0, 0.0, 0.0, 0.14);
    end
    else if FHoverCopy then
    begin
      if isDark then
        Canvas.DrawRoundedRect(bX, bY, bW, bH, btnRad, 1.0, 1.0, 1.0, 0.10)
      else
        Canvas.DrawRoundedRect(bX, bY, bW, bH, btnRad, 0.0, 0.0, 0.0, 0.06);
    end;

    midX := bX + (bW / 2.0);
    midY := bY + (bH / 2.0);

    // Two overlapping sheets
    Canvas.DrawRoundedRectOutline(midX - 4.5, midY - 4.5, 7.0, 8.0, 1.2, 1.2, txtCol.R, txtCol.G, txtCol.B, 0.60);
    if isDark then
      Canvas.DrawRoundedRect(midX - 2.5, midY - 2.5, 7.0, 8.0, 1.2, 0.18, 0.18, 0.18, 1.0)
    else
      Canvas.DrawRoundedRect(midX - 2.5, midY - 2.5, 7.0, 8.0, 1.2, 0.96, 0.96, 0.96, 1.0);
    Canvas.DrawRoundedRectOutline(midX - 2.5, midY - 2.5, 7.0, 8.0, 1.2, 1.2, txtCol.R, txtCol.G, txtCol.B, 0.75);
  end;

  // 3. Clear (✕) Button
  if GetClearButtonRect(bX, bY, bW, bH) then
  begin
    btnRad := Math.Min(6.0, bH / 2.0);
    if FPressedClear then
    begin
      if isDark then
        Canvas.DrawRoundedRect(bX, bY, bW, bH, btnRad, 1.0, 1.0, 1.0, 0.20)
      else
        Canvas.DrawRoundedRect(bX, bY, bW, bH, btnRad, 0.0, 0.0, 0.0, 0.14);
    end
    else if FHoverClear then
    begin
      if isDark then
        Canvas.DrawRoundedRect(bX, bY, bW, bH, btnRad, 1.0, 1.0, 1.0, 0.10)
      else
        Canvas.DrawRoundedRect(bX, bY, bW, bH, btnRad, 0.0, 0.0, 0.0, 0.06);
    end;

    midX := bX + (bW / 2.0);
    midY := bY + (bH / 2.0);

    Canvas.DrawLine(midX - 3.5, midY - 3.5, midX + 3.5, midY + 3.5, 1.5, txtCol.R, txtCol.G, txtCol.B, 0.70);
    Canvas.DrawLine(midX + 3.5, midY - 3.5, midX - 3.5, midY + 3.5, 1.5, txtCol.R, txtCol.G, txtCol.B, 0.70);
  end;
end;

procedure TFtUrlEntry.DrawDomainContrastText(Canvas: TFtCanvasAgg);
var
  fnt: TFtFont;
  curTheme: TFtTheme;
  txtCol: TFtRgbColor;
  chipX, chipY, chipW, chipH: Double;
  leftX, rightX, textAvailW: Double;
  bmX, bmY, bmW, bmH: Double;
  cpX, cpY, cpW, cpH: Double;
  curX, textY: Double;
  schemeW, hostW: Double;
begin
  if FIsEditing then Exit;

  curTheme := FtGetTheme();
  txtCol := curTheme.GetTextColor();
  fnt := GetFont();
  if not Assigned(fnt) then fnt := FtGetSystemFont();

  leftX := X + FPaddingX;
  if GetSecurityChipRect(chipX, chipY, chipW, chipH) then
    leftX := chipX + chipW + 6.0;

  rightX := X + Width - FPaddingX;
  if GetBookmarkButtonRect(bmX, bmY, bmW, bmH) then
    rightX := Math.Min(rightX, bmX - 4.0);
  if GetCopyButtonRect(cpX, cpY, cpW, cpH) then
    rightX := Math.Min(rightX, cpX - 4.0);

  textAvailW := Math.Max(0.0, rightX - leftX);
  if textAvailW <= 0.0 then Exit;

  curX := leftX;
  textY := Y + (Height / 2.0) + (fnt.Ascent - fnt.Descent) / 2.0;

  // Clip text smoothly between security chip and action buttons
  Canvas.PushClipRoundedRect(leftX, Y + 1.0, textAvailW, Height - 2.0, 0.0);
  try
    // 1. Scheme (subtly dimmed ~55%)
    if FParts.Scheme <> '' then
    begin
      schemeW := fnt.GetTextWidth(FParts.Scheme);
      Canvas.PushAlpha(0.55);
      try
        Canvas.DrawText(curX, textY, FParts.Scheme, fnt, txtCol.R, txtCol.G, txtCol.B);
      finally
        Canvas.PopAlpha();
      end;
      curX := curX + schemeW;
    end;

    // 2. Registrable Host/Domain (100% full contrast!)
    if FParts.Host <> '' then
    begin
      hostW := fnt.GetTextWidth(FParts.Host);
      Canvas.DrawText(curX, textY, FParts.Host, fnt, txtCol.R, txtCol.G, txtCol.B);
      curX := curX + hostW;
    end;

    // 3. Path, query, and fragment (subtly dimmed ~65%)
    if FParts.PathEtc <> '' then
    begin
      Canvas.PushAlpha(0.65);
      try
        Canvas.DrawText(curX, textY, FParts.PathEtc, fnt, txtCol.R, txtCol.G, txtCol.B);
      finally
        Canvas.PopAlpha();
      end;
    end;
  finally
    Canvas.PopClipRoundedRect();
  end;
end;

procedure TFtUrlEntry.DrawContent(Canvas: TFtCanvasAgg);
begin
  inherited DrawContent(Canvas);

  UpdateSubEntryBounds();

  DrawSecurityChip(Canvas);

  if not FIsEditing then
    DrawDomainContrastText(Canvas);

  DrawActionButtons(Canvas);
end;

end.
