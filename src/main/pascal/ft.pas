library ft;

{$mode objfpc}{$H+}

uses
  ctypes, SysUtils,
  Ft.Backend.X11,
  Ft.Font,
  Ft.Widget,
  Ft.Widget.Buttons,
  Ft.Widget.Switches,
  Ft.Widget.Texts,
  Ft.Theme;

var
  gLastSystemFontDesc: AnsiString;
  gLastWidgetFontDesc: AnsiString;
  gLastThemeName: AnsiString;
  gLastAvailableThemes: AnsiString;
  gLastSwitchCaption: AnsiString;
  gLastTextValue: AnsiString;
  gLastSelectedText: AnsiString;
  gLastClipboardText: AnsiString;

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

procedure ft_button_set_corner_radius(button: Pointer; radius: Double); cdecl; export;
begin
  if Assigned(button) and (TObject(button) is TFtButton) then
    TFtButton(button).CornerRadius := radius;
end;

function ft_button_get_corner_radius(button: Pointer): Double; cdecl; export;
begin
  if Assigned(button) and (TObject(button) is TFtButton) then
    Result := TFtButton(button).CornerRadius
  else
    Result := -1.0;
end;

procedure ft_button_set_shadow(button: Pointer; enabled: cint32); cdecl; export;
begin
  if Assigned(button) and (TObject(button) is TFtButton) then
    TFtButton(button).EnableShadow := enabled;
end;

function ft_button_get_shadow(button: Pointer): cint32; cdecl; export;
begin
  if Assigned(button) and (TObject(button) is TFtButton) then
    Result := TFtButton(button).EnableShadow
  else
    Result := -1;
end;

function ft_switch_create(parent: Pointer; x, y, w, h: cint32; caption: PChar): Pointer; cdecl; export;
var
  Sw: TFtSwitch;
begin
  Sw := TFtSwitch.Create(TFtWidget(parent));
  Sw.X := x;
  Sw.Y := y;
  Sw.Width := w;
  Sw.Height := h;
  if Assigned(caption) then
    Sw.Caption := StrPas(caption)
  else
    Sw.Caption := '';
  Result := Pointer(Sw);
end;

procedure ft_switch_set_checked(switch_widget: Pointer; checked: cint32); cdecl; export;
begin
  if Assigned(switch_widget) and (TObject(switch_widget) is TFtSwitch) then
    TFtSwitch(switch_widget).Checked := (checked <> 0);
end;

function ft_switch_get_checked(switch_widget: Pointer): cint32; cdecl; export;
begin
  if Assigned(switch_widget) and (TObject(switch_widget) is TFtSwitch) and TFtSwitch(switch_widget).Checked then
    Result := 1
  else
    Result := 0;
end;

procedure ft_switch_toggle(switch_widget: Pointer); cdecl; export;
begin
  if Assigned(switch_widget) and (TObject(switch_widget) is TFtSwitch) then
    TFtSwitch(switch_widget).Toggle();
end;

procedure ft_switch_set_toggled(switch_widget: Pointer; toggled: cint32); cdecl; export;
begin
  ft_switch_set_checked(switch_widget, toggled);
end;

function ft_switch_get_toggled(switch_widget: Pointer): cint32; cdecl; export;
begin
  Result := ft_switch_get_checked(switch_widget);
end;

function ft_switch_get_state(switch_widget: Pointer): cint32; cdecl; export;
begin
  if Assigned(switch_widget) and (TObject(switch_widget) is TFtSwitch) then
    Result := Ord(TFtSwitch(switch_widget).State)
  else
    Result := 0;
end;

procedure ft_switch_on_toggle(switch_widget: Pointer; callback: TFtSwitchCallback; user_data: Pointer); cdecl; export;
begin
  if Assigned(switch_widget) and (TObject(switch_widget) is TFtSwitch) then
  begin
    TFtSwitch(switch_widget).OnToggle := callback;
    TFtSwitch(switch_widget).UserData := user_data;
  end;
end;

procedure ft_switch_on_change(switch_widget: Pointer; callback: TFtSwitchCallback; user_data: Pointer); cdecl; export;
begin
  ft_switch_on_toggle(switch_widget, callback, user_data);
end;

procedure ft_switch_on_hover(switch_widget: Pointer; callback: TFtSwitchHoverCallback; user_data: Pointer); cdecl; export;
begin
  if Assigned(switch_widget) and (TObject(switch_widget) is TFtSwitch) then
  begin
    TFtSwitch(switch_widget).OnHover := callback;
    TFtSwitch(switch_widget).UserData := user_data;
  end;
end;

procedure ft_switch_set_corner_radius(switch_widget: Pointer; radius: Double); cdecl; export;
begin
  if Assigned(switch_widget) and (TObject(switch_widget) is TFtSwitch) then
    TFtSwitch(switch_widget).CornerRadius := radius;
end;

function ft_switch_get_corner_radius(switch_widget: Pointer): Double; cdecl; export;
begin
  if Assigned(switch_widget) and (TObject(switch_widget) is TFtSwitch) then
    Result := TFtSwitch(switch_widget).CornerRadius
  else
    Result := -1.0;
end;

procedure ft_switch_set_shadow(switch_widget: Pointer; enabled: cint32); cdecl; export;
begin
  if Assigned(switch_widget) and (TObject(switch_widget) is TFtSwitch) then
    TFtSwitch(switch_widget).EnableShadow := enabled;
end;

function ft_switch_get_shadow(switch_widget: Pointer): cint32; cdecl; export;
begin
  if Assigned(switch_widget) and (TObject(switch_widget) is TFtSwitch) then
    Result := TFtSwitch(switch_widget).EnableShadow
  else
    Result := -1;
end;

procedure ft_switch_set_caption(switch_widget: Pointer; caption: PChar); cdecl; export;
begin
  if Assigned(switch_widget) and (TObject(switch_widget) is TFtSwitch) then
  begin
    if Assigned(caption) then
      TFtSwitch(switch_widget).Caption := StrPas(caption)
    else
      TFtSwitch(switch_widget).Caption := '';
    TFtSwitch(switch_widget).Invalidate();
  end;
end;

function ft_switch_get_caption(switch_widget: Pointer): PChar; cdecl; export;
begin
  if Assigned(switch_widget) and (TObject(switch_widget) is TFtSwitch) then
  begin
    gLastSwitchCaption := TFtSwitch(switch_widget).Caption;
    Result := PChar(gLastSwitchCaption);
  end
  else
    Result := nil;
end;

function ft_text_create(parent: Pointer; x, y, w, h: cint32; text: PChar): Pointer; cdecl; export;
var
  strText: string;
begin
  if Assigned(text) then
    strText := StrPas(text)
  else
    strText := '';
  Result := Pointer(TFtText.Create(TFtWidget(parent), strText));
  TFtWidget(Result).X := x;
  TFtWidget(Result).Y := y;
  TFtWidget(Result).Width := w;
  TFtWidget(Result).Height := h;
end;

procedure ft_text_set_text(text_widget: Pointer; text: PChar); cdecl; export;
begin
  if Assigned(text_widget) and (TObject(text_widget) is TFtText) then
  begin
    if Assigned(text) then
      TFtText(text_widget).Text := StrPas(text)
    else
      TFtText(text_widget).Text := '';
  end;
end;

function ft_text_get_text(text_widget: Pointer): PChar; cdecl; export;
begin
  if Assigned(text_widget) and (TObject(text_widget) is TFtText) then
  begin
    gLastTextValue := TFtText(text_widget).Text;
    Result := PChar(gLastTextValue);
  end
  else
    Result := nil;
end;

procedure ft_text_set_selectable(text_widget: Pointer; selectable: cint32); cdecl; export;
begin
  if Assigned(text_widget) and (TObject(text_widget) is TFtText) then
    TFtText(text_widget).Selectable := (selectable <> 0);
end;

function ft_text_get_selectable(text_widget: Pointer): cint32; cdecl; export;
begin
  if Assigned(text_widget) and (TObject(text_widget) is TFtText) and TFtText(text_widget).Selectable then
    Result := 1
  else
    Result := 0;
end;

function ft_text_get_selected_text(text_widget: Pointer): PChar; cdecl; export;
begin
  if Assigned(text_widget) and (TObject(text_widget) is TFtText) then
  begin
    gLastSelectedText := TFtText(text_widget).SelectedText;
    Result := PChar(gLastSelectedText);
  end
  else
    Result := nil;
end;

procedure ft_text_select_all(text_widget: Pointer); cdecl; export;
begin
  if Assigned(text_widget) and (TObject(text_widget) is TFtText) then
    TFtText(text_widget).SelectAll();
end;

procedure ft_text_clear_selection(text_widget: Pointer); cdecl; export;
begin
  if Assigned(text_widget) and (TObject(text_widget) is TFtText) then
    TFtText(text_widget).ClearSelection();
end;

procedure ft_text_copy(text_widget: Pointer); cdecl; export;
begin
  if Assigned(text_widget) and (TObject(text_widget) is TFtText) then
    TFtText(text_widget).CopyToClipboard();
end;

procedure ft_text_set_alignment(text_widget: Pointer; alignment: cint32); cdecl; export;
begin
  if Assigned(text_widget) and (TObject(text_widget) is TFtText) then
  begin
    case alignment of
      1: TFtText(text_widget).Alignment := taCenter;
      2: TFtText(text_widget).Alignment := taRight;
      else TFtText(text_widget).Alignment := taLeft;
    end;
  end;
end;

function ft_text_get_alignment(text_widget: Pointer): cint32; cdecl; export;
begin
  if Assigned(text_widget) and (TObject(text_widget) is TFtText) then
  begin
    case TFtText(text_widget).Alignment of
      taCenter: Result := 1;
      taRight:  Result := 2;
      else      Result := 0;
    end;
  end
  else
    Result := 0;
end;

procedure ft_text_set_color(text_widget: Pointer; r, g, b: Double); cdecl; export;
begin
  if Assigned(text_widget) and (TObject(text_widget) is TFtText) then
    TFtText(text_widget).SetColor(r, g, b);
end;

procedure ft_text_reset_color(text_widget: Pointer); cdecl; export;
begin
  if Assigned(text_widget) and (TObject(text_widget) is TFtText) then
    TFtText(text_widget).ResetColor();
end;

procedure ft_clipboard_set_text(text: PChar); cdecl; export;
begin
  if Assigned(text) then
    FtSetClipboardText(StrPas(text))
  else
    FtSetClipboardText('');
end;

function ft_clipboard_get_text(): PChar; cdecl; export;
begin
  gLastClipboardText := FtGetClipboardText();
  Result := PChar(gLastClipboardText);
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

function ft_theme_set(theme_name: PChar): cint32; cdecl; export;
begin
  if Assigned(theme_name) and FtSetTheme(StrPas(theme_name)) then
    Result := 1
  else
    Result := 0;
end;

function ft_theme_get(): PChar; cdecl; export;
begin
  gLastThemeName := FtGetThemeName();
  Result := PChar(gLastThemeName);
end;

function ft_theme_get_available(): PChar; cdecl; export;
begin
  gLastAvailableThemes := FtGetAvailableThemes();
  Result := PChar(gLastAvailableThemes);
end;

function ft_theme_load_file(filepath: PChar): cint32; cdecl; export;
begin
  if Assigned(filepath) and FtThemeLoadFile(StrPas(filepath)) then
    Result := 1
  else
    Result := 0;
end;

function ft_theme_load_dir(dirpath: PChar): cint32; cdecl; export;
begin
  if Assigned(dirpath) then
    Result := FtThemeLoadDir(StrPas(dirpath))
  else
    Result := 0;
end;

procedure ft_theme_set_dark_mode(enabled: cint32); cdecl; export;
begin
  FtSetDarkMode(enabled <> 0);
end;

function ft_theme_get_dark_mode(): cint32; cdecl; export;
begin
  if FtGetDarkMode() then
    Result := 1
  else
    Result := 0;
end;

function ft_theme_has_dark_mode(theme_name: PChar): cint32; cdecl; export;
begin
  if Assigned(theme_name) and FtThemeHasDarkMode(StrPas(theme_name)) then
    Result := 1
  else
    Result := 0;
end;

procedure ft_theme_set_corner_radius(radius: Double); cdecl; export;
begin
  FtSetCornerRadius(radius);
end;

function ft_theme_get_corner_radius(): Double; cdecl; export;
begin
  Result := FtGetCornerRadius();
end;

procedure ft_theme_set_shadow(enabled: cint32); cdecl; export;
begin
  FtSetEnableShadow(enabled <> 0);
end;

function ft_theme_get_shadow(): cint32; cdecl; export;
begin
  if FtGetEnableShadow() then
    Result := 1
  else
    Result := 0;
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
  ft_button_set_corner_radius,
  ft_button_get_corner_radius,
  ft_button_set_shadow,
  ft_button_get_shadow,
  ft_switch_create,
  ft_switch_set_checked,
  ft_switch_get_checked,
  ft_switch_toggle,
  ft_switch_set_toggled,
  ft_switch_get_toggled,
  ft_switch_get_state,
  ft_switch_on_toggle,
  ft_switch_on_change,
  ft_switch_on_hover,
  ft_switch_set_corner_radius,
  ft_switch_get_corner_radius,
  ft_switch_set_shadow,
  ft_switch_get_shadow,
  ft_switch_set_caption,
  ft_switch_get_caption,
  ft_system_font_get,
  ft_system_font_set,
  ft_widget_set_font,
  ft_widget_get_font,
  ft_screen_dpi_get,
  ft_screen_dpi_set,
  ft_font_gamma_get,
  ft_font_gamma_set,
  ft_theme_set,
  ft_theme_get,
  ft_theme_get_available,
  ft_theme_load_file,
  ft_theme_load_dir,
  ft_theme_set_dark_mode,
  ft_theme_get_dark_mode,
  ft_theme_has_dark_mode,
  ft_theme_set_corner_radius,
  ft_theme_get_corner_radius,
  ft_theme_set_shadow,
  ft_theme_get_shadow,
  ft_text_create,
  ft_text_set_text,
  ft_text_get_text,
  ft_text_set_selectable,
  ft_text_get_selectable,
  ft_text_get_selected_text,
  ft_text_select_all,
  ft_text_clear_selection,
  ft_text_copy,
  ft_text_set_alignment,
  ft_text_get_alignment,
  ft_text_set_color,
  ft_text_reset_color,
  ft_clipboard_set_text,
  ft_clipboard_get_text;

begin
end.
