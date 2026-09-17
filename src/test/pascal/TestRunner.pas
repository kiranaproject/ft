program TestRunner;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, Math, fpcunit, testregistry, consoletestrunner,
  Floria.SVG.DOM, Floria.SVG.Parser,
  Ft.Css, Ft.Bitmap, Ft.Blur, Ft.Canvas.Agg, Ft.Svg, Ft.Widget, Ft.Widget.Containers, Ft.Widget.Images,
  Ft.Widget.Tabs, Ft.Widget.Splitters, Ft.Widget.TreeViews, Ft.Widget.Tables, Ft.Widget.Texts;

type
  TFtDesktopWidgetsTest = class(TTestCase)
  published
    procedure TestNotebook();
    procedure TestSplitter();
    procedure TestTreeView();
    procedure TestTable();
    procedure TestDynamicContainerRenderArea();
    procedure TestCanvasRoundedRectClipping();
  end;

  TFtSvgTest = class(TTestCase)
  published
    procedure TestSVGRasterizeRect();
    procedure TestSVGRasterizeCircle();
    procedure TestSVGRasterizePath();
    procedure TestSVGRasterizeUseAndGroup();
    procedure TestBitmapCreateFromSVG();
    procedure TestImageWidgetLoadSVG();
    procedure TestSVGRasterizeLinearGradient();
    procedure TestSVGRasterizeRadialGradient();
  end;
  TFtCssTest = class(TTestCase)
  published
    procedure TestColorParsing();
    procedure TestLengthParsing();
    procedure TestOpacityParsing();
    procedure TestTransitionParsing();
    procedure TestStyleSheetResolving();
    procedure TestPseudoClassResolving();
    procedure TestSpecificityAndInlineStyle();
  end;

procedure TFtCssTest.TestColorParsing();
var
  col: TFtRgbaColor;
begin
  AssertTrue('Parse #ff0000', FtParseColor('#ff0000', col));
  AssertEquals('Red R', 1.0, Round(col.R * 100.0) / 100.0);
  AssertEquals('Red G', 0.0, Round(col.G * 100.0) / 100.0);
  AssertEquals('Red B', 0.0, Round(col.B * 100.0) / 100.0);
  AssertEquals('Red A', 1.0, Round(col.A * 100.0) / 100.0);

  AssertTrue('Parse #00ff0080', FtParseColor('#00ff0080', col));
  AssertEquals('Green G', 1.0, Round(col.G * 100.0) / 100.0);
  AssertTrue('Alpha ~ 0.5', Abs(col.A - 0.50) < 0.02);

  AssertTrue('Parse rgb(255, 128, 0)', FtParseColor('rgb(255, 128, 0)', col));
  AssertEquals('RGB R', 1.0, Round(col.R * 100.0) / 100.0);
  AssertTrue('RGB G ~ 0.5', Abs(col.G - (128.0 / 255.0)) < 0.01);

  AssertTrue('Parse transparent', FtParseColor('transparent', col));
  AssertEquals('Transparent A', 0.0, col.A);

  AssertTrue('Parse white', FtParseColor('white', col));
  AssertEquals('White R', 1.0, col.R);
  AssertEquals('White G', 1.0, col.G);
  AssertEquals('White B', 1.0, col.B);
end;

procedure TFtCssTest.TestLengthParsing();
var
  v: Double;
begin
  AssertTrue('Parse 16px', FtParseLength('16px', v));
  AssertEquals('Pixels value', 16.0, v);

  AssertTrue('Parse 12.5px', FtParseLength('12.5px', v));
  AssertEquals('Float pixels', 12.5, v);

  AssertTrue('Parse 24', FtParseLength('24', v));
  AssertEquals('Unitless pixels', 24.0, v);
end;

procedure TFtCssTest.TestOpacityParsing();
var
  v: Double;
begin
  AssertTrue('Parse 0.75', FtParseOpacity('0.75', v));
  AssertEquals('Opacity 0.75', 0.75, Round(v * 100.0) / 100.0);

  AssertTrue('Parse 50%', FtParseOpacity('50%', v));
  AssertEquals('Opacity 50%', 0.5, Round(v * 100.0) / 100.0);

  AssertTrue('Parse 1.5 clamps to 1.0', FtParseOpacity('1.5', v));
  AssertEquals('Clamp max', 1.0, v);

  AssertTrue('Parse -0.2 clamps to 0.0', FtParseOpacity('-0.2', v));
  AssertEquals('Clamp min', 0.0, v);
end;

procedure TFtCssTest.TestTransitionParsing();
var
  prop, timing: string;
  durMs: Integer;
begin
  AssertTrue('Parse all 250ms ease', FtParseTransition('all 250ms ease', prop, durMs, timing));
  AssertEquals('Prop all', 'all', prop);
  AssertEquals('Dur 250ms', 250, durMs);
  AssertEquals('Timing ease', 'ease', timing);

  AssertTrue('Parse background-color 0.3s ease-in-out', FtParseTransition('background-color 0.3s ease-in-out', prop, durMs, timing));
  AssertEquals('Prop bg', 'background-color', prop);
  AssertEquals('Dur 300ms', 300, durMs);
  AssertEquals('Timing ease-in-out', 'ease-in-out', timing);
end;

procedure TFtCssTest.TestStyleSheetResolving();
var
  sheet: TFtStyleSheet;
  css: string;
  st: TFtWidgetStyle;
begin
  sheet := TFtStyleSheet.Create();
  try
    css := 'button {' + LineEnding +
           '    background-color: #1e1e2e;' + LineEnding +
           '    color: #cdd6f4;' + LineEnding +
           '    border-color: #89b4fa;' + LineEnding +
           '    border-width: 1.5px;' + LineEnding +
           '    border-radius: 8px;' + LineEnding +
           '    font-size: 14px;' + LineEnding +
           '    opacity: 0.9;' + LineEnding +
           '}' + LineEnding +
           'button.btn-primary {' + LineEnding +
           '    background-color: #89b4fa;' + LineEnding +
           '    color: #11111b;' + LineEnding +
           '    border-radius: 12px;' + LineEnding +
           '}';

    AssertTrue('Load CSS string', sheet.LoadFromString(css));

    // Resolve unclassed button
    st := sheet.ResolveStyle('button', '', '', '');
    AssertTrue('Has bg', st.HasBgColor);
    AssertTrue('Has border width', st.HasBorderWidth);
    AssertEquals('Border width 1.5', 1.5, st.BorderWidth);
    AssertEquals('Border radius 8.0', 8.0, st.BorderRadius);
    AssertEquals('Font size 14.0', 14.0, st.FontSize);
    AssertTrue('Opacity ~ 0.9', Abs(st.Opacity - 0.9) < 0.01);

    // Resolve button with class .btn-primary
    st := sheet.ResolveStyle('button', '', 'btn-primary', '');
    AssertTrue('Has bg', st.HasBgColor);
    AssertEquals('Class overridden border radius 12.0', 12.0, st.BorderRadius);
    // Preserves inherited or non-overridden properties from base rule
    AssertTrue('Retains border width', st.HasBorderWidth);
    AssertEquals('Retains border width 1.5', 1.5, st.BorderWidth);
  finally
    sheet.Free();
  end;
end;

procedure TFtCssTest.TestPseudoClassResolving();
var
  sheet: TFtStyleSheet;
  css: string;
  stNormal, stHover, stActive, stChecked, stDisabled: TFtWidgetStyle;
begin
  sheet := TFtStyleSheet.Create();
  try
    css := 'button.test-btn {' + LineEnding +
           '    background-color: #3b82f6;' + LineEnding +
           '}' + LineEnding +
           'button.test-btn:hover {' + LineEnding +
           '    background-color: #2563eb;' + LineEnding +
           '}' + LineEnding +
           'button.test-btn:active {' + LineEnding +
           '    background-color: #1d4ed8;' + LineEnding +
           '}' + LineEnding +
           'button.test-btn:checked {' + LineEnding +
           '    background-color: #10b981;' + LineEnding +
           '}' + LineEnding +
           'button.test-btn:disabled {' + LineEnding +
           '    opacity: 0.5;' + LineEnding +
           '}';

    AssertTrue('Load CSS', sheet.LoadFromString(css));

    stNormal   := sheet.ResolveStyle('button', '', 'test-btn', '');
    stHover    := sheet.ResolveStyle('button', '', 'test-btn', ':hover');
    stActive   := sheet.ResolveStyle('button', '', 'test-btn', ':active');
    stChecked  := sheet.ResolveStyle('button', '', 'test-btn', ':checked');
    stDisabled := sheet.ResolveStyle('button', '', 'test-btn', ':disabled');

    AssertTrue('Normal has bg', stNormal.HasBgColor);
    AssertTrue('Hover has bg', stHover.HasBgColor);
    AssertTrue('Active has bg', stActive.HasBgColor);
    AssertTrue('Checked has bg', stChecked.HasBgColor);
    AssertTrue('Disabled has opacity', stDisabled.HasOpacity);

    // Verify hover color differs from normal color
    AssertFalse('Hover != Normal R', (Abs(stHover.BgColor.R - stNormal.BgColor.R) < 0.001) and
                                     (Abs(stHover.BgColor.G - stNormal.BgColor.G) < 0.001) and
                                     (Abs(stHover.BgColor.B - stNormal.BgColor.B) < 0.001));

    // Verify checked color is distinct green (#10b981)
    AssertTrue('Checked green channel high', stChecked.BgColor.G > 0.6);

    // Verify disabled opacity
    AssertEquals('Disabled opacity 0.5', 0.5, Round(stDisabled.Opacity * 100.0) / 100.0);
  finally
    sheet.Free();
  end;
end;

procedure TFtCssTest.TestSpecificityAndInlineStyle();
var
  sheet: TFtStyleSheet;
  css: string;
  st: TFtWidgetStyle;
begin
  sheet := TFtStyleSheet.Create();
  try
    css := 'button { background-color: #111111; border-radius: 4px; }' + LineEnding +
           '.btn { background-color: #222222; }' + LineEnding +
           '#my-btn { background-color: #333333; }';

    AssertTrue('Load CSS', sheet.LoadFromString(css));

    // ID selector wins over class and tag
    st := sheet.ResolveStyle('button', 'my-btn', 'btn', '');
    AssertTrue('Has bg', st.HasBgColor);
    // #333333 -> 0x33 / 255 = 0.2
    AssertTrue('ID selector wins', Abs(st.BgColor.R - (51.0 / 255.0)) < 0.01);
    AssertEquals('Border radius from tag rule', 4.0, st.BorderRadius);

    // Inline CSS overrides stylesheet ID rule
    st := sheet.ResolveStyle('button', 'my-btn', 'btn', '', 'background-color: #ffffff; border-radius: 16px;');
    AssertEquals('Inline bg R = 1.0', 1.0, Round(st.BgColor.R * 100.0) / 100.0);
    AssertEquals('Inline border radius = 16.0', 16.0, st.BorderRadius);
  finally
    sheet.Free();
  end;
end;

{ TFtSvgTest }

procedure TFtSvgTest.TestSVGRasterizeRect();
var
  svg: string;
  bmp: TFtBitmap;
  p: PByte;
begin
  svg := '<svg width="100" height="100" viewBox="0 0 100 100">' +
         '  <rect x="10" y="10" width="80" height="80" fill="#ff0000" />' +
         '</svg>';
  bmp := TFtSVGRenderer.RenderStringToBitmap(svg, 100, 100);
  try
    AssertEquals('Width', 100, bmp.Width);
    AssertEquals('Height', 100, bmp.Height);

    // Center pixel (50, 50) must be red (BGRA: B=0, G=0, R=255, A=255)
    p := PByte(bmp.PixelBuffer) + (50 * bmp.Stride + 50 * 4);
    AssertTrue('Center pixel Red >= 240', p[2] >= 240);
    AssertTrue('Center pixel Green <= 10', p[1] <= 10);
    AssertTrue('Center pixel Blue <= 10', p[0] <= 10);
    AssertTrue('Center pixel Alpha >= 240', p[3] >= 240);

    // Outside pixel (2, 2) must be transparent
    p := PByte(bmp.PixelBuffer) + (2 * bmp.Stride + 2 * 4);
    AssertEquals('Outside pixel Alpha', 0, p[3]);
  finally
    bmp.Free();
  end;
end;

procedure TFtSvgTest.TestSVGRasterizeCircle();
var
  svg: string;
  bmp: TFtBitmap;
  p: PByte;
begin
  svg := '<svg width="100" height="100" viewBox="0 0 100 100">' +
         '  <circle cx="50" cy="50" r="30" fill="#00ff00" />' +
         '</svg>';
  bmp := TFtSVGRenderer.RenderStringToBitmap(svg, 100, 100);
  try
    // Center pixel (50, 50) must be green
    p := PByte(bmp.PixelBuffer) + (50 * bmp.Stride + 50 * 4);
    AssertTrue('Center pixel Green >= 240', p[1] >= 240);
    AssertTrue('Center pixel Red <= 10', p[2] <= 10);
    AssertTrue('Center pixel Alpha >= 240', p[3] >= 240);

    // Outside pixel (5, 5) must be transparent
    p := PByte(bmp.PixelBuffer) + (5 * bmp.Stride + 5 * 4);
    AssertEquals('Outside pixel Alpha', 0, p[3]);
  finally
    bmp.Free();
  end;
end;

procedure TFtSvgTest.TestSVGRasterizePath();
var
  svg: string;
  bmp: TFtBitmap;
  p: PByte;
begin
  svg := '<svg width="100" height="100" viewBox="0 0 100 100">' +
         '  <path d="M 20 20 L 80 20 L 80 80 L 20 80 Z" fill="#0000ff" />' +
         '</svg>';
  bmp := TFtSVGRenderer.RenderStringToBitmap(svg, 100, 100);
  try
    // Center pixel (50, 50) must be blue
    p := PByte(bmp.PixelBuffer) + (50 * bmp.Stride + 50 * 4);
    AssertTrue('Center pixel Blue >= 240', p[0] >= 240);
    AssertTrue('Center pixel Red <= 10', p[2] <= 10);
    AssertTrue('Center pixel Alpha >= 240', p[3] >= 240);
  finally
    bmp.Free();
  end;
end;

procedure TFtSvgTest.TestSVGRasterizeUseAndGroup();
var
  svg: string;
  bmp: TFtBitmap;
  p: PByte;
begin
  svg := '<svg width="100" height="100">' +
         '  <defs>' +
         '    <rect id="box" width="40" height="40" fill="#ffff00" />' +
         '  </defs>' +
         '  <g transform="translate(30, 30)">' +
         '    <use href="#box" />' +
         '  </g>' +
         '</svg>';
  bmp := TFtSVGRenderer.RenderStringToBitmap(svg, 100, 100);
  try
    // Pixel inside the used box (50, 50) must be yellow (R=255, G=255, B=0)
    p := PByte(bmp.PixelBuffer) + (50 * bmp.Stride + 50 * 4);
    AssertTrue('Used box Red >= 240', p[2] >= 240);
    AssertTrue('Used box Green >= 240', p[1] >= 240);
    AssertTrue('Used box Blue <= 10', p[0] <= 10);
    AssertTrue('Used box Alpha >= 240', p[3] >= 240);

    // Pixel outside (10, 10) must be transparent
    p := PByte(bmp.PixelBuffer) + (10 * bmp.Stride + 10 * 4);
    AssertEquals('Outside Alpha', 0, p[3]);
  finally
    bmp.Free();
  end;
end;

procedure TFtSvgTest.TestBitmapCreateFromSVG();
var
  svg: string;
  bmp: TFtBitmap;
  p: PByte;
begin
  svg := '<svg width="60" height="60" viewBox="0 0 60 60">' +
         '  <rect width="60" height="60" fill="#00ffff" />' +
         '</svg>';
  bmp := TFtBitmap.CreateFromSVG(svg, 60, 60);
  try
    AssertEquals('Bmp Width', 60, bmp.Width);
    AssertEquals('Bmp Height', 60, bmp.Height);
    p := PByte(bmp.PixelBuffer) + (30 * bmp.Stride + 30 * 4);
    // Cyan: B=255, G=255, R=0, A=255
    AssertTrue('Cyan Blue >= 240', p[0] >= 240);
    AssertTrue('Cyan Green >= 240', p[1] >= 240);
    AssertTrue('Cyan Red <= 10', p[2] <= 10);
  finally
    bmp.Free();
  end;
end;

procedure TFtSvgTest.TestImageWidgetLoadSVG();
var
  img: TFtImage;
  svg: string;
begin
  img := TFtImage.Create(nil, 0, 0, 100, 100);
  try
    svg := '<svg width="50" height="50"><circle cx="25" cy="25" r="20" fill="#800080" /></svg>';
    img.LoadSVGFromString(svg);
    AssertTrue('SVGDocument assigned', Assigned(img.SVGDocument));
    AssertEquals('Intrinsic Width', 50.0, img.SVGDocument.GetIntrinsicWidth());
  finally
    img.Free();
  end;
end;

procedure TFtSvgTest.TestSVGRasterizeLinearGradient();
var
  svg: string;
  bmp: TFtBitmap;
  pLeft, pRight: PByte;
begin
  svg := '<svg width="100" height="100">' +
         '  <defs>' +
         '    <linearGradient id="lg1" x1="0%" y1="0%" x2="100%" y2="0%">' +
         '      <stop offset="0%" stop-color="#ff0000" />' +
         '      <stop offset="100%" stop-color="#0000ff" />' +
         '    </linearGradient>' +
         '  </defs>' +
         '  <rect width="100" height="100" fill="url(#lg1)" />' +
         '</svg>';

  bmp := TFtSVGRenderer.RenderStringToBitmap(svg, 100, 100);
  try
    AssertNotNull('Bitmap rendered', bmp);
    // Near left (10, 50): Red dominant (BGRA: p[0]=B, p[1]=G, p[2]=R, p[3]=A)
    pLeft := PByte(bmp.PixelBuffer) + (50 * bmp.Stride + 10 * 4);
    AssertTrue('Left pixel Red >= 200', pLeft[2] >= 200);
    AssertTrue('Left pixel Blue <= 60', pLeft[0] <= 60);
    AssertTrue('Left pixel Alpha >= 240', pLeft[3] >= 240);

    // Near right (90, 50): Blue dominant
    pRight := PByte(bmp.PixelBuffer) + (50 * bmp.Stride + 90 * 4);
    AssertTrue('Right pixel Blue >= 200', pRight[0] >= 200);
    AssertTrue('Right pixel Red <= 60', pRight[2] <= 60);
    AssertTrue('Right pixel Alpha >= 240', pRight[3] >= 240);
  finally
    bmp.Free();
  end;
end;

procedure TFtSvgTest.TestSVGRasterizeRadialGradient();
var
  svg: string;
  bmp: TFtBitmap;
  pCenter, pEdge: PByte;
begin
  svg := '<svg width="100" height="100">' +
         '  <defs>' +
         '    <radialGradient id="rg1" cx="50%" cy="50%" r="50%">' +
         '      <stop offset="0%" stop-color="#ffff00" />' +
         '      <stop offset="100%" stop-color="#000000" />' +
         '    </radialGradient>' +
         '  </defs>' +
         '  <rect width="100" height="100" fill="url(#rg1)" />' +
         '</svg>';

  bmp := TFtSVGRenderer.RenderStringToBitmap(svg, 100, 100);
  try
    AssertNotNull('Bitmap rendered', bmp);
    // Center (50, 50): Yellow (R=255, G=255, B=0, A=255)
    pCenter := PByte(bmp.PixelBuffer) + (50 * bmp.Stride + 50 * 4);
    AssertTrue('Center Red >= 240', pCenter[2] >= 240);
    AssertTrue('Center Green >= 240', pCenter[1] >= 240);
    AssertTrue('Center Blue <= 20', pCenter[0] <= 20);
    AssertTrue('Center Alpha >= 240', pCenter[3] >= 240);

    // Near edge (95, 50): Black (R <= 60, G <= 60, B <= 60)
    pEdge := PByte(bmp.PixelBuffer) + (50 * bmp.Stride + 95 * 4);
    AssertTrue('Edge Red <= 60', pEdge[2] <= 60);
    AssertTrue('Edge Green <= 60', pEdge[1] <= 60);
    AssertTrue('Edge Blue <= 60', pEdge[0] <= 60);
  finally
    bmp.Free();
  end;
end;

{ TFtDesktopWidgetsTest }

procedure TFtDesktopWidgetsTest.TestNotebook();
var
  nb: TFtNotebook;
  p1, p2: TFtTabPage;
  cx, cy, cw, ch: Double;
  inClose: Boolean;
  tabIdx: Integer;
begin
  nb := TFtNotebook.Create(nil);
  try
    nb.X := 10; nb.Y := 10; nb.Width := 400; nb.Height := 300;
    p1 := nb.AddTab('General', False);
    p2 := nb.AddTab('Settings', True);
    nb.AddTab('About', False);

    AssertEquals('Page count is 3', 3, nb.PageCount);
    AssertEquals('Active index defaults to 0', 0, nb.ActiveIndex);
    AssertTrue('First page is visible', p1.Visible);
    AssertFalse('Second page is not visible', p2.Visible);

    nb.ActiveIndex := 1;
    AssertEquals('Active index is 1', 1, nb.ActiveIndex);
    AssertFalse('First page is now hidden', p1.Visible);
    AssertTrue('Second page is now visible', p2.Visible);
    AssertEquals('Tab 2 title', 'Settings', nb.Pages[1].Title);
    AssertTrue('Tab 2 is closeable', nb.Pages[1].Closeable);

    // Test close button hit testing and click closing
    AssertTrue('GetCloseButtonRect for Settings tab', nb.GetCloseButtonRect(1, cx, cy, cw, ch));
    tabIdx := nb.TabIndexAt(Round(cx + cw * 0.5), Round(cy + ch * 0.5), inClose);
    AssertEquals('Hit tab index is 1', 1, tabIdx);
    AssertTrue('Hit inClose is True', inClose);

    nb.MouseDown(Round(cx + cw * 0.5), Round(cy + ch * 0.5), 1);
    nb.MouseUp(Round(cx + cw * 0.5), Round(cy + ch * 0.5), 1);
    AssertEquals('Page count after close click is 2', 2, nb.PageCount);
    AssertEquals('Tab 0 is still General', 'General', nb.Pages[0].Title);
    AssertEquals('Tab 1 is now About', 'About', nb.Pages[1].Title);

    nb.ClearTabs();
    AssertEquals('Page count after clear is 0', 0, nb.PageCount);
    AssertEquals('Active index after clear is -1', -1, nb.ActiveIndex);
  finally
    nb.Free();
  end;
end;

procedure TFtDesktopWidgetsTest.TestSplitter();
var
  spl: TFtSplitter;
  pane1, pane2: TFtContainer;
begin
  spl := TFtSplitter.Create(nil);
  pane1 := TFtContainer.Create(spl);
  pane2 := TFtContainer.Create(spl);
  try
    spl.X := 0; spl.Y := 0; spl.Width := 600; spl.Height := 400;
    spl.Orientation := soHorizontal;
    spl.SetPanes(pane1, pane2);

    AssertEquals('Splitter orientation is horizontal', Ord(soHorizontal), Ord(spl.Orientation));
    AssertNotNull('Pane1 assigned', spl.Pane1);
    AssertNotNull('Pane2 assigned', spl.Pane2);

    spl.SetSplitterRatio(0.4);
    AssertTrue('SplitterPos is ~240 (40% of 600)', Abs(spl.SplitterPos - 237.6) < 5.0);

    spl.Orientation := soVertical;
    AssertEquals('Splitter orientation changed to vertical', Ord(soVertical), Ord(spl.Orientation));
  finally
    spl.Free();
  end;
end;

procedure TFtDesktopWidgetsTest.TestTreeView();
var
  tv: TFtTreeView;
  docs, pics, work: TFtTreeNode;
begin
  tv := TFtTreeView.Create(nil);
  try
    tv.X := 0; tv.Y := 0; tv.Width := 250; tv.Height := 400;
    docs := tv.AddNode('Documents');
    pics := tv.AddNode('Pictures');

    AssertEquals('Root has 2 children', 2, tv.Root.ChildCount);
    AssertEquals('First node text', 'Documents', docs.Text);
    AssertEquals('Second node text', 'Pictures', pics.Text);
    AssertEquals('Docs level is 0', 0, docs.Level);

    work := docs.AddChild('Work');
    docs.AddChild('Personal');

    AssertEquals('Docs has 2 children', 2, docs.ChildCount);
    AssertEquals('Work level is 1', 1, work.Level);
    AssertTrue('Docs has children', docs.HasChildren());
    AssertFalse('Work has no children', work.HasChildren());

    docs.Expanded := True;
    tv.RebuildVisibleNodes();

    tv.SelectedNode := work;
    AssertTrue('Selected node is work', tv.SelectedNode = work);

    tv.Clear();
    AssertEquals('Root has 0 children after clear', 0, tv.Root.ChildCount);
  finally
    tv.Free();
  end;
end;

procedure TFtDesktopWidgetsTest.TestTable();
var
  tbl: TFtTable;
begin
  tbl := TFtTable.Create(nil);
  try
    tbl.X := 0; tbl.Y := 0; tbl.Width := 500; tbl.Height := 300;
    tbl.AddColumn('ID', 60.0, taCenter);
    tbl.AddColumn('Name', 180.0, taLeft);
    tbl.AddColumn('Price', 100.0, taRight);

    AssertEquals('Column count is 3', 3, tbl.ColumnCount);
    AssertEquals('Column 0 title', 'ID', tbl.Columns[0].Title);
    AssertEquals('Column 1 width', 180.0, tbl.Columns[1].Width);
    AssertEquals('Column 2 align is taRight', Ord(taRight), Ord(tbl.Columns[2].Alignment));

    tbl.AddRow(['1', 'Mechanical Keyboard', '$89.99']);
    tbl.AddRow(['2', 'Gaming Mouse', '$49.99']);

    AssertEquals('Row count is 2', 2, tbl.RowCount);
    AssertEquals('Cell (0, 0)', '1', tbl.GetCell(0, 0));
    AssertEquals('Cell (0, 1)', 'Mechanical Keyboard', tbl.GetCell(0, 1));
    AssertEquals('Cell (1, 2)', '$49.99', tbl.GetCell(1, 2));

    tbl.SetCell(1, 1, 'Wireless Mouse');
    AssertEquals('Updated Cell (1, 1)', 'Wireless Mouse', tbl.GetCell(1, 1));

    tbl.SelectedRow := 1;
    AssertEquals('Selected row is 1', 1, tbl.SelectedRow);

    tbl.DeleteRow(0);
    AssertEquals('Row count after delete is 1', 1, tbl.RowCount);
    AssertEquals('Remaining row item', 'Wireless Mouse', tbl.GetCell(0, 1));

    tbl.ClearRows();
    AssertEquals('Row count after clear is 0', 0, tbl.RowCount);
  finally
    tbl.Free();
  end;
end;

procedure TFtDesktopWidgetsTest.TestDynamicContainerRenderArea();
var
  cont: TFtContainer;
  child: TFtWidget;
  rx, ry, rw, rh, rrad: Double;
  px, py, pw, ph, prad: Double;
begin
  cont := TFtContainer.Create(nil);
  try
    cont.X := 50;
    cont.Y := 60;
    cont.Width := 300;
    cont.Height := 200;
    cont.DrawFrame := True;
    cont.SetPadding(0.0, 0.0);
    cont.CornerRadius := 10.0;

    // Test render area calculation
    cont.GetRenderArea(rx, ry, rw, rh, rrad);
    AssertEquals('Render area X', 51.0, rx);
    AssertEquals('Render area Y', 61.0, ry);
    AssertEquals('Render area W', 298.0, rw);
    AssertEquals('Render area H', 198.0, rh);
    AssertEquals('Inner Radius (10 - 1 bw)', 9.0, rrad);

    // Test child querying parent render area
    child := TFtWidget.Create(cont);
    AssertTrue('Child queries parent render area', child.GetParentRenderArea(px, py, pw, ph, prad));
    AssertEquals('Child parent X', rx, px);
    AssertEquals('Child parent Y', ry, py);
    AssertEquals('Child parent Radius', 9.0, prad);

    // Test with 0 radius (sharp corners)
    cont.CornerRadius := 0.0;
    AssertEquals('Inner radius is 0 when corner radius is 0', 0.0, cont.GetInnerRadius());
    cont.GetRenderArea(rx, ry, rw, rh, rrad);
    AssertEquals('Render area radius is 0', 0.0, rrad);
  finally
    cont.Free();
  end;
end;

procedure TFtDesktopWidgetsTest.TestCanvasRoundedRectClipping();
var
  buf: array[0..99, 0..99] of TBgraPixel;
  canvas: TFtCanvasAgg;
  pBuf: PBgraPixel;
  x, y: Integer;
  centerPix, cornerPix: TBgraPixel;
begin
  pBuf := @buf[0, 0];
  // Fill buffer with solid white
  for y := 0 to 99 do
    for x := 0 to 99 do
    begin
      buf[y, x].R := 255;
      buf[y, x].G := 255;
      buf[y, x].B := 255;
      buf[y, x].A := 255;
    end;

  canvas := TFtCanvasAgg.Create(pBuf, 100, 100);
  try
    // Clip to rounded rect at (10, 10, 80, 80) with radius 20.0
    canvas.PushClipRoundedRect(10.0, 10.0, 80.0, 80.0, 20.0);
    try
      // Draw a solid black rect covering the entire 100x100 area
      canvas.DrawRect(0, 0, 100, 100, 0.0, 0.0, 0.0, 1.0);
    finally
      canvas.PopClipRoundedRect();
    end;

    // Center pixel (50, 50) is inside: must be black!
    centerPix := buf[50, 50];
    AssertEquals('Center pixel R is black (0)', 0, centerPix.R);
    AssertEquals('Center pixel G is black (0)', 0, centerPix.G);
    AssertEquals('Center pixel B is black (0)', 0, centerPix.B);

    // Corner pixel (11, 11) is in the top-left corner wedge outside the curve:
    // Distance from arc center (30, 30) is sqrt((30-11.5)^2 + (30-11.5)^2) = 26.16 > 20.0
    // So pixel (11, 11) MUST remain white!
    cornerPix := buf[11, 11];
    AssertEquals('Corner pixel R is preserved white (255)', 255, cornerPix.R);
    AssertEquals('Corner pixel G is preserved white (255)', 255, cornerPix.G);
    AssertEquals('Corner pixel B is preserved white (255)', 255, cornerPix.B);

    // Pixel at (50, 10) (top edge straight section) is inside: must be black!
    AssertEquals('Top edge pixel R is black (0)', 0, buf[10, 50].R);

    // Pixel outside the 80x80 box at (5, 5) must be white (clipped by rect clip)
    AssertEquals('Outside rect pixel R is white (255)', 255, buf[5, 5].R);
  finally
    canvas.Free();
  end;
end;

var
  Application: TTestRunner;

begin
  Application := TTestRunner.Create(nil);
  try
    RegisterTest(TFtCssTest);
    RegisterTest(TFtSvgTest);
    RegisterTest(TFtDesktopWidgetsTest);
    Application.Initialize;
    Application.Run;
  finally
    Application.Free;
  end;
end.
