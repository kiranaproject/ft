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

implementation

end.
