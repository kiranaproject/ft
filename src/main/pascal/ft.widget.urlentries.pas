unit Ft.Widget.UrlEntries;

{$mode objfpc}{$H+}

interface

uses
  ctypes, SysUtils, Classes, Math, Ft.Canvas, Floria.Font,
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
    uaBookmark = 1
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
    procedure DrawBackground(Canvas: TFtCanvas); override;
    procedure KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string); override;
  public
    constructor Create(AUrlEntry: TFtUrlEntry); reintroduce;
    procedure GotFocus(); override;
    procedure LostFocus(); override;
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
    FAutoPrefixHttps: Boolean;

    FHoverChip: Boolean;
    FPressedChip: Boolean;
    FHoverBookmark: Boolean;
    FPressedBookmark: Boolean;

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

    procedure ParseUrlString(const AUrl: string);
    procedure UpdateSubEntryBounds();

    function GetSecurityChipRect(out AX, AY, AW, AH: Double): Boolean;
    function GetBookmarkButtonRect(out AX, AY, AW, AH: Double): Boolean;

    procedure DrawSecurityChip(Canvas: TFtCanvas);
    procedure DrawDomainContrastText(Canvas: TFtCanvas);
    procedure DrawActionButtons(Canvas: TFtCanvas);
  protected
    procedure DrawContent(Canvas: TFtCanvas); override;
  public
    constructor Create(AParent: TFtWidget; const AInitialUrl: string = ''); reintroduce;
    destructor Destroy(); override;

    function GetElementType(): string; override;
    function GetEffectiveCornerRadius(): Double; override;
    function IsFocusedForDrawing(): Boolean; override;
    function GetCursor(): Integer; override;

    procedure GotFocus(); override;
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

procedure TFtUrlSubEntry.DrawBackground(Canvas: TFtCanvas);
begin
  // Seamless inside TFtUrlEntry pill container: do not draw separate background or frame
end;

procedure TFtUrlSubEntry.KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string);
begin
  if (AKeySym = 65293) or (AKeySym = 65421) or (AKeySym = 13) or (AKeySym = 10) then
  begin
    if Assigned(FUrlEntry) then
      FUrlEntry.CommitEdit();
    Exit;
  end
  else if (AKeySym = 65307) or (AKeySym = 27) then
  begin
    if Assigned(FUrlEntry) then
      FUrlEntry.CancelEdit();
    Exit;
  end;

  inherited KeyDown(AKeySym, AState, AChar);
end;

procedure TFtUrlSubEntry.GotFocus();
begin
  inherited GotFocus();
  if Assigned(FUrlEntry) then
  begin
    FUrlEntry.InvalidateStyle();
    FUrlEntry.Invalidate();
  end;
end;

procedure TFtUrlSubEntry.LostFocus();
begin
  inherited LostFocus();
  // In a browser Omnibox, losing focus reverts uncommitted text
  if Assigned(FUrlEntry) then
  begin
    if not FUrlEntry.FSwitchingEdit then
      FUrlEntry.CancelEdit();
    FUrlEntry.InvalidateStyle();
    FUrlEntry.Invalidate();
  end;
end;

{ TFtUrlEntry }

constructor TFtUrlEntry.Create(AParent: TFtWidget; const AInitialUrl: string);
begin
  inherited Create(AParent);
  FFocusable := True;
  Height := 36;
  FCornerRadius := 18.0;
  FBackdropBlur := 0.0;
  FPaddingX := 8;
  FPaddingY := 3;
  ScrollBarMode := ftSbModeNone;

  FSecurityState := ussSecure;
  FShowSecurityChip := True;
  FShowSecurityBadgeText := False;
  FBookmarked := False;
  FShowBookmarkButton := True;
  FAutoPrefixHttps := True;

  FHoverChip := False;
  FPressedChip := False;
  FHoverBookmark := False;
  FPressedBookmark := False;

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

function TFtUrlEntry.IsFocusedForDrawing(): Boolean;
begin
  Result := FFocused or FIsEditing or (Assigned(FSubEntry) and FSubEntry.Focused);
end;

function TFtUrlEntry.GetEffectiveCornerRadius(): Double;
var
  st: TFtWidgetStyle;
  maxRad: Double;
begin
  maxRad := Math.Min(Width / 2.0, Height / 2.0);
  st := GetResolvedStyle();
  if st.HasBorderRadius then
    Result := st.BorderRadius
  else if FCornerRadius >= 0.0 then
    Result := FCornerRadius
  else
    Result := maxRad;

  if Result > maxRad then
    Result := maxRad;
end;

procedure TFtUrlEntry.GotFocus();
begin
  inherited GotFocus();
  if not FIsEditing then
    SetEditing(True);
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

procedure TFtUrlEntry.ParseUrlString(const AUrl: string);
var
  colonPos, slashPos, pathStart: Integer;
  remaining: string;
begin
  FParts.Scheme := '';
  FParts.Host := '';
  FParts.PathEtc := '';
  FParts.SecurityState := ussInsecure;

  if AUrl = '' then
  begin
    FSecurityState := ussSecure;
    Exit;
  end;

  colonPos := Pos('://', AUrl);
  if colonPos > 0 then
  begin
    FParts.Scheme := Copy(AUrl, 1, colonPos + 2); // includes '://'
    remaining := Copy(AUrl, colonPos + 3, Length(AUrl));

    if LowerCase(Copy(AUrl, 1, colonPos - 1)) = 'https' then
      FParts.SecurityState := ussSecure
    else if LowerCase(Copy(AUrl, 1, colonPos - 1)) = 'http' then
      FParts.SecurityState := ussInsecure
    else if LowerCase(Copy(AUrl, 1, colonPos - 1)) = 'file' then
      FParts.SecurityState := ussFile
    else
      FParts.SecurityState := ussInternal;
  end
  else
  begin
    colonPos := Pos(':', AUrl);
    if colonPos > 0 then
    begin
      FParts.Scheme := Copy(AUrl, 1, colonPos);
      remaining := Copy(AUrl, colonPos + 1, Length(AUrl));
      if (LowerCase(FParts.Scheme) = 'about:') or (LowerCase(FParts.Scheme) = 'floria:') then
        FParts.SecurityState := ussInternal
      else
        FParts.SecurityState := ussCustom;
    end
    else
    begin
      remaining := AUrl;
      FParts.SecurityState := ussSecure;
    end;
  end;

  slashPos := Pos('/', remaining);
  if slashPos > 0 then
  begin
    FParts.Host := Copy(remaining, 1, slashPos - 1);
    FParts.PathEtc := Copy(remaining, slashPos, Length(remaining));
  end
  else
  begin
    pathStart := Pos('?', remaining);
    if pathStart = 0 then
      pathStart := Pos('#', remaining);

    if pathStart > 0 then
    begin
      FParts.Host := Copy(remaining, 1, pathStart - 1);
      FParts.PathEtc := Copy(remaining, pathStart, Length(remaining));
    end
    else
    begin
      FParts.Host := remaining;
      FParts.PathEtc := '';
    end;
  end;

  FSecurityState := FParts.SecurityState;
end;

function TFtUrlEntry.GetSecurityChipRect(out AX, AY, AW, AH: Double): Boolean;
var
  fnt: TFtFont;
  badgeW: Double;
begin
  if not FShowSecurityChip then
  begin
    AX := 0.0; AY := 0.0; AW := 0.0; AH := 0.0;
    Exit(False);
  end;

  AX := X + FPaddingX;
  AY := Y + (Height - (Height - (FPaddingY * 2.0))) / 2.0;
  AH := Math.Max(16.0, Height - (FPaddingY * 2.0));

  if FShowSecurityBadgeText and (FSecurityState = ussInsecure) then
  begin
    fnt := GetFont();
    if not Assigned(fnt) then fnt := FtGetSystemFont();
    badgeW := 25.0 + fnt.GetTextWidth('Not secure') + 10.0;
    AW := badgeW;
  end
  else
  begin
    AW := AH + 2.0;
  end;

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
begin
  if not Assigned(FSubEntry) then Exit;

  leftX := X + FPaddingX;
  if GetSecurityChipRect(chipX, chipY, chipW, chipH) then
    leftX := chipX + chipW + 6.0;

  rightX := X + Width - FPaddingX;
  if GetBookmarkButtonRect(bmX, bmY, bmW, bmH) then
    rightX := Math.Min(rightX, bmX - 4.0);

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
    InvalidateStyle();
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
  if FHoverChip or FHoverBookmark then
    Exit(FT_CURSOR_HAND);

  if not FIsEditing then
    Exit(FT_CURSOR_IBEAM);

  Result := FT_CURSOR_DEFAULT;
end;

procedure TFtUrlEntry.MouseMove(AX, AY: Integer);
var
  oldChip, oldBm: Boolean;
  cX, cY, cW, cH: Double;
begin
  inherited MouseMove(AX, AY);

  oldChip := FHoverChip;
  oldBm := FHoverBookmark;

  FHoverChip := GetSecurityChipRect(cX, cY, cW, cH) and (AX >= cX) and (AX <= cX + cW) and (AY >= cY) and (AY <= cY + cH);
  FHoverBookmark := GetBookmarkButtonRect(cX, cY, cW, cH) and (AX >= cX) and (AX <= cX + cW) and (AY >= cY) and (AY <= cY + cH);

  if (oldChip <> FHoverChip) or (oldBm <> FHoverBookmark) then
    Invalidate();
end;

procedure TFtUrlEntry.MouseLeave();
begin
  inherited MouseLeave();
  if FHoverChip or FHoverBookmark then
  begin
    FHoverChip := False;
    FHoverBookmark := False;
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

  // Bookmark button click (only button on the right side)
  if GetBookmarkButtonRect(cX, cY, cW, cH) and (AX >= cX) and (AX <= cX + cW) and (AY >= cY) and (AY <= cY + cH) then
  begin
    FPressedBookmark := True;
    SetBookmarked(not FBookmarked);
    if Assigned(FOnBookmarkClick) then
      FOnBookmarkClick(Self, cint32(Ord(FBookmarked)), FUserData);
    if Assigned(FOnActionClick) then
      FOnActionClick(Self, cint32(Ord(uaBookmark)), FUserData);
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

procedure TFtUrlEntry.DrawSecurityChip(Canvas: TFtCanvas);
var
  cX, cY, cW, cH: Double;
  midX, midY, triX: Double;
  curTheme: TFtTheme;
  txtCol: TFtRgbColor;
  accentCol: TFtRgbColor;
  isDark: Boolean;
  chipRad: Double;
  fnt: TFtFont;
  st: TFtWidgetStyle;
begin
  if not GetSecurityChipRect(cX, cY, cW, cH) then Exit;

  curTheme := FtGetTheme();
  isDark := curTheme.DarkMode;
  st := GetResolvedStyle();
  if st.HasTextColor then
    txtCol := MakeRgbColor(st.TextColor.R, st.TextColor.G, st.TextColor.B)
  else
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

  midX := cX + (Math.Min(cW, cH + 2.0) / 2.0);
  midY := cY + (cH / 2.0);

  case FSecurityState of
    ussSecure:
    begin
      // Padlock icon: shackle (curved arch) + body
      Canvas.DrawRoundedRectOutline(midX - 3.5, midY - 6.0, 7.0, 6.0, 3.5, 3.5, txtCol.R, txtCol.G, txtCol.B, 0.85);
      Canvas.DrawRoundedRect(midX - 4.5, midY - 2.0, 9.0, 8.0, 1.5, txtCol.R, txtCol.G, txtCol.B, 0.90);
      // Keyhole (dot + stem) in high-contrast color matching theme
      if isDark then
      begin
        Canvas.DrawCircle(midX, midY + 1.0, 1.1, 0.12, 0.12, 0.12, 1.0);
        Canvas.DrawLine(midX, midY + 1.0, midX, midY + 3.2, 1.1, 0.12, 0.12, 0.12, 1.0);
      end
      else
      begin
        Canvas.DrawCircle(midX, midY + 1.0, 1.1, 1.0, 1.0, 1.0, 1.0);
        Canvas.DrawLine(midX, midY + 1.0, midX, midY + 3.2, 1.1, 1.0, 1.0, 1.0, 1.0);
      end;
    end;

    ussInsecure:
    begin
      if FShowSecurityBadgeText then
        triX := cX + 12.0
      else
        triX := midX;

      // Warning triangle with exclamation mark (amber / danger red)
      // Triangle path: top (triX, midY - 5.5), bottom-right (triX + 5.5, midY + 5.0), bottom-left (triX - 5.5, midY + 5.0)
      Canvas.DrawLine(triX, midY - 5.5, triX + 5.5, midY + 5.0, 1.6, 0.85, 0.25, 0.20, 1.0);
      Canvas.DrawLine(triX + 5.5, midY + 5.0, triX - 5.5, midY + 5.0, 1.6, 0.85, 0.25, 0.20, 1.0);
      Canvas.DrawLine(triX - 5.5, midY + 5.0, triX, midY - 5.5, 1.6, 0.85, 0.25, 0.20, 1.0);
      // Exclamation bar + dot
      Canvas.DrawLine(triX, midY - 2.5, triX, midY + 1.0, 1.4, 0.85, 0.25, 0.20, 1.0);
      Canvas.DrawCircle(triX, midY + 3.2, 0.7, 0.85, 0.25, 0.20, 1.0);

      // Badge text "Not secure" if enabled (spaced properly after the triangle)
      if FShowSecurityBadgeText then
      begin
        fnt := GetFont();
        if not Assigned(fnt) then fnt := FtGetSystemFont();
        Canvas.DrawText(cX + 24.5, midY + (fnt.Ascent - fnt.Descent) / 2.0, 'Not secure', fnt, 0.85, 0.25, 0.20);
      end;
    end;

    ussInternal, ussFile:
    begin
      // Document sheet icon with text lines
      Canvas.DrawRoundedRectOutline(midX - 4.5, midY - 6.0, 9.0, 12.0, 1.2, 1.2, txtCol.R, txtCol.G, txtCol.B, 0.80);
      Canvas.DrawLine(midX - 2.5, midY - 2.5, midX + 2.5, midY - 2.5, 1.0, txtCol.R, txtCol.G, txtCol.B, 0.60);
      Canvas.DrawLine(midX - 2.5, midY + 0.5, midX + 2.5, midY + 0.5, 1.0, txtCol.R, txtCol.G, txtCol.B, 0.60);
      Canvas.DrawLine(midX - 2.5, midY + 3.5, midX + 1.0, midY + 3.5, 1.0, txtCol.R, txtCol.G, txtCol.B, 0.60);
    end;

    ussCustom:
    begin
      Canvas.DrawCircle(midX, midY, 4.0, accentCol.R, accentCol.G, accentCol.B, 0.80);
    end;
  end;
end;

procedure TFtUrlEntry.DrawActionButtons(Canvas: TFtCanvas);
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
  st: TFtWidgetStyle;
begin
  curTheme := FtGetTheme();
  isDark := curTheme.DarkMode;
  st := GetResolvedStyle();
  if st.HasTextColor then
    txtCol := MakeRgbColor(st.TextColor.R, st.TextColor.G, st.TextColor.B)
  else
    txtCol := curTheme.GetTextColor();

  // Bookmark / Star Button (the only button on the right side)
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
end;

procedure TFtUrlEntry.DrawDomainContrastText(Canvas: TFtCanvas);
var
  fnt: TFtFont;
  curTheme: TFtTheme;
  txtCol: TFtRgbColor;
  chipX, chipY, chipW, chipH: Double;
  leftX, rightX, textAvailW: Double;
  bmX, bmY, bmW, bmH: Double;
  curX, textY: Double;
  schemeW, hostW: Double;
  st: TFtWidgetStyle;
begin
  if FIsEditing then Exit;

  curTheme := FtGetTheme();
  st := GetResolvedStyle();
  if st.HasTextColor then
    txtCol := MakeRgbColor(st.TextColor.R, st.TextColor.G, st.TextColor.B)
  else
    txtCol := curTheme.GetTextColor();
  fnt := GetFont();
  if not Assigned(fnt) then fnt := FtGetSystemFont();

  leftX := X + FPaddingX;
  if GetSecurityChipRect(chipX, chipY, chipW, chipH) then
    leftX := chipX + chipW + 6.0;

  rightX := X + Width - FPaddingX;
  if GetBookmarkButtonRect(bmX, bmY, bmW, bmH) then
    rightX := Math.Min(rightX, bmX - 4.0);

  textAvailW := Math.Max(0.0, rightX - leftX);
  if textAvailW <= 0.0 then Exit;

  curX := leftX;
  textY := Y + (Height / 2.0) + (fnt.Ascent - fnt.Descent) / 2.0;

  // Clip text smoothly between security chip and bookmark button
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

    // 3. Path, Query, Anchor (subtly dimmed ~60%)
    if FParts.PathEtc <> '' then
    begin
      Canvas.PushAlpha(0.60);
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

procedure TFtUrlEntry.DrawContent(Canvas: TFtCanvas);
begin
  inherited DrawContent(Canvas);

  UpdateSubEntryBounds();

  DrawSecurityChip(Canvas);

  if not FIsEditing then
    DrawDomainContrastText(Canvas);

  DrawActionButtons(Canvas);
end;

end.
