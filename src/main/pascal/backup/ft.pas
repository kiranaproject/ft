library ft;

{$mode objfpc}{$H+}

uses
  ctypes, SysUtils,
  Ft.Backend.X11,
  Ft.Canvas.Agg,
  Ft.Widget;

procedure ft_init; cdecl; export;
begin
  FtBackendInit;
end;

procedure ft_main_loop; cdecl; export;
begin
  FtBackendMainLoop;
end;

procedure ft_quit; cdecl; export;
begin
  FtBackendQuit;
end;

function ft_window_create(width, height: cint32; title: PChar): Pointer; cdecl; export;
begin
  Result := Pointer(TFtX11Window.Create(width, height, StrPas(title)));
end;

procedure ft_widget_show(widget: Pointer); cdecl; export;
begin
  if Assigned(widget) and (TObject(widget) is TFtX11Window) then
    TFtX11Window(widget).Show;
end;

function ft_button_create(parent: Pointer; x, y, w, h: cint32; caption: PChar): Pointer; cdecl; export;
var
  Btn: TFtButton;
begin
  Btn := TFtButton.Create(TFtWidget(parent));
  Btn.X := x;
  Btn.Y := y;
  Btn.Width := w;
  Btn.Height := h;
  Btn.Caption := StrPas(caption);
  Result := Pointer(Btn);
end;

procedure ft_button_on_click(button: Pointer; callback: TFtClickCallback; user_data: Pointer); cdecl; export;
begin
  if Assigned(button) and (TObject(button) is TFtButton) then
  begin
    TFtButton(button).OnClick := callback;
    TFtButton(button).UserData := user_data;
  end;
end;

exports
  ft_init,
  ft_main_loop,
  ft_quit,
  ft_window_create,
  ft_widget_show,
  ft_button_create,
  ft_button_on_click;
end.