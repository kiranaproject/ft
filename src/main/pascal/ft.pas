library ft;

{$mode objfpc}{$H+}

uses
  ctypes, SysUtils,
  Ft.Backend.X11,
  Ft.Font,
  Ft.Widget,
  Ft.Buttons;

var
  gLastSystemFontDesc: AnsiString;
  gLastWidgetFontDesc: AnsiString;

procedure ft_init(); cdecl; export;
begin
  FtBackendInit();
end;

procedure ft_main_loop(); cdecl; export;
begin
  FtBackendMainLoop();
end;

procedure ft_quit(); cdecl; export;
begin
  FtBackendQuit();
end;

function ft_window_create(width, height: cint32; title: PChar): Pointer; cdecl; export;
begin
  Result := Pointer(TFtX11Window.Create(width, height, StrPas(title)));
end;

procedure ft_widget_show(widget: Pointer); cdecl; export;
begin
  if Assigned(widget) and (TObject(widget) is TFtX11Window) then
    TFtX11Window(widget).Show();
end;

procedure ft_window_set_title(window: Pointer; title: PChar); cdecl; export;
begin
  if Assigned(window) and (TObject(window) is TFtX11Window) then
    TFtX11Window(window).SetTitle(StrPas(title));
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

function ft_toggle_button_create(parent: Pointer; x, y, w, h: cint32; caption: PChar): Pointer; cdecl; export;
var
  Btn: TFtToggleButton;
begin
  Btn := TFtToggleButton.Create(TFtWidget(parent));
  Btn.X := x;
  Btn.Y := y;
  Btn.Width := w;
  Btn.Height := h;
  Btn.Caption := StrPas(caption);
  Result := Pointer(Btn);
end;

procedure ft_button_set_toggle(button: Pointer; can_toggle: cint32); cdecl; export;
begin
  if Assigned(button) and (TObject(button) is TFtButton) then
    TFtButton(button).CanToggle := (can_toggle <> 0);
end;

function ft_button_get_toggle(button: Pointer): cint32; cdecl; export;
begin
  if Assigned(button) and (TObject(button) is TFtButton) and TFtButton(button).CanToggle then
    Result := 1
  else
    Result := 0;
end;

procedure ft_button_set_toggled(button: Pointer; toggled: cint32); cdecl; export;
begin
  if Assigned(button) and (TObject(button) is TFtButton) then
    TFtButton(button).Toggled := (toggled <> 0);
end;

function ft_button_get_toggled(button: Pointer): cint32; cdecl; export;
begin
  if Assigned(button) and (TObject(button) is TFtButton) and TFtButton(button).Toggled then
    Result := 1
  else
    Result := 0;
end;

function ft_button_get_state(button: Pointer): cint32; cdecl; export;
begin
  if Assigned(button) and (TObject(button) is TFtButton) then
    Result := Ord(TFtButton(button).State)
  else
    Result := 0;
end;

procedure ft_button_on_hover(button: Pointer; callback: TFtHoverCallback; user_data: Pointer); cdecl; export;
begin
  if Assigned(button) and (TObject(button) is TFtButton) then
  begin
    TFtButton(button).OnHover := callback;
    TFtButton(button).UserData := user_data;
  end;
end;

procedure ft_button_on_press(button: Pointer; callback: TFtPressCallback; user_data: Pointer); cdecl; export;
begin
  if Assigned(button) and (TObject(button) is TFtButton) then
  begin
    TFtButton(button).OnPress := callback;
    TFtButton(button).UserData := user_data;
  end;
end;

procedure ft_button_on_toggle(button: Pointer; callback: TFtToggleCallback; user_data: Pointer); cdecl; export;
begin
  if Assigned(button) and (TObject(button) is TFtButton) then
  begin
    TFtButton(button).OnToggle := callback;
    TFtButton(button).UserData := user_data;
  end;
end;

function ft_system_font_get(): PChar; cdecl; export;
begin
  gLastSystemFontDesc := FtGetSystemFont().FontDesc;
  Result := PChar(gLastSystemFontDesc);
end;

procedure ft_system_font_set(desc: PChar); cdecl; export;
begin
  if Assigned(desc) then
    FtFontManager().DefaultFontDesc := StrPas(desc);
end;

procedure ft_widget_set_font(widget: Pointer; font_desc: PChar); cdecl; export;
begin
  if Assigned(widget) and (TObject(widget) is TFtWidget) then
  begin
    if Assigned(font_desc) then
      TFtWidget(widget).FontDesc := StrPas(font_desc)
    else
      TFtWidget(widget).FontDesc := '';
  end;
end;

function ft_widget_get_font(widget: Pointer): PChar; cdecl; export;
begin
  if Assigned(widget) and (TObject(widget) is TFtWidget) then
  begin
    gLastWidgetFontDesc := TFtWidget(widget).FontDesc;
    Result := PChar(gLastWidgetFontDesc);
  end
  else
    Result := nil;
end;

function ft_screen_dpi_get(): Double; cdecl; export;
begin
  Result := FtGetScreenDPI();
end;

procedure ft_screen_dpi_set(dpi: Double); cdecl; export;
begin
  FtSetScreenDPI(dpi);
end;

function ft_font_gamma_get(): Double; cdecl; export;
begin
  Result := FtGetFontGamma();
end;

procedure ft_font_gamma_set(gamma: Double); cdecl; export;
begin
  FtSetFontGamma(gamma);
end;

exports
  ft_init,
  ft_main_loop,
  ft_quit,
  ft_window_create,
  ft_window_set_title,
  ft_widget_show,
  ft_button_create,
  ft_toggle_button_create,
  ft_button_on_click,
  ft_button_set_toggle,
  ft_button_get_toggle,
  ft_button_set_toggled,
  ft_button_get_toggled,
  ft_button_get_state,
  ft_button_on_hover,
  ft_button_on_press,
  ft_button_on_toggle,
  ft_system_font_get,
  ft_system_font_set,
  ft_widget_set_font,
  ft_widget_get_font,
  ft_screen_dpi_get,
  ft_screen_dpi_set,
  ft_font_gamma_get,
  ft_font_gamma_set;

begin
end.
