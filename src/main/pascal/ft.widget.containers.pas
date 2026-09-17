unit Ft.Widget.Containers;

{$mode objfpc}{$H+}

interface

uses
  ctypes, SysUtils, Classes, Math, Ft.Canvas.Agg, Ft.Font, Ft.Widget, Ft.Theme, Ft.Widget.ScrollBars, Ft.Css;

type
  TFtContainer = class(TFtWidget)
  protected
    FScrollBarMode: TFtScrollBarMode;
    FVScrollBar: TFtScrollBar;
    FHScrollBar: TFtScrollBar;
    FScrollX: Double;
    FScrollY: Double;
    FLastIntScrollX: Integer;
    FLastIntScrollY: Integer;
    FContentWidth: Double;
    FContentHeight: Double;
    FCornerRadius: Double;
    FPaddingX: Double;
    FPaddingY: Double;
    FDrawFrame: Boolean;
    FDrawFocusRing: Boolean;
    FAutoContentSize: Boolean;
    FBackdropBlur: Double;
    FOnScroll: TFtScrollCallback;
    FOnScrollEvent: TFtScrollEvent;
    FUserData: Pointer;

    procedure SetScrollBarMode(AValue: TFtScrollBarMode); virtual;
    procedure SetScrollX(AValue: Double); virtual;
    procedure SetScrollY(AValue: Double); virtual;
    procedure SetCornerRadius(AValue: Double); virtual;
    procedure SetBackdropBlur(AValue: Double); virtual;
    procedure SetContentWidth(AValue: Double); virtual;
    procedure SetContentHeight(AValue: Double); virtual;
    procedure SetDrawFrame(AValue: Boolean); virtual;
    procedure SetPaddingX(AValue: Double); virtual;
    procedure SetPaddingY(AValue: Double); virtual;

    procedure HandleVScroll(Sender: TObject; Value: Double); virtual;
    procedure HandleHScroll(Sender: TObject; Value: Double); virtual;
    procedure DrawBackground(Canvas: TFtCanvasAgg); virtual;
    procedure DrawContent(Canvas: TFtCanvasAgg); virtual;
    procedure DrawChildren(Canvas: TFtCanvasAgg); virtual;
    procedure ShiftChildren(DeltaX, DeltaY: Integer); virtual;
    procedure RecalculateContentSize(); virtual;
  public
    constructor Create(AParent: TFtWidget); override;
    destructor Destroy(); override;
    function GetElementType(): string; override;

    procedure Draw(Canvas: TFtCanvasAgg); override;
    function HitTest(AX, AY: Integer): TFtWidget; override;
    procedure MouseDown(AX, AY: Integer; AButton: Integer); override;
    procedure InvalidateRect(AX, AY, AW, AH: Integer); override;

    procedure GetClientRect(out AX, AY, AW, AH: Double); virtual;
    procedure SetContentSize(AWidth, AHeight: Double);
    procedure SetPadding(APaddingX, APaddingY: Double);
    procedure AddChildRelative(AWidget: TFtWidget; ARelX, ARelY: Integer);
    procedure UpdateScrollBars(); virtual;

    property ScrollBarMode: TFtScrollBarMode read FScrollBarMode write SetScrollBarMode;
    property VScrollBar: TFtScrollBar read FVScrollBar;
    property HScrollBar: TFtScrollBar read FHScrollBar;
    property ScrollX: Double read FScrollX write SetScrollX;
    property ScrollY: Double read FScrollY write SetScrollY;
    property LastIntScrollX: Integer read FLastIntScrollX;
    property LastIntScrollY: Integer read FLastIntScrollY;
    property ContentWidth: Double read FContentWidth write SetContentWidth;
    property ContentHeight: Double read FContentHeight write SetContentHeight;
    property CornerRadius: Double read FCornerRadius write SetCornerRadius;
    property BackdropBlur: Double read FBackdropBlur write SetBackdropBlur;
    property PaddingX: Double read FPaddingX write SetPaddingX;
    property PaddingY: Double read FPaddingY write SetPaddingY;
    property DrawFrame: Boolean read FDrawFrame write SetDrawFrame;
    property DrawFocusRing: Boolean read FDrawFocusRing write FDrawFocusRing;
    property AutoContentSize: Boolean read FAutoContentSize write FAutoContentSize;
    property OnScroll: TFtScrollCallback read FOnScroll write FOnScroll;
    property OnScrollEvent: TFtScrollEvent read FOnScrollEvent write FOnScrollEvent;
    property UserData: Pointer read FUserData write FUserData;
  end;

implementation

{ TFtContainer }

constructor TFtContainer.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FFocusable := False;
  FScrollBarMode := ftSbModeAutoBoth;
  FScrollX := 0.0;
  FScrollY := 0.0;
  FLastIntScrollX := 0;
  FLastIntScrollY := 0;
  FContentWidth := 0.0;
  FContentHeight := 0.0;
  FCornerRadius := -1.0;
  FBackdropBlur := 0.0;
  FPaddingX := 8.0;
  FPaddingY := 6.0;
  FDrawFrame := True;
  FDrawFocusRing := True;
  FAutoContentSize := True;
  FOnScroll := nil;
  FOnScrollEvent := nil;
  FUserData := nil;

  Width := 200;
  Height := 150;

  FVScrollBar := TFtScrollBar.Create(Self, ftSbVertical);
  FVScrollBar.OnScrollEvent := @HandleVScroll;
  FHScrollBar := TFtScrollBar.Create(Self, ftSbHorizontal);
  FHScrollBar.OnScrollEvent := @HandleHScroll;
end;

destructor TFtContainer.Destroy();
begin
  FVScrollBar := nil;
  FHScrollBar := nil;
  inherited Destroy();
end;

function TFtContainer.GetElementType(): string;
begin
  Result := 'container';
end;

procedure TFtContainer.SetScrollBarMode(AValue: TFtScrollBarMode);
begin
  if FScrollBarMode <> AValue then
  begin
    FScrollBarMode := AValue;
    UpdateScrollBars();
    Invalidate();
  end;
end;

procedure TFtContainer.SetScrollX(AValue: Double);
var
  clamped: Double;
  newInt, delta: Integer;
begin
  clamped := AValue;
  if clamped < 0.0 then clamped := 0.0;
  if Abs(FScrollX - clamped) > 1e-4 then
  begin
    FScrollX := clamped;
    newInt := Round(FScrollX);
    delta := newInt - FLastIntScrollX;
    FLastIntScrollX := newInt;
    if delta <> 0 then
      ShiftChildren(delta, 0);
    if Assigned(FHScrollBar) and FHScrollBar.Visible then
      FHScrollBar.Value := FScrollX;
    Invalidate();
    if Assigned(FOnScrollEvent) then
      FOnScrollEvent(Self, FScrollX);
    if Assigned(FOnScroll) then
      FOnScroll(Self, FScrollX, FUserData);
  end;
end;

procedure TFtContainer.SetScrollY(AValue: Double);
var
  clamped: Double;
  newInt, delta: Integer;
begin
  clamped := AValue;
  if clamped < 0.0 then clamped := 0.0;
  if Abs(FScrollY - clamped) > 1e-4 then
  begin
    FScrollY := clamped;
    newInt := Round(FScrollY);
    delta := newInt - FLastIntScrollY;
    FLastIntScrollY := newInt;
    if delta <> 0 then
      ShiftChildren(0, delta);
    if Assigned(FVScrollBar) and FVScrollBar.Visible then
      FVScrollBar.Value := FScrollY;
    Invalidate();
    if Assigned(FOnScrollEvent) then
      FOnScrollEvent(Self, FScrollY);
    if Assigned(FOnScroll) then
      FOnScroll(Self, FScrollY, FUserData);
  end;
end;

procedure TFtContainer.SetCornerRadius(AValue: Double);
begin
  if Abs(FCornerRadius - AValue) > 1e-4 then
  begin
    FCornerRadius := AValue;
    Invalidate();
  end;
end;

procedure TFtContainer.SetBackdropBlur(AValue: Double);
begin
  if AValue < 0.0 then AValue := 0.0;
  if Abs(FBackdropBlur - AValue) > 1e-4 then
  begin
    FBackdropBlur := AValue;
    Invalidate();
  end;
end;

procedure TFtContainer.SetContentWidth(AValue: Double);
begin
  if Abs(FContentWidth - AValue) > 1e-4 then
  begin
    FContentWidth := Math.Max(0.0, AValue);
    UpdateScrollBars();
    Invalidate();
  end;
end;

procedure TFtContainer.SetContentHeight(AValue: Double);
begin
  if Abs(FContentHeight - AValue) > 1e-4 then
  begin
    FContentHeight := Math.Max(0.0, AValue);
    UpdateScrollBars();
    Invalidate();
  end;
end;

procedure TFtContainer.SetContentSize(AWidth, AHeight: Double);
begin
  FAutoContentSize := False;
  FContentWidth := Math.Max(0.0, AWidth);
  FContentHeight := Math.Max(0.0, AHeight);
  UpdateScrollBars();
  Invalidate();
end;

procedure TFtContainer.SetPadding(APaddingX, APaddingY: Double);
begin
  FPaddingX := APaddingX;
  FPaddingY := APaddingY;
  UpdateScrollBars();
  Invalidate();
end;

procedure TFtContainer.SetDrawFrame(AValue: Boolean);
begin
  if FDrawFrame <> AValue then
  begin
    FDrawFrame := AValue;
    Invalidate();
  end;
end;

procedure TFtContainer.SetPaddingX(AValue: Double);
begin
  if Abs(FPaddingX - AValue) > 1e-4 then
  begin
    FPaddingX := AValue;
    UpdateScrollBars();
    Invalidate();
  end;
end;

procedure TFtContainer.SetPaddingY(AValue: Double);
begin
  if Abs(FPaddingY - AValue) > 1e-4 then
  begin
    FPaddingY := AValue;
    UpdateScrollBars();
    Invalidate();
  end;
end;

procedure TFtContainer.HandleVScroll(Sender: TObject; Value: Double);
begin
  if Abs(FScrollY - Value) > 1e-4 then
    SetScrollY(Value);
end;

procedure TFtContainer.HandleHScroll(Sender: TObject; Value: Double);
begin
  if Abs(FScrollX - Value) > 1e-4 then
    SetScrollX(Value);
end;

procedure TFtContainer.ShiftChildren(DeltaX, DeltaY: Integer);
var
  i: Integer;
  child: TFtWidget;
begin
  if (DeltaX = 0) and (DeltaY = 0) then Exit;

  for i := 0 to Children.Count - 1 do
  begin
    child := TFtWidget(Children[i]);
    if (child <> FVScrollBar) and (child <> FHScrollBar) then
    begin
      child.X := child.X - DeltaX;
      child.Y := child.Y - DeltaY;
    end;
  end;
end;

procedure TFtContainer.AddChildRelative(AWidget: TFtWidget; ARelX, ARelY: Integer);
begin
  if not Assigned(AWidget) then Exit;
  AWidget.X := Round(X + FPaddingX) - FLastIntScrollX + ARelX;
  AWidget.Y := Round(Y + FPaddingY) - FLastIntScrollY + ARelY;
  UpdateScrollBars();
end;

procedure TFtContainer.RecalculateContentSize();
var
  i: Integer;
  child: TFtWidget;
  maxW, maxH: Double;
  relR, relB: Double;
begin
  if not FAutoContentSize then Exit;
  maxW := 0.0;
  maxH := 0.0;
  for i := 0 to Children.Count - 1 do
  begin
    child := TFtWidget(Children[i]);
    if (child <> FVScrollBar) and (child <> FHScrollBar) and child.Visible then
    begin
      relR := (child.X - (X + FPaddingX) + FLastIntScrollX) + child.Width;
      relB := (child.Y - (Y + FPaddingY) + FLastIntScrollY) + child.Height;
      if relR > maxW then maxW := relR;
      if relB > maxH then maxH := relB;
    end;
  end;
  if (maxW > 0.0) or (maxH > 0.0) then
  begin
    FContentWidth := maxW;
    FContentHeight := maxH;
  end;
end;

procedure TFtContainer.GetClientRect(out AX, AY, AW, AH: Double);
var
  vBarW, hBarH: Double;
begin
  vBarW := 0.0;
  hBarH := 0.0;
  if Assigned(FVScrollBar) and FVScrollBar.Visible then
    vBarW := FVScrollBar.Width + 2.0;
  if Assigned(FHScrollBar) and FHScrollBar.Visible then
    hBarH := FHScrollBar.Height + 2.0;

  AX := X + FPaddingX;
  AY := Y + FPaddingY;
  AW := Math.Max(0.0, Width - (FPaddingX * 2.0) - vBarW);
  AH := Math.Max(0.0, Height - (FPaddingY * 2.0) - hBarH);
end;

procedure TFtContainer.UpdateScrollBars();
var
  barThickness: Double;
  vNeeded, hNeeded: Boolean;
  viewW, viewH: Double;
begin
  if (not Assigned(FVScrollBar)) or (not Assigned(FHScrollBar)) then Exit;

  RecalculateContentSize();

  barThickness := 9.0;
  viewW := Math.Max(0.0, Width - (FPaddingX * 2.0));
  viewH := Math.Max(0.0, Height - (FPaddingY * 2.0));

  vNeeded := False;
  hNeeded := False;

  case FScrollBarMode of
    ftSbModeNone:
    begin
      vNeeded := False;
      hNeeded := False;
    end;
    ftSbModeHorizontalOnly:
    begin
      hNeeded := FContentWidth > viewW;
    end;
    ftSbModeVerticalOnly:
    begin
      vNeeded := FContentHeight > viewH;
    end;
    ftSbModeAutoBoth:
    begin
      vNeeded := FContentHeight > viewH;
      if vNeeded then
        hNeeded := FContentWidth > (viewW - barThickness - 2.0)
      else
        hNeeded := FContentWidth > viewW;

      if hNeeded and not vNeeded then
        vNeeded := FContentHeight > (viewH - barThickness - 2.0);
    end;
  end;

  if vNeeded then
    viewW := Math.Max(0.0, viewW - barThickness - 2.0);
  if hNeeded then
    viewH := Math.Max(0.0, viewH - barThickness - 2.0);

  // Clamp scroll positions
  if FContentHeight > viewH then
  begin
    if FScrollY > FContentHeight - viewH then
      SetScrollY(FContentHeight - viewH);
  end
  else
    SetScrollY(0.0);

  if FContentWidth > viewW then
  begin
    if FScrollX > FContentWidth - viewW then
      SetScrollX(FContentWidth - viewW);
  end
  else
    SetScrollX(0.0);

  // Configure VScrollBar
  if FVScrollBar.Visible <> vNeeded then
    FVScrollBar.Visible := vNeeded;
  if vNeeded then
  begin
    FVScrollBar.X := X + Width - Round(barThickness) - 3;
    FVScrollBar.Y := Y + 3;
    FVScrollBar.Width := Round(barThickness);
    if hNeeded then
      FVScrollBar.Height := Height - 6 - Round(barThickness) - 2
    else
      FVScrollBar.Height := Height - 6;
    FVScrollBar.SetRange(0.0, Math.Max(0.0, FContentHeight - viewH), viewH);
    if Abs(FVScrollBar.Value - FScrollY) > 1e-4 then
      FVScrollBar.Value := FScrollY;
    FVScrollBar.Step := 25.0;
  end;

  // Configure HScrollBar
  if FHScrollBar.Visible <> hNeeded then
    FHScrollBar.Visible := hNeeded;
  if hNeeded then
  begin
    FHScrollBar.X := X + 3;
    FHScrollBar.Y := Y + Height - Round(barThickness) - 3;
    if vNeeded then
      FHScrollBar.Width := Width - 6 - Round(barThickness) - 2
    else
      FHScrollBar.Width := Width - 6;
    FHScrollBar.Height := Round(barThickness);
    FHScrollBar.SetRange(0.0, Math.Max(0.0, FContentWidth - viewW), viewW);
    if Abs(FHScrollBar.Value - FScrollX) > 1e-4 then
      FHScrollBar.Value := FScrollX;
    FHScrollBar.Step := 25.0;
  end;
end;

procedure TFtContainer.DrawBackground(Canvas: TFtCanvasAgg);
var
  st: TFtWidgetStyle;
  rad, bw: Double;
  bg: TFtRgbColor;
  cx, cy, cw, ch: Integer;
  drawShadow: Boolean;
  effBlur: Double;
begin
  st := GetResolvedStyle();
  if st.HasBgColor or st.HasBorderColor or st.HasBorderRadius or (FBackdropBlur > 0.5) or st.HasBackdropBlur then
  begin
    if FCornerRadius >= 0.0 then
      rad := FCornerRadius
    else if st.HasBorderRadius then
      rad := st.BorderRadius
    else
      rad := FtGetTheme().CornerRadius;

    // Drop shadow
    drawShadow := (st.HasShadow and st.EnableShadow) or (not st.HasShadow and FtGetTheme().EnableShadow);
    if drawShadow and Canvas.GetClipRect(cx, cy, cw, ch) then
    begin
      // If clip rect is strictly inside the container interior, the outer shadow is not touched
      if (cx >= X + 6) and (cy >= Y + 6) and (cx + cw <= X + Width - 6) and (cy + ch <= Y + Height - 6) then
        drawShadow := False;
    end;
    if drawShadow then
      Canvas.DrawShadow(X, Y, Width, Height, rad, 0.0, 2.0, 4.0, 0.0, 0.0, 0.0, 0.12);

    // Backdrop blur (frosted glass / acrylic effect)
    effBlur := 0.0;
    if FBackdropBlur > 0.5 then
      effBlur := FBackdropBlur
    else if st.HasBackdropBlur and (st.BackdropBlur > 0.5) then
      effBlur := st.BackdropBlur;

    if effBlur > 0.5 then
      Canvas.BlurRoundedRect(X, Y, Width, Height, rad, effBlur);

    // Background
    if st.HasBgColor then
      Canvas.DrawRoundedRect(X, Y, Width, Height, rad, st.BgColor.R, st.BgColor.G, st.BgColor.B, st.BgColor.A)
    else if not ((FBackdropBlur > 0.5) or st.HasBackdropBlur) then
    begin
      bg := FtGetTheme().GetInputBackground();
      Canvas.DrawRoundedRect(X, Y, Width, Height, rad, bg.R, bg.G, bg.B, 1.0);
    end;

    // Border
    bw := 1.0;
    if st.HasBorderWidth then bw := st.BorderWidth;
    if (bw > 0.0) and st.HasBorderColor then
      Canvas.DrawRoundedRectOutline(X, Y, Width, Height, rad, bw, st.BorderColor.R, st.BorderColor.G, st.BorderColor.B, st.BorderColor.A);

    // Focus ring
    if FFocused and FDrawFocusRing then
      FtGetTheme().DrawFocusRing(Canvas, X, Y, Width, Height, rad);
  end
  else
    FtGetTheme().DrawInputPlate(Canvas, X, Y, Width, Height, FFocused and FDrawFocusRing, FCornerRadius);
end;

procedure TFtContainer.DrawContent(Canvas: TFtCanvasAgg);
begin
  // Base container does nothing here; descendants like TFtTextArea override this
end;

procedure TFtContainer.DrawChildren(Canvas: TFtCanvasAgg);
var
  i: Integer;
  child: TFtWidget;
  chOpac: Double;
begin
  for i := 0 to Children.Count - 1 do
  begin
    child := TFtWidget(Children[i]);
    if (child <> FVScrollBar) and (child <> FHScrollBar) and child.Visible then
      if Canvas.IntersectsClip(child.X - 4, child.Y - 4, child.Width + 8, child.Height + 8) then
      begin
        chOpac := child.Opacity;
        if chOpac <= 0.0 then Continue;
        if chOpac < 0.999 then
        begin
          Canvas.PushAlpha(chOpac);
          try
            child.Draw(Canvas);
          finally
            Canvas.PopAlpha();
          end;
        end
        else
          child.Draw(Canvas);
      end;
  end;
end;

procedure TFtContainer.Draw(Canvas: TFtCanvasAgg);
var
  cx, cy, cw, ch: Double;
begin
  if not Visible then Exit;
  if not Canvas.IntersectsClip(X - 4, Y - 4, Width + 8, Height + 8) then Exit;

  UpdateScrollBars();

  if FDrawFrame then
    DrawBackground(Canvas);

  GetClientRect(cx, cy, cw, ch);
  Canvas.SetClipRect(Round(cx), Round(cy), Round(cw), Round(ch));
  try
    DrawContent(Canvas);
    DrawChildren(Canvas);
  finally
    Canvas.ResetClipRect();
  end;

  if Assigned(FVScrollBar) and FVScrollBar.Visible and Canvas.IntersectsClip(FVScrollBar.X - 4, FVScrollBar.Y - 4, FVScrollBar.Width + 8, FVScrollBar.Height + 8) then
    FVScrollBar.Draw(Canvas);
  if Assigned(FHScrollBar) and FHScrollBar.Visible and Canvas.IntersectsClip(FHScrollBar.X - 4, FHScrollBar.Y - 4, FHScrollBar.Width + 8, FHScrollBar.Height + 8) then
    FHScrollBar.Draw(Canvas);
end;

procedure TFtContainer.InvalidateRect(AX, AY, AW, AH: Integer);
var
  ix1, iy1, ix2, iy2: Integer;
begin
  if not Visible then Exit;
  ix1 := AX;
  iy1 := AY;
  ix2 := AX + AW;
  iy2 := AY + AH;
  if ix1 < X - 4 then ix1 := X - 4;
  if iy1 < Y - 4 then iy1 := Y - 4;
  if ix2 > X + Width + 4 then ix2 := X + Width + 4;
  if iy2 > Y + Height + 4 then iy2 := Y + Height + 4;

  if (ix2 > ix1) and (iy2 > iy1) then
  begin
    if Assigned(Parent) then
      Parent.InvalidateRect(ix1, iy1, ix2 - ix1, iy2 - iy1);
  end;
end;

function TFtContainer.HitTest(AX, AY: Integer): TFtWidget;
var
  i: Integer;
  child, target: TFtWidget;
  cx, cy, cw, ch: Double;
begin
  Result := nil;
  if not Visible then Exit;

  UpdateScrollBars();

  // Test scrollbars first
  if Assigned(FVScrollBar) and FVScrollBar.Visible then
  begin
    target := FVScrollBar.HitTest(AX, AY);
    if Assigned(target) then Exit(target);
  end;
  if Assigned(FHScrollBar) and FHScrollBar.Visible then
  begin
    target := FHScrollBar.HitTest(AX, AY);
    if Assigned(target) then Exit(target);
  end;

  // Test children within client area
  GetClientRect(cx, cy, cw, ch);
  if (AX >= cx) and (AX <= cx + cw) and (AY >= cy) and (AY <= cy + ch) then
  begin
    for i := Children.Count - 1 downto 0 do
    begin
      child := TFtWidget(Children[i]);
      if (child <> FVScrollBar) and (child <> FHScrollBar) and child.Visible then
      begin
        target := child.HitTest(AX, AY);
        if Assigned(target) then
          Exit(target);
      end;
    end;
  end;

  // Otherwise check container bounds
  if (AX >= X) and (AX <= X + Width) and (AY >= Y) and (AY <= Y + Height) then
    Result := Self;
end;

procedure TFtContainer.MouseDown(AX, AY: Integer; AButton: Integer);
begin
  // Mouse wheel
  if AButton = 4 then
  begin
    SetScrollY(FScrollY - 30.0);
    Exit;
  end;
  if AButton = 5 then
  begin
    SetScrollY(FScrollY + 30.0);
    Exit;
  end;
  if AButton = 6 then
  begin
    SetScrollX(FScrollX - 30.0);
    Exit;
  end;
  if AButton = 7 then
  begin
    SetScrollX(FScrollX + 30.0);
    Exit;
  end;

  inherited MouseDown(AX, AY, AButton);

  if FFocusable and (AButton = 1) then
    SetFocus();
end;

end.
