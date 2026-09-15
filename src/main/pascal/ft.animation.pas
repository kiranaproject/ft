unit Ft.Animation;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, Classes, Math, Ft.Css;

type
  { Single active transition for a widget }
  TFtTransition = class
  public
    Widget: Pointer; // Pointer to TFtWidget to avoid circular unit dependency
    Prop: string;
    DurationMs: Integer;
    StartTimeMs: QWord;
    Timing: string;
    StartStyle: TFtWidgetStyle;
    TargetStyle: TFtWidgetStyle;
    CurrentStyle: TFtWidgetStyle;
    Finished: Boolean;

    constructor Create(AWidget: Pointer; const AFrom, ATo: TFtWidgetStyle; const AProp: string; ADuration: Integer; const ATiming: string);
    procedure Update(NowMs: QWord);
  end;

  { Global Animator managing 60 FPS animation ticker }
  TFtAnimator = class
  private
    FTransitions: TFPList;
    FContinuousWidgets: TFPList;
  public
    constructor Create();
    destructor Destroy(); override;

    procedure StartTransition(AWidget: Pointer; const AFrom, ATo: TFtWidgetStyle; const AProp: string; ADuration: Integer; const ATiming: string);
    procedure StopTransitions(AWidget: Pointer);
    procedure RegisterContinuous(AWidget: Pointer);
    procedure UnregisterContinuous(AWidget: Pointer);
    function HasActiveAnimations(): Boolean;
    function GetAnimatedStyle(AWidget: Pointer; out OutStyle: TFtWidgetStyle): Boolean;
    procedure Tick(NowMs: QWord);
  end;

type
  TFtInvalidateWidgetProc = procedure(AWidget: Pointer);

procedure FtSetInvalidateWidgetProc(AProc: TFtInvalidateWidgetProc);
function FtGetAnimator(): TFtAnimator;
function FtSolveCubicBezier(x, x1, y1, x2, y2: Double): Double;
function FtEvaluateTiming(t: Double; const ATiming: string): Double;
function FtLerpColor(const C1, C2: TFtRgbaColor; T: Double): TFtRgbaColor;
function FtLerpDouble(V1, V2, T: Double): Double;
function FtStylesEqual(const S1, S2: TFtWidgetStyle): Boolean;

implementation

var
  GAnimator: TFtAnimator = nil;
  GInvalidateWidgetProc: TFtInvalidateWidgetProc = nil;

procedure FtSetInvalidateWidgetProc(AProc: TFtInvalidateWidgetProc);
begin
  GInvalidateWidgetProc := AProc;
end;

function FtLerpDouble(V1, V2, T: Double): Double;
begin
  Result := V1 + (V2 - V1) * T;
end;

function FtLerpColor(const C1, C2: TFtRgbaColor; T: Double): TFtRgbaColor;
begin
  Result.R := C1.R + (C2.R - C1.R) * T;
  Result.G := C1.G + (C2.G - C1.G) * T;
  Result.B := C1.B + (C2.B - C1.B) * T;
  Result.A := C1.A + (C2.A - C1.A) * T;
end;

function SampleBezierX(t, x1, x2: Double): Double; inline;
begin
  Result := ((1.0 - 3.0 * x2 + 3.0 * x1) * t + (3.0 * x2 - 6.0 * x1)) * t * t + 3.0 * x1 * t;
end;

function SampleBezierY(t, y1, y2: Double): Double; inline;
begin
  Result := ((1.0 - 3.0 * y2 + 3.0 * y1) * t + (3.0 * y2 - 6.0 * y1)) * t * t + 3.0 * y1 * t;
end;

function SampleBezierDerivativeX(t, x1, x2: Double): Double; inline;
begin
  Result := (3.0 * (1.0 - 3.0 * x2 + 3.0 * x1) * t + 2.0 * (3.0 * x2 - 6.0 * x1)) * t + 3.0 * x1;
end;

function FtSolveCubicBezier(x, x1, y1, x2, y2: Double): Double;
var
  t, d2, x2_sample: Double;
  i: Integer;
  t0, t1: Double;
begin
  if x <= 0.0 then Exit(0.0);
  if x >= 1.0 then Exit(1.0);

  // Newton-Raphson iteration
  t := x;
  for i := 0 to 7 do
  begin
    x2_sample := SampleBezierX(t, x1, x2) - x;
    if Abs(x2_sample) < 1e-6 then
      Exit(SampleBezierY(t, y1, y2));
    d2 := SampleBezierDerivativeX(t, x1, x2);
    if Abs(d2) < 1e-6 then Break;
    t := t - x2_sample / d2;
  end;

  // Fallback: Bisection
  t0 := 0.0;
  t1 := 1.0;
  t := x;
  while t0 < t1 do
  begin
    x2_sample := SampleBezierX(t, x1, x2);
    if Abs(x2_sample - x) < 1e-6 then
      Exit(SampleBezierY(t, y1, y2));
    if x > x2_sample then
      t0 := t
    else
      t1 := t;
    t := (t1 + t0) * 0.5;
  end;

  Result := SampleBezierY(t, y1, y2);
end;

function FtEvaluateTiming(t: Double; const ATiming: string): Double;
var
  clean: string;
  p1, p2: Integer;
  params: TStringList;
  x1, y1, x2, y2: Double;
begin
  if t <= 0.0 then Exit(0.0);
  if t >= 1.0 then Exit(1.0);

  clean := LowerCase(Trim(ATiming));

  if (clean = '') or (clean = 'ease') then
    Result := FtSolveCubicBezier(t, 0.25, 0.1, 0.25, 1.0)
  else if clean = 'linear' then
    Result := t
  else if clean = 'ease-in' then
    Result := FtSolveCubicBezier(t, 0.42, 0.0, 1.0, 1.0)
  else if clean = 'ease-out' then
    Result := FtSolveCubicBezier(t, 0.0, 0.0, 0.58, 1.0)
  else if clean = 'ease-in-out' then
    Result := FtSolveCubicBezier(t, 0.42, 0.0, 0.58, 1.0)
  else if (Length(clean) > 13) and (Copy(clean, 1, 13) = 'cubic-bezier(') then
  begin
    p1 := Pos('(', clean);
    p2 := Pos(')', clean);
    if (p1 > 0) and (p2 > p1) then
    begin
      params := TStringList.Create();
      try
        params.Delimiter := ',';
        params.StrictDelimiter := True;
        params.DelimitedText := Copy(clean, p1 + 1, p2 - p1 - 1);
        if params.Count = 4 then
        begin
          x1 := StrToFloatDef(Trim(params[0]), 0.25);
          y1 := StrToFloatDef(Trim(params[1]), 0.1);
          x2 := StrToFloatDef(Trim(params[2]), 0.25);
          y2 := StrToFloatDef(Trim(params[3]), 1.0);
          Result := FtSolveCubicBezier(t, x1, y1, x2, y2);
          Exit;
        end;
      finally
        params.Free();
      end;
    end;
    Result := FtSolveCubicBezier(t, 0.25, 0.1, 0.25, 1.0);
  end
  else
    Result := FtSolveCubicBezier(t, 0.25, 0.1, 0.25, 1.0);
end;

function ColorsEqual(const C1, C2: TFtRgbaColor): Boolean;
begin
  Result := (Abs(C1.R - C2.R) < 1e-4) and
            (Abs(C1.G - C2.G) < 1e-4) and
            (Abs(C1.B - C2.B) < 1e-4) and
            (Abs(C1.A - C2.A) < 1e-4);
end;

function FtStylesEqual(const S1, S2: TFtWidgetStyle): Boolean;
begin
  if S1.HasBgColor <> S2.HasBgColor then Exit(False);
  if S1.HasBgColor and not ColorsEqual(S1.BgColor, S2.BgColor) then Exit(False);

  if S1.HasTextColor <> S2.HasTextColor then Exit(False);
  if S1.HasTextColor and not ColorsEqual(S1.TextColor, S2.TextColor) then Exit(False);

  if S1.HasBorderColor <> S2.HasBorderColor then Exit(False);
  if S1.HasBorderColor and not ColorsEqual(S1.BorderColor, S2.BorderColor) then Exit(False);

  if S1.HasBorderWidth <> S2.HasBorderWidth then Exit(False);
  if S1.HasBorderWidth and (Abs(S1.BorderWidth - S2.BorderWidth) > 1e-4) then Exit(False);

  if S1.HasBorderRadius <> S2.HasBorderRadius then Exit(False);
  if S1.HasBorderRadius and (Abs(S1.BorderRadius - S2.BorderRadius) > 1e-4) then Exit(False);

  Result := True;
end;

{ TFtTransition }

constructor TFtTransition.Create(AWidget: Pointer; const AFrom, ATo: TFtWidgetStyle; const AProp: string; ADuration: Integer; const ATiming: string);
begin
  inherited Create();
  Widget := AWidget;
  StartStyle := AFrom;
  TargetStyle := ATo;
  CurrentStyle := AFrom;
  Prop := AProp;
  DurationMs := ADuration;
  Timing := ATiming;
  StartTimeMs := GetTickCount64();
  Finished := False;
end;

function FtPropMatches(const ReqProp, AnimPropList: string): Boolean;
var
  p: string;
begin
  if (AnimPropList = 'all') or (AnimPropList = '') then Exit(True);
  p := ',' + LowerCase(Trim(AnimPropList)) + ',';
  if ReqProp = 'background' then
    Exit(Pos('background', p) > 0)
  else if ReqProp = 'color' then
    Exit(Pos(',color,', p) > 0)
  else if ReqProp = 'border-color' then
    Exit((Pos('border-color', p) > 0) or (Pos(',border,', p) > 0))
  else if ReqProp = 'border-width' then
    Exit((Pos('border-width', p) > 0) or (Pos(',border,', p) > 0))
  else if ReqProp = 'border-radius' then
    Exit(Pos('border-radius', p) > 0);
  Result := False;
end;

procedure TFtTransition.Update(NowMs: QWord);
var
  elapsed: Double;
  progress, easedProgress: Double;
  animProp: string;
begin
  if Finished then Exit;

  elapsed := Double(NowMs) - Double(StartTimeMs);
  if elapsed < 0.0 then elapsed := 0.0;

  if (DurationMs <= 0) or (elapsed >= DurationMs) then
  begin
    Finished := True;
    CurrentStyle := TargetStyle;
    Exit;
  end;

  progress := elapsed / DurationMs;
  if progress < 0.0 then progress := 0.0;
  if progress > 1.0 then progress := 1.0;

  easedProgress := FtEvaluateTiming(progress, Timing);

  // Start with target style base properties
  CurrentStyle := TargetStyle;
  animProp := LowerCase(Trim(Prop));
  if animProp = '' then animProp := 'all';

  // 1. Background color interpolation
  if FtPropMatches('background', animProp) then
  begin
    if StartStyle.HasBgColor and TargetStyle.HasBgColor then
    begin
      CurrentStyle.HasBgColor := True;
      CurrentStyle.BgColor := FtLerpColor(StartStyle.BgColor, TargetStyle.BgColor, easedProgress);
    end;
  end;

  // 2. Text color interpolation
  if FtPropMatches('color', animProp) then
  begin
    if StartStyle.HasTextColor and TargetStyle.HasTextColor then
    begin
      CurrentStyle.HasTextColor := True;
      CurrentStyle.TextColor := FtLerpColor(StartStyle.TextColor, TargetStyle.TextColor, easedProgress);
    end;
  end;

  // 3. Border color interpolation
  if FtPropMatches('border-color', animProp) then
  begin
    if StartStyle.HasBorderColor and TargetStyle.HasBorderColor then
    begin
      CurrentStyle.HasBorderColor := True;
      CurrentStyle.BorderColor := FtLerpColor(StartStyle.BorderColor, TargetStyle.BorderColor, easedProgress);
    end;
  end;

  // 4. Border width interpolation
  if FtPropMatches('border-width', animProp) then
  begin
    if StartStyle.HasBorderWidth and TargetStyle.HasBorderWidth then
    begin
      CurrentStyle.HasBorderWidth := True;
      CurrentStyle.BorderWidth := FtLerpDouble(StartStyle.BorderWidth, TargetStyle.BorderWidth, easedProgress);
    end;
  end;

  // 5. Border radius interpolation
  if FtPropMatches('border-radius', animProp) then
  begin
    if StartStyle.HasBorderRadius and TargetStyle.HasBorderRadius then
    begin
      CurrentStyle.HasBorderRadius := True;
      CurrentStyle.BorderRadius := FtLerpDouble(StartStyle.BorderRadius, TargetStyle.BorderRadius, easedProgress);
    end;
  end;
end;

{ TFtAnimator }

constructor TFtAnimator.Create();
begin
  inherited Create();
  FTransitions := TFPList.Create();
  FContinuousWidgets := TFPList.Create();
end;

destructor TFtAnimator.Destroy();
var
  i: Integer;
begin
  for i := 0 to FTransitions.Count - 1 do
    TFtTransition(FTransitions[i]).Free();
  FTransitions.Free();
  FContinuousWidgets.Free();
  inherited Destroy();
end;

procedure TFtAnimator.StartTransition(AWidget: Pointer; const AFrom, ATo: TFtWidgetStyle; const AProp: string; ADuration: Integer; const ATiming: string);
var
  i: Integer;
  trans: TFtTransition;
  effectiveFrom: TFtWidgetStyle;
begin
  if not Assigned(AWidget) then Exit;

  effectiveFrom := AFrom;

  // If there is already an active transition for this widget, reuse its current in-flight style
  for i := FTransitions.Count - 1 downto 0 do
  begin
    trans := TFtTransition(FTransitions[i]);
    if trans.Widget = AWidget then
    begin
      effectiveFrom := trans.CurrentStyle;
      FTransitions.Delete(i);
      trans.Free();
    end;
  end;

  if (ADuration <= 0) or FtStylesEqual(effectiveFrom, ATo) then Exit;

  trans := TFtTransition.Create(AWidget, effectiveFrom, ATo, AProp, ADuration, ATiming);
  FTransitions.Add(trans);
end;

procedure TFtAnimator.StopTransitions(AWidget: Pointer);
var
  i: Integer;
  trans: TFtTransition;
begin
  for i := FTransitions.Count - 1 downto 0 do
  begin
    trans := TFtTransition(FTransitions[i]);
    if trans.Widget = AWidget then
    begin
      FTransitions.Delete(i);
      trans.Free();
    end;
  end;
  UnregisterContinuous(AWidget);
end;

procedure TFtAnimator.RegisterContinuous(AWidget: Pointer);
begin
  if not Assigned(AWidget) then Exit;
  if FContinuousWidgets.IndexOf(AWidget) < 0 then
    FContinuousWidgets.Add(AWidget);
end;

procedure TFtAnimator.UnregisterContinuous(AWidget: Pointer);
begin
  if not Assigned(AWidget) then Exit;
  FContinuousWidgets.Remove(AWidget);
end;

function TFtAnimator.HasActiveAnimations(): Boolean;
begin
  Result := (FTransitions.Count > 0) or (FContinuousWidgets.Count > 0);
end;

function TFtAnimator.GetAnimatedStyle(AWidget: Pointer; out OutStyle: TFtWidgetStyle): Boolean;
var
  i: Integer;
  trans: TFtTransition;
begin
  Result := False;
  for i := FTransitions.Count - 1 downto 0 do
  begin
    trans := TFtTransition(FTransitions[i]);
    if trans.Widget = AWidget then
    begin
      OutStyle := trans.CurrentStyle;
      Exit(True);
    end;
  end;
end;

procedure TFtAnimator.Tick(NowMs: QWord);
var
  i: Integer;
  trans: TFtTransition;
  w: Pointer;
begin
  for i := FTransitions.Count - 1 downto 0 do
  begin
    trans := TFtTransition(FTransitions[i]);
    trans.Update(NowMs);
    if Assigned(GInvalidateWidgetProc) and Assigned(trans.Widget) then
      GInvalidateWidgetProc(trans.Widget);

    if trans.Finished then
    begin
      FTransitions.Delete(i);
      trans.Free();
    end;
  end;

  for i := FContinuousWidgets.Count - 1 downto 0 do
  begin
    if i < FContinuousWidgets.Count then
    begin
      w := FContinuousWidgets[i];
      if Assigned(GInvalidateWidgetProc) and Assigned(w) then
        GInvalidateWidgetProc(w);
    end;
  end;
end;

function FtGetAnimator(): TFtAnimator;
begin
  if not Assigned(GAnimator) then
    GAnimator := TFtAnimator.Create();
  Result := GAnimator;
end;

finalization
  if Assigned(GAnimator) then
  begin
    GAnimator.Free();
    GAnimator := nil;
  end;

end.
