unit Ft.Backend.X11;

{$mode objfpc}{$H+}

interface

uses
  ctypes, x, xlib, xutil, SysUtils, Ft.Canvas.Agg, Ft.Widget;

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
    FHoverWidget: TFtWidget;
    FPressedWidget: TFtWidget;
    FNeedsRepaint: Boolean;
  public
    constructor Create(W, H: Integer; Title: string); reintroduce;
    destructor Destroy; override;
    procedure Resize(NewW, NewH: Integer);
    procedure SetTitle(const ATitle: string);
    procedure Repaint;
    procedure HandleEvents;
    procedure Show;
    procedure Invalidate; override;
    procedure WidgetDestroyed(AWidget: TFtWidget); override;
  end;

var
  GDisplay: PDisplay = nil;
  GRunning: Boolean = False;
  GActiveWindow: TFtX11Window = nil;

procedure FtBackendInit;
procedure FtBackendMainLoop;
procedure FtBackendQuit;

implementation

procedure FtBackendInit;
begin
  XInitThreads();
  GDisplay := XOpenDisplay(nil);
  if GDisplay = nil then
    raise Exception.Create('Floria Toolkit: Unable to connect to X11 display.');
  GRunning := True;
end;

procedure FtBackendQuit;
begin
  GRunning := False;
end;

procedure FtBackendMainLoop;
begin
  while GRunning and Assigned(GActiveWindow) do
  begin
    GActiveWindow.HandleEvents;
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
  FNeedsRepaint := False;
  XSelectInput(FDisplay, FWindow, ExposureMask or ButtonPressMask or ButtonReleaseMask or PointerMotionMask or LeaveWindowMask or StructureNotifyMask);

  FWMDeleteWindow := XInternAtom(FDisplay, 'WM_DELETE_WINDOW', False);
  XSetWMProtocols(FDisplay, FWindow, @FWMDeleteWindow, 1);

  FGC := XCreateGC(FDisplay, FWindow, 0, nil);

  GetMem(FPixelBuffer, Width * Height * 4);
  FXImage := XCreateImage(FDisplay, Visual, 24, ZPixmap, 0, PChar(FPixelBuffer), Width, Height, 32, 0);

  FCanvas := TFtCanvasAgg.Create(FPixelBuffer, Width, Height);
  GActiveWindow := Self;
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

destructor TFtX11Window.Destroy;
begin
  FHoverWidget := nil;
  FPressedWidget := nil;
  FCanvas.Free;
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
  inherited Destroy;
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

  Repaint;
end;

procedure TFtX11Window.Show;
begin
  XMapWindow(FDisplay, FWindow);
  Repaint;
  XFlush(FDisplay);
end;

procedure TFtX11Window.Repaint;
begin
  FCanvas.Clear(0.92, 0.93, 0.94);
  Self.Draw(FCanvas);
  XPutImage(FDisplay, FWindow, FGC, FXImage, 0, 0, 0, 0, Width, Height);
  XFlush(FDisplay);
end;

procedure TFtX11Window.Invalidate;
begin
  FNeedsRepaint := True;
end;

procedure TFtX11Window.WidgetDestroyed(AWidget: TFtWidget);
begin
  if FHoverWidget = AWidget then
    FHoverWidget := nil;
  if FPressedWidget = AWidget then
    FPressedWidget := nil;
  inherited WidgetDestroyed(AWidget);
end;

procedure TFtX11Window.HandleEvents;
var
  Event: TXEvent;
  Target: TFtWidget;
  needsResize: Boolean;
  newW, newH: Integer;
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
        Target := HitTest(Event.xmotion.x, Event.xmotion.y);
        if Target = Self then
          Target := nil;

        if Target <> FHoverWidget then
        begin
          if Assigned(FHoverWidget) then
            FHoverWidget.MouseLeave;
          FHoverWidget := Target;
          if Assigned(FHoverWidget) then
            FHoverWidget.MouseEnter;
        end;
        if Assigned(Target) then
          Target.MouseMove(Event.xmotion.x, Event.xmotion.y);
      end;
      LeaveNotify:
      begin
        if Assigned(FHoverWidget) then
        begin
          FHoverWidget.MouseLeave;
          FHoverWidget := nil;
        end;
      end;
      ButtonPress:
      begin
        Target := HitTest(Event.xbutton.x, Event.xbutton.y);
        if Target = Self then
          Target := nil;
        FPressedWidget := Target;
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
            FPressedWidget.Click;
          FPressedWidget := nil;
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
    Repaint;
  end;
end;

end.