// ft.widget.iconviews.pas — icon / grid view widget with flow layout and marquee selection
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit Ft.Widget.IconViews;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Math, Types,
  Floria.Image.Core, Ft.Canvas, Floria.Font, Ft.Widget, Ft.Widget.Containers,
  Ft.Widget.ScrollBars, Ft.Theme, Ft.Css, Ft.Icons;

type
  TFtIconZoomLevel = (izlSmall, izlNormal, izlLarge, izlHuge);

  TFtIconViewItem = class
  private
    FCaption: string;
    FSubText: string;
    FIcon: TFloriaImage;
    FIconName: string;
    FSelected: Boolean;
    FTag: Integer;
    FData: Pointer;
  public
    constructor Create(const ACaption: string = ''; AIcon: TFloriaImage = nil; const AIconName: string = '');
    destructor Destroy(); override;

    property Caption: string read FCaption write FCaption;
    property SubText: string read FSubText write FSubText;
    property Icon: TFloriaImage read FIcon write FIcon;
    property IconName: string read FIconName write FIconName;
    property Selected: Boolean read FSelected write FSelected;
    property Tag: Integer read FTag write FTag;
    property Data: Pointer read FData write FData;
  end;

  TFtIconCacheEntry = class
  public
    Name: string;
    Size: Integer;
    DarkMode: Boolean;
    Image: TFloriaImage;
    constructor Create(const AName: string; ASize: Integer; ADarkMode: Boolean; AImage: TFloriaImage);
    destructor Destroy(); override;
  end;

  TFtIconSelectEvent = procedure(Sender: TObject; ItemIndex: Integer) of object;
  TFtIconSelectCallback = procedure(Sender: Pointer; ItemIndex: Integer; UserData: Pointer); cdecl;
  TFtIconActivateEvent = procedure(Sender: TObject; ItemIndex: Integer) of object;
  TFtIconActivateCallback = procedure(Sender: Pointer; ItemIndex: Integer; UserData: Pointer); cdecl;
  TFtIconContextMenuEvent = procedure(Sender: TObject; ItemIndex: Integer; ScreenX, ScreenY: Integer) of object;
  TFtIconContextMenuCallback = procedure(Sender: Pointer; ItemIndex: Integer; ScreenX, ScreenY: Integer; UserData: Pointer); cdecl;

  TFtIconView = class(TFtContainer)
  private
    FItems: TFPList; // TFtIconViewItem
    FIconCache: TFPList; // TFtIconCacheEntry
    FSelectedIndex: Integer;
    FSelAnchorIndex: Integer;
    FHoveredIndex: Integer;
    FPressedIndex: Integer;
    FLastClickTime: QWord;
    FLastClickIndex: Integer;
    FMultiSelect: Boolean;

    FZoomLevel: TFtIconZoomLevel;
    FIconSize: Integer;
    FItemWidth: Double;
    FItemHeight: Double;
    FSpacingX: Double;
    FSpacingY: Double;
    FCols: Integer;

    // Marquee selection
    FIsDraggingMarquee: Boolean;
    FMarqueeStartX: Integer;
    FMarqueeStartY: Integer;
    FMarqueeCurX: Integer;
    FMarqueeCurY: Integer;
    FPreMarqueeSelection: array of Boolean;

    // Callbacks & Events
    FOnSelectItem: TFtIconSelectEvent;
    FOnSelectItemCb: TFtIconSelectCallback;
    FOnItemActivate: TFtIconActivateEvent;
    FOnItemActivateCb: TFtIconActivateCallback;
    FOnContextMenu: TFtIconContextMenuEvent;
    FOnContextMenuCb: TFtIconContextMenuCallback;
    FOnContextMenuUserData: Pointer;
    FOnItemActivateUserData: Pointer;

    procedure SetSelectedIndex(AValue: Integer);
    procedure SetMultiSelect(AValue: Boolean);
    procedure SetZoomLevel(AValue: TFtIconZoomLevel);
    procedure SetItemWidth(AValue: Double);
    procedure SetItemHeight(AValue: Double);
    procedure SetIconSize(AValue: Integer);
    procedure SetSpacingX(AValue: Double);
    procedure SetSpacingY(AValue: Double);
    function GetItemCount(): Integer;
    function GetItem(AIndex: Integer): TFtIconViewItem;
    procedure WrapTwoLines(const AText: string; AFont: TFtFont; AMaxW: Double; out Line1, Line2: string);
    function GetCachedIcon(const AName: string; ASize: Integer; ADarkMode: Boolean): TFloriaImage;
    procedure ClearIconCache();
  protected
    procedure DrawContent(Canvas: TFtCanvas); override;
    procedure GetRenderArea(out AX, AY, AW, AH, ARadius: Double); override;
    procedure SetScrollX(AValue: Double); override;
    procedure SetScrollY(AValue: Double); override;
  public
    constructor Create(AParent: TFtWidget); override;
    destructor Destroy(); override;

    function GetElementType(): string; override;
    procedure SetBounds(AX, AY, AW, AH: Integer); override;
    procedure UpdateLayout(); override;
    procedure RecalculateLayout();
    procedure ScrollIntoView(AIndex: Integer);

    procedure ZoomIn();
    procedure ZoomOut();

    function AddItem(const ACaption: string; AIcon: TFloriaImage = nil; const AIconName: string = ''): Integer;
    function InsertItem(AIndex: Integer; const ACaption: string; AIcon: TFloriaImage = nil; const AIconName: string = ''): Integer;
    procedure DeleteItem(AIndex: Integer);
    procedure Clear();

    function ItemAtPosition(AX, AY: Integer): Integer;
    function GetItemRect(AIndex: Integer; out ARectX, ARectY, ARectW, ARectH: Double): Boolean;

    procedure SelectAll();
    procedure ClearSelection();
    function IsItemSelected(AIndex: Integer): Boolean;
    procedure SetItemSelected(AIndex: Integer; ASelected: Boolean);
    function GetSelectedCount(): Integer;
    function GetSelectedIndices(): TIntegerDynArray;

    procedure MouseDown(AX, AY: Integer; AButton: Integer); override;
    procedure MouseMove(AX, AY: Integer); override;
    procedure MouseUp(AX, AY: Integer; AButton: Integer); override;
    procedure MouseLeave(); override;
    procedure KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string); override;

    property ItemCount: Integer read GetItemCount;
    property Items[AIndex: Integer]: TFtIconViewItem read GetItem;
    property SelectedIndex: Integer read FSelectedIndex write SetSelectedIndex;
    property MultiSelect: Boolean read FMultiSelect write SetMultiSelect;
    property ZoomLevel: TFtIconZoomLevel read FZoomLevel write SetZoomLevel;
    property IconSize: Integer read FIconSize write SetIconSize;
    property ItemWidth: Double read FItemWidth write SetItemWidth;
    property ItemHeight: Double read FItemHeight write SetItemHeight;
    property SpacingX: Double read FSpacingX write SetSpacingX;
    property SpacingY: Double read FSpacingY write SetSpacingY;
    property Columns: Integer read FCols;

    property OnSelectItem: TFtIconSelectEvent read FOnSelectItem write FOnSelectItem;
    property OnSelectItemCb: TFtIconSelectCallback read FOnSelectItemCb write FOnSelectItemCb;
    property OnItemActivate: TFtIconActivateEvent read FOnItemActivate write FOnItemActivate;
    property OnItemActivateCb: TFtIconActivateCallback read FOnItemActivateCb write FOnItemActivateCb;
    property OnItemActivateUserData: Pointer read FOnItemActivateUserData write FOnItemActivateUserData;
    property OnContextMenu: TFtIconContextMenuEvent read FOnContextMenu write FOnContextMenu;
    property OnContextMenuCb: TFtIconContextMenuCallback read FOnContextMenuCb write FOnContextMenuCb;
    property OnContextMenuUserData: Pointer read FOnContextMenuUserData write FOnContextMenuUserData;
  end;

implementation

{ TFtIconCacheEntry }

constructor TFtIconCacheEntry.Create(const AName: string; ASize: Integer; ADarkMode: Boolean; AImage: TFloriaImage);
begin
  inherited Create();
  Name := AName;
  Size := ASize;
  DarkMode := ADarkMode;
  Image := AImage;
end;

destructor TFtIconCacheEntry.Destroy();
begin
  if Assigned(Image) then
    FreeAndNil(Image);
  inherited Destroy();
end;

{ TFtIconViewItem }

constructor TFtIconViewItem.Create(const ACaption: string = ''; AIcon: TFloriaImage = nil; const AIconName: string = '');
begin
  inherited Create();
  FCaption := ACaption;
  FSubText := '';
  FIcon := AIcon;
  FIconName := AIconName;
  FSelected := False;
  FTag := 0;
  FData := nil;
end;

destructor TFtIconViewItem.Destroy();
begin
  inherited Destroy();
end;

{ TFtIconView }

constructor TFtIconView.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FItems := TFPList.Create();
  FIconCache := TFPList.Create();
  FSelectedIndex := -1;
  FSelAnchorIndex := -1;
  FHoveredIndex := -1;
  FPressedIndex := -1;
  FLastClickTime := 0;
  FLastClickIndex := -1;
  FMultiSelect := False;

  FZoomLevel := izlNormal;
  FIconSize := 48;
  FItemWidth := 96.0;
  FItemHeight := 104.0;
  FSpacingX := 8.0;
  FSpacingY := 8.0;
  FPaddingX := 8.0;
  FPaddingY := 8.0;
  FCols := 1;

  FFocusable := True;
  FDrawFrame := True;
  FScrollBarMode := ftSbModeAutoBoth;
  FCornerRadius := -1.0;
end;

procedure TFtIconView.ClearIconCache();
var
  i: Integer;
begin
  if Assigned(FIconCache) then
  begin
    for i := 0 to FIconCache.Count - 1 do
      TFtIconCacheEntry(FIconCache[i]).Free();
    FIconCache.Clear();
  end;
end;

destructor TFtIconView.Destroy();
var
  i: Integer;
begin
  ClearIconCache();
  FreeAndNil(FIconCache);
  for i := 0 to FItems.Count - 1 do
    TFtIconViewItem(FItems[i]).Free();
  FreeAndNil(FItems);
  SetLength(FPreMarqueeSelection, 0);
  inherited Destroy();
end;

function TFtIconView.GetElementType(): string;
begin
  Result := 'iconview';
end;

function TFtIconView.GetItemCount(): Integer;
begin
  Result := FItems.Count;
end;

function TFtIconView.GetItem(AIndex: Integer): TFtIconViewItem;
begin
  if (AIndex >= 0) and (AIndex < FItems.Count) then
    Result := TFtIconViewItem(FItems[AIndex])
  else
    Result := nil;
end;

procedure TFtIconView.SetSelectedIndex(AValue: Integer);
var
  i: Integer;
  changed: Boolean;
begin
  if (AValue < -1) or (AValue >= FItems.Count) then AValue := -1;
  changed := (FSelectedIndex <> AValue);

  FSelectedIndex := AValue;
  FSelAnchorIndex := AValue;

  for i := 0 to FItems.Count - 1 do
    TFtIconViewItem(FItems[i]).Selected := (i = FSelectedIndex);

  if FSelectedIndex >= 0 then
    ScrollIntoView(FSelectedIndex);

  Invalidate();

  if changed then
  begin
    if Assigned(FOnSelectItem) then
      FOnSelectItem(Self, FSelectedIndex);
    if Assigned(FOnSelectItemCb) then
      FOnSelectItemCb(Pointer(Self), FSelectedIndex, FUserData);
  end;
end;

procedure TFtIconView.SetMultiSelect(AValue: Boolean);
var
  i, sel: Integer;
begin
  if FMultiSelect <> AValue then
  begin
    FMultiSelect := AValue;
    if not FMultiSelect then
    begin
      if (FSelectedIndex >= 0) and (FSelectedIndex < FItems.Count) and TFtIconViewItem(FItems[FSelectedIndex]).Selected then
      begin
        for i := 0 to FItems.Count - 1 do
          TFtIconViewItem(FItems[i]).Selected := (i = FSelectedIndex);
      end
      else
      begin
        sel := -1;
        for i := 0 to FItems.Count - 1 do
        begin
          if (sel = -1) and TFtIconViewItem(FItems[i]).Selected then
            sel := i
          else
            TFtIconViewItem(FItems[i]).Selected := False;
        end;
        FSelectedIndex := sel;
        FSelAnchorIndex := sel;
      end;
      Invalidate();
    end;
  end;
end;

procedure TFtIconView.SetZoomLevel(AValue: TFtIconZoomLevel);
begin
  FZoomLevel := AValue;
  case AValue of
    izlSmall:
    begin
      FIconSize := 32;
      FItemWidth := 80.0;
      FItemHeight := 88.0;
    end;
    izlNormal:
    begin
      FIconSize := 48;
      FItemWidth := 96.0;
      FItemHeight := 104.0;
    end;
    izlLarge:
    begin
      FIconSize := 64;
      FItemWidth := 112.0;
      FItemHeight := 120.0;
    end;
    izlHuge:
    begin
      FIconSize := 96;
      FItemWidth := 144.0;
      FItemHeight := 152.0;
    end;
  end;
  RecalculateLayout();
end;

procedure TFtIconView.ZoomIn();
begin
  case FZoomLevel of
    izlSmall: SetZoomLevel(izlNormal);
    izlNormal: SetZoomLevel(izlLarge);
    izlLarge: SetZoomLevel(izlHuge);
    izlHuge: ; // already maximum
  end;
end;

procedure TFtIconView.ZoomOut();
begin
  case FZoomLevel of
    izlHuge: SetZoomLevel(izlLarge);
    izlLarge: SetZoomLevel(izlNormal);
    izlNormal: SetZoomLevel(izlSmall);
    izlSmall: ; // already minimum
  end;
end;

function TFtIconView.GetCachedIcon(const AName: string; ASize: Integer; ADarkMode: Boolean): TFloriaImage;
var
  i: Integer;
  entry: TFtIconCacheEntry;
  img: TFloriaImage;
begin
  Result := nil;
  if (AName = '') or (FIconCache = nil) then Exit;

  for i := 0 to FIconCache.Count - 1 do
  begin
    entry := TFtIconCacheEntry(FIconCache[i]);
    if (entry.Name = AName) and (entry.Size = ASize) and (entry.DarkMode = ADarkMode) then
      Exit(entry.Image);
  end;

  img := FtGetIconBitmap(AName, ASize, ASize, ADarkMode);
  if Assigned(img) then
  begin
    entry := TFtIconCacheEntry.Create(AName, ASize, ADarkMode, img);
    FIconCache.Add(entry);
    Result := img;
  end;
end;

procedure TFtIconView.SetItemWidth(AValue: Double);
begin
  if AValue < 40.0 then AValue := 40.0;
  if FItemWidth <> AValue then
  begin
    FItemWidth := AValue;
    RecalculateLayout();
  end;
end;

procedure TFtIconView.SetItemHeight(AValue: Double);
begin
  if AValue < 40.0 then AValue := 40.0;
  if FItemHeight <> AValue then
  begin
    FItemHeight := AValue;
    RecalculateLayout();
  end;
end;

procedure TFtIconView.SetIconSize(AValue: Integer);
begin
  if AValue < 16 then AValue := 16;
  if FIconSize <> AValue then
  begin
    FIconSize := AValue;
    Invalidate();
  end;
end;

procedure TFtIconView.SetSpacingX(AValue: Double);
begin
  if AValue < 0.0 then AValue := 0.0;
  if FSpacingX <> AValue then
  begin
    FSpacingX := AValue;
    RecalculateLayout();
  end;
end;

procedure TFtIconView.SetSpacingY(AValue: Double);
begin
  if AValue < 0.0 then AValue := 0.0;
  if FSpacingY <> AValue then
  begin
    FSpacingY := AValue;
    RecalculateLayout();
  end;
end;

procedure TFtIconView.SetBounds(AX, AY, AW, AH: Integer);
begin
  inherited SetBounds(AX, AY, AW, AH);
  RecalculateLayout();
end;

procedure TFtIconView.UpdateLayout();
begin
  inherited UpdateLayout();
  RecalculateLayout();
end;

procedure TFtIconView.RecalculateLayout();
var
  availW, totalH: Double;
  rows: Integer;
  vBarW: Double;
begin
  vBarW := 0.0;
  if Assigned(FVScrollBar) and FVScrollBar.Visible then
    vBarW := FVScrollBar.Width + 2.0;

  availW := Math.Max(FItemWidth, Width - (FPaddingX * 2.0) - vBarW);
  FCols := Math.Max(1, Trunc((availW + FSpacingX) / (FItemWidth + FSpacingX)));

  if FItems.Count > 0 then
  begin
    rows := (FItems.Count + FCols - 1) div FCols;
    totalH := (FPaddingY * 2.0) + (rows * FItemHeight) + Math.Max(0, rows - 1) * FSpacingY;
  end
  else
    totalH := 0.0;

  ContentHeight := totalH;
  ContentWidth := Width;
  UpdateScrollBars();
  Invalidate();
end;

procedure TFtIconView.GetRenderArea(out AX, AY, AW, AH, ARadius: Double);
var
  bw: Double;
  st: TFtWidgetStyle;
  vBarW, hBarH: Double;
begin
  vBarW := 0.0;
  hBarH := 0.0;
  if Assigned(FVScrollBar) and FVScrollBar.Visible then
    vBarW := FVScrollBar.Width + 2.0;
  if Assigned(FHScrollBar) and FHScrollBar.Visible then
    hBarH := FHScrollBar.Height + 2.0;

  bw := 0.0;
  if FDrawFrame then
  begin
    st := GetResolvedStyle();
    bw := 1.0;
    if st.HasBorderWidth then bw := st.BorderWidth;
  end;

  AX := X + bw;
  AY := Y + bw;
  AW := Math.Max(0.0, Width - (bw * 2.0) - vBarW);
  AH := Math.Max(0.0, Height - (bw * 2.0) - hBarH);
  ARadius := Math.Max(0.0, GetEffectiveCornerRadius() - bw);
end;

procedure TFtIconView.SetScrollX(AValue: Double);
begin
  inherited SetScrollX(0.0);
end;

procedure TFtIconView.SetScrollY(AValue: Double);
var
  maxScroll, viewH: Double;
begin
  viewH := Math.Max(0.0, Height - (FPaddingY * 2.0));
  maxScroll := Math.Max(0.0, FContentHeight - viewH);
  if AValue > maxScroll then AValue := maxScroll;
  if AValue < 0.0 then AValue := 0.0;
  inherited SetScrollY(AValue);
end;

procedure TFtIconView.ScrollIntoView(AIndex: Integer);
var
  row: Integer;
  itemTop, itemBottom, viewH: Double;
begin
  if (AIndex < 0) or (AIndex >= FItems.Count) or (FCols <= 0) then Exit;

  row := AIndex div FCols;
  itemTop := FPaddingY + (row * (FItemHeight + FSpacingY));
  itemBottom := itemTop + FItemHeight;
  viewH := Math.Max(0.0, Height - (FPaddingY * 2.0));

  if itemTop < FScrollY then
    SetScrollY(Math.Max(0.0, itemTop - FPaddingY))
  else if itemBottom > (FScrollY + viewH) then
    SetScrollY(itemBottom - viewH + FPaddingY);
end;

function TFtIconView.AddItem(const ACaption: string; AIcon: TFloriaImage = nil; const AIconName: string = ''): Integer;
var
  item: TFtIconViewItem;
begin
  item := TFtIconViewItem.Create(ACaption, AIcon, AIconName);
  Result := FItems.Add(item);
  RecalculateLayout();
end;

function TFtIconView.InsertItem(AIndex: Integer; const ACaption: string; AIcon: TFloriaImage = nil; const AIconName: string = ''): Integer;
var
  item: TFtIconViewItem;
begin
  if (AIndex < 0) or (AIndex > FItems.Count) then AIndex := FItems.Count;
  item := TFtIconViewItem.Create(ACaption, AIcon, AIconName);
  FItems.Insert(AIndex, item);
  if (FSelectedIndex >= AIndex) and (FSelectedIndex >= 0) then
    Inc(FSelectedIndex);
  if (FSelAnchorIndex >= AIndex) and (FSelAnchorIndex >= 0) then
    Inc(FSelAnchorIndex);
  Result := AIndex;
  RecalculateLayout();
end;

procedure TFtIconView.DeleteItem(AIndex: Integer);
var
  item: TFtIconViewItem;
begin
  if (AIndex < 0) or (AIndex >= FItems.Count) then Exit;
  item := TFtIconViewItem(FItems[AIndex]);
  FItems.Delete(AIndex);
  item.Free();

  if FSelectedIndex = AIndex then
  begin
    if FSelectedIndex >= FItems.Count then
      FSelectedIndex := FItems.Count - 1;
    if (FSelectedIndex >= 0) and not FMultiSelect then
      TFtIconViewItem(FItems[FSelectedIndex]).Selected := True;
  end
  else if FSelectedIndex > AIndex then
    Dec(FSelectedIndex);

  if FSelAnchorIndex = AIndex then
    FSelAnchorIndex := FSelectedIndex
  else if FSelAnchorIndex > AIndex then
    Dec(FSelAnchorIndex);

  RecalculateLayout();
end;

procedure TFtIconView.Clear();
var
  i: Integer;
begin
  for i := 0 to FItems.Count - 1 do
    TFtIconViewItem(FItems[i]).Free();
  FItems.Clear();
  FSelectedIndex := -1;
  FSelAnchorIndex := -1;
  FHoveredIndex := -1;
  FPressedIndex := -1;
  RecalculateLayout();
end;

function TFtIconView.ItemAtPosition(AX, AY: Integer): Integer;
var
  relX, relY: Double;
  col, row, idx: Integer;
  itemX, itemY: Double;
begin
  Result := -1;
  if (FCols <= 0) or (FItems.Count = 0) then Exit;

  relX := (AX - X - FPaddingX) + FScrollX;
  relY := (AY - Y - FPaddingY) + FScrollY;

  if (relX < 0.0) or (relY < 0.0) then Exit;

  col := Trunc(relX / (FItemWidth + FSpacingX));
  row := Trunc(relY / (FItemHeight + FSpacingY));

  if (col < 0) or (col >= FCols) then Exit;

  idx := (row * FCols) + col;
  if (idx < 0) or (idx >= FItems.Count) then Exit;

  itemX := col * (FItemWidth + FSpacingX);
  itemY := row * (FItemHeight + FSpacingY);

  if (relX >= itemX) and (relX <= itemX + FItemWidth) and
     (relY >= itemY) and (relY <= itemY + FItemHeight) then
    Result := idx;
end;

function TFtIconView.GetItemRect(AIndex: Integer; out ARectX, ARectY, ARectW, ARectH: Double): Boolean;
var
  col, row: Integer;
begin
  if (AIndex < 0) or (AIndex >= FItems.Count) or (FCols <= 0) then
  begin
    ARectX := 0; ARectY := 0; ARectW := 0; ARectH := 0;
    Exit(False);
  end;

  col := AIndex mod FCols;
  row := AIndex div FCols;

  ARectX := X + FPaddingX + (col * (FItemWidth + FSpacingX)) - FScrollX;
  ARectY := Y + FPaddingY + (row * (FItemHeight + FSpacingY)) - FScrollY;
  ARectW := FItemWidth;
  ARectH := FItemHeight;
  Result := True;
end;

procedure TFtIconView.SelectAll();
var
  i: Integer;
begin
  if not FMultiSelect or (FItems.Count = 0) then Exit;
  for i := 0 to FItems.Count - 1 do
    TFtIconViewItem(FItems[i]).Selected := True;
  if FSelectedIndex < 0 then
    FSelectedIndex := 0;
  if FSelAnchorIndex < 0 then
    FSelAnchorIndex := 0;
  Invalidate();
  if Assigned(FOnSelectItem) then
    FOnSelectItem(Self, FSelectedIndex);
  if Assigned(FOnSelectItemCb) then
    FOnSelectItemCb(Pointer(Self), FSelectedIndex, FUserData);
end;

procedure TFtIconView.ClearSelection();
var
  i: Integer;
  hadSel: Boolean;
begin
  hadSel := False;
  for i := 0 to FItems.Count - 1 do
  begin
    if TFtIconViewItem(FItems[i]).Selected then
    begin
      TFtIconViewItem(FItems[i]).Selected := False;
      hadSel := True;
    end;
  end;
  if (FSelectedIndex >= 0) or hadSel then
  begin
    FSelectedIndex := -1;
    FSelAnchorIndex := -1;
    Invalidate();
    if Assigned(FOnSelectItem) then
      FOnSelectItem(Self, -1);
    if Assigned(FOnSelectItemCb) then
      FOnSelectItemCb(Pointer(Self), -1, FUserData);
  end;
end;

function TFtIconView.IsItemSelected(AIndex: Integer): Boolean;
var
  it: TFtIconViewItem;
begin
  it := GetItem(AIndex);
  if Assigned(it) then
    Result := it.Selected
  else
    Result := False;
end;

procedure TFtIconView.SetItemSelected(AIndex: Integer; ASelected: Boolean);
var
  it: TFtIconViewItem;
  i: Integer;
begin
  it := GetItem(AIndex);
  if not Assigned(it) then Exit;

  if not FMultiSelect and ASelected then
  begin
    for i := 0 to FItems.Count - 1 do
      TFtIconViewItem(FItems[i]).Selected := (i = AIndex);
    FSelectedIndex := AIndex;
    FSelAnchorIndex := AIndex;
  end
  else
  begin
    it.Selected := ASelected;
    if ASelected then
    begin
      FSelectedIndex := AIndex;
      FSelAnchorIndex := AIndex;
    end
    else if FSelectedIndex = AIndex then
    begin
      FSelectedIndex := -1;
      for i := 0 to FItems.Count - 1 do
      begin
        if TFtIconViewItem(FItems[i]).Selected then
        begin
          FSelectedIndex := i;
          Break;
        end;
      end;
    end;
  end;
  Invalidate();
end;

function TFtIconView.GetSelectedCount(): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to FItems.Count - 1 do
    if TFtIconViewItem(FItems[i]).Selected then
      Inc(Result);
end;

function TFtIconView.GetSelectedIndices(): TIntegerDynArray;
var
  i, cnt, idx: Integer;
begin
  cnt := GetSelectedCount();
  SetLength(Result, cnt);
  idx := 0;
  for i := 0 to FItems.Count - 1 do
  begin
    if TFtIconViewItem(FItems[i]).Selected then
    begin
      Result[idx] := i;
      Inc(idx);
    end;
  end;
end;

procedure TFtIconView.MouseDown(AX, AY: Integer; AButton: Integer);
var
  hitIdx: Integer;
  mods: Cardinal;
  hasCtrl, hasShift: Boolean;
  nowTime: QWord;
  isDblClick: Boolean;
  minIdx, maxIdx, i: Integer;
begin
  mods := FtGetKeyboardModifiers();
  hasCtrl := (mods and FT_KEY_MOD_CONTROL) <> 0;
  hasShift := (mods and FT_KEY_MOD_SHIFT) <> 0;

  // Ctrl + MouseWheel zoom
  if hasCtrl and (AButton = 4) then
  begin
    ZoomIn();
    Exit;
  end;
  if hasCtrl and (AButton = 5) then
  begin
    ZoomOut();
    Exit;
  end;

  inherited MouseDown(AX, AY, AButton);

  if not FFocused and CanFocus() then
    SetFocus();

  hitIdx := ItemAtPosition(AX, AY);

  if AButton = 1 then
  begin
    if hitIdx >= 0 then
    begin
      FPressedIndex := hitIdx;

      nowTime := GetTickCount64();
      isDblClick := (hitIdx = FLastClickIndex) and ((nowTime - FLastClickTime) < 400);
      if isDblClick then
        FLastClickTime := 0
      else
        FLastClickTime := nowTime;
      FLastClickIndex := hitIdx;

      if not FMultiSelect then
      begin
        SelectedIndex := hitIdx;
      end
      else
      begin
        if hasShift then
        begin
          if FSelAnchorIndex < 0 then
          begin
            if FSelectedIndex >= 0 then
              FSelAnchorIndex := FSelectedIndex
            else
              FSelAnchorIndex := 0;
          end;

          if not hasCtrl then
          begin
            for i := 0 to FItems.Count - 1 do
              TFtIconViewItem(FItems[i]).Selected := False;
          end;

          minIdx := Min(FSelAnchorIndex, hitIdx);
          maxIdx := Max(FSelAnchorIndex, hitIdx);
          for i := minIdx to maxIdx do
            TFtIconViewItem(FItems[i]).Selected := True;

          FSelectedIndex := hitIdx;
          Invalidate();
          if Assigned(FOnSelectItem) then
            FOnSelectItem(Self, FSelectedIndex);
          if Assigned(FOnSelectItemCb) then
            FOnSelectItemCb(Pointer(Self), FSelectedIndex, FUserData);
        end
        else if hasCtrl then
        begin
          TFtIconViewItem(FItems[hitIdx]).Selected := not TFtIconViewItem(FItems[hitIdx]).Selected;
          FSelectedIndex := hitIdx;
          FSelAnchorIndex := hitIdx;
          Invalidate();
          if Assigned(FOnSelectItem) then
            FOnSelectItem(Self, FSelectedIndex);
          if Assigned(FOnSelectItemCb) then
            FOnSelectItemCb(Pointer(Self), FSelectedIndex, FUserData);
        end
        else
        begin
          if not TFtIconViewItem(FItems[hitIdx]).Selected then
          begin
            for i := 0 to FItems.Count - 1 do
              TFtIconViewItem(FItems[i]).Selected := (i = hitIdx);
            FSelectedIndex := hitIdx;
            FSelAnchorIndex := hitIdx;
            Invalidate();
            if Assigned(FOnSelectItem) then
              FOnSelectItem(Self, FSelectedIndex);
            if Assigned(FOnSelectItemCb) then
              FOnSelectItemCb(Pointer(Self), FSelectedIndex, FUserData);
          end;
        end;
      end;

      if isDblClick then
      begin
        if Assigned(FOnItemActivate) then
          FOnItemActivate(Self, hitIdx);
        if Assigned(FOnItemActivateCb) then
          FOnItemActivateCb(Pointer(Self), hitIdx, FOnItemActivateUserData);
      end;
    end
    else
    begin
      FPressedIndex := -1;
      if not hasCtrl and not hasShift then
        ClearSelection();

      FIsDraggingMarquee := True;
      FMarqueeStartX := AX;
      FMarqueeStartY := AY;
      FMarqueeCurX := AX;
      FMarqueeCurY := AY;
      SetLength(FPreMarqueeSelection, FItems.Count);
      for i := 0 to FItems.Count - 1 do
        FPreMarqueeSelection[i] := TFtIconViewItem(FItems[i]).Selected;
    end;
  end
  else if AButton = 3 then
  begin
    if hitIdx >= 0 then
    begin
      if not IsItemSelected(hitIdx) then
      begin
        if not hasCtrl then
          ClearSelection();
        SetItemSelected(hitIdx, True);
      end;
    end;

    if Assigned(FOnContextMenu) then
      FOnContextMenu(Self, hitIdx, AX, AY);
    if Assigned(FOnContextMenuCb) then
      FOnContextMenuCb(Pointer(Self), hitIdx, AX, AY, FOnContextMenuUserData);
  end;
end;

procedure TFtIconView.MouseMove(AX, AY: Integer);
var
  newHover, i: Integer;
  mqX1, mqY1, mqX2, mqY2: Double;
  cellX, cellY, cellW, cellH: Double;
  intersects: Boolean;
begin
  inherited MouseMove(AX, AY);

  if FIsDraggingMarquee then
  begin
    FMarqueeCurX := AX;
    FMarqueeCurY := AY;

    mqX1 := Min(FMarqueeStartX, FMarqueeCurX);
    mqY1 := Min(FMarqueeStartY, FMarqueeCurY);
    mqX2 := Max(FMarqueeStartX, FMarqueeCurX);
    mqY2 := Max(FMarqueeStartY, FMarqueeCurY);

    for i := 0 to FItems.Count - 1 do
    begin
      if GetItemRect(i, cellX, cellY, cellW, cellH) then
      begin
        intersects := not ((cellX + cellW < mqX1) or (cellX > mqX2) or
                           (cellY + cellH < mqY1) or (cellY > mqY2));
        if intersects then
          TFtIconViewItem(FItems[i]).Selected := True
        else if (i < Length(FPreMarqueeSelection)) then
          TFtIconViewItem(FItems[i]).Selected := FPreMarqueeSelection[i];
      end;
    end;
    Invalidate();
  end
  else
  begin
    newHover := ItemAtPosition(AX, AY);
    if newHover <> FHoveredIndex then
    begin
      FHoveredIndex := newHover;
      Invalidate();
    end;
  end;
end;

procedure TFtIconView.MouseUp(AX, AY: Integer; AButton: Integer);
var
  relIdx, i: Integer;
  mods: Cardinal;
  hasCtrl, hasShift: Boolean;
begin
  inherited MouseUp(AX, AY, AButton);

  if AButton = 1 then
  begin
    if FIsDraggingMarquee then
    begin
      FIsDraggingMarquee := False;
      SetLength(FPreMarqueeSelection, 0);
      Invalidate();
      Exit;
    end;

    if FPressedIndex >= 0 then
    begin
      relIdx := ItemAtPosition(AX, AY);
      if relIdx = FPressedIndex then
      begin
        mods := FtGetKeyboardModifiers();
        hasCtrl := (mods and FT_KEY_MOD_CONTROL) <> 0;
        hasShift := (mods and FT_KEY_MOD_SHIFT) <> 0;

        if FMultiSelect and not hasCtrl and not hasShift and (GetSelectedCount() > 1) then
        begin
          for i := 0 to FItems.Count - 1 do
            TFtIconViewItem(FItems[i]).Selected := (i = relIdx);
          FSelectedIndex := relIdx;
          FSelAnchorIndex := relIdx;
          Invalidate();
        end;

        if Assigned(FOnSelectItem) then
          FOnSelectItem(Self, FSelectedIndex);
        if Assigned(FOnSelectItemCb) then
          FOnSelectItemCb(Pointer(Self), FSelectedIndex, FUserData);
      end;
      FPressedIndex := -1;
    end;
  end;
end;

procedure TFtIconView.MouseLeave();
begin
  inherited MouseLeave();
  FPressedIndex := -1;
  if FHoveredIndex >= 0 then
  begin
    FHoveredIndex := -1;
    Invalidate();
  end;
end;

procedure TFtIconView.KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string);
var
  hasCtrl, hasShift: Boolean;
  targetIdx, minIdx, maxIdx, i: Integer;
begin
  inherited KeyDown(AKeySym, AState, AChar);

  hasCtrl := (AState and FT_KEY_MOD_CONTROL) <> 0;
  hasShift := (AState and FT_KEY_MOD_SHIFT) <> 0;

  // Return / Enter ($FF0D, $FF8D): Activate selected item
  if ((AKeySym = $FF0D) or (AKeySym = $FF8D)) and (FSelectedIndex >= 0) and (FSelectedIndex < FItems.Count) then
  begin
    if Assigned(FOnItemActivate) then
      FOnItemActivate(Self, FSelectedIndex);
    if Assigned(FOnItemActivateCb) then
      FOnItemActivateCb(Pointer(Self), FSelectedIndex, FOnItemActivateUserData);
    Exit;
  end;

  // Space ($0020): Toggle selection
  if (AKeySym = $0020) and (FSelectedIndex >= 0) and (FSelectedIndex < FItems.Count) then
  begin
    if FMultiSelect then
      TFtIconViewItem(FItems[FSelectedIndex]).Selected := not TFtIconViewItem(FItems[FSelectedIndex]).Selected
    else
      TFtIconViewItem(FItems[FSelectedIndex]).Selected := True;
    Invalidate();
    Exit;
  end;

  // Ctrl + A: Select All
  if FMultiSelect and hasCtrl and ((AKeySym = $61) or (AKeySym = $41) or (AChar = 'a') or (AChar = 'A')) then
  begin
    SelectAll();
    Exit;
  end;

  // Escape ($FF1B): Clear selection
  if (AKeySym = $FF1B) then
  begin
    ClearSelection();
    Exit;
  end;

  // Ctrl + Plus / Equal / KP_Add: Zoom In
  if hasCtrl and ((AKeySym = $002B) or (AKeySym = $003D) or (AKeySym = $FFAB)) then
  begin
    ZoomIn();
    Exit;
  end;

  // Ctrl + Minus / KP_Subtract: Zoom Out
  if hasCtrl and ((AKeySym = $002D) or (AKeySym = $FFAD)) then
  begin
    ZoomOut();
    Exit;
  end;

  // Ctrl + 0: Reset Zoom
  if hasCtrl and ((AKeySym = $0030) or (AKeySym = $FFB0)) then
  begin
    SetZoomLevel(izlNormal);
    Exit;
  end;

  if FItems.Count = 0 then Exit;

  targetIdx := FSelectedIndex;

  case AKeySym of
    $FF51: // Left
    begin
      if targetIdx > 0 then
        Dec(targetIdx)
      else
        targetIdx := 0;
    end;
    $FF53: // Right
    begin
      if targetIdx < FItems.Count - 1 then
        Inc(targetIdx)
      else
        targetIdx := FItems.Count - 1;
    end;
    $FF52: // Up
    begin
      if targetIdx >= FCols then
        targetIdx := targetIdx - FCols
      else
        targetIdx := 0;
    end;
    $FF54: // Down
    begin
      if targetIdx + FCols < FItems.Count then
        targetIdx := targetIdx + FCols
      else
        targetIdx := FItems.Count - 1;
    end;
    $FF50: // Home
      targetIdx := 0;
    $FF57: // End
      targetIdx := FItems.Count - 1;
    $FF55: // PageUp
      targetIdx := Math.Max(0, targetIdx - (FCols * 3));
    $FF56: // PageDown
      targetIdx := Math.Min(FItems.Count - 1, targetIdx + (FCols * 3));
    else
      Exit;
  end;

  if FMultiSelect and hasShift then
  begin
    if FSelAnchorIndex < 0 then
      FSelAnchorIndex := FSelectedIndex;
    if FSelAnchorIndex < 0 then
      FSelAnchorIndex := 0;

    for i := 0 to FItems.Count - 1 do
      TFtIconViewItem(FItems[i]).Selected := False;

    minIdx := Min(FSelAnchorIndex, targetIdx);
    maxIdx := Max(FSelAnchorIndex, targetIdx);
    for i := minIdx to maxIdx do
      TFtIconViewItem(FItems[i]).Selected := True;

    FSelectedIndex := targetIdx;
    ScrollIntoView(targetIdx);
    Invalidate();
    if Assigned(FOnSelectItem) then
      FOnSelectItem(Self, FSelectedIndex);
    if Assigned(FOnSelectItemCb) then
      FOnSelectItemCb(Pointer(Self), FSelectedIndex, FUserData);
  end
  else
  begin
    SelectedIndex := targetIdx;
  end;
end;

procedure TFtIconView.WrapTwoLines(const AText: string; AFont: TFtFont; AMaxW: Double; out Line1, Line2: string);
var
  i, lastSpace: Integer;
  curStr, sub: string;
begin
  Line1 := '';
  Line2 := '';
  if AText = '' then Exit;

  if (AFont = nil) or (AFont.GetTextWidth(AText) <= AMaxW) then
  begin
    Line1 := AText;
    Exit;
  end;

  lastSpace := 0;
  for i := 1 to Length(AText) do
  begin
    if AText[i] = ' ' then
      lastSpace := i;
    curStr := Copy(AText, 1, i);
    if AFont.GetTextWidth(curStr) > AMaxW then
    begin
      if (lastSpace > 0) and (lastSpace >= i div 2) then
      begin
        Line1 := Copy(AText, 1, lastSpace - 1);
        sub := Copy(AText, lastSpace + 1, MaxInt);
      end
      else
      begin
        Line1 := Copy(AText, 1, i - 1);
        sub := Copy(AText, i, MaxInt);
      end;
      Line2 := FtFitTextWithEllipsis(Trim(sub), AFont, AMaxW);
      Exit;
    end;
  end;

  Line1 := AText;
end;

procedure TFtIconView.DrawContent(Canvas: TFtCanvas);
var
  theme: TFtTheme;
  accent: TFtRgbColor;
  i: Integer;
  cellX, cellY, cellW, cellH: Double;
  isSelected, isHovered: Boolean;
  textR, textG, textB: Double;
  iconX, iconY: Integer;
  item: TFtIconViewItem;
  capW, textX, textY, lineH, subY: Double;
  line1, line2: string;
  fnt: TFtFont;
  mqX1, mqY1, mqW, mqH: Double;
  iconImg, cachedImg: TFloriaImage;
begin
  theme := FtGetTheme();
  accent := theme.GetAccentColor();
  fnt := Font;

  for i := 0 to FItems.Count - 1 do
  begin
    item := TFtIconViewItem(FItems[i]);
    if not GetItemRect(i, cellX, cellY, cellW, cellH) then
      Continue;

    // Viewport culling
    if (cellY + cellH < Y) or (cellY > Y + Height) then
      Continue;

    isSelected := item.Selected;
    isHovered := (i = FHoveredIndex);

    // Draw item background plate
    if isSelected then
    begin
      Canvas.DrawRoundedRect(cellX, cellY, cellW, cellH, 6.0, accent.R, accent.G, accent.B, 0.28);
      Canvas.DrawRoundedRectOutline(cellX, cellY, cellW, cellH, 6.0, 1.0, accent.R, accent.G, accent.B, 0.85);
      if theme.DarkMode then
      begin textR := 1.0; textG := 1.0; textB := 1.0; end
      else
      begin textR := 0.05; textG := 0.10; textB := 0.15; end;
    end
    else if isHovered then
    begin
      if theme.DarkMode then
        Canvas.DrawRoundedRect(cellX, cellY, cellW, cellH, 6.0, 0.25, 0.28, 0.35, 0.5)
      else
        Canvas.DrawRoundedRect(cellX, cellY, cellW, cellH, 6.0, 0.88, 0.90, 0.95, 0.6);

      if theme.DarkMode then
      begin textR := 0.92; textG := 0.92; textB := 0.94; end
      else
      begin textR := 0.12; textG := 0.14; textB := 0.18; end;
    end
    else
    begin
      if theme.DarkMode then
      begin textR := 0.85; textG := 0.86; textB := 0.90; end
      else
      begin textR := 0.18; textG := 0.20; textB := 0.24; end;
    end;

    // Draw Icon (centered horizontally)
    iconX := Round(cellX + (cellW - FIconSize) * 0.5);
    iconY := Round(cellY + 8.0);
    iconImg := item.Icon;
    if (item.IconName <> '') then
    begin
      cachedImg := GetCachedIcon(item.IconName, FIconSize, theme.DarkMode);
      if Assigned(cachedImg) then
        iconImg := cachedImg;
    end;
    if Assigned(iconImg) and (iconImg.Width > 0) and (iconImg.Height > 0) then
      Canvas.DrawImageScaled(iconX, iconY, FIconSize, FIconSize, iconImg, 1.0);

    // Draw Caption text
    textX := cellX + 4.0;
    capW := cellW - 8.0;
    textY := iconY + FIconSize + 6.0;
    lineH := 16.0;

    WrapTwoLines(item.Caption, fnt, capW, line1, line2);

    if line2 = '' then
    begin
      Canvas.DrawTextCentered(Round(textX), Round(textY), Round(capW), Round(lineH), line1, fnt, textR, textG, textB);
    end
    else
    begin
      Canvas.DrawTextCentered(Round(textX), Round(textY), Round(capW), Round(lineH), line1, fnt, textR, textG, textB);
      Canvas.DrawTextCentered(Round(textX), Round(textY + lineH), Round(capW), Round(lineH), line2, fnt, textR, textG, textB);
    end;

    // Optional SubText (e.g. file size)
    if item.SubText <> '' then
    begin
      if line2 = '' then
        subY := textY + lineH
      else
        subY := textY + (lineH * 2.0);
      Canvas.DrawTextCentered(Round(textX), Round(subY), Round(capW), Round(lineH - 2.0),
        FtFitTextWithEllipsis(item.SubText, fnt, capW), fnt, textR * 0.7, textG * 0.7, textB * 0.7);
    end;
  end;

  // Draw Marquee drag rectangle
  if FIsDraggingMarquee then
  begin
    mqX1 := Min(FMarqueeStartX, FMarqueeCurX);
    mqY1 := Min(FMarqueeStartY, FMarqueeCurY);
    mqW := Abs(FMarqueeCurX - FMarqueeStartX);
    mqH := Abs(FMarqueeCurY - FMarqueeStartY);
    if (mqW > 2.0) and (mqH > 2.0) then
    begin
      Canvas.DrawRect(Round(mqX1), Round(mqY1), Round(mqW), Round(mqH), accent.R, accent.G, accent.B, 0.20);
      Canvas.DrawRoundedRectOutline(mqX1, mqY1, mqW, mqH, 0.0, 1.0, accent.R, accent.G, accent.B, 0.85);
    end;
  end;
end;

end.
