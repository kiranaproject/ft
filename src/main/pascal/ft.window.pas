unit Ft.Window;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Types,
  Floria.Canvas.Agg, Ft.Widget, Ft.Theme, Ft.Css;

type
  TFtWindowType = (
    ftwtNormal = 0,
    ftwtDialog = 1,
    ftwtPopupMenu = 2,
    ftwtDropdownMenu = 3,
    ftwtTooltip = 4,
    ftwtUtility = 5
  );

  TFtSelectionLostHandler = procedure();

  TFtWindow = class(TFtWidget)
  protected
    FTitle: string;
    FBorderless: Boolean;
    FSkipTaskbar: Boolean;
    FWindowType: TFtWindowType;
    FWindowOpacity: Double;
    FBackgroundOpacity: Double;
    FBackgroundBlur: Boolean;
    FHoverWidget: TFtWidget;
    FPressedWidget: TFtWidget;
    FFocusedWidget: TFtWidget;
    FMainMenu: TFtWidget;
    FActivePopup: TFtWidget;
    FNeedsRepaint: Boolean;
    FDirtyLeft: Integer;
    FDirtyTop: Integer;
    FDirtyRight: Integer;
    FDirtyBottom: Integer;
    FHasDirtyRect: Boolean;
    FFullRepaint: Boolean;
    FPixelBuffer: PByte;
    FCanvas: TFtCanvasAgg;

    procedure OnThemeChanged(); virtual;
    procedure OnStyleSheetChanged(); virtual;
  public
    constructor Create(W, H: Integer; const ATitle: string = ''); reintroduce; virtual;
    destructor Destroy(); override;

    function GetElementType(): string; override;
    function GetScreenWidth(): Integer; virtual;
    function GetScreenHeight(): Integer; virtual;
    function GetWindowOpacity(): Double; virtual;
    function GetBackgroundOpacity(): Double; virtual;
    function GetBackgroundBlur(): Boolean; virtual;

    // Platform-dependent virtual hook methods
    procedure Show(); virtual;
    procedure Hide(); virtual;
    procedure Repaint(); virtual;
    procedure Resize(NewW, NewH: Integer; AApplyToBackend: Boolean = True); virtual;
    procedure SetPosition(NewX, NewY: Integer); virtual;
    procedure GetPosition(out OutX, OutY: Integer); virtual;
    function ClientToScreen(AX, AY: Integer): TPoint; virtual;
    function ScreenToClient(AX, AY: Integer): TPoint; virtual;
    procedure SetTitle(const ATitle: string); virtual;
    procedure SetBorderless(ABorderless: Boolean); virtual;
    procedure SetSkipTaskbar(ASkip: Boolean); virtual;
    procedure SetWindowType(AType: TFtWindowType); virtual;
    procedure SetWindowOpacity(AOpacity: Double); virtual;
    procedure SetOpacity(AValue: Double); override;
    procedure SetBackgroundOpacity(AValue: Double); virtual;
    procedure SetBackgroundBlur(AValue: Boolean); virtual;
    procedure UpdateCursor(); virtual;
    procedure ClaimClipboard(); virtual;
    procedure ClaimPrimarySelection(const AText: string); virtual;
    procedure ClearPrimarySelection(); virtual;
    function FetchClipboardText(): string; virtual;
    function FetchPrimarySelectionText(): string; virtual;
    procedure GrabInput(); virtual;
    procedure UngrabInput(); virtual;
    function GetNativeHandle(): Pointer; virtual;

    // Platform-independent widget, focus & dirty rect logic
    procedure Invalidate(); override;
    procedure InvalidateRect(AX, AY, AW, AH: Integer); override;
    procedure WidgetDestroyed(AWidget: TFtWidget); override;
    procedure RequestFocus(AWidget: TFtWidget); override;
    procedure SetFocusedWidget(AWidget: TFtWidget); virtual;
    procedure FocusNext(ABackward: Boolean = False); virtual;
    procedure SetActivePopup(APopup: TFtWidget); virtual;
    procedure ClearActivePopup(); virtual;

    property Canvas: TFtCanvasAgg read FCanvas;
    property PixelBuffer: PByte read FPixelBuffer;
    property Title: string read FTitle write SetTitle;
    property Borderless: Boolean read FBorderless write SetBorderless;
    property SkipTaskbar: Boolean read FSkipTaskbar write SetSkipTaskbar;
    property WindowType: TFtWindowType read FWindowType write SetWindowType;
    property WindowOpacity: Double read GetWindowOpacity write SetWindowOpacity;
    property BackgroundOpacity: Double read GetBackgroundOpacity write SetBackgroundOpacity;
    property BackgroundBlur: Boolean read GetBackgroundBlur write SetBackgroundBlur;
    property FocusedWidget: TFtWidget read FFocusedWidget;
    property HoverWidget: TFtWidget read FHoverWidget;
    property PressedWidget: TFtWidget read FPressedWidget;
    property MainMenu: TFtWidget read FMainMenu write FMainMenu;
    property ActivePopup: TFtWidget read FActivePopup write SetActivePopup;
    property ScreenWidth: Integer read GetScreenWidth;
    property ScreenHeight: Integer read GetScreenHeight;
    property NeedsRepaint: Boolean read FNeedsRepaint write FNeedsRepaint;
    property HasDirtyRect: Boolean read FHasDirtyRect write FHasDirtyRect;
    property FullRepaint: Boolean read FFullRepaint write FFullRepaint;
    property DirtyLeft: Integer read FDirtyLeft write FDirtyLeft;
    property DirtyTop: Integer read FDirtyTop write FDirtyTop;
    property DirtyRight: Integer read FDirtyRight write FDirtyRight;
    property DirtyBottom: Integer read FDirtyBottom write FDirtyBottom;
  end;

  TFtWindowClass = class of TFtWindow;

var
  GWindows: TFPList = nil;
  GActiveWindow: TFtWindow = nil;
  GDefaultWindowClass: TFtWindowClass = nil;
  GGrabbedPopup: TFtWidget = nil;
  gClipboardText: string = '';
  gPrimarySelectionText: string = '';
  gOnPrimarySelectionLost: TFtSelectionLostHandler = nil;

function FtCreateWindow(W, H: Integer; const Title: string = ''; AType: TFtWindowType = ftwtNormal): TFtWindow;
procedure FtRegisterWindowClass(AClass: TFtWindowClass);
function FtGetActiveWindow(): TFtWindow;
procedure FtSetActiveWindow(AWindow: TFtWindow);

procedure FtSetClipboardText(const AText: string);
function FtGetClipboardText(): string;
procedure FtClaimPrimarySelection(const AText: string);
procedure FtClearPrimarySelection();
procedure FtSetSelectionLostHandler(AHandler: TFtSelectionLostHandler);

procedure FtGrabMenuInput(AWindow: TFtWindow);
procedure FtUngrabMenuInput(AWindow: TFtWindow);

function FindFocusableWidget(AWidget: TFtWidget): TFtWidget;

implementation

type
  TFtWindowBroadcaster = class
    procedure HandleThemeChanged();
    procedure HandleStyleSheetChanged();
  end;

var
  GBroadcaster: TFtWindowBroadcaster = nil;

procedure TFtWindowBroadcaster.HandleThemeChanged();
var
  i: Integer;
begin
  if Assigned(GWindows) then
  begin
    for i := 0 to GWindows.Count - 1 do
      TFtWindow(GWindows[i]).OnThemeChanged();
  end;
end;

procedure TFtWindowBroadcaster.HandleStyleSheetChanged();
var
  i: Integer;
begin
  if Assigned(GWindows) then
  begin
    for i := 0 to GWindows.Count - 1 do
      TFtWindow(GWindows[i]).OnStyleSheetChanged();
  end;
end;

function FindFocusableWidget(AWidget: TFtWidget): TFtWidget;
var
  w: TFtWidget;
begin
  w := AWidget;
  while Assigned(w) do
  begin
    if w.CanFocus() then
      Exit(w);
    w := w.Parent;
  end;
  Result := nil;
end;

{ TFtWindow }

constructor TFtWindow.Create(W, H: Integer; const ATitle: string);
begin
  inherited Create(nil);
  FTitle := ATitle;
  X := 0;
  Y := 0;
  Width := W;
  Height := H;
  Visible := False;
  FTitle := Title;
  FBorderless := False;
  FSkipTaskbar := False;
  FWindowType := ftwtNormal;
  FWindowOpacity := 1.0;
  FBackgroundOpacity := 1.0;
  FBackgroundBlur := False;
  FHoverWidget := nil;
  FPressedWidget := nil;
  FFocusedWidget := nil;
  FMainMenu := nil;
  FActivePopup := nil;
  FNeedsRepaint := True;
  FFullRepaint := True;
  FHasDirtyRect := False;

  if (Width > 0) and (Height > 0) then
  begin
    GetMem(FPixelBuffer, Width * Height * 4);
    FillChar(FPixelBuffer^, Width * Height * 4, 0);
    FCanvas := TFtCanvasAgg.Create(FPixelBuffer, Width, Height);
  end
  else
  begin
    FPixelBuffer := nil;
    FCanvas := nil;
  end;

  if not Assigned(GWindows) then
    GWindows := TFPList.Create();
  GWindows.Add(Self);
  GActiveWindow := Self;
end;

destructor TFtWindow.Destroy();
begin
  if Assigned(GWindows) then
  begin
    GWindows.Remove(Self);
    if GActiveWindow = Self then
    begin
      if GWindows.Count > 0 then
        GActiveWindow := TFtWindow(GWindows[GWindows.Count - 1])
      else
        GActiveWindow := nil;
    end;
  end;

  if GGrabbedPopup = Self then
    GGrabbedPopup := nil;

  if Assigned(FCanvas) then
    FreeAndNil(FCanvas);
  if Assigned(FPixelBuffer) then
  begin
    FreeMem(FPixelBuffer);
    FPixelBuffer := nil;
  end;

  inherited Destroy();
end;

function TFtWindow.GetElementType(): string;
begin
  Result := 'window';
end;

procedure TFtWindow.OnThemeChanged();
begin
  InvalidateStyle();
  Invalidate();
end;

procedure TFtWindow.OnStyleSheetChanged();
begin
  InvalidateStyle();
  Invalidate();
end;

function TFtWindow.GetScreenWidth(): Integer;
begin
  Result := 1920;
end;

function TFtWindow.GetScreenHeight(): Integer;
begin
  Result := 1080;
end;

function TFtWindow.GetWindowOpacity(): Double;
begin
  Result := FWindowOpacity;
end;

function TFtWindow.GetBackgroundOpacity(): Double;
begin
  Result := FBackgroundOpacity;
end;

function TFtWindow.GetBackgroundBlur(): Boolean;
begin
  Result := FBackgroundBlur;
end;

procedure TFtWindow.Show();
begin
  Visible := True;
  Invalidate();
end;

procedure TFtWindow.Hide();
begin
  Visible := False;
end;

procedure TFtWindow.Repaint();
var
  st: TFtWidgetStyle;
  isPartial: Boolean;
  dirtyX, dirtyY, dirtyW, dirtyH: Integer;
  isTranslucent: Boolean;
  effBgA: Double;
  rowY: Integer;
begin
  if (Width <= 0) or (Height <= 0) or not Assigned(FCanvas) then Exit;

  FNeedsRepaint := False;
  isPartial := FHasDirtyRect and not FFullRepaint;
  if FHasDirtyRect then
  begin
    dirtyX := FDirtyLeft;
    dirtyY := FDirtyTop;
    dirtyW := FDirtyRight - FDirtyLeft;
    dirtyH := FDirtyBottom - FDirtyTop;
  end
  else
  begin
    dirtyX := 0; dirtyY := 0; dirtyW := Width; dirtyH := Height;
  end;

  st := GetResolvedStyle();
  isTranslucent := ((FBackgroundOpacity < 0.999) or (st.HasBgColor and (st.BgColor.A < 0.999)) or
                    (FWindowType in [ftwtPopupMenu, ftwtDropdownMenu, ftwtTooltip]));

  if isPartial then
  begin
    FHasDirtyRect := False;
    FFullRepaint := False;

    if (dirtyW <= 0) or (dirtyH <= 0) then Exit;

    if isTranslucent and Assigned(FPixelBuffer) then
    begin
      for rowY := dirtyY to dirtyY + dirtyH - 1 do
        FillChar(PByte(FPixelBuffer)[(rowY * Width + dirtyX) * 4], dirtyW * 4, 0);
    end;

    FCanvas.ResetAllClipping();
    FCanvas.PushClipRect(dirtyX, dirtyY, dirtyW, dirtyH);
    try
      if not (FWindowType in [ftwtPopupMenu, ftwtDropdownMenu, ftwtTooltip]) then
      begin
        if st.HasBgColor then
        begin
          effBgA := st.BgColor.A * FBackgroundOpacity;
          FCanvas.DrawRect(0, 0, Width, Height, st.BgColor.R, st.BgColor.G, st.BgColor.B, effBgA);
        end
        else
          FtGetTheme().DrawWindowBackground(FCanvas, Width, Height, FBackgroundOpacity);
      end;
      Self.Draw(FCanvas);
    finally
      FCanvas.ResetAllClipping();
    end;
  end
  else
  begin
    FHasDirtyRect := False;
    FFullRepaint := False;

    if isTranslucent and Assigned(FPixelBuffer) then
      FillChar(FPixelBuffer^, Width * Height * 4, 0);

    FCanvas.ResetAllClipping();
    if not (FWindowType in [ftwtPopupMenu, ftwtDropdownMenu, ftwtTooltip]) then
    begin
      if st.HasBgColor then
      begin
        effBgA := st.BgColor.A * FBackgroundOpacity;
        FCanvas.DrawRect(0, 0, Width, Height, st.BgColor.R, st.BgColor.G, st.BgColor.B, effBgA);
      end
      else
        FtGetTheme().DrawWindowBackground(FCanvas, Width, Height, FBackgroundOpacity);
    end;
    Self.Draw(FCanvas);
  end;
end;

procedure TFtWindow.Resize(NewW, NewH: Integer; AApplyToBackend: Boolean = True);
begin
  if (NewW <= 0) or (NewH <= 0) then Exit;
  if (Width = NewW) and (Height = NewH) then Exit;

  Width := NewW;
  Height := NewH;
  if Assigned(FMainMenu) then
    FMainMenu.Width := Width;

  if Assigned(FCanvas) then
    FreeAndNil(FCanvas);
  if Assigned(FPixelBuffer) then
  begin
    FreeMem(FPixelBuffer);
    FPixelBuffer := nil;
  end;

  GetMem(FPixelBuffer, Width * Height * 4);
  FillChar(FPixelBuffer^, Width * Height * 4, 0);
  FCanvas := TFtCanvasAgg.Create(FPixelBuffer, Width, Height);

  Invalidate();
end;

procedure TFtWindow.SetPosition(NewX, NewY: Integer);
begin
  X := NewX;
  Y := NewY;
end;

procedure TFtWindow.GetPosition(out OutX, OutY: Integer);
begin
  OutX := X;
  OutY := Y;
end;

function TFtWindow.ClientToScreen(AX, AY: Integer): TPoint;
begin
  Result.X := X + AX;
  Result.Y := Y + AY;
end;

function TFtWindow.ScreenToClient(AX, AY: Integer): TPoint;
begin
  Result.X := AX - X;
  Result.Y := AY - Y;
end;

procedure TFtWindow.SetTitle(const ATitle: string);
begin
  FTitle := ATitle;
end;

procedure TFtWindow.SetBorderless(ABorderless: Boolean);
begin
  FBorderless := ABorderless;
end;

procedure TFtWindow.SetSkipTaskbar(ASkip: Boolean);
begin
  FSkipTaskbar := ASkip;
end;

procedure TFtWindow.SetWindowType(AType: TFtWindowType);
begin
  FWindowType := AType;
end;

procedure TFtWindow.SetWindowOpacity(AOpacity: Double);
begin
  if AOpacity < 0.0 then AOpacity := 0.0;
  if AOpacity > 1.0 then AOpacity := 1.0;
  if FWindowOpacity <> AOpacity then
  begin
    FWindowOpacity := AOpacity;
    Invalidate();
  end;
end;

procedure TFtWindow.SetOpacity(AValue: Double);
begin
  inherited SetOpacity(AValue);
  SetWindowOpacity(AValue);
end;

procedure TFtWindow.SetBackgroundOpacity(AValue: Double);
begin
  if AValue < 0.0 then AValue := 0.0;
  if AValue > 1.0 then AValue := 1.0;
  if FBackgroundOpacity <> AValue then
  begin
    FBackgroundOpacity := AValue;
    Invalidate();
  end;
end;

procedure TFtWindow.SetBackgroundBlur(AValue: Boolean);
begin
  if FBackgroundBlur <> AValue then
  begin
    FBackgroundBlur := AValue;
    Invalidate();
  end;
end;

procedure TFtWindow.UpdateCursor();
begin
end;

procedure TFtWindow.ClaimClipboard();
begin
end;

procedure TFtWindow.ClaimPrimarySelection(const AText: string);
begin
end;

procedure TFtWindow.ClearPrimarySelection();
begin
end;

function TFtWindow.FetchClipboardText(): string;
begin
  Result := gClipboardText;
end;

function TFtWindow.FetchPrimarySelectionText(): string;
begin
  Result := gPrimarySelectionText;
end;

procedure TFtWindow.GrabInput();
begin
end;

procedure TFtWindow.UngrabInput();
begin
end;

function TFtWindow.GetNativeHandle(): Pointer;
begin
  Result := nil;
end;

procedure TFtWindow.Invalidate();
begin
  FFullRepaint := True;
  FNeedsRepaint := True;
end;

procedure TFtWindow.InvalidateRect(AX, AY, AW, AH: Integer);
var
  cx1, cy1, cx2, cy2: Integer;
begin
  if not Visible or (Width <= 0) or (Height <= 0) then Exit;
  if (AW <= 0) or (AH <= 0) then Exit;

  cx1 := AX;
  cy1 := AY;
  cx2 := AX + AW;
  cy2 := AY + AH;
  if cx1 < 0 then cx1 := 0;
  if cy1 < 0 then cy1 := 0;
  if cx2 > Width then cx2 := Width;
  if cy2 > Height then cy2 := Height;
  if (cx2 <= cx1) or (cy2 <= cy1) then Exit;

  if FFullRepaint then
  begin
    FNeedsRepaint := True;
    Exit;
  end;

  if not FHasDirtyRect then
  begin
    FDirtyLeft := cx1;
    FDirtyTop := cy1;
    FDirtyRight := cx2;
    FDirtyBottom := cy2;
    FHasDirtyRect := True;
  end
  else
  begin
    if cx1 < FDirtyLeft then FDirtyLeft := cx1;
    if cy1 < FDirtyTop then FDirtyTop := cy1;
    if cx2 > FDirtyRight then FDirtyRight := cx2;
    if cy2 > FDirtyBottom then FDirtyBottom := cy2;
  end;

  FNeedsRepaint := True;
end;

procedure TFtWindow.WidgetDestroyed(AWidget: TFtWidget);
begin
  if FHoverWidget = AWidget then
    FHoverWidget := nil;
  if FPressedWidget = AWidget then
    FPressedWidget := nil;
  if FFocusedWidget = AWidget then
    FFocusedWidget := nil;
  if FMainMenu = AWidget then
    FMainMenu := nil;
  if FActivePopup = AWidget then
    FActivePopup := nil;
  UpdateCursor();
  inherited WidgetDestroyed(AWidget);
end;

procedure TFtWindow.RequestFocus(AWidget: TFtWidget);
begin
  SetFocusedWidget(AWidget);
end;

procedure TFtWindow.SetFocusedWidget(AWidget: TFtWidget);
begin
  if AWidget = FFocusedWidget then Exit;
  if Assigned(FFocusedWidget) then
    FFocusedWidget.LostFocus();
  if Assigned(AWidget) and AWidget.CanFocus() then
  begin
    FFocusedWidget := AWidget;
    FFocusedWidget.GotFocus();
  end
  else
    FFocusedWidget := nil;
end;

procedure TFtWindow.FocusNext(ABackward: Boolean = False);

  procedure CollectFocusable(AWidget: TFtWidget; AList: TFPList);
  var
    i: Integer;
    child: TFtWidget;
  begin
    if not AWidget.Visible then Exit;
    if AWidget.CanFocus() then
      AList.Add(AWidget);
    for i := 0 to AWidget.Children.Count - 1 do
    begin
      child := TFtWidget(AWidget.Children[i]);
      CollectFocusable(child, AList);
    end;
  end;

var
  list: TFPList;
  idx, nextIdx, cnt: Integer;
begin
  list := TFPList.Create();
  try
    CollectFocusable(Self, list);
    cnt := list.Count;
    if cnt = 0 then
    begin
      SetFocusedWidget(nil);
      Exit;
    end;

    idx := list.IndexOf(FFocusedWidget);
    if idx < 0 then
    begin
      if ABackward then
        nextIdx := cnt - 1
      else
        nextIdx := 0;
    end
    else
    begin
      if ABackward then
        nextIdx := (idx - 1 + cnt) mod cnt
      else
        nextIdx := (idx + 1) mod cnt;
    end;

    SetFocusedWidget(TFtWidget(list[nextIdx]));
  finally
    list.Free();
  end;
end;

procedure TFtWindow.SetActivePopup(APopup: TFtWidget);
begin
  FActivePopup := APopup;
end;

procedure TFtWindow.ClearActivePopup();
begin
  FActivePopup := nil;
end;

function FtCreateWindow(W, H: Integer; const Title: string = ''; AType: TFtWindowType = ftwtNormal): TFtWindow;
begin
  if Assigned(GDefaultWindowClass) then
    Result := GDefaultWindowClass.Create(W, H, Title)
  else
    Result := TFtWindow.Create(W, H, Title);
  if AType <> ftwtNormal then
    Result.WindowType := AType;
end;

procedure FtRegisterWindowClass(AClass: TFtWindowClass);
begin
  GDefaultWindowClass := AClass;
end;

function FtGetActiveWindow(): TFtWindow;
begin
  Result := GActiveWindow;
end;

procedure FtSetActiveWindow(AWindow: TFtWindow);
begin
  GActiveWindow := AWindow;
end;

procedure FtSetClipboardText(const AText: string);
begin
  gClipboardText := AText;
  if Assigned(GActiveWindow) then
    GActiveWindow.ClaimClipboard();
end;

function FtGetClipboardText(): string;
begin
  if Assigned(GActiveWindow) then
    Result := GActiveWindow.FetchClipboardText()
  else
    Result := gClipboardText;
end;

procedure FtClaimPrimarySelection(const AText: string);
begin
  gPrimarySelectionText := AText;
  if Assigned(GActiveWindow) then
    GActiveWindow.ClaimPrimarySelection(AText);
end;

procedure FtClearPrimarySelection();
begin
  gPrimarySelectionText := '';
  if Assigned(GActiveWindow) then
    GActiveWindow.ClearPrimarySelection();
end;

procedure FtSetSelectionLostHandler(AHandler: TFtSelectionLostHandler);
begin
  gOnPrimarySelectionLost := AHandler;
end;

procedure FtGrabMenuInput(AWindow: TFtWindow);
begin
  if Assigned(AWindow) then
    AWindow.GrabInput();
end;

procedure FtUngrabMenuInput(AWindow: TFtWindow);
begin
  if Assigned(AWindow) then
    AWindow.UngrabInput();
end;

initialization
  GBroadcaster := TFtWindowBroadcaster.Create();
  FtThemeManager().OnThemeChange := @GBroadcaster.HandleThemeChanged;
  FtGetStyleSheet().OnChange := @GBroadcaster.HandleStyleSheetChanged;

finalization
  if Assigned(GBroadcaster) then
    FreeAndNil(GBroadcaster);
  if Assigned(GWindows) then
    FreeAndNil(GWindows);

end.
