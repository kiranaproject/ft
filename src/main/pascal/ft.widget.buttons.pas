unit Ft.Widget.Buttons;

{$mode objfpc}{$H+}

interface

uses
  ctypes, SysUtils, Classes, Ft.Canvas.Agg, Ft.Font, Ft.Widget, Ft.Theme, Ft.Css;

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
    FOnClick: TFtClickCallback;
    FOnHover: TFtHoverCallback;
    FOnPress: TFtPressCallback;
    FUserData: Pointer;
    procedure SetKind(AValue: TFtWindowButtonKind);
    procedure SetStyle(AValue: TFtWindowButtonStyle);
    procedure SetGlyphArm(AValue: Double);
  public
    constructor Create(AParent: TFtWidget); override;
    constructor CreateKind(AParent: TFtWidget; AKind: TFtWindowButtonKind; AStyle: TFtWindowButtonStyle = wbsCircle);

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
      AGlyphArm: Double = 0.0
    );

    property Kind: TFtWindowButtonKind read FKind write SetKind;
    property Style: TFtWindowButtonStyle read FStyle write SetStyle;
    property State: TFtButtonState read FState;
    property GlyphArm: Double read FGlyphArm write SetGlyphArm;
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

    // 1. Drop shadow
    if (st.HasShadow and st.EnableShadow) or
       (not st.HasShadow and (FEnableShadow = 1)) or
       (not st.HasShadow and (FEnableShadow = -1) and FtGetTheme().EnableShadow) then
    begin
      Canvas.DrawShadow(X, Y, Width, Height, effRadius, 0.0, 2.0, 4.0, 0.0, 0.0, 0.0, 0.18);
    end;

    // 2. Background
    if st.HasBgColor then
      Canvas.DrawRoundedRect(X, Y, Width, Height, effRadius, st.BgColor.R, st.BgColor.G, st.BgColor.B, st.BgColor.A)
    else
      Canvas.DrawRoundedRect(X, Y, Width, Height, effRadius, 0.23, 0.51, 0.96, 1.0);

    // 3. Border outline
    bw := 1.0;
    if st.HasBorderWidth then bw := st.BorderWidth;
    if bw > 0.0 then
    begin
      if st.HasBorderColor then
        Canvas.DrawRoundedRectOutline(X, Y, Width, Height, effRadius, bw, st.BorderColor.R, st.BorderColor.G, st.BorderColor.B, st.BorderColor.A)
      else if st.HasBgColor then
        Canvas.DrawRoundedRectOutline(X, Y, Width, Height, effRadius, bw, st.BgColor.R * 0.8, st.BgColor.G * 0.8, st.BgColor.B * 0.8, 1.0);
    end;

    // 4. Centered text
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
      Canvas.DrawTextCentered(X, Y, Width, Height, Caption, txtFont, txtR, txtG, txtB);
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
  Invalidate();
  if Assigned(FOnHover) then
    FOnHover(Pointer(Self), 1, FUserData);
end;

procedure TFtWindowButton.MouseLeave();
begin
  inherited MouseLeave();
  if not FEnabled then Exit;
  FState := bsNormal;
  Invalidate();
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
        Invalidate();
        Click();
      end
      else
      begin
        FState := bsNormal;
        Invalidate();
      end;
      if Assigned(FOnPress) then
        FOnPress(Pointer(Self), 0, FUserData);
    end;
  end;
end;

procedure TFtWindowButton.Draw(Canvas: TFtCanvasAgg);
var
  theme: TFtTheme;
begin
  if not Visible then Exit;
  theme := FtGetTheme();
  DrawWindowButton(Canvas, X, Y, Width, Height, FKind, FStyle, FState, theme.DarkMode, FGlyphArm);
end;

class procedure TFtWindowButton.DrawWindowButton(
  Canvas: TFtCanvasAgg;
  BX, BY, BW, BH: Double;
  AKind: TFtWindowButtonKind;
  AStyle: TFtWindowButtonStyle;
  AState: TFtButtonState;
  DarkMode: Boolean;
  AGlyphArm: Double
);
var
  cenX, cenY, btnRad, arm, leg, rad: Double;
  isPressed, isHover: Boolean;
  gR, gG, gB, gA: Double;
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
  isHover := (AState = bsHovered);

  if isPressed then
    cenY := cenY + 0.5;

  gR := 1.0; gG := 1.0; gB := 1.0; gA := 1.0;

  case AStyle of
    wbsCircle:
    begin
      if isPressed then
      begin
        case AKind of
          wbkClose:
            Canvas.DrawCircle(cenX, cenY, btnRad - 0.5, 0.70, 0.02, 0.05, 1.0); // #B2060C Deep scarlet
          wbkMinimize:
            Canvas.DrawCircle(cenX, cenY, btnRad - 0.5, 0.78, 0.48, 0.02, 1.0); // #C67600 Deep amber
          wbkMaximize, wbkRestore:
            Canvas.DrawCircle(cenX, cenY, btnRad - 0.5, 0.06, 0.52, 0.24, 1.0); // #0E823E Deep emerald
        else
          Canvas.DrawCircle(cenX, cenY, btnRad - 0.5, 0.18, 0.42, 0.75, 1.0);
        end;
        gR := 1.0; gG := 1.0; gB := 1.0; gA := 1.0;
      end
      else if isHover then
      begin
        case AKind of
          wbkClose:
          begin
            // Dual-layer scarlet halo
            Canvas.DrawCircle(cenX, cenY, btnRad + 2.5, 0.98, 0.06, 0.11, 0.20);
            Canvas.DrawCircle(cenX, cenY, btnRad + 1.2, 0.98, 0.06, 0.11, 0.40);
            Canvas.DrawCircle(cenX, cenY, btnRad, 0.98, 0.06, 0.11, 1.0); // #FA0F1B
            gR := 1.0; gG := 1.0; gB := 1.0; gA := 1.0;
          end;
          wbkMinimize:
          begin
            // Dual-layer amber gold halo
            Canvas.DrawCircle(cenX, cenY, btnRad + 2.5, 0.96, 0.62, 0.04, 0.20);
            Canvas.DrawCircle(cenX, cenY, btnRad + 1.2, 0.96, 0.62, 0.04, 0.40);
            Canvas.DrawCircle(cenX, cenY, btnRad, 0.96, 0.62, 0.04, 1.0); // #F59E0B
            gR := 0.28; gG := 0.16; gB := 0.02; gA := 1.0;
          end;
          wbkMaximize, wbkRestore:
          begin
            // Dual-layer emerald green halo
            Canvas.DrawCircle(cenX, cenY, btnRad + 2.5, 0.06, 0.72, 0.32, 0.20);
            Canvas.DrawCircle(cenX, cenY, btnRad + 1.2, 0.06, 0.72, 0.32, 0.40);
            Canvas.DrawCircle(cenX, cenY, btnRad, 0.06, 0.72, 0.32, 1.0); // #10B981
            gR := 1.0; gG := 1.0; gB := 1.0; gA := 1.0;
          end;
        else
          Canvas.DrawCircle(cenX, cenY, btnRad + 2.5, 0.22, 0.50, 0.92, 0.20);
          Canvas.DrawCircle(cenX, cenY, btnRad + 1.2, 0.22, 0.50, 0.92, 0.40);
          Canvas.DrawCircle(cenX, cenY, btnRad, 0.22, 0.50, 0.92, 1.0);
          gR := 1.0; gG := 1.0; gB := 1.0; gA := 1.0;
        end;
      end
      else
      begin
        // Normal state: button-like styling
        if DarkMode then
        begin
          Canvas.DrawCircle(cenX, cenY, btnRad, 0.22, 0.24, 0.26, 1.0);
          Canvas.DrawCircleOutline(cenX, cenY, btnRad, 1.0, 0.32, 0.35, 0.38, 1.0);
          gR := 0.85; gG := 0.87; gB := 0.90; gA := 1.0;
        end
        else
        begin
          Canvas.DrawCircle(cenX, cenY, btnRad, 0.96, 0.97, 0.98, 1.0);
          Canvas.DrawCircleOutline(cenX, cenY, btnRad, 1.0, 0.80, 0.82, 0.85, 1.0);
          gR := 0.32; gG := 0.38; gB := 0.46; gA := 1.0;
        end;
      end;
    end;

    wbsSquircle:
    begin
      rad := 4.0;
      if isPressed then
      begin
        if AKind = wbkClose then
          Canvas.DrawRoundedRect(BX + 1.0, BY + 1.0, BW - 2.0, BH - 2.0, rad, 0.70, 0.02, 0.05, 1.0)
        else
          Canvas.DrawRoundedRect(BX + 1.0, BY + 1.0, BW - 2.0, BH - 2.0, rad, 0.20, 0.40, 0.70, 1.0);
        gR := 1.0; gG := 1.0; gB := 1.0; gA := 1.0;
      end
      else if isHover then
      begin
        if AKind = wbkClose then
        begin
          Canvas.DrawRoundedRect(BX, BY, BW, BH, rad, 0.98, 0.06, 0.11, 1.0);
          gR := 1.0; gG := 1.0; gB := 1.0; gA := 1.0;
        end
        else
        begin
          Canvas.DrawRoundedRect(BX, BY, BW, BH, rad, 0.25, 0.55, 0.95, 1.0);
          gR := 1.0; gG := 1.0; gB := 1.0; gA := 1.0;
        end;
      end
      else
      begin
        if DarkMode then
        begin
          Canvas.DrawRoundedRect(BX, BY, BW, BH, rad, 0.22, 0.24, 0.26, 1.0);
          Canvas.DrawRoundedRectOutline(BX, BY, BW, BH, rad, 1.0, 0.32, 0.35, 0.38, 1.0);
          gR := 0.85; gG := 0.87; gB := 0.90; gA := 1.0;
        end
        else
        begin
          Canvas.DrawRoundedRect(BX, BY, BW, BH, rad, 0.96, 0.97, 0.98, 1.0);
          Canvas.DrawRoundedRectOutline(BX, BY, BW, BH, rad, 1.0, 0.80, 0.82, 0.85, 1.0);
          gR := 0.32; gG := 0.38; gB := 0.46; gA := 1.0;
        end;
      end;
    end;

    wbsSquare:
    begin
      if isPressed then
      begin
        if AKind = wbkClose then
          Canvas.DrawRect(Round(BX), Round(BY), Round(BW), Round(BH), 0.70, 0.02, 0.05, 1.0)
        else
          Canvas.DrawRect(Round(BX), Round(BY), Round(BW), Round(BH), 0.20, 0.40, 0.70, 1.0);
        gR := 1.0; gG := 1.0; gB := 1.0; gA := 1.0;
      end
      else if isHover then
      begin
        if AKind = wbkClose then
          Canvas.DrawRect(Round(BX), Round(BY), Round(BW), Round(BH), 0.90, 0.10, 0.15, 1.0)
        else
          Canvas.DrawRect(Round(BX), Round(BY), Round(BW), Round(BH), 0.35, 0.38, 0.42, 1.0);
        gR := 1.0; gG := 1.0; gB := 1.0; gA := 1.0;
      end
      else
      begin
        if DarkMode then
        begin
          gR := 0.85; gG := 0.87; gB := 0.90; gA := 1.0;
        end
        else
        begin
          gR := 0.30; gG := 0.35; gB := 0.42; gA := 1.0;
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

    wbkMaximize: // Mac-style outward chevrons
    begin
      leg := arm * 0.8;
      // Top-right chevron (pointing ↗)
      Canvas.DrawLine(cenX + arm - leg, cenY - arm, cenX + arm, cenY - arm, 1.3, gR, gG, gB, gA);
      Canvas.DrawLine(cenX + arm, cenY - arm, cenX + arm, cenY - arm + leg, 1.3, gR, gG, gB, gA);
      // Bottom-left chevron (pointing ↙)
      Canvas.DrawLine(cenX - arm + leg, cenY + arm, cenX - arm, cenY + arm, 1.3, gR, gG, gB, gA);
      Canvas.DrawLine(cenX - arm, cenY + arm, cenX - arm, cenY + arm - leg, 1.3, gR, gG, gB, gA);
    end;

    wbkRestore: // Mac-style inward chevrons
    begin
      leg := arm * 0.65;
      // Top-right chevron (pointing inward ↘ toward center)
      Canvas.DrawLine(cenX + arm * 0.25, cenY - arm * 0.25 - leg, cenX + arm * 0.25, cenY - arm * 0.25, 1.3, gR, gG, gB, gA);
      Canvas.DrawLine(cenX + arm * 0.25 + leg, cenY - arm * 0.25, cenX + arm * 0.25, cenY - arm * 0.25, 1.3, gR, gG, gB, gA);
      // Bottom-left chevron (pointing inward ↖ toward center)
      Canvas.DrawLine(cenX - arm * 0.25, cenY + arm * 0.25 + leg, cenX - arm * 0.25, cenY + arm * 0.25, 1.3, gR, gG, gB, gA);
      Canvas.DrawLine(cenX - arm * 0.25 - leg, cenY + arm * 0.25, cenX - arm * 0.25, cenY + arm * 0.25, 1.3, gR, gG, gB, gA);
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
