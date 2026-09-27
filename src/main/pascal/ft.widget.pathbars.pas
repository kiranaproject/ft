unit Ft.Widget.PathBars;

{$mode objfpc}{$H+}

interface

uses
  ctypes, SysUtils, Classes, Math, Floria.Canvas.Agg, Floria.Font,
  Ft.Widget, Ft.Theme, Ft.Widget.Containers, Ft.Widget.ScrollBars, Ft.Widget.Entries, Ft.Css;

type
  TFtPathBarMode = (pbmBreadcrumbs, pbmEdit);

  TFtPathBarNavigateCallback = procedure(Sender: Pointer; const APath: PChar; UserData: Pointer); cdecl;
  TFtPathBarModeChangeCallback = procedure(Sender: Pointer; AMode: cint32; UserData: Pointer); cdecl;

  TFtPathSegment = record
    Name: string;
    FullPath: string;
    X: Double;
    Y: Double;
    Width: Double;
    Height: Double;
    IsEllipsis: Boolean;
    IsVisible: Boolean;
  end;

  TFtPathBar = class;

  { Internal sub-entry for inline text editing }
  TFtPathBarEntry = class(TFtEntry)
  private
    FPathBar: TFtPathBar;
  protected
    procedure KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string); override;
    procedure LostFocus(); override;
  public
    constructor Create(APathBar: TFtPathBar); reintroduce;
  end;

  { Nautilus-style dual-mode breadcrumb path entry widget }
  TFtPathBar = class(TFtContainer)
  private
    FPath: string;
    FMode: TFtPathBarMode;
    FEntry: TFtPathBarEntry;
    FSegments: array of TFtPathSegment;
    FHoverSegment: Integer;
    FPressedSegment: Integer;
    FHoverToggle: Boolean;
    FPressedToggle: Boolean;
    FShowEditButton: Boolean;
    FEditButtonWidth: Double;
    FRootDisplayName: string;
    FSwitchingMode: Boolean;
    FLastCommitTime: QWord;
    FOnNavigate: TFtPathBarNavigateCallback;
    FOnModeChange: TFtPathBarModeChangeCallback;

    procedure SetPath(const AValue: string);
    procedure SetMode(AValue: TFtPathBarMode);
    procedure SetShowEditButton(AValue: Boolean);
    procedure SetRootDisplayName(const AValue: string);
    procedure ParsePath(const APath: string);
    procedure ComputeLayout();
    procedure UpdateEntryBounds();
    function GetToggleRect(out AX, AY, AW, AH: Double): Boolean;
    function HitTestSegment(AX, AY: Integer): Integer;
    function IsOverEmptyArea(AX, AY: Integer): Boolean;
    procedure DrawBreadcrumbs(Canvas: TFtCanvasAgg);
    procedure DrawToggleButton(Canvas: TFtCanvasAgg);
  protected
    procedure DrawContent(Canvas: TFtCanvasAgg); override;
  public
    constructor Create(AParent: TFtWidget; const APath: string = ''); reintroduce;
    destructor Destroy(); override;

    function GetElementType(): string; override;
    function GetCursor(): Integer; override;

    procedure MouseDown(AX, AY: Integer; AButton: Integer); override;
    procedure MouseMove(AX, AY: Integer); override;
    procedure MouseUp(AX, AY: Integer; AButton: Integer); override;
    procedure MouseLeave(); override;
    procedure KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string); override;

    procedure NavigateTo(const APath: string);
    procedure CommitEdit();
    procedure CancelEdit();

    property Path: string read FPath write SetPath;
    property Mode: TFtPathBarMode read FMode write SetMode;
    property ShowEditButton: Boolean read FShowEditButton write SetShowEditButton;
    property RootDisplayName: string read FRootDisplayName write SetRootDisplayName;
    property Entry: TFtPathBarEntry read FEntry;
    property IsSwitchingMode: Boolean read FSwitchingMode;
    property OnNavigate: TFtPathBarNavigateCallback read FOnNavigate write FOnNavigate;
    property OnModeChange: TFtPathBarModeChangeCallback read FOnModeChange write FOnModeChange;
  end;

implementation

{ TFtPathBarEntry }

constructor TFtPathBarEntry.Create(APathBar: TFtPathBar);
begin
  inherited Create(APathBar, '');
  FPathBar := APathBar;
  DrawFrame := False;
  DrawFocusRing := False;
  ScrollBarMode := ftSbModeNone;
  Visible := False;
end;

procedure TFtPathBarEntry.KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string);
begin
  // Return / Enter ($FF0D / $FF8D) -> commit edit & navigate
  if (AKeySym = $FF0D) or (AKeySym = $FF8D) then
  begin
    if Assigned(FPathBar) then
      FPathBar.CommitEdit();
    Exit;
  end;

  // Escape ($FF1B) -> cancel edit & revert
  if (AKeySym = $FF1B) then
  begin
    if Assigned(FPathBar) then
      FPathBar.CancelEdit();
    Exit;
  end;

  inherited KeyDown(AKeySym, AState, AChar);
end;

procedure TFtPathBarEntry.LostFocus();
begin
  inherited LostFocus();
  if Assigned(FPathBar) and not FPathBar.IsSwitchingMode then
    FPathBar.CommitEdit();
end;

{ TFtPathBar }

constructor TFtPathBar.Create(AParent: TFtWidget; const APath: string);
begin
  inherited Create(AParent);
  FFocusable := True;
  FDrawFrame := True;
  FDrawFocusRing := True;
  FPaddingX := 6.0;
  FPaddingY := 3.0;
  FCornerRadius := 6.0;
  FScrollBarMode := ftSbModeNone;
  FMode := pbmBreadcrumbs;
  FHoverSegment := -1;
  FPressedSegment := -1;
  FHoverToggle := False;
  FPressedToggle := False;
  FShowEditButton := True;
  FEditButtonWidth := 24.0;
  FRootDisplayName := '';
  FSwitchingMode := False;
  FLastCommitTime := 0;
  FOnNavigate := nil;
  FOnModeChange := nil;

  FEntry := TFtPathBarEntry.Create(Self);
  SetPath(APath);
end;

destructor TFtPathBar.Destroy();
begin
  SetLength(FSegments, 0);
  inherited Destroy();
end;

function TFtPathBar.GetElementType(): string;
begin
  Result := 'pathbar';
end;

procedure TFtPathBar.SetPath(const AValue: string);
begin
  FPath := AValue;
  if Assigned(FEntry) and not FSwitchingMode then
    FEntry.Text := FPath;
  ParsePath(FPath);
  Invalidate();
end;

procedure TFtPathBar.SetMode(AValue: TFtPathBarMode);
begin
  if FMode <> AValue then
  begin
    FSwitchingMode := True;
    try
      FMode := AValue;
      if FMode = pbmEdit then
      begin
        UpdateEntryBounds();
        FEntry.Text := FPath;
        FEntry.Visible := True;
        FEntry.SelectAll();
        FEntry.SetFocus();
      end
      else
      begin
        FEntry.Visible := False;
        FEntry.KillFocus();
        ParsePath(FPath);
      end;
    finally
      FSwitchingMode := False;
    end;
    Invalidate();
    if Assigned(FOnModeChange) then
      FOnModeChange(Self, cint32(FMode), FUserData);
  end;
end;

procedure TFtPathBar.SetShowEditButton(AValue: Boolean);
begin
  if FShowEditButton <> AValue then
  begin
    FShowEditButton := AValue;
    UpdateEntryBounds();
    Invalidate();
  end;
end;

procedure TFtPathBar.SetRootDisplayName(const AValue: string);
begin
  if FRootDisplayName <> AValue then
  begin
    FRootDisplayName := AValue;
    ParsePath(FPath);
    Invalidate();
  end;
end;

procedure TFtPathBar.ParsePath(const APath: string);
var
  cleanPath: string;
  isAbsoluteUnix: Boolean;
  isWindowsDrive: Boolean;
  sep: Char;
  parts: TStringList;
  i: Integer;
  accum: string;
  segName, segFull: string;
  rootLabel: string;
begin
  SetLength(FSegments, 0);
  if APath = '' then Exit;

  cleanPath := APath;
  if Pos('\', cleanPath) > 0 then
    sep := '\'
  else
    sep := '/';

  isAbsoluteUnix := (cleanPath <> '') and (cleanPath[1] = '/');
  isWindowsDrive := (Length(cleanPath) >= 2) and (cleanPath[2] = ':');

  // Strip trailing slash unless root
  while (Length(cleanPath) > 1) and ((cleanPath[Length(cleanPath)] = '/') or (cleanPath[Length(cleanPath)] = '\')) do
  begin
    if isWindowsDrive and (Length(cleanPath) = 3) then Break;
    Delete(cleanPath, Length(cleanPath), 1);
  end;

  if cleanPath = '' then Exit;

  if FRootDisplayName <> '' then
    rootLabel := FRootDisplayName
  else
    rootLabel := '/';

  parts := TStringList.Create();
  try
    parts.StrictDelimiter := True;
    parts.Delimiter := sep;
    if sep = '\' then
      parts.DelimitedText := StringReplace(cleanPath, '/', '\', [rfReplaceAll])
    else
      parts.DelimitedText := StringReplace(cleanPath, '\', '/', [rfReplaceAll]);

    if isAbsoluteUnix then
    begin
      // Root segment
      SetLength(FSegments, 1);
      FSegments[0].Name := rootLabel;
      FSegments[0].FullPath := '/';
      FSegments[0].IsEllipsis := False;
      FSegments[0].IsVisible := True;

      accum := '';
      for i := 0 to parts.Count - 1 do
      begin
        if parts[i] <> '' then
        begin
          accum := accum + '/' + parts[i];
          SetLength(FSegments, Length(FSegments) + 1);
          FSegments[High(FSegments)].Name := parts[i];
          FSegments[High(FSegments)].FullPath := accum;
          FSegments[High(FSegments)].IsEllipsis := False;
          FSegments[High(FSegments)].IsVisible := True;
        end;
      end;
    end
    else if isWindowsDrive then
    begin
      accum := '';
      for i := 0 to parts.Count - 1 do
      begin
        if parts[i] <> '' then
        begin
          if accum = '' then
          begin
            accum := parts[i] + sep;
            segName := parts[i];
            segFull := accum;
          end
          else
          begin
            if (accum[Length(accum)] <> '\') and (accum[Length(accum)] <> '/') then
              accum := accum + sep + parts[i]
            else
              accum := accum + parts[i];
            segName := parts[i];
            segFull := accum;
          end;
          SetLength(FSegments, Length(FSegments) + 1);
          FSegments[High(FSegments)].Name := segName;
          FSegments[High(FSegments)].FullPath := segFull;
          FSegments[High(FSegments)].IsEllipsis := False;
          FSegments[High(FSegments)].IsVisible := True;
        end;
      end;
    end
    else
    begin
      // Relative or tilde path
      accum := '';
      for i := 0 to parts.Count - 1 do
      begin
        if parts[i] <> '' then
        begin
          if accum = '' then
            accum := parts[i]
          else
            accum := accum + sep + parts[i];
          SetLength(FSegments, Length(FSegments) + 1);
          FSegments[High(FSegments)].Name := parts[i];
          FSegments[High(FSegments)].FullPath := accum;
          FSegments[High(FSegments)].IsEllipsis := False;
          FSegments[High(FSegments)].IsVisible := True;
        end;
      end;
    end;
  finally
    parts.Free();
  end;
end;

procedure TFtPathBar.UpdateEntryBounds();
var
  availW: Double;
begin
  if Assigned(FEntry) then
  begin
    FEntry.X := Round(X + FPaddingX);
    FEntry.Y := Round(Y + FPaddingY);
    availW := Width - (FPaddingX * 2.0);
    if FShowEditButton then
      availW := availW - FEditButtonWidth - 4.0;
    FEntry.Width := Math.Max(0, Round(availW));
    FEntry.Height := Math.Max(0, Round(Height - (FPaddingY * 2.0)));
  end;
end;

function TFtPathBar.GetToggleRect(out AX, AY, AW, AH: Double): Boolean;
var
  pillH: Double;
begin
  if not FShowEditButton then
  begin
    AX := 0.0; AY := 0.0; AW := 0.0; AH := 0.0;
    Exit(False);
  end;
  pillH := Math.Max(16.0, Height - (FPaddingY * 2.0));
  AW := FEditButtonWidth;
  AH := pillH;
  AX := X + Width - FPaddingX - AW;
  AY := Y + (Height - pillH) / 2.0;
  Result := True;
end;

procedure TFtPathBar.ComputeLayout();
const
  CHEVRON_SPACING = 14.0;
  PILL_PAD_X = 8.0;
var
  fnt: TFtFont;
  availW, curX, pillH, pillY, textW: Double;
  i, count, tailStart: Integer;
  segW: array of Double;
  totalW: Double;
  ellipsisW: Double;
  usedW: Double;
begin
  count := Length(FSegments);
  if count = 0 then Exit;

  fnt := GetFont();
  if not Assigned(fnt) then
    fnt := FtGetSystemFont();

  pillH := Math.Max(16.0, Height - (FPaddingY * 2.0));
  pillY := Y + (Height - pillH) / 2.0;

  availW := Width - (FPaddingX * 2.0);
  if FShowEditButton then
    availW := availW - FEditButtonWidth - 4.0;

  SetLength(segW, count);
  totalW := 0.0;
  for i := 0 to count - 1 do
  begin
    textW := fnt.GetTextWidth(FSegments[i].Name);
    segW[i] := textW + (PILL_PAD_X * 2.0);
    totalW := totalW + segW[i];
    if i < count - 1 then
      totalW := totalW + CHEVRON_SPACING;
    FSegments[i].Height := pillH;
    FSegments[i].Y := pillY;
    FSegments[i].IsVisible := True;
    FSegments[i].IsEllipsis := False;
  end;

  ellipsisW := fnt.GetTextWidth('…') + (PILL_PAD_X * 2.0);

  // If segments fit entirely, assign sequential X coordinates
  if totalW <= availW then
  begin
    curX := X + FPaddingX;
    for i := 0 to count - 1 do
    begin
      FSegments[i].X := curX;
      FSegments[i].Width := segW[i];
      curX := curX + segW[i] + CHEVRON_SPACING;
    end;
    Exit;
  end;

  // Overflow handling: keep root segment (0), insert ellipsis, then fit tail segments
  // First, mark all middle segments invisible
  for i := 1 to count - 1 do
    FSegments[i].IsVisible := False;

  curX := X + FPaddingX;
  FSegments[0].X := curX;
  FSegments[0].Width := segW[0];
  FSegments[0].IsVisible := True;

  usedW := segW[0] + CHEVRON_SPACING + ellipsisW + CHEVRON_SPACING;
  tailStart := count;

  // Work backwards from leaf to fit as many tail segments as possible
  for i := count - 1 downto 1 do
  begin
    if (usedW + segW[i] + CHEVRON_SPACING <= availW) or (i = count - 1) then
    begin
      usedW := usedW + segW[i] + CHEVRON_SPACING;
      tailStart := i;
    end
    else
      Break;
  end;

  // Position ellipsis segment after segment 0
  if tailStart > 1 then
  begin
    curX := curX + segW[0] + CHEVRON_SPACING;
    // We repurpose segment 1 as ellipsis if tailStart > 1
    FSegments[1].Name := '…';
    FSegments[1].FullPath := '';
    FSegments[1].X := curX;
    FSegments[1].Width := ellipsisW;
    FSegments[1].Height := pillH;
    FSegments[1].Y := pillY;
    FSegments[1].IsVisible := True;
    FSegments[1].IsEllipsis := True;
    curX := curX + ellipsisW + CHEVRON_SPACING;
  end
  else
    curX := curX + segW[0] + CHEVRON_SPACING;

  // Position visible tail segments
  for i := tailStart to count - 1 do
  begin
    FSegments[i].X := curX;
    FSegments[i].Width := segW[i];
    FSegments[i].IsVisible := True;
    curX := curX + segW[i] + CHEVRON_SPACING;
  end;
end;

function TFtPathBar.HitTestSegment(AX, AY: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;
  if FMode <> pbmBreadcrumbs then Exit;
  for i := 0 to High(FSegments) do
  begin
    if FSegments[i].IsVisible and
       (AX >= FSegments[i].X) and (AX <= FSegments[i].X + FSegments[i].Width) and
       (AY >= FSegments[i].Y) and (AY <= FSegments[i].Y + FSegments[i].Height) then
      Exit(i);
  end;
end;

function TFtPathBar.IsOverEmptyArea(AX, AY: Integer): Boolean;
var
  lastX: Double;
  i: Integer;
  togX, togY, togW, togH: Double;
begin
  Result := False;
  if FMode <> pbmBreadcrumbs then Exit;

  // If outside path bar bounds, not empty area
  if (AX < X) or (AX > X + Width) or (AY < Y) or (AY > Y + Height) then Exit;

  // Check if over toggle button
  if GetToggleRect(togX, togY, togW, togH) then
  begin
    if (AX >= togX) and (AX <= togX + togW) and (AY >= togY) and (AY <= togY + togH) then
      Exit(False);
  end;

  // Find rightmost edge of visible segments
  lastX := X + FPaddingX;
  for i := 0 to High(FSegments) do
  begin
    if FSegments[i].IsVisible then
      lastX := Math.Max(lastX, FSegments[i].X + FSegments[i].Width);
  end;

  // If AX is past last segment and before toggle button
  Result := (AX > lastX);
end;

function TFtPathBar.GetCursor(): Integer;
var
  togX, togY, togW, togH: Double;
  rootWin: TFtWidget;
begin
  if FMode = pbmBreadcrumbs then
  begin
    if FHoverToggle then
      Exit(FT_CURSOR_HAND);
    if FHoverSegment >= 0 then
      Exit(FT_CURSOR_HAND);
    // Over empty breadcrumbs area -> I-beam cursor signals text entry on click!
    Exit(FT_CURSOR_IBEAM);
  end;

  if FHoverToggle then
    Exit(FT_CURSOR_HAND);

  Result := FT_CURSOR_DEFAULT;
end;

procedure TFtPathBar.MouseMove(AX, AY: Integer);
var
  oldHoverSeg: Integer;
  oldHoverTog: Boolean;
  togX, togY, togW, togH: Double;
begin
  inherited MouseMove(AX, AY);

  oldHoverSeg := FHoverSegment;
  oldHoverTog := FHoverToggle;

  // Check toggle button
  if GetToggleRect(togX, togY, togW, togH) and
     (AX >= togX) and (AX <= togX + togW) and (AY >= togY) and (AY <= togY + togH) then
  begin
    FHoverToggle := True;
    FHoverSegment := -1;
  end
  else
  begin
    FHoverToggle := False;
    if FMode = pbmBreadcrumbs then
      FHoverSegment := HitTestSegment(AX, AY)
    else
      FHoverSegment := -1;
  end;

  if (oldHoverSeg <> FHoverSegment) or (oldHoverTog <> FHoverToggle) then
    Invalidate();
end;

procedure TFtPathBar.MouseLeave();
begin
  inherited MouseLeave();
  if (FHoverSegment <> -1) or FHoverToggle then
  begin
    FHoverSegment := -1;
    FHoverToggle := False;
    Invalidate();
  end;
end;

procedure TFtPathBar.MouseDown(AX, AY: Integer; AButton: Integer);
var
  togX, togY, togW, togH: Double;
begin
  inherited MouseDown(AX, AY, AButton);

  if AButton <> 1 then Exit;

  // Toggle button clicked
  if GetToggleRect(togX, togY, togW, togH) and
     (AX >= togX) and (AX <= togX + togW) and (AY >= togY) and (AY <= togY + togH) then
  begin
    // Guard against immediate re-toggle if LostFocus just fired
    if (GetTickCount64() - FLastCommitTime < 120) then Exit;
    FPressedToggle := True;
    if FMode = pbmBreadcrumbs then
      SetMode(pbmEdit)
    else
      CommitEdit();
    Exit;
  end;

  if FMode = pbmBreadcrumbs then
  begin
    FHoverSegment := HitTestSegment(AX, AY);
    if FHoverSegment >= 0 then
    begin
      FPressedSegment := FHoverSegment;
      Invalidate();
    end
    else
    begin
      // Clicked on empty area: switch immediately to text edit mode!
      SetMode(pbmEdit);
    end;
  end;
end;

procedure TFtPathBar.MouseUp(AX, AY: Integer; AButton: Integer);
begin
  inherited MouseUp(AX, AY, AButton);

  if AButton <> 1 then Exit;
  FPressedToggle := False;

  if (FMode = pbmBreadcrumbs) and (FPressedSegment >= 0) then
  begin
    if FPressedSegment = FHoverSegment then
    begin
      if FSegments[FPressedSegment].IsEllipsis then
        SetMode(pbmEdit)
      else
        NavigateTo(FSegments[FPressedSegment].FullPath);
    end;
    FPressedSegment := -1;
    Invalidate();
  end;
end;

procedure TFtPathBar.KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string);
const
  ControlMask = 4;
var
  hasCtrl: Boolean;
begin
  hasCtrl := (AState and ControlMask) <> 0;

  // Ctrl+L: switch to edit mode & select all (standard browser & Nautilus shortcut)
  if hasCtrl and ((AKeySym = $6C) or (AKeySym = $4C)) then
  begin
    SetMode(pbmEdit);
    Exit;
  end;

  inherited KeyDown(AKeySym, AState, AChar);
end;

procedure TFtPathBar.NavigateTo(const APath: string);
begin
  SetPath(APath);
  if Assigned(FOnNavigate) then
    FOnNavigate(Self, PChar(FPath), FUserData);
end;

procedure TFtPathBar.CommitEdit();
var
  newPath: string;
begin
  FLastCommitTime := GetTickCount64();
  if FMode = pbmEdit then
  begin
    newPath := Trim(FEntry.Text);
    if newPath <> '' then
      FPath := newPath;
    SetMode(pbmBreadcrumbs);
    if Assigned(FOnNavigate) then
      FOnNavigate(Self, PChar(FPath), FUserData);
  end;
end;

procedure TFtPathBar.CancelEdit();
begin
  FLastCommitTime := GetTickCount64();
  if FMode = pbmEdit then
  begin
    FEntry.Text := FPath;
    SetMode(pbmBreadcrumbs);
  end;
end;

procedure TFtPathBar.DrawBreadcrumbs(Canvas: TFtCanvasAgg);
var
  i, count: Integer;
  fnt: TFtFont;
  curTheme: TFtTheme;
  txtCol: TFtRgbColor;
  accentCol: TFtRgbColor;
  pillRad: Double;
  textW, textX, textY: Double;
  chevX, chevY: Double;
  isLeaf: Boolean;
  isDark: Boolean;
  bgAlpha: Double;
  isPressed, isHovered: Boolean;
begin
  count := Length(FSegments);
  if count = 0 then Exit;

  curTheme := FtGetTheme();
  isDark := curTheme.DarkMode;
  txtCol := curTheme.GetTextColor();
  accentCol := curTheme.GetAccentColor();
  fnt := GetFont();
  if not Assigned(fnt) then
    fnt := FtGetSystemFont();

  pillRad := Math.Min(4.0, (Height - FPaddingY * 2.0) / 2.0);

  for i := 0 to count - 1 do
  begin
    if not FSegments[i].IsVisible then Continue;

    isLeaf := (i = count - 1);
    isHovered := (i = FHoverSegment);
    isPressed := (i = FPressedSegment);

    // Pill background on hover/press
    if isPressed then
    begin
      if isDark then
        Canvas.DrawRoundedRect(FSegments[i].X, FSegments[i].Y, FSegments[i].Width, FSegments[i].Height, pillRad, 1.0, 1.0, 1.0, 0.22)
      else
        Canvas.DrawRoundedRect(FSegments[i].X, FSegments[i].Y, FSegments[i].Width, FSegments[i].Height, pillRad, 0.0, 0.0, 0.0, 0.16);
    end
    else if isHovered then
    begin
      if isDark then
        Canvas.DrawRoundedRect(FSegments[i].X, FSegments[i].Y, FSegments[i].Width, FSegments[i].Height, pillRad, 1.0, 1.0, 1.0, 0.12)
      else
        Canvas.DrawRoundedRect(FSegments[i].X, FSegments[i].Y, FSegments[i].Width, FSegments[i].Height, pillRad, 0.0, 0.0, 0.0, 0.08);
    end;

    // Segment text
    textW := fnt.GetTextWidth(FSegments[i].Name);
    textX := FSegments[i].X + (FSegments[i].Width - textW) / 2.0;
    textY := Y + (Height / 2.0) + (fnt.Ascent - fnt.Descent) / 2.0;

    if isLeaf then
    begin
      // Current active directory: high contrast text
      Canvas.DrawText(textX, textY, FSegments[i].Name, fnt, txtCol.R, txtCol.G, txtCol.B);
    end
    else
    begin
      // Parent directory: slightly muted text
      Canvas.PushAlpha(0.80);
      try
        Canvas.DrawText(textX, textY, FSegments[i].Name, fnt, txtCol.R, txtCol.G, txtCol.B);
      finally
        Canvas.PopAlpha();
      end;

      // Antialiased chevron separator ›
      chevX := FSegments[i].X + FSegments[i].Width + 7.0;
      chevY := Y + (Height / 2.0);
      Canvas.DrawLine(chevX - 2.5, chevY - 4.0, chevX + 1.5, chevY, 1.5, txtCol.R, txtCol.G, txtCol.B, 0.40);
      Canvas.DrawLine(chevX + 1.5, chevY, chevX - 2.5, chevY + 4.0, 1.5, txtCol.R, txtCol.G, txtCol.B, 0.40);
    end;
  end;
end;

procedure TFtPathBar.DrawToggleButton(Canvas: TFtCanvasAgg);
var
  togX, togY, togW, togH: Double;
  midX, midY: Double;
  curTheme: TFtTheme;
  txtCol: TFtRgbColor;
  isDark: Boolean;
  pillRad: Double;
begin
  if not GetToggleRect(togX, togY, togW, togH) then Exit;

  curTheme := FtGetTheme();
  isDark := curTheme.DarkMode;
  txtCol := curTheme.GetTextColor();
  pillRad := Math.Min(4.0, togH / 2.0);

  if FHoverToggle then
  begin
    if isDark then
      Canvas.DrawRoundedRect(togX, togY, togW, togH, pillRad, 1.0, 1.0, 1.0, 0.12)
    else
      Canvas.DrawRoundedRect(togX, togY, togW, togH, pillRad, 0.0, 0.0, 0.0, 0.08);
  end;

  midX := togX + (togW / 2.0);
  midY := togY + (togH / 2.0);

  if FMode = pbmBreadcrumbs then
  begin
    // Edit icon: clean, unmistakable slanted vector pencil
    // 1. Conical tip & graphite point
    Canvas.DrawLine(midX - 5.0, midY + 5.0, midX - 5.0, midY + 2.0, 1.3, txtCol.R, txtCol.G, txtCol.B, 0.75);
    Canvas.DrawLine(midX - 5.0, midY + 5.0, midX - 2.0, midY + 5.0, 1.3, txtCol.R, txtCol.G, txtCol.B, 0.75);
    Canvas.DrawLine(midX - 5.0, midY + 2.0, midX - 2.0, midY + 5.0, 1.2, txtCol.R, txtCol.G, txtCol.B, 0.60);
    Canvas.DrawLine(midX - 5.0, midY + 5.0, midX - 3.8, midY + 3.8, 1.6, txtCol.R, txtCol.G, txtCol.B, 0.90);

    // 2. Shaft sides
    Canvas.DrawLine(midX - 5.0, midY + 2.0, midX + 2.0, midY - 5.0, 1.3, txtCol.R, txtCol.G, txtCol.B, 0.75);
    Canvas.DrawLine(midX - 2.0, midY + 5.0, midX + 5.0, midY - 2.0, 1.3, txtCol.R, txtCol.G, txtCol.B, 0.75);

    // 3. Top end & eraser band
    Canvas.DrawLine(midX + 2.0, midY - 5.0, midX + 5.0, midY - 2.0, 1.3, txtCol.R, txtCol.G, txtCol.B, 0.75);
    Canvas.DrawLine(midX + 0.6, midY - 3.6, midX + 3.6, midY - 0.6, 1.0, txtCol.R, txtCol.G, txtCol.B, 0.50);
  end
  else
  begin
    // Breadcrumbs icon: two small connected breadcrumb dots/pills ▪›▪
    Canvas.DrawRoundedRect(midX - 6.0, midY - 2.5, 4.0, 5.0, 1.0, txtCol.R, txtCol.G, txtCol.B, 0.70);
    Canvas.DrawLine(midX - 0.5, midY - 2.5, midX + 1.5, midY, 1.2, txtCol.R, txtCol.G, txtCol.B, 0.60);
    Canvas.DrawLine(midX + 1.5, midY, midX - 0.5, midY + 2.5, 1.2, txtCol.R, txtCol.G, txtCol.B, 0.60);
    Canvas.DrawRoundedRect(midX + 3.5, midY - 2.5, 4.0, 5.0, 1.0, txtCol.R, txtCol.G, txtCol.B, 0.70);
  end;
end;

procedure TFtPathBar.DrawContent(Canvas: TFtCanvasAgg);
begin
  inherited DrawContent(Canvas);

  UpdateEntryBounds();

  if FMode = pbmBreadcrumbs then
  begin
    ComputeLayout();
    DrawBreadcrumbs(Canvas);
  end;

  DrawToggleButton(Canvas);
end;

end.
