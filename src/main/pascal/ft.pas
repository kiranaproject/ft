library ft;

{$mode objfpc}{$H+}

uses
  ctypes, SysUtils, Types,
  Ft.Backend.X11,
  Ft.Font,
  Ft.Widget,
  Ft.Widget.Buttons,
  Ft.Widget.Switches,
  Ft.Widget.Texts,
  Ft.Widget.Entries,
  Ft.Widget.TextAreas,
  Ft.Widget.ScrollBars,
  Ft.Widget.Containers,
  Ft.Widget.Menus,
  Ft.Widget.Selectors,
  Ft.Widget.Meters,
  Ft.Theme,
  Ft.Css,
  Ft.Animation,
  Ft.Canvas.Agg,
  Ft.Bitmap,
  Ft.Widget.Images;

var
  gLastSystemFontDesc: AnsiString;
  gLastWidgetFontDesc: AnsiString;
  gLastThemeName: AnsiString;
  gLastAvailableThemes: AnsiString;
  gLastSwitchCaption: AnsiString;
  gLastTextValue: AnsiString;
  gLastSelectedText: AnsiString;
  gLastClipboardText: AnsiString;
  gLastEntryText: AnsiString;
  gLastEntryPlaceholder: AnsiString;
  gLastTextAreaText: AnsiString;
  gLastTextAreaPlaceholder: AnsiString;
  gLastMenuCaption: AnsiString;
  gLastMenuShortcut: AnsiString;
  gLastCheckBoxCaption: AnsiString;
  gLastRadioCaption: AnsiString;
  gLastComboItem: AnsiString;
  gLastComboText: AnsiString;
  gLastComboPlaceholder: AnsiString;
  gLastProgressFormat: AnsiString;
  gLastStyleClass: AnsiString;
  gLastStyleId: AnsiString;
  gLastInlineStyle: AnsiString;

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
  if Assigned(widget) then
  begin
    if TObject(widget) is TFtX11Window then
      TFtX11Window(widget).Show()
    else if TObject(widget) is TFtWidget then
    begin
      TFtWidget(widget).Visible := True;
      TFtWidget(widget).Invalidate();
    end;
  end;
end;

procedure ft_widget_hide(widget: Pointer); cdecl; export;
begin
  if Assigned(widget) then
  begin
    if TObject(widget) is TFtX11Window then
      TFtX11Window(widget).Hide()
    else if TObject(widget) is TFtWidget then
    begin
      TFtWidget(widget).Visible := False;
      TFtWidget(widget).Invalidate();
    end;
  end;
end;

procedure ft_window_set_title(window: Pointer; title: PChar); cdecl; export;
begin
  if Assigned(window) and (TObject(window) is TFtX11Window) then
    TFtX11Window(window).SetTitle(StrPas(title));
end;

procedure ft_window_set_borderless(window: Pointer; borderless: cint32); cdecl; export;
begin
  if Assigned(window) and (TObject(window) is TFtX11Window) then
    TFtX11Window(window).SetBorderless(borderless <> 0);
end;

function ft_window_get_borderless(window: Pointer): cint32; cdecl; export;
begin
  if Assigned(window) and (TObject(window) is TFtX11Window) and TFtX11Window(window).Borderless then
    Result := 1
  else
    Result := 0;
end;

procedure ft_window_set_skip_taskbar(window: Pointer; skip_taskbar: cint32); cdecl; export;
begin
  if Assigned(window) and (TObject(window) is TFtX11Window) then
    TFtX11Window(window).SetSkipTaskbar(skip_taskbar <> 0);
end;

function ft_window_get_skip_taskbar(window: Pointer): cint32; cdecl; export;
begin
  if Assigned(window) and (TObject(window) is TFtX11Window) and TFtX11Window(window).SkipTaskbar then
    Result := 1
  else
    Result := 0;
end;

procedure ft_window_set_window_type(window: Pointer; window_type: cint32); cdecl; export;
begin
  if Assigned(window) and (TObject(window) is TFtX11Window) then
  begin
    if (window_type >= Ord(Low(TFtWindowType))) and (window_type <= Ord(High(TFtWindowType))) then
      TFtX11Window(window).SetWindowType(TFtWindowType(window_type));
  end;
end;

function ft_window_get_window_type(window: Pointer): cint32; cdecl; export;
begin
  if Assigned(window) and (TObject(window) is TFtX11Window) then
    Result := Ord(TFtX11Window(window).WindowType)
  else
    Result := Ord(ftwtNormal);
end;

procedure ft_window_set_position(window: Pointer; x, y: cint32); cdecl; export;
begin
  if Assigned(window) and (TObject(window) is TFtX11Window) then
    TFtX11Window(window).SetPosition(x, y);
end;

procedure ft_window_get_position(window: Pointer; out_x, out_y: pcint32); cdecl; export;
var
  wx, wy: Integer;
begin
  wx := 0;
  wy := 0;
  if Assigned(window) and (TObject(window) is TFtX11Window) then
    TFtX11Window(window).GetPosition(wx, wy);
  if Assigned(out_x) then
    out_x^ := wx;
  if Assigned(out_y) then
    out_y^ := wy;
end;

procedure ft_window_set_opacity(window: Pointer; opacity: cdouble); cdecl; export;
begin
  if Assigned(window) and (TObject(window) is TFtX11Window) then
    TFtX11Window(window).SetWindowOpacity(opacity);
end;

function ft_window_get_opacity(window: Pointer): cdouble; cdecl; export;
begin
  if Assigned(window) and (TObject(window) is TFtX11Window) then
    Result := TFtX11Window(window).GetWindowOpacity()
  else
    Result := 1.0;
end;

procedure ft_window_set_background_opacity(window: Pointer; opacity: cdouble); cdecl; export;
begin
  if Assigned(window) and (TObject(window) is TFtX11Window) then
    TFtX11Window(window).SetBackgroundOpacity(opacity);
end;

function ft_window_get_background_opacity(window: Pointer): cdouble; cdecl; export;
begin
  if Assigned(window) and (TObject(window) is TFtX11Window) then
    Result := TFtX11Window(window).GetBackgroundOpacity()
  else
    Result := 1.0;
end;

procedure ft_window_set_background_blur(window: Pointer; blur: cint32); cdecl; export;
begin
  if Assigned(window) and (TObject(window) is TFtX11Window) then
    TFtX11Window(window).SetBackgroundBlur(blur <> 0);
end;

function ft_window_get_background_blur(window: Pointer): cint32; cdecl; export;
begin
  if Assigned(window) and (TObject(window) is TFtX11Window) and TFtX11Window(window).GetBackgroundBlur() then
    Result := 1
  else
    Result := 0;
end;

procedure ft_widget_set_focus(widget: Pointer); cdecl; export;
begin
  if Assigned(widget) and (TObject(widget) is TFtWidget) then
    TFtWidget(widget).SetFocus();
end;

function ft_widget_has_focus(widget: Pointer): cint32; cdecl; export;
begin
  if Assigned(widget) and (TObject(widget) is TFtWidget) and TFtWidget(widget).Focused then
    Result := 1
  else
    Result := 0;
end;

procedure ft_widget_set_focusable(widget: Pointer; focusable: cint32); cdecl; export;
begin
  if Assigned(widget) and (TObject(widget) is TFtWidget) then
    TFtWidget(widget).Focusable := (focusable <> 0);
end;

function ft_widget_get_focusable(widget: Pointer): cint32; cdecl; export;
begin
  if Assigned(widget) and (TObject(widget) is TFtWidget) and TFtWidget(widget).Focusable then
    Result := 1
  else
    Result := 0;
end;

procedure AdjustChildCoordinates(AParent: Pointer; var AX, AY: cint32);
var
  cont: TFtContainer;
begin
  if Assigned(AParent) and (TObject(AParent) is TFtContainer) then
  begin
    cont := TFtContainer(AParent);
    AX := Round(cont.X + cont.PaddingX - cont.ScrollX) + AX;
    AY := Round(cont.Y + cont.PaddingY - cont.ScrollY) + AY;
  end;
end;

function ft_button_create(parent: Pointer; x, y, w, h: cint32; caption: PChar): Pointer; cdecl; export;
var
  Btn: TFtButton;
begin
  AdjustChildCoordinates(parent, x, y);
  Btn := TFtButton.Create(TFtWidget(parent));
  Btn.X := x;
  Btn.Y := y;
  Btn.Width := w;
  Btn.Height := h;
  Btn.Caption := StrPas(caption);
  if Assigned(parent) and (TObject(parent) is TFtContainer) then
    TFtContainer(parent).UpdateScrollBars();
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
  AdjustChildCoordinates(parent, x, y);
  Btn := TFtToggleButton.Create(TFtWidget(parent));
  Btn.X := x;
  Btn.Y := y;
  Btn.Width := w;
  Btn.Height := h;
  Btn.Caption := StrPas(caption);
  if Assigned(parent) and (TObject(parent) is TFtContainer) then
    TFtContainer(parent).UpdateScrollBars();
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
  AdjustChildCoordinates(parent, x, y);
  Sw := TFtSwitch.Create(TFtWidget(parent));
  Sw.X := x;
  Sw.Y := y;
  Sw.Width := w;
  Sw.Height := h;
  if Assigned(caption) then
    Sw.Caption := StrPas(caption)
  else
    Sw.Caption := '';
  if Assigned(parent) and (TObject(parent) is TFtContainer) then
    TFtContainer(parent).UpdateScrollBars();
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
  AdjustChildCoordinates(parent, x, y);
  Result := Pointer(TFtText.Create(TFtWidget(parent), strText));
  TFtWidget(Result).X := x;
  TFtWidget(Result).Y := y;
  TFtWidget(Result).Width := w;
  TFtWidget(Result).Height := h;
  if Assigned(parent) and (TObject(parent) is TFtContainer) then
    TFtContainer(parent).UpdateScrollBars();
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

{ Entry Widgets (Single-line) }

function ft_entry_create(parent: Pointer; x, y, w, h: cint32; text: PChar): Pointer; cdecl; export;
var
  strText: string;
  entry: TFtEntry;
begin
  if Assigned(text) then
    strText := StrPas(text)
  else
    strText := '';
  AdjustChildCoordinates(parent, x, y);
  entry := TFtEntry.Create(TFtWidget(parent), strText);
  entry.X := x;
  entry.Y := y;
  entry.Width := w;
  entry.Height := h;
  if Assigned(parent) and (TObject(parent) is TFtContainer) then
    TFtContainer(parent).UpdateScrollBars();
  Result := Pointer(entry);
end;

procedure ft_entry_set_text(entry_widget: Pointer; text: PChar); cdecl; export;
begin
  if Assigned(entry_widget) and (TObject(entry_widget) is TFtEntry) then
  begin
    if Assigned(text) then
      TFtEntry(entry_widget).Text := StrPas(text)
    else
      TFtEntry(entry_widget).Text := '';
  end;
end;

function ft_entry_get_text(entry_widget: Pointer): PChar; cdecl; export;
begin
  if Assigned(entry_widget) and (TObject(entry_widget) is TFtEntry) then
  begin
    gLastEntryText := TFtEntry(entry_widget).Text;
    Result := PChar(gLastEntryText);
  end
  else
    Result := nil;
end;

procedure ft_entry_set_placeholder(entry_widget: Pointer; placeholder: PChar); cdecl; export;
begin
  if Assigned(entry_widget) and (TObject(entry_widget) is TFtEntry) then
  begin
    if Assigned(placeholder) then
      TFtEntry(entry_widget).Placeholder := StrPas(placeholder)
    else
      TFtEntry(entry_widget).Placeholder := '';
  end;
end;

function ft_entry_get_placeholder(entry_widget: Pointer): PChar; cdecl; export;
begin
  if Assigned(entry_widget) and (TObject(entry_widget) is TFtEntry) then
  begin
    gLastEntryPlaceholder := TFtEntry(entry_widget).Placeholder;
    Result := PChar(gLastEntryPlaceholder);
  end
  else
    Result := nil;
end;

procedure ft_entry_set_readonly(entry_widget: Pointer; readonly_mode: cint32); cdecl; export;
begin
  if Assigned(entry_widget) and (TObject(entry_widget) is TFtEntry) then
    TFtEntry(entry_widget).ReadOnly := (readonly_mode <> 0);
end;

function ft_entry_get_readonly(entry_widget: Pointer): cint32; cdecl; export;
begin
  if Assigned(entry_widget) and (TObject(entry_widget) is TFtEntry) and TFtEntry(entry_widget).ReadOnly then
    Result := 1
  else
    Result := 0;
end;

procedure ft_entry_on_change(entry_widget: Pointer; callback: TFtEntryChangeCallback; user_data: Pointer); cdecl; export;
begin
  if Assigned(entry_widget) and (TObject(entry_widget) is TFtEntry) then
  begin
    TFtEntry(entry_widget).OnChange := callback;
    TFtEntry(entry_widget).UserData := user_data;
  end;
end;

procedure ft_entry_on_submit(entry_widget: Pointer; callback: TFtEntrySubmitCallback; user_data: Pointer); cdecl; export;
begin
  if Assigned(entry_widget) and (TObject(entry_widget) is TFtEntry) then
  begin
    TFtEntry(entry_widget).OnSubmit := callback;
    TFtEntry(entry_widget).UserData := user_data;
  end;
end;

procedure ft_entry_set_corner_radius(entry_widget: Pointer; radius: Double); cdecl; export;
begin
  if Assigned(entry_widget) and (TObject(entry_widget) is TFtEntry) then
    TFtEntry(entry_widget).CornerRadius := radius;
end;

{ TextArea Widgets (Multi-line) }

function ft_textarea_create(parent: Pointer; x, y, w, h: cint32; text: PChar): Pointer; cdecl; export;
var
  strText: string;
  ta: TFtTextArea;
begin
  if Assigned(text) then
    strText := StrPas(text)
  else
    strText := '';
  AdjustChildCoordinates(parent, x, y);
  ta := TFtTextArea.Create(TFtWidget(parent), strText);
  ta.X := x;
  ta.Y := y;
  ta.Width := w;
  ta.Height := h;
  if Assigned(parent) and (TObject(parent) is TFtContainer) then
    TFtContainer(parent).UpdateScrollBars();
  Result := Pointer(ta);
end;

procedure ft_textarea_set_text(textarea_widget: Pointer; text: PChar); cdecl; export;
begin
  if Assigned(textarea_widget) and (TObject(textarea_widget) is TFtTextArea) then
  begin
    if Assigned(text) then
      TFtTextArea(textarea_widget).Text := StrPas(text)
    else
      TFtTextArea(textarea_widget).Text := '';
  end;
end;

function ft_textarea_get_text(textarea_widget: Pointer): PChar; cdecl; export;
begin
  if Assigned(textarea_widget) and (TObject(textarea_widget) is TFtTextArea) then
  begin
    gLastTextAreaText := TFtTextArea(textarea_widget).Text;
    Result := PChar(gLastTextAreaText);
  end
  else
    Result := nil;
end;

procedure ft_textarea_set_placeholder(textarea_widget: Pointer; placeholder: PChar); cdecl; export;
begin
  if Assigned(textarea_widget) and (TObject(textarea_widget) is TFtTextArea) then
  begin
    if Assigned(placeholder) then
      TFtTextArea(textarea_widget).Placeholder := StrPas(placeholder)
    else
      TFtTextArea(textarea_widget).Placeholder := '';
  end;
end;

function ft_textarea_get_placeholder(textarea_widget: Pointer): PChar; cdecl; export;
begin
  if Assigned(textarea_widget) and (TObject(textarea_widget) is TFtTextArea) then
  begin
    gLastTextAreaPlaceholder := TFtTextArea(textarea_widget).Placeholder;
    Result := PChar(gLastTextAreaPlaceholder);
  end
  else
    Result := nil;
end;

procedure ft_textarea_set_readonly(textarea_widget: Pointer; readonly_mode: cint32); cdecl; export;
begin
  if Assigned(textarea_widget) and (TObject(textarea_widget) is TFtTextArea) then
    TFtTextArea(textarea_widget).ReadOnly := (readonly_mode <> 0);
end;

function ft_textarea_get_readonly(textarea_widget: Pointer): cint32; cdecl; export;
begin
  if Assigned(textarea_widget) and (TObject(textarea_widget) is TFtTextArea) and TFtTextArea(textarea_widget).ReadOnly then
    Result := 1
  else
    Result := 0;
end;

procedure ft_textarea_on_change(textarea_widget: Pointer; callback: TFtTextAreaChangeCallback; user_data: Pointer); cdecl; export;
begin
  if Assigned(textarea_widget) and (TObject(textarea_widget) is TFtTextArea) then
  begin
    TFtTextArea(textarea_widget).OnChange := callback;
    TFtTextArea(textarea_widget).UserData := user_data;
  end;
end;

procedure ft_textarea_set_corner_radius(textarea_widget: Pointer; radius: Double); cdecl; export;
begin
  if Assigned(textarea_widget) and (TObject(textarea_widget) is TFtTextArea) then
    TFtTextArea(textarea_widget).CornerRadius := radius;
end;

procedure ft_textarea_set_scrollbar_mode(textarea_widget: Pointer; mode: cint32); cdecl; export;
begin
  if Assigned(textarea_widget) and (TObject(textarea_widget) is TFtTextArea) then
  begin
    case mode of
      0: TFtTextArea(textarea_widget).ScrollBarMode := ftSbModeNone;
      1: TFtTextArea(textarea_widget).ScrollBarMode := ftSbModeHorizontalOnly;
      2: TFtTextArea(textarea_widget).ScrollBarMode := ftSbModeVerticalOnly;
      3: TFtTextArea(textarea_widget).ScrollBarMode := ftSbModeAutoBoth;
    else
      TFtTextArea(textarea_widget).ScrollBarMode := ftSbModeAutoBoth;
    end;
  end;
end;

function ft_textarea_get_scrollbar_mode(textarea_widget: Pointer): cint32; cdecl; export;
begin
  if Assigned(textarea_widget) and (TObject(textarea_widget) is TFtTextArea) then
    Result := Ord(TFtTextArea(textarea_widget).ScrollBarMode)
  else
    Result := 0;
end;

function ft_textarea_get_vscrollbar(textarea_widget: Pointer): Pointer; cdecl; export;
begin
  if Assigned(textarea_widget) and (TObject(textarea_widget) is TFtTextArea) then
    Result := Pointer(TFtTextArea(textarea_widget).VScrollBar)
  else
    Result := nil;
end;

function ft_textarea_get_hscrollbar(textarea_widget: Pointer): Pointer; cdecl; export;
begin
  if Assigned(textarea_widget) and (TObject(textarea_widget) is TFtTextArea) then
    Result := Pointer(TFtTextArea(textarea_widget).HScrollBar)
  else
    Result := nil;
end;

{ ScrollBar Widgets }

function ft_scrollbar_create(parent: Pointer; x, y, w, h: cint32; orientation: cint32): Pointer; cdecl; export;
var
  orient: TFtScrollBarOrientation;
  sb: TFtScrollBar;
begin
  if orientation = 0 then
    orient := ftSbHorizontal
  else
    orient := ftSbVertical;
  AdjustChildCoordinates(parent, x, y);
  sb := TFtScrollBar.Create(TFtWidget(parent), orient);
  sb.X := x;
  sb.Y := y;
  sb.Width := w;
  sb.Height := h;
  if Assigned(parent) and (TObject(parent) is TFtContainer) then
    TFtContainer(parent).UpdateScrollBars();
  Result := Pointer(sb);
end;

procedure ft_scrollbar_set_orientation(scrollbar_widget: Pointer; orientation: cint32); cdecl; export;
begin
  if Assigned(scrollbar_widget) and (TObject(scrollbar_widget) is TFtScrollBar) then
  begin
    if orientation = 0 then
      TFtScrollBar(scrollbar_widget).Orientation := ftSbHorizontal
    else
      TFtScrollBar(scrollbar_widget).Orientation := ftSbVertical;
  end;
end;

function ft_scrollbar_get_orientation(scrollbar_widget: Pointer): cint32; cdecl; export;
begin
  if Assigned(scrollbar_widget) and (TObject(scrollbar_widget) is TFtScrollBar) and (TFtScrollBar(scrollbar_widget).Orientation = ftSbVertical) then
    Result := 1
  else
    Result := 0;
end;

procedure ft_scrollbar_set_range(scrollbar_widget: Pointer; min, max, page_size: Double); cdecl; export;
begin
  if Assigned(scrollbar_widget) and (TObject(scrollbar_widget) is TFtScrollBar) then
    TFtScrollBar(scrollbar_widget).SetRange(min, max, page_size);
end;

procedure ft_scrollbar_set_value(scrollbar_widget: Pointer; value: Double); cdecl; export;
begin
  if Assigned(scrollbar_widget) and (TObject(scrollbar_widget) is TFtScrollBar) then
    TFtScrollBar(scrollbar_widget).Value := value;
end;

function ft_scrollbar_get_value(scrollbar_widget: Pointer): Double; cdecl; export;
begin
  if Assigned(scrollbar_widget) and (TObject(scrollbar_widget) is TFtScrollBar) then
    Result := TFtScrollBar(scrollbar_widget).Value
  else
    Result := 0.0;
end;

function ft_scrollbar_get_min(scrollbar_widget: Pointer): Double; cdecl; export;
begin
  if Assigned(scrollbar_widget) and (TObject(scrollbar_widget) is TFtScrollBar) then
    Result := TFtScrollBar(scrollbar_widget).Min
  else
    Result := 0.0;
end;

function ft_scrollbar_get_max(scrollbar_widget: Pointer): Double; cdecl; export;
begin
  if Assigned(scrollbar_widget) and (TObject(scrollbar_widget) is TFtScrollBar) then
    Result := TFtScrollBar(scrollbar_widget).Max
  else
    Result := 0.0;
end;

function ft_scrollbar_get_page_size(scrollbar_widget: Pointer): Double; cdecl; export;
begin
  if Assigned(scrollbar_widget) and (TObject(scrollbar_widget) is TFtScrollBar) then
    Result := TFtScrollBar(scrollbar_widget).PageSize
  else
    Result := 0.0;
end;

procedure ft_scrollbar_set_step(scrollbar_widget: Pointer; step: Double); cdecl; export;
begin
  if Assigned(scrollbar_widget) and (TObject(scrollbar_widget) is TFtScrollBar) then
    TFtScrollBar(scrollbar_widget).Step := step;
end;

function ft_scrollbar_get_step(scrollbar_widget: Pointer): Double; cdecl; export;
begin
  if Assigned(scrollbar_widget) and (TObject(scrollbar_widget) is TFtScrollBar) then
    Result := TFtScrollBar(scrollbar_widget).Step
  else
    Result := 0.0;
end;

procedure ft_scrollbar_on_scroll(scrollbar_widget: Pointer; callback: TFtScrollCallback; user_data: Pointer); cdecl; export;
begin
  if Assigned(scrollbar_widget) and (TObject(scrollbar_widget) is TFtScrollBar) then
  begin
    TFtScrollBar(scrollbar_widget).OnScroll := callback;
    TFtScrollBar(scrollbar_widget).UserData := user_data;
  end;
end;

procedure ft_scrollbar_set_corner_radius(scrollbar_widget: Pointer; radius: Double); cdecl; export;
begin
  if Assigned(scrollbar_widget) and (TObject(scrollbar_widget) is TFtScrollBar) then
    TFtScrollBar(scrollbar_widget).CornerRadius := radius;
end;

{ Container Widgets (Scrollable Frame Box) }

function ft_container_create(parent: Pointer; x, y, w, h: cint32): Pointer; cdecl; export;
var
  cont: TFtContainer;
begin
  AdjustChildCoordinates(parent, x, y);
  cont := TFtContainer.Create(TFtWidget(parent));
  cont.X := x;
  cont.Y := y;
  cont.Width := w;
  cont.Height := h;
  if Assigned(parent) and (TObject(parent) is TFtContainer) then
    TFtContainer(parent).UpdateScrollBars();
  Result := Pointer(cont);
end;

procedure ft_container_set_scrollbar_mode(container: Pointer; mode: cint32); cdecl; export;
begin
  if Assigned(container) and (TObject(container) is TFtContainer) then
  begin
    case mode of
      0: TFtContainer(container).ScrollBarMode := ftSbModeNone;
      1: TFtContainer(container).ScrollBarMode := ftSbModeHorizontalOnly;
      2: TFtContainer(container).ScrollBarMode := ftSbModeVerticalOnly;
      3: TFtContainer(container).ScrollBarMode := ftSbModeAutoBoth;
    else
      TFtContainer(container).ScrollBarMode := ftSbModeAutoBoth;
    end;
  end;
end;

function ft_container_get_scrollbar_mode(container: Pointer): cint32; cdecl; export;
begin
  if Assigned(container) and (TObject(container) is TFtContainer) then
    Result := Ord(TFtContainer(container).ScrollBarMode)
  else
    Result := 0;
end;

procedure ft_container_set_content_size(container: Pointer; width, height: Double); cdecl; export;
begin
  if Assigned(container) and (TObject(container) is TFtContainer) then
    TFtContainer(container).SetContentSize(width, height);
end;

procedure ft_container_get_content_size(container: Pointer; width, height: PDouble); cdecl; export;
begin
  if Assigned(container) and (TObject(container) is TFtContainer) then
  begin
    if Assigned(width) then width^ := TFtContainer(container).ContentWidth;
    if Assigned(height) then height^ := TFtContainer(container).ContentHeight;
  end;
end;

procedure ft_container_set_scroll_pos(container: Pointer; scroll_x, scroll_y: Double); cdecl; export;
begin
  if Assigned(container) and (TObject(container) is TFtContainer) then
  begin
    TFtContainer(container).ScrollX := scroll_x;
    TFtContainer(container).ScrollY := scroll_y;
  end;
end;

function ft_container_get_scroll_x(container: Pointer): Double; cdecl; export;
begin
  if Assigned(container) and (TObject(container) is TFtContainer) then
    Result := TFtContainer(container).ScrollX
  else
    Result := 0.0;
end;

function ft_container_get_scroll_y(container: Pointer): Double; cdecl; export;
begin
  if Assigned(container) and (TObject(container) is TFtContainer) then
    Result := TFtContainer(container).ScrollY
  else
    Result := 0.0;
end;

procedure ft_container_set_corner_radius(container: Pointer; radius: Double); cdecl; export;
begin
  if Assigned(container) and (TObject(container) is TFtContainer) then
    TFtContainer(container).CornerRadius := radius;
end;

function ft_container_get_corner_radius(container: Pointer): Double; cdecl; export;
begin
  if Assigned(container) and (TObject(container) is TFtContainer) then
    Result := TFtContainer(container).CornerRadius
  else
    Result := -1.0;
end;

procedure ft_container_set_backdrop_blur(container: Pointer; radius: cdouble); cdecl; export;
begin
  if Assigned(container) and (TObject(container) is TFtContainer) then
    TFtContainer(container).BackdropBlur := radius;
end;

function ft_container_get_backdrop_blur(container: Pointer): cdouble; cdecl; export;
begin
  if Assigned(container) and (TObject(container) is TFtContainer) then
    Result := TFtContainer(container).BackdropBlur
  else
    Result := 0.0;
end;

procedure ft_container_set_padding(container: Pointer; pad_x, pad_y: Double); cdecl; export;
begin
  if Assigned(container) and (TObject(container) is TFtContainer) then
    TFtContainer(container).SetPadding(pad_x, pad_y);
end;

procedure ft_container_set_draw_frame(container: Pointer; draw_frame: cint32); cdecl; export;
begin
  if Assigned(container) and (TObject(container) is TFtContainer) then
    TFtContainer(container).DrawFrame := (draw_frame <> 0);
end;

function ft_container_get_draw_frame(container: Pointer): cint32; cdecl; export;
begin
  if Assigned(container) and (TObject(container) is TFtContainer) and TFtContainer(container).DrawFrame then
    Result := 1
  else
    Result := 0;
end;

procedure ft_container_set_draw_focus_ring(container: Pointer; draw_focus_ring: cint32); cdecl; export;
begin
  if Assigned(container) and (TObject(container) is TFtContainer) then
    TFtContainer(container).DrawFocusRing := (draw_focus_ring <> 0);
end;

function ft_container_get_draw_focus_ring(container: Pointer): cint32; cdecl; export;
begin
  if Assigned(container) and (TObject(container) is TFtContainer) and TFtContainer(container).DrawFocusRing then
    Result := 1
  else
    Result := 0;
end;

procedure ft_container_set_auto_content_size(container: Pointer; auto_size: cint32); cdecl; export;
begin
  if Assigned(container) and (TObject(container) is TFtContainer) then
  begin
    TFtContainer(container).AutoContentSize := (auto_size <> 0);
    TFtContainer(container).UpdateScrollBars();
    TFtContainer(container).Invalidate();
  end;
end;

function ft_container_get_auto_content_size(container: Pointer): cint32; cdecl; export;
begin
  if Assigned(container) and (TObject(container) is TFtContainer) and TFtContainer(container).AutoContentSize then
    Result := 1
  else
    Result := 0;
end;

function ft_container_get_vscrollbar(container: Pointer): Pointer; cdecl; export;
begin
  if Assigned(container) and (TObject(container) is TFtContainer) then
    Result := Pointer(TFtContainer(container).VScrollBar)
  else
    Result := nil;
end;

function ft_container_get_hscrollbar(container: Pointer): Pointer; cdecl; export;
begin
  if Assigned(container) and (TObject(container) is TFtContainer) then
    Result := Pointer(TFtContainer(container).HScrollBar)
  else
    Result := nil;
end;

procedure ft_container_on_scroll(container: Pointer; callback: TFtScrollCallback; user_data: Pointer); cdecl; export;
begin
  if Assigned(container) and (TObject(container) is TFtContainer) then
  begin
    TFtContainer(container).OnScroll := callback;
    TFtContainer(container).UserData := user_data;
  end;
end;

procedure ft_container_get_client_rect(container: Pointer; x, y, w, h: PDouble); cdecl; export;
var
  cx, cy, cw, ch: Double;
begin
  if Assigned(container) and (TObject(container) is TFtContainer) then
  begin
    TFtContainer(container).GetClientRect(cx, cy, cw, ch);
    if Assigned(x) then x^ := cx;
    if Assigned(y) then y^ := cy;
    if Assigned(w) then w^ := cw;
    if Assigned(h) then h^ := ch;
  end;
end;

procedure ft_container_update_scrollbars(container: Pointer); cdecl; export;
begin
  if Assigned(container) and (TObject(container) is TFtContainer) then
    TFtContainer(container).UpdateScrollBars();
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

{ Main Menu C API }

function ft_main_menu_create(window: Pointer): Pointer; cdecl; export;
var
  menu: TFtMainMenu;
begin
  menu := TFtMainMenu.Create(TFtWidget(window));
  if Assigned(window) and (TObject(window) is TFtX11Window) then
    TFtX11Window(window).MainMenu := menu;
  Result := Pointer(menu);
end;

function ft_main_menu_add_menu(main_menu: Pointer; caption: PChar): Pointer; cdecl; export;
begin
  if Assigned(main_menu) and (TObject(main_menu) is TFtMainMenu) then
    Result := Pointer(TFtMainMenu(main_menu).AddMenu(StrPas(caption)))
  else
    Result := nil;
end;

function ft_main_menu_add_item(main_menu: Pointer; caption: PChar; popup_menu: Pointer): Pointer; cdecl; export;
begin
  if Assigned(main_menu) and (TObject(main_menu) is TFtMainMenu) then
    Result := Pointer(TFtMainMenu(main_menu).AddItem(StrPas(caption), TFtPopupMenu(popup_menu)))
  else
    Result := nil;
end;

function ft_main_menu_item_count(main_menu: Pointer): cint32; cdecl; export;
begin
  if Assigned(main_menu) and (TObject(main_menu) is TFtMainMenu) then
    Result := TFtMainMenu(main_menu).ItemCount()
  else
    Result := 0;
end;

function ft_main_menu_get_item(main_menu: Pointer; index: cint32): Pointer; cdecl; export;
begin
  if Assigned(main_menu) and (TObject(main_menu) is TFtMainMenu) then
    Result := Pointer(TFtMainMenu(main_menu).GetItem(index))
  else
    Result := nil;
end;

procedure ft_main_menu_close(main_menu: Pointer); cdecl; export;
begin
  if Assigned(main_menu) and (TObject(main_menu) is TFtMainMenu) then
    TFtMainMenu(main_menu).CloseMenu();
end;

{ Pop-up / Context Menu C API }

function ft_popup_menu_create(parent: Pointer): Pointer; cdecl; export;
var
  pop: TFtPopupMenu;
begin
  pop := TFtPopupMenu.Create(TFtWidget(parent));
  Result := Pointer(pop);
end;

function ft_popup_menu_add_item(popup_menu: Pointer; caption: PChar; callback: TFtMenuCallback; user_data: Pointer): Pointer; cdecl; export;
begin
  if Assigned(popup_menu) and (TObject(popup_menu) is TFtPopupMenu) then
    Result := Pointer(TFtPopupMenu(popup_menu).AddItem(StrPas(caption), callback, user_data))
  else
    Result := nil;
end;

function ft_popup_menu_add_check_item(popup_menu: Pointer; caption: PChar; checked: cint32; callback: TFtMenuCallback; user_data: Pointer): Pointer; cdecl; export;
begin
  if Assigned(popup_menu) and (TObject(popup_menu) is TFtPopupMenu) then
    Result := Pointer(TFtPopupMenu(popup_menu).AddCheckItem(StrPas(caption), checked <> 0, callback, user_data))
  else
    Result := nil;
end;

function ft_popup_menu_add_separator(popup_menu: Pointer): Pointer; cdecl; export;
begin
  if Assigned(popup_menu) and (TObject(popup_menu) is TFtPopupMenu) then
    Result := Pointer(TFtPopupMenu(popup_menu).AddSeparator())
  else
    Result := nil;
end;

function ft_popup_menu_add_submenu(popup_menu: Pointer; caption: PChar; submenu: Pointer): Pointer; cdecl; export;
begin
  if Assigned(popup_menu) and (TObject(popup_menu) is TFtPopupMenu) then
    Result := Pointer(TFtPopupMenu(popup_menu).AddSubMenu(StrPas(caption), TFtPopupMenu(submenu)))
  else
    Result := nil;
end;

function ft_popup_menu_item_count(popup_menu: Pointer): cint32; cdecl; export;
begin
  if Assigned(popup_menu) and (TObject(popup_menu) is TFtPopupMenu) then
    Result := TFtPopupMenu(popup_menu).ItemCount()
  else
    Result := 0;
end;

function ft_popup_menu_get_item(popup_menu: Pointer; index: cint32): Pointer; cdecl; export;
begin
  if Assigned(popup_menu) and (TObject(popup_menu) is TFtPopupMenu) then
    Result := Pointer(TFtPopupMenu(popup_menu).GetItem(index))
  else
    Result := nil;
end;

procedure ft_popup_menu_show(popup_menu: Pointer; x, y: cint32); cdecl; export;
var
  menu: TFtPopupMenu;
  rootWin: TFtWidget;
  pt: TPoint;
begin
  if Assigned(popup_menu) and (TObject(popup_menu) is TFtPopupMenu) then
  begin
    menu := TFtPopupMenu(popup_menu);
    if Assigned(menu.OwnerWidget) then
    begin
      rootWin := menu.OwnerWidget.GetRootWidget();
      if Assigned(rootWin) and (rootWin is TFtX11Window) then
      begin
        pt := TFtX11Window(rootWin).ClientToScreen(x, y);
        x := pt.X;
        y := pt.Y;
      end;
    end;
    menu.Popup(x, y);
  end;
end;

procedure ft_popup_menu_close(popup_menu: Pointer); cdecl; export;
begin
  if Assigned(popup_menu) and (TObject(popup_menu) is TFtPopupMenu) then
    TFtPopupMenu(popup_menu).Close();
end;

procedure ft_popup_menu_clear(popup_menu: Pointer); cdecl; export;
begin
  if Assigned(popup_menu) and (TObject(popup_menu) is TFtPopupMenu) then
    TFtPopupMenu(popup_menu).Clear();
end;

procedure ft_popup_menu_set_corner_radius(popup_menu: Pointer; radius: Double); cdecl; export;
begin
  if Assigned(popup_menu) and (TObject(popup_menu) is TFtPopupMenu) then
  begin
    TFtPopupMenu(popup_menu).CornerRadius := radius;
    TFtPopupMenu(popup_menu).Invalidate();
  end;
end;

{ Menu Items C API }

procedure ft_menu_item_set_caption(item: Pointer; caption: PChar); cdecl; export;
begin
  if Assigned(item) and (TObject(item) is TFtMenuItem) then
    TFtMenuItem(item).Caption := StrPas(caption);
end;

function ft_menu_item_get_caption(item: Pointer): PChar; cdecl; export;
begin
  if Assigned(item) and (TObject(item) is TFtMenuItem) then
  begin
    gLastMenuCaption := TFtMenuItem(item).Caption;
    Result := PChar(gLastMenuCaption);
  end
  else
    Result := nil;
end;

procedure ft_menu_item_set_shortcut(item: Pointer; shortcut: PChar); cdecl; export;
begin
  if Assigned(item) and (TObject(item) is TFtMenuItem) then
    TFtMenuItem(item).Shortcut := StrPas(shortcut);
end;

function ft_menu_item_get_shortcut(item: Pointer): PChar; cdecl; export;
begin
  if Assigned(item) and (TObject(item) is TFtMenuItem) then
  begin
    gLastMenuShortcut := TFtMenuItem(item).Shortcut;
    Result := PChar(gLastMenuShortcut);
  end
  else
    Result := nil;
end;

procedure ft_menu_item_set_enabled(item: Pointer; enabled: cint32); cdecl; export;
begin
  if Assigned(item) and (TObject(item) is TFtMenuItem) then
    TFtMenuItem(item).Enabled := (enabled <> 0);
end;

function ft_menu_item_get_enabled(item: Pointer): cint32; cdecl; export;
begin
  if Assigned(item) and (TObject(item) is TFtMenuItem) and TFtMenuItem(item).Enabled then
    Result := 1
  else
    Result := 0;
end;

procedure ft_menu_item_set_checked(item: Pointer; checked: cint32); cdecl; export;
begin
  if Assigned(item) and (TObject(item) is TFtMenuItem) then
    TFtMenuItem(item).Checked := (checked <> 0);
end;

function ft_menu_item_get_checked(item: Pointer): cint32; cdecl; export;
begin
  if Assigned(item) and (TObject(item) is TFtMenuItem) and TFtMenuItem(item).Checked then
    Result := 1
  else
    Result := 0;
end;

procedure ft_menu_item_set_checkable(item: Pointer; checkable: cint32); cdecl; export;
begin
  if Assigned(item) and (TObject(item) is TFtMenuItem) then
    TFtMenuItem(item).Checkable := (checkable <> 0);
end;

function ft_menu_item_get_checkable(item: Pointer): cint32; cdecl; export;
begin
  if Assigned(item) and (TObject(item) is TFtMenuItem) and TFtMenuItem(item).Checkable then
    Result := 1
  else
    Result := 0;
end;

procedure ft_menu_item_set_submenu(item: Pointer; submenu: Pointer); cdecl; export;
begin
  if Assigned(item) and (TObject(item) is TFtMenuItem) then
    TFtMenuItem(item).SubMenu := TFtPopupMenu(submenu);
end;

function ft_menu_item_get_submenu(item: Pointer): Pointer; cdecl; export;
begin
  if Assigned(item) and (TObject(item) is TFtMenuItem) then
    Result := Pointer(TFtMenuItem(item).SubMenu)
  else
    Result := nil;
end;

procedure ft_menu_item_on_click(item: Pointer; callback: TFtMenuCallback; user_data: Pointer); cdecl; export;
begin
  if Assigned(item) and (TObject(item) is TFtMenuItem) then
  begin
    TFtMenuItem(item).OnClick := callback;
    TFtMenuItem(item).UserData := user_data;
  end;
end;

procedure ft_menu_item_set_tag(item: Pointer; tag: cint64); cdecl; export;
begin
  if Assigned(item) and (TObject(item) is TFtMenuItem) then
    TFtMenuItem(item).Tag := tag;
end;

function ft_menu_item_get_tag(item: Pointer): cint64; cdecl; export;
begin
  if Assigned(item) and (TObject(item) is TFtMenuItem) then
    Result := TFtMenuItem(item).Tag
  else
    Result := 0;
end;

{ Context Menu and Window Attachment C API }

procedure ft_widget_set_context_menu(widget: Pointer; popup_menu: Pointer); cdecl; export;
begin
  if Assigned(widget) and (TObject(widget) is TFtWidget) then
  begin
    TFtWidget(widget).ContextMenu := TFtWidget(popup_menu);
    if Assigned(popup_menu) and (TObject(popup_menu) is TFtPopupMenu) then
      TFtPopupMenu(popup_menu).OwnerWidget := TFtWidget(widget);
  end;
end;

function ft_widget_get_context_menu(widget: Pointer): Pointer; cdecl; export;
begin
  if Assigned(widget) and (TObject(widget) is TFtWidget) then
    Result := Pointer(TFtWidget(widget).ContextMenu)
  else
    Result := nil;
end;

procedure ft_window_set_context_menu(window: Pointer; popup_menu: Pointer); cdecl; export;
begin
  if Assigned(window) and (TObject(window) is TFtWidget) then
  begin
    TFtWidget(window).ContextMenu := TFtWidget(popup_menu);
    if Assigned(popup_menu) and (TObject(popup_menu) is TFtPopupMenu) then
      TFtPopupMenu(popup_menu).OwnerWidget := TFtWidget(window);
  end;
end;

function ft_window_get_context_menu(window: Pointer): Pointer; cdecl; export;
begin
  if Assigned(window) and (TObject(window) is TFtWidget) then
    Result := Pointer(TFtWidget(window).ContextMenu)
  else
    Result := nil;
end;

procedure ft_window_set_main_menu(window: Pointer; main_menu: Pointer); cdecl; export;
begin
  if Assigned(window) and (TObject(window) is TFtX11Window) then
    TFtX11Window(window).MainMenu := TFtWidget(main_menu);
end;

function ft_window_get_main_menu(window: Pointer): Pointer; cdecl; export;
begin
  if Assigned(window) and (TObject(window) is TFtX11Window) then
    Result := Pointer(TFtX11Window(window).MainMenu)
  else
    Result := nil;
end;

{ CSS Styling C API }

procedure ft_widget_set_style_class(widget: Pointer; style_class: PChar); cdecl; export;
begin
  if Assigned(widget) and (TObject(widget) is TFtWidget) then
    TFtWidget(widget).StyleClass := StrPas(style_class);
end;

function ft_widget_get_style_class(widget: Pointer): PChar; cdecl; export;
begin
  if Assigned(widget) and (TObject(widget) is TFtWidget) then
  begin
    gLastStyleClass := TFtWidget(widget).StyleClass;
    Result := PChar(gLastStyleClass);
  end
  else
    Result := '';
end;

procedure ft_widget_set_style_id(widget: Pointer; style_id: PChar); cdecl; export;
begin
  if Assigned(widget) and (TObject(widget) is TFtWidget) then
    TFtWidget(widget).StyleId := StrPas(style_id);
end;

function ft_widget_get_style_id(widget: Pointer): PChar; cdecl; export;
begin
  if Assigned(widget) and (TObject(widget) is TFtWidget) then
  begin
    gLastStyleId := TFtWidget(widget).StyleId;
    Result := PChar(gLastStyleId);
  end
  else
    Result := '';
end;

procedure ft_widget_set_style(widget: Pointer; inline_css: PChar); cdecl; export;
begin
  if Assigned(widget) and (TObject(widget) is TFtWidget) then
    TFtWidget(widget).InlineStyle := StrPas(inline_css);
end;

function ft_widget_get_style(widget: Pointer): PChar; cdecl; export;
begin
  if Assigned(widget) and (TObject(widget) is TFtWidget) then
  begin
    gLastInlineStyle := TFtWidget(widget).InlineStyle;
    Result := PChar(gLastInlineStyle);
  end
  else
    Result := '';
end;

procedure ft_widget_set_opacity(widget: Pointer; opacity: cdouble); cdecl; export;
begin
  if Assigned(widget) and (TObject(widget) is TFtWidget) then
    TFtWidget(widget).Opacity := opacity;
end;

function ft_widget_get_opacity(widget: Pointer): cdouble; cdecl; export;
begin
  if Assigned(widget) and (TObject(widget) is TFtWidget) then
    Result := TFtWidget(widget).Opacity
  else
    Result := 1.0;
end;

function ft_style_load_css_file(filepath: PChar): cint32; cdecl; export;
begin
  if Assigned(filepath) and FtLoadStyleSheet(StrPas(filepath)) then
    Result := 1
  else
    Result := 0;
end;

function ft_style_load_css_string(css_string: PChar): cint32; cdecl; export;
begin
  if Assigned(css_string) and FtLoadStyleSheetString(StrPas(css_string)) then
    Result := 1
  else
    Result := 0;
end;

function ft_animation_is_running(): cint32; cdecl; export;
begin
  if FtGetAnimator().HasActiveAnimations() then
    Result := 1
  else
    Result := 0;
end;

{ CheckBox Widgets }

function ft_checkbox_create(parent: Pointer; x, y, w, h: cint32; caption: PChar): Pointer; cdecl; export;
var
  cb: TFtCheckBox;
begin
  AdjustChildCoordinates(parent, x, y);
  cb := TFtCheckBox.Create(TFtWidget(parent));
  cb.X := x;
  cb.Y := y;
  if w > 0 then cb.Width := w;
  if h > 0 then cb.Height := h;
  if Assigned(caption) then
    cb.Caption := StrPas(caption);
  Result := Pointer(cb);
end;

procedure ft_checkbox_set_checked(checkbox: Pointer; checked: cint32); cdecl; export;
begin
  if Assigned(checkbox) and (TObject(checkbox) is TFtCheckBox) then
    TFtCheckBox(checkbox).Checked := (checked <> 0);
end;

function ft_checkbox_get_checked(checkbox: Pointer): cint32; cdecl; export;
begin
  if Assigned(checkbox) and (TObject(checkbox) is TFtCheckBox) then
  begin
    if TFtCheckBox(checkbox).Checked then
      Result := 1
    else
      Result := 0;
  end
  else
    Result := 0;
end;

procedure ft_checkbox_toggle(checkbox: Pointer); cdecl; export;
begin
  if Assigned(checkbox) and (TObject(checkbox) is TFtCheckBox) then
    TFtCheckBox(checkbox).Toggle();
end;

procedure ft_checkbox_set_caption(checkbox: Pointer; caption: PChar); cdecl; export;
begin
  if Assigned(checkbox) and (TObject(checkbox) is TFtCheckBox) and Assigned(caption) then
    TFtCheckBox(checkbox).Caption := StrPas(caption);
end;

function ft_checkbox_get_caption(checkbox: Pointer): PChar; cdecl; export;
begin
  if Assigned(checkbox) and (TObject(checkbox) is TFtCheckBox) then
  begin
    gLastCheckBoxCaption := TFtCheckBox(checkbox).Caption;
    Result := PChar(gLastCheckBoxCaption);
  end
  else
    Result := PChar('');
end;

procedure ft_checkbox_set_corner_radius(checkbox: Pointer; radius: Double); cdecl; export;
begin
  if Assigned(checkbox) and (TObject(checkbox) is TFtCheckBox) then
    TFtCheckBox(checkbox).CornerRadius := radius;
end;

function ft_checkbox_get_corner_radius(checkbox: Pointer): Double; cdecl; export;
begin
  if Assigned(checkbox) and (TObject(checkbox) is TFtCheckBox) then
    Result := TFtCheckBox(checkbox).CornerRadius
  else
    Result := 0.0;
end;

procedure ft_checkbox_on_toggle(checkbox: Pointer; callback: TFtCheckCallback; user_data: Pointer); cdecl; export;
begin
  if Assigned(checkbox) and (TObject(checkbox) is TFtCheckBox) then
  begin
    TFtCheckBox(checkbox).OnToggle := callback;
    TFtCheckBox(checkbox).UserData := user_data;
  end;
end;

{ RadioButton Widgets }

function ft_radio_create(parent: Pointer; x, y, w, h: cint32; caption: PChar): Pointer; cdecl; export;
var
  rb: TFtRadioButton;
begin
  AdjustChildCoordinates(parent, x, y);
  rb := TFtRadioButton.Create(TFtWidget(parent));
  rb.X := x;
  rb.Y := y;
  if w > 0 then rb.Width := w;
  if h > 0 then rb.Height := h;
  if Assigned(caption) then
    rb.Caption := StrPas(caption);
  Result := Pointer(rb);
end;

procedure ft_radio_set_checked(radio: Pointer; checked: cint32); cdecl; export;
begin
  if Assigned(radio) and (TObject(radio) is TFtRadioButton) then
    TFtRadioButton(radio).Checked := (checked <> 0);
end;

function ft_radio_get_checked(radio: Pointer): cint32; cdecl; export;
begin
  if Assigned(radio) and (TObject(radio) is TFtRadioButton) then
  begin
    if TFtRadioButton(radio).Checked then
      Result := 1
    else
      Result := 0;
  end
  else
    Result := 0;
end;

procedure ft_radio_set_group(radio: Pointer; group_id: cint32); cdecl; export;
begin
  if Assigned(radio) and (TObject(radio) is TFtRadioButton) then
    TFtRadioButton(radio).GroupId := group_id;
end;

function ft_radio_get_group(radio: Pointer): cint32; cdecl; export;
begin
  if Assigned(radio) and (TObject(radio) is TFtRadioButton) then
    Result := TFtRadioButton(radio).GroupId
  else
    Result := 0;
end;

procedure ft_radio_set_caption(radio: Pointer; caption: PChar); cdecl; export;
begin
  if Assigned(radio) and (TObject(radio) is TFtRadioButton) and Assigned(caption) then
    TFtRadioButton(radio).Caption := StrPas(caption);
end;

function ft_radio_get_caption(radio: Pointer): PChar; cdecl; export;
begin
  if Assigned(radio) and (TObject(radio) is TFtRadioButton) then
  begin
    gLastRadioCaption := TFtRadioButton(radio).Caption;
    Result := PChar(gLastRadioCaption);
  end
  else
    Result := PChar('');
end;

procedure ft_radio_on_toggle(radio: Pointer; callback: TFtRadioCallback; user_data: Pointer); cdecl; export;
begin
  if Assigned(radio) and (TObject(radio) is TFtRadioButton) then
  begin
    TFtRadioButton(radio).OnToggle := callback;
    TFtRadioButton(radio).UserData := user_data;
  end;
end;

{ ComboBox Widgets }

function ft_combobox_create(parent: Pointer; x, y, w, h: cint32): Pointer; cdecl; export;
var
  cb: TFtComboBox;
begin
  AdjustChildCoordinates(parent, x, y);
  cb := TFtComboBox.Create(TFtWidget(parent));
  cb.X := x;
  cb.Y := y;
  if w > 0 then cb.Width := w;
  if h > 0 then cb.Height := h;
  Result := Pointer(cb);
end;

function ft_combobox_add_item(combobox: Pointer; item: PChar): cint32; cdecl; export;
begin
  if Assigned(combobox) and (TObject(combobox) is TFtComboBox) and Assigned(item) then
    Result := TFtComboBox(combobox).AddItem(StrPas(item))
  else
    Result := -1;
end;

procedure ft_combobox_clear(combobox: Pointer); cdecl; export;
begin
  if Assigned(combobox) and (TObject(combobox) is TFtComboBox) then
    TFtComboBox(combobox).Clear();
end;

function ft_combobox_get_item_count(combobox: Pointer): cint32; cdecl; export;
begin
  if Assigned(combobox) and (TObject(combobox) is TFtComboBox) then
    Result := TFtComboBox(combobox).GetItemCount()
  else
    Result := 0;
end;

function ft_combobox_get_item(combobox: Pointer; index: cint32): PChar; cdecl; export;
begin
  if Assigned(combobox) and (TObject(combobox) is TFtComboBox) then
  begin
    gLastComboItem := TFtComboBox(combobox).GetItem(index);
    Result := PChar(gLastComboItem);
  end
  else
    Result := PChar('');
end;

procedure ft_combobox_set_selected(combobox: Pointer; index: cint32); cdecl; export;
begin
  if Assigned(combobox) and (TObject(combobox) is TFtComboBox) then
    TFtComboBox(combobox).SelectedIndex := index;
end;

function ft_combobox_get_selected(combobox: Pointer): cint32; cdecl; export;
begin
  if Assigned(combobox) and (TObject(combobox) is TFtComboBox) then
    Result := TFtComboBox(combobox).SelectedIndex
  else
    Result := -1;
end;

function ft_combobox_get_selected_text(combobox: Pointer): PChar; cdecl; export;
begin
  if Assigned(combobox) and (TObject(combobox) is TFtComboBox) then
  begin
    gLastComboText := TFtComboBox(combobox).GetItem(TFtComboBox(combobox).SelectedIndex);
    Result := PChar(gLastComboText);
  end
  else
    Result := PChar('');
end;

procedure ft_combobox_set_text(combobox: Pointer; text: PChar); cdecl; export;
begin
  if Assigned(combobox) and (TObject(combobox) is TFtComboBox) and Assigned(text) then
    TFtComboBox(combobox).Text := StrPas(text);
end;

function ft_combobox_get_text(combobox: Pointer): PChar; cdecl; export;
begin
  if Assigned(combobox) and (TObject(combobox) is TFtComboBox) then
  begin
    gLastComboText := TFtComboBox(combobox).Text;
    Result := PChar(gLastComboText);
  end
  else
    Result := PChar('');
end;

procedure ft_combobox_set_placeholder(combobox: Pointer; placeholder: PChar); cdecl; export;
begin
  if Assigned(combobox) and (TObject(combobox) is TFtComboBox) and Assigned(placeholder) then
    TFtComboBox(combobox).Placeholder := StrPas(placeholder);
end;

function ft_combobox_get_placeholder(combobox: Pointer): PChar; cdecl; export;
begin
  if Assigned(combobox) and (TObject(combobox) is TFtComboBox) then
  begin
    gLastComboPlaceholder := TFtComboBox(combobox).Placeholder;
    Result := PChar(gLastComboPlaceholder);
  end
  else
    Result := PChar('');
end;

procedure ft_combobox_set_editable(combobox: Pointer; editable: cint32); cdecl; export;
begin
  if Assigned(combobox) and (TObject(combobox) is TFtComboBox) then
    TFtComboBox(combobox).Editable := (editable <> 0);
end;

function ft_combobox_get_editable(combobox: Pointer): cint32; cdecl; export;
begin
  if Assigned(combobox) and (TObject(combobox) is TFtComboBox) then
  begin
    if TFtComboBox(combobox).Editable then
      Result := 1
    else
      Result := 0;
  end
  else
    Result := 0;
end;

procedure ft_combobox_set_corner_radius(combobox: Pointer; radius: Double); cdecl; export;
begin
  if Assigned(combobox) and (TObject(combobox) is TFtComboBox) then
    TFtComboBox(combobox).CornerRadius := radius;
end;

function ft_combobox_get_corner_radius(combobox: Pointer): Double; cdecl; export;
begin
  if Assigned(combobox) and (TObject(combobox) is TFtComboBox) then
    Result := TFtComboBox(combobox).CornerRadius
  else
    Result := 0.0;
end;

procedure ft_combobox_popup(combobox: Pointer); cdecl; export;
begin
  if Assigned(combobox) and (TObject(combobox) is TFtComboBox) then
    TFtComboBox(combobox).Popup();
end;

procedure ft_combobox_on_change(combobox: Pointer; callback: TFtComboChangeCallback; user_data: Pointer); cdecl; export;
begin
  if Assigned(combobox) and (TObject(combobox) is TFtComboBox) then
  begin
    TFtComboBox(combobox).OnChange := callback;
    TFtComboBox(combobox).UserData := user_data;
  end;
end;

{ Slider Widgets }

function ft_slider_create(parent: Pointer; x, y, w, h: cint32; orientation: cint32): Pointer; cdecl; export;
var
  orient: TFtSliderOrientation;
  sl: TFtSlider;
begin
  if orientation = 1 then
    orient := ftSliderVertical
  else
    orient := ftSliderHorizontal;
  AdjustChildCoordinates(parent, x, y);
  sl := TFtSlider.Create(TFtWidget(parent), orient);
  sl.X := x;
  sl.Y := y;
  if w > 0 then sl.Width := w;
  if h > 0 then sl.Height := h;
  Result := Pointer(sl);
end;

procedure ft_slider_set_orientation(slider: Pointer; orientation: cint32); cdecl; export;
begin
  if Assigned(slider) and (TObject(slider) is TFtSlider) then
  begin
    if orientation = 1 then
      TFtSlider(slider).Orientation := ftSliderVertical
    else
      TFtSlider(slider).Orientation := ftSliderHorizontal;
  end;
end;

function ft_slider_get_orientation(slider: Pointer): cint32; cdecl; export;
begin
  if Assigned(slider) and (TObject(slider) is TFtSlider) then
    Result := Ord(TFtSlider(slider).Orientation)
  else
    Result := 0;
end;

procedure ft_slider_set_range(slider: Pointer; min, max: Double); cdecl; export;
begin
  if Assigned(slider) and (TObject(slider) is TFtSlider) then
  begin
    TFtSlider(slider).Min := min;
    TFtSlider(slider).Max := max;
  end;
end;

function ft_slider_get_min(slider: Pointer): Double; cdecl; export;
begin
  if Assigned(slider) and (TObject(slider) is TFtSlider) then
    Result := TFtSlider(slider).Min
  else
    Result := 0.0;
end;

function ft_slider_get_max(slider: Pointer): Double; cdecl; export;
begin
  if Assigned(slider) and (TObject(slider) is TFtSlider) then
    Result := TFtSlider(slider).Max
  else
    Result := 100.0;
end;

procedure ft_slider_set_value(slider: Pointer; value: Double); cdecl; export;
begin
  if Assigned(slider) and (TObject(slider) is TFtSlider) then
    TFtSlider(slider).Value := value;
end;

function ft_slider_get_value(slider: Pointer): Double; cdecl; export;
begin
  if Assigned(slider) and (TObject(slider) is TFtSlider) then
    Result := TFtSlider(slider).Value
  else
    Result := 0.0;
end;

procedure ft_slider_set_step(slider: Pointer; step: Double); cdecl; export;
begin
  if Assigned(slider) and (TObject(slider) is TFtSlider) then
    TFtSlider(slider).Step := step;
end;

function ft_slider_get_step(slider: Pointer): Double; cdecl; export;
begin
  if Assigned(slider) and (TObject(slider) is TFtSlider) then
    Result := TFtSlider(slider).Step
  else
    Result := 0.0;
end;

procedure ft_slider_set_thumb_size(slider: Pointer; thumb_size: Double); cdecl; export;
begin
  if Assigned(slider) and (TObject(slider) is TFtSlider) then
    TFtSlider(slider).ThumbSize := thumb_size;
end;

function ft_slider_get_thumb_size(slider: Pointer): Double; cdecl; export;
begin
  if Assigned(slider) and (TObject(slider) is TFtSlider) then
    Result := TFtSlider(slider).ThumbSize
  else
    Result := 18.0;
end;

procedure ft_slider_on_change(slider: Pointer; callback: TFtSliderChangeCallback; user_data: Pointer); cdecl; export;
begin
  if Assigned(slider) and (TObject(slider) is TFtSlider) then
  begin
    TFtSlider(slider).OnChange := callback;
    TFtSlider(slider).UserData := user_data;
  end;
end;

{ ProgressBar Widgets }

function ft_progressbar_create(parent: Pointer; x, y, w, h: cint32; orientation: cint32): Pointer; cdecl; export;
var
  orient: TFtProgressOrientation;
  pb: TFtProgressBar;
begin
  if orientation = 1 then
    orient := ftProgressVertical
  else
    orient := ftProgressHorizontal;
  AdjustChildCoordinates(parent, x, y);
  pb := TFtProgressBar.Create(TFtWidget(parent), orient);
  pb.X := x;
  pb.Y := y;
  if w > 0 then pb.Width := w;
  if h > 0 then pb.Height := h;
  Result := Pointer(pb);
end;

procedure ft_progressbar_set_orientation(progressbar: Pointer; orientation: cint32); cdecl; export;
begin
  if Assigned(progressbar) and (TObject(progressbar) is TFtProgressBar) then
  begin
    if orientation = 1 then
      TFtProgressBar(progressbar).Orientation := ftProgressVertical
    else
      TFtProgressBar(progressbar).Orientation := ftProgressHorizontal;
  end;
end;

function ft_progressbar_get_orientation(progressbar: Pointer): cint32; cdecl; export;
begin
  if Assigned(progressbar) and (TObject(progressbar) is TFtProgressBar) then
    Result := Ord(TFtProgressBar(progressbar).Orientation)
  else
    Result := 0;
end;

procedure ft_progressbar_set_range(progressbar: Pointer; min, max: Double); cdecl; export;
begin
  if Assigned(progressbar) and (TObject(progressbar) is TFtProgressBar) then
  begin
    TFtProgressBar(progressbar).Min := min;
    TFtProgressBar(progressbar).Max := max;
  end;
end;

function ft_progressbar_get_min(progressbar: Pointer): Double; cdecl; export;
begin
  if Assigned(progressbar) and (TObject(progressbar) is TFtProgressBar) then
    Result := TFtProgressBar(progressbar).Min
  else
    Result := 0.0;
end;

function ft_progressbar_get_max(progressbar: Pointer): Double; cdecl; export;
begin
  if Assigned(progressbar) and (TObject(progressbar) is TFtProgressBar) then
    Result := TFtProgressBar(progressbar).Max
  else
    Result := 100.0;
end;

procedure ft_progressbar_set_value(progressbar: Pointer; value: Double); cdecl; export;
begin
  if Assigned(progressbar) and (TObject(progressbar) is TFtProgressBar) then
    TFtProgressBar(progressbar).Value := value;
end;

function ft_progressbar_get_value(progressbar: Pointer): Double; cdecl; export;
begin
  if Assigned(progressbar) and (TObject(progressbar) is TFtProgressBar) then
    Result := TFtProgressBar(progressbar).Value
  else
    Result := 0.0;
end;

procedure ft_progressbar_set_indeterminate(progressbar: Pointer; indeterminate: cint32); cdecl; export;
begin
  if Assigned(progressbar) and (TObject(progressbar) is TFtProgressBar) then
    TFtProgressBar(progressbar).Indeterminate := (indeterminate <> 0);
end;

function ft_progressbar_get_indeterminate(progressbar: Pointer): cint32; cdecl; export;
begin
  if Assigned(progressbar) and (TObject(progressbar) is TFtProgressBar) then
  begin
    if TFtProgressBar(progressbar).Indeterminate then
      Result := 1
    else
      Result := 0;
  end
  else
    Result := 0;
end;

procedure ft_progressbar_set_show_text(progressbar: Pointer; show_text: cint32); cdecl; export;
begin
  if Assigned(progressbar) and (TObject(progressbar) is TFtProgressBar) then
    TFtProgressBar(progressbar).ShowText := (show_text <> 0);
end;

function ft_progressbar_get_show_text(progressbar: Pointer): cint32; cdecl; export;
begin
  if Assigned(progressbar) and (TObject(progressbar) is TFtProgressBar) then
  begin
    if TFtProgressBar(progressbar).ShowText then
      Result := 1
    else
      Result := 0;
  end
  else
    Result := 0;
end;

procedure ft_progressbar_set_text_format(progressbar: Pointer; format: PChar); cdecl; export;
begin
  if Assigned(progressbar) and (TObject(progressbar) is TFtProgressBar) and Assigned(format) then
    TFtProgressBar(progressbar).TextFormat := StrPas(format);
end;

function ft_progressbar_get_text_format(progressbar: Pointer): PChar; cdecl; export;
begin
  if Assigned(progressbar) and (TObject(progressbar) is TFtProgressBar) then
  begin
    gLastProgressFormat := TFtProgressBar(progressbar).TextFormat;
    Result := PChar(gLastProgressFormat);
  end
  else
    Result := PChar('');
end;

procedure ft_progressbar_set_corner_radius(progressbar: Pointer; radius: Double); cdecl; export;
begin
  if Assigned(progressbar) and (TObject(progressbar) is TFtProgressBar) then
    TFtProgressBar(progressbar).CornerRadius := radius;
end;

function ft_progressbar_get_corner_radius(progressbar: Pointer): Double; cdecl; export;
begin
  if Assigned(progressbar) and (TObject(progressbar) is TFtProgressBar) then
    Result := TFtProgressBar(progressbar).CornerRadius
  else
    Result := 0.0;
end;

{ --- Bitmap & Image API --- }

function ft_bitmap_create(AWidth, AHeight: cint32): Pointer; cdecl; export;
begin
  Result := TFtBitmap.Create(AWidth, AHeight);
end;

function ft_bitmap_load_file(AFilePath: PAnsiChar): Pointer; cdecl; export;
begin
  if (AFilePath = nil) or (AFilePath^ = #0) then
    Result := TFtBitmap.Create(0, 0)
  else
    Result := TFtBitmap.CreateFromFile(string(AFilePath));
end;

function ft_bitmap_load_memory(AData: Pointer; ASize: cint32): Pointer; cdecl; export;
begin
  if (AData = nil) or (ASize <= 0) then
    Result := TFtBitmap.Create(0, 0)
  else
    Result := TFtBitmap.CreateFromMemory(AData, ASize);
end;

function ft_bitmap_create_from_rgba(APixels: Pointer; AWidth, AHeight: cint32): Pointer; cdecl; export;
begin
  Result := TFtBitmap.CreateFromRGBA(APixels, AWidth, AHeight);
end;

function ft_bitmap_create_from_bgra(APixels: Pointer; AWidth, AHeight: cint32): Pointer; cdecl; export;
begin
  Result := TFtBitmap.CreateFromBGRA(APixels, AWidth, AHeight);
end;

function ft_bitmap_get_width(ABitmap: Pointer): cint32; cdecl; export;
begin
  if Assigned(ABitmap) and (TObject(ABitmap) is TFtBitmap) then
    Result := TFtBitmap(ABitmap).Width
  else
    Result := 0;
end;

function ft_bitmap_get_height(ABitmap: Pointer): cint32; cdecl; export;
begin
  if Assigned(ABitmap) and (TObject(ABitmap) is TFtBitmap) then
    Result := TFtBitmap(ABitmap).Height
  else
    Result := 0;
end;

function ft_bitmap_get_stride(ABitmap: Pointer): cint32; cdecl; export;
begin
  if Assigned(ABitmap) and (TObject(ABitmap) is TFtBitmap) then
    Result := TFtBitmap(ABitmap).Stride
  else
    Result := 0;
end;

function ft_bitmap_get_pixels(ABitmap: Pointer): Pointer; cdecl; export;
begin
  if Assigned(ABitmap) and (TObject(ABitmap) is TFtBitmap) then
    Result := TFtBitmap(ABitmap).PixelBuffer
  else
    Result := nil;
end;

function ft_bitmap_create_scaled(ABitmap: Pointer; ANewW, ANewH: cint32): Pointer; cdecl; export;
begin
  if Assigned(ABitmap) and (TObject(ABitmap) is TFtBitmap) then
    Result := TFtBitmap(ABitmap).CreateScaled(ANewW, ANewH)
  else
    Result := TFtBitmap.Create(0, 0);
end;

procedure ft_bitmap_destroy(ABitmap: Pointer); cdecl; export;
begin
  if Assigned(ABitmap) and (TObject(ABitmap) is TFtBitmap) then
    TFtBitmap(ABitmap).Free();
end;

{ --- Image Widget API --- }

function ft_image_create(AParent: Pointer; AX, AY, AW, AH: cint32; AFilePath: PAnsiChar): Pointer; cdecl; export;
var
  p: TFtWidget;
  pathStr: string;
begin
  AdjustChildCoordinates(AParent, AX, AY);
  p := TFtWidget(AParent);
  if AFilePath <> nil then
    pathStr := string(AFilePath)
  else
    pathStr := '';
  Result := TFtImage.Create(p, AX, AY, AW, AH, pathStr);
  if Assigned(AParent) and (TObject(AParent) is TFtContainer) then
    TFtContainer(AParent).UpdateScrollBars();
end;

procedure ft_image_load_file(AWidget: Pointer; AFilePath: PAnsiChar); cdecl; export;
begin
  if Assigned(AWidget) and (TObject(AWidget) is TFtImage) and (AFilePath <> nil) then
    TFtImage(AWidget).LoadFromFile(string(AFilePath));
end;

procedure ft_image_load_memory(AWidget: Pointer; AData: Pointer; ASize: cint32); cdecl; export;
begin
  if Assigned(AWidget) and (TObject(AWidget) is TFtImage) then
    TFtImage(AWidget).LoadFromMemory(AData, ASize);
end;

procedure ft_image_set_bitmap(AWidget: Pointer; ABitmap: Pointer; AOwnsBitmap: cint32); cdecl; export;
begin
  if Assigned(AWidget) and (TObject(AWidget) is TFtImage) then
    TFtImage(AWidget).SetBitmap(TFtBitmap(ABitmap), AOwnsBitmap <> 0);
end;

function ft_image_get_bitmap(AWidget: Pointer): Pointer; cdecl; export;
begin
  if Assigned(AWidget) and (TObject(AWidget) is TFtImage) then
    Result := TFtImage(AWidget).Bitmap
  else
    Result := nil;
end;

procedure ft_image_set_scale_mode(AWidget: Pointer; AMode: cint32); cdecl; export;
begin
  if Assigned(AWidget) and (TObject(AWidget) is TFtImage) then
  begin
    case AMode of
      1: TFtImage(AWidget).ScaleMode := ftismStretch;
      2: TFtImage(AWidget).ScaleMode := ftismCenter;
      3: TFtImage(AWidget).ScaleMode := ftismNone;
      else TFtImage(AWidget).ScaleMode := ftismFit;
    end;
    TFtWidget(AWidget).Invalidate();
  end;
end;

function ft_image_get_scale_mode(AWidget: Pointer): cint32; cdecl; export;
begin
  if Assigned(AWidget) and (TObject(AWidget) is TFtImage) then
    Result := Ord(TFtImage(AWidget).ScaleMode)
  else
    Result := 0;
end;

procedure ft_image_set_opacity(AWidget: Pointer; AOpacity: cdouble); cdecl; export;
begin
  if Assigned(AWidget) and (TObject(AWidget) is TFtImage) then
  begin
    TFtImage(AWidget).Opacity := AOpacity;
    TFtWidget(AWidget).Invalidate();
  end;
end;

function ft_image_get_opacity(AWidget: Pointer): cdouble; cdecl; export;
begin
  if Assigned(AWidget) and (TObject(AWidget) is TFtImage) then
    Result := TFtImage(AWidget).Opacity
  else
    Result := 1.0;
end;

{ --- Canvas Direct Image Drawing API --- }

procedure ft_canvas_draw_image(ACanvas: Pointer; AX, AY: cdouble; ABitmap: Pointer; AOpacity: cdouble); cdecl; export;
begin
  if Assigned(ACanvas) and Assigned(ABitmap) and (TObject(ACanvas) is TFtCanvasAgg) and (TObject(ABitmap) is TFtBitmap) then
    TFtCanvasAgg(ACanvas).DrawImage(AX, AY, TFtBitmap(ABitmap), AOpacity);
end;

procedure ft_canvas_draw_image_scaled(ACanvas: Pointer; AX, AY, AW, AH: cdouble; ABitmap: Pointer; AOpacity: cdouble); cdecl; export;
begin
  if Assigned(ACanvas) and Assigned(ABitmap) and (TObject(ACanvas) is TFtCanvasAgg) and (TObject(ABitmap) is TFtBitmap) then
    TFtCanvasAgg(ACanvas).DrawImageScaled(AX, AY, AW, AH, TFtBitmap(ABitmap), AOpacity);
end;

procedure ft_canvas_draw_image_part(ACanvas: Pointer; AX, AY, AW, AH: cdouble; ABitmap: Pointer; ASrcX, ASrcY, ASrcW, ASrcH: cint32; AOpacity: cdouble); cdecl; export;
begin
  if Assigned(ACanvas) and Assigned(ABitmap) and (TObject(ACanvas) is TFtCanvasAgg) and (TObject(ABitmap) is TFtBitmap) then
    TFtCanvasAgg(ACanvas).DrawImagePart(AX, AY, AW, AH, TFtBitmap(ABitmap), ASrcX, ASrcY, ASrcW, ASrcH, AOpacity);
end;

procedure ft_canvas_push_alpha(ACanvas: Pointer; AAlpha: cdouble); cdecl; export;
begin
  if Assigned(ACanvas) and (TObject(ACanvas) is TFtCanvasAgg) then
    TFtCanvasAgg(ACanvas).PushAlpha(AAlpha);
end;

procedure ft_canvas_pop_alpha(ACanvas: Pointer); cdecl; export;
begin
  if Assigned(ACanvas) and (TObject(ACanvas) is TFtCanvasAgg) then
    TFtCanvasAgg(ACanvas).PopAlpha();
end;

procedure ft_canvas_reset_alpha(ACanvas: Pointer); cdecl; export;
begin
  if Assigned(ACanvas) and (TObject(ACanvas) is TFtCanvasAgg) then
    TFtCanvasAgg(ACanvas).ResetAlpha();
end;

function ft_canvas_get_alpha(ACanvas: Pointer): cdouble; cdecl; export;
begin
  if Assigned(ACanvas) and (TObject(ACanvas) is TFtCanvasAgg) then
    Result := TFtCanvasAgg(ACanvas).CurrentAlpha
  else
    Result := 1.0;
end;

exports
  ft_init,
  ft_main_loop,
  ft_quit,
  ft_window_create,
  ft_window_set_title,
  ft_window_set_borderless,
  ft_window_get_borderless,
  ft_window_set_skip_taskbar,
  ft_window_get_skip_taskbar,
  ft_window_set_window_type,
  ft_window_get_window_type,
  ft_window_set_position,
  ft_window_get_position,
  ft_window_set_opacity,
  ft_window_get_opacity,
  ft_window_set_background_opacity,
  ft_window_get_background_opacity,
  ft_window_set_background_blur,
  ft_window_get_background_blur,
  ft_widget_show,
  ft_widget_hide,
  ft_widget_set_focus,
  ft_widget_has_focus,
  ft_widget_set_focusable,
  ft_widget_get_focusable,
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
  ft_clipboard_get_text,
  ft_entry_create,
  ft_entry_set_text,
  ft_entry_get_text,
  ft_entry_set_placeholder,
  ft_entry_get_placeholder,
  ft_entry_set_readonly,
  ft_entry_get_readonly,
  ft_entry_on_change,
  ft_entry_on_submit,
  ft_entry_set_corner_radius,
  ft_textarea_create,
  ft_textarea_set_text,
  ft_textarea_get_text,
  ft_textarea_set_placeholder,
  ft_textarea_get_placeholder,
  ft_textarea_set_readonly,
  ft_textarea_get_readonly,
  ft_textarea_on_change,
  ft_textarea_set_corner_radius,
  ft_textarea_set_scrollbar_mode,
  ft_textarea_get_scrollbar_mode,
  ft_textarea_get_vscrollbar,
  ft_textarea_get_hscrollbar,
  ft_scrollbar_create,
  ft_scrollbar_set_orientation,
  ft_scrollbar_get_orientation,
  ft_scrollbar_set_range,
  ft_scrollbar_set_value,
  ft_scrollbar_get_value,
  ft_scrollbar_get_min,
  ft_scrollbar_get_max,
  ft_scrollbar_get_page_size,
  ft_scrollbar_set_step,
  ft_scrollbar_get_step,
  ft_scrollbar_on_scroll,
  ft_scrollbar_set_corner_radius,
  ft_container_create,
  ft_container_set_scrollbar_mode,
  ft_container_get_scrollbar_mode,
  ft_container_set_content_size,
  ft_container_get_content_size,
  ft_container_set_scroll_pos,
  ft_container_get_scroll_x,
  ft_container_get_scroll_y,
  ft_container_set_corner_radius,
  ft_container_get_corner_radius,
  ft_container_set_backdrop_blur,
  ft_container_get_backdrop_blur,
  ft_container_set_padding,
  ft_container_set_draw_frame,
  ft_container_get_draw_frame,
  ft_container_set_draw_focus_ring,
  ft_container_get_draw_focus_ring,
  ft_container_set_auto_content_size,
  ft_container_get_auto_content_size,
  ft_container_get_vscrollbar,
  ft_container_get_hscrollbar,
  ft_container_on_scroll,
  ft_container_get_client_rect,
  ft_container_update_scrollbars,
  ft_checkbox_create,
  ft_checkbox_set_checked,
  ft_checkbox_get_checked,
  ft_checkbox_toggle,
  ft_checkbox_set_caption,
  ft_checkbox_get_caption,
  ft_checkbox_set_corner_radius,
  ft_checkbox_get_corner_radius,
  ft_checkbox_on_toggle,
  ft_radio_create,
  ft_radio_set_checked,
  ft_radio_get_checked,
  ft_radio_set_group,
  ft_radio_get_group,
  ft_radio_set_caption,
  ft_radio_get_caption,
  ft_radio_on_toggle,
  ft_combobox_create,
  ft_combobox_add_item,
  ft_combobox_clear,
  ft_combobox_get_item_count,
  ft_combobox_get_item,
  ft_combobox_set_selected,
  ft_combobox_get_selected,
  ft_combobox_get_selected_text,
  ft_combobox_set_text,
  ft_combobox_get_text,
  ft_combobox_set_placeholder,
  ft_combobox_get_placeholder,
  ft_combobox_set_editable,
  ft_combobox_get_editable,
  ft_combobox_set_corner_radius,
  ft_combobox_get_corner_radius,
  ft_combobox_popup,
  ft_combobox_on_change,
  ft_slider_create,
  ft_slider_set_orientation,
  ft_slider_get_orientation,
  ft_slider_set_range,
  ft_slider_get_min,
  ft_slider_get_max,
  ft_slider_set_value,
  ft_slider_get_value,
  ft_slider_set_step,
  ft_slider_get_step,
  ft_slider_set_thumb_size,
  ft_slider_get_thumb_size,
  ft_slider_on_change,
  ft_progressbar_create,
  ft_progressbar_set_orientation,
  ft_progressbar_get_orientation,
  ft_progressbar_set_range,
  ft_progressbar_get_min,
  ft_progressbar_get_max,
  ft_progressbar_set_value,
  ft_progressbar_get_value,
  ft_progressbar_set_indeterminate,
  ft_progressbar_get_indeterminate,
  ft_progressbar_set_show_text,
  ft_progressbar_get_show_text,
  ft_progressbar_set_text_format,
  ft_progressbar_get_text_format,
  ft_progressbar_set_corner_radius,
  ft_progressbar_get_corner_radius,
  ft_main_menu_create,
  ft_main_menu_add_menu,
  ft_main_menu_add_item,
  ft_main_menu_item_count,
  ft_main_menu_get_item,
  ft_main_menu_close,
  ft_popup_menu_create,
  ft_popup_menu_add_item,
  ft_popup_menu_add_check_item,
  ft_popup_menu_add_separator,
  ft_popup_menu_add_submenu,
  ft_popup_menu_item_count,
  ft_popup_menu_get_item,
  ft_popup_menu_show,
  ft_popup_menu_close,
  ft_popup_menu_clear,
  ft_popup_menu_set_corner_radius,
  ft_menu_item_set_caption,
  ft_menu_item_get_caption,
  ft_menu_item_set_shortcut,
  ft_menu_item_get_shortcut,
  ft_menu_item_set_enabled,
  ft_menu_item_get_enabled,
  ft_menu_item_set_checked,
  ft_menu_item_get_checked,
  ft_menu_item_set_checkable,
  ft_menu_item_get_checkable,
  ft_menu_item_set_submenu,
  ft_menu_item_get_submenu,
  ft_menu_item_on_click,
  ft_menu_item_set_tag,
  ft_menu_item_get_tag,
  ft_widget_set_context_menu,
  ft_widget_get_context_menu,
  ft_window_set_context_menu,
  ft_window_get_context_menu,
  ft_window_set_main_menu,
  ft_window_get_main_menu,
  ft_widget_set_style_class,
  ft_widget_get_style_class,
  ft_widget_set_style_id,
  ft_widget_get_style_id,
  ft_widget_set_style,
  ft_widget_get_style,
  ft_widget_set_opacity,
  ft_widget_get_opacity,
  ft_style_load_css_file,
  ft_style_load_css_string,
  ft_animation_is_running,
  ft_bitmap_create,
  ft_bitmap_load_file,
  ft_bitmap_load_memory,
  ft_bitmap_create_from_rgba,
  ft_bitmap_create_from_bgra,
  ft_bitmap_get_width,
  ft_bitmap_get_height,
  ft_bitmap_get_stride,
  ft_bitmap_get_pixels,
  ft_bitmap_create_scaled,
  ft_bitmap_destroy,
  ft_image_create,
  ft_image_load_file,
  ft_image_load_memory,
  ft_image_set_bitmap,
  ft_image_get_bitmap,
  ft_image_set_scale_mode,
  ft_image_get_scale_mode,
  ft_image_set_opacity,
  ft_image_get_opacity,
  ft_canvas_draw_image,
  ft_canvas_draw_image_scaled,
  ft_canvas_draw_image_part,
  ft_canvas_push_alpha,
  ft_canvas_pop_alpha,
  ft_canvas_reset_alpha,
  ft_canvas_get_alpha;

begin
end.
