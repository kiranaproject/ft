unit Ft.Widget.Selectors;

{$mode objfpc}{$H+}

interface

uses
  ctypes, SysUtils, Classes, Math, Ft.Canvas.Agg, Ft.Font, Ft.Widget, Ft.Theme, Ft.Css,
  Ft.Widget.Menus, Ft.Backend.X11;

type
  { CheckBox Callbacks }
  TFtCheckCallback = procedure(Sender: Pointer; Checked: cint32; UserData: Pointer); cdecl;

  { RadioButton Callbacks }
  TFtRadioCallback = procedure(Sender: Pointer; Checked: cint32; UserData: Pointer); cdecl;

  { ComboBox Callbacks }
  TFtComboChangeCallback = procedure(Sender: Pointer; SelectedIndex: cint32; Text: PChar; UserData: Pointer); cdecl;

  { TFtCheckBox }
  TFtCheckBox = class(TFtWidget)
  private
    FChecked: Boolean;
    FState: TFtButtonState;
    FIsMouseDown: Boolean;
    FCornerRadius: Double;
    FCaption: string;
    FOnToggle: TFtCheckCallback;
    FUserData: Pointer;
    procedure SetChecked(AValue: Boolean);
    procedure SetCaption(const AValue: string);
    procedure SetCornerRadius(AValue: Double);
  public
    constructor Create(AParent: TFtWidget); override;

    procedure Draw(Canvas: TFtCanvasAgg); override;
    procedure Click(); override;
    procedure MouseEnter(); override;
    procedure MouseLeave(); override;
    procedure MouseDown(AX, AY: Integer; AButton: Integer); override;
    procedure MouseUp(AX, AY: Integer; AButton: Integer); override;
    procedure KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string); override;

    procedure Toggle();
    function GetElementType(): string; override;
    function GetStatePseudoClass(): string; override;

    property Checked: Boolean read FChecked write SetChecked;
    property Caption: string read FCaption write SetCaption;
    property State: TFtButtonState read FState;
    property CornerRadius: Double read FCornerRadius write SetCornerRadius;
    property OnToggle: TFtCheckCallback read FOnToggle write FOnToggle;
    property UserData: Pointer read FUserData write FUserData;
  end;

  { TFtRadioButton }
  TFtRadioButton = class(TFtWidget)
  private
    FChecked: Boolean;
    FState: TFtButtonState;
    FIsMouseDown: Boolean;
    FGroupId: Integer;
    FCaption: string;
    FOnToggle: TFtRadioCallback;
    FUserData: Pointer;
    procedure SetChecked(AValue: Boolean);
    procedure SetCaption(const AValue: string);
    procedure SetGroupId(AValue: Integer);
    procedure UncheckOthersInGroup();
  public
    constructor Create(AParent: TFtWidget); override;

    procedure Draw(Canvas: TFtCanvasAgg); override;
    procedure Click(); override;
    procedure MouseEnter(); override;
    procedure MouseLeave(); override;
    procedure MouseDown(AX, AY: Integer; AButton: Integer); override;
    procedure MouseUp(AX, AY: Integer; AButton: Integer); override;
    procedure KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string); override;

    function GetElementType(): string; override;
    function GetStatePseudoClass(): string; override;

    property Checked: Boolean read FChecked write SetChecked;
    property Caption: string read FCaption write SetCaption;
    property GroupId: Integer read FGroupId write SetGroupId;
    property State: TFtButtonState read FState;
    property OnToggle: TFtRadioCallback read FOnToggle write FOnToggle;
    property UserData: Pointer read FUserData write FUserData;
  end;

  { TFtComboBox }
  TFtComboBox = class(TFtWidget)
  private
    FItems: TStringList;
    FSelectedIndex: Integer;
    FText: string;
    FPlaceholder: string;
    FEditable: Boolean;
    FState: TFtButtonState;
    FIsMouseDown: Boolean;
    FCornerRadius: Double;
    FPopupMenu: TFtPopupMenu;
    FOnChange: TFtComboChangeCallback;
    FUserData: Pointer;
    procedure SetSelectedIndex(AValue: Integer);
    procedure SetText(const AValue: string);
    procedure SetPlaceholder(const AValue: string);
    procedure SetCornerRadius(AValue: Double);
    procedure RebuildPopupMenu();
    procedure HandleItemClick(Sender: TObject);
  public
    constructor Create(AParent: TFtWidget); override;
    destructor Destroy(); override;

    procedure Draw(Canvas: TFtCanvasAgg); override;
    procedure Click(); override;
    procedure MouseEnter(); override;
    procedure MouseLeave(); override;
    procedure MouseDown(AX, AY: Integer; AButton: Integer); override;
    procedure MouseUp(AX, AY: Integer; AButton: Integer); override;
    procedure KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string); override;

    function AddItem(const AItem: string): Integer;
    procedure Clear();
    function GetItem(AIndex: Integer): string;
    function GetItemCount(): Integer;
    procedure Popup();

    function GetElementType(): string; override;
    function GetStatePseudoClass(): string; override;

    property Items: TStringList read FItems;
    property SelectedIndex: Integer read FSelectedIndex write SetSelectedIndex;
    property Text: string read FText write SetText;
    property Placeholder: string read FPlaceholder write SetPlaceholder;
    property Editable: Boolean read FEditable write FEditable;
    property CornerRadius: Double read FCornerRadius write SetCornerRadius;
    property OnChange: TFtComboChangeCallback read FOnChange write FOnChange;
    property UserData: Pointer read FUserData write FUserData;
  end;

implementation

function GetWidgetScreenPosition(AWidget: TFtWidget): TPoint;
var
  rootWin: TFtWidget;
begin
  if Assigned(AWidget) then
  begin
    rootWin := AWidget.GetRootWidget();
    if Assigned(rootWin) and (rootWin is TFtX11Window) then
      Exit(TFtX11Window(rootWin).ClientToScreen(AWidget.X, AWidget.Y));
    Result.X := AWidget.X;
    Result.Y := AWidget.Y;
  end
  else
  begin
    Result.X := 0;
    Result.Y := 0;
  end;
end;

{ TFtCheckBox }

constructor TFtCheckBox.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FFocusable := True;
  FChecked := False;
  FState := bsNormal;
  FIsMouseDown := False;
  FCornerRadius := 4.0;
  FCaption := '';
  FOnToggle := nil;
  FUserData := nil;
  Width := 120;
  Height := 24;
end;

procedure TFtCheckBox.SetCaption(const AValue: string);
begin
  if FCaption <> AValue then
  begin
    FCaption := AValue;
    Invalidate();
  end;
end;

procedure TFtCheckBox.SetCornerRadius(AValue: Double);
begin
  if Abs(FCornerRadius - AValue) > 1e-4 then
  begin
    FCornerRadius := AValue;
    Invalidate();
  end;
end;

procedure TFtCheckBox.SetChecked(AValue: Boolean);
begin
  if FChecked <> AValue then
  begin
    FChecked := AValue;
    InvalidateStyle();
    Invalidate();
    if Assigned(FOnToggle) then
    begin
      if FChecked then
        FOnToggle(Pointer(Self), 1, FUserData)
      else
        FOnToggle(Pointer(Self), 0, FUserData);
    end;
  end;
end;

procedure TFtCheckBox.Toggle();
begin
  Checked := not FChecked;
end;

procedure TFtCheckBox.Click();
begin
  inherited Click();
  Toggle();
end;

function TFtCheckBox.GetElementType(): string;
begin
  Result := 'checkbox';
end;

function TFtCheckBox.GetStatePseudoClass(): string;
begin
  if not FEnabled then
    Result := ':disabled'
  else if FChecked then
    Result := ':checked'
  else if FState = bsPressed then
    Result := ':active'
  else if FState = bsHovered then
    Result := ':hover'
  else if FFocused then
    Result := ':focus'
  else
    Result := '';
end;

procedure TFtCheckBox.MouseEnter();
begin
  inherited MouseEnter();
  if FState <> bsPressed then
  begin
    FState := bsHovered;
    InvalidateStyle();
    Invalidate();
  end;
end;

procedure TFtCheckBox.MouseLeave();
begin
  inherited MouseLeave();
  FIsMouseDown := False;
  if FState <> bsNormal then
  begin
    FState := bsNormal;
    InvalidateStyle();
    Invalidate();
  end;
end;

procedure TFtCheckBox.MouseDown(AX, AY: Integer; AButton: Integer);
begin
  inherited MouseDown(AX, AY, AButton);
  if (AButton = 1) and FEnabled then
  begin
    FIsMouseDown := True;
    FState := bsPressed;
    InvalidateStyle();
    Invalidate();
  end;
end;

procedure TFtCheckBox.MouseUp(AX, AY: Integer; AButton: Integer);
begin
  inherited MouseUp(AX, AY, AButton);
  if (AButton = 1) and FIsMouseDown and FEnabled then
  begin
    FIsMouseDown := False;
    if (AX >= X) and (AX < X + Width) and (AY >= Y) and (AY < Y + Height) then
      FState := bsHovered
    else
      FState := bsNormal;
    InvalidateStyle();
    Invalidate();
  end;
end;

procedure TFtCheckBox.KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string);
begin
  inherited KeyDown(AKeySym, AState, AChar);
  if not FEnabled then Exit;
  if (AKeySym = 32) or (AKeySym = $FF0D) or (AKeySym = $FF8D) then // Space or Return/KP_Enter
    Click();
end;

procedure TFtCheckBox.Draw(Canvas: TFtCanvasAgg);
var
  st: TFtWidgetStyle;
  boxSize, boxX, boxY, rad: Double;
  bgR, bgG, bgB, bgA: Double;
  bdR, bdG, bdB, bdA: Double;
  txR, txG, txB: Double;
  bw: Double;
  fnt: TFtFont;
  accent: TFtRgbColor;
begin
  if not Visible then Exit;

  st := GetResolvedStyle();
  boxSize := 18.0;
  boxX := X + 2.0;
  boxY := Y + (Height - boxSize) / 2.0;

  if FCornerRadius >= 0.0 then
    rad := FCornerRadius
  else if st.HasBorderRadius then
    rad := st.BorderRadius
  else
    rad := 4.0;

  accent := FtGetTheme().GetAccentColor();

  // Resolve Box Colors
  if FChecked then
  begin
    if st.HasBgColor then
    begin
      bgR := st.BgColor.R; bgG := st.BgColor.G; bgB := st.BgColor.B; bgA := st.BgColor.A;
    end
    else
    begin
      bgR := accent.R; bgG := accent.G; bgB := accent.B; bgA := 1.0;
    end;

    if st.HasBorderColor then
    begin
      bdR := st.BorderColor.R; bdG := st.BorderColor.G; bdB := st.BorderColor.B; bdA := st.BorderColor.A;
    end
    else
    begin
      bdR := bgR * 0.85; bdG := bgG * 0.85; bdB := bgB * 0.85; bdA := 1.0;
    end;
  end
  else
  begin
    if st.HasBgColor then
    begin
      bgR := st.BgColor.R; bgG := st.BgColor.G; bgB := st.BgColor.B; bgA := st.BgColor.A;
    end
    else if FtGetDarkMode() then
    begin
      bgR := 0.16; bgG := 0.18; bgB := 0.20; bgA := 1.0;
    end
    else
    begin
      bgR := 1.0; bgG := 1.0; bgB := 1.0; bgA := 1.0;
    end;

    if st.HasBorderColor then
    begin
      bdR := st.BorderColor.R; bdG := st.BorderColor.G; bdB := st.BorderColor.B; bdA := st.BorderColor.A;
    end
    else if FtGetDarkMode() then
    begin
      bdR := 0.35; bdG := 0.38; bdB := 0.42; bdA := 1.0;
    end
    else
    begin
      bdR := 0.75; bdG := 0.78; bdB := 0.82; bdA := 1.0;
    end;
  end;

  bw := 1.2;
  if st.HasBorderWidth then bw := st.BorderWidth;

  // Draw Box Plate
  Canvas.DrawRoundedRect(boxX, boxY, boxSize, boxSize, rad, bgR, bgG, bgB, bgA);
  Canvas.DrawRoundedRectOutline(boxX, boxY, boxSize, boxSize, rad, bw, bdR, bdG, bdB, bdA);

  // Draw Checkmark if Checked
  if FChecked then
  begin
    // Checkmark legs: (boxX+4, boxY+9.5) -> (boxX+7.5, boxY+13.5) -> (boxX+14, boxY+5.5)
    Canvas.DrawLine(boxX + 4.0, boxY + 9.5, boxX + 7.5, boxY + 13.5, 2.2, 1.0, 1.0, 1.0, 1.0);
    Canvas.DrawLine(boxX + 7.5, boxY + 13.5, boxX + 14.0, boxY + 5.5, 2.2, 1.0, 1.0, 1.0, 1.0);
  end;

  // Draw Focus Ring
  if FFocused then
    FtGetTheme().DrawFocusRing(Canvas, boxX, boxY, boxSize, boxSize, rad);

  // Draw Caption Label
  if FCaption <> '' then
  begin
    if st.HasTextColor then
    begin
      txR := st.TextColor.R; txG := st.TextColor.G; txB := st.TextColor.B;
    end
    else
    begin
      accent := FtGetTheme().GetTextColor();
      txR := accent.R; txG := accent.G; txB := accent.B;
    end;

    fnt := GetFont();
    Canvas.DrawTextLeft(boxX + boxSize + 8.0, Y, Width - (boxSize + 10.0), Height, FCaption, fnt, txR, txG, txB);
  end;
end;

{ TFtRadioButton }

constructor TFtRadioButton.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FFocusable := True;
  FChecked := False;
  FState := bsNormal;
  FIsMouseDown := False;
  FGroupId := 0;
  FCaption := '';
  FOnToggle := nil;
  FUserData := nil;
  Width := 120;
  Height := 24;
end;

procedure TFtRadioButton.SetCaption(const AValue: string);
begin
  if FCaption <> AValue then
  begin
    FCaption := AValue;
    Invalidate();
  end;
end;

procedure TFtRadioButton.SetGroupId(AValue: Integer);
begin
  if FGroupId <> AValue then
  begin
    FGroupId := AValue;
    Invalidate();
  end;
end;

procedure TFtRadioButton.UncheckOthersInGroup();
var
  i: Integer;
  child: TFtWidget;
  radio: TFtRadioButton;
begin
  if not Assigned(Parent) then Exit;
  for i := 0 to Parent.Children.Count - 1 do
  begin
    child := TFtWidget(Parent.Children[i]);
    if (child is TFtRadioButton) and (child <> Self) then
    begin
      radio := TFtRadioButton(child);
      if (radio.GroupId = FGroupId) and radio.Checked then
      begin
        radio.FChecked := False;
        radio.InvalidateStyle();
        radio.Invalidate();
        if Assigned(radio.FOnToggle) then
          radio.FOnToggle(Pointer(radio), 0, radio.FUserData);
      end;
    end;
  end;
end;

procedure TFtRadioButton.SetChecked(AValue: Boolean);
begin
  if FChecked <> AValue then
  begin
    FChecked := AValue;
    if FChecked then
      UncheckOthersInGroup();
    InvalidateStyle();
    Invalidate();
    if Assigned(FOnToggle) then
    begin
      if FChecked then
        FOnToggle(Pointer(Self), 1, FUserData)
      else
        FOnToggle(Pointer(Self), 0, FUserData);
    end;
  end;
end;

procedure TFtRadioButton.Click();
begin
  inherited Click();
  if not FChecked then
    Checked := True;
end;

function TFtRadioButton.GetElementType(): string;
begin
  Result := 'radio';
end;

function TFtRadioButton.GetStatePseudoClass(): string;
begin
  if not FEnabled then
    Result := ':disabled'
  else if FChecked then
    Result := ':checked'
  else if FState = bsPressed then
    Result := ':active'
  else if FState = bsHovered then
    Result := ':hover'
  else if FFocused then
    Result := ':focus'
  else
    Result := '';
end;

procedure TFtRadioButton.MouseEnter();
begin
  inherited MouseEnter();
  if FState <> bsPressed then
  begin
    FState := bsHovered;
    InvalidateStyle();
    Invalidate();
  end;
end;

procedure TFtRadioButton.MouseLeave();
begin
  inherited MouseLeave();
  FIsMouseDown := False;
  if FState <> bsNormal then
  begin
    FState := bsNormal;
    InvalidateStyle();
    Invalidate();
  end;
end;

procedure TFtRadioButton.MouseDown(AX, AY: Integer; AButton: Integer);
begin
  inherited MouseDown(AX, AY, AButton);
  if (AButton = 1) and FEnabled then
  begin
    FIsMouseDown := True;
    FState := bsPressed;
    InvalidateStyle();
    Invalidate();
  end;
end;

procedure TFtRadioButton.MouseUp(AX, AY: Integer; AButton: Integer);
begin
  inherited MouseUp(AX, AY, AButton);
  if (AButton = 1) and FIsMouseDown and FEnabled then
  begin
    FIsMouseDown := False;
    if (AX >= X) and (AX < X + Width) and (AY >= Y) and (AY < Y + Height) then
      FState := bsHovered
    else
      FState := bsNormal;
    InvalidateStyle();
    Invalidate();
  end;
end;

procedure TFtRadioButton.KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string);
begin
  inherited KeyDown(AKeySym, AState, AChar);
  if not FEnabled then Exit;
  if (AKeySym = 32) or (AKeySym = $FF0D) or (AKeySym = $FF8D) then
    Click();
end;

procedure TFtRadioButton.Draw(Canvas: TFtCanvasAgg);
var
  st: TFtWidgetStyle;
  diameter, circleX, circleY, centerX, centerY, radius: Double;
  bgR, bgG, bgB, bgA: Double;
  bdR, bdG, bdB, bdA: Double;
  bulletR, bulletG, bulletB: Double;
  txR, txG, txB: Double;
  bw: Double;
  fnt: TFtFont;
  accent: TFtRgbColor;
begin
  if not Visible then Exit;

  st := GetResolvedStyle();
  diameter := 18.0;
  radius := diameter / 2.0;
  circleX := X + 2.0;
  circleY := Y + (Height - diameter) / 2.0;
  centerX := circleX + radius;
  centerY := circleY + radius;

  accent := FtGetTheme().GetAccentColor();

  if FChecked then
  begin
    if st.HasBorderColor then
    begin
      bdR := st.BorderColor.R; bdG := st.BorderColor.G; bdB := st.BorderColor.B; bdA := st.BorderColor.A;
    end
    else
    begin
      bdR := accent.R; bdG := accent.G; bdB := accent.B; bdA := 1.0;
    end;

    bulletR := bdR; bulletG := bdG; bulletB := bdB;
  end
  else
  begin
    if st.HasBorderColor then
    begin
      bdR := st.BorderColor.R; bdG := st.BorderColor.G; bdB := st.BorderColor.B; bdA := st.BorderColor.A;
    end
    else if FtGetDarkMode() then
    begin
      bdR := 0.35; bdG := 0.38; bdB := 0.42; bdA := 1.0;
    end
    else
    begin
      bdR := 0.75; bdG := 0.78; bdB := 0.82; bdA := 1.0;
    end;

    bulletR := 0.0; bulletG := 0.0; bulletB := 0.0;
  end;

  if st.HasBgColor then
  begin
    bgR := st.BgColor.R; bgG := st.BgColor.G; bgB := st.BgColor.B; bgA := st.BgColor.A;
  end
  else if FtGetDarkMode() then
  begin
    bgR := 0.16; bgG := 0.18; bgB := 0.20; bgA := 1.0;
  end
  else
  begin
    bgR := 1.0; bgG := 1.0; bgB := 1.0; bgA := 1.0;
  end;

  bw := 1.5;
  if st.HasBorderWidth then bw := st.BorderWidth;

  // Outer circle plate
  Canvas.DrawCircle(centerX, centerY, radius, bgR, bgG, bgB, bgA);
  Canvas.DrawCircleOutline(centerX, centerY, radius, bw, bdR, bdG, bdB, bdA);

  // Inner bullet if checked
  if FChecked then
    Canvas.DrawCircle(centerX, centerY, 4.5, bulletR, bulletG, bulletB, 1.0);

  // Focus Ring
  if FFocused then
    FtGetTheme().DrawFocusRing(Canvas, circleX, circleY, diameter, diameter, radius);

  // Caption Label
  if FCaption <> '' then
  begin
    if st.HasTextColor then
    begin
      txR := st.TextColor.R; txG := st.TextColor.G; txB := st.TextColor.B;
    end
    else
    begin
      accent := FtGetTheme().GetTextColor();
      txR := accent.R; txG := accent.G; txB := accent.B;
    end;

    fnt := GetFont();
    Canvas.DrawTextLeft(circleX + diameter + 8.0, Y, Width - (diameter + 10.0), Height, FCaption, fnt, txR, txG, txB);
  end;
end;

{ TFtComboBox }

constructor TFtComboBox.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FFocusable := True;
  FItems := TStringList.Create();
  FSelectedIndex := -1;
  FText := '';
  FPlaceholder := 'Select...';
  FEditable := False;
  FState := bsNormal;
  FIsMouseDown := False;
  FCornerRadius := 6.0;
  FPopupMenu := nil;
  FOnChange := nil;
  FUserData := nil;
  Width := 160;
  Height := 32;
end;

destructor TFtComboBox.Destroy();
begin
  FreeAndNil(FItems);
  if Assigned(FPopupMenu) then
    FreeAndNil(FPopupMenu);
  inherited Destroy();
end;

procedure TFtComboBox.SetSelectedIndex(AValue: Integer);
begin
  if (AValue >= -1) and (AValue < FItems.Count) and (FSelectedIndex <> AValue) then
  begin
    FSelectedIndex := AValue;
    if (FSelectedIndex >= 0) and (FSelectedIndex < FItems.Count) then
      FText := FItems[FSelectedIndex];
    Invalidate();
    if Assigned(FOnChange) then
      FOnChange(Pointer(Self), FSelectedIndex, PChar(FText), FUserData);
  end;
end;

procedure TFtComboBox.SetText(const AValue: string);
begin
  if FText <> AValue then
  begin
    FText := AValue;
    FSelectedIndex := FItems.IndexOf(FText);
    Invalidate();
    if Assigned(FOnChange) then
      FOnChange(Pointer(Self), FSelectedIndex, PChar(FText), FUserData);
  end;
end;

procedure TFtComboBox.SetPlaceholder(const AValue: string);
begin
  if FPlaceholder <> AValue then
  begin
    FPlaceholder := AValue;
    Invalidate();
  end;
end;

procedure TFtComboBox.SetCornerRadius(AValue: Double);
begin
  if Abs(FCornerRadius - AValue) > 1e-4 then
  begin
    FCornerRadius := AValue;
    Invalidate();
  end;
end;

function TFtComboBox.AddItem(const AItem: string): Integer;
begin
  Result := FItems.Add(AItem);
  if (FSelectedIndex = -1) and (FItems.Count = 1) then
  begin
    FSelectedIndex := 0;
    FText := AItem;
  end;
  Invalidate();
end;

procedure TFtComboBox.Clear();
begin
  FItems.Clear();
  FSelectedIndex := -1;
  FText := '';
  Invalidate();
end;

function TFtComboBox.GetItem(AIndex: Integer): string;
begin
  if (AIndex >= 0) and (AIndex < FItems.Count) then
    Result := FItems[AIndex]
  else
    Result := '';
end;

function TFtComboBox.GetItemCount(): Integer;
begin
  Result := FItems.Count;
end;

procedure TFtComboBox.HandleItemClick(Sender: TObject);
var
  Item: TFtMenuItem;
begin
  if Assigned(Sender) and (Sender is TFtMenuItem) then
  begin
    Item := TFtMenuItem(Sender);
    SetSelectedIndex(Integer(Item.Tag));
  end;
end;

procedure TFtComboBox.RebuildPopupMenu();
var
  i: Integer;
  item: TFtMenuItem;
begin
  if Assigned(FPopupMenu) then
    FreeAndNil(FPopupMenu);

  FPopupMenu := TFtPopupMenu.Create(Self);
  FPopupMenu.MinWidth := Width;

  for i := 0 to FItems.Count - 1 do
  begin
    item := FPopupMenu.AddItem(FItems[i], nil, nil);
    item.Tag := i;
    item.OnClickEvent := @HandleItemClick;
  end;
end;

procedure TFtComboBox.Popup();
var
  pt: TPoint;
begin
  if FItems.Count = 0 then Exit;
  RebuildPopupMenu();
  pt := GetWidgetScreenPosition(Self);
  FPopupMenu.Popup(pt.X, pt.Y + Height + 2);
end;

procedure TFtComboBox.Click();
begin
  inherited Click();
  Popup();
end;

function TFtComboBox.GetElementType(): string;
begin
  Result := 'combobox';
end;

function TFtComboBox.GetStatePseudoClass(): string;
begin
  if not FEnabled then
    Result := ':disabled'
  else if FState = bsPressed then
    Result := ':active'
  else if FState = bsHovered then
    Result := ':hover'
  else if FFocused then
    Result := ':focus'
  else
    Result := '';
end;

procedure TFtComboBox.MouseEnter();
begin
  inherited MouseEnter();
  if FState <> bsPressed then
  begin
    FState := bsHovered;
    InvalidateStyle();
    Invalidate();
  end;
end;

procedure TFtComboBox.MouseLeave();
begin
  inherited MouseLeave();
  FIsMouseDown := False;
  if FState <> bsNormal then
  begin
    FState := bsNormal;
    InvalidateStyle();
    Invalidate();
  end;
end;

procedure TFtComboBox.MouseDown(AX, AY: Integer; AButton: Integer);
begin
  inherited MouseDown(AX, AY, AButton);
  if (AButton = 1) and FEnabled then
  begin
    FIsMouseDown := True;
    FState := bsPressed;
    InvalidateStyle();
    Invalidate();
  end;
end;

procedure TFtComboBox.MouseUp(AX, AY: Integer; AButton: Integer);
begin
  inherited MouseUp(AX, AY, AButton);
  if (AButton = 1) and FIsMouseDown and FEnabled then
  begin
    FIsMouseDown := False;
    if (AX >= X) and (AX < X + Width) and (AY >= Y) and (AY < Y + Height) then
      FState := bsHovered
    else
      FState := bsNormal;
    InvalidateStyle();
    Invalidate();
  end;
end;

procedure TFtComboBox.KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string);
begin
  inherited KeyDown(AKeySym, AState, AChar);
  if not FEnabled then Exit;
  if (AKeySym = 32) or (AKeySym = $FF0D) or (AKeySym = $FF8D) or (AKeySym = $FF54) then // Space, Enter, Down Arrow
    Popup()
  else if (AKeySym = $FF52) and (FSelectedIndex > 0) then // Up Arrow
    SetSelectedIndex(FSelectedIndex - 1)
  else if (AKeySym = $FF54) and (FSelectedIndex < FItems.Count - 1) then // Down Arrow
    SetSelectedIndex(FSelectedIndex + 1);
end;

procedure TFtComboBox.Draw(Canvas: TFtCanvasAgg);
var
  st: TFtWidgetStyle;
  rad, bw: Double;
  bgR, bgG, bgB, bgA: Double;
  bdR, bdG, bdB, bdA: Double;
  txR, txG, txB: Double;
  arrowX, arrowY: Double;
  dispText: string;
  isPlaceholder: Boolean;
  fnt: TFtFont;
  accent: TFtRgbColor;
begin
  if not Visible then Exit;

  st := GetResolvedStyle();

  if FCornerRadius >= 0.0 then
    rad := FCornerRadius
  else if st.HasBorderRadius then
    rad := st.BorderRadius
  else
    rad := 6.0;

  accent := FtGetTheme().GetAccentColor();

  if st.HasBgColor then
  begin
    bgR := st.BgColor.R; bgG := st.BgColor.G; bgB := st.BgColor.B; bgA := st.BgColor.A;
  end
  else if FtGetDarkMode() then
  begin
    bgR := 0.16; bgG := 0.18; bgB := 0.20; bgA := 1.0;
  end
  else
  begin
    bgR := 1.0; bgG := 1.0; bgB := 1.0; bgA := 1.0;
  end;

  if FFocused then
  begin
    bdR := accent.R; bdG := accent.G; bdB := accent.B; bdA := 1.0;
  end
  else if st.HasBorderColor then
  begin
    bdR := st.BorderColor.R; bdG := st.BorderColor.G; bdB := st.BorderColor.B; bdA := st.BorderColor.A;
  end
  else if FtGetDarkMode() then
  begin
    bdR := 0.30; bdG := 0.33; bdB := 0.38; bdA := 1.0;
  end
  else
  begin
    bdR := 0.80; bdG := 0.82; bdB := 0.85; bdA := 1.0;
  end;

  bw := 1.0;
  if st.HasBorderWidth then bw := st.BorderWidth;

  // Drop Shadow
  if (st.HasShadow and st.EnableShadow) or (not st.HasShadow and FtGetTheme().EnableShadow) then
    Canvas.DrawShadow(X, Y, Width, Height, rad, 0.0, 1.5, 3.0, 0.0, 0.0, 0.0, 0.10);

  // Background plate
  Canvas.DrawRoundedRect(X, Y, Width, Height, rad, bgR, bgG, bgB, bgA);
  Canvas.DrawRoundedRectOutline(X, Y, Width, Height, rad, bw, bdR, bdG, bdB, bdA);

  // Focus Ring
  if FFocused then
    FtGetTheme().DrawFocusRing(Canvas, X, Y, Width, Height, rad);

  // Determine display text
  isPlaceholder := False;
  if FText <> '' then
    dispText := FText
  else if (FSelectedIndex >= 0) and (FSelectedIndex < FItems.Count) then
    dispText := FItems[FSelectedIndex]
  else
  begin
    dispText := FPlaceholder;
    isPlaceholder := True;
  end;

  // Text Color
  if isPlaceholder then
  begin
    txR := 0.55; txG := 0.58; txB := 0.62;
  end
  else if st.HasTextColor then
  begin
    txR := st.TextColor.R; txG := st.TextColor.G; txB := st.TextColor.B;
  end
  else
  begin
    accent := FtGetTheme().GetTextColor();
    txR := accent.R; txG := accent.G; txB := accent.B;
  end;

  fnt := GetFont();
  if dispText <> '' then
    Canvas.DrawTextLeft(X + 10.0, Y, Width - 32.0, Height, dispText, fnt, txR, txG, txB);

  // Dropdown Chevron Arrow
  arrowX := X + Width - 18.0;
  arrowY := Y + (Height / 2.0) - 1.5;
  Canvas.DrawLine(arrowX - 4.0, arrowY - 2.0, arrowX, arrowY + 2.5, 1.8, txR, txG, txB, 0.75);
  Canvas.DrawLine(arrowX, arrowY + 2.5, arrowX + 4.0, arrowY - 2.0, 1.8, txR, txG, txB, 0.75);
end;

end.
