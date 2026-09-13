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
  Ft.Widget.Entries,
  Ft.Widget.TextAreas,
  Ft.Widget.ScrollBars,
  Ft.Widget.Containers,
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
  gLastEntryText: AnsiString;
  gLastEntryPlaceholder: AnsiString;
  gLastTextAreaText: AnsiString;
  gLastTextAreaPlaceholder: AnsiString;

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

exports
  ft_init,
  ft_main_loop,
  ft_quit,
  ft_window_create,
  ft_window_set_title,
  ft_widget_show,
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
  ft_container_update_scrollbars;

begin
end.
