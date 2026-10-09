unit Ft.Widget.Layouts;

// Ft.Widget.Layouts
// =================
// Micro-Flexbox responsive layout engine for Floria Toolkit.
// Provides declarative, constraint-driven child positioning along
// main and cross axes without manual coordinate math.
//
// Highlights:
//   - TFtFlexDirection: ftfdRow (horizontal), ftfdColumn (vertical)
//   - TFtJustifyContent: ftjcStart, ftjcCenter, ftjcEnd, ftjcSpaceBetween, ftjcSpaceAround, ftjcSpaceEvenly
//   - TFtAlignItems: ftaiStretch, ftaiStart, ftaiCenter, ftaiEnd
//   - TFtSpacer: Transparent auto-stretching spacer (equivalent to Qt addStretch / Flutter Spacer)
//   - TFtFlexBox: Core flex container inheriting from TFtContainer
//   - TFtHBox: Horizontal convenience container (ftfdRow, ftaiCenter)
//   - TFtVBox: Vertical convenience container (ftfdColumn, ftaiStretch)

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Math,
  Ft.Canvas, Ft.Widget, Ft.Widget.ScrollBars, Ft.Widget.Containers, Ft.Theme, Ft.Css;

type
  TFtFlexDirection = (
    ftfdRow = 0,
    ftfdColumn = 1
  );

  TFtJustifyContent = (
    ftjcStart = 0,
    ftjcCenter = 1,
    ftjcEnd = 2,
    ftjcSpaceBetween = 3,
    ftjcSpaceAround = 4,
    ftjcSpaceEvenly = 5
  );

  TFtAlignItems = (
    ftaiStretch = 0,
    ftaiStart = 1,
    ftaiCenter = 2,
    ftaiEnd = 3
  );

  TFtFlexWrap = (
    ftfwNoWrap = 0,
    ftfwWrap = 1,
    ftfwWrapReverse = 2
  );

  { TFtSpacer — transparent stretchable item absorbing flex room }
  TFtSpacer = class(TFtWidget)
  public
    constructor Create(AParent: TFtWidget); override;
    function GetElementType(): string; override;
    procedure Draw(Canvas: TFtCanvas); override;
    function HitTest(AX, AY: Integer): TFtWidget; override;
  end;

  { TFtFlexBox — Micro-Flexbox container }
  TFtFlexBox = class(TFtContainer)
  protected
    FDirection: TFtFlexDirection;
    FWrap: TFtFlexWrap;
    FJustifyContent: TFtJustifyContent;
    FAlignItems: TFtAlignItems;
    FGap: Double;
    procedure SetDirection(AValue: TFtFlexDirection); virtual;
    procedure SetWrap(AValue: TFtFlexWrap); virtual;
    procedure SetJustifyContent(AValue: TFtJustifyContent); virtual;
    procedure SetAlignItems(AValue: TFtAlignItems); virtual;
    procedure SetGap(AValue: Double); virtual;
  public
    constructor Create(AParent: TFtWidget); override;
    function GetElementType(): string; override;
    function GetEffectiveCornerRadius(): Double; override;
    function GetChildRenderArea(out AX, AY, AW, AH, ARadius: Double): Boolean; override;
    procedure Draw(Canvas: TFtCanvas); override;
    procedure DrawBackground(Canvas: TFtCanvas); override;
    function HitTest(AX, AY: Integer): TFtWidget; override;
    procedure UpdateLayout(); override;
    procedure UpdateScrollBars(); override;
    procedure SetBounds(AX, AY, AW, AH: Integer); override;
    function AddSpacer(AGrow: Double = 1.0): TFtSpacer;

    property Direction: TFtFlexDirection read FDirection write SetDirection;
    property Wrap: TFtFlexWrap read FWrap write SetWrap;
    property JustifyContent: TFtJustifyContent read FJustifyContent write SetJustifyContent;
    property AlignItems: TFtAlignItems read FAlignItems write SetAlignItems;
    property Gap: Double read FGap write SetGap;
  end;

  { TFtHBox — Horizontal flexbox }
  TFtHBox = class(TFtFlexBox)
  public
    constructor Create(AParent: TFtWidget); override;
    function GetElementType(): string; override;
  end;

  { TFtVBox — Vertical flexbox }
  TFtVBox = class(TFtFlexBox)
  public
    constructor Create(AParent: TFtWidget); override;
    function GetElementType(): string; override;
  end;

implementation

{ TFtSpacer }

constructor TFtSpacer.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FFlexGrow := 1.0;
  FFlexBasis := 0.0;
  Width := 0;
  Height := 0;
  Visible := True;
end;

procedure TFtSpacer.Draw(Canvas: TFtCanvas);
begin
  // Spacers are invisible fillers; nothing to draw
end;

function TFtSpacer.HitTest(AX, AY: Integer): TFtWidget;
begin
  Result := nil;
end;

function TFtSpacer.GetElementType(): string;
begin
  Result := 'spacer';
end;

{ TFtFlexBox }

constructor TFtFlexBox.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FPaddingX := 0.0;
  FPaddingY := 0.0;
  FDirection := ftfdRow;
  FWrap := ftfwNoWrap;
  FJustifyContent := ftjcStart;
  FAlignItems := ftaiStretch;
  FGap := 0.0;
  FDrawFrame := False;
  FDrawFocusRing := False;
  FCornerRadius := 0.0;
  FScrollBarMode := ftSbModeNone;
  FAutoContentSize := False;
  if Assigned(FVScrollBar) then FVScrollBar.Visible := False;
  if Assigned(FHScrollBar) then FHScrollBar.Visible := False;
end;

function TFtFlexBox.GetElementType(): string;
begin
  Result := 'flexbox';
end;

function TFtFlexBox.GetEffectiveCornerRadius(): Double;
var
  st: TFtWidgetStyle;
begin
  if FCornerRadius >= 0.0 then
    Result := FCornerRadius
  else
  begin
    st := GetResolvedStyle();
    if st.HasBorderRadius then
      Result := st.BorderRadius
    else
      Result := 0.0;
  end;
end;

function TFtFlexBox.GetChildRenderArea(out AX, AY, AW, AH, ARadius: Double): Boolean;
var
  st: TFtWidgetStyle;
begin
  st := GetResolvedStyle();
  if st.HasBgColor or (st.HasBorderColor and (st.BorderWidth > 0.0)) or FDrawFrame or (FBackdropBlur > 0.5) or st.HasBackdropBlur then
    Result := inherited GetChildRenderArea(AX, AY, AW, AH, ARadius)
  else if Assigned(Parent) then
    Result := Parent.GetChildRenderArea(AX, AY, AW, AH, ARadius)
  else
  begin
    AX := 0.0; AY := 0.0; AW := 0.0; AH := 0.0; ARadius := 0.0;
    Result := False;
  end;
end;

procedure TFtFlexBox.DrawBackground(Canvas: TFtCanvas);
var
  st: TFtWidgetStyle;
begin
  st := GetResolvedStyle();
  // Flexboxes are completely transparent by default ("like it's nothing there").
  // Only draw background/border/shadow if explicitly styled via CSS or if DrawFrame is enabled.
  if st.HasBgColor or (st.HasBorderColor and (st.BorderWidth > 0.0)) or FDrawFrame or (FBackdropBlur > 0.5) or st.HasBackdropBlur then
    inherited DrawBackground(Canvas);
end;

procedure TFtFlexBox.Draw(Canvas: TFtCanvas);
var
  st: TFtWidgetStyle;
begin
  if not Visible then Exit;
  if not Canvas.IntersectsClip(X - 4, Y - 4, Width + 8, Height + 8) then Exit;

  st := GetResolvedStyle();
  if st.HasBgColor or (st.HasBorderColor and (st.BorderWidth > 0.0)) or FDrawFrame or (FBackdropBlur > 0.5) or st.HasBackdropBlur then
  begin
    // Explicitly styled flexbox: draw background, border, shadow, and clip to render area
    inherited Draw(Canvas);
  end
  else
  begin
    // Pure transparent flexbox layout: draw children directly with no background, border, or rounded clip
    DrawChildren(Canvas);
  end;
end;

function TFtFlexBox.HitTest(AX, AY: Integer): TFtWidget;
var
  i: Integer;
  child, target: TFtWidget;
  st: TFtWidgetStyle;
begin
  Result := nil;
  if not Visible then Exit;

  // 1. Check children first
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

  // 2. Only catch clicks if flexbox has an explicit visible background or frame
  st := GetResolvedStyle();
  if (FDrawFrame or st.HasBgColor or (FBackdropBlur > 0.5) or st.HasBackdropBlur) and
     (AX >= X) and (AX <= X + Width) and (AY >= Y) and (AY <= Y + Height) then
    Result := Self;
end;

procedure TFtFlexBox.UpdateScrollBars();
begin
  if FScrollBarMode = ftSbModeNone then
  begin
    if Assigned(FVScrollBar) then FVScrollBar.Visible := False;
    if Assigned(FHScrollBar) then FHScrollBar.Visible := False;
    FScrollX := 0.0;
    FScrollY := 0.0;
    FLastIntScrollX := 0;
    FLastIntScrollY := 0;
    Exit;
  end;
  inherited UpdateScrollBars();
end;

procedure TFtFlexBox.SetDirection(AValue: TFtFlexDirection);
begin
  if FDirection <> AValue then
  begin
    FDirection := AValue;
    UpdateLayout();
    Invalidate();
  end;
end;

procedure TFtFlexBox.SetWrap(AValue: TFtFlexWrap);
begin
  if FWrap <> AValue then
  begin
    FWrap := AValue;
    UpdateLayout();
    Invalidate();
  end;
end;

procedure TFtFlexBox.SetJustifyContent(AValue: TFtJustifyContent);
begin
  if FJustifyContent <> AValue then
  begin
    FJustifyContent := AValue;
    UpdateLayout();
    Invalidate();
  end;
end;

procedure TFtFlexBox.SetAlignItems(AValue: TFtAlignItems);
begin
  if FAlignItems <> AValue then
  begin
    FAlignItems := AValue;
    UpdateLayout();
    Invalidate();
  end;
end;

procedure TFtFlexBox.SetGap(AValue: Double);
begin
  if Abs(FGap - AValue) > 1e-4 then
  begin
    FGap := AValue;
    UpdateLayout();
    Invalidate();
  end;
end;

procedure TFtFlexBox.SetBounds(AX, AY, AW, AH: Integer);
begin
  inherited SetBounds(AX, AY, AW, AH);
  UpdateLayout();
end;

function TFtFlexBox.AddSpacer(AGrow: Double): TFtSpacer;
begin
  Result := TFtSpacer.Create(Self);
  Result.FlexGrow := AGrow;
  UpdateLayout();
end;

type
  TFtFlexLine = record
    startIndex: Integer;
    count: Integer;
    totalBaseMain: Double;
    totalGrow: Double;
    totalShrink: Double;
    crossSize: Double;
  end;

procedure TFtFlexBox.UpdateLayout();
var
  i, numVisible: Integer;
  child: TFtWidget;
  visibleItems: array of TFtWidget;
  isRow: Boolean;
  padLeft, padRight, padTop, padBottom: Double;
  availMain, availCross: Double;
  mainStart, crossStart: Double;
  baseSizes: array of Double;
  finalMainSizes: array of Double;
  finalCrossSizes: array of Double;
  mainMarginBefore, mainMarginAfter: array of Double;
  crossMarginBefore, crossMarginAfter: array of Double;
  curMainPos, curCrossPos: Double;
  effAlign: TFtAlignSelf;
  spacingOffset, itemGap: Double;
  childMain, childCross: Double;
  shrinkFactor: Double;
  st, chSt: TFtWidgetStyle;
  flexLines: array of TFtFlexLine;
  numLines, l, lStart, lCount, idx: Integer;
  itemOuterMain, itemOuterCross: Double;
  lineRem, lineActualMain, lineGapTotal: Double;
  totalLinesCross, curLineCrossPos, lineCrossBase: Double;
begin
  if not Assigned(Children) or (Children.Count = 0) then Exit;
  if (Width <= 0) or (Height <= 0) then Exit;

  // 1. Resolve CSS style properties on the flex container
  st := GetResolvedStyle();
  if st.HasFlexDirection then
  begin
    if SameText(st.FlexDirection, 'column') or SameText(st.FlexDirection, 'column-reverse') then
      FDirection := ftfdColumn
    else
      FDirection := ftfdRow;
  end;
  if st.HasFlexWrap then
  begin
    if SameText(st.FlexWrap, 'wrap') then
      FWrap := ftfwWrap
    else if SameText(st.FlexWrap, 'wrap-reverse') then
      FWrap := ftfwWrapReverse
    else
      FWrap := ftfwNoWrap;
  end;
  if st.HasJustifyContent then
  begin
    if SameText(st.JustifyContent, 'center') then
      FJustifyContent := ftjcCenter
    else if SameText(st.JustifyContent, 'flex-end') or SameText(st.JustifyContent, 'end') then
      FJustifyContent := ftjcEnd
    else if SameText(st.JustifyContent, 'space-between') then
      FJustifyContent := ftjcSpaceBetween
    else if SameText(st.JustifyContent, 'space-around') then
      FJustifyContent := ftjcSpaceAround
    else if SameText(st.JustifyContent, 'space-evenly') then
      FJustifyContent := ftjcSpaceEvenly
    else
      FJustifyContent := ftjcStart;
  end;
  if st.HasAlignItems then
  begin
    if SameText(st.AlignItems, 'center') then
      FAlignItems := ftaiCenter
    else if SameText(st.AlignItems, 'flex-start') or SameText(st.AlignItems, 'start') then
      FAlignItems := ftaiStart
    else if SameText(st.AlignItems, 'flex-end') or SameText(st.AlignItems, 'end') then
      FAlignItems := ftaiEnd
    else
      FAlignItems := ftaiStretch;
  end;
  if st.HasGap then
    FGap := st.Gap;

  // 2. Determine padding & available inner space
  padLeft := FPaddingX;
  padRight := FPaddingX;
  padTop := FPaddingY;
  padBottom := FPaddingY;

  isRow := (FDirection = ftfdRow);
  if isRow then
  begin
    availMain := Max(0.0, Width - (padLeft + padRight));
    availCross := Max(0.0, Height - (padTop + padBottom));
    mainStart := X + padLeft;
    crossStart := Y + padTop;
  end
  else
  begin
    availMain := Max(0.0, Height - (padTop + padBottom));
    availCross := Max(0.0, Width - (padLeft + padRight));
    mainStart := Y + padTop;
    crossStart := X + padLeft;
  end;

  // 3. Filter visible layout children
  numVisible := 0;
  SetLength(visibleItems, Children.Count);
  for i := 0 to Children.Count - 1 do
  begin
    child := TFtWidget(Children[i]);
    if child.Visible and (child <> FVScrollBar) and (child <> FHScrollBar) then
    begin
      visibleItems[numVisible] := child;
      Inc(numVisible);
    end;
  end;
  SetLength(visibleItems, numVisible);

  if numVisible = 0 then Exit;

  // 4. Allocate metric arrays & inspect child styles
  SetLength(baseSizes, numVisible);
  SetLength(finalMainSizes, numVisible);
  SetLength(finalCrossSizes, numVisible);
  SetLength(mainMarginBefore, numVisible);
  SetLength(mainMarginAfter, numVisible);
  SetLength(crossMarginBefore, numVisible);
  SetLength(crossMarginAfter, numVisible);

  for i := 0 to numVisible - 1 do
  begin
    child := visibleItems[i];
    chSt := child.GetResolvedStyle();
    if chSt.HasFlexGrow then child.FlexGrow := chSt.FlexGrow;
    if chSt.HasFlexShrink then child.FlexShrink := chSt.FlexShrink;
    if chSt.HasFlexBasis then child.FlexBasis := chSt.FlexBasis;
    if chSt.HasAlignSelf then
    begin
      if SameText(chSt.AlignSelf, 'stretch') then child.AlignSelf := ftasStretch
      else if SameText(chSt.AlignSelf, 'center') then child.AlignSelf := ftasCenter
      else if SameText(chSt.AlignSelf, 'flex-start') or SameText(chSt.AlignSelf, 'start') then child.AlignSelf := ftasStart
      else if SameText(chSt.AlignSelf, 'flex-end') or SameText(chSt.AlignSelf, 'end') then child.AlignSelf := ftasEnd
      else child.AlignSelf := ftasAuto;
    end;
    if chSt.HasMarginLeft then child.MarginLeft := Round(chSt.MarginLeft);
    if chSt.HasMarginRight then child.MarginRight := Round(chSt.MarginRight);
    if chSt.HasMarginTop then child.MarginTop := Round(chSt.MarginTop);
    if chSt.HasMarginBottom then child.MarginBottom := Round(chSt.MarginBottom);

    if isRow then
    begin
      mainMarginBefore[i] := child.MarginLeft;
      mainMarginAfter[i] := child.MarginRight;
      crossMarginBefore[i] := child.MarginTop;
      crossMarginAfter[i] := child.MarginBottom;
    end
    else
    begin
      mainMarginBefore[i] := child.MarginTop;
      mainMarginAfter[i] := child.MarginBottom;
      crossMarginBefore[i] := child.MarginLeft;
      crossMarginAfter[i] := child.MarginRight;
    end;

    // Lock in preferred dimensions before layout mutations if not yet captured
    if (child.PreferredWidth <= 0) and (child.Width > 0) then
      child.PreferredWidth := child.Width;
    if (child.PreferredHeight <= 0) and (child.Height > 0) then
      child.PreferredHeight := child.Height;

    // Base main size
    if child.FlexBasis >= 0.0 then
      baseSizes[i] := child.FlexBasis
    else if child is TFtSpacer then
      baseSizes[i] := 0.0
    else if child.FlexGrow > 0.0 then
      baseSizes[i] := 0.0
    else
    begin
      if isRow then
        baseSizes[i] := child.GetPreferredWidth()
      else
        baseSizes[i] := child.GetPreferredHeight();
    end;

    // Cross natural size
    if isRow then
      finalCrossSizes[i] := child.GetPreferredHeight()
    else
      finalCrossSizes[i] := child.GetPreferredWidth();
  end;

  // 5. Group items into flex lines (respecting FWrap)
  SetLength(flexLines, numVisible);
  numLines := 1;
  flexLines[0].startIndex := 0;
  flexLines[0].count := 0;
  flexLines[0].totalBaseMain := 0.0;
  flexLines[0].totalGrow := 0.0;
  flexLines[0].totalShrink := 0.0;
  flexLines[0].crossSize := 0.0;

  for i := 0 to numVisible - 1 do
  begin
    itemOuterMain := baseSizes[i] + mainMarginBefore[i] + mainMarginAfter[i];
    itemOuterCross := finalCrossSizes[i] + crossMarginBefore[i] + crossMarginAfter[i];

    if (FWrap <> ftfwNoWrap) and (flexLines[numLines - 1].count > 0) then
    begin
      if (flexLines[numLines - 1].totalBaseMain + FGap + itemOuterMain > availMain) then
      begin
        Inc(numLines);
        flexLines[numLines - 1].startIndex := i;
        flexLines[numLines - 1].count := 0;
        flexLines[numLines - 1].totalBaseMain := 0.0;
        flexLines[numLines - 1].totalGrow := 0.0;
        flexLines[numLines - 1].totalShrink := 0.0;
        flexLines[numLines - 1].crossSize := 0.0;
      end;
    end;

    if flexLines[numLines - 1].count > 0 then
      flexLines[numLines - 1].totalBaseMain := flexLines[numLines - 1].totalBaseMain + FGap + itemOuterMain
    else
      flexLines[numLines - 1].totalBaseMain := itemOuterMain;

    Inc(flexLines[numLines - 1].count);
    flexLines[numLines - 1].totalGrow := flexLines[numLines - 1].totalGrow + visibleItems[i].FlexGrow;
    flexLines[numLines - 1].totalShrink := flexLines[numLines - 1].totalShrink + (visibleItems[i].FlexShrink * baseSizes[i]);
    if itemOuterCross > flexLines[numLines - 1].crossSize then
      flexLines[numLines - 1].crossSize := itemOuterCross;
  end;
  SetLength(flexLines, numLines);

  // If single line with nowrap, line's cross size is full availCross
  if (numLines = 1) and (FWrap = ftfwNoWrap) then
    flexLines[0].crossSize := availCross;

  // 6. Distribute growth or shrinkage along main axis per line
  for l := 0 to numLines - 1 do
  begin
    lineRem := availMain - flexLines[l].totalBaseMain;
    lStart := flexLines[l].startIndex;
    lCount := flexLines[l].count;

    if (lineRem > 0.0) and (flexLines[l].totalGrow > 0.0) then
    begin
      for idx := lStart to lStart + lCount - 1 do
      begin
        child := visibleItems[idx];
        if child.FlexGrow > 0.0 then
          finalMainSizes[idx] := baseSizes[idx] + (lineRem * (child.FlexGrow / flexLines[l].totalGrow))
        else
          finalMainSizes[idx] := baseSizes[idx];
      end;
    end
    else if (lineRem < 0.0) and (flexLines[l].totalShrink > 0.0) then
    begin
      shrinkFactor := Abs(lineRem) / flexLines[l].totalShrink;
      for idx := lStart to lStart + lCount - 1 do
      begin
        child := visibleItems[idx];
        finalMainSizes[idx] := Max(0.0, baseSizes[idx] - (child.FlexShrink * baseSizes[idx] * shrinkFactor));
      end;
    end
    else
    begin
      for idx := lStart to lStart + lCount - 1 do
        finalMainSizes[idx] := baseSizes[idx];
    end;
  end;

  // 7. Calculate cross-axis line starting position
  totalLinesCross := 0.0;
  for l := 0 to numLines - 1 do
    totalLinesCross := totalLinesCross + flexLines[l].crossSize;
  totalLinesCross := totalLinesCross + Max(0, numLines - 1) * FGap;

  if FWrap = ftfwWrapReverse then
    curLineCrossPos := crossStart + totalLinesCross
  else
    curLineCrossPos := crossStart;

  // 8. Place children per line
  for l := 0 to numLines - 1 do
  begin
    lStart := flexLines[l].startIndex;
    lCount := flexLines[l].count;

    lineActualMain := 0.0;
    for idx := lStart to lStart + lCount - 1 do
      lineActualMain := lineActualMain + finalMainSizes[idx] + mainMarginBefore[idx] + mainMarginAfter[idx];
    lineGapTotal := FGap * Max(0, lCount - 1);
    lineRem := availMain - (lineActualMain + lineGapTotal);

    spacingOffset := 0.0;
    itemGap := FGap;
    if (lineRem > 0.0) and (flexLines[l].totalGrow = 0.0) then
    begin
      case FJustifyContent of
        ftjcStart:        spacingOffset := 0.0;
        ftjcCenter:       spacingOffset := lineRem * 0.5;
        ftjcEnd:          spacingOffset := lineRem;
        ftjcSpaceBetween: if lCount > 1 then itemGap := FGap + (lineRem / (lCount - 1));
        ftjcSpaceAround:  begin itemGap := FGap + (lineRem / lCount); spacingOffset := (lineRem / lCount) * 0.5; end;
        ftjcSpaceEvenly:  begin itemGap := FGap + (lineRem / (lCount + 1)); spacingOffset := lineRem / (lCount + 1); end;
      end;
    end;

    curMainPos := mainStart + spacingOffset;

    if FWrap = ftfwWrapReverse then
      lineCrossBase := curLineCrossPos - flexLines[l].crossSize
    else
      lineCrossBase := curLineCrossPos;

    for idx := lStart to lStart + lCount - 1 do
    begin
      child := visibleItems[idx];
      childMain := finalMainSizes[idx];
      curMainPos := curMainPos + mainMarginBefore[idx];

      effAlign := child.AlignSelf;
      if effAlign = ftasAuto then
      begin
        case FAlignItems of
          ftaiStretch: effAlign := ftasStretch;
          ftaiStart:   effAlign := ftasStart;
          ftaiCenter:  effAlign := ftasCenter;
          ftaiEnd:     effAlign := ftasEnd;
        end;
      end;

      if effAlign = ftasStretch then
        childCross := Max(0.0, flexLines[l].crossSize - (crossMarginBefore[idx] + crossMarginAfter[idx]))
      else
        childCross := finalCrossSizes[idx];

      case effAlign of
        ftasStart, ftasStretch:
          curCrossPos := lineCrossBase + crossMarginBefore[idx];
        ftasCenter:
          curCrossPos := lineCrossBase + crossMarginBefore[idx] +
            ((flexLines[l].crossSize - (crossMarginBefore[idx] + crossMarginAfter[idx])) - childCross) * 0.5;
        ftasEnd:
          curCrossPos := lineCrossBase + flexLines[l].crossSize - crossMarginAfter[idx] - childCross;
        else
          curCrossPos := lineCrossBase + crossMarginBefore[idx];
      end;

      if isRow then
      begin
        child.X := Round(curMainPos);
        child.Y := Round(curCrossPos);
        child.Width := Round(childMain);
        child.Height := Round(childCross);
      end
      else
      begin
        child.X := Round(curCrossPos);
        child.Y := Round(curMainPos);
        child.Width := Round(childCross);
        child.Height := Round(childMain);
      end;

      child.Invalidate();
      child.UpdateLayout();

      curMainPos := curMainPos + childMain + mainMarginAfter[idx] + itemGap;
    end;

    if FWrap = ftfwWrapReverse then
      curLineCrossPos := curLineCrossPos - (flexLines[l].crossSize + FGap)
    else
      curLineCrossPos := curLineCrossPos + flexLines[l].crossSize + FGap;
  end;
end;

{ TFtHBox }

constructor TFtHBox.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FDirection := ftfdRow;
  FAlignItems := ftaiStretch;
end;

function TFtHBox.GetElementType(): string;
begin
  Result := 'hbox';
end;

{ TFtVBox }

constructor TFtVBox.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FDirection := ftfdColumn;
  FAlignItems := ftaiStretch;
end;

function TFtVBox.GetElementType(): string;
begin
  Result := 'vbox';
end;

end.
