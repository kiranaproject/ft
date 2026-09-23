unit Ft.Backend.X11;

{$mode objfpc}{$H+}

interface

uses
  ctypes, SysUtils, Classes,
  Floria.XCB, Floria.XCB.Keysyms, Floria.XCB.Cursor, Floria.X11.KeySym,
  Floria.Canvas.Agg, Ft.Widget, Ft.Theme, Ft.Css, Ft.Animation, Ft.Window;

type
  TMWMHints = record
    flags: culong;
    functions: culong;
    decorations: culong;
    input_mode: clong;
    status: culong;
  end;
  PMWMHints = ^TMWMHints;

  Pxcb_expose_event_t = ^xcb_expose_event_t;
  Pxcb_configure_notify_event_t = ^xcb_configure_notify_event_t;
  Pxcb_motion_notify_event_t = ^xcb_motion_notify_event_t;
  Pxcb_enter_notify_event_t = ^xcb_enter_notify_event_t;
  Pxcb_leave_notify_event_t = ^xcb_leave_notify_event_t;
  Pxcb_button_press_event_t = ^xcb_button_press_event_t;
  Pxcb_button_release_event_t = ^xcb_button_release_event_t;
  Pxcb_key_press_event_t = ^xcb_key_press_event_t;
  Pxcb_key_release_event_t = ^xcb_key_release_event_t;
  Pxcb_selection_clear_event_t = ^xcb_selection_clear_event_t;
  Pxcb_selection_request_event_t = ^xcb_selection_request_event_t;
  Pxcb_selection_notify_event_t = ^xcb_selection_notify_event_t;
  Pxcb_client_message_event_t = ^xcb_client_message_event_t;
  Pxcb_destroy_notify_event_t = ^xcb_destroy_notify_event_t;

  TFT_pollfd = record
    fd: cint;
    events: cshort;
    revents: cshort;
  end;

function libc_poll(fds: Pointer; nfds: culong; timeout: cint): cint; cdecl; external 'c' name 'poll';

const
  MWM_HINTS_DECORATIONS = 1 shl 1;

type
  TFtX11Window = class(TFtWindow)
  private
    FConnection: Pxcb_connection_t;
    FWindow: xcb_window_t;
    FGC: xcb_gcontext_t;
    FScratchBuffer: Pointer;
    FScratchBufferSize: Cardinal;
    FVisual: xcb_visualid_t;
    FDepth: Byte;
    FColormap: xcb_colormap_t;
    FHasPendingResize: Boolean;
    FPendingResizeW: Integer;
    FPendingResizeH: Integer;
    FLastResizeTime: QWord;
    FLastConfigureTime: QWord;
    FLastResizeRenderTime: QWord;
    FCurrentCursor: xcb_cursor_t;

    procedure UpdateBlurBehindRegion();
  public
    function GetScreenWidth(): Integer; override;
    function GetScreenHeight(): Integer; override;
    constructor Create(W, H: Integer; const ATitle: string = ''); override;
    destructor Destroy(); override;
    procedure Resize(NewW, NewH: Integer; AApplyToBackend: Boolean = True); override;
    procedure SetTitle(const ATitle: string); override;
    procedure SetBorderless(ABorderless: Boolean); override;
    procedure SetSkipTaskbar(ASkip: Boolean); override;
    procedure SetWindowType(AType: TFtWindowType); override;
    procedure SetWindowOpacity(AOpacity: Double); override;
    procedure SetBackgroundBlur(AValue: Boolean); override;
    procedure SetPosition(NewX, NewY: Integer); override;
    procedure GetPosition(out OutX, OutY: Integer); override;
    function ClientToScreen(AX, AY: Integer): TPoint; override;
    function ScreenToClient(AX, AY: Integer): TPoint; override;
    procedure Repaint(); override;
    procedure Show(); override;
    procedure Hide(); override;
    procedure UpdateCursor(); override;
    procedure ClearActivePopup(); override;
    procedure ClaimClipboard(); override;
    procedure ClaimPrimarySelection(const AText: string); override;
    procedure ClearPrimarySelection(); override;
    function FetchClipboardText(): string; override;
    function FetchPrimarySelectionText(): string; override;
    procedure GrabInput(); override;
    procedure UngrabInput(); override;
    function GetNativeHandle(): Pointer; override;
    procedure WidgetDestroyed(AWidget: TFtWidget); override;

    procedure HandleEvents();
    procedure HandleGenericEvent(Event: Pxcb_generic_event_t);

    property Window: xcb_window_t read FWindow;
    property Connection: Pxcb_connection_t read FConnection;
    property Display: Pxcb_connection_t read FConnection; // For backwards compatibility
  end;

  TFtHintWindow = class(TFtWidget)
  private
    FPopupWindow: TFtWindow;
    FText: string;
    FLines: TStringList;
  public
    constructor Create(AParent: TFtWidget); override;
    destructor Destroy(); override;
    procedure SetHintText(const AText: string);
    procedure ShowAt(AScreenX, AScreenY: Integer);
    procedure Hide();
    procedure Draw(Canvas: TFtCanvasAgg); override;
    property PopupWindow: TFtWindow read FPopupWindow;
  end;

var
  GConnection: Pxcb_connection_t = nil;
  GDisplay: Pxcb_connection_t = nil; // For backwards compatibility
  GScreen: Pxcb_screen_t = nil;
  GKeySymbols: Pxcb_key_symbols_t = nil;
  GCursorContext: Pxcb_cursor_context_t = nil;
  GCursorIBeam: xcb_cursor_t = 0;
  GCursorSizeH: xcb_cursor_t = 0;
  GCursorSizeV: xcb_cursor_t = 0;
  GCursorHand:  xcb_cursor_t = 0;
  GRunning: Boolean = False;

procedure FtBackendInit();
procedure FtBackendMainLoop();
procedure FtBackendProcessEvents();
procedure FtBackendQuit();
procedure FtGrabMenuInput(AWindow: TFtWindow);
procedure FtUngrabMenuInput(AWindow: TFtWindow);
function FindWindowByHandle(AWindow: xcb_window_t): TFtX11Window;
function HasMainWindows(): Boolean;
procedure FtSetClipboardText(const AText: string);
function FtGetClipboardText(): string;
procedure FtClaimPrimarySelection(const AText: string);
procedure FtClearPrimarySelection();
procedure FtSetSelectionLostHandler(AHandler: TFtSelectionLostHandler);
function FtGetScreenWidth(): Integer;
function FtGetScreenHeight(): Integer;

procedure FtShowHint(AWidget: TFtWidget; const AHintText: string; AScreenX, AScreenY: Integer);
procedure FtHideHint();
function FtIsHintVisible(): Boolean;
procedure FtSetHintDelay(ADelayMs: Integer);
function FtGetHintDelay(): Integer;

implementation

uses
  Math, Floria.Font, Ft.Widget.Menus;

procedure c_free(p: Pointer); cdecl; external 'c' name 'free';
function xcb_cursor_load_cursor(ctx: Pxcb_cursor_context_t; const name: PChar): xcb_cursor_t; cdecl; external 'xcb-cursor' name 'xcb_cursor_load_cursor';
function xcb_key_press_lookup_keysym(syms: Pxcb_key_symbols_t; event: Pxcb_key_press_event_t; col: Integer): xcb_keysym_t; cdecl; external 'xcb-keysyms' name 'xcb_key_press_lookup_keysym';
function xcb_key_release_lookup_keysym(syms: Pxcb_key_symbols_t; event: Pxcb_key_release_event_t; col: Integer): xcb_keysym_t; cdecl; external 'xcb-keysyms' name 'xcb_key_release_lookup_keysym';

var
  atomWMProtocols: xcb_atom_t = 0;
  atomWMDeleteWindow: xcb_atom_t = 0;
  atomWMName: xcb_atom_t = 0;
  atomClipboard: xcb_atom_t = 0;
  atomUTF8String: xcb_atom_t = 0;
  atomTargets: xcb_atom_t = 0;
  atomFtSelection: xcb_atom_t = 0;
  atomMotifWmHints: xcb_atom_t = 0;
  atomNetWmName: xcb_atom_t = 0;
  atomNetWmIconName: xcb_atom_t = 0;
  atomNetWmState: xcb_atom_t = 0;
  atomNetWmStateSkipTaskbar: xcb_atom_t = 0;
  atomNetWmStateSkipPager: xcb_atom_t = 0;
  atomNetWmWindowType: xcb_atom_t = 0;
  atomNetWmWindowTypeNormal: xcb_atom_t = 0;
  atomNetWmWindowTypeDialog: xcb_atom_t = 0;
  atomNetWmWindowTypePopupMenu: xcb_atom_t = 0;
  atomNetWmWindowTypeDropdownMenu: xcb_atom_t = 0;
  atomNetWmWindowTypeTooltip: xcb_atom_t = 0;
  atomNetWmWindowTypeUtility: xcb_atom_t = 0;
  atomNetWmWindowOpacity: xcb_atom_t = 0;
  atomBlurRegionNet: xcb_atom_t = 0;
  atomBlurRegionKde: xcb_atom_t = 0;

  GHintWindow: TFtHintWindow = nil;
  GHintTargetWidget: TFtWidget = nil;
  GHintHoverStartMs: QWord = 0;
  GHintDelayMs: Integer = 500;
  GHintLastMouseX: Integer = -1;
  GHintLastMouseY: Integer = -1;
  GHintVisible: Boolean = False;

function InternAtom(const AName: string): xcb_atom_t;
var
  cookie: xcb_intern_atom_cookie_t;
  reply: Pxcb_intern_atom_reply_t;
begin
  cookie := xcb_intern_atom(GConnection, 0, Length(AName), PChar(AName));
  reply := xcb_intern_atom_reply(GConnection, cookie, nil);
  if Assigned(reply) then
  begin
    Result := reply^.atom;
    c_free(reply);
  end
  else
    Result := 0;
end;

procedure InitAtoms();
begin
  atomWMProtocols := InternAtom('WM_PROTOCOLS');
  atomWMDeleteWindow := InternAtom('WM_DELETE_WINDOW');
  atomWMName := InternAtom('WM_NAME');
  atomClipboard := InternAtom('CLIPBOARD');
  atomUTF8String := InternAtom('UTF8_STRING');
  atomTargets := InternAtom('TARGETS');
  atomFtSelection := InternAtom('FT_SELECTION');
  atomMotifWmHints := InternAtom('_MOTIF_WM_HINTS');
  atomNetWmName := InternAtom('_NET_WM_NAME');
  atomNetWmIconName := InternAtom('_NET_WM_ICON_NAME');
  atomNetWmState := InternAtom('_NET_WM_STATE');
  atomNetWmStateSkipTaskbar := InternAtom('_NET_WM_STATE_SKIP_TASKBAR');
  atomNetWmStateSkipPager := InternAtom('_NET_WM_STATE_SKIP_PAGER');
  atomNetWmWindowType := InternAtom('_NET_WM_WINDOW_TYPE');
  atomNetWmWindowTypeNormal := InternAtom('_NET_WM_WINDOW_TYPE_NORMAL');
  atomNetWmWindowTypeDialog := InternAtom('_NET_WM_WINDOW_TYPE_DIALOG');
  atomNetWmWindowTypePopupMenu := InternAtom('_NET_WM_WINDOW_TYPE_POPUP_MENU');
  atomNetWmWindowTypeDropdownMenu := InternAtom('_NET_WM_WINDOW_TYPE_DROPDOWN_MENU');
  atomNetWmWindowTypeTooltip := InternAtom('_NET_WM_WINDOW_TYPE_TOOLTIP');
  atomNetWmWindowTypeUtility := InternAtom('_NET_WM_WINDOW_TYPE_UTILITY');
  atomNetWmWindowOpacity := InternAtom('_NET_WM_WINDOW_OPACITY');
  atomBlurRegionNet := InternAtom('_NET_WM_BLUR_BEHIND_REGION');
  atomBlurRegionKde := InternAtom('_KDE_NET_WM_BLUR_BEHIND_REGION');
end;

function FindVisual(screen: Pxcb_screen_t; targetDepth: Integer): xcb_visualid_t;
var
  depth_iter: xcb_depth_iterator_t;
  vis_iter: xcb_visualtype_iterator_t;
begin
  Result := 0;
  if screen = nil then Exit;
  depth_iter := xcb_screen_allowed_depths_iterator(screen);
  while depth_iter.rem > 0 do
  begin
    if depth_iter.data^.depth = targetDepth then
    begin
      vis_iter := xcb_depth_visuals_iterator(depth_iter.data);
      while vis_iter.rem > 0 do
      begin
        // TrueColor = 4
        if (vis_iter.data^._class = 4) or (targetDepth = 32) then
          Exit(vis_iter.data^.visual_id);
        xcb_visualtype_next(@vis_iter);
      end;
    end;
    xcb_depth_next(@depth_iter);
  end;
end;

procedure FtBackendInit();
var
  screenIdx: cint = 0;
  setup: Pxcb_setup_t;
  iter: xcb_screen_iterator_t;
begin
  GConnection := xcb_connect(nil, @screenIdx);
  if (GConnection = nil) or (xcb_connection_has_error(GConnection) > 0) then
    raise Exception.Create('Floria Toolkit: Unable to connect to XCB display.');

  GDisplay := GConnection;
  setup := xcb_get_setup(GConnection);
  iter := xcb_setup_roots_iterator(setup);
  while (screenIdx > 0) and (iter.rem > 0) do
  begin
    xcb_screen_next(@iter);
    Dec(screenIdx);
  end;
  GScreen := iter.data;

  InitAtoms();

  GKeySymbols := xcb_key_symbols_alloc(GConnection);
  if xcb_cursor_context_new(GConnection, GScreen, @GCursorContext) >= 0 then
  begin
    GCursorIBeam := xcb_cursor_load_cursor(GCursorContext, 'xterm');

    GCursorSizeH := xcb_cursor_load_cursor(GCursorContext, 'col-resize');
    if GCursorSizeH = 0 then
      GCursorSizeH := xcb_cursor_load_cursor(GCursorContext, 'ew-resize');
    if GCursorSizeH = 0 then
      GCursorSizeH := xcb_cursor_load_cursor(GCursorContext, 'sb_h_double_arrow');

    GCursorSizeV := xcb_cursor_load_cursor(GCursorContext, 'row-resize');
    if GCursorSizeV = 0 then
      GCursorSizeV := xcb_cursor_load_cursor(GCursorContext, 'ns-resize');
    if GCursorSizeV = 0 then
      GCursorSizeV := xcb_cursor_load_cursor(GCursorContext, 'sb_v_double_arrow');

    GCursorHand := xcb_cursor_load_cursor(GCursorContext, 'pointer');
    if GCursorHand = 0 then
      GCursorHand := xcb_cursor_load_cursor(GCursorContext, 'hand2');
  end;

  GRunning := True;
end;

procedure FtBackendQuit();
begin
  GRunning := False;
end;

function FindWindowByHandle(AWindow: xcb_window_t): TFtX11Window;
var
  i: Integer;
  w: TFtWindow;
begin
  Result := nil;
  if not Assigned(GWindows) or (AWindow = 0) then Exit;
  for i := 0 to GWindows.Count - 1 do
  begin
    w := TFtWindow(GWindows[i]);
    if (w is TFtX11Window) and (TFtX11Window(w).FWindow = AWindow) then
      Exit(TFtX11Window(w));
  end;
end;

function HasMainWindows(): Boolean;
var
  i: Integer;
  w: TFtWindow;
begin
  Result := False;
  if not Assigned(GWindows) then Exit;
  for i := 0 to GWindows.Count - 1 do
  begin
    w := TFtWindow(GWindows[i]);
    if w.WindowType in [ftwtNormal, ftwtDialog] then
      Exit(True);
  end;
end;

function FtGetScreenWidth(): Integer;
begin
  if Assigned(GScreen) then
    Result := GScreen^.width_in_pixels
  else
    Result := 1920;
end;

function FtGetScreenHeight(): Integer;
begin
  if Assigned(GScreen) then
    Result := GScreen^.height_in_pixels
  else
    Result := 1080;
end;

procedure FtGrabMenuInput(AWindow: TFtWindow);
var
  mask: Word;
  xwin: TFtX11Window;
begin
  if Assigned(AWindow) and (AWindow is TFtX11Window) then
  begin
    xwin := TFtX11Window(AWindow);
    if (xwin.FWindow <> 0) and Assigned(xwin.FConnection) then
    begin
      mask := XCB_EVENT_MASK_BUTTON_PRESS or
              XCB_EVENT_MASK_BUTTON_RELEASE or
              XCB_EVENT_MASK_POINTER_MOTION;
      xcb_grab_pointer(xwin.FConnection, 1, xwin.FWindow, mask,
                       XCB_GRAB_MODE_ASYNC, XCB_GRAB_MODE_ASYNC, 0, 0, XCB_CURRENT_TIME);
      xcb_grab_keyboard(xwin.FConnection, 1, xwin.FWindow, XCB_CURRENT_TIME,
                        XCB_GRAB_MODE_ASYNC, XCB_GRAB_MODE_ASYNC);
      xcb_flush(xwin.FConnection);
    end;
  end;
end;

procedure FtUngrabMenuInput(AWindow: TFtWindow);
var
  xwin: TFtX11Window;
begin
  if Assigned(AWindow) and (AWindow is TFtX11Window) then
  begin
    xwin := TFtX11Window(AWindow);
    if Assigned(xwin.FConnection) then
    begin
      xcb_ungrab_pointer(xwin.FConnection, XCB_CURRENT_TIME);
      xcb_ungrab_keyboard(xwin.FConnection, XCB_CURRENT_TIME);
      xcb_flush(xwin.FConnection);
    end;
  end;
end;

procedure CheckHintTimer();
var
  nowMs: QWord;
  effHint: string;
begin
  if not GHintVisible and Assigned(GHintTargetWidget) and (GHintHoverStartMs > 0) then
  begin
    nowMs := GetTickCount64();
    if (nowMs - GHintHoverStartMs) >= QWord(GHintDelayMs) then
    begin
      effHint := GHintTargetWidget.GetEffectiveHint();
      if effHint <> '' then
        FtShowHint(GHintTargetWidget, effHint, GHintLastMouseX, GHintLastMouseY);
      GHintHoverStartMs := 0;
    end;
  end;
end;

procedure HandleHintMotion(AWindow: TFtX11Window; ATarget: TFtWidget; ARootX, ARootY: Integer);
begin
  if (ATarget = nil) or not ATarget.Visible or not ATarget.ShowHint then
  begin
    FtHideHint();
    GHintTargetWidget := nil;
    GHintHoverStartMs := 0;
    Exit;
  end;

  if ATarget <> GHintTargetWidget then
  begin
    FtHideHint();
    GHintTargetWidget := ATarget;
    GHintHoverStartMs := GetTickCount64();
    GHintLastMouseX := ARootX;
    GHintLastMouseY := ARootY;
  end
  else
  begin
    if (Abs(ARootX - GHintLastMouseX) > 6) or (Abs(ARootY - GHintLastMouseY) > 6) then
    begin
      if GHintVisible then
        FtHideHint();
      GHintHoverStartMs := GetTickCount64();
      GHintLastMouseX := ARootX;
      GHintLastMouseY := ARootY;
    end;
  end;
end;

procedure FtBackendProcessEvents();
var
  ev: Pxcb_generic_event_t;
  evType: Byte;
  win: TFtX11Window;
  winId: xcb_window_t;
  i: Integer;
  nowMs: QWord;
  shouldResize: Boolean;
begin
  while Assigned(GConnection) do
  begin
    ev := xcb_poll_for_event(GConnection);
    if ev = nil then Break;

    evType := ev^.response_type and $7F;
    winId := 0;

    case evType of
      XCB_EXPOSE: winId := Pxcb_expose_event_t(ev)^.window;
      XCB_CONFIGURE_NOTIFY: winId := Pxcb_configure_notify_event_t(ev)^.window;
      XCB_MOTION_NOTIFY: winId := Pxcb_motion_notify_event_t(ev)^.event;
      XCB_ENTER_NOTIFY, XCB_LEAVE_NOTIFY: winId := Pxcb_enter_notify_event_t(ev)^.event;
      XCB_BUTTON_PRESS, XCB_BUTTON_RELEASE: winId := Pxcb_button_press_event_t(ev)^.event;
      XCB_KEY_PRESS, XCB_KEY_RELEASE: winId := Pxcb_key_press_event_t(ev)^.event;
      XCB_SELECTION_CLEAR: winId := Pxcb_selection_clear_event_t(ev)^.owner;
      XCB_SELECTION_REQUEST: winId := Pxcb_selection_request_event_t(ev)^.owner;
      XCB_SELECTION_NOTIFY: winId := Pxcb_selection_notify_event_t(ev)^.requestor;
      XCB_CLIENT_MESSAGE: winId := Pxcb_client_message_event_t(ev)^.window;
      XCB_DESTROY_NOTIFY: winId := Pxcb_destroy_notify_event_t(ev)^.window;
    end;

    win := FindWindowByHandle(winId);
    if Assigned(win) then
      win.HandleGenericEvent(ev)
    else
    begin
      if (evType = XCB_SELECTION_REQUEST) or (evType = XCB_SELECTION_CLEAR) then
      begin
        if Assigned(GActiveWindow) and (GActiveWindow is TFtX11Window) then
          TFtX11Window(GActiveWindow).HandleGenericEvent(ev);
      end;
    end;

    c_free(ev);
  end;

  if Assigned(GWindows) then
  begin
    nowMs := GetTickCount64();
    for i := GWindows.Count - 1 downto 0 do
    begin
      if i < GWindows.Count then
      begin
        if TObject(GWindows[i]) is TFtX11Window then
        begin
          win := TFtX11Window(GWindows[i]);
          if win.FHasPendingResize then
          begin
            if (win.FPendingResizeW = win.Width) and (win.FPendingResizeH = win.Height) then
              win.FHasPendingResize := False
            else
            begin
              shouldResize := ((nowMs - win.FLastConfigureTime) >= 25) or
                              ((nowMs - win.FLastResizeRenderTime) >= 30);
              if shouldResize then
              begin
                win.FHasPendingResize := False;
                win.NeedsRepaint := False;
                win.Resize(win.FPendingResizeW, win.FPendingResizeH, False);
              end;
            end;
          end;

          if win.NeedsRepaint then
          begin
            win.NeedsRepaint := False;
            win.Repaint();
          end;
        end;
      end;
    end;
  end;
  CheckHintTimer();
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
    if TObject(GWindows[i]) is TFtX11Window then
    begin
      w := TFtX11Window(GWindows[i]);
      if w.FHasPendingResize or ((ANowMs >= w.FLastConfigureTime) and ((ANowMs - w.FLastConfigureTime) < 150)) then
        Exit(True);
    end;
  end;
end;

procedure FtBackendMainLoop();
var
  frameStartMs, nowMs: QWord;
  elapsedMs: Integer;
  animator: TFtAnimator;
  pfd: TFT_pollfd;
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
      nowMs := GetTickCount64();
      if IsAnyWindowResizing(nowMs) then
        Sleep(8)
      else if Assigned(GConnection) then
      begin
        xcb_flush(GConnection);
        pfd.fd := xcb_get_file_descriptor(GConnection);
        pfd.events := 1; // POLLIN
        pfd.revents := 0;
        libc_poll(@pfd, 1, 50);
      end
      else
        Sleep(10);
    end;
  end;

  if Assigned(GCursorContext) then
  begin
    xcb_cursor_context_free(GCursorContext);
    GCursorContext := nil;
  end;
  if Assigned(GKeySymbols) then
  begin
    xcb_key_symbols_free(GKeySymbols);
    GKeySymbols := nil;
  end;
  if Assigned(GConnection) then
  begin
    xcb_disconnect(GConnection);
    GConnection := nil;
    GDisplay := nil;
  end;
end;

procedure FtXcbPutImage(c: Pxcb_connection_t; wid: xcb_window_t; gc: xcb_gcontext_t;
                        depth: Byte; buffer: Pointer; bufWidth, bufHeight: Integer;
                        rx, ry, rw, rh: Integer; var scratchBuf: Pointer; var scratchSize: Cardinal);
var
  maxBytes, rowsPerChunk: Cardinal;
  curY, remH, chunkH: Integer;
  chunkData: PByte;
  row: Integer;
  needed: Cardinal;
begin
  if (rw <= 0) or (rh <= 0) or (buffer = nil) then Exit;

  maxBytes := xcb_get_maximum_request_length(c) * 4;
  if maxBytes > 32 then
    Dec(maxBytes, 32)
  else
    maxBytes := 65535 * 4 - 32;

  if (rw = bufWidth) and (rx = 0) then
  begin
    rowsPerChunk := maxBytes div Cardinal(rw * 4);
    if rowsPerChunk < 1 then rowsPerChunk := 1;

    curY := ry;
    remH := rh;
    while remH > 0 do
    begin
      chunkH := remH;
      if Cardinal(chunkH) > rowsPerChunk then
        chunkH := rowsPerChunk;
      chunkData := PByte(buffer) + ((curY * bufWidth + rx) * 4);
      xcb_put_image(c, XCB_IMAGE_FORMAT_Z_PIXMAP, wid, gc, Word(rw), Word(chunkH),
                    SmallInt(rx), SmallInt(curY), 0, depth,
                    Cardinal(chunkH * rw * 4), chunkData);
      Inc(curY, chunkH);
      Dec(remH, chunkH);
    end;
  end
  else
  begin
    rowsPerChunk := maxBytes div Cardinal(rw * 4);
    if rowsPerChunk < 1 then rowsPerChunk := 1;

    curY := ry;
    remH := rh;
    while remH > 0 do
    begin
      chunkH := remH;
      if Cardinal(chunkH) > rowsPerChunk then
        chunkH := rowsPerChunk;

      needed := Cardinal(chunkH * rw * 4);
      if needed > scratchSize then
      begin
        ReallocMem(scratchBuf, needed);
        scratchSize := needed;
      end;

      for row := 0 to chunkH - 1 do
      begin
        Move((PByte(buffer) + (((curY + row) * bufWidth + rx) * 4))^,
             (PByte(scratchBuf) + (row * rw * 4))^,
             rw * 4);
      end;

      xcb_put_image(c, XCB_IMAGE_FORMAT_Z_PIXMAP, wid, gc, Word(rw), Word(chunkH),
                    SmallInt(rx), SmallInt(curY), 0, depth,
                    needed, PByte(scratchBuf));
      Inc(curY, chunkH);
      Dec(remH, chunkH);
    end;
  end;
end;

constructor TFtX11Window.Create(W, H: Integer; const ATitle: string);
var
  vis32: xcb_visualid_t;
  mask: Cardinal;
  valList: xcb_create_window_value_list_t;
begin
  inherited Create(W, H, ATitle);
  FConnection := GConnection;
  FScratchBuffer := nil;
  FScratchBufferSize := 0;

  vis32 := FindVisual(GScreen, 32);
  if vis32 <> 0 then
  begin
    FVisual := vis32;
    FDepth := 32;
    FColormap := xcb_generate_id(FConnection);
    xcb_create_colormap(FConnection, XCB_COLORMAP_ALLOC_NONE, FColormap, GScreen^.root, FVisual);
  end
  else
  begin
    FVisual := GScreen^.root_visual;
    FDepth := GScreen^.root_depth;
    FColormap := 0;
  end;

  FWindow := xcb_generate_id(FConnection);

  FillChar(valList, SizeOf(valList), 0);
  valList.background_pixmap := 0; // None - disable X background clear to eliminate flicker
  valList.border_pixel := 0;
  valList.bit_gravity := XCB_GRAVITY_NORTH_WEST;
  valList.event_mask := XCB_EVENT_MASK_EXPOSURE or
                        XCB_EVENT_MASK_BUTTON_PRESS or
                        XCB_EVENT_MASK_BUTTON_RELEASE or
                        XCB_EVENT_MASK_POINTER_MOTION or
                        XCB_EVENT_MASK_LEAVE_WINDOW or
                        XCB_EVENT_MASK_STRUCTURE_NOTIFY or
                        XCB_EVENT_MASK_KEY_PRESS or
                        XCB_EVENT_MASK_KEY_RELEASE or
                        XCB_EVENT_MASK_PROPERTY_CHANGE;

  mask := XCB_CW_BACK_PIXMAP or XCB_CW_BORDER_PIXEL or XCB_CW_BIT_GRAVITY or XCB_CW_EVENT_MASK;
  if FDepth = 32 then
  begin
    mask := mask or XCB_CW_COLORMAP;
    valList.colormap := FColormap;
  end;

  xcb_create_window_aux(FConnection, FDepth, FWindow, GScreen^.root,
                        100, 100, Width, Height, 0,
                        XCB_WINDOW_CLASS_INPUT_OUTPUT, FVisual, mask, @valList);

  SetTitle(ATitle);
  FCurrentCursor := High(xcb_cursor_t);
  FHasPendingResize := False;
  FPendingResizeW := 0;
  FPendingResizeH := 0;
  FLastResizeTime := 0;
  FLastConfigureTime := 0;
  FLastResizeRenderTime := 0;

  // Configure WM_PROTOCOLS for graceful window close
  xcb_change_property(FConnection, XCB_PROP_MODE_REPLACE, FWindow,
                      atomWMProtocols, XCB_ATOM_ATOM, 32, 1, @atomWMDeleteWindow);

  FGC := xcb_generate_id(FConnection);
  xcb_create_gc(FConnection, FGC, FWindow, 0, nil);

  xcb_flush(FConnection);
end;

procedure TFtX11Window.SetTitle(const ATitle: string);
var
  p: PChar;
  len: Integer;
begin
  inherited SetTitle(ATitle);
  p := PChar(ATitle);
  len := Length(ATitle);

  if (len > 0) and (FWindow <> 0) and Assigned(FConnection) then
  begin
    xcb_change_property(FConnection, XCB_PROP_MODE_REPLACE, FWindow, atomNetWmName, atomUTF8String, 8, len, p);
    xcb_change_property(FConnection, XCB_PROP_MODE_REPLACE, FWindow, atomNetWmIconName, atomUTF8String, 8, len, p);
    xcb_change_property(FConnection, XCB_PROP_MODE_REPLACE, FWindow, atomWMName, atomUTF8String, 8, len, p);
    xcb_flush(FConnection);
  end;
end;

procedure TFtX11Window.SetBorderless(ABorderless: Boolean);
var
  hints: TMWMHints;
  val: xcb_change_window_attributes_value_list_t;
begin
  inherited SetBorderless(ABorderless);
  if (FWindow = 0) or (FConnection = nil) then Exit;

  FillChar(hints, SizeOf(hints), 0);
  hints.flags := MWM_HINTS_DECORATIONS;
  if ABorderless then
    hints.decorations := 0
  else
    hints.decorations := 1;

  xcb_change_property(FConnection, XCB_PROP_MODE_REPLACE, FWindow, atomMotifWmHints, atomMotifWmHints, 32, 5, @hints);

  if FWindowType in [ftwtPopupMenu, ftwtDropdownMenu, ftwtTooltip] then
  begin
    FillChar(val, SizeOf(val), 0);
    val.override_redirect := 1;
    xcb_change_window_attributes_aux(FConnection, FWindow, XCB_CW_OVERRIDE_REDIRECT, @val);
  end;
  xcb_flush(FConnection);
end;

procedure TFtX11Window.SetSkipTaskbar(ASkip: Boolean);
var
  atoms: array[0..1] of xcb_atom_t;
begin
  inherited SetSkipTaskbar(ASkip);
  if (FWindow = 0) or (FConnection = nil) then Exit;

  if ASkip then
  begin
    atoms[0] := atomNetWmStateSkipTaskbar;
    atoms[1] := atomNetWmStateSkipPager;
    xcb_change_property(FConnection, XCB_PROP_MODE_REPLACE, FWindow, atomNetWmState, XCB_ATOM_ATOM, 32, 2, @atoms[0]);
  end
  else
    xcb_delete_property(FConnection, FWindow, atomNetWmState);
  xcb_flush(FConnection);
end;

procedure TFtX11Window.SetWindowType(AType: TFtWindowType);
var
  typeAtom: xcb_atom_t;
  val: xcb_change_window_attributes_value_list_t;
begin
  inherited SetWindowType(AType);
  if (FWindow = 0) or (FConnection = nil) then Exit;

  case AType of
    ftwtNormal: typeAtom := atomNetWmWindowTypeNormal;
    ftwtDialog: typeAtom := atomNetWmWindowTypeDialog;
    ftwtPopupMenu: typeAtom := atomNetWmWindowTypePopupMenu;
    ftwtDropdownMenu: typeAtom := atomNetWmWindowTypeDropdownMenu;
    ftwtTooltip: typeAtom := atomNetWmWindowTypeTooltip;
    ftwtUtility: typeAtom := atomNetWmWindowTypeUtility;
  else
    typeAtom := atomNetWmWindowTypeNormal;
  end;

  xcb_change_property(FConnection, XCB_PROP_MODE_REPLACE, FWindow, atomNetWmWindowType, XCB_ATOM_ATOM, 32, 1, @typeAtom);

  if AType in [ftwtPopupMenu, ftwtDropdownMenu, ftwtTooltip] then
  begin
    FillChar(val, SizeOf(val), 0);
    val.override_redirect := 1;
    xcb_change_window_attributes_aux(FConnection, FWindow, XCB_CW_OVERRIDE_REDIRECT, @val);
    SetSkipTaskbar(True);
    SetBorderless(True);
  end;
  xcb_flush(FConnection);
end;

procedure TFtX11Window.SetWindowOpacity(AOpacity: Double);
var
  cardinalValue: Cardinal;
begin
  inherited SetWindowOpacity(AOpacity);
  if (FConnection = nil) or (FWindow = 0) then Exit;

  if AOpacity >= 0.999 then
    xcb_delete_property(FConnection, FWindow, atomNetWmWindowOpacity)
  else
  begin
    cardinalValue := Cardinal(Round(AOpacity * 4294967295.0));
    xcb_change_property(FConnection, XCB_PROP_MODE_REPLACE, FWindow, atomNetWmWindowOpacity, XCB_ATOM_CARDINAL, 32, 1, @cardinalValue);
  end;
  xcb_flush(FConnection);
end;

procedure TFtX11Window.SetBackgroundBlur(AValue: Boolean);
begin
  if FBackgroundBlur <> AValue then
  begin
    inherited SetBackgroundBlur(AValue);
    UpdateBlurBehindRegion();
  end;
end;

procedure TFtX11Window.UpdateBlurBehindRegion();
var
  data: array[0..3] of Cardinal;
begin
  if (FWindow = 0) or (FConnection = nil) then Exit;

  if FBackgroundBlur then
  begin
    data[0] := 0;
    data[1] := 0;
    data[2] := Width;
    data[3] := Height;
    xcb_change_property(FConnection, XCB_PROP_MODE_REPLACE, FWindow, atomBlurRegionNet, XCB_ATOM_CARDINAL, 32, 4, @data[0]);
    xcb_change_property(FConnection, XCB_PROP_MODE_REPLACE, FWindow, atomBlurRegionKde, XCB_ATOM_CARDINAL, 32, 4, @data[0]);
  end
  else
  begin
    xcb_delete_property(FConnection, FWindow, atomBlurRegionNet);
    xcb_delete_property(FConnection, FWindow, atomBlurRegionKde);
  end;
  xcb_flush(FConnection);
end;

function TFtX11Window.GetScreenWidth(): Integer;
begin
  Result := FtGetScreenWidth();
end;

function TFtX11Window.GetScreenHeight(): Integer;
begin
  Result := FtGetScreenHeight();
end;

procedure TFtX11Window.SetPosition(NewX, NewY: Integer);
var
  values: array[0..1] of Cardinal;
begin
  X := NewX;
  Y := NewY;
  if (FWindow <> 0) and Assigned(FConnection) then
  begin
    values[0] := Cardinal(NewX);
    values[1] := Cardinal(NewY);
    xcb_configure_window(FConnection, FWindow, XCB_CONFIG_WINDOW_X or XCB_CONFIG_WINDOW_Y, @values[0]);
    xcb_flush(FConnection);
  end;
end;

procedure TFtX11Window.GetPosition(out OutX, OutY: Integer);
var
  cookie: xcb_translate_coordinates_cookie_t;
  reply: Pxcb_translate_coordinates_reply_t;
begin
  OutX := X;
  OutY := Y;
  if (FWindow <> 0) and Assigned(FConnection) and Assigned(GScreen) then
  begin
    cookie := xcb_translate_coordinates(FConnection, FWindow, GScreen^.root, 0, 0);
    reply := xcb_translate_coordinates_reply(FConnection, cookie, nil);
    if Assigned(reply) then
    begin
      OutX := reply^.dst_x;
      OutY := reply^.dst_y;
      c_free(reply);
    end;
  end;
end;

function TFtX11Window.ClientToScreen(AX, AY: Integer): TPoint;
var
  cookie: xcb_translate_coordinates_cookie_t;
  reply: Pxcb_translate_coordinates_reply_t;
begin
  Result.X := AX;
  Result.Y := AY;
  if (FWindow <> 0) and Assigned(FConnection) and Assigned(GScreen) then
  begin
    cookie := xcb_translate_coordinates(FConnection, FWindow, GScreen^.root, SmallInt(AX), SmallInt(AY));
    reply := xcb_translate_coordinates_reply(FConnection, cookie, nil);
    if Assigned(reply) then
    begin
      Result.X := reply^.dst_x;
      Result.Y := reply^.dst_y;
      c_free(reply);
    end;
  end;
end;

function TFtX11Window.ScreenToClient(AX, AY: Integer): TPoint;
var
  cookie: xcb_translate_coordinates_cookie_t;
  reply: Pxcb_translate_coordinates_reply_t;
begin
  Result.X := AX;
  Result.Y := AY;
  if (FWindow <> 0) and Assigned(FConnection) and Assigned(GScreen) then
  begin
    cookie := xcb_translate_coordinates(FConnection, GScreen^.root, FWindow, SmallInt(AX), SmallInt(AY));
    reply := xcb_translate_coordinates_reply(FConnection, cookie, nil);
    if Assigned(reply) then
    begin
      Result.X := reply^.dst_x;
      Result.Y := reply^.dst_y;
      c_free(reply);
    end;
  end;
end;

destructor TFtX11Window.Destroy();
begin
  if Assigned(FScratchBuffer) then
  begin
    FreeMem(FScratchBuffer);
    FScratchBuffer := nil;
    FScratchBufferSize := 0;
  end;

  if (FGC <> 0) and Assigned(FConnection) then
  begin
    xcb_free_gc(FConnection, FGC);
    FGC := 0;
  end;
  if (FColormap <> 0) and (FDepth = 32) and Assigned(FConnection) then
  begin
    xcb_free_colormap(FConnection, FColormap);
    FColormap := 0;
  end;
  if (FWindow <> 0) and Assigned(FConnection) then
  begin
    xcb_destroy_window(FConnection, FWindow);
    FWindow := 0;
  end;
  inherited Destroy();
end;

procedure TFtX11Window.Resize(NewW, NewH: Integer; AApplyToBackend: Boolean = True);
var
  values: array[0..1] of Cardinal;
begin
  if (NewW <= 0) or (NewH <= 0) or ((NewW = Width) and (NewH = Height)) then Exit;

  inherited Resize(NewW, NewH, AApplyToBackend);

  FHasPendingResize := False;
  FLastResizeTime := GetTickCount64();

  if AApplyToBackend and (FWindow <> 0) and Assigned(FConnection) then
  begin
    values[0] := Cardinal(Width);
    values[1] := Cardinal(Height);
    xcb_configure_window(FConnection, FWindow, XCB_CONFIG_WINDOW_WIDTH or XCB_CONFIG_WINDOW_HEIGHT, @values[0]);
    if FBackgroundBlur then
      UpdateBlurBehindRegion();
    xcb_flush(FConnection);
  end;

  FFullRepaint := True;
  Repaint();
  FLastResizeRenderTime := GetTickCount64();
end;

procedure TFtX11Window.Show();
begin
  inherited Show();
  if (FWindow <> 0) and Assigned(FConnection) then
  begin
    xcb_map_window(FConnection, FWindow);
    FNeedsRepaint := True;
    xcb_flush(FConnection);
  end;
end;

procedure TFtX11Window.Hide();
begin
  if Assigned(GHintTargetWidget) and (GHintTargetWidget.GetRootWidget() = Self) then
  begin
    FtHideHint();
    GHintTargetWidget := nil;
    GHintHoverStartMs := 0;
  end;
  inherited Hide();
  if (FWindow <> 0) and Assigned(FConnection) then
  begin
    xcb_unmap_window(FConnection, FWindow);
    xcb_flush(FConnection);
  end;
end;

procedure TFtX11Window.Repaint();
var
  isPartial: Boolean;
  dirtyX, dirtyY, dirtyW, dirtyH: Integer;
begin
  if (Width <= 0) or (Height <= 0) or (FWindow = 0) or not Assigned(FCanvas) or not Assigned(FConnection) then Exit;

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

  inherited Repaint();

  if isPartial then
  begin
    if (dirtyW > 0) and (dirtyH > 0) then
      FtXcbPutImage(FConnection, FWindow, FGC, FDepth, FPixelBuffer, Width, Height,
                    dirtyX, dirtyY, dirtyW, dirtyH, FScratchBuffer, FScratchBufferSize);
  end
  else
  begin
    FtXcbPutImage(FConnection, FWindow, FGC, FDepth, FPixelBuffer, Width, Height,
                  0, 0, Width, Height, FScratchBuffer, FScratchBufferSize);
  end;
  xcb_flush(FConnection);
end;

procedure TFtX11Window.ClearActivePopup();
begin
  inherited ClearActivePopup();
  if Assigned(FMainMenu) then
    TFtMainMenu(FMainMenu).CloseMenu();
end;

procedure TFtX11Window.ClaimPrimarySelection(const AText: string);
begin
  if (FWindow <> 0) and Assigned(FConnection) then
  begin
    xcb_set_selection_owner(FConnection, FWindow, 1 {XA_PRIMARY}, XCB_CURRENT_TIME);
    xcb_flush(FConnection);
  end;
end;

procedure TFtX11Window.ClearPrimarySelection();
var
  cookie: xcb_get_selection_owner_cookie_t;
  reply: Pxcb_get_selection_owner_reply_t;
  isOwner: Boolean;
begin
  if (FWindow <> 0) and Assigned(FConnection) then
  begin
    cookie := xcb_get_selection_owner(FConnection, 1);
    reply := xcb_get_selection_owner_reply(FConnection, cookie, nil);
    if Assigned(reply) then
    begin
      isOwner := (reply^.owner = FWindow);
      c_free(reply);
      if isOwner then
      begin
        xcb_set_selection_owner(FConnection, 0, 1, XCB_CURRENT_TIME);
        xcb_flush(FConnection);
      end;
    end;
  end;
end;

procedure FtSetSelectionLostHandler(AHandler: TFtSelectionLostHandler);
begin
  Ft.Window.FtSetSelectionLostHandler(AHandler);
end;

procedure FtClaimPrimarySelection(const AText: string);
begin
  Ft.Window.FtClaimPrimarySelection(AText);
end;

procedure FtClearPrimarySelection();
begin
  Ft.Window.FtClearPrimarySelection();
end;

procedure FtSetClipboardText(const AText: string);
begin
  Ft.Window.FtSetClipboardText(AText);
end;

function GetSelectionRequestorWindow(): TFtX11Window;
var
  i: Integer;
  w: TFtWindow;
begin
  if Assigned(GActiveWindow) and (TObject(GActiveWindow) is TFtX11Window) and
     (GActiveWindow.WindowType = ftwtNormal) and (TFtX11Window(GActiveWindow).FWindow <> 0) then
    Exit(TFtX11Window(GActiveWindow));
  if Assigned(GWindows) then
  begin
    for i := 0 to GWindows.Count - 1 do
    begin
      w := TFtWindow(GWindows[i]);
      if Assigned(w) and (TObject(w) is TFtX11Window) and (w.WindowType = ftwtNormal) and (TFtX11Window(w).FWindow <> 0) then
        Exit(TFtX11Window(w));
    end;
    for i := 0 to GWindows.Count - 1 do
    begin
      w := TFtWindow(GWindows[i]);
      if Assigned(w) and (TObject(w) is TFtX11Window) and (TFtX11Window(w).FWindow <> 0) then
        Exit(TFtX11Window(w));
    end;
  end;
  if Assigned(GActiveWindow) and (TObject(GActiveWindow) is TFtX11Window) then
    Exit(TFtX11Window(GActiveWindow));
  Result := nil;
end;

function FtFetchSelectionFromXCB(ASelectionAtom: xcb_atom_t): string;
var
  win: TFtX11Window;
  conn: Pxcb_connection_t;
  ownerCookie: xcb_get_selection_owner_cookie_t;
  ownerReply: Pxcb_get_selection_owner_reply_t;
  ownerWin: xcb_window_t;
  targetAtom: xcb_atom_t;
  attempt: Integer;
  startTime: QWord;
  ev: Pxcb_generic_event_t;
  evType: Byte;
  selNotify: Pxcb_selection_notify_event_t;
  propCookie: xcb_get_property_cookie_t;
  propReply: Pxcb_get_property_reply_t;
  propLen: Cardinal;
  propData: Pointer;
begin
  Result := '';
  win := GetSelectionRequestorWindow();
  if not Assigned(win) or not Assigned(win.FConnection) or (win.FWindow = 0) then
    Exit;

  conn := win.FConnection;
  ownerCookie := xcb_get_selection_owner(conn, ASelectionAtom);
  ownerReply := xcb_get_selection_owner_reply(conn, ownerCookie, nil);
  if not Assigned(ownerReply) then Exit;
  ownerWin := ownerReply^.owner;
  c_free(ownerReply);

  if ownerWin = 0 then Exit;

  if ownerWin = win.FWindow then
  begin
    if ASelectionAtom = 1 then
      Exit(gPrimarySelectionText)
    else
      Exit(gClipboardText);
  end;

  if Assigned(GWindows) then
  begin
    for attempt := 0 to GWindows.Count - 1 do
    begin
      if (TObject(GWindows[attempt]) is TFtX11Window) and
         (TFtX11Window(GWindows[attempt]).FWindow = ownerWin) then
      begin
        if ASelectionAtom = 1 then
          Exit(gPrimarySelectionText)
        else
          Exit(gClipboardText);
      end;
    end;
  end;

  for attempt := 1 to 2 do
  begin
    if attempt = 1 then
      targetAtom := atomUTF8String
    else
      targetAtom := XCB_ATOM_STRING;

    xcb_delete_property(conn, win.FWindow, atomFtSelection);
    xcb_convert_selection(conn, win.FWindow, ASelectionAtom, targetAtom, atomFtSelection, XCB_CURRENT_TIME);
    xcb_flush(conn);

    startTime := GetTickCount64();
    while (GetTickCount64() - startTime < 300) do
    begin
      ev := xcb_poll_for_event(conn);
      if Assigned(ev) then
      begin
        evType := ev^.response_type and $7F;
        if evType = XCB_SELECTION_NOTIFY then
        begin
          selNotify := Pxcb_selection_notify_event_t(ev);
          if selNotify^.property_ <> 0 then
          begin
            propCookie := xcb_get_property(conn, 1, win.FWindow, selNotify^.property_, XCB_GET_PROPERTY_TYPE_ANY, 0, 1024 * 1024);
            propReply := xcb_get_property_reply(conn, propCookie, nil);
            if Assigned(propReply) then
            begin
              propLen := xcb_get_property_value_length(propReply);
              propData := xcb_get_property_value(propReply);
              if propLen > 0 then
              begin
                SetLength(Result, propLen);
                Move(propData^, Result[1], propLen);
              end;
              c_free(propReply);
            end;
          end;
          c_free(ev);
          if Result <> '' then Exit;
          Break;
        end
        else
        begin
          win.HandleGenericEvent(ev);
          c_free(ev);
        end;
      end
      else
        Sleep(2);
    end;
  end;
end;

function FetchClipboardFromXCB(): string;
var
  win: TFtX11Window;
  conn: Pxcb_connection_t;
  cookie: xcb_get_selection_owner_cookie_t;
  reply: Pxcb_get_selection_owner_reply_t;
  owner: xcb_window_t;
  fetched: string;
begin
  win := GetSelectionRequestorWindow();
  if Assigned(win) and Assigned(win.FConnection) and (win.FWindow <> 0) then
  begin
    conn := win.FConnection;
    cookie := xcb_get_selection_owner(conn, atomClipboard);
    reply := xcb_get_selection_owner_reply(conn, cookie, nil);
    if Assigned(reply) then
    begin
      owner := reply^.owner;
      c_free(reply);

      if owner <> 0 then
      begin
        if owner = win.FWindow then
          Exit(gClipboardText);

        fetched := FtFetchSelectionFromXCB(atomClipboard);
        if fetched <> '' then
        begin
          gClipboardText := fetched;
          Exit(fetched);
        end;
      end
      else
      begin
        cookie := xcb_get_selection_owner(conn, 1);
        reply := xcb_get_selection_owner_reply(conn, cookie, nil);
        if Assigned(reply) then
        begin
          owner := reply^.owner;
          c_free(reply);
          if (owner <> 0) and (owner <> win.FWindow) then
          begin
            fetched := FtFetchSelectionFromXCB(1);
            if fetched <> '' then
            begin
              gClipboardText := fetched;
              Exit(fetched);
            end;
          end;
        end;
      end;
    end;
  end;

  Result := gClipboardText;
end;

function FtGetClipboardText(): string;
begin
  Result := Ft.Window.FtGetClipboardText();
end;

procedure TFtX11Window.UpdateCursor();
var
  target: TFtWidget;
  valList: xcb_change_window_attributes_value_list_t;
  targetCursor: xcb_cursor_t;
  cType: Integer;
begin
  if (FWindow = 0) or (FConnection = nil) then Exit;

  if Assigned(FPressedWidget) then
    target := FPressedWidget
  else
    target := FHoverWidget;

  targetCursor := 0;
  if Assigned(target) then
  begin
    cType := target.GetCursor();
    case cType of
      FT_CURSOR_IBEAM:  targetCursor := GCursorIBeam;
      FT_CURSOR_SIZE_H: targetCursor := GCursorSizeH;
      FT_CURSOR_SIZE_V: targetCursor := GCursorSizeV;
      FT_CURSOR_HAND:   targetCursor := GCursorHand;
    else
      targetCursor := 0;
    end;
  end;

  if targetCursor = FCurrentCursor then Exit;
  FCurrentCursor := targetCursor;

  FillChar(valList, SizeOf(valList), 0);
  valList.cursor := targetCursor;
  xcb_change_window_attributes_aux(FConnection, FWindow, XCB_CW_CURSOR, @valList);
  xcb_flush(FConnection);
end;

procedure TFtX11Window.ClaimClipboard();
begin
  if Assigned(FConnection) and (FWindow <> 0) and (atomClipboard <> 0) then
  begin
    xcb_set_selection_owner(FConnection, FWindow, atomClipboard, XCB_CURRENT_TIME);
    xcb_flush(FConnection);
  end;
end;

function TFtX11Window.FetchClipboardText(): string;
begin
  Result := FetchClipboardFromXCB();
end;

function TFtX11Window.FetchPrimarySelectionText(): string;
begin
  Result := FtFetchSelectionFromXCB(1);
end;

procedure TFtX11Window.GrabInput();
begin
  FtGrabMenuInput(Self);
end;

procedure TFtX11Window.UngrabInput();
begin
  FtUngrabMenuInput(Self);
end;

function TFtX11Window.GetNativeHandle(): Pointer;
begin
  Result := Pointer(PtrUInt(FWindow));
end;

procedure TFtX11Window.WidgetDestroyed(AWidget: TFtWidget);
begin
  if GHintTargetWidget = AWidget then
  begin
    FtHideHint();
    GHintTargetWidget := nil;
    GHintHoverStartMs := 0;
  end;
  inherited WidgetDestroyed(AWidget);
  UpdateCursor();
end;

procedure TFtX11Window.HandleEvents();
begin
  FtBackendProcessEvents();
end;

function KeySymToUtf8(sym: Cardinal): string;
var
  wc: WideString;
begin
  if (sym >= 32) and (sym <= 126) then
    Result := Chr(sym)
  else if (sym >= 160) and (sym <= $10FFFF) then
  begin
    if (sym >= $01000100) and (sym <= $0110FFFF) then
      sym := sym - $01000000;
    if sym <= $FFFF then
      Result := UTF8Encode(WideChar(sym))
    else
    begin
      SetLength(wc, 2);
      wc[1] := WideChar($D800 + ((sym - $10000) shr 10));
      wc[2] := WideChar($DC00 + ((sym - $10000) and $3FF));
      Result := UTF8Encode(wc);
    end;
  end
  else
    Result := '';
end;

procedure TFtX11Window.HandleGenericEvent(Event: Pxcb_generic_event_t);
var
  evType: Byte;
  Target: TFtWidget;
  focusTarget: TFtWidget;
  ctxWidget: TFtWidget;
  keysym: Cardinal;
  col: Integer;
  strUtf8: string;
  navPop: TFtPopupMenu;
  clickedIdx: Integer;
  wasSameItem: Boolean;

  ep: Pxcb_expose_event_t;
  cp: Pxcb_configure_notify_event_t;
  mp: Pxcb_motion_notify_event_t;
  bp: Pxcb_button_press_event_t;
  kp: Pxcb_key_press_event_t;
  kr: Pxcb_key_release_event_t;
  req: Pxcb_selection_request_event_t;
  resp: xcb_selection_notify_event_t;
  targets: array[0..2] of xcb_atom_t;
  sendText: string;
  sc: Pxcb_selection_clear_event_t;
  cm: Pxcb_client_message_event_t;
begin
  if Event = nil then Exit;
  evType := Event^.response_type and $7F;

  case evType of
    XCB_EXPOSE:
    begin
      ep := Pxcb_expose_event_t(Event);
      InvalidateRect(ep^.x, ep^.y, ep^.width, ep^.height);
    end;

    XCB_CONFIGURE_NOTIFY:
    begin
      cp := Pxcb_configure_notify_event_t(Event);
      FPendingResizeW := cp^.width;
      FPendingResizeH := cp^.height;
      FHasPendingResize := True;
      X := cp^.x;
      Y := cp^.y;
      FLastConfigureTime := GetTickCount64();
    end;

    XCB_MOTION_NOTIFY:
    begin
      mp := Pxcb_motion_notify_event_t(Event);
      GCurrentKeyboardModifiers := mp^.state;
      if FWindowType in [ftwtPopupMenu, ftwtDropdownMenu] then
      begin
        if (Children.Count > 0) and (TFtWidget(Children[0]) is TFtPopupMenu) then
          TFtPopupMenu(Children[0]).MouseMove(mp^.event_x, mp^.event_y);
      end
      else if Assigned(GGrabbedPopup) and Assigned(FMainMenu) and
              (TFtMainMenu(FMainMenu).ActiveIndex >= 0) and
              (FMainMenu.HitTest(mp^.event_x, mp^.event_y) <> nil) then
      begin
        FMainMenu.MouseMove(mp^.event_x, mp^.event_y);
      end
      else if Assigned(FPressedWidget) then
      begin
        FPressedWidget.MouseMove(mp^.event_x, mp^.event_y);
        UpdateCursor();
      end
      else
      begin
        Target := HitTest(mp^.event_x, mp^.event_y);
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
        begin
          Target.MouseMove(mp^.event_x, mp^.event_y);
          UpdateCursor();
        end;
        HandleHintMotion(Self, Target, mp^.root_x, mp^.root_y);
      end;
    end;

    XCB_LEAVE_NOTIFY:
    begin
      FtHideHint();
      GHintTargetWidget := nil;
      GHintHoverStartMs := 0;
      if Assigned(FHoverWidget) then
      begin
        FHoverWidget.MouseLeave();
        FHoverWidget := nil;
        UpdateCursor();
      end;
    end;

    XCB_BUTTON_PRESS:
    begin
      FtHideHint();
      GHintHoverStartMs := 0;
      bp := Pxcb_button_press_event_t(Event);
      GCurrentKeyboardModifiers := bp^.state;
      if FWindowType in [ftwtPopupMenu, ftwtDropdownMenu] then
      begin
        if (bp^.event_x < 0) or (bp^.event_x >= Width) or
           (bp^.event_y < 0) or (bp^.event_y >= Height) then
        begin
          if Assigned(GGrabbedPopup) then
            TFtPopupMenu(GGrabbedPopup).DismissAll();
        end
        else
        begin
          if (Children.Count > 0) and (TFtWidget(Children[0]) is TFtPopupMenu) then
          begin
            FPressedWidget := TFtPopupMenu(Children[0]);
            TFtPopupMenu(Children[0]).MouseDown(bp^.event_x, bp^.event_y, bp^.detail);
          end;
        end;
      end
      else if Assigned(GGrabbedPopup) then
      begin
        if Assigned(FMainMenu) and (FMainMenu.HitTest(bp^.event_x, bp^.event_y) <> nil) then
        begin
          clickedIdx := TFtMainMenu(FMainMenu).ItemAt(bp^.event_x, bp^.event_y);
          wasSameItem := (TFtMainMenu(FMainMenu).ActiveIndex >= 0) and (clickedIdx = TFtMainMenu(FMainMenu).ActiveIndex);

          TFtPopupMenu(GGrabbedPopup).DismissAll();

          if (bp^.detail = 1) and (clickedIdx >= 0) and not wasSameItem then
          begin
            FPressedWidget := FMainMenu;
            FMainMenu.MouseDown(bp^.event_x, bp^.event_y, bp^.detail);
          end;
        end
        else
        begin
          TFtPopupMenu(GGrabbedPopup).DismissAll();
          if bp^.detail = 3 then
          begin
            Target := HitTest(bp^.event_x, bp^.event_y);
            if Target = Self then
              Target := nil;
            focusTarget := FindFocusableWidget(Target);
            if Assigned(focusTarget) then
              SetFocusedWidget(focusTarget);
            if Assigned(Target) then
              Target.MouseDown(bp^.event_x, bp^.event_y, bp^.detail);

            ctxWidget := Target;
            while Assigned(ctxWidget) and (ctxWidget.ContextMenu = nil) do
              ctxWidget := ctxWidget.Parent;

            if Assigned(ctxWidget) and Assigned(ctxWidget.ContextMenu) then
              TFtPopupMenu(ctxWidget.ContextMenu).Popup(bp^.root_x, bp^.root_y)
            else if Assigned(FContextMenu) then
              TFtPopupMenu(FContextMenu).Popup(bp^.root_x, bp^.root_y);
          end;
        end;
      end
      else if bp^.detail = 3 then
      begin
        Target := HitTest(bp^.event_x, bp^.event_y);
        if Target = Self then
          Target := nil;
        focusTarget := FindFocusableWidget(Target);
        if Assigned(focusTarget) then
          SetFocusedWidget(focusTarget);
        if Assigned(Target) then
          Target.MouseDown(bp^.event_x, bp^.event_y, bp^.detail);

        ctxWidget := Target;
        while Assigned(ctxWidget) and (ctxWidget.ContextMenu = nil) do
          ctxWidget := ctxWidget.Parent;

        if Assigned(ctxWidget) and Assigned(ctxWidget.ContextMenu) then
          TFtPopupMenu(ctxWidget.ContextMenu).Popup(bp^.root_x, bp^.root_y)
        else if Assigned(FContextMenu) then
          TFtPopupMenu(FContextMenu).Popup(bp^.root_x, bp^.root_y);
      end
      else
      begin
        Target := HitTest(bp^.event_x, bp^.event_y);
        if Target = Self then
          Target := nil;
        if not (bp^.detail in [4, 5, 6, 7]) then
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
          Target.MouseDown(bp^.event_x, bp^.event_y, bp^.detail);
      end;
    end;

    XCB_BUTTON_RELEASE:
    begin
      bp := Pxcb_button_release_event_t(Event);
      GCurrentKeyboardModifiers := bp^.state;
      if FWindowType in [ftwtPopupMenu, ftwtDropdownMenu] then
      begin
        if (Children.Count > 0) and (TFtWidget(Children[0]) is TFtPopupMenu) then
        begin
          TFtPopupMenu(Children[0]).MouseUp(bp^.event_x, bp^.event_y, bp^.detail);
          TFtPopupMenu(Children[0]).Click();
        end;
        FPressedWidget := nil;
        UpdateCursor();
      end
      else
      begin
        Target := HitTest(bp^.event_x, bp^.event_y);
        if Target = Self then
          Target := nil;
        if Assigned(FPressedWidget) then
        begin
          FPressedWidget.MouseUp(bp^.event_x, bp^.event_y, bp^.detail);
          if Target = FPressedWidget then
            FPressedWidget.Click();
          FPressedWidget := nil;
          UpdateCursor();
        end;
      end;
    end;

    XCB_KEY_PRESS:
    begin
      FtHideHint();
      GHintHoverStartMs := 0;
      kp := Pxcb_key_press_event_t(Event);
      GCurrentKeyboardModifiers := kp^.state;
      col := 0;
      if (kp^.state and 1) <> 0 then col := 1;
      keysym := xcb_key_press_lookup_keysym(GKeySymbols, kp, col);
      strUtf8 := KeySymToUtf8(keysym);

      if Assigned(GGrabbedPopup) and TFtPopupMenu(GGrabbedPopup).IsOpen then
      begin
        navPop := TFtPopupMenu(GGrabbedPopup);
        while Assigned(navPop.ActiveSubMenu) and navPop.ActiveSubMenu.IsOpen do
          navPop := navPop.ActiveSubMenu;

        case keysym of
          XK_Escape:
            TFtPopupMenu(GGrabbedPopup).DismissAll();
          XK_Down:
            navPop.SelectNext();
          XK_Up:
            navPop.SelectPrev();
          XK_Right:
          begin
            if (navPop.HoverIndex >= 0) and (navPop.HoverIndex < navPop.Items.Count) and
               TFtMenuItem(navPop.Items[navPop.HoverIndex]).HasSubMenu() then
              navPop.ActivateSelected();
          end;
          XK_Left:
          begin
            if Assigned(navPop.ParentPopupMenu) then
            begin
              navPop.Close();
              if Assigned(navPop.ParentPopupMenu) then
                navPop.ParentPopupMenu.Invalidate();
            end;
          end;
          XK_Return, XK_KP_Enter:
          begin
            navPop.ActivateSelected();
          end;
        end;
      end
      else if (keysym = XK_Tab) or (keysym = XK_ISO_Left_Tab) then
      begin
        FocusNext((keysym = XK_ISO_Left_Tab) or ((kp^.state and 1) <> 0));
      end
      else if Assigned(FFocusedWidget) then
        FFocusedWidget.KeyDown(keysym, kp^.state, strUtf8);
    end;

    XCB_KEY_RELEASE:
    begin
      kr := Pxcb_key_release_event_t(Event);
      GCurrentKeyboardModifiers := kr^.state;
      col := 0;
      if (kr^.state and 1) <> 0 then col := 1;
      keysym := xcb_key_release_lookup_keysym(GKeySymbols, kr, col);
      if Assigned(FFocusedWidget) then
        FFocusedWidget.KeyUp(keysym, kr^.state);
    end;

    XCB_SELECTION_REQUEST:
    begin
      req := Pxcb_selection_request_event_t(Event);
      FillChar(resp, SizeOf(resp), 0);
      resp.response_type := XCB_SELECTION_NOTIFY;
      resp.time := req^.time;
      resp.requestor := req^.requestor;
      resp.selection := req^.selection;
      resp.target := req^.target;
      resp.property_ := 0;

      if (req^.target = atomTargets) and (atomTargets <> 0) then
      begin
        targets[0] := atomTargets;
        targets[1] := atomUTF8String;
        targets[2] := XCB_ATOM_STRING;
        xcb_change_property(FConnection, XCB_PROP_MODE_REPLACE, req^.requestor,
                            req^.property_, XCB_ATOM_ATOM, 32, 3, @targets[0]);
        resp.property_ := req^.property_;
      end
      else if (req^.target = atomUTF8String) or (req^.target = XCB_ATOM_STRING) then
      begin
        if req^.selection = 1 then
          sendText := gPrimarySelectionText
        else
          sendText := gClipboardText;

        if Length(sendText) > 0 then
          xcb_change_property(FConnection, XCB_PROP_MODE_REPLACE, req^.requestor,
                              req^.property_, req^.target, 8, Length(sendText), PChar(sendText))
        else
          xcb_change_property(FConnection, XCB_PROP_MODE_REPLACE, req^.requestor,
                              req^.property_, req^.target, 8, 0, nil);
        resp.property_ := req^.property_;
      end;

      xcb_send_event(FConnection, 0, req^.requestor, 0, PChar(@resp));
      xcb_flush(FConnection);
    end;

    XCB_SELECTION_CLEAR:
    begin
      sc := Pxcb_selection_clear_event_t(Event);
      if sc^.selection = 1 then
      begin
        gPrimarySelectionText := '';
        if Assigned(gOnPrimarySelectionLost) then
          gOnPrimarySelectionLost();
      end
      else if (atomClipboard <> 0) and (sc^.selection = atomClipboard) then
      begin
        gClipboardText := '';
      end;
    end;

    XCB_CLIENT_MESSAGE:
    begin
      cm := Pxcb_client_message_event_t(Event);
      if (cm^.format = 32) and (PCardinal(@cm^.data.raw[0])^ = atomWMDeleteWindow) then
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

    XCB_DESTROY_NOTIFY:
    begin
      if FWindowType in [ftwtNormal, ftwtDialog] then
      begin
        if not HasMainWindows() then
          GRunning := False;
      end;
    end;
  end;
end;

{ TFtHintWindow }

constructor TFtHintWindow.Create(AParent: TFtWidget);
var
  popWin: TFtWindow;
  prevActive: TFtWindow;
begin
  inherited Create(AParent);
  FText := '';
  FLines := TStringList.Create();
  FPopupWindow := nil;
  Visible := False;

  if Assigned(GConnection) then
  begin
    prevActive := GActiveWindow;
    popWin := FtCreateWindow(100, 30, '', ftwtTooltip);
    GActiveWindow := prevActive;
    popWin.Borderless := True;
    popWin.SkipTaskbar := True;
    popWin.Visible := False;
    FPopupWindow := popWin;
    Self.X := 0;
    Self.Y := 0;
    Self.Parent := popWin;
    popWin.Children.Add(Self);
  end;
end;

destructor TFtHintWindow.Destroy();
begin
  FLines.Free();
  if Assigned(FPopupWindow) then
  begin
    FPopupWindow.Children.Remove(Self);
    Self.Parent := nil;
    FPopupWindow.Free();
    FPopupWindow := nil;
  end;
  inherited Destroy();
end;

procedure TFtHintWindow.SetHintText(const AText: string);
var
  fnt: TFtFont;
  i: Integer;
  lineW, maxW, lineH, totalH: Double;
  padX, padY: Double;
  newW, newH: Integer;
begin
  FText := AText;
  FLines.Clear();
  if AText = '' then Exit;
  FLines.Text := AText;
  if FLines.Count = 0 then
    FLines.Add(AText);

  fnt := FtGetSystemFont();
  lineH := 16.0;
  if Assigned(fnt) then
    lineH := fnt.Height;
  if lineH < 14.0 then lineH := 14.0;

  maxW := 0.0;
  for i := 0 to FLines.Count - 1 do
  begin
    if Assigned(fnt) then
      lineW := fnt.GetTextWidth(FLines[i])
    else
      lineW := Length(FLines[i]) * 8.0;
    if lineW > maxW then
      maxW := lineW;
  end;

  padX := 8.0;
  padY := 5.0;
  totalH := FLines.Count * (lineH + 2.0) - 2.0;

  newW := Math.Max(24, Math.Ceil(maxW + padX * 2.0));
  newH := Math.Max(18, Math.Ceil(totalH + padY * 2.0));

  Self.Width := newW;
  Self.Height := newH;
  if Assigned(FPopupWindow) then
    FPopupWindow.Resize(newW, newH);
end;

procedure TFtHintWindow.ShowAt(AScreenX, AScreenY: Integer);
var
  screenW, screenH: Integer;
  posX, posY: Integer;
begin
  if not Assigned(FPopupWindow) or (FText = '') then Exit;

  screenW := FPopupWindow.ScreenWidth;
  screenH := FPopupWindow.ScreenHeight;

  posX := AScreenX + 12;
  posY := AScreenY + 20;

  if posX + Width > screenW - 6 then
    posX := screenW - Width - 6;
  if posX < 6 then
    posX := 6;

  if posY + Height > screenH - 6 then
    posY := AScreenY - Height - 6;
  if posY < 6 then
    posY := 6;

  FPopupWindow.SetPosition(posX, posY);
  FPopupWindow.Show();
  Self.Visible := True;
  FPopupWindow.Repaint();
end;

procedure TFtHintWindow.Hide();
begin
  Self.Visible := False;
  if Assigned(FPopupWindow) then
    FPopupWindow.Hide();
end;

procedure TFtHintWindow.Draw(Canvas: TFtCanvasAgg);
var
  fnt: TFtFont;
  i: Integer;
  curY, lineH, padX, padY: Double;
  bgR, bgG, bgB, bgA: Double;
  bdR, bdG, bdB, bdA: Double;
  txR, txG, txB: Double;
  rad: Double;
begin
  if not Visible or (FText = '') then Exit;

  rad := 5.0;
  padX := 8.0;
  padY := 5.0;

  if FtGetDarkMode() then
  begin
    bgR := 0.16; bgG := 0.18; bgB := 0.22; bgA := 0.96;
    bdR := 0.32; bdG := 0.36; bdB := 0.42; bdA := 0.90;
    txR := 0.96; txG := 0.97; txB := 0.98;
  end
  else
  begin
    bgR := 0.18; bgG := 0.20; bgB := 0.24; bgA := 0.94;
    bdR := 0.28; bdG := 0.30; bdB := 0.35; bdA := 0.80;
    txR := 1.0;  txG := 1.0;  txB := 1.0;
  end;

  Canvas.DrawShadow(X, Y, Width, Height, rad, 0.0, 2.0, 4.0, 0.0, 0.0, 0.0, 0.25);
  Canvas.DrawRoundedRect(X, Y, Width, Height, rad, bgR, bgG, bgB, bgA);
  Canvas.DrawRoundedRectOutline(X, Y, Width, Height, rad, 1.0, bdR, bdG, bdB, bdA);

  fnt := FtGetSystemFont();
  lineH := 16.0;
  if Assigned(fnt) then
    lineH := fnt.Height;
  if lineH < 14.0 then lineH := 14.0;

  curY := Y + padY;
  if Assigned(fnt) then
    curY := curY + fnt.Ascent
  else
    curY := curY + 12.0;

  for i := 0 to FLines.Count - 1 do
  begin
    if Assigned(fnt) then
      Canvas.DrawText(X + padX, curY, FLines[i], fnt, txR, txG, txB)
    else
      Canvas.DrawTextLeft(X + padX, curY - 12.0, Width - padX * 2.0, lineH, FLines[i], nil, txR, txG, txB);
    curY := curY + lineH + 2.0;
  end;
end;

procedure FtShowHint(AWidget: TFtWidget; const AHintText: string; AScreenX, AScreenY: Integer);
begin
  if AHintText = '' then
  begin
    FtHideHint();
    Exit;
  end;
  if not Assigned(GHintWindow) then
    GHintWindow := TFtHintWindow.Create(nil);
  GHintWindow.SetHintText(AHintText);
  GHintWindow.ShowAt(AScreenX, AScreenY);
  GHintVisible := True;
end;

procedure FtHideHint();
begin
  if GHintVisible then
  begin
    if Assigned(GHintWindow) then
      GHintWindow.Hide();
    GHintVisible := False;
  end;
  GHintHoverStartMs := 0;
end;

function FtIsHintVisible(): Boolean;
begin
  Result := GHintVisible;
end;

procedure FtSetHintDelay(ADelayMs: Integer);
begin
  GHintDelayMs := Math.Max(50, ADelayMs);
end;

function FtGetHintDelay(): Integer;
begin
  Result := GHintDelayMs;
end;

initialization
  FtRegisterWindowClass(TFtX11Window);

finalization
  if Assigned(GHintWindow) then
    FreeAndNil(GHintWindow);

end.
