unit Ft.Backend.X11;

{$mode objfpc}{$H+}

interface

uses
  ctypes, x, xlib, xutil, SysUtils, Classes, Ft.Canvas.Agg, Ft.Widget, Ft.Theme, Ft.Css, Ft.Animation;

type
  TFtWindowType = (
    ftwtNormal = 0,
    ftwtDialog = 1,
    ftwtPopupMenu = 2,
    ftwtDropdownMenu = 3,
    ftwtTooltip = 4,
    ftwtUtility = 5
  );

  TMWMHints = record
    flags: culong;
    functions: culong;
    decorations: culong;
    input_mode: clong;
    status: culong;
  end;
  PMWMHints = ^TMWMHints;

const
  MWM_HINTS_DECORATIONS = 1 shl 1;

type
  TFtX11Window = class(TFtWidget)
  private
    FDisplay: PDisplay;
    FWindow: TWindow;
    FGC: TGC;
    FXImage: PXImage;
    FPixelBuffer: Pointer;
    FCanvas: TFtCanvasAgg;
    FWMDeleteWindow: TAtom;
    FAtomClipboard: TAtom;
    FAtomUTF8String: TAtom;
    FAtomTargets: TAtom;
    FCursorIBeam: TCursor;
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
    FHasPendingResize: Boolean;
    FPendingResizeW: Integer;
    FPendingResizeH: Integer;
    FLastResizeTime: QWord;
    FLastConfigureTime: QWord;
    FLastResizeRenderTime: QWord;
    FBorderless: Boolean;
    FSkipTaskbar: Boolean;
    FWindowType: TFtWindowType;
    FVisual: PVisual;
    FDepth: cint;
    FColormap: TColormap;
    FBackgroundOpacity: Double;
    procedure OnThemeChanged();
    procedure OnStyleSheetChanged();
    procedure UpdateCursor();
  public
    constructor Create(W, H: Integer; Title: string); reintroduce;
    destructor Destroy(); override;
    procedure Resize(NewW, NewH: Integer; AApplyToX11: Boolean = True);
    procedure SetTitle(const ATitle: string);
    procedure SetBorderless(ABorderless: Boolean);
    procedure SetSkipTaskbar(ASkip: Boolean);
    procedure SetWindowType(AType: TFtWindowType);
    procedure SetWindowOpacity(AOpacity: Double);
    function GetWindowOpacity(): Double;
    procedure SetOpacity(AValue: Double); override;
    procedure SetBackgroundOpacity(AValue: Double);
    function GetBackgroundOpacity(): Double;
    procedure SetPosition(NewX, NewY: Integer);
    procedure GetPosition(out OutX, OutY: Integer);
    function ClientToScreen(AX, AY: Integer): TPoint;
    function ScreenToClient(AX, AY: Integer): TPoint;
    function GetElementType(): string; override;
    procedure Repaint();
    procedure HandleEvents();
    procedure HandleEvent(var Event: TXEvent);
    procedure Show();
    procedure Hide();
    procedure Invalidate(); override;
    procedure InvalidateRect(AX, AY, AW, AH: Integer); override;
    procedure WidgetDestroyed(AWidget: TFtWidget); override;
    procedure RequestFocus(AWidget: TFtWidget); override;
    procedure SetFocusedWidget(AWidget: TFtWidget);
    procedure FocusNext(ABackward: Boolean = False);
    procedure ClaimClipboard();
    procedure SetActivePopup(APopup: TFtWidget);
    procedure ClearActivePopup();
    property Window: TWindow read FWindow;
    property Display: PDisplay read FDisplay;
    property Borderless: Boolean read FBorderless write SetBorderless;
    property SkipTaskbar: Boolean read FSkipTaskbar write SetSkipTaskbar;
    property WindowType: TFtWindowType read FWindowType write SetWindowType;
    property WindowOpacity: Double read GetWindowOpacity write SetWindowOpacity;
    property BackgroundOpacity: Double read GetBackgroundOpacity write SetBackgroundOpacity;
    property FocusedWidget: TFtWidget read FFocusedWidget;
    property MainMenu: TFtWidget read FMainMenu write FMainMenu;
    property ActivePopup: TFtWidget read FActivePopup write SetActivePopup;
  end;

type
  TFtSelectionLostHandler = procedure();

var
  GDisplay: PDisplay = nil;
  GRunning: Boolean = False;
  GActiveWindow: TFtX11Window = nil;
  GWindows: TFPList = nil;
  GGrabbedPopup: TFtWidget = nil;

procedure FtBackendInit();
procedure FtBackendMainLoop();
procedure FtBackendProcessEvents();
procedure FtBackendQuit();
procedure FtGrabMenuInput(AWindow: TFtX11Window);
procedure FtUngrabMenuInput(AWindow: TFtX11Window);
function FindWindowByHandle(AWindow: TWindow): TFtX11Window;
function HasMainWindows(): Boolean;
procedure FtSetClipboardText(const AText: string);
function FtGetClipboardText(): string;
procedure FtClaimPrimarySelection(const AText: string);
procedure FtClearPrimarySelection();
procedure FtSetSelectionLostHandler(AHandler: TFtSelectionLostHandler);

implementation

uses
  Ft.Widget.Menus;

procedure FtBackendInit();
begin
  XInitThreads();
  GDisplay := XOpenDisplay(nil);
  if GDisplay = nil then
    raise Exception.Create('Floria Toolkit: Unable to connect to X11 display.');
  GRunning := True;
end;

procedure FtBackendQuit();
begin
  GRunning := False;
end;

function FindWindowByHandle(AWindow: TWindow): TFtX11Window;
var
  i: Integer;
  w: TFtX11Window;
begin
  Result := nil;
  if not Assigned(GWindows) then Exit;
  for i := 0 to GWindows.Count - 1 do
  begin
    w := TFtX11Window(GWindows[i]);
    if w.FWindow = AWindow then
      Exit(w);
  end;
end;

function HasMainWindows(): Boolean;
var
  i: Integer;
  w: TFtX11Window;
begin
  Result := False;
  if not Assigned(GWindows) then Exit;
  for i := 0 to GWindows.Count - 1 do
  begin
    w := TFtX11Window(GWindows[i]);
    if w.FWindowType in [ftwtNormal, ftwtDialog] then
      Exit(True);
  end;
end;

procedure FtGrabMenuInput(AWindow: TFtX11Window);
begin
  if Assigned(AWindow) and (AWindow.FWindow <> None) and Assigned(AWindow.FDisplay) then
  begin
    XGrabPointer(AWindow.FDisplay, AWindow.FWindow, True,
      ButtonPressMask or ButtonReleaseMask or PointerMotionMask,
      GrabModeAsync, GrabModeAsync, None, None, CurrentTime);
    XGrabKeyboard(AWindow.FDisplay, AWindow.FWindow, True,
      GrabModeAsync, GrabModeAsync, CurrentTime);
  end;
end;

procedure FtUngrabMenuInput(AWindow: TFtX11Window);
begin
  if Assigned(AWindow) and Assigned(AWindow.FDisplay) then
  begin
    XUngrabPointer(AWindow.FDisplay, CurrentTime);
    XUngrabKeyboard(AWindow.FDisplay, CurrentTime);
  end;
end;

procedure FtBackendProcessEvents();
var
  Event: TXEvent;
  win: TFtX11Window;
  i: Integer;
  nowMs: QWord;
  shouldResize: Boolean;
begin
  while Assigned(GDisplay) and (XPending(GDisplay) > 0) do
  begin
    XNextEvent(GDisplay, @Event);
    win := FindWindowByHandle(Event.xany.window);
    if Assigned(win) then
      win.HandleEvent(Event)
    else
    begin
      if (Event._type = SelectionRequest) or (Event._type = SelectionClear) then
      begin
        if Assigned(GActiveWindow) then
          GActiveWindow.HandleEvent(Event);
      end;
    end;
  end;

  if Assigned(GWindows) then
  begin
    nowMs := GetTickCount64();
    for i := GWindows.Count - 1 downto 0 do
    begin
      if i < GWindows.Count then
      begin
        win := TFtX11Window(GWindows[i]);
        if win.FHasPendingResize then
        begin
          if (win.FPendingResizeW = win.Width) and (win.FPendingResizeH = win.Height) then
            win.FHasPendingResize := False
          else
          begin
            // Frame skipping during resize bursts:
            // 1) Drag has paused/ended (>= 25ms since last configure event), OR
            // 2) At least 30ms passed since previous resize render completed (~30 FPS rate)
            shouldResize := ((nowMs - win.FLastConfigureTime) >= 25) or
                            ((nowMs - win.FLastResizeRenderTime) >= 30);
            if shouldResize then
            begin
              win.FHasPendingResize := False;
              win.FNeedsRepaint := False;

              // Discard any queued Expose events for this window since Resize does a full redraw
              while XCheckTypedWindowEvent(win.FDisplay, win.FWindow, Expose, @Event) do
                ;

              win.Resize(win.FPendingResizeW, win.FPendingResizeH, False);
            end;
          end;
        end;

        if win.FNeedsRepaint then
        begin
          win.FNeedsRepaint := False;
          win.Repaint();
        end;
      end;
    end;
  end;
end;

function IsAnyWindowResizing(ANowMs: QWord): Boolean;
var
  i: Integer;
  w: TFtX11Window;
begin
  Result := False;
  if not Assigned(GWindows) then Exit;
  for i := 0 to GWindows.Count - 1 do
  begin
    w := TFtX11Window(GWindows[i]);
    if w.FHasPendingResize or ((ANowMs >= w.FLastConfigureTime) and ((ANowMs - w.FLastConfigureTime) < 150)) then
      Exit(True);
  end;
end;

procedure FtBackendMainLoop();
var
  frameStartMs, nowMs: QWord;
  elapsedMs: Integer;
  animator: TFtAnimator;
begin
  animator := FtGetAnimator();
  while GRunning and HasMainWindows() do
  begin
    frameStartMs := GetTickCount64();

    if animator.HasActiveAnimations() then
      animator.Tick(frameStartMs);

    FtBackendProcessEvents();

    if animator.HasActiveAnimations() then
    begin
      nowMs := GetTickCount64();
      elapsedMs := Integer(nowMs - frameStartMs);
      if animator.HasActiveTransitions() or IsAnyWindowResizing(nowMs) then
      begin
        if elapsedMs < 16 then
          Sleep(16 - elapsedMs)
        else
          Sleep(1);
      end
      else
      begin
        if elapsedMs < 33 then
          Sleep(33 - elapsedMs)
        else
          Sleep(1);
      end;
    end
    else
    begin
      if Assigned(GDisplay) and (XPending(GDisplay) = 0) then
      begin
        nowMs := GetTickCount64();
        if IsAnyWindowResizing(nowMs) then
          Sleep(8)
        else
          Sleep(10);
      end;
    end;
  end;
  if Assigned(GDisplay) then
  begin
    XCloseDisplay(GDisplay);
    GDisplay := nil;
  end;
end;

type
  TFtX11Broadcaster = class
    procedure HandleThemeChanged();
    procedure HandleStyleSheetChanged();
  end;

var
  GBroadcaster: TFtX11Broadcaster = nil;

procedure TFtX11Broadcaster.HandleThemeChanged();
var
  i: Integer;
  win: TFtX11Window;
begin
  if Assigned(GWindows) then
  begin
    for i := 0 to GWindows.Count - 1 do
    begin
      win := TFtX11Window(GWindows[i]);
      win.InvalidateStyle();
      win.Invalidate();
    end;
  end;
end;

procedure TFtX11Broadcaster.HandleStyleSheetChanged();
var
  i: Integer;
  win: TFtX11Window;
begin
  if Assigned(GWindows) then
  begin
    for i := 0 to GWindows.Count - 1 do
    begin
      win := TFtX11Window(GWindows[i]);
      win.InvalidateStyle();
      win.Invalidate();
    end;
  end;
end;

constructor TFtX11Window.Create(W, H: Integer; Title: string);
var
  ScreenNum: cint;
  vinfo: TXVisualInfo;
  has32BitVisual: Boolean;
  winAttr: TXSetWindowAttributes;
begin
  inherited Create(nil);
  X := 0;
  Y := 0;
  Width := W;
  Height := H;
  FDisplay := GDisplay;
  FBorderless := False;
  FSkipTaskbar := False;
  FWindowType := ftwtNormal;
  FBackgroundOpacity := 1.0;

  ScreenNum := DefaultScreen(FDisplay);
  has32BitVisual := (XMatchVisualInfo(FDisplay, ScreenNum, 32, TrueColor, @vinfo) <> 0);
  if has32BitVisual then
  begin
    FVisual := vinfo.visual;
    FDepth := 32;
    FColormap := XCreateColormap(FDisplay, RootWindow(FDisplay, ScreenNum), FVisual, AllocNone);
    FillChar(winAttr, SizeOf(winAttr), 0);
    winAttr.colormap := FColormap;
    winAttr.border_pixel := 0;
    winAttr.background_pixmap := None;
    winAttr.bit_gravity := NorthWestGravity;
    FWindow := XCreateWindow(FDisplay, RootWindow(FDisplay, ScreenNum),
      100, 100, Width, Height, 0,
      32, InputOutput, FVisual,
      CWColormap or CWBorderPixel or CWBackPixmap or CWBitGravity,
      @winAttr);
  end
  else
  begin
    FVisual := DefaultVisual(FDisplay, ScreenNum);
    FDepth := 24;
    FColormap := None;
    FWindow := XCreateSimpleWindow(FDisplay, RootWindow(FDisplay, ScreenNum),
      100, 100, Width, Height, 0,
      BlackPixel(FDisplay, ScreenNum),
      BlackPixel(FDisplay, ScreenNum));

    // Disable X server background clearing and retain bit gravity during resize to eliminate flicker
    FillChar(winAttr, SizeOf(winAttr), 0);
    winAttr.background_pixmap := None;
    winAttr.bit_gravity := NorthWestGravity;
    XChangeWindowAttributes(FDisplay, FWindow, CWBackPixmap or CWBitGravity, @winAttr);
  end;

  SetTitle(Title);
  FHoverWidget := nil;
  FPressedWidget := nil;
  FFocusedWidget := nil;
  FMainMenu := nil;
  FActivePopup := nil;
  FCursorIBeam := None;
  FNeedsRepaint := False;
  FDirtyLeft := 0;
  FDirtyTop := 0;
  FDirtyRight := 0;
  FDirtyBottom := 0;
  FHasDirtyRect := False;
  FFullRepaint := True;
  FHasPendingResize := False;
  FPendingResizeW := 0;
  FPendingResizeH := 0;
  FLastResizeTime := 0;
  FLastConfigureTime := 0;
  FLastResizeRenderTime := 0;
  XSelectInput(FDisplay, FWindow, ExposureMask or ButtonPressMask or ButtonReleaseMask or PointerMotionMask or LeaveWindowMask or StructureNotifyMask or KeyPressMask or KeyReleaseMask);

  FWMDeleteWindow := XInternAtom(FDisplay, 'WM_DELETE_WINDOW', False);
  FAtomClipboard := XInternAtom(FDisplay, 'CLIPBOARD', False);
  FAtomUTF8String := XInternAtom(FDisplay, 'UTF8_STRING', False);
  FAtomTargets := XInternAtom(FDisplay, 'TARGETS', False);
  XSetWMProtocols(FDisplay, FWindow, @FWMDeleteWindow, 1);

  FGC := XCreateGC(FDisplay, FWindow, 0, nil);

  GetMem(FPixelBuffer, Width * Height * 4);
  FXImage := XCreateImage(FDisplay, FVisual, FDepth, ZPixmap, 0, PChar(FPixelBuffer), Width, Height, 32, 0);

  FCanvas := TFtCanvasAgg.Create(FPixelBuffer, Width, Height);
  if not Assigned(GWindows) then
    GWindows := TFPList.Create();
  GWindows.Add(Self);
  GActiveWindow := Self;

  if not Assigned(GBroadcaster) then
  begin
    GBroadcaster := TFtX11Broadcaster.Create();
    FtThemeManager().OnThemeChange := @GBroadcaster.HandleThemeChanged;
    FtGetStyleSheet().OnChange := @GBroadcaster.HandleStyleSheetChanged;
  end;
end;

procedure TFtX11Window.SetTitle(const ATitle: string);
var
  utf8String, netWmName, netWmIconName, wmName: TAtom;
  p: PChar;
  len: Integer;
begin
  p := PChar(ATitle);
  len := Length(ATitle);

  // 1. Legacy fallback (Latin-1)
  XStoreName(FDisplay, FWindow, p);

  // 2. Modern EWMH UTF-8 window title and icon name
  utf8String := XInternAtom(FDisplay, 'UTF8_STRING', False);
  netWmName := XInternAtom(FDisplay, '_NET_WM_NAME', False);
  netWmIconName := XInternAtom(FDisplay, '_NET_WM_ICON_NAME', False);
  wmName := XInternAtom(FDisplay, 'WM_NAME', False);

  if len > 0 then
  begin
    XChangeProperty(FDisplay, FWindow, netWmName, utf8String, 8, PropModeReplace, PByte(p), len);
    XChangeProperty(FDisplay, FWindow, netWmIconName, utf8String, 8, PropModeReplace, PByte(p), len);
    XChangeProperty(FDisplay, FWindow, wmName, utf8String, 8, PropModeReplace, PByte(p), len);
  end;
end;

procedure TFtX11Window.SetBorderless(ABorderless: Boolean);
var
  hints: TMWMHints;
  prop: TAtom;
  winAttr: TXSetWindowAttributes;
begin
  FBorderless := ABorderless;
  if FWindow = None then Exit;

  FillChar(hints, SizeOf(hints), 0);
  hints.flags := MWM_HINTS_DECORATIONS;
  if ABorderless then
    hints.decorations := 0
  else
    hints.decorations := 1;

  prop := XInternAtom(FDisplay, '_MOTIF_WM_HINTS', False);
  XChangeProperty(FDisplay, FWindow, prop, prop, 32, PropModeReplace, PByte(@hints), 5);

  if FWindowType in [ftwtPopupMenu, ftwtDropdownMenu, ftwtTooltip] then
  begin
    FillChar(winAttr, SizeOf(winAttr), 0);
    winAttr.override_redirect := 1;
    XChangeWindowAttributes(FDisplay, FWindow, CWOverrideRedirect, @winAttr);
  end;
end;

procedure TFtX11Window.SetSkipTaskbar(ASkip: Boolean);
var
  netWmState, atomSkipTaskbar, atomSkipPager: TAtom;
  atoms: array[0..1] of TAtom;
begin
  FSkipTaskbar := ASkip;
  if FWindow = None then Exit;

  netWmState := XInternAtom(FDisplay, '_NET_WM_STATE', False);
  atomSkipTaskbar := XInternAtom(FDisplay, '_NET_WM_STATE_SKIP_TASKBAR', False);
  atomSkipPager := XInternAtom(FDisplay, '_NET_WM_STATE_SKIP_PAGER', False);

  if ASkip then
  begin
    atoms[0] := atomSkipTaskbar;
    atoms[1] := atomSkipPager;
    XChangeProperty(FDisplay, FWindow, netWmState, 4 {XA_ATOM}, 32, PropModeReplace, PByte(@atoms), 2);
  end
  else
    XDeleteProperty(FDisplay, FWindow, netWmState);
end;

procedure TFtX11Window.SetWindowType(AType: TFtWindowType);
var
  netWmWindowType, typeAtom: TAtom;
  typeName: string;
  winAttr: TXSetWindowAttributes;
begin
  FWindowType := AType;
  if FWindow = None then Exit;

  case AType of
    ftwtNormal: typeName := '_NET_WM_WINDOW_TYPE_NORMAL';
    ftwtDialog: typeName := '_NET_WM_WINDOW_TYPE_DIALOG';
    ftwtPopupMenu: typeName := '_NET_WM_WINDOW_TYPE_POPUP_MENU';
    ftwtDropdownMenu: typeName := '_NET_WM_WINDOW_TYPE_DROPDOWN_MENU';
    ftwtTooltip: typeName := '_NET_WM_WINDOW_TYPE_TOOLTIP';
    ftwtUtility: typeName := '_NET_WM_WINDOW_TYPE_UTILITY';
  else
    typeName := '_NET_WM_WINDOW_TYPE_NORMAL';
  end;

  netWmWindowType := XInternAtom(FDisplay, '_NET_WM_WINDOW_TYPE', False);
  typeAtom := XInternAtom(FDisplay, PChar(typeName), False);
  XChangeProperty(FDisplay, FWindow, netWmWindowType, 4 {XA_ATOM}, 32, PropModeReplace, PByte(@typeAtom), 1);

  if AType in [ftwtPopupMenu, ftwtDropdownMenu, ftwtTooltip] then
  begin
    FillChar(winAttr, SizeOf(winAttr), 0);
    winAttr.override_redirect := 1;
    XChangeWindowAttributes(FDisplay, FWindow, CWOverrideRedirect, @winAttr);
    SetSkipTaskbar(True);
    SetBorderless(True);
  end;
end;

procedure TFtX11Window.SetWindowOpacity(AOpacity: Double);
var
  netWmWindowOpacity, atomCardinal: TAtom;
  cardinalValue: culong;
begin
  if AOpacity < 0.0 then AOpacity := 0.0;
  if AOpacity > 1.0 then AOpacity := 1.0;
  FOpacity := AOpacity;
  if (FDisplay = nil) or (FWindow = None) then Exit;

  netWmWindowOpacity := XInternAtom(FDisplay, '_NET_WM_WINDOW_OPACITY', False);
  if AOpacity >= 0.999 then
    XDeleteProperty(FDisplay, FWindow, netWmWindowOpacity)
  else
  begin
    atomCardinal := XInternAtom(FDisplay, 'CARDINAL', False);
    cardinalValue := culong(Round(AOpacity * 4294967295.0));
    XChangeProperty(FDisplay, FWindow, netWmWindowOpacity, atomCardinal, 32, PropModeReplace, PByte(@cardinalValue), 1);
  end;
  XFlush(FDisplay);
end;

function TFtX11Window.GetWindowOpacity(): Double;
begin
  Result := FOpacity;
end;

procedure TFtX11Window.SetOpacity(AValue: Double);
begin
  inherited SetOpacity(AValue);
  SetWindowOpacity(AValue);
end;

procedure TFtX11Window.SetBackgroundOpacity(AValue: Double);
begin
  if AValue < 0.0 then AValue := 0.0;
  if AValue > 1.0 then AValue := 1.0;
  if Abs(FBackgroundOpacity - AValue) > 1e-4 then
  begin
    FBackgroundOpacity := AValue;
    Invalidate();
  end;
end;

function TFtX11Window.GetBackgroundOpacity(): Double;
begin
  Result := FBackgroundOpacity;
end;

procedure TFtX11Window.SetPosition(NewX, NewY: Integer);
begin
  X := NewX;
  Y := NewY;
  if FWindow <> None then
    XMoveWindow(FDisplay, FWindow, NewX, NewY);
end;

procedure TFtX11Window.GetPosition(out OutX, OutY: Integer);
var
  rootRet, childRet: TWindow;
  rx, ry: cint;
  w, h, bw, d: cuint;
begin
  OutX := X;
  OutY := Y;
  if FWindow <> None then
  begin
    rootRet := None;
    childRet := None;
    XGetGeometry(FDisplay, FWindow, @rootRet, @rx, @ry, @w, @h, @bw, @d);
    XTranslateCoordinates(FDisplay, FWindow, rootRet, 0, 0, @rx, @ry, @childRet);
    OutX := rx;
    OutY := ry;
  end;
end;

function TFtX11Window.ClientToScreen(AX, AY: Integer): TPoint;
var
  rootX, rootY: cint;
  child: TWindow;
  rootWin: TWindow;
begin
  Result.X := AX;
  Result.Y := AY;
  if FWindow <> None then
  begin
    rootWin := RootWindow(FDisplay, DefaultScreen(FDisplay));
    XTranslateCoordinates(FDisplay, FWindow, rootWin, AX, AY, @rootX, @rootY, @child);
    Result.X := rootX;
    Result.Y := rootY;
  end;
end;

function TFtX11Window.ScreenToClient(AX, AY: Integer): TPoint;
var
  clX, clY: cint;
  child: TWindow;
  rootWin: TWindow;
begin
  Result.X := AX;
  Result.Y := AY;
  if FWindow <> None then
  begin
    rootWin := RootWindow(FDisplay, DefaultScreen(FDisplay));
    XTranslateCoordinates(FDisplay, rootWin, FWindow, AX, AY, @clX, @clY, @child);
    Result.X := clX;
    Result.Y := clY;
  end;
end;

destructor TFtX11Window.Destroy();
begin
  if Assigned(GWindows) then
    GWindows.Remove(Self);
  if GActiveWindow = Self then
  begin
    if Assigned(GWindows) and (GWindows.Count > 0) then
      GActiveWindow := TFtX11Window(GWindows[0])
    else
      GActiveWindow := nil;
  end;
  if GGrabbedPopup = Self then
    GGrabbedPopup := nil;

  FHoverWidget := nil;
  FPressedWidget := nil;
  FFocusedWidget := nil;
  if FCursorIBeam <> None then
  begin
    XFreeCursor(FDisplay, FCursorIBeam);
    FCursorIBeam := None;
  end;
  FCanvas.Free();
  if Assigned(FXImage) then
  begin
    FXImage^.data := nil;
    XDestroyImage(FXImage);
    FXImage := nil;
  end;
  if Assigned(FPixelBuffer) then
  begin
    FreeMem(FPixelBuffer);
    FPixelBuffer := nil;
  end;
  if Assigned(FGC) then
    XFreeGC(FDisplay, FGC);
  if (FColormap <> None) and (FDepth = 32) then
  begin
    XFreeColormap(FDisplay, FColormap);
    FColormap := None;
  end;
  if FWindow <> None then
    XDestroyWindow(FDisplay, FWindow);
  FWindow := None;
  inherited Destroy();
end;

procedure TFtX11Window.Resize(NewW, NewH: Integer; AApplyToX11: Boolean = True);
begin
  if (NewW <= 0) or (NewH <= 0) or ((NewW = Width) and (NewH = Height)) then Exit;

  Width := NewW;
  Height := NewH;
  FHasPendingResize := False;
  FLastResizeTime := GetTickCount64();
  if Assigned(FMainMenu) then
    FMainMenu.Width := Width;

  if AApplyToX11 and (FWindow <> None) and Assigned(FDisplay) then
    XResizeWindow(FDisplay, FWindow, Width, Height);

  if Assigned(FXImage) then
  begin
    FXImage^.data := nil;
    XDestroyImage(FXImage);
    FXImage := nil;
  end;

  if Assigned(FPixelBuffer) then
    FreeMem(FPixelBuffer);

  GetMem(FPixelBuffer, Width * Height * 4);
  FXImage := XCreateImage(FDisplay, FVisual, FDepth, ZPixmap, 0, PChar(FPixelBuffer), Width, Height, 32, 0);

  if Assigned(FCanvas) then
    FCanvas.Resize(FPixelBuffer, Width, Height)
  else
    FCanvas := TFtCanvasAgg.Create(FPixelBuffer, Width, Height);

  FFullRepaint := True;
  Repaint();
  FLastResizeRenderTime := GetTickCount64();
end;

procedure TFtX11Window.Show();
begin
  Visible := True;
  if FWindow <> None then
  begin
    XMapRaised(FDisplay, FWindow);
    FNeedsRepaint := True;
    XFlush(FDisplay);
  end;
end;

procedure TFtX11Window.Hide();
begin
  Visible := False;
  if FWindow <> None then
  begin
    XUnmapWindow(FDisplay, FWindow);
    XFlush(FDisplay);
  end;
end;

function TFtX11Window.GetElementType(): string;
begin
  Result := 'window';
end;

procedure TFtX11Window.Repaint();
var
  st: TFtWidgetStyle;
  isPartial: Boolean;
  dirtyX, dirtyY, dirtyW, dirtyH: Integer;
  isTranslucent: Boolean;
  effBgA: Double;
  rowY: Integer;
begin
  if (Width <= 0) or (Height <= 0) or (FWindow = None) or not Assigned(FCanvas) then Exit;

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
  isTranslucent := (FDepth = 32) and ((FBackgroundOpacity < 0.999) or (st.HasBgColor and (st.BgColor.A < 0.999)));

  if isPartial then
  begin
    FHasDirtyRect := False;
    FFullRepaint := False;

    if (dirtyW <= 0) or (dirtyH <= 0) then Exit;

    if isTranslucent then
    begin
      for rowY := dirtyY to dirtyY + dirtyH - 1 do
        FillChar(PByte(FPixelBuffer)[(rowY * Width + dirtyX) * 4], dirtyW * 4, 0);
    end;

    FCanvas.ResetAllClipping();
    FCanvas.PushClipRect(dirtyX, dirtyY, dirtyW, dirtyH);
    try
      if not (FWindowType in [ftwtPopupMenu, ftwtDropdownMenu]) then
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

    XPutImage(FDisplay, FWindow, FGC, FXImage, dirtyX, dirtyY, dirtyX, dirtyY, dirtyW, dirtyH);
    XFlush(FDisplay);
  end
  else
  begin
    FHasDirtyRect := False;
    FFullRepaint := False;

    if isTranslucent then
      FillChar(FPixelBuffer^, Width * Height * 4, 0);

    FCanvas.ResetAllClipping();
    if not (FWindowType in [ftwtPopupMenu, ftwtDropdownMenu]) then
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

    XPutImage(FDisplay, FWindow, FGC, FXImage, 0, 0, 0, 0, Width, Height);
    XFlush(FDisplay);
  end;
end;

procedure TFtX11Window.SetActivePopup(APopup: TFtWidget);
begin
  FActivePopup := APopup;
end;

procedure TFtX11Window.ClearActivePopup();
begin
  FActivePopup := nil;
  if Assigned(FMainMenu) then
    TFtMainMenu(FMainMenu).CloseMenu();
end;

procedure TFtX11Window.OnThemeChanged();
begin
  InvalidateStyle();
  Invalidate();
end;

procedure TFtX11Window.OnStyleSheetChanged();
begin
  InvalidateStyle();
  Invalidate();
end;

procedure TFtX11Window.Invalidate();
begin
  FFullRepaint := True;
  FNeedsRepaint := True;
end;

procedure TFtX11Window.InvalidateRect(AX, AY, AW, AH: Integer);
var
  cx1, cy1, cx2, cy2: Integer;
begin
  if not Visible or (Width <= 0) or (Height <= 0) then Exit;
  if (AW <= 0) or (AH <= 0) then Exit;

  // Clamp incoming rect to window bounds
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

var
  gClipboardText: string = '';
  gPrimarySelectionText: string = '';
  gOnPrimarySelectionLost: TFtSelectionLostHandler = nil;

procedure FtSetSelectionLostHandler(AHandler: TFtSelectionLostHandler);
begin
  gOnPrimarySelectionLost := AHandler;
end;

procedure FtClaimPrimarySelection(const AText: string);
begin
  gPrimarySelectionText := AText;
  if Assigned(GActiveWindow) and Assigned(GActiveWindow.FDisplay) and (GActiveWindow.FWindow <> None) then
  begin
    XSetSelectionOwner(GActiveWindow.FDisplay, 1 {XA_PRIMARY}, GActiveWindow.FWindow, CurrentTime);
    XFlush(GActiveWindow.FDisplay);
  end;
end;

procedure FtClearPrimarySelection();
begin
  gPrimarySelectionText := '';
  if Assigned(GActiveWindow) and Assigned(GActiveWindow.FDisplay) and (GActiveWindow.FWindow <> None) then
  begin
    if XGetSelectionOwner(GActiveWindow.FDisplay, 1 {XA_PRIMARY}) = GActiveWindow.FWindow then
    begin
      XSetSelectionOwner(GActiveWindow.FDisplay, 1 {XA_PRIMARY}, None, CurrentTime);
      XFlush(GActiveWindow.FDisplay);
    end;
  end;
end;

procedure FtSetClipboardText(const AText: string);
begin
  gClipboardText := AText;
  if Assigned(GActiveWindow) then
    GActiveWindow.ClaimClipboard();
end;

function GetSelectionRequestorWindow(): TFtX11Window;
var
  i: Integer;
  w: TFtX11Window;
begin
  if Assigned(GActiveWindow) and (GActiveWindow.FWindowType = ftwtNormal) and (GActiveWindow.FWindow <> None) then
    Exit(GActiveWindow);
  if Assigned(GWindows) then
  begin
    for i := 0 to GWindows.Count - 1 do
    begin
      w := TFtX11Window(GWindows[i]);
      if Assigned(w) and (w.FWindowType = ftwtNormal) and (w.FWindow <> None) then
        Exit(w);
    end;
    for i := 0 to GWindows.Count - 1 do
    begin
      w := TFtX11Window(GWindows[i]);
      if Assigned(w) and (w.FWindow <> None) then
        Exit(w);
    end;
  end;
  Result := GActiveWindow;
end;

function FtFetchSelectionFromX11(ASelectionAtom: TAtom): string;
var
  win, wItem: TFtX11Window;
  disp: PDisplay;
  reqWin: TWindow;
  owner: TWindow;
  atomUTF8, atomString, selProp: TAtom;
  targetAtom: TAtom;
  attempt: Integer;
  startTime: QWord;
  gotNotify: Boolean;
  ev, evReq: TXEvent;
  actualType: TAtom;
  actualFormat: cint;
  nItems, bytesAfter: culong;
  propData: PByte;
  ret: cint;
  retStr: string;
  i: Integer;
begin
  Result := '';
  win := GetSelectionRequestorWindow();
  if not Assigned(win) or not Assigned(win.FDisplay) or (win.FWindow = None) then
    Exit;

  disp := win.FDisplay;
  reqWin := win.FWindow;

  owner := XGetSelectionOwner(disp, ASelectionAtom);
  if owner = None then
    Exit;

  // If one of our windows owns the selection, return the cached text immediately
  if owner = reqWin then
  begin
    if ASelectionAtom = 1 then
      Exit(gPrimarySelectionText)
    else
      Exit(gClipboardText);
  end;

  if Assigned(GWindows) then
  begin
    for i := 0 to GWindows.Count - 1 do
    begin
      wItem := TFtX11Window(GWindows[i]);
      if Assigned(wItem) and (wItem.FWindow = owner) then
      begin
        if ASelectionAtom = 1 then
          Exit(gPrimarySelectionText)
        else
          Exit(gClipboardText);
      end;
    end;
  end;

  atomUTF8 := win.FAtomUTF8String;
  if atomUTF8 = None then
    atomUTF8 := XInternAtom(disp, 'UTF8_STRING', False);
  atomString := 31; // XA_STRING = 31
  selProp := XInternAtom(disp, 'FT_SELECTION', False);

  // Try UTF8_STRING first (attempt 1), then XA_STRING fallback (attempt 2)
  for attempt := 1 to 2 do
  begin
    if attempt = 1 then
      targetAtom := atomUTF8
    else
      targetAtom := atomString;

    XDeleteProperty(disp, reqWin, selProp);
    XConvertSelection(disp, ASelectionAtom, targetAtom, selProp, reqWin, CurrentTime);
    XFlush(disp);

    startTime := GetTickCount64();
    gotNotify := False;
    FillChar(ev, SizeOf(ev), 0);

    while (GetTickCount64() - startTime < 300) do
    begin
      if XCheckTypedWindowEvent(disp, reqWin, SelectionNotify, @ev) then
      begin
        gotNotify := True;
        Break;
      end;
      if XCheckTypedEvent(disp, SelectionNotify, @ev) then
      begin
        gotNotify := True;
        Break;
      end;
      if XCheckTypedEvent(disp, SelectionRequest, @evReq) then
      begin
        win.HandleEvent(evReq);
      end;
      Sleep(2);
    end;

    if gotNotify and (ev.xselection._property <> None) then
    begin
      actualType := None;
      actualFormat := 0;
      nItems := 0;
      bytesAfter := 0;
      propData := nil;
      ret := XGetWindowProperty(disp, reqWin, ev.xselection._property, 0, 1024 * 1024, True, AnyPropertyType,
                                @actualType, @actualFormat, @nItems, @bytesAfter, @propData);
      if (ret = 0) and Assigned(propData) and (nItems > 0) then
      begin
        SetLength(retStr, nItems);
        Move(propData^, retStr[1], nItems);
        XFree(propData);
        Result := retStr;
        Exit;
      end;
      if Assigned(propData) then
        XFree(propData);
    end;
  end;
end;

function FtGetClipboardText(): string;
var
  win: TFtX11Window;
  disp: PDisplay;
  clipAtom: TAtom;
  owner: TWindow;
  fetched: string;
begin
  win := GetSelectionRequestorWindow();
  if Assigned(win) and Assigned(win.FDisplay) and (win.FWindow <> None) then
  begin
    disp := win.FDisplay;
    clipAtom := win.FAtomClipboard;
    if clipAtom = None then
      clipAtom := XInternAtom(disp, 'CLIPBOARD', False);

    owner := XGetSelectionOwner(disp, clipAtom);
    if owner <> None then
    begin
      if owner = win.FWindow then
        Exit(gClipboardText);

      fetched := FtFetchSelectionFromX11(clipAtom);
      if fetched <> '' then
      begin
        gClipboardText := fetched;
        Exit(fetched);
      end;
    end
    else
    begin
      // Fallback: check primary selection (XA_PRIMARY = 1)
      owner := XGetSelectionOwner(disp, 1);
      if (owner <> None) and (owner <> win.FWindow) then
      begin
        fetched := FtFetchSelectionFromX11(1);
        if fetched <> '' then
        begin
          gClipboardText := fetched;
          Exit(fetched);
        end;
      end;
    end;
  end;

  Result := gClipboardText;
end;

procedure TFtX11Window.UpdateCursor();
var
  target: TFtWidget;
begin
  if Assigned(FPressedWidget) then
    target := FPressedWidget
  else
    target := FHoverWidget;

  if Assigned(target) and (target.GetCursor() = 1) then
  begin
    if FCursorIBeam = None then
      FCursorIBeam := XCreateFontCursor(FDisplay, 152); // XC_xterm
    XDefineCursor(FDisplay, FWindow, FCursorIBeam);
  end
  else
    XUndefineCursor(FDisplay, FWindow);
end;

procedure TFtX11Window.ClaimClipboard();
begin
  if Assigned(FDisplay) and (FWindow <> None) then
  begin
    if FAtomClipboard <> None then
      XSetSelectionOwner(FDisplay, FAtomClipboard, FWindow, CurrentTime);
    XFlush(FDisplay);
  end;
end;

procedure TFtX11Window.WidgetDestroyed(AWidget: TFtWidget);
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

procedure TFtX11Window.RequestFocus(AWidget: TFtWidget);
begin
  SetFocusedWidget(AWidget);
end;

procedure TFtX11Window.SetFocusedWidget(AWidget: TFtWidget);
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

procedure TFtX11Window.FocusNext(ABackward: Boolean = False);

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

procedure TFtX11Window.HandleEvents();
begin
  FtBackendProcessEvents();
end;

procedure TFtX11Window.HandleEvent(var Event: TXEvent);
var
  Target: TFtWidget;
  focusTarget: TFtWidget;
  ctxWidget: TFtWidget;
  keysym: TKeySym;
  strBuf: array[0..31] of AnsiChar;
  charCount: Integer;
  composeStatus: TXComposeStatus;
  req: TXSelectionRequestEvent;
  resp: TXSelectionEvent;
  targets: array[0..2] of TAtom;
  atomString: TAtom;
  sendText: string;
  navPop: TFtPopupMenu;
  clickedIdx: Integer;
  wasSameItem: Boolean;
begin
  case Event._type of
    Expose:
    begin
      InvalidateRect(Event.xexpose.x, Event.xexpose.y, Event.xexpose.width, Event.xexpose.height);
    end;

    ConfigureNotify:
    begin
      while XCheckTypedWindowEvent(FDisplay, FWindow, ConfigureNotify, @Event) do
        ;
      FPendingResizeW := Event.xconfigure.width;
      FPendingResizeH := Event.xconfigure.height;
      FHasPendingResize := True;
      X := Event.xconfigure.x;
      Y := Event.xconfigure.y;
      FLastConfigureTime := GetTickCount64();
    end;

    MotionNotify:
    begin
      if FWindowType in [ftwtPopupMenu, ftwtDropdownMenu] then
      begin
        if (Children.Count > 0) and (TFtWidget(Children[0]) is TFtPopupMenu) then
          TFtPopupMenu(Children[0]).MouseMove(Event.xmotion.x, Event.xmotion.y);
      end
      else if Assigned(GGrabbedPopup) and Assigned(FMainMenu) and
              (TFtMainMenu(FMainMenu).ActiveIndex >= 0) and
              (FMainMenu.HitTest(Event.xmotion.x, Event.xmotion.y) <> nil) then
      begin
        FMainMenu.MouseMove(Event.xmotion.x, Event.xmotion.y);
      end
      else if Assigned(FPressedWidget) then
      begin
        FPressedWidget.MouseMove(Event.xmotion.x, Event.xmotion.y);
      end
      else
      begin
        Target := HitTest(Event.xmotion.x, Event.xmotion.y);
        if Target = Self then
          Target := nil;

        if Target <> FHoverWidget then
        begin
          if Assigned(FHoverWidget) then
            FHoverWidget.MouseLeave();
          FHoverWidget := Target;
          if Assigned(FHoverWidget) then
            FHoverWidget.MouseEnter();
          UpdateCursor();
        end;
        if Assigned(Target) then
          Target.MouseMove(Event.xmotion.x, Event.xmotion.y);
      end;
    end;

    LeaveNotify:
    begin
      if Assigned(FHoverWidget) then
      begin
        FHoverWidget.MouseLeave();
        FHoverWidget := nil;
        UpdateCursor();
      end;
    end;

    ButtonPress:
    begin
      if FWindowType in [ftwtPopupMenu, ftwtDropdownMenu] then
      begin
        if (Event.xbutton.x < 0) or (Event.xbutton.x >= Width) or
           (Event.xbutton.y < 0) or (Event.xbutton.y >= Height) then
        begin
          if Assigned(GGrabbedPopup) then
            TFtPopupMenu(GGrabbedPopup).DismissAll();
        end
        else
        begin
          if (Children.Count > 0) and (TFtWidget(Children[0]) is TFtPopupMenu) then
          begin
            FPressedWidget := TFtPopupMenu(Children[0]);
            TFtPopupMenu(Children[0]).MouseDown(Event.xbutton.x, Event.xbutton.y, Event.xbutton.button);
          end;
        end;
      end
      else if Assigned(GGrabbedPopup) then
      begin
        if Assigned(FMainMenu) and (FMainMenu.HitTest(Event.xbutton.x, Event.xbutton.y) <> nil) then
        begin
          clickedIdx := TFtMainMenu(FMainMenu).ItemAt(Event.xbutton.x, Event.xbutton.y);
          wasSameItem := (TFtMainMenu(FMainMenu).ActiveIndex >= 0) and (clickedIdx = TFtMainMenu(FMainMenu).ActiveIndex);

          TFtPopupMenu(GGrabbedPopup).DismissAll();

          if (Event.xbutton.button = 1) and (clickedIdx >= 0) and not wasSameItem then
          begin
            FPressedWidget := FMainMenu;
            FMainMenu.MouseDown(Event.xbutton.x, Event.xbutton.y, Event.xbutton.button);
          end;
        end
        else
        begin
          TFtPopupMenu(GGrabbedPopup).DismissAll();
          if Event.xbutton.button = 3 then
          begin
            Target := HitTest(Event.xbutton.x, Event.xbutton.y);
            if Target = Self then
              Target := nil;
            focusTarget := FindFocusableWidget(Target);
            if Assigned(focusTarget) then
              SetFocusedWidget(focusTarget);
            if Assigned(Target) then
              Target.MouseDown(Event.xbutton.x, Event.xbutton.y, Event.xbutton.button);

            ctxWidget := Target;
            while Assigned(ctxWidget) and (ctxWidget.ContextMenu = nil) do
              ctxWidget := ctxWidget.Parent;

            if Assigned(ctxWidget) and Assigned(ctxWidget.ContextMenu) then
              TFtPopupMenu(ctxWidget.ContextMenu).Popup(Event.xbutton.x_root, Event.xbutton.y_root)
            else if Assigned(FContextMenu) then
              TFtPopupMenu(FContextMenu).Popup(Event.xbutton.x_root, Event.xbutton.y_root);
          end;
        end;
      end
      else if Event.xbutton.button = 3 then
      begin
        Target := HitTest(Event.xbutton.x, Event.xbutton.y);
        if Target = Self then
          Target := nil;
        focusTarget := FindFocusableWidget(Target);
        if Assigned(focusTarget) then
          SetFocusedWidget(focusTarget);
        if Assigned(Target) then
          Target.MouseDown(Event.xbutton.x, Event.xbutton.y, Event.xbutton.button);

        ctxWidget := Target;
        while Assigned(ctxWidget) and (ctxWidget.ContextMenu = nil) do
          ctxWidget := ctxWidget.Parent;

        if Assigned(ctxWidget) and Assigned(ctxWidget.ContextMenu) then
          TFtPopupMenu(ctxWidget.ContextMenu).Popup(Event.xbutton.x_root, Event.xbutton.y_root)
        else if Assigned(FContextMenu) then
          TFtPopupMenu(FContextMenu).Popup(Event.xbutton.x_root, Event.xbutton.y_root);
      end
      else
      begin
        Target := HitTest(Event.xbutton.x, Event.xbutton.y);
        if Target = Self then
          Target := nil;
        if not (Event.xbutton.button in [4, 5, 6, 7]) then
        begin
          focusTarget := FindFocusableWidget(Target);
          if not Assigned(focusTarget) then
          begin
            if Assigned(gOnPrimarySelectionLost) then
              gOnPrimarySelectionLost();
            FtClearPrimarySelection();
            SetFocusedWidget(nil);
          end
          else
            SetFocusedWidget(focusTarget);

          FPressedWidget := Target;
        end;
        UpdateCursor();
        if Assigned(Target) then
          Target.MouseDown(Event.xbutton.x, Event.xbutton.y, Event.xbutton.button);
      end;
    end;

    ButtonRelease:
    begin
      if FWindowType in [ftwtPopupMenu, ftwtDropdownMenu] then
      begin
        if (Children.Count > 0) and (TFtWidget(Children[0]) is TFtPopupMenu) then
        begin
          TFtPopupMenu(Children[0]).MouseUp(Event.xbutton.x, Event.xbutton.y, Event.xbutton.button);
          TFtPopupMenu(Children[0]).Click();
        end;
        FPressedWidget := nil;
        UpdateCursor();
      end
      else
      begin
        Target := HitTest(Event.xbutton.x, Event.xbutton.y);
        if Target = Self then
          Target := nil;
        if Assigned(FPressedWidget) then
        begin
          FPressedWidget.MouseUp(Event.xbutton.x, Event.xbutton.y, Event.xbutton.button);
          if Target = FPressedWidget then
            FPressedWidget.Click();
          FPressedWidget := nil;
          UpdateCursor();
        end;
      end;
    end;

    2: // KeyPress
    begin
      keysym := 0;
      charCount := XLookupString(@Event.xkey, strBuf, SizeOf(strBuf) - 1, @keysym, @composeStatus);
      if charCount > 0 then
        strBuf[charCount] := #0
      else
        strBuf[0] := #0;

      if Assigned(GGrabbedPopup) and TFtPopupMenu(GGrabbedPopup).IsOpen then
      begin
        navPop := TFtPopupMenu(GGrabbedPopup);
        while Assigned(navPop.ActiveSubMenu) and navPop.ActiveSubMenu.IsOpen do
          navPop := navPop.ActiveSubMenu;

        case keysym of
          $FF1B: // Escape
            TFtPopupMenu(GGrabbedPopup).DismissAll();
          $FF54: // Down arrow
            navPop.SelectNext();
          $FF52: // Up arrow
            navPop.SelectPrev();
          $FF53: // Right arrow
          begin
            if (navPop.HoverIndex >= 0) and (navPop.HoverIndex < navPop.Items.Count) and
               TFtMenuItem(navPop.Items[navPop.HoverIndex]).HasSubMenu() then
              navPop.ActivateSelected();
          end;
          $FF51: // Left arrow
          begin
            if Assigned(navPop.ParentPopupMenu) then
            begin
              navPop.Close();
              if Assigned(navPop.ParentPopupMenu) then
                navPop.ParentPopupMenu.Invalidate();
            end;
          end;
          $FF0D, $FF8D: // Return / Enter / KP_Enter
          begin
            navPop.ActivateSelected();
          end;
        end;
      end
      else if (keysym = $FF09) or (keysym = $FE20) then
      begin
        FocusNext((keysym = $FE20) or ((Event.xkey.state and 1) <> 0));
      end
      else if Assigned(FFocusedWidget) then
        FFocusedWidget.KeyDown(keysym, Event.xkey.state, StrPas(strBuf));
    end;

    3: // KeyRelease
    begin
      keysym := 0;
      XLookupString(@Event.xkey, nil, 0, @keysym, nil);
      if Assigned(FFocusedWidget) then
        FFocusedWidget.KeyUp(keysym, Event.xkey.state);
    end;

    SelectionRequest:
    begin
      req := Event.xselectionrequest;
      FillChar(resp, SizeOf(resp), 0);
      resp._type := SelectionNotify;
      resp.display := req.display;
      resp.requestor := req.requestor;
      resp.selection := req.selection;
      resp.target := req.target;
      resp._property := None;
      resp.time := req.time;
      atomString := 31; // XA_STRING = 31

      if (req.target = FAtomTargets) and (FAtomTargets <> None) then
      begin
        targets[0] := FAtomTargets;
        targets[1] := FAtomUTF8String;
        targets[2] := atomString;
        XChangeProperty(FDisplay, req.requestor, req._property, 4 {XA_ATOM=4}, 32, PropModeReplace, PByte(@targets), 3);
        resp._property := req._property;
      end
      else if (req.target = FAtomUTF8String) or (req.target = atomString) then
      begin
        if req.selection = 1 then
          sendText := gPrimarySelectionText
        else
          sendText := gClipboardText;

        if Length(sendText) > 0 then
          XChangeProperty(FDisplay, req.requestor, req._property, req.target, 8, PropModeReplace, PByte(PChar(sendText)), Length(sendText))
        else
          XChangeProperty(FDisplay, req.requestor, req._property, req.target, 8, PropModeReplace, nil, 0);
        resp._property := req._property;
      end;

      XSendEvent(FDisplay, req.requestor, False, 0, @resp);
    end;

    SelectionClear:
    begin
      if Event.xselectionclear.selection = 1 then
      begin
        if XGetSelectionOwner(FDisplay, 1) <> FWindow then
        begin
          gPrimarySelectionText := '';
          if Assigned(gOnPrimarySelectionLost) then
            gOnPrimarySelectionLost();
        end;
      end
      else if (FAtomClipboard <> None) and (Event.xselectionclear.selection = FAtomClipboard) then
      begin
        if XGetSelectionOwner(FDisplay, FAtomClipboard) <> FWindow then
        begin
          gClipboardText := '';
        end;
      end;
    end;

    ClientMessage:
    begin
      if (Event.xclient.format = 32) and
         (TAtom(Event.xclient.data.l[0]) = FWMDeleteWindow) then
      begin
        if FWindowType in [ftwtNormal, ftwtDialog] then
        begin
          Self.Free();
          if not HasMainWindows() then
            GRunning := False;
        end
        else
          Hide();
      end;
    end;

    DestroyNotify:
    begin
      if FWindowType in [ftwtNormal, ftwtDialog] then
      begin
        if not HasMainWindows() then
          GRunning := False;
      end;
    end;
  end;
end;

finalization
  if Assigned(GBroadcaster) then
  begin
    if Assigned(FtThemeManager()) then
      FtThemeManager().OnThemeChange := nil;
    if Assigned(FtGetStyleSheet()) then
      FtGetStyleSheet().OnChange := nil;
    FreeAndNil(GBroadcaster);
  end;
  if Assigned(GWindows) then
    FreeAndNil(GWindows);

end.