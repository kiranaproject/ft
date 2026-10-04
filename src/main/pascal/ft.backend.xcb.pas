unit Ft.Backend.XCB;

{$mode objfpc}{$H+}

interface

uses
  Ft.Window, Ft.Backend.X11;

type
  TFtXCBWindow = Ft.Backend.X11.TFtX11Window;
  TFtX11Window = Ft.Backend.X11.TFtX11Window;
  TFtWindow = Ft.Window.TFtWindow;
  TFtWindowType = Ft.Window.TFtWindowType;
  TFtSelectionLostHandler = Ft.Window.TFtSelectionLostHandler;
  TFtEventFilterFunc = Ft.Backend.X11.TFtEventFilterFunc;
  TFtTickCallback = Ft.Backend.X11.TFtTickCallback;

procedure FtRegisterEventFilter(AFilter: TFtEventFilterFunc);
procedure FtSetTickCallback(ACallback: TFtTickCallback; AUserData: Pointer);

implementation

procedure FtRegisterEventFilter(AFilter: TFtEventFilterFunc);
begin
  Ft.Backend.X11.FtRegisterEventFilter(AFilter);
end;

procedure FtSetTickCallback(ACallback: TFtTickCallback; AUserData: Pointer);
begin
  Ft.Backend.X11.FtSetTickCallback(ACallback, AUserData);
end;

end.
