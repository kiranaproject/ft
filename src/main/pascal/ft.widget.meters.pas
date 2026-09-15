unit Ft.Widget.Meters;

{$mode objfpc}{$H+}

interface

uses
  ctypes, SysUtils, Classes, Math, Ft.Canvas.Agg, Ft.Font, Ft.Widget, Ft.Theme, Ft.Css;

type
  TFtSliderOrientation = (ftSliderHorizontal = 0, ftSliderVertical = 1);
  TFtProgressOrientation = (ftProgressHorizontal = 0, ftProgressVertical = 1);

  TFtSliderChangeCallback = procedure(Sender: Pointer; Value: Double; UserData: Pointer); cdecl;

  { TFtSlider }
  TFtSlider = class(TFtWidget)
  private
    FOrientation: TFtSliderOrientation;
    FMin: Double;
    FMax: Double;
    FValue: Double;
    FStep: Double;
    FThumbSize: Double;
    FIsDragging: Boolean;
    FState: TFtButtonState;
    FOnChange: TFtSliderChangeCallback;
    FUserData: Pointer;
    procedure SetOrientation(AValue: TFtSliderOrientation);
    procedure SetMin(AValue: Double);
    procedure SetMax(AValue: Double);
    procedure SetValue(AValue: Double);
    procedure SetStep(AValue: Double);
    procedure SetThumbSize(AValue: Double);
    procedure UpdateValueFromPos(AX, AY: Integer);
    function ClampValue(AValue: Double): Double;
  public
    constructor Create(AParent: TFtWidget; AOrientation: TFtSliderOrientation = ftSliderHorizontal); reintroduce;

    procedure Draw(Canvas: TFtCanvasAgg); override;
    procedure MouseDown(AX, AY: Integer; AButton: Integer); override;
    procedure MouseMove(AX, AY: Integer); override;
    procedure MouseUp(AX, AY: Integer; AButton: Integer); override;
    procedure MouseEnter(); override;
    procedure MouseLeave(); override;
    procedure KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string); override;

    function GetElementType(): string; override;
    function GetStatePseudoClass(): string; override;

    property Orientation: TFtSliderOrientation read FOrientation write SetOrientation;
    property Min: Double read FMin write SetMin;
    property Max: Double read FMax write SetMax;
    property Value: Double read FValue write SetValue;
    property Step: Double read FStep write SetStep;
    property ThumbSize: Double read FThumbSize write SetThumbSize;
    property OnChange: TFtSliderChangeCallback read FOnChange write FOnChange;
    property UserData: Pointer read FUserData write FUserData;
  end;

  { TFtProgressBar }
  TFtProgressBar = class(TFtWidget)
  private
    FOrientation: TFtProgressOrientation;
    FMin: Double;
    FMax: Double;
    FValue: Double;
    FIndeterminate: Boolean;
    FShowText: Boolean;
    FTextFormat: string;
    FCornerRadius: Double;
    procedure SetOrientation(AValue: TFtProgressOrientation);
    procedure SetMin(AValue: Double);
    procedure SetMax(AValue: Double);
    procedure SetValue(AValue: Double);
    procedure SetIndeterminate(AValue: Boolean);
    procedure SetShowText(AValue: Boolean);
    procedure SetTextFormat(const AValue: string);
    procedure SetCornerRadius(AValue: Double);
    function ClampValue(AValue: Double): Double;
  public
    constructor Create(AParent: TFtWidget; AOrientation: TFtProgressOrientation = ftProgressHorizontal); reintroduce;

    procedure Draw(Canvas: TFtCanvasAgg); override;

    function GetElementType(): string; override;

    property Orientation: TFtProgressOrientation read FOrientation write SetOrientation;
    property Min: Double read FMin write SetMin;
    property Max: Double read FMax write SetMax;
    property Value: Double read FValue write SetValue;
    property Indeterminate: Boolean read FIndeterminate write SetIndeterminate;
    property ShowText: Boolean read FShowText write SetShowText;
    property TextFormat: string read FTextFormat write SetTextFormat;
    property CornerRadius: Double read FCornerRadius write SetCornerRadius;
  end;

implementation

{ TFtSlider }

constructor TFtSlider.Create(AParent: TFtWidget; AOrientation: TFtSliderOrientation);
begin
  inherited Create(AParent);
  FFocusable := True;
  FOrientation := AOrientation;
  FMin := 0.0;
  FMax := 100.0;
  FValue := 0.0;
  FStep := 0.0;
  FThumbSize := 18.0;
  FIsDragging := False;
  FState := bsNormal;
  FOnChange := nil;
  FUserData := nil;

  if FOrientation = ftSliderHorizontal then
  begin
    Width := 160;
    Height := 24;
  end
  else
  begin
    Width := 24;
    Height := 160;
  end;
end;

function TFtSlider.ClampValue(AValue: Double): Double;
var
  clamped: Double;
begin
  if AValue < FMin then
    clamped := FMin
  else if AValue > FMax then
    clamped := FMax
  else
    clamped := AValue;

  if FStep > 0.0 then
    clamped := FMin + Round((clamped - FMin) / FStep) * FStep;

  if clamped < FMin then clamped := FMin;
  if clamped > FMax then clamped := FMax;

  Result := clamped;
end;

procedure TFtSlider.SetOrientation(AValue: TFtSliderOrientation);
begin
  if FOrientation <> AValue then
  begin
    FOrientation := AValue;
    Invalidate();
  end;
end;

procedure TFtSlider.SetMin(AValue: Double);
begin
  if Abs(FMin - AValue) > 1e-6 then
  begin
    FMin := AValue;
    if FMax < FMin then FMax := FMin;
    Value := FValue;
    Invalidate();
  end;
end;

procedure TFtSlider.SetMax(AValue: Double);
begin
  if Abs(FMax - AValue) > 1e-6 then
  begin
    FMax := AValue;
    if FMin > FMax then FMin := FMax;
    Value := FValue;
    Invalidate();
  end;
end;

procedure TFtSlider.SetValue(AValue: Double);
var
  newVal: Double;
begin
  newVal := ClampValue(AValue);
  if Abs(FValue - newVal) > 1e-6 then
  begin
    FValue := newVal;
    Invalidate();
    if Assigned(FOnChange) then
      FOnChange(Pointer(Self), FValue, FUserData);
  end;
end;

procedure TFtSlider.SetStep(AValue: Double);
begin
  if Abs(FStep - AValue) > 1e-6 then
  begin
    FStep := Math.Max(0.0, AValue);
    Value := FValue;
  end;
end;

procedure TFtSlider.SetThumbSize(AValue: Double);
begin
  if Abs(FThumbSize - AValue) > 1e-4 then
  begin
    FThumbSize := Math.Max(10.0, AValue);
    Invalidate();
  end;
end;

procedure TFtSlider.UpdateValueFromPos(AX, AY: Integer);
var
  trackLength, trackStart, pos, ratio, newVal: Double;
begin
  if FMax <= FMin then Exit;

  if FOrientation = ftSliderHorizontal then
  begin
    trackStart := FThumbSize / 2.0;
    trackLength := Math.Max(1.0, Width - FThumbSize);
    pos := Math.Max(0.0, Math.Min(trackLength, Double(AX) - trackStart));
    ratio := pos / trackLength;
  end
  else
  begin
    trackStart := FThumbSize / 2.0;
    trackLength := Math.Max(1.0, Height - FThumbSize);
    // Vertical slider: bottom is min, top is max (or top min, bottom max)
    pos := Math.Max(0.0, Math.Min(trackLength, Double(Height - AY) - trackStart));
    ratio := pos / trackLength;
  end;

  newVal := FMin + ratio * (FMax - FMin);
  SetValue(newVal);
end;

procedure TFtSlider.MouseDown(AX, AY: Integer; AButton: Integer);
begin
  inherited MouseDown(AX, AY, AButton);
  if (AButton = 1) and FEnabled then
  begin
    FIsDragging := True;
    FState := bsPressed;
    UpdateValueFromPos(AX, AY);
    InvalidateStyle();
    Invalidate();
  end;
end;

procedure TFtSlider.MouseMove(AX, AY: Integer);
begin
  inherited MouseMove(AX, AY);
  if FIsDragging and FEnabled then
  begin
    UpdateValueFromPos(AX, AY);
  end;
end;

procedure TFtSlider.MouseUp(AX, AY: Integer; AButton: Integer);
begin
  inherited MouseUp(AX, AY, AButton);
  if (AButton = 1) and FIsDragging then
  begin
    FIsDragging := False;
    if (AX >= 0) and (AX < Width) and (AY >= 0) and (AY < Height) then
      FState := bsHovered
    else
      FState := bsNormal;
    InvalidateStyle();
    Invalidate();
  end;
end;

procedure TFtSlider.MouseEnter();
begin
  inherited MouseEnter();
  if FState <> bsPressed then
  begin
    FState := bsHovered;
    InvalidateStyle();
    Invalidate();
  end;
end;

procedure TFtSlider.MouseLeave();
begin
  inherited MouseLeave();
  if not FIsDragging and (FState <> bsNormal) then
  begin
    FState := bsNormal;
    InvalidateStyle();
    Invalidate();
  end;
end;

procedure TFtSlider.KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string);
var
  delta: Double;
begin
  inherited KeyDown(AKeySym, AState, AChar);
  if not FEnabled then Exit;

  if FStep > 0.0 then
    delta := FStep
  else
    delta := Math.Max(0.01, (FMax - FMin) * 0.05);

  case AKeySym of
    $FF51, $FF54: // Left or Down arrow
      SetValue(FValue - delta);
    $FF53, $FF52: // Right or Up arrow
      SetValue(FValue + delta);
    $FF50: // Home
      SetValue(FMin);
    $FF57: // End
      SetValue(FMax);
  end;
end;

function TFtSlider.GetElementType(): string;
begin
  Result := 'slider';
end;

function TFtSlider.GetStatePseudoClass(): string;
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

procedure TFtSlider.Draw(Canvas: TFtCanvasAgg);
var
  st: TFtWidgetStyle;
  trackThick, trackRad, ratio: Double;
  trackX, trackY, trackW, trackH: Double;
  fillX, fillY, fillW, fillH: Double;
  thumbX, thumbY, thumbRad: Double;
  bgR, bgG, bgB, bgA: Double;
  fillR, fillG, fillB: Double;
  accent: TFtRgbColor;
begin
  if not Visible then Exit;

  st := GetResolvedStyle();
  trackThick := 6.0;
  trackRad := trackThick / 2.0;
  thumbRad := FThumbSize / 2.0;

  if FMax > FMin then
    ratio := (FValue - FMin) / (FMax - FMin)
  else
    ratio := 0.0;

  accent := FtGetTheme().GetAccentColor();

  // Track Background color
  if st.HasBgColor then
  begin
    bgR := st.BgColor.R; bgG := st.BgColor.G; bgB := st.BgColor.B; bgA := st.BgColor.A;
  end
  else if FtGetDarkMode() then
  begin
    bgR := 0.22; bgG := 0.24; bgB := 0.28; bgA := 1.0;
  end
  else
  begin
    bgR := 0.85; bgG := 0.87; bgB := 0.90; bgA := 1.0;
  end;

  // Track Active Fill color
  if st.HasTextColor then
  begin
    fillR := st.TextColor.R; fillG := st.TextColor.G; fillB := st.TextColor.B;
  end
  else
  begin
    fillR := accent.R; fillG := accent.G; fillB := accent.B;
  end;

  if FOrientation = ftSliderHorizontal then
  begin
    trackX := X + thumbRad;
    trackY := Y + (Height - trackThick) / 2.0;
    trackW := Math.Max(1.0, Width - FThumbSize);
    trackH := trackThick;

    thumbX := trackX + ratio * trackW;
    thumbY := Y + Height / 2.0;

    // Draw Inactive Track
    Canvas.DrawRoundedRect(trackX, trackY, trackW, trackH, trackRad, bgR, bgG, bgB, bgA);

    // Draw Active Fill
    if ratio > 0.001 then
    begin
      fillW := ratio * trackW;
      Canvas.DrawRoundedRect(trackX, trackY, fillW, trackH, trackRad, fillR, fillG, fillB, 1.0);
    end;
  end
  else
  begin
    trackX := X + (Width - trackThick) / 2.0;
    trackY := Y + thumbRad;
    trackW := trackThick;
    trackH := Math.Max(1.0, Height - FThumbSize);

    thumbX := X + Width / 2.0;
    thumbY := (Y + Height - thumbRad) - ratio * trackH;

    // Draw Inactive Track
    Canvas.DrawRoundedRect(trackX, trackY, trackW, trackH, trackRad, bgR, bgG, bgB, bgA);

    // Draw Active Fill (from bottom up)
    if ratio > 0.001 then
    begin
      fillH := ratio * trackH;
      fillY := (Y + Height - thumbRad) - fillH;
      Canvas.DrawRoundedRect(trackX, fillY, trackW, fillH, trackRad, fillR, fillG, fillB, 1.0);
    end;
  end;

  // Draw Thumb Shadow
  Canvas.DrawShadow(thumbX - thumbRad, thumbY - thumbRad, FThumbSize, FThumbSize, thumbRad, 0.0, 1.5, 3.5, 0.0, 0.0, 0.0, 0.18);

  // Draw Thumb Plate (crisp white with accent or dark surface)
  if FtGetDarkMode() then
    Canvas.DrawCircle(thumbX, thumbY, thumbRad, 0.95, 0.96, 0.97, 1.0)
  else
    Canvas.DrawCircle(thumbX, thumbY, thumbRad, 1.0, 1.0, 1.0, 1.0);

  // Thumb outline
  Canvas.DrawCircleOutline(thumbX, thumbY, thumbRad, 1.2, fillR, fillG, fillB, 0.85);

  // Focus Ring
  if FFocused then
    FtGetTheme().DrawFocusRing(Canvas, thumbX - thumbRad - 1.0, thumbY - thumbRad - 1.0, FThumbSize + 2.0, FThumbSize + 2.0, thumbRad + 1.0);
end;

{ TFtProgressBar }

constructor TFtProgressBar.Create(AParent: TFtWidget; AOrientation: TFtProgressOrientation);
begin
  inherited Create(AParent);
  FOrientation := AOrientation;
  FMin := 0.0;
  FMax := 100.0;
  FValue := 0.0;
  FIndeterminate := False;
  FShowText := False;
  FTextFormat := '%.0f%%';
  FCornerRadius := 5.0;

  if FOrientation = ftProgressHorizontal then
  begin
    Width := 200;
    Height := 18;
  end
  else
  begin
    Width := 18;
    Height := 200;
  end;
end;

function TFtProgressBar.ClampValue(AValue: Double): Double;
begin
  if AValue < FMin then
    Result := FMin
  else if AValue > FMax then
    Result := FMax
  else
    Result := AValue;
end;

procedure TFtProgressBar.SetOrientation(AValue: TFtProgressOrientation);
begin
  if FOrientation <> AValue then
  begin
    FOrientation := AValue;
    Invalidate();
  end;
end;

procedure TFtProgressBar.SetMin(AValue: Double);
begin
  if Abs(FMin - AValue) > 1e-6 then
  begin
    FMin := AValue;
    if FMax < FMin then FMax := FMin;
    Value := FValue;
    Invalidate();
  end;
end;

procedure TFtProgressBar.SetMax(AValue: Double);
begin
  if Abs(FMax - AValue) > 1e-6 then
  begin
    FMax := AValue;
    if FMin > FMax then FMin := FMax;
    Value := FValue;
    Invalidate();
  end;
end;

procedure TFtProgressBar.SetValue(AValue: Double);
var
  newVal: Double;
begin
  newVal := ClampValue(AValue);
  if Abs(FValue - newVal) > 1e-6 then
  begin
    FValue := newVal;
    Invalidate();
  end;
end;

procedure TFtProgressBar.SetIndeterminate(AValue: Boolean);
begin
  if FIndeterminate <> AValue then
  begin
    FIndeterminate := AValue;
    Invalidate();
  end;
end;

procedure TFtProgressBar.SetShowText(AValue: Boolean);
begin
  if FShowText <> AValue then
  begin
    FShowText := AValue;
    Invalidate();
  end;
end;

procedure TFtProgressBar.SetTextFormat(const AValue: string);
begin
  if FTextFormat <> AValue then
  begin
    FTextFormat := AValue;
    Invalidate();
  end;
end;

procedure TFtProgressBar.SetCornerRadius(AValue: Double);
begin
  if Abs(FCornerRadius - AValue) > 1e-4 then
  begin
    FCornerRadius := AValue;
    Invalidate();
  end;
end;

function TFtProgressBar.GetElementType(): string;
begin
  Result := 'progressbar';
end;

procedure TFtProgressBar.Draw(Canvas: TFtCanvasAgg);
var
  st: TFtWidgetStyle;
  rad, bw, ratio: Double;
  bgR, bgG, bgB, bgA: Double;
  bdR, bdG, bdB, bdA: Double;
  fillR, fillG, fillB: Double;
  fillX, fillY, fillW, fillH: Double;
  blockLen, cyclePos, animPhase: Double;
  accent: TFtRgbColor;
  txt: string;
  fnt: TFtFont;
  nowTicks: QWord;
begin
  if not Visible then Exit;

  st := GetResolvedStyle();

  if FCornerRadius >= 0.0 then
    rad := FCornerRadius
  else if st.HasBorderRadius then
    rad := st.BorderRadius
  else
    rad := 5.0;

  accent := FtGetTheme().GetAccentColor();

  // Background
  if st.HasBgColor then
  begin
    bgR := st.BgColor.R; bgG := st.BgColor.G; bgB := st.BgColor.B; bgA := st.BgColor.A;
  end
  else if FtGetDarkMode() then
  begin
    bgR := 0.18; bgG := 0.20; bgB := 0.23; bgA := 1.0;
  end
  else
  begin
    bgR := 0.88; bgG := 0.90; bgB := 0.93; bgA := 1.0;
  end;

  // Border
  if st.HasBorderColor then
  begin
    bdR := st.BorderColor.R; bdG := st.BorderColor.G; bdB := st.BorderColor.B; bdA := st.BorderColor.A;
  end
  else if FtGetDarkMode() then
  begin
    bdR := 0.28; bdG := 0.31; bdB := 0.35; bdA := 1.0;
  end
  else
  begin
    bdR := 0.78; bdG := 0.80; bdB := 0.84; bdA := 1.0;
  end;

  // Fill Color
  if st.HasTextColor then
  begin
    fillR := st.TextColor.R; fillG := st.TextColor.G; fillB := st.TextColor.B;
  end
  else
  begin
    fillR := accent.R; fillG := accent.G; fillB := accent.B;
  end;

  bw := 1.0;
  if st.HasBorderWidth then bw := st.BorderWidth;

  // Draw Background Track
  Canvas.DrawRoundedRect(X, Y, Width, Height, rad, bgR, bgG, bgB, bgA);
  Canvas.DrawRoundedRectOutline(X, Y, Width, Height, rad, bw, bdR, bdG, bdB, bdA);

  // Draw Fill
  if FIndeterminate then
  begin
    nowTicks := GetTickCount64();
    // 1500ms full sweep cycle
    cyclePos := (nowTicks mod 1500) / 1500.0;
    // Bouncing oscillation: 0 -> 1 -> 0
    animPhase := (1.0 - Cos(cyclePos * 2.0 * Pi)) / 2.0;

    if FOrientation = ftProgressHorizontal then
    begin
      blockLen := Width * 0.35;
      fillX := X + animPhase * (Width - blockLen);
      Canvas.DrawRoundedRect(fillX, Y + 1.0, blockLen, Height - 2.0, Math.Max(2.0, rad - 1.0), fillR, fillG, fillB, 1.0);
    end
    else
    begin
      blockLen := Height * 0.35;
      fillY := Y + animPhase * (Height - blockLen);
      Canvas.DrawRoundedRect(X + 1.0, fillY, Width - 2.0, blockLen, Math.Max(2.0, rad - 1.0), fillR, fillG, fillB, 1.0);
    end;
  end
  else
  begin
    if FMax > FMin then
      ratio := (FValue - FMin) / (FMax - FMin)
    else
      ratio := 0.0;

    if ratio > 0.001 then
    begin
      if FOrientation = ftProgressHorizontal then
      begin
        fillW := Math.Max(rad * 2.0, ratio * Width);
        if fillW > Width then fillW := Width;
        Canvas.DrawRoundedRect(X + 1.0, Y + 1.0, fillW - 2.0, Height - 2.0, Math.Max(2.0, rad - 1.0), fillR, fillG, fillB, 1.0);
      end
      else
      begin
        fillH := Math.Max(rad * 2.0, ratio * Height);
        if fillH > Height then fillH := Height;
        fillY := (Y + Height) - fillH;
        Canvas.DrawRoundedRect(X + 1.0, fillY + 1.0, Width - 2.0, fillH - 2.0, Math.Max(2.0, rad - 1.0), fillR, fillG, fillB, 1.0);
      end;
    end;
  end;

  // Draw Percentage Text
  if FShowText and not FIndeterminate and (FOrientation = ftProgressHorizontal) then
  begin
    if FMax > FMin then
      ratio := (FValue - FMin) / (FMax - FMin) * 100.0
    else
      ratio := 0.0;

    try
      txt := Format(FTextFormat, [ratio]);
    except
      txt := Format('%.0f%%', [ratio]);
    end;

    fnt := GetFont();
    // High contrast centered text
    if FtGetDarkMode() or (ratio > 52.0) then
      Canvas.DrawTextCentered(X, Y, Width, Height, txt, fnt, 1.0, 1.0, 1.0)
    else
      Canvas.DrawTextCentered(X, Y, Width, Height, txt, fnt, 0.2, 0.2, 0.2);
  end;
end;

end.
