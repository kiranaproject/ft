unit Ft.Widget.Tabs;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Math,
  Floria.Image.Core, Ft.Canvas, Floria.Font, Ft.Widget, Ft.Widget.Containers, Ft.Widget.Buttons, Ft.Theme, Ft.Css;

type
  TFtTabPage = class;
  TFtNotebook = class;

  TFtTabChangeEvent = procedure(Sender: TObject; NewIndex, OldIndex: Integer) of object;
  TFtTabCloseEvent = procedure(Sender: TObject; TabIndex: Integer; var CanClose: Boolean) of object;
  TFtTabClickCallback = procedure(Sender: Pointer; NewIndex, OldIndex: Integer; UserData: Pointer); cdecl;

  TFtTabPage = class(TFtContainer)
  private
    FTitle: string;
    FCloseable: Boolean;
    FIcon: TFloriaImage;
    FNotebook: TFtNotebook;
    procedure SetTitle(const AValue: string);
    procedure SetCloseable(AValue: Boolean);
    procedure SetIcon(AValue: TFloriaImage);
  public
    constructor Create(AParent: TFtWidget); override;
    function GetElementType(): string; override;

    property Title: string read FTitle write SetTitle;
    property Closeable: Boolean read FCloseable write SetCloseable;
    property Icon: TFloriaImage read FIcon write SetIcon;
    property Notebook: TFtNotebook read FNotebook write FNotebook;
  end;

  TFtNotebook = class(TFtWidget)
  private
    FPages: TFPList; // TFtTabPage
    FActiveIndex: Integer;
    FTabHeight: Double;
    FMaxTabWidth: Double;
    FMinTabWidth: Double;
    FScrollOffset: Double;
    FMaxScrollOffset: Double;
    FScrollButtonsVisible: Boolean;
    FHoveredScrollButton: Integer; // 0=none, 1=left, 2=right
    FPressedScrollButton: Integer; // 0=none, 1=left, 2=right
    FHoveredIndex: Integer;
    FHoveredClose: Boolean;
    FPressedCloseIndex: Integer;
    FOnTabChange: TFtTabChangeEvent;
    FOnTabClose: TFtTabCloseEvent;
    FOnTabChangeCb: TFtTabClickCallback;
    FUserData: Pointer;

    procedure SetActiveIndex(AValue: Integer);
    procedure SetTabHeight(AValue: Double);
    procedure SetMaxTabWidth(AValue: Double);
    procedure SetMinTabWidth(AValue: Double);
    procedure SetScrollOffset(AValue: Double);
    function GetPageCount(): Integer;
    function GetTotalTabsWidth(): Double;
    procedure GetTabsArea(out AX, AW: Double);
    function ScrollButtonAt(AX, AY: Integer): Integer;
  protected
    procedure DrawTabStrip(Canvas: TFtCanvas); virtual;
  public
    constructor Create(AParent: TFtWidget); override;
    destructor Destroy(); override;
    function GetElementType(): string; override;
    function GetEffectiveHint(): string; override;

    function CalculateTabWidth(AIndex: Integer): Double;
    function GetTabRect(AIndex: Integer; out RX, RY, RW, RH: Double): Boolean;
    function GetCloseButtonRect(AIndex: Integer; out CX, CY, CW, CH: Double): Boolean;
    function GetLeftScrollButtonRect(out BX, BY, BW, BH: Double): Boolean;
    function GetRightScrollButtonRect(out BX, BY, BW, BH: Double): Boolean;
    function TabIndexAt(AX, AY: Integer; out InCloseBtn: Boolean): Integer;

    procedure UpdateScrollLimits();
    procedure ScrollBy(ADelta: Double);
    procedure EnsureTabVisible(AIndex: Integer);

    procedure UpdateLayout(); override;
    procedure SetBounds(AX, AY, AW, AH: Integer); override;
    function GetPage(AIndex: Integer): TFtTabPage;
    function AddTab(const ATitle: string; ACloseable: Boolean = False): TFtTabPage;
    procedure RemoveTab(AIndex: Integer; FreePage: Boolean = True);
    procedure ClearTabs();

    procedure Draw(Canvas: TFtCanvas); override;
    function HitTest(AX, AY: Integer): TFtWidget; override;
    procedure MouseDown(AX, AY: Integer; AButton: Integer); override;
    procedure MouseUp(AX, AY: Integer; AButton: Integer); override;
    procedure MouseMove(AX, AY: Integer); override;
    procedure MouseLeave(); override;
    procedure KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string); override;

    property ActiveIndex: Integer read FActiveIndex write SetActiveIndex;
    property PageCount: Integer read GetPageCount;
    property Pages[AIndex: Integer]: TFtTabPage read GetPage;
    property TabHeight: Double read FTabHeight write SetTabHeight;
    property MaxTabWidth: Double read FMaxTabWidth write SetMaxTabWidth;
    property MinTabWidth: Double read FMinTabWidth write SetMinTabWidth;
    property ScrollOffset: Double read FScrollOffset write SetScrollOffset;
    property MaxScrollOffset: Double read FMaxScrollOffset;
    property ScrollButtonsVisible: Boolean read FScrollButtonsVisible;
    property OnTabChange: TFtTabChangeEvent read FOnTabChange write FOnTabChange;
    property OnTabClose: TFtTabCloseEvent read FOnTabClose write FOnTabClose;
    property OnTabChangeCb: TFtTabClickCallback read FOnTabChangeCb write FOnTabChangeCb;
    property UserData: Pointer read FUserData write FUserData;
  end;

implementation

{ TFtTabPage }

constructor TFtTabPage.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FTitle := 'Tab';
  FCloseable := False;
  FIcon := nil;
  FNotebook := nil;
  FDrawFrame := False;
  FPaddingX := 0.0;
  FPaddingY := 0.0;
end;

function TFtTabPage.GetElementType(): string;
begin
  Result := 'tabpage';
end;

procedure TFtTabPage.SetTitle(const AValue: string);
begin
  if FTitle <> AValue then
  begin
    FTitle := AValue;
    if Assigned(FNotebook) then
      FNotebook.Invalidate();
  end;
end;

procedure TFtTabPage.SetCloseable(AValue: Boolean);
begin
  if FCloseable <> AValue then
  begin
    FCloseable := AValue;
    if Assigned(FNotebook) then
      FNotebook.Invalidate();
  end;
end;

procedure TFtTabPage.SetIcon(AValue: TFloriaImage);
begin
  if FIcon <> AValue then
  begin
    FIcon := AValue;
    if Assigned(FNotebook) then
      FNotebook.Invalidate();
  end;
end;

{ TFtNotebook }

constructor TFtNotebook.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FPages := TFPList.Create();
  FActiveIndex := -1;
  FTabHeight := 36.0;
  FMaxTabWidth := 200.0;
  FMinTabWidth := 70.0;
  FScrollOffset := 0.0;
  FMaxScrollOffset := 0.0;
  FScrollButtonsVisible := False;
  FHoveredScrollButton := 0;
  FPressedScrollButton := 0;
  FHoveredIndex := -1;
  FHoveredClose := False;
  FPressedCloseIndex := -1;
  FFocusable := True;
end;

destructor TFtNotebook.Destroy();
begin
  ClearTabs();
  FPages.Free();
  inherited Destroy();
end;

function TFtNotebook.GetElementType(): string;
begin
  Result := 'notebook';
end;

function TFtNotebook.GetEffectiveHint(): string;
var
  page: TFtTabPage;
  rx, ry, rw, rh, twText: Double;
  fnt: TFtFont;
begin
  if not FShowHint or not Visible then Exit('');
  if (FHoveredIndex >= 0) and (FHoveredIndex < FPages.Count) then
  begin
    if FHoveredClose then
      Exit('Close Tab');
    page := GetPage(FHoveredIndex);
    if Assigned(page) then
    begin
      if page.Hint <> '' then
        Exit(page.Hint);
      fnt := Font;
      if not Assigned(fnt) then fnt := FtGetSystemFont();
      if Assigned(fnt) then
        twText := fnt.GetTextWidth(page.Title)
      else
        twText := Length(page.Title) * 8.5;
      if GetTabRect(FHoveredIndex, rx, ry, rw, rh) then
      begin
        if (rx + rw > X + Width) or (rw < twText + 20.0) then
          Exit(page.Title);
      end;
    end;
  end;
  Result := inherited GetEffectiveHint();
end;

function TFtNotebook.GetPageCount(): Integer;
begin
  Result := FPages.Count;
end;

function TFtNotebook.GetPage(AIndex: Integer): TFtTabPage;
begin
  if (AIndex >= 0) and (AIndex < FPages.Count) then
    Result := TFtTabPage(FPages[AIndex])
  else
    Result := nil;
end;

procedure TFtNotebook.SetBounds(AX, AY, AW, AH: Integer);
begin
  inherited SetBounds(AX, AY, AW, AH);
  UpdateLayout();
end;

procedure TFtNotebook.SetMaxTabWidth(AValue: Double);
begin
  if AValue < 0.0 then AValue := 0.0;
  if FMaxTabWidth <> AValue then
  begin
    FMaxTabWidth := AValue;
    UpdateScrollLimits();
    Invalidate();
  end;
end;

procedure TFtNotebook.SetMinTabWidth(AValue: Double);
begin
  if AValue < 20.0 then AValue := 20.0;
  if FMinTabWidth <> AValue then
  begin
    FMinTabWidth := AValue;
    UpdateScrollLimits();
    Invalidate();
  end;
end;

procedure TFtNotebook.SetScrollOffset(AValue: Double);
begin
  UpdateScrollLimits();
  if AValue < 0.0 then AValue := 0.0;
  if AValue > FMaxScrollOffset then AValue := FMaxScrollOffset;
  if FScrollOffset <> AValue then
  begin
    FScrollOffset := AValue;
    Invalidate();
  end;
end;

procedure TFtNotebook.ScrollBy(ADelta: Double);
begin
  SetScrollOffset(FScrollOffset + ADelta);
end;

function TFtNotebook.CalculateTabWidth(AIndex: Integer): Double;
var
  page: TFtTabPage;
  fnt: TFtFont;
  twText: Double;
begin
  Result := FMinTabWidth;
  if (AIndex < 0) or (AIndex >= FPages.Count) then Exit;
  page := TFtTabPage(FPages[AIndex]);
  if Assigned(Font) then fnt := Font else fnt := FtGetSystemFont();

  if Assigned(fnt) then
    twText := fnt.GetTextWidth(page.Title)
  else
    twText := Length(page.Title) * 8.5;

  Result := Math.Max(FMinTabWidth, twText + 28.0);
  if page.Closeable then
    Result := Result + 22.0;

  if (FMaxTabWidth > 0.0) and (Result > FMaxTabWidth) then
    Result := Math.Max(FMinTabWidth, FMaxTabWidth);
end;

function TFtNotebook.GetTotalTabsWidth(): Double;
var
  i: Integer;
begin
  Result := 0.0;
  for i := 0 to FPages.Count - 1 do
    Result := Result + CalculateTabWidth(i) + 4.0;
end;

procedure TFtNotebook.GetTabsArea(out AX, AW: Double);
begin
  AX := X + 4.0;
  if FScrollButtonsVisible then
    AW := Math.Max(50.0, Width - 8.0 - 48.0)
  else
    AW := Math.Max(50.0, Width - 8.0);
end;

procedure TFtNotebook.UpdateScrollLimits();
var
  totalW, availW, tabsAreaX, tabsAreaW: Double;
begin
  totalW := GetTotalTabsWidth();
  availW := Width - 8.0;
  if (Width > 0) and (totalW > availW) then
  begin
    FScrollButtonsVisible := True;
    tabsAreaW := Math.Max(50.0, availW - 48.0);
    FMaxScrollOffset := Math.Max(0.0, totalW - tabsAreaW);
  end
  else
  begin
    FScrollButtonsVisible := False;
    FMaxScrollOffset := 0.0;
    FScrollOffset := 0.0;
  end;

  if FScrollOffset > FMaxScrollOffset then
    FScrollOffset := FMaxScrollOffset;
  if FScrollOffset < 0.0 then
    FScrollOffset := 0.0;
end;

procedure TFtNotebook.EnsureTabVisible(AIndex: Integer);
var
  i: Integer;
  curX, tabW, tabsAreaX, tabsAreaW: Double;
  tabLeft, tabRight: Double;
begin
  if (AIndex < 0) or (AIndex >= FPages.Count) then Exit;
  UpdateScrollLimits();
  if not FScrollButtonsVisible then Exit;

  GetTabsArea(tabsAreaX, tabsAreaW);

  curX := 0.0;
  for i := 0 to AIndex - 1 do
    curX := curX + CalculateTabWidth(i) + 4.0;
  tabW := CalculateTabWidth(AIndex);
  tabLeft := curX;
  tabRight := curX + tabW;

  if tabLeft < FScrollOffset then
    SetScrollOffset(tabLeft)
  else if tabRight > FScrollOffset + tabsAreaW then
    SetScrollOffset(tabRight - tabsAreaW);
end;

procedure TFtNotebook.UpdateLayout();
var
  i: Integer;
  page: TFtTabPage;
  headerH, pageX, pageY, pageW, pageH: Integer;
begin
  UpdateScrollLimits();
  headerH := Round(FTabHeight);
  pageX := X;
  pageY := Y + headerH;
  pageW := Width;
  pageH := Height - headerH;
  if pageH < 0 then pageH := 0;

  for i := 0 to FPages.Count - 1 do
  begin
    page := TFtTabPage(FPages[i]);
    page.SetBounds(pageX, pageY, pageW, pageH);
    page.Visible := (i = FActiveIndex);
  end;
  Invalidate();
end;

function TFtNotebook.GetTabRect(AIndex: Integer; out RX, RY, RW, RH: Double): Boolean;
var
  i: Integer;
  curX: Double;
  tabW: Double;
begin
  Result := False;
  if (AIndex < 0) or (AIndex >= FPages.Count) then Exit;

  UpdateScrollLimits();
  curX := X + 4.0 - FScrollOffset;
  for i := 0 to FPages.Count - 1 do
  begin
    tabW := CalculateTabWidth(i);
    if i = AIndex then
    begin
      RX := curX;
      RY := Y;
      RW := tabW;
      RH := FTabHeight;
      Exit(True);
    end;
    curX := curX + tabW + 4.0;
  end;
end;

function TFtNotebook.GetCloseButtonRect(AIndex: Integer; out CX, CY, CW, CH: Double): Boolean;
var
  tx, ty, tw, th: Double;
  page: TFtTabPage;
begin
  Result := False;
  if not GetTabRect(AIndex, tx, ty, tw, th) then Exit;
  page := GetPage(AIndex);
  if not Assigned(page) or not page.Closeable then Exit;

  CW := 18.0;
  CH := 18.0;
  CX := tx + tw - 24.0;
  CY := ty + (th - CH) * 0.5;
  Result := True;
end;

function TFtNotebook.GetLeftScrollButtonRect(out BX, BY, BW, BH: Double): Boolean;
begin
  if not FScrollButtonsVisible then Exit(False);
  BW := 20.0;
  BH := 20.0;
  BX := X + Width - 46.0;
  BY := Y + (FTabHeight - BH) * 0.5;
  Result := True;
end;

function TFtNotebook.GetRightScrollButtonRect(out BX, BY, BW, BH: Double): Boolean;
begin
  if not FScrollButtonsVisible then Exit(False);
  BW := 20.0;
  BH := 20.0;
  BX := X + Width - 23.0;
  BY := Y + (FTabHeight - BH) * 0.5;
  Result := True;
end;

function TFtNotebook.ScrollButtonAt(AX, AY: Integer): Integer;
var
  bx, by, bw, bh: Double;
begin
  Result := 0;
  if not FScrollButtonsVisible then Exit;
  if GetLeftScrollButtonRect(bx, by, bw, bh) then
    if (AX >= bx) and (AX <= bx + bw) and (AY >= by) and (AY <= by + bh) then
      Exit(1);
  if GetRightScrollButtonRect(bx, by, bw, bh) then
    if (AX >= bx) and (AX <= bx + bw) and (AY >= by) and (AY <= by + bh) then
      Exit(2);
end;

function TFtNotebook.TabIndexAt(AX, AY: Integer; out InCloseBtn: Boolean): Integer;
var
  i: Integer;
  tx, ty, tw, th, cx, cy, cw, ch: Double;
  tabsAreaX, tabsAreaW: Double;
begin
  InCloseBtn := False;
  Result := -1;
  if (AY < Y) or (AY > Y + FTabHeight) then Exit;

  if ScrollButtonAt(AX, AY) > 0 then Exit;

  GetTabsArea(tabsAreaX, tabsAreaW);
  if (AX < tabsAreaX) or (AX > tabsAreaX + tabsAreaW) then Exit;

  for i := 0 to FPages.Count - 1 do
  begin
    if GetTabRect(i, tx, ty, tw, th) then
    begin
      if (AX >= tx) and (AX <= tx + tw) and (AY >= ty) and (AY <= ty + th) then
      begin
        Result := i;
        if GetCloseButtonRect(i, cx, cy, cw, ch) then
        begin
          if (AX >= cx) and (AX <= cx + cw) and (AY >= cy) and (AY <= cy + ch) then
            InCloseBtn := True;
        end;
        Exit;
      end;
    end;
  end;
end;

procedure TFtNotebook.SetActiveIndex(AValue: Integer);
var
  oldIdx: Integer;
begin
  if (AValue < 0) and (FPages.Count > 0) then AValue := 0;
  if AValue >= FPages.Count then AValue := FPages.Count - 1;

  if FActiveIndex <> AValue then
  begin
    oldIdx := FActiveIndex;
    FActiveIndex := AValue;
    UpdateLayout();
    EnsureTabVisible(FActiveIndex);

    if Assigned(FOnTabChange) then
      FOnTabChange(Self, FActiveIndex, oldIdx);
    if Assigned(FOnTabChangeCb) then
      FOnTabChangeCb(Pointer(Self), FActiveIndex, oldIdx, FUserData);
  end;
end;

procedure TFtNotebook.SetTabHeight(AValue: Double);
begin
  if AValue < 20.0 then AValue := 20.0;
  if FTabHeight <> AValue then
  begin
    FTabHeight := AValue;
    UpdateLayout();
  end;
end;

function TFtNotebook.AddTab(const ATitle: string; ACloseable: Boolean = False): TFtTabPage;
begin
  Result := TFtTabPage.Create(Self);
  Result.Title := ATitle;
  Result.Closeable := ACloseable;
  Result.Notebook := Self;
  FPages.Add(Result);

  if FActiveIndex < 0 then
    FActiveIndex := 0;

  UpdateLayout();
  EnsureTabVisible(FActiveIndex);
end;

procedure TFtNotebook.RemoveTab(AIndex: Integer; FreePage: Boolean = True);
var
  page: TFtTabPage;
begin
  if (AIndex < 0) or (AIndex >= FPages.Count) then Exit;
  page := TFtTabPage(FPages[AIndex]);
  FPages.Delete(AIndex);

  if FreePage then
    page.Free();

  if FActiveIndex >= FPages.Count then
    FActiveIndex := FPages.Count - 1;

  UpdateLayout();
  if FActiveIndex >= 0 then
    EnsureTabVisible(FActiveIndex);
end;

procedure TFtNotebook.ClearTabs();
var
  i: Integer;
begin
  for i := 0 to FPages.Count - 1 do
    TFtTabPage(FPages[i]).Free();
  FPages.Clear();
  FActiveIndex := -1;
  FScrollOffset := 0.0;
  FMaxScrollOffset := 0.0;
  FScrollButtonsVisible := False;
  Invalidate();
end;

procedure TFtNotebook.DrawTabStrip(Canvas: TFtCanvas);
var
  theme: TFtTheme;
  i: Integer;
  page: TFtTabPage;
  tx, ty, tw, th, cx, cy, cw, ch: Double;
  isHovered, isCloseHover, isClosePressed: Boolean;
  tabR, tabG, tabB: Double;
  textR, textG, textB: Double;
  borderR, borderG, borderB: Double;
  baseY, rad: Double;
  btnState: TFtButtonState;
  textStartX, textAvailW, iconW, iconH, iconY: Double;
  tabsAreaX, tabsAreaW: Double;
  fitTitle: string;
  bx, by, bw, bh, bgR, bgG, bgB, fgR, fgG, fgB, btnAlpha, arrowCX, arrowCY: Double;
  canScrollLeft, canScrollRight, btnHover, btnPress: Boolean;
begin
  theme := FtGetTheme();
  rad := 6.0;
  baseY := Y + FTabHeight - 1.0;

  // Resolve border palette
  if theme.DarkMode then
  begin
    borderR := 0.20; borderG := 0.25; borderB := 0.33; // #334155
  end
  else
  begin
    borderR := 0.80; borderG := 0.84; borderB := 0.88; // #CBD5E1
  end;

  // 1. Draw continuous baseline divider line across the entire tab strip
  Canvas.DrawLine(X, baseY, X + Width, baseY, 1.0, borderR, borderG, borderB, 1.0);

  UpdateScrollLimits();
  GetTabsArea(tabsAreaX, tabsAreaW);

  // Clip the tab strip to tabsArea to prevent tabs spilling into scroll buttons or window edges
  Canvas.PushClipRect(Round(tabsAreaX), Round(Y), Round(tabsAreaW), Round(FTabHeight + 2.0));
  try
    // 2. Pass 1: Draw Inactive Tabs (sits flush on top of the baseline)
    for i := 0 to FPages.Count - 1 do
    begin
      if i = FActiveIndex then Continue;
      page := TFtTabPage(FPages[i]);
      if not GetTabRect(i, tx, ty, tw, th) then Continue;

      // Cull completely invisible tabs
      if (tx + tw < tabsAreaX) or (tx > tabsAreaX + tabsAreaW) then Continue;

      isHovered := (i = FHoveredIndex) and not FHoveredClose;

      // Inactive tab geometry: sits on baseline
      ty := Y + 2.0;
      th := FTabHeight - 3.0;

      if theme.DarkMode then
      begin
        if isHovered then
        begin
          tabR := 0.18; tabG := 0.20; tabB := 0.26;
          textR := 0.95; textG := 0.96; textB := 0.98;
        end
        else
        begin
          tabR := 0.13; tabG := 0.14; tabB := 0.18;
          textR := 0.58; textG := 0.64; textB := 0.72;
        end;
      end
      else
      begin
        if isHovered then
        begin
          tabR := 0.93; tabG := 0.95; tabB := 0.97; // #EDF2F7
          textR := 0.10; textG := 0.15; textB := 0.25; // #1E293B
        end
        else
        begin
          tabR := 0.89; tabG := 0.91; tabB := 0.94; // #E2E8F0
          textR := 0.28; textG := 0.35; textB := 0.44; // #475569
        end;
      end;

      // Top-rounded tab body clipped at the bottom
      Canvas.PushClipRect(Round(tx - 1), Round(ty - 1), Round(tw + 2), Round(th + 1));
      Canvas.DrawRoundedRect(tx, ty, tw, th + rad, rad, tabR, tabG, tabB, 1.0);
      Canvas.DrawRoundedRectOutline(tx, ty, tw, th + rad, rad, 1.0, borderR, borderG, borderB, 1.0);
      Canvas.PopClipRect();

      // Inactive Tab Title Text & Icon
      textStartX := tx + 12.0;
      textAvailW := tw - 24.0;
      if page.Closeable then
        textAvailW := tw - 38.0;

      if Assigned(page.Icon) and (page.Icon.Width > 0) and (page.Icon.Height > 0) then
      begin
        iconH := Min(th - 6.0, 16.0);
        iconW := (page.Icon.Width / page.Icon.Height) * iconH;
        iconY := Round(ty + (th - iconH) * 0.5);
        Canvas.DrawImageScaled(Round(textStartX), iconY, Round(iconW), Round(iconH), page.Icon, 1.0);
        textStartX := Round(textStartX + iconW + 6.0);
        textAvailW := textAvailW - (iconW + 6.0);
      end;

      if textAvailW > 0.0 then
      begin
        fitTitle := FtFitTextWithEllipsis(page.Title, Font, textAvailW);
        if (not page.Closeable) and not Assigned(page.Icon) and (fitTitle = page.Title) then
          Canvas.DrawTextCentered(Round(tx), Round(ty + 1.0), Round(tw), Round(th), fitTitle, Font, textR, textG, textB)
        else
          Canvas.DrawTextLeft(textStartX, ty + 1.0, textAvailW, th, fitTitle, Font, textR, textG, textB);
      end;

      // Inactive Tab Close Button
      if page.Closeable and GetCloseButtonRect(i, cx, cy, cw, ch) then
      begin
        isCloseHover := (i = FHoveredIndex) and FHoveredClose;
        isClosePressed := isCloseHover and (i = FPressedCloseIndex);
        btnState := bsNormal;
        if isClosePressed then
          btnState := bsPressed
        else if isCloseHover then
          btnState := bsHovered;

        TFtWindowButton.DrawWindowButton(
          Canvas,
          cx, cy, cw, ch,
          wbkClose,
          wbsCircle,
          btnState,
          theme.DarkMode,
          2.5
        );
      end;
    end;

    // 3. Pass 2: Draw Active Tab (covers baseline divider, open bottom merges into page)
    if (FActiveIndex >= 0) and (FActiveIndex < FPages.Count) then
    begin
      i := FActiveIndex;
      page := TFtTabPage(FPages[i]);
      if GetTabRect(i, tx, ty, tw, th) then
      begin
        // Active tab extends down 1px over baseline
        ty := Y + 1.0;
        th := FTabHeight - 1.0;

        if theme.DarkMode then
        begin
          tabR := 0.10; tabG := 0.11; tabB := 0.15;
          textR := 0.97; textG := 0.98; textB := 0.99;
        end
        else
        begin
          tabR := 1.0; tabG := 1.0; tabB := 1.0; // Pure white
          textR := 0.06; textG := 0.09; textB := 0.16; // #0F172A
        end;

        // Active tab body fill (covers the baseline)
        Canvas.PushClipRect(Round(tx - 1), Round(ty - 1), Round(tw + 2), Round(th + 2));
        Canvas.DrawRoundedRect(tx, ty, tw, th + rad, rad, tabR, tabG, tabB, 1.0);

        // Active tab outline (bottom border clipped away -> open bottom!)
        Canvas.DrawRoundedRectOutline(tx, ty, tw, th + rad, rad, 1.0, borderR, borderG, borderB, 1.0);
        Canvas.PopClipRect();

        // Clear any remaining baseline line across active tab span to guarantee seamless merge
        Canvas.DrawLine(tx + 1.0, baseY, tx + tw - 1.0, baseY, 1.5, tabR, tabG, tabB, 1.0);

        // Active Tab Title Text & Icon
        textStartX := tx + 12.0;
        textAvailW := tw - 24.0;
        if page.Closeable then
          textAvailW := tw - 38.0;

        if Assigned(page.Icon) and (page.Icon.Width > 0) and (page.Icon.Height > 0) then
        begin
          iconH := Min(th - 6.0, 16.0);
          iconW := (page.Icon.Width / page.Icon.Height) * iconH;
          iconY := Round(ty + (th - iconH) * 0.5);
          Canvas.DrawImageScaled(Round(textStartX), iconY, Round(iconW), Round(iconH), page.Icon, 1.0);
          textStartX := Round(textStartX + iconW + 6.0);
          textAvailW := textAvailW - (iconW + 6.0);
        end;

        if textAvailW > 0.0 then
        begin
          fitTitle := FtFitTextWithEllipsis(page.Title, Font, textAvailW);
          if (not page.Closeable) and not Assigned(page.Icon) and (fitTitle = page.Title) then
            Canvas.DrawTextCentered(Round(tx), Round(ty + 1.0), Round(tw), Round(th), fitTitle, Font, textR, textG, textB)
          else
            Canvas.DrawTextLeft(textStartX, ty + 1.0, textAvailW, th, fitTitle, Font, textR, textG, textB);
        end;

        // Active Tab Close Button
        if page.Closeable and GetCloseButtonRect(i, cx, cy, cw, ch) then
        begin
          isCloseHover := (i = FHoveredIndex) and FHoveredClose;
          isClosePressed := isCloseHover and (i = FPressedCloseIndex);
          btnState := bsNormal;
          if isClosePressed then
            btnState := bsPressed
          else if isCloseHover then
            btnState := bsHovered;

          TFtWindowButton.DrawWindowButton(
            Canvas,
            cx, cy, cw, ch,
            wbkClose,
            wbsCircle,
            btnState,
            theme.DarkMode,
            2.5
          );
        end;
      end;
    end;
  finally
    Canvas.PopClipRect();
  end;

  // 4. Draw Scroll Navigation Buttons if overflow occurs
  if FScrollButtonsVisible then
  begin
    // Left Scroll Button
    if GetLeftScrollButtonRect(bx, by, bw, bh) then
    begin
      canScrollLeft := (FScrollOffset > 1.0);
      btnHover := (FHoveredScrollButton = 1);
      btnPress := (FPressedScrollButton = 1);

      if theme.DarkMode then
      begin
        if btnPress then
        begin bgR := 0.22; bgG := 0.25; bgB := 0.32; end
        else if btnHover then
        begin bgR := 0.18; bgG := 0.20; bgB := 0.26; end
        else
        begin bgR := 0.13; bgG := 0.14; bgB := 0.18; end;
        fgR := 0.90; fgG := 0.92; fgB := 0.96;
      end
      else
      begin
        if btnPress then
        begin bgR := 0.82; bgG := 0.85; bgB := 0.89; end
        else if btnHover then
        begin bgR := 0.89; bgG := 0.92; bgB := 0.95; end
        else
        begin bgR := 0.94; bgG := 0.95; bgB := 0.97; end;
        fgR := 0.20; fgG := 0.25; fgB := 0.35;
      end;

      if not canScrollLeft then
        btnAlpha := 0.3
      else
        btnAlpha := 1.0;

      Canvas.DrawRoundedRect(bx, by, bw, bh, 4.0, bgR, bgG, bgB, btnAlpha);
      Canvas.DrawRoundedRectOutline(bx, by, bw, bh, 4.0, 1.0, borderR, borderG, borderB, btnAlpha * 0.7);

      arrowCX := bx + bw * 0.5 + 1.0;
      arrowCY := by + bh * 0.5;
      Canvas.DrawLine(arrowCX + 2.0, arrowCY - 4.5, arrowCX - 2.5, arrowCY, 1.6, fgR, fgG, fgB, btnAlpha);
      Canvas.DrawLine(arrowCX - 2.5, arrowCY, arrowCX + 2.0, arrowCY + 4.5, 1.6, fgR, fgG, fgB, btnAlpha);
    end;

    // Right Scroll Button
    if GetRightScrollButtonRect(bx, by, bw, bh) then
    begin
      canScrollRight := (FScrollOffset < FMaxScrollOffset - 1.0);
      btnHover := (FHoveredScrollButton = 2);
      btnPress := (FPressedScrollButton = 2);

      if theme.DarkMode then
      begin
        if btnPress then
        begin bgR := 0.22; bgG := 0.25; bgB := 0.32; end
        else if btnHover then
        begin bgR := 0.18; bgG := 0.20; bgB := 0.26; end
        else
        begin bgR := 0.13; bgG := 0.14; bgB := 0.18; end;
        fgR := 0.90; fgG := 0.92; fgB := 0.96;
      end
      else
      begin
        if btnPress then
        begin bgR := 0.82; bgG := 0.85; bgB := 0.89; end
        else if btnHover then
        begin bgR := 0.89; bgG := 0.92; bgB := 0.95; end
        else
        begin bgR := 0.94; bgG := 0.95; bgB := 0.97; end;
        fgR := 0.20; fgG := 0.25; fgB := 0.35;
      end;

      if not canScrollRight then
        btnAlpha := 0.3
      else
        btnAlpha := 1.0;

      Canvas.DrawRoundedRect(bx, by, bw, bh, 4.0, bgR, bgG, bgB, btnAlpha);
      Canvas.DrawRoundedRectOutline(bx, by, bw, bh, 4.0, 1.0, borderR, borderG, borderB, btnAlpha * 0.7);

      arrowCX := bx + bw * 0.5 - 1.0;
      arrowCY := by + bh * 0.5;
      Canvas.DrawLine(arrowCX - 2.0, arrowCY - 4.5, arrowCX + 2.5, arrowCY, 1.6, fgR, fgG, fgB, btnAlpha);
      Canvas.DrawLine(arrowCX + 2.5, arrowCY, arrowCX - 2.0, arrowCY + 4.5, 1.6, fgR, fgG, fgB, btnAlpha);
    end;
  end;
end;

procedure TFtNotebook.Draw(Canvas: TFtCanvas);
var
  activePage: TFtTabPage;
begin
  if not Visible then Exit;

  // 1. Draw Tab Strip
  DrawTabStrip(Canvas);

  // 2. Draw Active Page
  activePage := GetPage(FActiveIndex);
  if Assigned(activePage) and activePage.Visible then
    activePage.Draw(Canvas);
end;

function TFtNotebook.HitTest(AX, AY: Integer): TFtWidget;
var
  activePage: TFtTabPage;
begin
  Result := nil;
  if not Visible or not Enabled then Exit;

  // Tab strip header area
  if (AX >= X) and (AX <= X + Width) and (AY >= Y) and (AY <= Y + FTabHeight) then
    Exit(Self);

  // Body container area: delegate to active page
  activePage := GetPage(FActiveIndex);
  if Assigned(activePage) and activePage.Visible then
    Result := activePage.HitTest(AX, AY);

  if not Assigned(Result) and (AX >= X) and (AX <= X + Width) and (AY >= Y) and (AY <= Y + Height) then
    Result := Self;
end;

procedure TFtNotebook.MouseDown(AX, AY: Integer; AButton: Integer);
var
  idx: Integer;
  inClose: Boolean;
  btnIdx: Integer;
begin
  inherited MouseDown(AX, AY, AButton);

  // Mouse wheel over tab strip
  if (AY >= Y) and (AY <= Y + FTabHeight) and (AButton in [4, 5, 6, 7]) then
  begin
    if AButton in [4, 6] then
      ScrollBy(-40.0)
    else if AButton in [5, 7] then
      ScrollBy(40.0);
    Exit;
  end;

  if AButton = 1 then
  begin
    btnIdx := ScrollButtonAt(AX, AY);
    if btnIdx > 0 then
    begin
      FPressedScrollButton := btnIdx;
      if btnIdx = 1 then
        ScrollBy(-60.0)
      else
        ScrollBy(60.0);
      Invalidate();
      Exit;
    end;

    idx := TabIndexAt(AX, AY, inClose);
    if idx >= 0 then
    begin
      if inClose then
      begin
        FPressedCloseIndex := idx;
        Invalidate();
      end
      else
      begin
        FPressedCloseIndex := -1;
        ActiveIndex := idx;
      end;
    end
    else
      FPressedCloseIndex := -1;
  end;
end;

procedure TFtNotebook.MouseUp(AX, AY: Integer; AButton: Integer);
var
  idx: Integer;
  inClose: Boolean;
  canClose: Boolean;
begin
  inherited MouseUp(AX, AY, AButton);

  if FPressedScrollButton > 0 then
  begin
    FPressedScrollButton := 0;
    Invalidate();
    Exit;
  end;

  if (AButton = 1) and (FPressedCloseIndex >= 0) then
  begin
    idx := TabIndexAt(AX, AY, inClose);
    if (idx = FPressedCloseIndex) and inClose then
    begin
      canClose := True;
      if Assigned(FOnTabClose) then
        FOnTabClose(Self, idx, canClose);
      if canClose then
        RemoveTab(idx, True);
    end;
    FPressedCloseIndex := -1;
    Invalidate();
  end;
end;

procedure TFtNotebook.MouseMove(AX, AY: Integer);
var
  oldHover, newHover: Integer;
  oldClose, newClose: Boolean;
  oldBtn, newBtn: Integer;
begin
  inherited MouseMove(AX, AY);

  oldHover := FHoveredIndex;
  oldClose := FHoveredClose;
  oldBtn := FHoveredScrollButton;

  newBtn := ScrollButtonAt(AX, AY);
  FHoveredScrollButton := newBtn;

  if newBtn > 0 then
  begin
    newHover := -1;
    newClose := False;
  end
  else
    newHover := TabIndexAt(AX, AY, newClose);

  if (oldHover <> newHover) or (oldClose <> newClose) or (oldBtn <> newBtn) then
  begin
    FHoveredIndex := newHover;
    FHoveredClose := newClose;
    Invalidate();
  end;
end;

procedure TFtNotebook.MouseLeave();
begin
  inherited MouseLeave();
  if (FHoveredIndex >= 0) or FHoveredClose or (FPressedCloseIndex >= 0) or
     (FHoveredScrollButton > 0) or (FPressedScrollButton > 0) then
  begin
    FHoveredIndex := -1;
    FHoveredClose := False;
    FPressedCloseIndex := -1;
    FHoveredScrollButton := 0;
    FPressedScrollButton := 0;
    Invalidate();
  end;
end;

procedure TFtNotebook.KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string);
begin
  inherited KeyDown(AKeySym, AState, AChar);

  // Left Arrow ($FF51): Previous Tab
  if (AKeySym = $FF51) and (FActiveIndex > 0) then
    ActiveIndex := FActiveIndex - 1
  // Right Arrow ($FF53): Next Tab
  else if (AKeySym = $FF53) and (FActiveIndex < FPages.Count - 1) then
    ActiveIndex := FActiveIndex + 1;
end;

end.
