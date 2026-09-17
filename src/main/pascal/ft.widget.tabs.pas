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
    FOnTabChange: TFtTabChangeEvent;
    FOnTabClose: TFtTabCloseEvent;
    FOnTabChangeCb: TFtTabClickCallback;
    FUserData: Pointer;

    procedure SetActiveIndex(AValue: Integer);
    procedure SetTabHeight(AValue: Double);
    function GetPageCount(): Integer;
    function GetTabRect(AIndex: Integer; out RX, RY, RW, RH: Double): Boolean;
    function GetCloseButtonRect(AIndex: Integer; out CX, CY, CW, CH: Double): Boolean;
    function TabIndexAt(AX, AY: Integer; out InCloseBtn: Boolean): Integer;
  protected
    procedure DrawTabStrip(Canvas: TFtCanvasAgg); virtual;
  public
    constructor Create(AParent: TFtWidget); override;
    destructor Destroy(); override;
    function GetElementType(): string; override;

    procedure UpdateLayout();
    function GetPage(AIndex: Integer): TFtTabPage;
    function AddTab(const ATitle: string; ACloseable: Boolean = False): TFtTabPage;
    procedure RemoveTab(AIndex: Integer; FreePage: Boolean = True);
    procedure ClearTabs();

    procedure Draw(Canvas: TFtCanvasAgg); override;
    function HitTest(AX, AY: Integer): TFtWidget; override;
    procedure MouseDown(AX, AY: Integer; AButton: Integer); override;
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
  titleLen: Integer;
  tabW: Double;
begin
  Result := False;
  if (AIndex < 0) or (AIndex >= FPages.Count) then Exit;

  curX := X;
  for i := 0 to FPages.Count - 1 do
  begin
    page := TFtTabPage(FPages[i]);
    titleLen := Length(page.Title);
    tabW := Max(80.0, Min(220.0, titleLen * 9.0 + 32.0));
    if page.Closeable then
      tabW := tabW + 20.0;

    if i = AIndex then
    begin
      RX := curX;
      RY := Y;
      RW := tabW;
      RH := FTabHeight;
      Exit(True);
    end;
    curX := curX + tabW + 2.0;
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

  CW := 16.0;
  CH := 16.0;
  CX := tx + tw - 22.0;
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
  isActive, isHovered, isCloseHover: Boolean;
  tabR, tabG, tabB: Double;
  textR, textG, textB: Double;
  stripR, stripG, stripB: Double;
  accent: TFtRgbColor;
  barH: Double;
begin
  theme := FtGetTheme();
  accent := theme.GetAccentColor();

  // Draw tab strip backdrop
  if theme.DarkMode then
  begin
    stripR := 0.12; stripG := 0.12; stripB := 0.16;
  end
  else
  begin
    stripR := 0.90; stripG := 0.90; stripB := 0.92;
  end;
  Canvas.DrawRect(X, Y, Width, Round(FTabHeight), stripR, stripG, stripB, 1.0);

  // Bottom dividing line
  Canvas.DrawLine(X, Y + FTabHeight - 1.0, X + Width, Y + FTabHeight - 1.0, 1.0, stripR * 0.7, stripG * 0.7, stripB * 0.7, 1.0);

  // Draw individual tabs
  for i := 0 to FPages.Count - 1 do
  begin
    page := TFtTabPage(FPages[i]);
    if not GetTabRect(i, tx, ty, tw, th) then Continue;

    isActive := (i = FActiveIndex);
    isHovered := (i = FHoveredIndex);

    if isActive then
    begin
      if theme.DarkMode then
      begin
        tabR := 0.18; tabG := 0.19; tabB := 0.24;
      end
      else
      begin
        tabR := 1.0; tabG := 1.0; tabB := 1.0;
      end;
      textR := accent.R; textG := accent.G; textB := accent.B;
    end
    else if isHovered then
    begin
      if theme.DarkMode then
      begin
        tabR := 0.15; tabG := 0.15; tabB := 0.20;
      end
      else
      begin
        tabR := 0.94; tabG := 0.94; tabB := 0.96;
      end;
      textR := 0.8; textG := 0.8; textB := 0.8;
    end
    else
    begin
      tabR := stripR; tabG := stripG; tabB := stripB;
      if theme.DarkMode then
      begin
        textR := 0.6; textG := 0.6; textB := 0.6;
      end
      else
      begin
        textR := 0.4; textG := 0.4; textB := 0.4;
      end;
    end;

    // Tab body with rounded top corners
    Canvas.DrawRoundedRect(tx, ty + 3.0, tw, th - 3.0, 6.0, tabR, tabG, tabB, 1.0);

    // Active indicator top bar
    if isActive then
    begin
      barH := 3.0;
      Canvas.DrawRoundedRect(tx + 2.0, ty + 1.0, tw - 4.0, barH, 2.0, accent.R, accent.G, accent.B, 1.0);
    end;

    // Title Text
    if page.Closeable then
      Canvas.DrawTextLeft(tx + 12.0, ty + 6.0, tw - 36.0, th - 8.0, page.Title, Font, textR, textG, textB)
    else
      Canvas.DrawTextCentered(Round(tx), Round(ty), Round(tw), Round(th), page.Title, Font, textR, textG, textB);

    // Close button ('X')
    if page.Closeable and GetCloseButtonRect(i, cx, cy, cw, ch) then
    begin
      isCloseHover := (i = FHoveredIndex) and FHoveredClose;
      if isCloseHover then
      begin
        Canvas.DrawRoundedRect(cx, cy, cw, ch, 4.0, 0.9, 0.2, 0.2, 0.8);
        Canvas.DrawTextCentered(Round(cx), Round(cy) - 1, Round(cw), Round(ch), 'x', Font, 1.0, 1.0, 1.0);
      end
      else
      begin
        Canvas.DrawTextCentered(Round(cx), Round(cy) - 1, Round(cw), Round(ch), 'x', Font, textR, textG, textB);
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
  canClose: Boolean;
begin
  inherited MouseDown(AX, AY, AButton);

  if AButton = 1 then
  begin
    idx := TabIndexAt(AX, AY, inClose);
    if idx >= 0 then
    begin
      if inClose then
      begin
        canClose := True;
        if Assigned(FOnTabClose) then
          FOnTabClose(Self, idx, canClose);
        if canClose then
          RemoveTab(idx, True);
      end
      else
      begin
        ActiveIndex := idx;
      end;
    end;
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
  if (FHoveredIndex >= 0) or FHoveredClose then
  begin
    FHoveredIndex := -1;
    FHoveredClose := False;
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
