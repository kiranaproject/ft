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

procedure FtRegisterEventFilter(AFilter: TFtEventFilterFunc);

implementation

procedure FtRegisterEventFilter(AFilter: TFtEventFilterFunc);
begin
  Ft.Backend.X11.FtRegisterEventFilter(AFilter);
end;

end.
