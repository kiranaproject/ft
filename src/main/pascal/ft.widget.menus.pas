unit Ft.Widget.Menus;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Floria.Canvas.Agg, Floria.Font, Ft.Widget, Ft.Theme;

type
  { Forward declarations }
  TFtMenuItem = class;
  TFtPopupMenu = class;
  TFtMainMenu = class;

  { Callback types }
  TFtMenuCallback = procedure(MenuItem: Pointer; UserData: Pointer); cdecl;

  { TFtMenuItem }
  TFtMenuItem = class
  private
    FCaption: string;
    FShortcut: string;
    FEnabled: Boolean;
    FChecked: Boolean;
    FCheckable: Boolean;
    FIsSeparator: Boolean;
    FSubMenu: TFtPopupMenu;
    FParentMenu: TFtWidget;
    FOnClick: TFtMenuCallback;
    FUserData: Pointer;
    FOnClickEvent: TNotifyEvent;
    FTag: Int64;
    procedure SetCaption(const AValue: string);
    procedure SetChecked(AValue: Boolean);
  public
    X, Y, Width, Height: Integer;

    constructor Create(AParentMenu: TFtWidget); virtual;
    destructor Destroy(); override;

    procedure Click(); virtual;
    function HasSubMenu(): Boolean;

    property Caption: string read FCaption write SetCaption;
    property Shortcut: string read FShortcut write FShortcut;
    property Enabled: Boolean read FEnabled write FEnabled;
    property Checked: Boolean read FChecked write SetChecked;
    property Checkable: Boolean read FCheckable write FCheckable;
    property IsSeparator: Boolean read FIsSeparator write FIsSeparator;
    property SubMenu: TFtPopupMenu read FSubMenu write FSubMenu;
    property ParentMenu: TFtWidget read FParentMenu;
    property OnClick: TFtMenuCallback read FOnClick write FOnClick;
    property UserData: Pointer read FUserData write FUserData;
    property OnClickEvent: TNotifyEvent read FOnClickEvent write FOnClickEvent;
    property Tag: Int64 read FTag write FTag;
  end;

  { TFtPopupMenu }
  TFtPopupMenu = class(TFtWidget)
  private
    FPopupWindow: TFtWidget;
    FOwnerWidget: TFtWidget;
    FParentMainMenu: TFtMainMenu;
    FItems: TFPList;
    FActiveSubMenu: TFtPopupMenu;
    FParentPopupMenu: TFtPopupMenu;
    FParentMenuItem: TFtMenuItem;
    FHoverIndex: Integer;
    FPressedIndex: Integer;
    FIsOpen: Boolean;
    FItemHeight: Integer;
    FMinWidth: Integer;
    FCornerRadius: Double;
  public
    constructor Create(AParent: TFtWidget); override;
    destructor Destroy(); override;

    function AddItem(const ACaption: string; AOnClick: TFtMenuCallback = nil; AUserData: Pointer = nil): TFtMenuItem;
    function AddCheckItem(const ACaption: string; AChecked: Boolean; AOnClick: TFtMenuCallback = nil; AUserData: Pointer = nil): TFtMenuItem;
    function AddSeparator(): TFtMenuItem;
    function AddSubMenu(const ACaption: string; ASubMenu: TFtPopupMenu): TFtMenuItem;
    function ItemCount(): Integer;
    function GetItem(AIndex: Integer): TFtMenuItem;
    procedure Clear();

    procedure RecalcLayout();
    procedure Popup(AX, AY: Integer);
    procedure Close();
    procedure DismissAll();

    procedure Draw(Canvas: TFtCanvasAgg); override;
    procedure DrawCascade(Canvas: TFtCanvasAgg);
    function HitTest(AX, AY: Integer): TFtWidget; override;
    function HitTestCascade(AX, AY: Integer; out HitPopup: TFtPopupMenu; out HitItem: TFtMenuItem): Boolean;
    function ItemAt(AX, AY: Integer): Integer;

    procedure MouseMove(AX, AY: Integer); override;
    procedure MouseDown(AX, AY: Integer; AButton: Integer); override;
    procedure MouseUp(AX, AY: Integer; AButton: Integer); override;
    procedure Click(); override;

    procedure SelectNext();
    procedure SelectPrev();
    procedure ActivateSelected();

    property PopupWindow: TFtWidget read FPopupWindow;
    property ParentMainMenu: TFtMainMenu read FParentMainMenu write FParentMainMenu;
    property Items: TFPList read FItems;
    property IsOpen: Boolean read FIsOpen;
    property ActiveSubMenu: TFtPopupMenu read FActiveSubMenu;
    property ParentPopupMenu: TFtPopupMenu read FParentPopupMenu;
    property ParentMenuItem: TFtMenuItem read FParentMenuItem;
    property HoverIndex: Integer read FHoverIndex write FHoverIndex;
    property ItemHeight: Integer read FItemHeight write FItemHeight;
    property MinWidth: Integer read FMinWidth write FMinWidth;
    property CornerRadius: Double read FCornerRadius write FCornerRadius;
    property OwnerWidget: TFtWidget read FOwnerWidget write FOwnerWidget;
  end;

  { TFtMainMenu }
  TFtMainMenu = class(TFtWidget)
  private
    FItems: TFPList;
    FHoverIndex: Integer;
    FActiveIndex: Integer;
  public
    constructor Create(AParent: TFtWidget); override;
    destructor Destroy(); override;

    function AddMenu(const ACaption: string): TFtPopupMenu;
    function AddItem(const ACaption: string; ASubMenu: TFtPopupMenu): TFtMenuItem;
    function ItemCount(): Integer;
    function GetItem(AIndex: Integer): TFtMenuItem;
    procedure Clear();

    procedure RecalcLayout();
    procedure CloseMenu();

    procedure Draw(Canvas: TFtCanvasAgg); override;
    function HitTest(AX, AY: Integer): TFtWidget; override;
    function ItemAt(AX, AY: Integer): Integer;

    procedure MouseMove(AX, AY: Integer); override;
    procedure MouseDown(AX, AY: Integer; AButton: Integer); override;
    procedure MouseUp(AX, AY: Integer; AButton: Integer); override;
    procedure MouseLeave(); override;

    property Items: TFPList read FItems;
    property HoverIndex: Integer read FHoverIndex;
    property ActiveIndex: Integer read FActiveIndex;
  end;

implementation

uses
  Types, Ft.Window;

{ TFtMenuItem }

constructor TFtMenuItem.Create(AParentMenu: TFtWidget);
begin
  inherited Create();
  FParentMenu := AParentMenu;
  FCaption := '';
  FShortcut := '';
  FEnabled := True;
  FChecked := False;
  FCheckable := False;
  FIsSeparator := False;
  FSubMenu := nil;
  FOnClick := nil;
  FUserData := nil;
  FOnClickEvent := nil;
  FTag := 0;
  X := 0;
  Y := 0;
  Width := 0;
  Height := 0;
end;

destructor TFtMenuItem.Destroy();
begin
  if Assigned(FSubMenu) then
  begin
    FSubMenu.Free();
    FSubMenu := nil;
  end;
  inherited Destroy();
end;

procedure TFtMenuItem.SetCaption(const AValue: string);
begin
  FCaption := AValue;
  if FCaption = '-' then
    FIsSeparator := True;
end;

procedure TFtMenuItem.SetChecked(AValue: Boolean);
begin
  if FChecked <> AValue then
  begin
    FChecked := AValue;
    FCheckable := True;
    if Assigned(FParentMenu) then
      FParentMenu.Invalidate();
  end;
end;

function TFtMenuItem.HasSubMenu(): Boolean;
begin
  Result := Assigned(FSubMenu) and (FSubMenu.ItemCount() > 0);
end;

procedure TFtMenuItem.Click();
begin
  if not FEnabled or FIsSeparator then Exit;

  if FCheckable then
    FChecked := not FChecked;

  if Assigned(FOnClick) then
    FOnClick(Pointer(Self), FUserData);

  if Assigned(FOnClickEvent) then
    FOnClickEvent(Self);
end;

{ TFtPopupMenu }

constructor TFtPopupMenu.Create(AParent: TFtWidget);
var
  popWin: TFtWindow;
begin
  inherited Create(nil);
  FOwnerWidget := AParent;
  FParentMainMenu := nil;
  FItems := TFPList.Create();
  FActiveSubMenu := nil;
  FParentPopupMenu := nil;
  FParentMenuItem := nil;
  FHoverIndex := -1;
  FPressedIndex := -1;
  FIsOpen := False;
  FItemHeight := 28;
  FMinWidth := 160;
  FCornerRadius := 0.0;

  { Create native borderless popup window }
  popWin := FtCreateWindow(FMinWidth, 50, '', ftwtPopupMenu);
  popWin.Borderless := True;
  popWin.SkipTaskbar := True;
  popWin.Visible := False;
  FPopupWindow := popWin;

  Self.X := 0;
  Self.Y := 0;
  Self.Parent := popWin;
  popWin.Children.Add(Self);
  Visible := False;
end;

destructor TFtPopupMenu.Destroy();
var
  I: Integer;
begin
  if FIsOpen then DismissAll();
  Clear();
  for I := 0 to FItems.Count - 1 do
    TFtMenuItem(FItems[I]).Free();
  FItems.Free();
  if Assigned(FPopupWindow) then
  begin
    FPopupWindow.Children.Remove(Self);
    Self.Parent := nil;
    FPopupWindow.Free();
    FPopupWindow := nil;
  end;
  inherited Destroy();
end;

function TFtPopupMenu.AddItem(const ACaption: string; AOnClick: TFtMenuCallback = nil; AUserData: Pointer = nil): TFtMenuItem;
var
  item: TFtMenuItem;
begin
  item := TFtMenuItem.Create(Self);
  item.Caption := ACaption;
  item.OnClick := AOnClick;
  item.UserData := AUserData;
  FItems.Add(item);
  Result := item;
end;

function TFtPopupMenu.AddCheckItem(const ACaption: string; AChecked: Boolean; AOnClick: TFtMenuCallback = nil; AUserData: Pointer = nil): TFtMenuItem;
var
  item: TFtMenuItem;
begin
  item := TFtMenuItem.Create(Self);
  item.Caption := ACaption;
  item.Checkable := True;
  item.Checked := AChecked;
  item.OnClick := AOnClick;
  item.UserData := AUserData;
  FItems.Add(item);
  Result := item;
end;

function TFtPopupMenu.AddSeparator(): TFtMenuItem;
var
  item: TFtMenuItem;
begin
  item := TFtMenuItem.Create(Self);
  item.Caption := '-';
  item.IsSeparator := True;
  FItems.Add(item);
  Result := item;
end;

function TFtPopupMenu.AddSubMenu(const ACaption: string; ASubMenu: TFtPopupMenu): TFtMenuItem;
var
  item: TFtMenuItem;
begin
  item := TFtMenuItem.Create(Self);
  item.Caption := ACaption;
  item.SubMenu := ASubMenu;
  if Assigned(ASubMenu) then
  begin
    ASubMenu.FParentPopupMenu := Self;
    ASubMenu.FParentMenuItem := item;
  end;
  FItems.Add(item);
  Result := item;
end;

function TFtPopupMenu.ItemCount(): Integer;
begin
  Result := FItems.Count;
end;

function TFtPopupMenu.GetItem(AIndex: Integer): TFtMenuItem;
begin
  if (AIndex >= 0) and (AIndex < FItems.Count) then
    Result := TFtMenuItem(FItems[AIndex])
  else
    Result := nil;
end;

procedure TFtPopupMenu.Clear();
var
  I: Integer;
begin
  Close();
  for I := 0 to FItems.Count - 1 do
    TFtMenuItem(FItems[I]).Free();
  FItems.Clear();
end;

procedure TFtPopupMenu.RecalcLayout();
var
  I: Integer;
  item: TFtMenuItem;
  fnt: TFtFont;
  maxCapW, maxShortW, curCapW, curShortW: Double;
  hasSub: Boolean;
  calcW: Double;
  curY: Integer;
  effItemH: Integer;
begin
  fnt := GetFont();
  maxCapW := 0.0;
  maxShortW := 0.0;
  hasSub := False;

  for I := 0 to FItems.Count - 1 do
  begin
    item := TFtMenuItem(FItems[I]);
    if item.IsSeparator then Continue;

    if item.HasSubMenu() then
      hasSub := True;

    if Assigned(fnt) then
    begin
      curCapW := fnt.GetTextWidth(item.Caption);
      if curCapW > maxCapW then maxCapW := curCapW;

      if item.Shortcut <> '' then
      begin
        curShortW := fnt.GetTextWidth(item.Shortcut);
        if curShortW > maxShortW then maxShortW := curShortW;
      end;
    end;
  end;

  effItemH := FItemHeight;
  if Assigned(fnt) and (Round(fnt.Size + 14) > effItemH) then
    effItemH := Round(fnt.Size + 14);

  calcW := 32.0 + maxCapW; // left check/padding + text
  if maxShortW > 0.0 then
    calcW := calcW + 24.0 + maxShortW;
  if hasSub then
    calcW := calcW + 20.0
  else
    calcW := calcW + 12.0;

  if calcW < FMinWidth then
    calcW := FMinWidth;

  Width := Round(calcW);

  curY := 2;
  for I := 0 to FItems.Count - 1 do
  begin
    item := TFtMenuItem(FItems[I]);
    item.X := 1;
    item.Width := Width - 2;
    item.Y := curY;
    if item.IsSeparator then
      item.Height := 8
    else
      item.Height := effItemH;
    curY := curY + item.Height;
  end;

  Height := curY + 2;

  if Assigned(FPopupWindow) then
  begin
    Self.Width := Width;
    Self.Height := Height;
    TFtWindow(FPopupWindow).Resize(Width, Height);
  end;
end;

procedure TFtPopupMenu.Popup(AX, AY: Integer);
var
  popWin: TFtWindow;
  screenW, screenH: Integer;
begin
  RecalcLayout();

  popWin := TFtWindow(FPopupWindow);
  if Assigned(popWin) then
  begin
    screenW := popWin.ScreenWidth;
    screenH := popWin.ScreenHeight;

    if AX + Width > screenW then
      AX := screenW - Width - 2;
    if AY + Height > screenH then
      AY := screenH - Height - 2;
    if AX < 0 then AX := 0;
    if AY < 0 then AY := 0;

    popWin.SetPosition(AX, AY);
    popWin.Show();
  end;

  X := 0;
  Y := 0;
  FIsOpen := True;
  Visible := True;
  FHoverIndex := -1;
  FPressedIndex := -1;

  if not Assigned(FParentPopupMenu) then
  begin
    GGrabbedPopup := Self;
    if Assigned(popWin) then
      FtGrabMenuInput(popWin);
  end;

  if Assigned(popWin) then
    popWin.Repaint();
end;

procedure TFtPopupMenu.Close();
var
  popWin: TFtWindow;
begin
  if not FIsOpen then Exit;
  if Assigned(FActiveSubMenu) then
  begin
    FActiveSubMenu.Close();
    FActiveSubMenu := nil;
  end;
  FIsOpen := False;
  Visible := False;
  FHoverIndex := -1;
  FPressedIndex := -1;
  popWin := TFtWindow(FPopupWindow);
  if Assigned(popWin) then
    popWin.Hide();
end;

procedure TFtPopupMenu.DismissAll();
var
  rootPop: TFtPopupMenu;
  popWin: TFtWindow;
begin
  rootPop := Self;
  while Assigned(rootPop.FParentPopupMenu) do
    rootPop := rootPop.FParentPopupMenu;

  if GGrabbedPopup = rootPop then
  begin
    popWin := TFtWindow(rootPop.FPopupWindow);
    if Assigned(popWin) then
      FtUngrabMenuInput(popWin);
    GGrabbedPopup := nil;
  end;

  rootPop.Close();

  if Assigned(rootPop.FParentMainMenu) then
    rootPop.FParentMainMenu.CloseMenu();
end;

procedure TFtPopupMenu.Draw(Canvas: TFtCanvasAgg);
var
  I: Integer;
  item: TFtMenuItem;
  fnt: TFtFont;
begin
  if not FIsOpen or not Visible then Exit;

  { Flat rectangular plate (rounded corners & shadows handled natively by X11 compositor) }
  FtGetTheme().DrawPopupMenuPlate(Canvas, 0, 0, Width, Height, 0.0);

  fnt := GetFont();

  { Draw items }
  for I := 0 to FItems.Count - 1 do
  begin
    item := TFtMenuItem(FItems[I]);
    if item.IsSeparator then
      FtGetTheme().DrawMenuSeparator(Canvas, item.X, item.Y, item.Width)
    else
      FtGetTheme().DrawPopupMenuItem(Canvas, item.X, item.Y, item.Width, item.Height,
                                     item.Caption, item.Shortcut, fnt,
                                     (FHoverIndex = I), item.Enabled, item.Checked, item.HasSubMenu());
  end;
end;

procedure TFtPopupMenu.DrawCascade(Canvas: TFtCanvasAgg);
begin
  if not FIsOpen then Exit;
  Self.Draw(Canvas);
end;

function TFtPopupMenu.HitTest(AX, AY: Integer): TFtWidget;
begin
  Result := nil;
  if not FIsOpen or not Visible then Exit;
  if (AX >= 0) and (AX < Width) and (AY >= 0) and (AY < Height) then
    Result := Self;
end;

function TFtPopupMenu.HitTestCascade(AX, AY: Integer; out HitPopup: TFtPopupMenu; out HitItem: TFtMenuItem): Boolean;
begin
  HitPopup := nil;
  HitItem := nil;
  Result := False;
end;

function TFtPopupMenu.ItemAt(AX, AY: Integer): Integer;
var
  I: Integer;
  item: TFtMenuItem;
begin
  Result := -1;
  if not FIsOpen then Exit;
  if (AX < 0) or (AX >= Width) or (AY < 0) or (AY >= Height) then
    Exit;

  for I := 0 to FItems.Count - 1 do
  begin
    item := TFtMenuItem(FItems[I]);
    if (AY >= item.Y) and (AY < item.Y + item.Height) then
      Exit(I);
  end;
end;

procedure TFtPopupMenu.MouseMove(AX, AY: Integer);
var
  newIdx: Integer;
  item: TFtMenuItem;
  subX, subY: Integer;
  popWin: TFtWindow;
  screenNum, screenW: Integer;
begin
  newIdx := ItemAt(AX, AY);

  if (newIdx >= 0) and TFtMenuItem(FItems[newIdx]).IsSeparator then
    newIdx := -1;

  if newIdx <> FHoverIndex then
  begin
    FHoverIndex := newIdx;

    if FHoverIndex >= 0 then
    begin
      item := TFtMenuItem(FItems[FHoverIndex]);
      if item.Enabled and item.HasSubMenu() then
      begin
        if FActiveSubMenu <> item.SubMenu then
        begin
          if Assigned(FActiveSubMenu) then
            FActiveSubMenu.Close();
          FActiveSubMenu := item.SubMenu;
          FActiveSubMenu.FParentPopupMenu := Self;
          FActiveSubMenu.FParentMenuItem := item;
          FActiveSubMenu.RecalcLayout();

          popWin := TFtWindow(FPopupWindow);
          subX := popWin.X + Width - 2;
          subY := popWin.Y + item.Y - 2;

          screenW := popWin.ScreenWidth;
          if subX + FActiveSubMenu.Width > screenW then
            subX := popWin.X - FActiveSubMenu.Width + 2;

          FActiveSubMenu.Popup(subX, subY);
        end;
      end
      else
      begin
        if Assigned(FActiveSubMenu) then
        begin
          FActiveSubMenu.Close();
          FActiveSubMenu := nil;
        end;
      end;
    end
    else
    begin
      if Assigned(FActiveSubMenu) then
      begin
        FActiveSubMenu.Close();
        FActiveSubMenu := nil;
      end;
    end;

    if Assigned(FPopupWindow) then
      TFtWindow(FPopupWindow).Repaint();
  end;
end;

procedure TFtPopupMenu.MouseDown(AX, AY: Integer; AButton: Integer);
var
  idx: Integer;
begin
  if AButton = 1 then
  begin
    idx := ItemAt(AX, AY);
    if (idx >= 0) and not TFtMenuItem(FItems[idx]).IsSeparator and TFtMenuItem(FItems[idx]).Enabled then
    begin
      FPressedIndex := idx;
      FHoverIndex := idx;
      if Assigned(FPopupWindow) then
        TFtWindow(FPopupWindow).Repaint();
    end;
  end;
end;

procedure TFtPopupMenu.MouseUp(AX, AY: Integer; AButton: Integer);
var
  idx: Integer;
  item: TFtMenuItem;
begin
  if (AButton = 1) and (FPressedIndex >= 0) then
  begin
    idx := ItemAt(AX, AY);
    if idx = FPressedIndex then
    begin
      item := TFtMenuItem(FItems[idx]);
      if item.Enabled and not item.IsSeparator then
      begin
        if not item.HasSubMenu() then
        begin
          DismissAll();
          item.Click();
        end;
      end;
    end;
    FPressedIndex := -1;
    if Assigned(FPopupWindow) then
      TFtWindow(FPopupWindow).Repaint();
  end;
end;

procedure TFtPopupMenu.Click();
begin
  { Click dispatch handled through MouseUp or KeyPress }
end;

procedure TFtPopupMenu.SelectNext();
var
  startIdx, idx, cnt: Integer;
  item: TFtMenuItem;
begin
  cnt := FItems.Count;
  if cnt = 0 then Exit;
  startIdx := FHoverIndex;
  idx := startIdx;
  repeat
    idx := (idx + 1) mod cnt;
    item := TFtMenuItem(FItems[idx]);
    if item.Enabled and not item.IsSeparator then
    begin
      FHoverIndex := idx;
      if Assigned(FPopupWindow) then
        TFtWindow(FPopupWindow).Repaint();
      Exit;
    end;
  until idx = startIdx;
end;

procedure TFtPopupMenu.SelectPrev();
var
  startIdx, idx, cnt: Integer;
  item: TFtMenuItem;
begin
  cnt := FItems.Count;
  if cnt = 0 then Exit;
  startIdx := FHoverIndex;
  if startIdx < 0 then startIdx := 0;
  idx := startIdx;
  repeat
    idx := (idx - 1 + cnt) mod cnt;
    item := TFtMenuItem(FItems[idx]);
    if item.Enabled and not item.IsSeparator then
    begin
      FHoverIndex := idx;
      if Assigned(FPopupWindow) then
        TFtWindow(FPopupWindow).Repaint();
      Exit;
    end;
  until idx = startIdx;
end;

procedure TFtPopupMenu.ActivateSelected();
var
  item: TFtMenuItem;
begin
  if (FHoverIndex >= 0) and (FHoverIndex < FItems.Count) then
  begin
    item := TFtMenuItem(FItems[FHoverIndex]);
    if item.Enabled and not item.IsSeparator then
    begin
      if item.HasSubMenu() then
      begin
        MouseMove(item.X + 10, item.Y + 4);
        if Assigned(FActiveSubMenu) then
          FActiveSubMenu.SelectNext();
      end
      else
      begin
        DismissAll();
        item.Click();
      end;
    end;
  end;
end;

{ TFtMainMenu }

constructor TFtMainMenu.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FItems := TFPList.Create();
  FHoverIndex := -1;
  FActiveIndex := -1;
  X := 0;
  Y := 0;
  if Assigned(AParent) then
    Width := AParent.Width
  else
    Width := 800;
  Height := 28;
  Visible := True;
end;

destructor TFtMainMenu.Destroy();
var
  I: Integer;
begin
  CloseMenu();
  for I := 0 to FItems.Count - 1 do
    TFtMenuItem(FItems[I]).Free();
  FItems.Free();
  inherited Destroy();
end;

function TFtMainMenu.AddMenu(const ACaption: string): TFtPopupMenu;
var
  pop: TFtPopupMenu;
  item: TFtMenuItem;
begin
  pop := TFtPopupMenu.Create(Self);
  pop.ParentMainMenu := Self;
  item := TFtMenuItem.Create(Self);
  item.Caption := ACaption;
  item.SubMenu := pop;
  pop.FParentMenuItem := item;
  FItems.Add(item);
  RecalcLayout();
  Result := pop;
end;

function TFtMainMenu.AddItem(const ACaption: string; ASubMenu: TFtPopupMenu): TFtMenuItem;
var
  item: TFtMenuItem;
begin
  item := TFtMenuItem.Create(Self);
  item.Caption := ACaption;
  item.SubMenu := ASubMenu;
  if Assigned(ASubMenu) then
  begin
    ASubMenu.FParentMenuItem := item;
    ASubMenu.ParentMainMenu := Self;
  end;
  FItems.Add(item);
  RecalcLayout();
  Result := item;
end;

function TFtMainMenu.ItemCount(): Integer;
begin
  Result := FItems.Count;
end;

function TFtMainMenu.GetItem(AIndex: Integer): TFtMenuItem;
begin
  if (AIndex >= 0) and (AIndex < FItems.Count) then
    Result := TFtMenuItem(FItems[AIndex])
  else
    Result := nil;
end;

procedure TFtMainMenu.Clear();
var
  I: Integer;
begin
  CloseMenu();
  for I := 0 to FItems.Count - 1 do
    TFtMenuItem(FItems[I]).Free();
  FItems.Clear();
end;

procedure TFtMainMenu.RecalcLayout();
var
  I: Integer;
  item: TFtMenuItem;
  fnt: TFtFont;
  curX: Integer;
  tw: Double;
begin
  fnt := GetFont();
  curX := 0;

  for I := 0 to FItems.Count - 1 do
  begin
    item := TFtMenuItem(FItems[I]);
    if Assigned(fnt) then
      tw := fnt.GetTextWidth(item.Caption)
    else
      tw := Length(item.Caption) * 8.0;

    item.X := curX;
    item.Y := 0;
    item.Width := Round(tw) + 20;
    item.Height := Height - 1;
    curX := curX + item.Width;
  end;
end;

procedure TFtMainMenu.CloseMenu();
var
  item: TFtMenuItem;
  rootPop: TFtPopupMenu;
  popWin: TFtWindow;
begin
  if FActiveIndex >= 0 then
  begin
    item := TFtMenuItem(FItems[FActiveIndex]);
    if Assigned(item.SubMenu) then
    begin
      rootPop := item.SubMenu;
      while Assigned(rootPop.FParentPopupMenu) do
        rootPop := rootPop.FParentPopupMenu;

      if GGrabbedPopup = rootPop then
      begin
        popWin := TFtWindow(rootPop.FPopupWindow);
        if Assigned(popWin) then
          FtUngrabMenuInput(popWin);
        GGrabbedPopup := nil;
      end;
      item.SubMenu.Close();
    end;
    FActiveIndex := -1;
    FHoverIndex := -1;
    Invalidate();
  end
  else if FHoverIndex >= 0 then
  begin
    FHoverIndex := -1;
    Invalidate();
  end;
end;

procedure TFtMainMenu.Draw(Canvas: TFtCanvasAgg);
var
  I: Integer;
  item: TFtMenuItem;
  fnt: TFtFont;
begin
  if not Visible then Exit;

  { Draw menu bar plate background }
  FtGetTheme().DrawMenuBar(Canvas, X, Y, Width, Height);

  fnt := GetFont();

  { Draw top level items }
  for I := 0 to FItems.Count - 1 do
  begin
    item := TFtMenuItem(FItems[I]);
    FtGetTheme().DrawMenuBarItem(Canvas, X + item.X, Y + item.Y, item.Width, item.Height,
                                 item.Caption, fnt,
                                 (FHoverIndex = I), (FActiveIndex = I));
  end;
end;

function TFtMainMenu.HitTest(AX, AY: Integer): TFtWidget;
begin
  Result := nil;
  if not Visible then Exit;

  if (AX >= X) and (AX < X + Width) and (AY >= Y) and (AY < Y + Height) then
    Result := Self;
end;

function TFtMainMenu.ItemAt(AX, AY: Integer): Integer;
var
  relX, relY: Integer;
  I: Integer;
  item: TFtMenuItem;
begin
  Result := -1;
  relX := AX - X;
  relY := AY - Y;
  if (relY < 0) or (relY >= Height) then Exit;

  for I := 0 to FItems.Count - 1 do
  begin
    item := TFtMenuItem(FItems[I]);
    if (relX >= item.X) and (relX < item.X + item.Width) then
      Exit(I);
  end;
end;

procedure TFtMainMenu.MouseMove(AX, AY: Integer);
var
  newIdx: Integer;
  item: TFtMenuItem;
  rootWin: TFtWidget;
  pt: TPoint;
begin
  newIdx := ItemAt(AX, AY);

  if FActiveIndex >= 0 then
  begin
    { Dropdown already open: hovering over another top-level switches immediately }
    if (newIdx >= 0) and (newIdx <> FActiveIndex) then
    begin
      item := TFtMenuItem(FItems[FActiveIndex]);
      if Assigned(item.SubMenu) then
        item.SubMenu.Close();

      FActiveIndex := newIdx;
      FHoverIndex := newIdx;

      item := TFtMenuItem(FItems[newIdx]);
      if Assigned(item.SubMenu) then
      begin
        item.SubMenu.ParentMainMenu := Self;
        rootWin := GetRootWidget();
        if Assigned(rootWin) and (rootWin is TFtWindow) then
          pt := TFtWindow(rootWin).ClientToScreen(X + item.X, Y + Height)
        else
        begin
          pt.X := X + item.X;
          pt.Y := Y + Height;
        end;
        item.SubMenu.Popup(pt.X, pt.Y);
      end;

      Invalidate();
    end;
  end
  else
  begin
    if newIdx <> FHoverIndex then
    begin
      FHoverIndex := newIdx;
      Invalidate();
    end;
  end;
end;

procedure TFtMainMenu.MouseDown(AX, AY: Integer; AButton: Integer);
var
  idx: Integer;
  item: TFtMenuItem;
  rootWin: TFtWidget;
  pt: TPoint;
begin
  if AButton = 1 then
  begin
    idx := ItemAt(AX, AY);
    if idx >= 0 then
    begin
      if idx = FActiveIndex then
      begin
        { Clicking the already open dropdown closes it }
        CloseMenu();
      end
      else
      begin
        if FActiveIndex >= 0 then
          CloseMenu();

        FActiveIndex := idx;
        FHoverIndex := idx;
        item := TFtMenuItem(FItems[idx]);
        if Assigned(item.SubMenu) then
        begin
          item.SubMenu.ParentMainMenu := Self;
          rootWin := GetRootWidget();
          if Assigned(rootWin) and (rootWin is TFtWindow) then
            pt := TFtWindow(rootWin).ClientToScreen(X + item.X, Y + Height)
          else
          begin
            pt.X := X + item.X;
            pt.Y := Y + Height;
          end;
          item.SubMenu.Popup(pt.X, pt.Y);
        end;
        Invalidate();
      end;
    end;
  end;
end;

procedure TFtMainMenu.MouseUp(AX, AY: Integer; AButton: Integer);
begin
end;

procedure TFtMainMenu.MouseLeave();
begin
  if FActiveIndex < 0 then
  begin
    FHoverIndex := -1;
    Invalidate();
  end;
end;

end.
