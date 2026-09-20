unit Ft.Widget.Buttons;

{$mode objfpc}{$H+}

interface

uses
  ctypes, SysUtils, Classes, Ft.Canvas.Agg, Ft.Font, Ft.Widget, Ft.Theme, Ft.Css, Ft.Animation;

type
  TFtClickCallback = procedure(Sender: Pointer; UserData: Pointer); cdecl;
  TFtHoverCallback = procedure(Sender: Pointer; Hovered: cint32; UserData: Pointer); cdecl;
  TFtPressCallback = procedure(Sender: Pointer; Pressed: cint32; UserData: Pointer); cdecl;
  TFtToggleCallback = procedure(Sender: Pointer; Toggled: cint32; UserData: Pointer); cdecl;

  TFtButton = class(TFtWidget)
  private
    FState: TFtButtonState;
    FIsMouseDown: Boolean;
    FCanToggle: Boolean;
    FToggled: Boolean;
    FCornerRadius: Double;
    FEnableShadow: Integer;
    FOnClick: TFtClickCallback;
    FOnHover: TFtHoverCallback;
    FOnPress: TFtPressCallback;
    FOnToggle: TFtToggleCallback;
    FUserData: Pointer;
    procedure SetToggled(AValue: Boolean);
    procedure SetCanToggle(AValue: Boolean);
    procedure SetCornerRadius(AValue: Double);
    procedure SetEnableShadow(AValue: Integer);
  public
    Caption: string;
    constructor Create(AParent: TFtWidget); override;

    function GetElementType(): string; override;
    function GetStatePseudoClass(): string; override;
    procedure Draw(Canvas: TFtCanvasAgg); override;
    procedure Click(); override;
    procedure MouseEnter(); override;
    procedure MouseLeave(); override;
    procedure MouseDown(AX, AY: Integer; AButton: Integer); override;
    procedure MouseUp(AX, AY: Integer; AButton: Integer); override;
    procedure KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string); override;
    procedure KeyUp(AKeySym: Cardinal; AState: Cardinal); override;
    procedure LostFocus(); override;

    property State: TFtButtonState read FState;
    property CanToggle: Boolean read FCanToggle write SetCanToggle;
    property Toggled: Boolean read FToggled write SetToggled;
    property CornerRadius: Double read FCornerRadius write SetCornerRadius;
    property EnableShadow: Integer read FEnableShadow write SetEnableShadow;
    property OnClick: TFtClickCallback read FOnClick write FOnClick;
    property OnHover: TFtHoverCallback read FOnHover write FOnHover;
    property OnPress: TFtPressCallback read FOnPress write FOnPress;
    property OnToggle: TFtToggleCallback read FOnToggle write FOnToggle;
    property UserData: Pointer read FUserData write FUserData;
  end;

  TFtToggleButton = class(TFtButton)
  public
    constructor Create(AParent: TFtWidget); override;
  end;

  TFtWindowButtonKind = (
    wbkClose,      // '×' vector cross with scarlet glowing halo on hover/click
    wbkMinimize,   // '—' horizontal dash with amber halo on hover/click
    wbkMaximize,   // Dual outward chevrons (Mac-style) with emerald halo on hover/click
    wbkRestore,    // Dual inward chevrons (Mac-style) with emerald halo on hover/click
    wbkShade,      // '▴' window rollup chevron
    wbkPin,        // '•' pin / stick-on-top indicator
    wbkMenu,       // '☰' window hamburger / dots menu
    wbkAdd         // '+' new tab / add button
  );

  TFtWindowButtonStyle = (
    wbsCircle,     // Circular pill/halo (macOS traffic lights, modern tabs)
    wbsSquircle,   // Rounded rectangle (modern GTK / GNOME header bar)
    wbsSquare      // Flat rectangle (traditional Windows caption button)
  );

  TFtWindowButton = class(TFtWidget)
  private
    FKind: TFtWindowButtonKind;
    FStyle: TFtWindowButtonStyle;
    FState: TFtButtonState;
    FIsMouseDown: Boolean;
    FGlyphArm: Double;
    FHoverProgress: Double;
    FTransitionStartMs: QWord;
    FTransitionDurationMs: Integer;
    FEffectiveDurationMs: Integer;
    FTransitionStartVal: Double;
    FTransitionTargetVal: Double;
    FTransitionActive: Boolean;
    FOnClick: TFtClickCallback;
    FOnHover: TFtHoverCallback;
    FOnPress: TFtPressCallback;
    FUserData: Pointer;
    procedure SetKind(AValue: TFtWindowButtonKind);
    procedure SetStyle(AValue: TFtWindowButtonStyle);
    procedure SetGlyphArm(AValue: Double);
    procedure SetTransitionDuration(AValue: Integer);
    procedure StartHoverTransition(ATarget: Double);
  protected
    procedure SetEnabled(AValue: Boolean); override;
  public
    constructor Create(AParent: TFtWidget); override;
    constructor CreateKind(AParent: TFtWidget; AKind: TFtWindowButtonKind; AStyle: TFtWindowButtonStyle = wbsCircle);
    destructor Destroy(); override;

    function GetElementType(): string; override;
    function GetStatePseudoClass(): string; override;

    procedure Draw(Canvas: TFtCanvasAgg); override;
    procedure Click(); override;
    procedure MouseEnter(); override;
    procedure MouseLeave(); override;
    procedure MouseDown(AX, AY: Integer; AButton: Integer); override;
    procedure MouseUp(AX, AY: Integer; AButton: Integer); override;

    class procedure DrawWindowButton(
      Canvas: TFtCanvasAgg;
      BX, BY, BW, BH: Double;
      AKind: TFtWindowButtonKind;
      AStyle: TFtWindowButtonStyle;
      AState: TFtButtonState;
      DarkMode: Boolean;
      AGlyphArm: Double = 0.0;
      AHoverProgress: Double = -1.0
    );

    property Kind: TFtWindowButtonKind read FKind write SetKind;
    property Style: TFtWindowButtonStyle read FStyle write SetStyle;
    property State: TFtButtonState read FState;
    property GlyphArm: Double read FGlyphArm write SetGlyphArm;
    property TransitionDuration: Integer read FTransitionDurationMs write SetTransitionDuration;
    property HoverProgress: Double read FHoverProgress;
    property OnClick: TFtClickCallback read FOnClick write FOnClick;
    property OnHover: TFtHoverCallback read FOnHover write FOnHover;
    property OnPress: TFtPressCallback read FOnPress write FOnPress;
    property UserData: Pointer read FUserData write FUserData;
  end;

implementation

{ TFtButton }

constructor TFtButton.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FFocusable := True;
  FState := bsNormal;
  FIsMouseDown := False;
  FCanToggle := False;
  FToggled := False;
  FCornerRadius := -1.0;
  FEnableShadow := -1;
  FOnClick := nil;
  FOnHover := nil;
  FOnPress := nil;
  FOnToggle := nil;
  FUserData := nil;
end;

procedure TFtButton.SetCornerRadius(AValue: Double);
begin
  if FCornerRadius <> AValue then
  begin
    FCornerRadius := AValue;
    Invalidate();
  end;
end;

procedure TFtButton.SetEnableShadow(AValue: Integer);
begin
  if FEnableShadow <> AValue then
  begin
    FEnableShadow := AValue;
    Invalidate();
  end;
end;

procedure TFtButton.SetCanToggle(AValue: Boolean);
begin
  if FCanToggle <> AValue then
  begin
    FCanToggle := AValue;
    if not FCanToggle and FToggled then
      SetToggled(False);
  end;
end;

procedure TFtButton.SetToggled(AValue: Boolean);
begin
  if FToggled <> AValue then
  begin
    FToggled := AValue;
    Invalidate();
    if Assigned(FOnToggle) then
    begin
      if FToggled then
        FOnToggle(Self, 1, FUserData)
      else
        FOnToggle(Self, 0, FUserData);
    end;
  end;
end;

function TFtButton.GetElementType(): string;
begin
  Result := 'button';
end;

function TFtButton.GetStatePseudoClass(): string;
begin
  if not FEnabled then
    Result := ':disabled'
  else if FState = bsPressed then
    Result := ':active'
  else if FState = bsHovered then
    Result := ':hover'
  else if FCanToggle and FToggled then
    Result := ':checked'
  else if FFocused then
    Result := ':focus'
  else
    Result := '';
end;

procedure TFtButton.MouseEnter();
begin
  if FIsMouseDown then
    FState := bsPressed
  else
    FState := bsHovered;
  InvalidateStyle();
  Invalidate();
  if Assigned(FOnHover) then
    FOnHover(Self, 1, FUserData);
end;

procedure TFtButton.MouseLeave();
begin
  FState := bsNormal;
  InvalidateStyle();
  Invalidate();
  if Assigned(FOnHover) then
    FOnHover(Self, 0, FUserData);
end;

procedure TFtButton.MouseDown(AX, AY: Integer; AButton: Integer);
begin
  inherited MouseDown(AX, AY, AButton);
  if AButton = 1 then
  begin
    FIsMouseDown := True;
    FState := bsPressed;
    InvalidateStyle();
    Invalidate();
    if Assigned(FOnPress) then
      FOnPress(Self, 1, FUserData);
  end;
end;

procedure TFtButton.MouseUp(AX, AY: Integer; AButton: Integer);
begin
  if AButton = 1 then
  begin
    FIsMouseDown := False;
    if (AX >= X) and (AX < X + Width) and (AY >= Y) and (AY < Y + Height) then
      FState := bsHovered
    else
      FState := bsNormal;
    InvalidateStyle();
    Invalidate();
    if Assigned(FOnPress) then
      FOnPress(Self, 0, FUserData);
  end;
end;

procedure TFtButton.Click();
begin
  if FCanToggle then
    SetToggled(not FToggled);
  if Assigned(FOnClick) then
    FOnClick(Self, FUserData);
end;

procedure TFtButton.Draw(Canvas: TFtCanvasAgg);
var
  effRadius: Double;
  st: TFtWidgetStyle;
  bw: Double;
  txtFont: TFtFont;
  txtR, txtG, txtB: Double;
  textY: Integer;
  haloR, haloG, haloB: Double;
begin
  if not Visible then Exit;

  st := GetResolvedStyle();
  if st.HasBgColor or st.HasBorderColor or st.HasBorderRadius or st.HasTextColor then
  begin
    if st.HasBorderRadius then
      effRadius := st.BorderRadius
    else if FCornerRadius >= 0.0 then
      effRadius := FCornerRadius
    else
      effRadius := FtGetTheme().CornerRadius;

    // 1. Signature Floria squircle hover halo bloom
    if (FState = bsHovered) and (effRadius > 0.0) then
    begin
      if st.HasBorderColor then
      begin
        haloR := st.BorderColor.R;
        haloG := st.BorderColor.G;
        haloB := st.BorderColor.B;
      end
      else if FtGetDarkMode() then
      begin
        haloR := 0.38; haloG := 0.65; haloB := 0.98;
      end
      else
      begin
        haloR := 0.23; haloG := 0.51; haloB := 0.96;
      end;
      Canvas.DrawRoundedRect(X - 1.5, Y - 1.5, Width + 3.0, Height + 3.0, effRadius + 1.0, haloR, haloG, haloB, 0.20);
    end;

    // 2. Drop shadow
    if (st.HasShadow and st.EnableShadow) or
       (not st.HasShadow and (FEnableShadow = 1)) or
       (not st.HasShadow and (FEnableShadow = -1) and FtGetTheme().EnableShadow) then
    begin
      if FState <> bsPressed then
        Canvas.DrawShadow(X, Y, Width, Height, effRadius, 0.0, 2.0, 4.0, 0.0, 0.0, 0.0, 0.18);
    end;

    // 3. Background
    if st.HasBgColor then
      Canvas.DrawRoundedRect(X, Y, Width, Height, effRadius, st.BgColor.R, st.BgColor.G, st.BgColor.B, st.BgColor.A)
    else
      Canvas.DrawRoundedRect(X, Y, Width, Height, effRadius, 0.23, 0.51, 0.96, 1.0);

    // 4. Border outline
    bw := 1.0;
    if st.HasBorderWidth then bw := st.BorderWidth;
    if bw > 0.0 then
    begin
      if st.HasBorderColor then
        Canvas.DrawRoundedRectOutline(X, Y, Width, Height, effRadius, bw, st.BorderColor.R, st.BorderColor.G, st.BorderColor.B, st.BorderColor.A)
      else if st.HasBgColor then
        Canvas.DrawRoundedRectOutline(X, Y, Width, Height, effRadius, bw, st.BgColor.R * 0.8, st.BgColor.G * 0.8, st.BgColor.B * 0.8, 1.0);
    end;

    // 5. Centered text with tactile pressed shift
    if Caption <> '' then
    begin
      txtFont := GetFont();
      txtR := 1.0; txtG := 1.0; txtB := 1.0;
      if st.HasTextColor then
      begin
        txtR := st.TextColor.R;
        txtG := st.TextColor.G;
        txtB := st.TextColor.B;
      end;
      textY := Y;
      if FState = bsPressed then
        Inc(textY);
      Canvas.DrawTextCentered(X, textY, Width, Height, Caption, txtFont, txtR, txtG, txtB);
    end;
  end
  else
  begin
    FtGetTheme().DrawButtonEx(Canvas, X, Y, Width, Height, FState, FToggled, Caption, GetFont(), FCornerRadius, FEnableShadow);
  end;

  if FFocused then
  begin
    if st.HasBorderRadius then
      effRadius := st.BorderRadius
    else if FCornerRadius >= 0.0 then
      effRadius := FCornerRadius
    else
      effRadius := FtGetTheme().CornerRadius;
    FtGetTheme().DrawFocusRing(Canvas, X, Y, Width, Height, effRadius);
  end;

  inherited Draw(Canvas);
end;

procedure TFtButton.KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string);
begin
  inherited KeyDown(AKeySym, AState, AChar);
  if (AKeySym = $20) then // Space
  begin
    if FState <> bsPressed then
    begin
      FState := bsPressed;
      InvalidateStyle();
      Invalidate();
    end;
  end
  else if (AKeySym = $FF0D) or (AKeySym = $FF8D) then // Return / Enter
  begin
    Click();
  end;
end;

procedure TFtButton.KeyUp(AKeySym: Cardinal; AState: Cardinal);
begin
  inherited KeyUp(AKeySym, AState);
  if (AKeySym = $20) then // Space
  begin
    if FState = bsPressed then
    begin
      FState := bsNormal;
      InvalidateStyle();
      Invalidate();
      Click();
    end;
  end;
end;

procedure TFtButton.LostFocus();
begin
  if FState = bsPressed then
  begin
    FState := bsNormal;
    InvalidateStyle();
    Invalidate();
  end;
  inherited LostFocus();
end;

{ TFtToggleButton }

constructor TFtToggleButton.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FCanToggle := True;
end;

{ TFtWindowButton }

constructor TFtWindowButton.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FKind := wbkClose;
  FStyle := wbsCircle;
  FState := bsNormal;
  FIsMouseDown := False;
  FGlyphArm := 0.0;
  FHoverProgress := 0.0;
  FTransitionStartMs := 0;
  FTransitionDurationMs := 180;
  FEffectiveDurationMs := 180;
  FTransitionStartVal := 0.0;
  FTransitionTargetVal := 0.0;
  FTransitionActive := False;
  FOnClick := nil;
  FOnHover := nil;
  FOnPress := nil;
  FUserData := nil;
  Width := 16;
  Height := 16;
end;

constructor TFtWindowButton.CreateKind(AParent: TFtWidget; AKind: TFtWindowButtonKind; AStyle: TFtWindowButtonStyle);
begin
  Create(AParent);
  FKind := AKind;
  FStyle := AStyle;
end;

destructor TFtWindowButton.Destroy();
begin
  if FTransitionActive then
  begin
    FTransitionActive := False;
    FtGetAnimator().UnregisterContinuous(Self);
  end;
  inherited Destroy();
end;

procedure TFtWindowButton.SetKind(AValue: TFtWindowButtonKind);
begin
  if FKind <> AValue then
  begin
    FKind := AValue;
    Invalidate();
  end;
end;

procedure TFtWindowButton.SetStyle(AValue: TFtWindowButtonStyle);
begin
  if FStyle <> AValue then
  begin
    FStyle := AValue;
    Invalidate();
  end;
end;

procedure TFtWindowButton.SetGlyphArm(AValue: Double);
begin
  if FGlyphArm <> AValue then
  begin
    FGlyphArm := AValue;
    Invalidate();
  end;
end;

procedure TFtWindowButton.SetTransitionDuration(AValue: Integer);
begin
  if AValue < 0 then AValue := 0;
  FTransitionDurationMs := AValue;
end;

procedure TFtWindowButton.SetEnabled(AValue: Boolean);
begin
  inherited SetEnabled(AValue);
  if not AValue then
  begin
    if FTransitionActive then
    begin
      FTransitionActive := False;
      FtGetAnimator().UnregisterContinuous(Self);
    end;
    FHoverProgress := 0.0;
    FState := bsNormal;
    Invalidate();
  end;
end;

procedure TFtWindowButton.StartHoverTransition(ATarget: Double);
var
  dur: Integer;
  st: TFtWidgetStyle;
begin
  dur := FTransitionDurationMs;
  st := GetResolvedStyle();
  if st.HasTransition and (st.TransitionDurationMs > 0) then
    dur := st.TransitionDurationMs;

  if (dur <= 0) or (Abs(FHoverProgress - ATarget) < 1e-4) then
  begin
    FHoverProgress := ATarget;
    if FTransitionActive then
    begin
      FTransitionActive := False;
      FtGetAnimator().UnregisterContinuous(Self);
    end;
    Invalidate();
    Exit;
  end;

  FTransitionStartVal := FHoverProgress;
  FTransitionTargetVal := ATarget;
  FTransitionStartMs := GetTickCount64();
  FEffectiveDurationMs := dur;
  if not FTransitionActive then
  begin
    FTransitionActive := True;
    FtGetAnimator().RegisterContinuous(Self);
  end;
  Invalidate();
end;

function TFtWindowButton.GetElementType(): string;
begin
  Result := 'windowbutton';
end;

function TFtWindowButton.GetStatePseudoClass(): string;
begin
  if not FEnabled then
    Result := ':disabled'
  else if FState = bsPressed then
    Result := ':active'
  else if FState = bsHovered then
    Result := ':hover'
  else
    Result := '';
end;

procedure TFtWindowButton.Click();
begin
  inherited Click();
  if Assigned(FOnClick) then
    FOnClick(Pointer(Self), FUserData);
end;

procedure TFtWindowButton.MouseEnter();
begin
  inherited MouseEnter();
  if not FEnabled then Exit;
  if FIsMouseDown then
    FState := bsPressed
  else
    FState := bsHovered;
  InvalidateStyle();
  StartHoverTransition(1.0);
  if Assigned(FOnHover) then
    FOnHover(Pointer(Self), 1, FUserData);
end;

procedure TFtWindowButton.MouseLeave();
begin
  inherited MouseLeave();
  if not FEnabled then Exit;
  FState := bsNormal;
  InvalidateStyle();
  StartHoverTransition(0.0);
  if Assigned(FOnHover) then
    FOnHover(Pointer(Self), 0, FUserData);
end;

procedure TFtWindowButton.MouseDown(AX, AY: Integer; AButton: Integer);
begin
  inherited MouseDown(AX, AY, AButton);
  if not FEnabled then Exit;
  if AButton = 1 then
  begin
    FIsMouseDown := True;
    FState := bsPressed;
    InvalidateStyle();
    Invalidate();
    if Assigned(FOnPress) then
      FOnPress(Pointer(Self), 1, FUserData);
  end;
end;

procedure TFtWindowButton.MouseUp(AX, AY: Integer; AButton: Integer);
begin
  inherited MouseUp(AX, AY, AButton);
  if not FEnabled then Exit;
  if AButton = 1 then
  begin
    if FIsMouseDown then
    begin
      FIsMouseDown := False;
      if (AX >= X) and (AX < X + Width) and (AY >= Y) and (AY < Y + Height) then
      begin
        FState := bsHovered;
        InvalidateStyle();
        Invalidate();
        Click();
      end
      else
      begin
        FState := bsNormal;
        InvalidateStyle();
        StartHoverTransition(0.0);
      end;
      if Assigned(FOnPress) then
        FOnPress(Pointer(Self), 0, FUserData);
    end;
  end;
end;

procedure TFtWindowButton.Draw(Canvas: TFtCanvasAgg);
var
  theme: TFtTheme;
  nowMs: QWord;
  elapsed, t, easedT: Double;
begin
  if not Visible then Exit;

  if FTransitionActive then
  begin
    nowMs := GetTickCount64();
    if nowMs <= FTransitionStartMs then
      elapsed := 0.0
    else
      elapsed := Double(nowMs - FTransitionStartMs);

    if (FEffectiveDurationMs <= 0) or (elapsed >= FEffectiveDurationMs) then
    begin
      FHoverProgress := FTransitionTargetVal;
      FTransitionActive := False;
      FtGetAnimator().UnregisterContinuous(Self);
    end
    else
    begin
      t := elapsed / FEffectiveDurationMs;
      if t < 0.0 then t := 0.0;
      if t > 1.0 then t := 1.0;
      // Smooth cubic ease-out: 1 - (1 - t)^3
      easedT := 1.0 - (1.0 - t) * (1.0 - t) * (1.0 - t);
      FHoverProgress := FTransitionStartVal + (FTransitionTargetVal - FTransitionStartVal) * easedT;
    end;
  end;

  theme := FtGetTheme();
  DrawWindowButton(Canvas, X, Y, Width, Height, FKind, FStyle, FState, theme.DarkMode, FGlyphArm, FHoverProgress);
end;

class procedure TFtWindowButton.DrawWindowButton(
  Canvas: TFtCanvasAgg;
  BX, BY, BW, BH: Double;
  AKind: TFtWindowButtonKind;
  AStyle: TFtWindowButtonStyle;
  AState: TFtButtonState;
  DarkMode: Boolean;
  AGlyphArm: Double;
  AHoverProgress: Double
);
var
  cenX, cenY, btnRad, arm, leg, rad: Double;
  isPressed: Boolean;
  prog: Double;
  normBgR, normBgG, normBgB: Double;
  normBdR, normBdG, normBdB: Double;
  normGR, normGG, normGB: Double;
  hovBgR, hovBgG, hovBgB: Double;
  hovHaloR, hovHaloG, hovHaloB: Double;
  hovGR, hovGG, hovGB: Double;
  pressBgR, pressBgG, pressBgB: Double;
  curBgR, curBgG, curBgB: Double;
  gR, gG, gB, gA: Double;
  outlineA, cShift: Double;
begin
  cenX := BX + BW * 0.5;
  cenY := BY + BH * 0.5;
  btnRad := (BW * 0.5) - 1.0;
  if (BH * 0.5 - 1.0) < btnRad then
    btnRad := (BH * 0.5) - 1.0;
  if btnRad < 4.0 then btnRad := 4.0;

  arm := AGlyphArm;
  if arm <= 0.0 then
    arm := btnRad * 0.42;

  isPressed := (AState = bsPressed);

  if AHoverProgress >= 0.0 then
  begin
    prog := AHoverProgress;
    if prog < 0.0 then prog := 0.0;
    if prog > 1.0 then prog := 1.0;
  end
  else
  begin
    if (AState = bsHovered) or isPressed then
      prog := 1.0
    else
      prog := 0.0;
  end;

  if isPressed then
    cenY := cenY + 0.5;

  if DarkMode then
  begin
    normBgR := 0.22; normBgG := 0.24; normBgB := 0.26;
    normBdR := 0.32; normBdG := 0.35; normBdB := 0.38;
    normGR  := 0.85; normGG := 0.87; normGB := 0.90;
  end
  else
  begin
    normBgR := 0.96; normBgG := 0.97; normBgB := 0.98;
    normBdR := 0.80; normBdG := 0.82; normBdB := 0.85;
    normGR  := 0.32; normGG := 0.38; normGB := 0.46;
  end;

  case AKind of
    wbkClose:
    begin
      hovBgR := 0.98; hovBgG := 0.06; hovBgB := 0.11; // #FA0F1B
      hovHaloR := 0.98; hovHaloG := 0.06; hovHaloB := 0.11;
      hovGR := 1.0; hovGG := 1.0; hovGB := 1.0;
      pressBgR := 0.70; pressBgG := 0.02; pressBgB := 0.05; // #B2060C
    end;

    wbkMinimize:
    begin
      hovBgR := 0.96; hovBgG := 0.62; hovBgB := 0.04; // #F59E0B
      hovHaloR := 0.96; hovHaloG := 0.62; hovHaloB := 0.04;
      hovGR := 0.28; hovGG := 0.16; hovGB := 0.02;
      pressBgR := 0.78; pressBgG := 0.48; pressBgB := 0.02; // #C67600
    end;

    wbkMaximize, wbkRestore:
    begin
      hovBgR := 0.06; hovBgG := 0.72; hovBgB := 0.32; // #10B981
      hovHaloR := 0.06; hovHaloG := 0.72; hovHaloB := 0.32;
      hovGR := 1.0; hovGG := 1.0; hovGB := 1.0;
      pressBgR := 0.06; pressBgG := 0.52; pressBgB := 0.24; // #0E823E
    end;

  else
    hovBgR := 0.22; hovBgG := 0.50; hovBgB := 0.92;
    hovHaloR := 0.22; hovHaloG := 0.50; hovHaloB := 0.92;
    hovGR := 1.0; hovGG := 1.0; hovGB := 1.0;
    pressBgR := 0.18; pressBgG := 0.42; pressBgB := 0.75;
  end;

  if isPressed then
  begin
    curBgR := pressBgR; curBgG := pressBgG; curBgB := pressBgB;
    gR := hovGR; gG := hovGG; gB := hovGB; gA := 1.0;
  end
  else
  begin
    curBgR := normBgR + (hovBgR - normBgR) * prog;
    curBgG := normBgG + (hovBgG - normBgG) * prog;
    curBgB := normBgB + (hovBgB - normBgB) * prog;

    gR := normGR + (hovGR - normGR) * prog;
    gG := normGG + (hovGG - normGG) * prog;
    gB := normGB + (hovGB - normGB) * prog;
    gA := 1.0;
  end;

  case AStyle of
    wbsCircle:
    begin
      if isPressed then
      begin
        Canvas.DrawCircle(cenX, cenY, btnRad - 0.5, curBgR, curBgG, curBgB, 1.0);
      end
      else
      begin
        if prog > 0.005 then
        begin
          Canvas.DrawCircle(cenX, cenY, btnRad + 2.5 * prog, hovHaloR, hovHaloG, hovHaloB, 0.20 * prog);
          Canvas.DrawCircle(cenX, cenY, btnRad + 1.2 * prog, hovHaloR, hovHaloG, hovHaloB, 0.40 * prog);
        end;
        Canvas.DrawCircle(cenX, cenY, btnRad, curBgR, curBgG, curBgB, 1.0);
        outlineA := 1.0 - prog;
        if outlineA > 0.01 then
          Canvas.DrawCircleOutline(cenX, cenY, btnRad, 1.0, normBdR, normBdG, normBdB, outlineA);
      end;
    end;

    wbsSquircle:
    begin
      rad := 4.0;
      if isPressed then
      begin
        Canvas.DrawRoundedRect(BX + 1.0, BY + 1.0, BW - 2.0, BH - 2.0, rad, curBgR, curBgG, curBgB, 1.0);
      end
      else
      begin
        if prog > 0.005 then
        begin
          Canvas.DrawRoundedRect(BX - 1.5 * prog, BY - 1.5 * prog, BW + 3.0 * prog, BH + 3.0 * prog, rad + 1.0, hovHaloR, hovHaloG, hovHaloB, 0.20 * prog);
        end;
        Canvas.DrawRoundedRect(BX, BY, BW, BH, rad, curBgR, curBgG, curBgB, 1.0);
        outlineA := 1.0 - prog;
        if outlineA > 0.01 then
          Canvas.DrawRoundedRectOutline(BX, BY, BW, BH, rad, 1.0, normBdR, normBdG, normBdB, outlineA);
      end;
    end;

    wbsSquare:
    begin
      if isPressed then
      begin
        Canvas.DrawRect(Round(BX), Round(BY), Round(BW), Round(BH), curBgR, curBgG, curBgB, 1.0);
      end
      else
      begin
        if prog > 0.005 then
        begin
          if AKind = wbkClose then
            Canvas.DrawRect(Round(BX), Round(BY), Round(BW), Round(BH), 0.90, 0.10, 0.15, prog)
          else if DarkMode then
            Canvas.DrawRect(Round(BX), Round(BY), Round(BW), Round(BH), 0.30, 0.34, 0.38, prog)
          else
            Canvas.DrawRect(Round(BX), Round(BY), Round(BW), Round(BH), 0.35, 0.38, 0.42, prog);
        end;
      end;
    end;
  end;

  // Render Vector Glyphs
  case AKind of
    wbkClose:
    begin
      Canvas.DrawLine(cenX - arm, cenY - arm, cenX + arm, cenY + arm, 1.4, gR, gG, gB, gA);
      Canvas.DrawLine(cenX + arm, cenY - arm, cenX - arm, cenY + arm, 1.4, gR, gG, gB, gA);
    end;

    wbkMinimize:
    begin
      Canvas.DrawLine(cenX - arm, cenY, cenX + arm, cenY, 1.4, gR, gG, gB, gA);
    end;

    wbkMaximize: // Mac-style outward chevrons with subtle expansion on hover
    begin
      cShift := 0.4 * prog;
      leg := arm * 0.8;
      // Top-right chevron (pointing ↗)
      Canvas.DrawLine(cenX + arm - leg + cShift, cenY - arm - cShift, cenX + arm + cShift, cenY - arm - cShift, 1.3, gR, gG, gB, gA);
      Canvas.DrawLine(cenX + arm + cShift, cenY - arm - cShift, cenX + arm + cShift, cenY - arm + leg - cShift, 1.3, gR, gG, gB, gA);
      // Bottom-left chevron (pointing ↙)
      Canvas.DrawLine(cenX - arm + leg - cShift, cenY + arm + cShift, cenX - arm - cShift, cenY + arm + cShift, 1.3, gR, gG, gB, gA);
      Canvas.DrawLine(cenX - arm - cShift, cenY + arm + cShift, cenX - arm - cShift, cenY + arm - leg + cShift, 1.3, gR, gG, gB, gA);
    end;

    wbkRestore: // Mac-style inward chevrons with subtle inward convergence on hover
    begin
      cShift := 0.35 * prog;
      leg := arm * 0.65;
      // Top-right chevron (pointing inward ↘ toward center)
      Canvas.DrawLine(cenX + arm * 0.25 - cShift, cenY - arm * 0.25 - leg - cShift, cenX + arm * 0.25 - cShift, cenY - arm * 0.25 + cShift, 1.3, gR, gG, gB, gA);
      Canvas.DrawLine(cenX + arm * 0.25 + leg - cShift, cenY - arm * 0.25, cenX + arm * 0.25 - cShift, cenY - arm * 0.25 + cShift, 1.3, gR, gG, gB, gA);
      // Bottom-left chevron (pointing inward ↖ toward center)
      Canvas.DrawLine(cenX - arm * 0.25 + cShift, cenY + arm * 0.25 + leg + cShift, cenX - arm * 0.25 + cShift, cenY - arm * 0.25 - cShift, 1.3, gR, gG, gB, gA);
      Canvas.DrawLine(cenX - arm * 0.25 - leg + cShift, cenY + arm * 0.25, cenX - arm * 0.25 + cShift, cenY - arm * 0.25 - cShift, 1.3, gR, gG, gB, gA);
    end;

    wbkShade:
    begin
      Canvas.DrawLine(cenX - arm, cenY + arm * 0.4, cenX, cenY - arm * 0.4, 1.3, gR, gG, gB, gA);
      Canvas.DrawLine(cenX, cenY - arm * 0.4, cenX + arm, cenY + arm * 0.4, 1.3, gR, gG, gB, gA);
    end;

    wbkPin:
    begin
      Canvas.DrawCircle(cenX, cenY, arm * 0.45, gR, gG, gB, gA);
    end;

    wbkMenu:
    begin
      Canvas.DrawLine(cenX - arm, cenY - arm * 0.6, cenX + arm, cenY - arm * 0.6, 1.2, gR, gG, gB, gA);
      Canvas.DrawLine(cenX - arm, cenY, cenX + arm, cenY, 1.2, gR, gG, gB, gA);
      Canvas.DrawLine(cenX - arm, cenY + arm * 0.6, cenX + arm, cenY + arm * 0.6, 1.2, gR, gG, gB, gA);
    end;

    wbkAdd:
    begin
      Canvas.DrawLine(cenX - arm, cenY, cenX + arm, cenY, 1.3, gR, gG, gB, gA);
      Canvas.DrawLine(cenX, cenY - arm, cenX, cenY + arm, 1.3, gR, gG, gB, gA);
    end;
  end;
end;

end.
