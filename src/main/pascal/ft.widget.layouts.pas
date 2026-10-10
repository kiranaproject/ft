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
  Ft.Canvas, Ft.Widget, Ft.Widget.ScrollBars, Ft.Widget.Containers, Ft.Theme, Ft.Css,
  Ft.Widget.Splitters, Ft.Widget.Texts;

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
    function AddSplitter(ASize: Double = 6.0): TFtSplitter;

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

  { ── 2D Grid Layout Track Definitions ── }
  TFtGridTrackSize = (
    gtsAuto = 0,    { Size to maximum preferred width/height of children }
    gtsFixed = 1,   { Explicit pixel size }
    gtsFlex = 2     { Fractional proportional expansion (like CSS fr) }
  );

  TFtGridTrackDef = record
    SizeMode: TFtGridTrackSize;
    Value: Double;  { Pixel length for gtsFixed, weight (e.g. 1.0) for gtsFlex }
  end;
  TFtGridTrackDefArray = array of TFtGridTrackDef;

  { TFtGrid — Declarative 2D Grid container }
  TFtGrid = class(TFtContainer)
  protected
    FColDefs: TFtGridTrackDefArray;
    FRowDefs: TFtGridTrackDefArray;
    FColumnGap: Double;
    FRowGap: Double;
    procedure EnsureColumnCount(ACount: Integer);
    procedure EnsureRowCount(ACount: Integer);
    function GetColumnCount(): Integer;
    function GetRowCount(): Integer;
    procedure SetColumnCount(AValue: Integer);
    procedure SetRowCount(AValue: Integer);
    procedure SetColumnGap(AValue: Double);
    procedure SetRowGap(AValue: Double);
    function IsStyled(): Boolean; virtual;
  public
    constructor Create(AParent: TFtWidget); override;
    function GetElementType(): string; override;
    function GetEffectiveCornerRadius(): Double; override;
    function GetChildRenderArea(out AX, AY, AW, AH, ARadius: Double): Boolean; override;
    procedure Draw(Canvas: TFtCanvas); override;
    procedure DrawBackground(Canvas: TFtCanvas); override;
    function HitTest(AX, AY: Integer): TFtWidget; override;
    procedure UpdateLayout(); override;
    procedure SetBounds(AX, AY, AW, AH: Integer); override;

    procedure SetColumn(ACol: Integer; AMode: TFtGridTrackSize; AValue: Double = 0.0);
    procedure SetRow(ARow: Integer; AMode: TFtGridTrackSize; AValue: Double = 0.0);
    procedure SetColumnFixed(ACol: Integer; AWidth: Double);
    procedure SetColumnFlex(ACol: Integer; AWeight: Double = 1.0);
    procedure SetColumnAuto(ACol: Integer);
    procedure SetRowFixed(ARow: Integer; AHeight: Double);
    procedure SetRowFlex(ARow: Integer; AWeight: Double = 1.0);
    procedure SetRowAuto(ARow: Integer);
    procedure SetColumnTemplate(const ATemplate: string);
    procedure SetRowTemplate(const ATemplate: string);

    procedure AddWidget(AWidget: TFtWidget; ACol, ARow: Integer; AColSpan: Integer = 1; ARowSpan: Integer = 1);

    property ColumnCount: Integer read GetColumnCount write SetColumnCount;
    property RowCount: Integer read GetRowCount write SetRowCount;
    property ColumnGap: Double read FColumnGap write SetColumnGap;
    property RowGap: Double read FRowGap write SetRowGap;
  end;

  { TFtFormGrid — High-level 2D Form layout aligning label/input columns }
  TFtFormGrid = class(TFtGrid)
  private
    FCurrentRow: Integer;
    FLabelAlignment: TFtAlignSelf;
  public
    constructor Create(AParent: TFtWidget); override;
    function GetElementType(): string; override;
    function AddRow(const ALabel: string; AControl: TFtWidget): TFtLabel;
    procedure AddRowWidgets(ALabelWidget, AControlWidget: TFtWidget);
    procedure AddSpanned(AWidget: TFtWidget);
    function AddSectionHeader(const ATitle: string): TFtLabel;

    property CurrentRow: Integer read FCurrentRow write FCurrentRow;
    property LabelAlignment: TFtAlignSelf read FLabelAlignment write FLabelAlignment;
  end;

  { TFtSizeGroup — Synchronizes dimensions of widgets across independent layouts }
  TFtSizeGroupMode = (
    ftsgHorizontal = 0,
    ftsgVertical = 1,
    ftsgBoth = 2
  );

  TFtSizeGroup = class(TObject)
  private
    FWidgets: TFPList;
    FMode: TFtSizeGroupMode;
  public
    constructor Create(AMode: TFtSizeGroupMode = ftsgHorizontal);
    destructor Destroy(); override;
    procedure AddWidget(AWidget: TFtWidget);
    procedure RemoveWidget(AWidget: TFtWidget);
    procedure Synchronize();

    property Mode: TFtSizeGroupMode read FMode write FMode;
    property Widgets: TFPList read FWidgets;
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

function TFtFlexBox.AddSplitter(ASize: Double): TFtSplitter;
begin
  Result := TFtSplitter.Create(Self);
  Result.SplitterSize := ASize;
  Result.FlexBasis := ASize;
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
    if not child.HasExplicitPreferredWidth() and (child.Width > 0) then
      child.PreferredWidth := child.Width;
    if not child.HasExplicitPreferredHeight() and (child.Height > 0) then
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

{ ── Track Template Parser ── }

function ParseTrackTemplate(const ATemplate: string): TFtGridTrackDefArray;
var
  tokens: TStringList;
  i, j, repCount: Integer;
  tok, repToken, inner: string;
  val: Double;
  openP, commaP, closeP: Integer;
begin
  Result := nil;
  if Trim(ATemplate) = '' then Exit;

  tokens := TStringList.Create();
  try
    tokens.Delimiter := ' ';
    tokens.StrictDelimiter := False;
    tokens.DelimitedText := StringReplace(ATemplate, ',', ' ', [rfReplaceAll]);

    for i := 0 to tokens.Count - 1 do
    begin
      tok := LowerCase(Trim(tokens[i]));
      if tok = '' then Continue;

      // Handle repeat(N, track)
      if Copy(tok, 1, 7) = 'repeat(' then
      begin
        openP := Pos('(', tok);
        closeP := Pos(')', tok);
        if (openP > 0) and (closeP > openP) then
        begin
          inner := Copy(tok, openP + 1, closeP - openP - 1);
          commaP := Pos(',', inner);
          if commaP > 0 then
          begin
            repCount := StrToIntDef(Trim(Copy(inner, 1, commaP - 1)), 1);
            repToken := LowerCase(Trim(Copy(inner, commaP + 1, Length(inner) - commaP)));
            for j := 1 to repCount do
            begin
              SetLength(Result, Length(Result) + 1);
              if repToken = 'auto' then
              begin
                Result[High(Result)].SizeMode := gtsAuto;
                Result[High(Result)].Value := 0.0;
              end
              else if (Copy(repToken, Length(repToken) - 1, 2) = 'fr') then
              begin
                Result[High(Result)].SizeMode := gtsFlex;
                Result[High(Result)].Value := StrToFloatDef(Copy(repToken, 1, Length(repToken) - 2), 1.0);
              end
              else if (repToken = 'flex') or (repToken = '*') then
              begin
                Result[High(Result)].SizeMode := gtsFlex;
                Result[High(Result)].Value := 1.0;
              end
              else
              begin
                repToken := StringReplace(repToken, 'px', '', [rfIgnoreCase]);
                Result[High(Result)].SizeMode := gtsFixed;
                Result[High(Result)].Value := StrToFloatDef(repToken, 32.0);
              end;
            end;
            Continue;
          end;
        end;
      end;

      SetLength(Result, Length(Result) + 1);
      if tok = 'auto' then
      begin
        Result[High(Result)].SizeMode := gtsAuto;
        Result[High(Result)].Value := 0.0;
      end
      else if (Copy(tok, Length(tok) - 1, 2) = 'fr') then
      begin
        Result[High(Result)].SizeMode := gtsFlex;
        Result[High(Result)].Value := StrToFloatDef(Copy(tok, 1, Length(tok) - 2), 1.0);
      end
      else if (tok = 'flex') or (tok = '*') then
      begin
        Result[High(Result)].SizeMode := gtsFlex;
        Result[High(Result)].Value := 1.0;
      end
      else
      begin
        tok := StringReplace(tok, 'px', '', [rfIgnoreCase]);
        val := StrToFloatDef(tok, 0.0);
        if val > 0.0 then
        begin
          Result[High(Result)].SizeMode := gtsFixed;
          Result[High(Result)].Value := val;
        end
        else
        begin
          Result[High(Result)].SizeMode := gtsAuto;
          Result[High(Result)].Value := 0.0;
        end;
      end;
    end;
  finally
    tokens.Free();
  end;
end;

{ TFtGrid }

constructor TFtGrid.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FPaddingX := 0.0;
  FPaddingY := 0.0;
  FColumnGap := 8.0;
  FRowGap := 8.0;
  FDrawFrame := False;
  FDrawFocusRing := False;
  FCornerRadius := 0.0;
  FScrollBarMode := ftSbModeNone;
  FAutoContentSize := False;
  if Assigned(FVScrollBar) then FVScrollBar.Visible := False;
  if Assigned(FHScrollBar) then FHScrollBar.Visible := False;
  EnsureColumnCount(1);
  EnsureRowCount(1);
end;

function TFtGrid.GetElementType(): string;
begin
  Result := 'grid';
end;

function TFtGrid.GetEffectiveCornerRadius(): Double;
var
  st: TFtWidgetStyle;
begin
  st := GetResolvedStyle();
  if st.HasBorderRadius then
    Result := st.BorderRadius
  else if FDrawFrame then
    Result := FCornerRadius
  else
    Result := 0.0;
end;

function TFtGrid.GetChildRenderArea(out AX, AY, AW, AH, ARadius: Double): Boolean;
var
  st: TFtWidgetStyle;
begin
  st := GetResolvedStyle();
  if not FDrawFrame and not st.HasBorderWidth and not st.HasBorderRadius and not st.HasBgColor then
  begin
    if Assigned(Parent) then
      Exit(Parent.GetChildRenderArea(AX, AY, AW, AH, ARadius))
    else
    begin
      AX := X;
      AY := Y;
      AW := Width;
      AH := Height;
      ARadius := 0.0;
      Exit(True);
    end;
  end;
  Result := inherited GetChildRenderArea(AX, AY, AW, AH, ARadius);
end;

function TFtGrid.IsStyled(): Boolean;
var
  st: TFtWidgetStyle;
begin
  st := GetResolvedStyle();
  Result := st.HasBgColor or (st.HasBorderColor and (st.BorderWidth > 0.0)) or
            FDrawFrame or (FBackdropBlur > 0.5) or st.HasBackdropBlur;
end;

procedure TFtGrid.DrawBackground(Canvas: TFtCanvas);
begin
  if not IsStyled then
    Exit;
  inherited DrawBackground(Canvas);
end;

procedure TFtGrid.Draw(Canvas: TFtCanvas);
begin
  if not Visible then
    Exit;
  if not IsStyled then
  begin
    DrawChildren(Canvas);
    Exit;
  end;
  inherited Draw(Canvas);
end;

function TFtGrid.HitTest(AX, AY: Integer): TFtWidget;
var
  ChildHit: TFtWidget;
  st: TFtWidgetStyle;
begin
  ChildHit := inherited HitTest(AX, AY);
  if (ChildHit = Self) and not IsStyled then
  begin
    st := GetResolvedStyle();
    if not (FDrawFrame or st.HasBgColor or (FBackdropBlur > 0.5) or st.HasBackdropBlur) then
      Exit(nil);
  end;
  Result := ChildHit;
end;

procedure TFtGrid.SetBounds(AX, AY, AW, AH: Integer);
begin
  inherited SetBounds(AX, AY, AW, AH);
  UpdateLayout();
end;

procedure TFtGrid.EnsureColumnCount(ACount: Integer);
var
  i, oldLen: Integer;
begin
  if ACount < 1 then ACount := 1;
  oldLen := Length(FColDefs);
  if oldLen < ACount then
  begin
    SetLength(FColDefs, ACount);
    for i := oldLen to ACount - 1 do
    begin
      FColDefs[i].SizeMode := gtsAuto;
      FColDefs[i].Value := 0.0;
    end;
  end;
end;

procedure TFtGrid.EnsureRowCount(ACount: Integer);
var
  i, oldLen: Integer;
begin
  if ACount < 1 then ACount := 1;
  oldLen := Length(FRowDefs);
  if oldLen < ACount then
  begin
    SetLength(FRowDefs, ACount);
    for i := oldLen to ACount - 1 do
    begin
      FRowDefs[i].SizeMode := gtsAuto;
      FRowDefs[i].Value := 0.0;
    end;
  end;
end;

function TFtGrid.GetColumnCount(): Integer;
begin
  Result := Length(FColDefs);
end;

function TFtGrid.GetRowCount(): Integer;
begin
  Result := Length(FRowDefs);
end;

procedure TFtGrid.SetColumnCount(AValue: Integer);
begin
  if AValue < 1 then AValue := 1;
  EnsureColumnCount(AValue);
  SetLength(FColDefs, AValue);
  UpdateLayout();
end;

procedure TFtGrid.SetRowCount(AValue: Integer);
begin
  if AValue < 1 then AValue := 1;
  EnsureRowCount(AValue);
  SetLength(FRowDefs, AValue);
  UpdateLayout();
end;

procedure TFtGrid.SetColumnGap(AValue: Double);
begin
  if Abs(FColumnGap - AValue) > 1e-4 then
  begin
    FColumnGap := AValue;
    UpdateLayout();
  end;
end;

procedure TFtGrid.SetRowGap(AValue: Double);
begin
  if Abs(FRowGap - AValue) > 1e-4 then
  begin
    FRowGap := AValue;
    UpdateLayout();
  end;
end;

procedure TFtGrid.SetColumn(ACol: Integer; AMode: TFtGridTrackSize; AValue: Double);
begin
  EnsureColumnCount(ACol + 1);
  FColDefs[ACol].SizeMode := AMode;
  FColDefs[ACol].Value := AValue;
  UpdateLayout();
end;

procedure TFtGrid.SetRow(ARow: Integer; AMode: TFtGridTrackSize; AValue: Double);
begin
  EnsureRowCount(ARow + 1);
  FRowDefs[ARow].SizeMode := AMode;
  FRowDefs[ARow].Value := AValue;
  UpdateLayout();
end;

procedure TFtGrid.SetColumnFixed(ACol: Integer; AWidth: Double);
begin
  SetColumn(ACol, gtsFixed, AWidth);
end;

procedure TFtGrid.SetColumnFlex(ACol: Integer; AWeight: Double);
begin
  SetColumn(ACol, gtsFlex, AWeight);
end;

procedure TFtGrid.SetColumnAuto(ACol: Integer);
begin
  SetColumn(ACol, gtsAuto, 0.0);
end;

procedure TFtGrid.SetRowFixed(ARow: Integer; AHeight: Double);
begin
  SetRow(ARow, gtsFixed, AHeight);
end;

procedure TFtGrid.SetRowFlex(ARow: Integer; AWeight: Double);
begin
  SetRow(ARow, gtsFlex, AWeight);
end;

procedure TFtGrid.SetRowAuto(ARow: Integer);
begin
  SetRow(ARow, gtsAuto, 0.0);
end;

procedure TFtGrid.SetColumnTemplate(const ATemplate: string);
var
  defs: TFtGridTrackDefArray;
  i: Integer;
begin
  defs := ParseTrackTemplate(ATemplate);
  if Length(defs) > 0 then
  begin
    SetLength(FColDefs, Length(defs));
    for i := 0 to High(defs) do
      FColDefs[i] := defs[i];
    UpdateLayout();
  end;
end;

procedure TFtGrid.SetRowTemplate(const ATemplate: string);
var
  defs: TFtGridTrackDefArray;
  i: Integer;
begin
  defs := ParseTrackTemplate(ATemplate);
  if Length(defs) > 0 then
  begin
    SetLength(FRowDefs, Length(defs));
    for i := 0 to High(defs) do
      FRowDefs[i] := defs[i];
    UpdateLayout();
  end;
end;

procedure TFtGrid.AddWidget(AWidget: TFtWidget; ACol, ARow: Integer; AColSpan: Integer; ARowSpan: Integer);
begin
  if not Assigned(AWidget) then Exit;
  AWidget.Parent := Self;
  AWidget.SetGridCell(ACol, ARow, AColSpan, ARowSpan);
  EnsureColumnCount(ACol + AColSpan);
  EnsureRowCount(ARow + ARowSpan);
  UpdateLayout();
end;

procedure TFtGrid.UpdateLayout();
var
  numCols, numRows: Integer;
  colWidths: array of Double;
  rowHeights: array of Double;
  colPositions: array of Double;
  rowPositions: array of Double;
  availW, availH: Double;
  usedW, usedH: Double;
  remW, remH: Double;
  totalColFlex, totalRowFlex: Double;
  totalColGaps, totalRowGaps: Double;
  i, c, r, cs, rs, colIdx, rowIdx: Integer;
  child: TFtWidget;
  cellX, cellY, cellW, cellH: Double;
  st, chSt: TFtWidgetStyle;
  w, h: Double;
begin
  if not Assigned(Children) or (Children.Count = 0) then Exit;
  if (Width <= 0) or (Height <= 0) then Exit;

  // 1. Resolve CSS properties if specified on the grid container
  st := GetResolvedStyle();
  if st.HasColumnGap then
    FColumnGap := st.ColumnGap
  else if st.HasGap then
    FColumnGap := st.Gap;

  if st.HasRowGap then
    FRowGap := st.RowGap
  else if st.HasGap then
    FRowGap := st.Gap;

  if st.HasGridTemplateColumns and (st.GridTemplateColumns <> '') then
    SetColumnTemplate(st.GridTemplateColumns);
  if st.HasGridTemplateRows and (st.GridTemplateRows <> '') then
    SetRowTemplate(st.GridTemplateRows);

  // 2. Discover maximum columns and rows from child cells
  numCols := Length(FColDefs);
  numRows := Length(FRowDefs);

  for i := 0 to Children.Count - 1 do
  begin
    child := TFtWidget(Children[i]);
    if child.Visible and (child <> FVScrollBar) and (child <> FHScrollBar) and
       (child.GridRow >= 0) and (child.GridColumn >= 0) then
    begin
      chSt := child.GetResolvedStyle();
      if chSt.HasGridColumn then child.GridColumn := chSt.GridColumn;
      if chSt.HasGridRow then child.GridRow := chSt.GridRow;
      if chSt.HasGridColSpan then child.GridColSpan := chSt.GridColSpan;
      if chSt.HasGridRowSpan then child.GridRowSpan := chSt.GridRowSpan;

      if child.GridColumn + child.GridColSpan > numCols then
        numCols := child.GridColumn + child.GridColSpan;
      if child.GridRow + child.GridRowSpan > numRows then
        numRows := child.GridRow + child.GridRowSpan;
    end;
  end;

  if numCols < 1 then numCols := 1;
  if numRows < 1 then numRows := 1;
  EnsureColumnCount(numCols);
  EnsureRowCount(numRows);

  // 3. Determine available area
  availW := Max(0.0, Width - (FPaddingX * 2.0));
  availH := Max(0.0, Height - (FPaddingY * 2.0));

  // 4. Calculate column widths
  SetLength(colWidths, numCols);
  for c := 0 to numCols - 1 do
  begin
    case FColDefs[c].SizeMode of
      gtsFixed:
        colWidths[c] := FColDefs[c].Value;
      gtsAuto:
        begin
          colWidths[c] := 0.0;
          for i := 0 to Children.Count - 1 do
          begin
            child := TFtWidget(Children[i]);
            if child.Visible and (child <> FVScrollBar) and (child <> FHScrollBar) and
               (child.GridColumn = c) and (child.GridColSpan = 1) then
            begin
              w := child.GetPreferredWidth() + child.MarginLeft + child.MarginRight;
              if w > colWidths[c] then
                colWidths[c] := w;
            end;
          end;
        end;
      gtsFlex:
        colWidths[c] := 0.0;
    end;
  end;

  totalColGaps := Max(0, numCols - 1) * FColumnGap;
  usedW := totalColGaps;
  totalColFlex := 0.0;
  for c := 0 to numCols - 1 do
  begin
    if FColDefs[c].SizeMode = gtsFlex then
      totalColFlex := totalColFlex + Max(0.01, FColDefs[c].Value)
    else
      usedW := usedW + colWidths[c];
  end;

  remW := Max(0.0, availW - usedW);
  if totalColFlex > 0.0 then
  begin
    for c := 0 to numCols - 1 do
    begin
      if FColDefs[c].SizeMode = gtsFlex then
        colWidths[c] := remW * (Max(0.01, FColDefs[c].Value) / totalColFlex);
    end;
  end;

  // 5. Calculate row heights
  SetLength(rowHeights, numRows);
  for r := 0 to numRows - 1 do
  begin
    case FRowDefs[r].SizeMode of
      gtsFixed:
        rowHeights[r] := FRowDefs[r].Value;
      gtsAuto:
        begin
          rowHeights[r] := 0.0;
          for i := 0 to Children.Count - 1 do
          begin
            child := TFtWidget(Children[i]);
            if child.Visible and (child <> FVScrollBar) and (child <> FHScrollBar) and
               (child.GridRow = r) and (child.GridRowSpan = 1) then
            begin
              h := child.GetPreferredHeight() + child.MarginTop + child.MarginBottom;
              if h > rowHeights[r] then
                rowHeights[r] := h;
            end;
          end;
          if rowHeights[r] < 24.0 then
            rowHeights[r] := 24.0;
        end;
      gtsFlex:
        rowHeights[r] := 0.0;
    end;
  end;

  totalRowGaps := Max(0, numRows - 1) * FRowGap;
  usedH := totalRowGaps;
  totalRowFlex := 0.0;
  for r := 0 to numRows - 1 do
  begin
    if FRowDefs[r].SizeMode = gtsFlex then
      totalRowFlex := totalRowFlex + Max(0.01, FRowDefs[r].Value)
    else
      usedH := usedH + rowHeights[r];
  end;

  remH := Max(0.0, availH - usedH);
  if totalRowFlex > 0.0 then
  begin
    for r := 0 to numRows - 1 do
    begin
      if FRowDefs[r].SizeMode = gtsFlex then
        rowHeights[r] := remH * (Max(0.01, FRowDefs[r].Value) / totalRowFlex);
    end;
  end;

  // 6. Compute column X and row Y coordinates
  SetLength(colPositions, numCols);
  colPositions[0] := X + FPaddingX;
  for c := 1 to numCols - 1 do
    colPositions[c] := colPositions[c - 1] + colWidths[c - 1] + FColumnGap;

  SetLength(rowPositions, numRows);
  rowPositions[0] := Y + FPaddingY;
  for r := 1 to numRows - 1 do
    rowPositions[r] := rowPositions[r - 1] + rowHeights[r - 1] + FRowGap;

  // 7. Position visible children
  for i := 0 to Children.Count - 1 do
  begin
    child := TFtWidget(Children[i]);
    if not child.Visible or (child = FVScrollBar) or (child = FHScrollBar) or
       (child.GridColumn < 0) or (child.GridRow < 0) then Continue;

    c := child.GridColumn;
    r := child.GridRow;
    cs := Max(1, child.GridColSpan);
    rs := Max(1, child.GridRowSpan);

    if c >= numCols then c := numCols - 1;
    if r >= numRows then r := numRows - 1;
    if c + cs > numCols then cs := numCols - c;
    if r + rs > numRows then rs := numRows - r;

    cellW := 0.0;
    for colIdx := c to c + cs - 1 do
      cellW := cellW + colWidths[colIdx];
    cellW := cellW + (cs - 1) * FColumnGap;

    cellH := 0.0;
    for rowIdx := r to r + rs - 1 do
      cellH := cellH + rowHeights[rowIdx];
    cellH := cellH + (rs - 1) * FRowGap;

    cellX := colPositions[c] + child.MarginLeft;
    cellY := rowPositions[r] + child.MarginTop;
    cellW := Max(0.0, cellW - (child.MarginLeft + child.MarginRight));
    cellH := Max(0.0, cellH - (child.MarginTop + child.MarginBottom));

    child.SetBounds(Round(cellX), Round(cellY), Round(cellW), Round(cellH));
    child.UpdateLayout();
    child.Invalidate();
  end;
end;

{ TFtFormGrid }

constructor TFtFormGrid.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FCurrentRow := 0;
  FLabelAlignment := ftasCenter;
  SetColumnCount(2);
  SetColumnAuto(0);      // Column 0 matches widest label
  SetColumnFlex(1, 1.0); // Column 1 stretches input controls across remaining width
  FColumnGap := 12.0;
  FRowGap := 10.0;
end;

function TFtFormGrid.GetElementType(): string;
begin
  Result := 'formgrid';
end;

function TFtFormGrid.AddRow(const ALabel: string; AControl: TFtWidget): TFtLabel;
begin
  Result := TFtLabel.Create(Self);
  Result.GridColumn := 0;
  Result.GridRow := FCurrentRow;
  Result.GridColSpan := 1;
  Result.GridRowSpan := 1;
  Result.AlignSelf := FLabelAlignment;
  Result.Text := ALabel;

  if Assigned(AControl) then
  begin
    AControl.GridColumn := 1;
    AControl.GridRow := FCurrentRow;
    AControl.GridColSpan := 1;
    AControl.GridRowSpan := 1;
    if AControl.Parent <> Self then
    begin
      AControl.Parent := Self;
      Self.Children.Add(AControl);
    end;
  end;

  Inc(FCurrentRow);
  EnsureRowCount(FCurrentRow);
  UpdateLayout();
end;

procedure TFtFormGrid.AddRowWidgets(ALabelWidget, AControlWidget: TFtWidget);
begin
  if Assigned(ALabelWidget) then
  begin
    ALabelWidget.GridColumn := 0;
    ALabelWidget.GridRow := FCurrentRow;
    ALabelWidget.GridColSpan := 1;
    ALabelWidget.GridRowSpan := 1;
    if ALabelWidget.Parent <> Self then
    begin
      ALabelWidget.Parent := Self;
      Self.Children.Add(ALabelWidget);
    end;
  end;

  if Assigned(AControlWidget) then
  begin
    AControlWidget.GridColumn := 1;
    AControlWidget.GridRow := FCurrentRow;
    AControlWidget.GridColSpan := 1;
    AControlWidget.GridRowSpan := 1;
    if AControlWidget.Parent <> Self then
    begin
      AControlWidget.Parent := Self;
      Self.Children.Add(AControlWidget);
    end;
  end;

  Inc(FCurrentRow);
  EnsureRowCount(FCurrentRow);
  UpdateLayout();
end;

procedure TFtFormGrid.AddSpanned(AWidget: TFtWidget);
begin
  if not Assigned(AWidget) then Exit;
  AWidget.GridColumn := 0;
  AWidget.GridRow := FCurrentRow;
  AWidget.GridColSpan := 2;
  AWidget.GridRowSpan := 1;
  if AWidget.Parent <> Self then
  begin
    AWidget.Parent := Self;
    Self.Children.Add(AWidget);
  end;

  Inc(FCurrentRow);
  EnsureRowCount(FCurrentRow);
  UpdateLayout();
end;

function TFtFormGrid.AddSectionHeader(const ATitle: string): TFtLabel;
begin
  Result := TFtLabel.Create(Self);
  Result.GridColumn := 0;
  Result.GridRow := FCurrentRow;
  Result.GridColSpan := 2;
  Result.GridRowSpan := 1;
  Result.MarginTop := 10;
  Result.MarginBottom := 4;
  Result.Text := ATitle;

  Inc(FCurrentRow);
  EnsureRowCount(FCurrentRow);
  UpdateLayout();
end;

{ TFtSizeGroup }

constructor TFtSizeGroup.Create(AMode: TFtSizeGroupMode);
begin
  inherited Create();
  FMode := AMode;
  FWidgets := TFPList.Create();
end;

destructor TFtSizeGroup.Destroy();
begin
  FWidgets.Free();
  inherited Destroy();
end;

procedure TFtSizeGroup.AddWidget(AWidget: TFtWidget);
begin
  if Assigned(AWidget) and (FWidgets.IndexOf(AWidget) < 0) then
  begin
    FWidgets.Add(AWidget);
    Synchronize();
  end;
end;

procedure TFtSizeGroup.RemoveWidget(AWidget: TFtWidget);
begin
  if Assigned(AWidget) then
  begin
    FWidgets.Remove(AWidget);
    Synchronize();
  end;
end;

procedure TFtSizeGroup.Synchronize();
var
  i: Integer;
  w: TFtWidget;
  curW, curH, maxW, maxH: Integer;
begin
  if not Assigned(FWidgets) or (FWidgets.Count = 0) then Exit;

  maxW := 0;
  maxH := 0;
  for i := 0 to FWidgets.Count - 1 do
  begin
    w := TFtWidget(FWidgets[i]);
    if Assigned(w) and w.Visible then
    begin
      curW := w.GetPreferredWidth();
      if w.Width > curW then curW := w.Width;
      if curW > maxW then maxW := curW;

      curH := w.GetPreferredHeight();
      if w.Height > curH then curH := w.Height;
      if curH > maxH then maxH := curH;
    end;
  end;

  for i := 0 to FWidgets.Count - 1 do
  begin
    w := TFtWidget(FWidgets[i]);
    if Assigned(w) then
    begin
      if (FMode = ftsgHorizontal) or (FMode = ftsgBoth) then
      begin
        w.PreferredWidth := maxW;
        w.Width := maxW;
      end;
      if (FMode = ftsgVertical) or (FMode = ftsgBoth) then
      begin
        w.PreferredHeight := maxH;
        w.Height := maxH;
      end;
      if Assigned(w.Parent) then
        w.Parent.UpdateLayout();
    end;
  end;
end;

end.
