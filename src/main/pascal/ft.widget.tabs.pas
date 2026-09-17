unit Ft.Widget.Tabs;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Math,
  Ft.Canvas.Agg, Ft.Font, Ft.Widget, Ft.Widget.Containers, Ft.Theme, Ft.Css;

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
    FNotebook: TFtNotebook;
    procedure SetTitle(const AValue: string);
    procedure SetCloseable(AValue: Boolean);
  public
    constructor Create(AParent: TFtWidget); override;
    function GetElementType(): string; override;

    property Title: string read FTitle write SetTitle;
    property Closeable: Boolean read FCloseable write SetCloseable;
    property Notebook: TFtNotebook read FNotebook write FNotebook;
  end;

  TFtNotebook = class(TFtWidget)
  private
    FPages: TFPList; // TFtTabPage
    FActiveIndex: Integer;
    FTabHeight: Double;
    FHoveredIndex: Integer;
    FHoveredClose: Boolean;
    FPressedCloseIndex: Integer;
    FOnTabChange: TFtTabChangeEvent;
    FOnTabClose: TFtTabCloseEvent;
    FOnTabChangeCb: TFtTabClickCallback;
    FUserData: Pointer;

    procedure SetActiveIndex(AValue: Integer);
    procedure SetTabHeight(AValue: Double);
    function GetPageCount(): Integer;
  protected
    procedure DrawTabStrip(Canvas: TFtCanvasAgg); virtual;
  public
    constructor Create(AParent: TFtWidget); override;
    destructor Destroy(); override;
    function GetElementType(): string; override;

    function GetTabRect(AIndex: Integer; out RX, RY, RW, RH: Double): Boolean;
    function GetCloseButtonRect(AIndex: Integer; out CX, CY, CW, CH: Double): Boolean;
    function TabIndexAt(AX, AY: Integer; out InCloseBtn: Boolean): Integer;

    procedure UpdateLayout();
    function GetPage(AIndex: Integer): TFtTabPage;
    function AddTab(const ATitle: string; ACloseable: Boolean = False): TFtTabPage;
    procedure RemoveTab(AIndex: Integer; FreePage: Boolean = True);
    procedure ClearTabs();

    procedure Draw(Canvas: TFtCanvasAgg); override;
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

{ TFtNotebook }

constructor TFtNotebook.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FPages := TFPList.Create();
  FActiveIndex := -1;
  FTabHeight := 36.0;
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

procedure TFtNotebook.UpdateLayout();
var
  i: Integer;
  page: TFtTabPage;
  headerH, pageX, pageY, pageW, pageH: Integer;
begin
  headerH := Round(FTabHeight);
  pageX := X;
  pageY := Y + headerH;
  pageW := Width;
  pageH := Height - headerH;
  if pageH < 0 then pageH := 0;

  for i := 0 to FPages.Count - 1 do
  begin
    page := TFtTabPage(FPages[i]);
    page.X := pageX;
    page.Y := pageY;
    page.Width := pageW;
    page.Height := pageH;
    page.Visible := (i = FActiveIndex);
  end;
  Invalidate();
end;

function TFtNotebook.GetTabRect(AIndex: Integer; out RX, RY, RW, RH: Double): Boolean;
var
  i: Integer;
  curX: Double;
  page: TFtTabPage;
  fnt: TFtFont;
  twText: Double;
  tabW: Double;
begin
  Result := False;
  if (AIndex < 0) or (AIndex >= FPages.Count) then Exit;

  if Assigned(Font) then fnt := Font else fnt := FtGetSystemFont();

  curX := X + 4.0;
  for i := 0 to FPages.Count - 1 do
  begin
    page := TFtTabPage(FPages[i]);
    if Assigned(fnt) then
      twText := fnt.GetTextWidth(page.Title)
    else
      twText := Length(page.Title) * 8.5;

    tabW := Math.Max(70.0, twText + 28.0);
    if page.Closeable then
      tabW := tabW + 22.0;

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

function TFtNotebook.TabIndexAt(AX, AY: Integer; out InCloseBtn: Boolean): Integer;
var
  i: Integer;
  tx, ty, tw, th, cx, cy, cw, ch: Double;
begin
  InCloseBtn := False;
  Result := -1;
  if (AY < Y) or (AY > Y + FTabHeight) then Exit;

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
end;

procedure TFtNotebook.ClearTabs();
var
  i: Integer;
begin
  for i := 0 to FPages.Count - 1 do
    TFtTabPage(FPages[i]).Free();
  FPages.Clear();
  FActiveIndex := -1;
  Invalidate();
end;

procedure TFtNotebook.DrawTabStrip(Canvas: TFtCanvasAgg);
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
  cenX, cenY, btnRad, arm: Double;
  xR, xG, xB, xA: Double;
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

  // 2. Pass 1: Draw Inactive Tabs (sits flush on top of the baseline)
  for i := 0 to FPages.Count - 1 do
  begin
    if i = FActiveIndex then Continue;
    page := TFtTabPage(FPages[i]);
    if not GetTabRect(i, tx, ty, tw, th) then Continue;

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

    // Inactive Tab Title Text
    if page.Closeable then
      Canvas.DrawTextLeft(tx + 12.0, ty + 1.0, tw - 38.0, th, page.Title, Font, textR, textG, textB)
    else
      Canvas.DrawTextCentered(Round(tx), Round(ty + 1.0), Round(tw), Round(th), page.Title, Font, textR, textG, textB);

    // Inactive Tab Close Button
    if page.Closeable and GetCloseButtonRect(i, cx, cy, cw, ch) then
    begin
      isCloseHover := (i = FHoveredIndex) and FHoveredClose;
      isClosePressed := isCloseHover and (i = FPressedCloseIndex);
      cenX := cx + cw * 0.5;
      cenY := cy + ch * 0.5;
      btnRad := 7.0;
      arm := 2.5;

      if isClosePressed then
      begin
        Canvas.DrawCircle(cenX, cenY + 0.5, btnRad - 0.5, 0.70, 0.02, 0.05, 1.0); // #B2060C Click
        xR := 1.0; xG := 1.0; xB := 1.0; xA := 1.0;
        cenY := cenY + 0.5;
      end
      else if isCloseHover then
      begin
        // Dual-layer glowing halo (from design legend)
        Canvas.DrawCircle(cenX, cenY, btnRad + 2.5, 0.98, 0.06, 0.11, 0.20);
        Canvas.DrawCircle(cenX, cenY, btnRad + 1.2, 0.98, 0.06, 0.11, 0.40);
        Canvas.DrawCircle(cenX, cenY, btnRad, 0.98, 0.06, 0.11, 1.0); // #FA0F1B Hover
        xR := 1.0; xG := 1.0; xB := 1.0; xA := 1.0;
      end
      else
      begin
        // Normal state: button-like styling
        if theme.DarkMode then
        begin
          Canvas.DrawCircle(cenX, cenY, btnRad, 0.22, 0.24, 0.26, 1.0);
          Canvas.DrawCircleOutline(cenX, cenY, btnRad, 1.0, 0.32, 0.35, 0.38, 1.0);
          xR := 0.85; xG := 0.87; xB := 0.90; xA := 1.0;
        end
        else
        begin
          Canvas.DrawCircle(cenX, cenY, btnRad, 0.96, 0.97, 0.98, 1.0);
          Canvas.DrawCircleOutline(cenX, cenY, btnRad, 1.0, 0.80, 0.82, 0.85, 1.0);
          xR := 0.32; xG := 0.38; xB := 0.46; xA := 1.0;
        end;
      end;

      // Anti-aliased 'x' cross lines
      Canvas.DrawLine(cenX - arm, cenY - arm, cenX + arm, cenY + arm, 1.4, xR, xG, xB, xA);
      Canvas.DrawLine(cenX + arm, cenY - arm, cenX - arm, cenY + arm, 1.4, xR, xG, xB, xA);
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

      // Active Tab Title Text
      if page.Closeable then
        Canvas.DrawTextLeft(tx + 12.0, ty + 1.0, tw - 38.0, th, page.Title, Font, textR, textG, textB)
      else
        Canvas.DrawTextCentered(Round(tx), Round(ty + 1.0), Round(tw), Round(th), page.Title, Font, textR, textG, textB);

      // Active Tab Close Button
      if page.Closeable and GetCloseButtonRect(i, cx, cy, cw, ch) then
      begin
        isCloseHover := (i = FHoveredIndex) and FHoveredClose;
        isClosePressed := isCloseHover and (i = FPressedCloseIndex);
        cenX := cx + cw * 0.5;
        cenY := cy + ch * 0.5;
        btnRad := 7.0;
        arm := 2.5;

        if isClosePressed then
        begin
          Canvas.DrawCircle(cenX, cenY + 0.5, btnRad - 0.5, 0.70, 0.02, 0.05, 1.0); // #B2060C Click
          xR := 1.0; xG := 1.0; xB := 1.0; xA := 1.0;
          cenY := cenY + 0.5;
        end
        else if isCloseHover then
        begin
          // Glowing halo
          Canvas.DrawCircle(cenX, cenY, btnRad + 2.5, 0.98, 0.06, 0.11, 0.20);
          Canvas.DrawCircle(cenX, cenY, btnRad + 1.2, 0.98, 0.06, 0.11, 0.40);
          Canvas.DrawCircle(cenX, cenY, btnRad, 0.98, 0.06, 0.11, 1.0); // #FA0F1B Hover
          xR := 1.0; xG := 1.0; xB := 1.0; xA := 1.0;
        end
        else
        begin
          // Normal state: button-like styling
          if theme.DarkMode then
          begin
            Canvas.DrawCircle(cenX, cenY, btnRad, 0.22, 0.24, 0.26, 1.0);
            Canvas.DrawCircleOutline(cenX, cenY, btnRad, 1.0, 0.32, 0.35, 0.38, 1.0);
            xR := 0.85; xG := 0.87; xB := 0.90; xA := 1.0;
          end
          else
          begin
            Canvas.DrawCircle(cenX, cenY, btnRad, 0.96, 0.97, 0.98, 1.0);
            Canvas.DrawCircleOutline(cenX, cenY, btnRad, 1.0, 0.80, 0.82, 0.85, 1.0);
            xR := 0.32; xG := 0.38; xB := 0.46; xA := 1.0;
          end;
        end;

        // Anti-aliased 'x' cross lines
        Canvas.DrawLine(cenX - arm, cenY - arm, cenX + arm, cenY + arm, 1.4, xR, xG, xB, xA);
        Canvas.DrawLine(cenX + arm, cenY - arm, cenX - arm, cenY + arm, 1.4, xR, xG, xB, xA);
      end;
    end;
  end;
end;

procedure TFtNotebook.Draw(Canvas: TFtCanvasAgg);
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
begin
  inherited MouseDown(AX, AY, AButton);

  if AButton = 1 then
  begin
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
begin
  inherited MouseMove(AX, AY);

  oldHover := FHoveredIndex;
  oldClose := FHoveredClose;
  newHover := TabIndexAt(AX, AY, newClose);

  if (oldHover <> newHover) or (oldClose <> newClose) then
  begin
    FHoveredIndex := newHover;
    FHoveredClose := newClose;
    Invalidate();
  end;
end;

procedure TFtNotebook.MouseLeave();
begin
  inherited MouseLeave();
  if (FHoveredIndex >= 0) or FHoveredClose or (FPressedCloseIndex >= 0) then
  begin
    FHoveredIndex := -1;
    FHoveredClose := False;
    FPressedCloseIndex := -1;
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
