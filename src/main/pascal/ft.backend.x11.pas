unit Ft.Backend.X11;

{$mode objfpc}{$H+}

interface

uses
  ctypes, x, xlib, xutil, SysUtils, Classes, Ft.Canvas.Agg, Ft.Widget, Ft.Theme;

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
    FNeedsRepaint: Boolean;
    procedure OnThemeChanged();
    procedure UpdateCursor();
  public
    constructor Create(W, H: Integer; Title: string); reintroduce;
    destructor Destroy(); override;
    procedure Resize(NewW, NewH: Integer);
    procedure SetTitle(const ATitle: string);
    procedure Repaint();
    procedure HandleEvents();
    procedure Show();
    procedure Invalidate(); override;
    procedure WidgetDestroyed(AWidget: TFtWidget); override;
    procedure RequestFocus(AWidget: TFtWidget); override;
    procedure SetFocusedWidget(AWidget: TFtWidget);
    procedure FocusNext(ABackward: Boolean = False);
    procedure ClaimClipboard();
    property FocusedWidget: TFtWidget read FFocusedWidget;
  end;

type
  TFtSelectionLostHandler = procedure();

var
  GDisplay: PDisplay = nil;
  GRunning: Boolean = False;
  GActiveWindow: TFtX11Window = nil;

procedure FtBackendInit();
procedure FtBackendMainLoop();
procedure FtBackendQuit();
procedure FtSetClipboardText(const AText: string);
function FtGetClipboardText(): string;
procedure FtClaimPrimarySelection(const AText: string);
procedure FtClearPrimarySelection();
procedure FtSetSelectionLostHandler(AHandler: TFtSelectionLostHandler);

implementation

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

procedure FtBackendMainLoop();
begin
  while GRunning and Assigned(GActiveWindow) do
  begin
    GActiveWindow.HandleEvents();
    if Assigned(GDisplay) and (XPending(GDisplay) = 0) then
      Sleep(10);
  end;
  if Assigned(GDisplay) then
  begin
    XCloseDisplay(GDisplay);
    GDisplay := nil;
  end;
end;

constructor TFtX11Window.Create(W, H: Integer; Title: string);
var
  ScreenNum: cint;
  Visual: PVisual;
  winAttr: TXSetWindowAttributes;
begin
  inherited Create(nil);
  X := 0;
  Y := 0;
  Width := W;
  Height := H;
  FDisplay := GDisplay;

  ScreenNum := DefaultScreen(FDisplay);
  Visual := DefaultVisual(FDisplay, ScreenNum);

  FWindow := XCreateSimpleWindow(FDisplay, RootWindow(FDisplay, ScreenNum),
    100, 100, Width, Height, 0,
    BlackPixel(FDisplay, ScreenNum),
    BlackPixel(FDisplay, ScreenNum));

  // Disable X server background clearing and retain bit gravity during resize to eliminate flicker
  FillChar(winAttr, SizeOf(winAttr), 0);
  winAttr.background_pixmap := None;
  winAttr.bit_gravity := NorthWestGravity;
  XChangeWindowAttributes(FDisplay, FWindow, CWBackPixmap or CWBitGravity, @winAttr);

  SetTitle(Title);
  FHoverWidget := nil;
  FPressedWidget := nil;
  FFocusedWidget := nil;
  FCursorIBeam := None;
  FNeedsRepaint := False;
  XSelectInput(FDisplay, FWindow, ExposureMask or ButtonPressMask or ButtonReleaseMask or PointerMotionMask or LeaveWindowMask or StructureNotifyMask or KeyPressMask or KeyReleaseMask);

  FWMDeleteWindow := XInternAtom(FDisplay, 'WM_DELETE_WINDOW', False);
  FAtomClipboard := XInternAtom(FDisplay, 'CLIPBOARD', False);
  FAtomUTF8String := XInternAtom(FDisplay, 'UTF8_STRING', False);
  FAtomTargets := XInternAtom(FDisplay, 'TARGETS', False);
  XSetWMProtocols(FDisplay, FWindow, @FWMDeleteWindow, 1);

  FGC := XCreateGC(FDisplay, FWindow, 0, nil);

  GetMem(FPixelBuffer, Width * Height * 4);
  FXImage := XCreateImage(FDisplay, Visual, 24, ZPixmap, 0, PChar(FPixelBuffer), Width, Height, 32, 0);

  FCanvas := TFtCanvasAgg.Create(FPixelBuffer, Width, Height);
  GActiveWindow := Self;
  FtThemeManager().OnThemeChange := @Self.OnThemeChanged;
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

destructor TFtX11Window.Destroy();
begin
  if Assigned(FtThemeManager().OnThemeChange) then
    FtThemeManager().OnThemeChange := nil;
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
  XDestroyWindow(FDisplay, FWindow);
  inherited Destroy();
end;

procedure TFtX11Window.Resize(NewW, NewH: Integer);
var
  Visual: PVisual;
  ScreenNum: cint;
begin
  if (NewW <= 0) or (NewH <= 0) or ((NewW = Width) and (NewH = Height)) then Exit;

  Width := NewW;
  Height := NewH;

  if Assigned(FXImage) then
  begin
    FXImage^.data := nil;
    XDestroyImage(FXImage);
    FXImage := nil;
  end;

  if Assigned(FPixelBuffer) then
    FreeMem(FPixelBuffer);

  GetMem(FPixelBuffer, Width * Height * 4);
  ScreenNum := DefaultScreen(FDisplay);
  Visual := DefaultVisual(FDisplay, ScreenNum);
  FXImage := XCreateImage(FDisplay, Visual, 24, ZPixmap, 0, PChar(FPixelBuffer), Width, Height, 32, 0);

  if Assigned(FCanvas) then
    FCanvas.Resize(FPixelBuffer, Width, Height)
  else
    FCanvas := TFtCanvasAgg.Create(FPixelBuffer, Width, Height);

  Repaint();
end;

procedure TFtX11Window.Show();
begin
  XMapWindow(FDisplay, FWindow);
  Repaint();
  XFlush(FDisplay);
end;

procedure TFtX11Window.Repaint();
begin
  FtGetTheme().DrawWindowBackground(FCanvas, Width, Height);
  Self.Draw(FCanvas);
  XPutImage(FDisplay, FWindow, FGC, FXImage, 0, 0, 0, 0, Width, Height);
  XFlush(FDisplay);
end;

procedure TFtX11Window.OnThemeChanged();
begin
  Invalidate();
end;

procedure TFtX11Window.Invalidate();
begin
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

function FtGetClipboardText(): string;
begin
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

procedure TFtX11Window.HandleEvents();
var
  Event: TXEvent;
  Target: TFtWidget;
  needsResize: Boolean;
  newW, newH: Integer;
  keysym: TKeySym;
  strBuf: array[0..31] of AnsiChar;
  charCount: Integer;
  composeStatus: TXComposeStatus;
  req: TXSelectionRequestEvent;
  resp: TXSelectionEvent;
  targets: array[0..2] of TAtom;
  atomString: TAtom;
  sendText: string;
begin
  needsResize := False;
  newW := Width;
  newH := Height;

  while (XPending(FDisplay) > 0) do
  begin
    XNextEvent(FDisplay, @Event);
    case Event._type of
      Expose:
      begin
        FNeedsRepaint := True;
      end;
      ConfigureNotify:
      begin
        if (Event.xconfigure.width <> newW) or (Event.xconfigure.height <> newH) then
        begin
          newW := Event.xconfigure.width;
          newH := Event.xconfigure.height;
          needsResize := True;
        end;
      end;
      MotionNotify:
      begin
        if Assigned(FPressedWidget) then
          FPressedWidget.MouseMove(Event.xmotion.x, Event.xmotion.y)
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
        Target := HitTest(Event.xbutton.x, Event.xbutton.y);
        if Target = Self then
          Target := nil;
        if Target = nil then
        begin
          if Assigned(gOnPrimarySelectionLost) then
            gOnPrimarySelectionLost();
          FtClearPrimarySelection();
          SetFocusedWidget(nil);
        end
        else
        begin
          if Target.CanFocus() then
            SetFocusedWidget(Target)
          else
            SetFocusedWidget(nil);
        end;
        FPressedWidget := Target;
        UpdateCursor();
        if Assigned(Target) then
          Target.MouseDown(Event.xbutton.x, Event.xbutton.y, Event.xbutton.button);
      end;
      ButtonRelease:
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
      2: // KeyPress
      begin
        keysym := 0;
        charCount := XLookupString(@Event.xkey, strBuf, SizeOf(strBuf) - 1, @keysym, @composeStatus);
        if charCount > 0 then
          strBuf[charCount] := #0
        else
          strBuf[0] := #0;

        // Tab ($FF09) or ISO_Left_Tab ($FE20). ShiftMask = 1
        if (keysym = $FF09) or (keysym = $FE20) then
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
          // If our window is currently the owner of XA_PRIMARY, this is a stale SelectionClear
          // from a rapid ownership change within our window. Only clear if we don't own it!
          if XGetSelectionOwner(FDisplay, 1) <> FWindow then
          begin
            gPrimarySelectionText := '';
            if Assigned(gOnPrimarySelectionLost) then
              gOnPrimarySelectionLost();
          end;
        end;
      end;
      ClientMessage:
      begin
        if (Event.xclient.format = 32) and
           (TAtom(Event.xclient.data.l[0]) = FWMDeleteWindow) then
          GRunning := False;
      end;
      DestroyNotify:
        GRunning := False;
    end;
  end;

  if needsResize and ((newW <> Width) or (newH <> Height)) then
    Resize(newW, newH)
  else if FNeedsRepaint then
  begin
    FNeedsRepaint := False;
    Repaint();
  end;
end;

end.