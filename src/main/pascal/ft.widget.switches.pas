unit Ft.Widget.Switches;

{$mode objfpc}{$H+}

interface

uses
  ctypes, SysUtils, Classes, Floria.Canvas.Agg, Floria.Font, Ft.Widget, Ft.Theme, Ft.Css, Ft.Animation;

type
  TFtSwitchCallback = procedure(Sender: Pointer; Checked: cint32; UserData: Pointer); cdecl;
  TFtSwitchHoverCallback = procedure(Sender: Pointer; Hovered: cint32; UserData: Pointer); cdecl;

  TFtSwitch = class(TFtWidget)
  private
    FChecked: Boolean;
    FState: TFtButtonState;
    FIsMouseDown: Boolean;
    FCornerRadius: Double;
    FEnableShadow: Integer;
    FThumbProgress: Double;
    FThumbInitialized: Boolean;
    FTransitionActive: Boolean;
    FTransitionStartVal: Double;
    FTransitionTargetVal: Double;
    FTransitionStartMs: QWord;
    FEffectiveDurationMs: Integer;
    FEffectiveTiming: string;
    FTransitionDurationMs: Integer;
    FOnToggle: TFtSwitchCallback;
    FOnHover: TFtSwitchHoverCallback;
    FUserData: Pointer;
    procedure SetChecked(AValue: Boolean);
    procedure SetCornerRadius(AValue: Double);
    procedure SetEnableShadow(AValue: Integer);
    procedure SetTransitionDuration(AValue: Integer);
    procedure StartThumbTransition(ATarget: Double);
  public
    Caption: string;
    constructor Create(AParent: TFtWidget); override;
    destructor Destroy(); override;

    procedure SetEnabled(AValue: Boolean); override;
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
    function GetEffectiveHint(): string; override;

    property Checked: Boolean read FChecked write SetChecked;
    property State: TFtButtonState read FState;
    property ThumbProgress: Double read FThumbProgress;
    property TransitionDuration: Integer read FTransitionDurationMs write SetTransitionDuration;
    property CornerRadius: Double read FCornerRadius write SetCornerRadius;
    property EnableShadow: Integer read FEnableShadow write SetEnableShadow;
    property OnToggle: TFtSwitchCallback read FOnToggle write FOnToggle;
    property OnHover: TFtSwitchHoverCallback read FOnHover write FOnHover;
    property UserData: Pointer read FUserData write FUserData;
  end;

implementation

{ TFtSwitch }

constructor TFtSwitch.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FFocusable := True;
  FChecked := False;
  FState := bsNormal;
  FIsMouseDown := False;
  FCornerRadius := -1.0;
  FEnableShadow := -1;
  FThumbProgress := 0.0;
  FThumbInitialized := False;
  FTransitionActive := False;
  FTransitionStartVal := 0.0;
  FTransitionTargetVal := 0.0;
  FTransitionStartMs := 0;
  FEffectiveDurationMs := 200;
  FEffectiveTiming := 'ease';
  FTransitionDurationMs := 200;
  FOnToggle := nil;
  FOnHover := nil;
  FUserData := nil;
  Caption := '';
  Width := 48;
  Height := 24;
end;

destructor TFtSwitch.Destroy();
begin
  if FTransitionActive then
  begin
    FTransitionActive := False;
    FtGetAnimator().UnregisterContinuous(Self);
  end;
  inherited Destroy();
end;

procedure TFtSwitch.SetEnabled(AValue: Boolean);
begin
  inherited SetEnabled(AValue);
  if not AValue then
  begin
    if FTransitionActive then
    begin
      FTransitionActive := False;
      FtGetAnimator().UnregisterContinuous(Self);
    end;
    FState := bsNormal;
    Invalidate();
  end;
end;

procedure TFtSwitch.SetCornerRadius(AValue: Double);
begin
  if FCornerRadius <> AValue then
  begin
    FCornerRadius := AValue;
    Invalidate();
  end;
end;

procedure TFtSwitch.SetEnableShadow(AValue: Integer);
begin
  if FEnableShadow <> AValue then
  begin
    FEnableShadow := AValue;
    Invalidate();
  end;
end;

procedure TFtSwitch.SetTransitionDuration(AValue: Integer);
begin
  if AValue < 0 then AValue := 0;
  FTransitionDurationMs := AValue;
end;

procedure TFtSwitch.StartThumbTransition(ATarget: Double);
var
  dur: Integer;
  st: TFtWidgetStyle;
  timing: string;
begin
  dur := FTransitionDurationMs;
  timing := 'ease';
  st := GetResolvedStyle();
  if st.HasTransition and (st.TransitionDurationMs > 0) then
    dur := st.TransitionDurationMs;
  if st.HasTransition and (st.TransitionTiming <> '') then
    timing := st.TransitionTiming;

  if (dur <= 0) or (Abs(FThumbProgress - ATarget) < 1e-4) then
  begin
    FThumbProgress := ATarget;
    if FTransitionActive then
    begin
      FTransitionActive := False;
      FtGetAnimator().UnregisterContinuous(Self);
    end;
    Invalidate();
    Exit;
  end;

  FTransitionStartVal := FThumbProgress;
  FTransitionTargetVal := ATarget;
  FTransitionStartMs := GetTickCount64();
  FEffectiveDurationMs := dur;
  FEffectiveTiming := timing;
  if not FTransitionActive then
  begin
    FTransitionActive := True;
    FtGetAnimator().RegisterContinuous(Self);
  end;
  Invalidate();
end;

procedure TFtSwitch.SetChecked(AValue: Boolean);
var
  targetVal: Double;
begin
  if FChecked <> AValue then
  begin
    FChecked := AValue;
    InvalidateStyle();
    if FChecked then
      targetVal := 1.0
    else
      targetVal := 0.0;

    if not FThumbInitialized then
    begin
      FThumbInitialized := True;
      FThumbProgress := targetVal;
    end
    else
      StartThumbTransition(targetVal);

    Invalidate();
    if Assigned(FOnToggle) then
    begin
      if FChecked then
        FOnToggle(Self, 1, FUserData)
      else
        FOnToggle(Self, 0, FUserData);
    end;
  end;
end;

function TFtSwitch.GetElementType(): string;
begin
  Result := 'switch';
end;

function TFtSwitch.GetStatePseudoClass(): string;
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

function TFtSwitch.GetEffectiveHint(): string;
var
  f: TFtFont;
begin
  if not FShowHint or not Visible then Exit('');
  if FHint <> '' then Exit(FHint);
  if Caption = '' then Exit('');
  f := GetFont();
  if not Assigned(f) then f := FtGetSystemFont();
  if Assigned(f) and (Width > 0) and (f.GetTextWidth(Caption) > (Width - 52.0)) then
    Result := Caption
  else
    Result := '';
end;

procedure TFtSwitch.Toggle();
begin
  SetChecked(not FChecked);
end;

procedure TFtSwitch.MouseEnter();
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

procedure TFtSwitch.MouseLeave();
begin
  FState := bsNormal;
  InvalidateStyle();
  Invalidate();
  if Assigned(FOnHover) then
    FOnHover(Self, 0, FUserData);
end;

procedure TFtSwitch.MouseDown(AX, AY: Integer; AButton: Integer);
begin
  inherited MouseDown(AX, AY, AButton);
  if AButton = 1 then
  begin
    FIsMouseDown := True;
    FState := bsPressed;
    InvalidateStyle();
    Invalidate();
  end;
end;

procedure TFtSwitch.MouseUp(AX, AY: Integer; AButton: Integer);
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
  end;
end;

procedure TFtSwitch.Click();
begin
  Toggle();
end;

procedure TFtSwitch.Draw(Canvas: TFtCanvasAgg);
var
  trackW, trackH: Integer;
  rad, thumbD, thumbX, thumbY, labelX, labelY: Double;
  minThumbX, maxThumbX: Double;
  bw: Double;
  actualFont: TFtFont;
  st: TFtWidgetStyle;
  txtR, txtG, txtB: Double;
  trackR, trackG, trackB: Double;
  nowMs: QWord;
  elapsed, t, easedT: Double;
begin
  if not Visible then Exit;

  if not FThumbInitialized then
    FThumbInitialized := True;

  if FTransitionActive then
  begin
    nowMs := GetTickCount64();
    if nowMs <= FTransitionStartMs then
      elapsed := 0.0
    else
      elapsed := Double(nowMs - FTransitionStartMs);

    if (FEffectiveDurationMs <= 0) or (elapsed >= FEffectiveDurationMs) then
    begin
      FThumbProgress := FTransitionTargetVal;
      FTransitionActive := False;
      FtGetAnimator().UnregisterContinuous(Self);
    end
    else
    begin
      t := elapsed / FEffectiveDurationMs;
      if t < 0.0 then t := 0.0;
      if t > 1.0 then t := 1.0;
      easedT := FtEvaluateTiming(t, FEffectiveTiming);
      FThumbProgress := FTransitionStartVal + (FTransitionTargetVal - FTransitionStartVal) * easedT;
    end;
  end;

  st := GetResolvedStyle();

  if (Caption <> '') and (Width >= Round(Height * 2.2)) then
  begin
    trackH := Height;
    trackW := Round(Height * 1.85);
    if trackW < 36 then trackW := 36;
    labelX := X + trackW + 8;
  end
  else
  begin
    trackH := Height;
    trackW := Width;
    labelX := X + Width + 8;
  end;

  if st.HasBorderRadius then
    rad := st.BorderRadius
  else if FCornerRadius >= 0.0 then
    rad := FCornerRadius
  else
    rad := trackH / 2.0;

  thumbD := trackH - 4.0;
  thumbY := Y + 2.0;

  minThumbX := X + 2.0;
  maxThumbX := X + trackW - thumbD - 2.0;
  thumbX := minThumbX + (maxThumbX - minThumbX) * FThumbProgress;

  // 1. Drop shadow if enabled
  if (st.HasShadow and st.EnableShadow) or
     (not st.HasShadow and (FEnableShadow = 1)) or
     (not st.HasShadow and (FEnableShadow = -1) and FtGetTheme().EnableShadow) then
  begin
    Canvas.DrawShadow(X, Y, trackW, trackH, rad, 0.0, 2.0, 4.0, 0.0, 0.0, 0.0, 0.15);
  end;

  // 2. Track background
  if st.HasBgColor then
    Canvas.DrawRoundedRect(X, Y, trackW, trackH, rad, st.BgColor.R, st.BgColor.G, st.BgColor.B, st.BgColor.A)
  else
  begin
    // Smoothly lerp track background in fallback mode
    trackR := 0.85 + (0.23 - 0.85) * FThumbProgress;
    trackG := 0.87 + (0.51 - 0.87) * FThumbProgress;
    trackB := 0.90 + (0.96 - 0.90) * FThumbProgress;
    Canvas.DrawRoundedRect(X, Y, trackW, trackH, rad, trackR, trackG, trackB, 1.0);
  end;

  // 3. Border outline
  bw := 1.0;
  if st.HasBorderWidth then bw := st.BorderWidth;
  if bw > 0.0 then
  begin
    if st.HasBorderColor then
      Canvas.DrawRoundedRectOutline(X, Y, trackW, trackH, rad, bw, st.BorderColor.R, st.BorderColor.G, st.BorderColor.B, st.BorderColor.A)
    else
      Canvas.DrawRoundedRectOutline(X, Y, trackW, trackH, rad, bw, 0.75, 0.77, 0.80, 1.0);
  end;

  // 4. Thumb knob (white circle with subtle shadow)
  Canvas.DrawShadow(thumbX, thumbY, thumbD, thumbD, thumbD / 2.0, 0.0, 1.0, 2.0, 0.0, 0.0, 0.0, 0.20);
  Canvas.DrawRoundedRect(thumbX, thumbY, thumbD, thumbD, thumbD / 2.0, 1.0, 1.0, 1.0, 1.0);
  Canvas.DrawRoundedRectOutline(thumbX, thumbY, thumbD, thumbD, thumbD / 2.0, 0.5, 0.85, 0.87, 0.90, 1.0);

  // 5. Caption label
  if Caption <> '' then
  begin
    actualFont := GetFont();
    if not Assigned(actualFont) then actualFont := FtGetSystemFont();
    if st.HasTextColor then
    begin
      txtR := st.TextColor.R; txtG := st.TextColor.G; txtB := st.TextColor.B;
    end
    else
    begin
      txtR := FtGetTheme().GetTextColor().R;
      txtG := FtGetTheme().GetTextColor().G;
      txtB := FtGetTheme().GetTextColor().B;
    end;
    labelY := Y + (Height - actualFont.Height) / 2.0 + actualFont.Ascent;
    Canvas.DrawText(labelX, labelY, Caption, actualFont, txtR, txtG, txtB);
  end;

  // 6. Focus ring
  if FFocused then
    FtGetTheme().DrawFocusRing(Canvas, X, Y, trackW, trackH, rad);

  inherited Draw(Canvas);
end;

procedure TFtSwitch.KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string);
begin
  inherited KeyDown(AKeySym, AState, AChar);
  // Space ($20), Return ($FF0D), Enter ($FF8D) -> Toggle
  if (AKeySym = $20) or (AKeySym = $FF0D) or (AKeySym = $FF8D) then
  begin
    Toggle();
  end
  // Left Arrow ($FF51) -> Turn OFF
  else if (AKeySym = $FF51) then
  begin
    if FChecked then
      SetChecked(False);
  end
  // Right Arrow ($FF53) -> Turn ON
  else if (AKeySym = $FF53) then
  begin
    if not FChecked then
      SetChecked(True);
  end;
end;

end.
