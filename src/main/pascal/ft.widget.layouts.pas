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

  { TFtSpacer — transparent stretchable item absorbing flex room }
  TFtSpacer = class(TFtWidget)
  public
    constructor Create(AParent: TFtWidget); override;
    procedure Draw(Canvas: TFtCanvas); override;
    function HitTest(AX, AY: Integer): TFtWidget; override;
  end;

  { TFtFlexBox — Micro-Flexbox container }
  TFtFlexBox = class(TFtContainer)
  protected
    FDirection: TFtFlexDirection;
    FJustifyContent: TFtJustifyContent;
    FAlignItems: TFtAlignItems;
    FGap: Double;
    procedure SetDirection(AValue: TFtFlexDirection); virtual;
    procedure SetJustifyContent(AValue: TFtJustifyContent); virtual;
    procedure SetAlignItems(AValue: TFtAlignItems); virtual;
    procedure SetGap(AValue: Double); virtual;
  public
    constructor Create(AParent: TFtWidget); override;
    procedure UpdateLayout(); override;
    procedure UpdateScrollBars(); override;
    procedure SetBounds(AX, AY, AW, AH: Integer); override;
    function AddSpacer(AGrow: Double = 1.0): TFtSpacer;

    property Direction: TFtFlexDirection read FDirection write SetDirection;
    property JustifyContent: TFtJustifyContent read FJustifyContent write SetJustifyContent;
    property AlignItems: TFtAlignItems read FAlignItems write SetAlignItems;
    property Gap: Double read FGap write SetGap;
  end;

  { TFtHBox — Horizontal flexbox }
  TFtHBox = class(TFtFlexBox)
  public
    constructor Create(AParent: TFtWidget); override;
  end;

  { TFtVBox — Vertical flexbox }
  TFtVBox = class(TFtFlexBox)
  public
    constructor Create(AParent: TFtWidget); override;
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

{ TFtFlexBox }

constructor TFtFlexBox.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FPaddingX := 0.0;
  FPaddingY := 0.0;
  FDirection := ftfdRow;
  FJustifyContent := ftjcStart;
  FAlignItems := ftaiStretch;
  FGap := 0.0;
  FDrawFrame := False;
  FDrawFocusRing := False;
  FScrollBarMode := ftSbModeNone;
  FAutoContentSize := False;
  if Assigned(FVScrollBar) then FVScrollBar.Visible := False;
  if Assigned(FHScrollBar) then FHScrollBar.Visible := False;
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
  totalBaseMain: Double;
  totalGrow: Double;
  remainingSpace: Double;
  gapTotal: Double;
  curMainPos, curCrossPos: Double;
  effAlign: TFtAlignSelf;
  spacingOffset, itemGap: Double;
  childMain, childCross: Double;
  totalShrink, shrinkFactor: Double;
begin
  if not Assigned(Children) or (Children.Count = 0) then Exit;
  if (Width <= 0) or (Height <= 0) then Exit;

  // 1. Determine padding & available inner space
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

  // 2. Filter visible layout children (ignore invisible and internal scrollbars)
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

  // 3. Allocate metric arrays
  SetLength(baseSizes, numVisible);
  SetLength(finalMainSizes, numVisible);
  SetLength(finalCrossSizes, numVisible);
  SetLength(mainMarginBefore, numVisible);
  SetLength(mainMarginAfter, numVisible);
  SetLength(crossMarginBefore, numVisible);
  SetLength(crossMarginAfter, numVisible);

  totalBaseMain := 0.0;
  totalGrow := 0.0;
  totalShrink := 0.0;

  for i := 0 to numVisible - 1 do
  begin
    child := visibleItems[i];
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

    totalBaseMain := totalBaseMain + baseSizes[i] + mainMarginBefore[i] + mainMarginAfter[i];
    totalGrow := totalGrow + child.FlexGrow;
    totalShrink := totalShrink + (child.FlexShrink * baseSizes[i]);
  end;

  gapTotal := FGap * Max(0, numVisible - 1);
  remainingSpace := availMain - (totalBaseMain + gapTotal);

  // 4. Distribute growth or shrinkage along main axis
  if (remainingSpace > 0.0) and (totalGrow > 0.0) then
  begin
    for i := 0 to numVisible - 1 do
    begin
      child := visibleItems[i];
      if child.FlexGrow > 0.0 then
        finalMainSizes[i] := baseSizes[i] + (remainingSpace * (child.FlexGrow / totalGrow))
      else
        finalMainSizes[i] := baseSizes[i];
    end;
    remainingSpace := 0.0;
  end
  else if (remainingSpace < 0.0) and (totalShrink > 0.0) then
  begin
    shrinkFactor := Abs(remainingSpace) / totalShrink;
    for i := 0 to numVisible - 1 do
    begin
      child := visibleItems[i];
      finalMainSizes[i] := Max(0.0, baseSizes[i] - (child.FlexShrink * baseSizes[i] * shrinkFactor));
    end;
    remainingSpace := 0.0;
  end
  else
  begin
    for i := 0 to numVisible - 1 do
      finalMainSizes[i] := baseSizes[i];
  end;

  // 5. Cross-axis sizing (align-items / align-self)
  for i := 0 to numVisible - 1 do
  begin
    child := visibleItems[i];
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
      finalCrossSizes[i] := Max(0.0, availCross - (crossMarginBefore[i] + crossMarginAfter[i]))
    else
    begin
      if isRow then
        finalCrossSizes[i] := child.GetPreferredHeight()
      else
        finalCrossSizes[i] := child.GetPreferredWidth();
    end;
  end;

  // 6. Main-axis positioning (justify-content)
  spacingOffset := 0.0;
  itemGap := FGap;

  if (remainingSpace > 0.0) and (totalGrow = 0.0) then
  begin
    case FJustifyContent of
      ftjcStart:
        spacingOffset := 0.0;
      ftjcCenter:
        spacingOffset := remainingSpace * 0.5;
      ftjcEnd:
        spacingOffset := remainingSpace;
      ftjcSpaceBetween:
      begin
        if numVisible > 1 then
          itemGap := FGap + (remainingSpace / (numVisible - 1))
        else
          spacingOffset := 0.0;
      end;
      ftjcSpaceAround:
      begin
        itemGap := FGap + (remainingSpace / numVisible);
        spacingOffset := (remainingSpace / numVisible) * 0.5;
      end;
      ftjcSpaceEvenly:
      begin
        itemGap := FGap + (remainingSpace / (numVisible + 1));
        spacingOffset := remainingSpace / (numVisible + 1);
      end;
    end;
  end;

  curMainPos := mainStart + spacingOffset;

  // 7. Place children
  for i := 0 to numVisible - 1 do
  begin
    child := visibleItems[i];
    childMain := finalMainSizes[i];
    childCross := finalCrossSizes[i];

    curMainPos := curMainPos + mainMarginBefore[i];

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

    case effAlign of
      ftasStart, ftasStretch:
        curCrossPos := crossStart + crossMarginBefore[i];
      ftasCenter:
        curCrossPos := crossStart + crossMarginBefore[i] +
          ((availCross - (crossMarginBefore[i] + crossMarginAfter[i])) - childCross) * 0.5;
      ftasEnd:
        curCrossPos := crossStart + availCross - crossMarginAfter[i] - childCross;
      else
        curCrossPos := crossStart + crossMarginBefore[i];
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

    curMainPos := curMainPos + childMain + mainMarginAfter[i] + itemGap;
  end;
end;

{ TFtHBox }

constructor TFtHBox.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FDirection := ftfdRow;
  FAlignItems := ftaiStretch;
end;

{ TFtVBox }

constructor TFtVBox.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FDirection := ftfdColumn;
  FAlignItems := ftaiStretch;
end;

end.
