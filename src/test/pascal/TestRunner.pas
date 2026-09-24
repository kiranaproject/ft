program TestRunner;

{$mode objfpc}{$H+}

uses
  ctypes, Classes, SysUtils, Math, Types, fpcunit, testregistry, consoletestrunner,
  Floria.SVG.DOM, Floria.SVG.Parser,
  Ft.Css, Floria.Image.Core, Floria.Image.BMP, Floria.Image.PNG, Floria.Image.JPEG, Floria.Image.Blur, Floria.Canvas.Agg, Floria.SVG.Rasterizer, Ft.Widget, Ft.Widget.Containers, Ft.Widget.Images,
  Ft.Widget.Tabs, Ft.Widget.Splitters, Ft.Widget.TreeViews, Ft.Widget.Tables, Ft.Widget.Texts, Ft.Widget.Buttons,
  Ft.Widget.Switches, Ft.Widget.Selectors, Ft.Backend.X11, Ft.Theme, Floria.Font;

type
  TFtDesktopWidgetsTest = class(TTestCase)
  published
    procedure TestNotebook();
    procedure TestSplitter();
    procedure TestTreeView();
    procedure TestTable();
    procedure TestTableMultiSelect();
    procedure TestDynamicContainerRenderArea();
    procedure TestCanvasRoundedRectClipping();
    procedure TestWindowButton();
    procedure TestSwitch();
    procedure TestHints();
    procedure TestTextWordWrapAndClipping();
    procedure TestButtonIconAndCustomDrawing();
  end;

  TFtSvgTest = class(TTestCase)
  published
    procedure TestSVGRasterizeRect();
    procedure TestSVGRasterizeCircle();
    procedure TestSVGRasterizePath();
    procedure TestSVGRasterizeUseAndGroup();
    procedure TestBitmapCreateFromSVG();
    procedure TestImageWidgetLoadSVG();
    procedure TestImageWidgetLoadPNG();
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
    procedure TestRootPseudoClassResolving();
    procedure TestCssVariablesAndCustomProperties();
    procedure TestDefaultThemeWithRootVariables();
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

procedure TFtCssTest.TestRootPseudoClassResolving();
var
  sheet: TFtStyleSheet;
  css: string;
  stWindow, stBtnNormal, stBtnHover, stBtnDisabled, stBtnCustom: TFtWidgetStyle;
begin
  sheet := TFtStyleSheet.Create();
  try
    css := ':root {' + LineEnding +
           '    color: #1e293b;' + LineEnding +
           '    background-color: #ffffff;' + LineEnding +
           '    border-color: #cbd5e1;' + LineEnding +
           '}' + LineEnding +
           ':root:hover {' + LineEnding +
           '    color: #2563eb;' + LineEnding +
           '    background-color: #f1f5f9;' + LineEnding +
           '}' + LineEnding +
           ':root:disabled {' + LineEnding +
           '    color: #94a3b8;' + LineEnding +
           '    background-color: #f8fafc;' + LineEnding +
           '}' + LineEnding +
           'button.styled {' + LineEnding +
           '    border-width: 2px;' + LineEnding +
           '}' + LineEnding +
           'button.custom {' + LineEnding +
           '    color: #ef4444;' + LineEnding +
           '    background-color: #fee2e2;' + LineEnding +
           '}';

    AssertTrue('Load CSS with :root', sheet.LoadFromString(css));

    // 1. :root directly styles window
    stWindow := sheet.ResolveStyle('window', '', '', '');
    AssertTrue('Window has bg', stWindow.HasBgColor);
    AssertTrue('Window has text color', stWindow.HasTextColor);
    AssertTrue('Window has border color', stWindow.HasBorderColor);
    AssertEquals('Window bg R is 1.0', 1.0, Round(stWindow.BgColor.R * 100.0) / 100.0);

    // 2. Widget without color automatically inherits :root baseline text color and border color
    stBtnNormal := sheet.ResolveStyle('button', '', 'styled', '');
    AssertTrue('Button normal inherits root text color', stBtnNormal.HasTextColor);
    AssertEquals('Root text R ~ 0.12', 0.12, Round(stBtnNormal.TextColor.R * 100.0) / 100.0);
    AssertTrue('Button normal inherits root border color', stBtnNormal.HasBorderColor);

    // 3. Widget on hover inherits :root:hover baseline
    stBtnHover := sheet.ResolveStyle('button', '', 'styled', ':hover');
    AssertTrue('Button hover inherits hover text color', stBtnHover.HasTextColor);
    AssertTrue('Hover text color is blue', (stBtnHover.TextColor.B > 0.8) and (stBtnHover.TextColor.R < 0.3));
    AssertTrue('Button hover inherits hover bg', stBtnHover.HasBgColor);

    // 4. Widget on disabled inherits :root:disabled baseline
    stBtnDisabled := sheet.ResolveStyle('button', '', 'styled', ':disabled');
    AssertTrue('Button disabled inherits disabled text color', stBtnDisabled.HasTextColor);
    AssertTrue('Button disabled inherits disabled bg', stBtnDisabled.HasBgColor);

    // 5. Widget with explicit override does not get overwritten by baseline
    stBtnCustom := sheet.ResolveStyle('button', '', 'custom', '');
    AssertTrue('Custom has text color', stBtnCustom.HasTextColor);
    AssertTrue('Custom text is red', stBtnCustom.TextColor.R > 0.8);
    AssertTrue('Custom has bg', stBtnCustom.HasBgColor);
  finally
    sheet.Free();
  end;
end;

procedure TFtCssTest.TestCssVariablesAndCustomProperties();
var
  sheet: TFtStyleSheet;
  css: string;
  stLight, stDark, stSpecial, stFallback: TFtWidgetStyle;
begin
  sheet := TFtStyleSheet.Create();
  try
    css := ':root {' + LineEnding +
           '    --bg-main: #ffffff;' + LineEnding +
           '    --text-main: #0f172a;' + LineEnding +
           '    --accent: #3b82f6;' + LineEnding +
           '    --radius: 8px;' + LineEnding +
           '    --border-main: 1.5px solid #e2e8f0;' + LineEnding +
           '}' + LineEnding +
           '.dark {' + LineEnding +
           '    --bg-main: #0f172a;' + LineEnding +
           '    --text-main: #f8fafc;' + LineEnding +
           '    --accent: #60a5fa;' + LineEnding +
           '}' + LineEnding +
           'button.themed {' + LineEnding +
           '    background-color: var(--bg-main);' + LineEnding +
           '    color: var(--text-main);' + LineEnding +
           '    border-radius: var(--radius);' + LineEnding +
           '    border: var(--border-main);' + LineEnding +
           '}' + LineEnding +
           'button.special {' + LineEnding +
           '    --bg-main: #10b981;' + LineEnding +
           '    background-color: var(--bg-main);' + LineEnding +
           '}' + LineEnding +
           'button.fallback {' + LineEnding +
           '    background-color: var(--undefined-bg, #a855f7);' + LineEnding +
           '    color: var(--undefined-text, var(--accent, #000000));' + LineEnding +
           '}';

    AssertTrue('Load CSS with custom properties', sheet.LoadFromString(css));

    // 1. Light mode resolution
    stLight := sheet.ResolveStyle('button', '', 'themed', '');
    AssertTrue('Light button has bg', stLight.HasBgColor);
    AssertEquals('Light bg is #ffffff', 1.0, Round(stLight.BgColor.R * 100.0) / 100.0);
    AssertTrue('Light button has text', stLight.HasTextColor);
    AssertTrue('Light button has border width 1.5', Abs(stLight.BorderWidth - 1.5) < 0.01);
    AssertEquals('Light button has radius 8.0', 8.0, stLight.BorderRadius);

    // 2. Dark mode resolution overrides variables
    stDark := sheet.ResolveStyle('button', '', 'themed dark', '');
    AssertTrue('Dark button has bg', stDark.HasBgColor);
    AssertTrue('Dark bg is dark (#0f172a)', stDark.BgColor.R < 0.1);
    AssertTrue('Dark text is white (#f8fafc)', stDark.TextColor.R > 0.9);
    // Preserves non-overridden variable --radius
    AssertEquals('Dark button retains radius 8.0', 8.0, stDark.BorderRadius);

    // 3. Local element override takes precedence over :root
    stSpecial := sheet.ResolveStyle('button', '', 'special', '');
    AssertTrue('Special button has green bg (#10b981)', stSpecial.BgColor.G > 0.7);

    // 4. Fallback support with nested var()
    stFallback := sheet.ResolveStyle('button', '', 'fallback', '');
    AssertTrue('Fallback bg resolved to #a855f7', (stFallback.BgColor.R > 0.6) and (stFallback.BgColor.B > 0.9));
    AssertTrue('Nested fallback resolved to --accent (#3b82f6)', stFallback.TextColor.B > 0.9);

    // 5. Public helper methods
    AssertEquals('Query variable --accent', '#3b82f6', sheet.GetVariable('--accent'));
    AssertEquals('Query variable in dark mode', '#60a5fa', sheet.GetVariable('--accent', 'dark'));
    AssertTrue('ResolveString replaces vars', Pos('#3b82f6', sheet.ResolveString('2px solid var(--accent)')) > 0);
  finally
    sheet.Free();
  end;
end;

procedure TFtCssTest.TestDefaultThemeWithRootVariables();
var
  sheet: TFtStyleSheet;
  stBtnLight, stBtnDark, stBtnHoverDark, stEntryLight, stEntryDark, stWinLight, stWinDark: TFtWidgetStyle;
  stLabelLight, stLabelDark, stMenuDisLight, stMenuDisDark: TFtWidgetStyle;
  disCol: TFtRgbColor;
  path: string;
begin
  sheet := TFtStyleSheet.Create();
  try
    path := 'themes/default.css';
    if not FileExists(path) then path := '../themes/default.css';
    AssertTrue('themes/default.css exists', FileExists(path));
    AssertTrue('Load default.css', sheet.LoadFromFile(path));

    // 1. Light mode button
    stBtnLight := sheet.ResolveStyle('button', '', '', '');
    AssertTrue('Light button has bg', stBtnLight.HasBgColor);
    AssertTrue('Light button bg ~ #f5f7fa', Abs(stBtnLight.BgColor.R - (245.0 / 255.0)) < 0.02);
    AssertTrue('Light button has text #334155', Abs(stBtnLight.TextColor.R - (51.0 / 255.0)) < 0.02);
    AssertTrue('Light button has border #ccd1d9', Abs(stBtnLight.BorderColor.R - (204.0 / 255.0)) < 0.02);

    // 2. Dark mode button (variables automatically switch via .dark)
    stBtnDark := sheet.ResolveStyle('button', '', 'dark', '');
    AssertTrue('Dark button has bg', stBtnDark.HasBgColor);
    AssertTrue('Dark button bg ~ #25282e', Abs(stBtnDark.BgColor.R - (37.0 / 255.0)) < 0.02);
    AssertTrue('Dark button text ~ #d9dee6', Abs(stBtnDark.TextColor.R - (217.0 / 255.0)) < 0.02);
    AssertTrue('Dark button border ~ #3b4048', Abs(stBtnDark.BorderColor.R - (59.0 / 255.0)) < 0.02);

    // 3. Dark mode button hover
    stBtnHoverDark := sheet.ResolveStyle('button', '', 'dark', ':hover');
    AssertTrue('Dark button hover bg ~ #2d323b', Abs(stBtnHoverDark.BgColor.R - (45.0 / 255.0)) < 0.02);
    AssertTrue('Dark button hover text #ffffff', Abs(stBtnHoverDark.TextColor.R - 1.0) < 0.02);
    AssertTrue('Dark button hover border #60a5fa', Abs(stBtnHoverDark.BorderColor.R - (96.0 / 255.0)) < 0.02);

    // 4. Entry surface
    stEntryLight := sheet.ResolveStyle('entry', '', '', '');
    AssertTrue('Entry light bg is white', Abs(stEntryLight.BgColor.R - 1.0) < 0.01);

    stEntryDark := sheet.ResolveStyle('entry', '', 'dark', '');
    AssertTrue('Entry dark bg ~ #27272a', Abs(stEntryDark.BgColor.R - (39.0 / 255.0)) < 0.02);

    // 5. Window background and text
    stWinLight := sheet.ResolveStyle('window', '', '', '');
    AssertTrue('Window light bg ~ #f0f2f5', Abs(stWinLight.BgColor.R - (240.0 / 255.0)) < 0.02);

    stWinDark := sheet.ResolveStyle('window', '', 'dark', '');
    AssertTrue('Window dark bg ~ #18181b', Abs(stWinDark.BgColor.R - (24.0 / 255.0)) < 0.02);

    // 6. Label (TFtText) must NOT have border in light or dark mode
    stLabelLight := sheet.ResolveStyle('label', '', '', '');
    AssertFalse('Label light has no border color', stLabelLight.HasBorderColor);
    AssertFalse('Label light has no border width', stLabelLight.HasBorderWidth);

    stLabelDark := sheet.ResolveStyle('label', '', 'dark', '');
    AssertFalse('Label dark has no border color', stLabelDark.HasBorderColor);
    AssertFalse('Label dark has no border width', stLabelDark.HasBorderWidth);

    // 7. Menu disabled text color
    stMenuDisLight := sheet.ResolveStyle('menu', '', '', ':disabled');
    AssertTrue('Menu disabled light has text color', stMenuDisLight.HasTextColor);
    AssertTrue('Menu disabled light is slate-400 (#94a3b8)', Abs(stMenuDisLight.TextColor.R - (148.0 / 255.0)) < 0.03);

    stMenuDisDark := sheet.ResolveStyle('menu', '', 'dark', ':disabled');
    AssertTrue('Menu disabled dark has text color', stMenuDisDark.HasTextColor);
    AssertTrue('Menu disabled dark is zinc-500 (#71717a)', Abs(stMenuDisDark.TextColor.R - (113.0 / 255.0)) < 0.03);

    // 8. Theme manager menu disabled text color
    FtSetDarkMode(False);
    disCol := FtGetTheme().GetMenuDisabledTextColor();
    AssertTrue('Theme light disabled menu text ~ #94a3b8', Abs(disCol.R - (148.0 / 255.0)) < 0.03);

    FtSetDarkMode(True);
    disCol := FtGetTheme().GetMenuDisabledTextColor();
    AssertTrue('Theme dark disabled menu text ~ #71717a', Abs(disCol.R - (113.0 / 255.0)) < 0.03);
    FtSetDarkMode(False);
  finally
    sheet.Free();
  end;
end;

{ TFtSvgTest }

procedure TFtSvgTest.TestSVGRasterizeRect();
var
  svg: string;
  bmp: TFloriaImage;
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
  bmp: TFloriaImage;
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
  bmp: TFloriaImage;
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
  bmp: TFloriaImage;
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
  bmp: TFloriaImage;
  p: PByte;
begin
  svg := '<svg width="60" height="60" viewBox="0 0 60 60">' +
         '  <rect width="60" height="60" fill="#00ffff" />' +
         '</svg>';
  bmp := TFloriaSVGRenderer.RenderStringToImage(svg, 60, 60);
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

procedure TFtSvgTest.TestImageWidgetLoadPNG();
var
  img: TFtImage;
  assetPath: string;
begin
  img := TFtImage.Create(nil, 0, 0, 100, 100);
  try
    if FileExists('examples/assets/emoji_smile.png') then
      assetPath := 'examples/assets/emoji_smile.png'
    else if FileExists('../examples/assets/emoji_smile.png') then
      assetPath := '../examples/assets/emoji_smile.png'
    else
      assetPath := ExtractFilePath(ParamStr(0)) + '../examples/assets/emoji_smile.png';
    AssertTrue('Asset file exists: ' + assetPath, FileExists(assetPath));
    img.LoadFromFile(assetPath);
    AssertTrue('Bitmap assigned', Assigned(img.Bitmap));
    AssertEquals('Width 128', 128, img.Bitmap.Width);
    AssertEquals('Height 128', 128, img.Bitmap.Height);
  finally
    img.Free();
  end;
end;

procedure TFtSvgTest.TestSVGRasterizeLinearGradient();
var
  svg: string;
  bmp: TFloriaImage;
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
  bmp: TFloriaImage;
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
  testBmp: TFloriaImage;
begin
  tbl := TFtTable.Create(nil);
  testBmp := TFloriaImage.Create(16, 16);
  try
    tbl.X := 0; tbl.Y := 0; tbl.Width := 500; tbl.Height := 300;
    tbl.AddColumn('ID', 60.0, taCenter);
    tbl.AddColumn('Name', 180.0, taLeft);
    tbl.AddColumn('Price', 100.0, taRight);

    AssertEquals('Column count is 3', 3, tbl.ColumnCount);
    AssertEquals('Column 0 title', 'ID', tbl.Columns[0].Title);
    AssertEquals('Column 1 width', 180.0, tbl.Columns[1].Width);
    AssertEquals('Column 2 align is taRight', Ord(taRight), Ord(tbl.Columns[2].Alignment));

    // Test Column Icon
    tbl.SetColumnIcon(0, testBmp);
    AssertTrue('Column icon assigned', tbl.GetColumnIcon(0) = testBmp);

    tbl.AddRow(['1', 'Mechanical Keyboard', '$89.99']);
    tbl.AddRow(['2', 'Gaming Mouse', '$49.99']);

    AssertEquals('Row count is 2', 2, tbl.RowCount);
    AssertEquals('Cell (0, 0)', '1', tbl.GetCell(0, 0));
    AssertEquals('Cell (0, 1)', 'Mechanical Keyboard', tbl.GetCell(0, 1));
    AssertEquals('Cell (1, 2)', '$49.99', tbl.GetCell(1, 2));

    // Test Cell Icon
    tbl.SetCellIcon(0, 1, testBmp);
    AssertTrue('Cell icon assigned', tbl.GetCellIcon(0, 1) = testBmp);

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
    testBmp.Free();
    tbl.Free();
  end;
end;

procedure TFtDesktopWidgetsTest.TestTableMultiSelect();
var
  tbl: TFtTable;
  rows: TIntegerDynArray;
begin
  tbl := TFtTable.Create(nil);
  try
    tbl.X := 0; tbl.Y := 0; tbl.Width := 500; tbl.Height := 300;
    tbl.AddColumn('ID', 60.0, taCenter);
    tbl.AddColumn('Name', 180.0, taLeft);

    tbl.AddRow(['1', 'Item 1']);
    tbl.AddRow(['2', 'Item 2']);
    tbl.AddRow(['3', 'Item 3']);
    tbl.AddRow(['4', 'Item 4']);
    tbl.AddRow(['5', 'Item 5']);

    // 1. Initial defaults (MultiSelect = False)
    AssertFalse('Default MultiSelect is False', tbl.MultiSelect);
    AssertEquals('Default SelectedRow is -1', -1, tbl.SelectedRow);
    AssertEquals('Default selected count is 0', 0, tbl.GetSelectedRowCount());

    // Single-selection behavior
    tbl.SelectedRow := 1;
    AssertEquals('SelectedRow is 1', 1, tbl.SelectedRow);
    AssertTrue('Row 1 is selected', tbl.IsRowSelected(1));
    AssertFalse('Row 0 is not selected', tbl.IsRowSelected(0));
    AssertEquals('Selected count is 1', 1, tbl.GetSelectedRowCount());
    rows := tbl.GetSelectedRows();
    AssertEquals('Selected rows length is 1', 1, Length(rows));
    AssertEquals('Selected row index is 1', 1, rows[0]);

    // 2. Enable MultiSelect
    tbl.MultiSelect := True;
    AssertTrue('MultiSelect is True', tbl.MultiSelect);
    AssertTrue('Row 1 remains selected after enabling MultiSelect', tbl.IsRowSelected(1));

    // Programmatically add row 3
    tbl.SetRowSelected(3, True);
    AssertTrue('Row 3 is selected', tbl.IsRowSelected(3));
    AssertTrue('Row 1 is still selected', tbl.IsRowSelected(1));
    AssertEquals('Selected count is 2', 2, tbl.GetSelectedRowCount());
    rows := tbl.GetSelectedRows();
    AssertEquals('Selected rows length is 2', 2, Length(rows));
    AssertEquals('Row 1 in list', 1, rows[0]);
    AssertEquals('Row 3 in list', 3, rows[1]);

    // Programmatically unselect row 1
    tbl.SetRowSelected(1, False);
    AssertFalse('Row 1 unselected', tbl.IsRowSelected(1));
    AssertTrue('Row 3 remains selected', tbl.IsRowSelected(3));
    AssertEquals('Selected count is 1', 1, tbl.GetSelectedRowCount());

    // 3. SelectAll()
    tbl.SelectAll();
    AssertEquals('All 5 rows selected', 5, tbl.GetSelectedRowCount());
    AssertTrue('Row 0 selected', tbl.IsRowSelected(0));
    AssertTrue('Row 4 selected', tbl.IsRowSelected(4));

    // 4. ClearSelection()
    tbl.ClearSelection();
    AssertEquals('Selected count is 0 after ClearSelection', 0, tbl.GetSelectedRowCount());
    AssertEquals('SelectedRow is -1 after ClearSelection', -1, tbl.SelectedRow);
    AssertFalse('Row 0 not selected', tbl.IsRowSelected(0));

    // 5. Mouse interactions
    // Regular click on row 2 (no modifiers)
    FtSetKeyboardModifiers(0);
    tbl.MouseDown(10, Round(tbl.Y + tbl.HeaderHeight + 2.5 * tbl.RowHeight), 1);
    AssertEquals('SelectedRow is 2 after click', 2, tbl.SelectedRow);
    AssertTrue('Row 2 is selected', tbl.IsRowSelected(2));
    AssertEquals('Only 1 row selected', 1, tbl.GetSelectedRowCount());

    // Ctrl + Click on row 4 (toggle on)
    FtSetKeyboardModifiers(FT_KEY_MOD_CONTROL);
    tbl.MouseDown(10, Round(tbl.Y + tbl.HeaderHeight + 4.5 * tbl.RowHeight), 1);
    AssertTrue('Row 2 remains selected', tbl.IsRowSelected(2));
    AssertTrue('Row 4 is selected', tbl.IsRowSelected(4));
    AssertEquals('Selected count is 2 after Ctrl+Click', 2, tbl.GetSelectedRowCount());

    // Ctrl + Click on row 2 (toggle off)
    tbl.MouseDown(10, Round(tbl.Y + tbl.HeaderHeight + 2.5 * tbl.RowHeight), 1);
    AssertFalse('Row 2 toggled off', tbl.IsRowSelected(2));
    AssertTrue('Row 4 still selected', tbl.IsRowSelected(4));
    AssertEquals('Selected count is 1 after Ctrl+Click off', 1, tbl.GetSelectedRowCount());

    // Regular click on row 1 resets selection and sets anchor
    FtSetKeyboardModifiers(0);
    tbl.MouseDown(10, Round(tbl.Y + tbl.HeaderHeight + 1.5 * tbl.RowHeight), 1);
    AssertTrue('Row 1 is selected', tbl.IsRowSelected(1));
    AssertFalse('Row 4 is unselected', tbl.IsRowSelected(4));
    AssertEquals('Selected count is 1 after fresh click', 1, tbl.GetSelectedRowCount());

    // Shift + Click on row 3 (range from anchor 1 to 3: rows 1, 2, 3)
    FtSetKeyboardModifiers(FT_KEY_MOD_SHIFT);
    tbl.MouseDown(10, Round(tbl.Y + tbl.HeaderHeight + 3.5 * tbl.RowHeight), 1);
    AssertTrue('Row 1 in range', tbl.IsRowSelected(1));
    AssertTrue('Row 2 in range', tbl.IsRowSelected(2));
    AssertTrue('Row 3 in range', tbl.IsRowSelected(3));
    AssertFalse('Row 0 not in range', tbl.IsRowSelected(0));
    AssertFalse('Row 4 not in range', tbl.IsRowSelected(4));
    AssertEquals('Selected count is 3 after Shift+Click', 3, tbl.GetSelectedRowCount());

    // 6. Keyboard interactions
    // Escape key clears selection
    FtSetKeyboardModifiers(0);
    tbl.KeyDown($FF1B, 0, '');
    AssertEquals('Escape clears selection', 0, tbl.GetSelectedRowCount());

    // Ctrl + A selects all
    tbl.KeyDown($61, FT_KEY_MOD_CONTROL, 'a');
    AssertEquals('Ctrl+A selects all 5 rows', 5, tbl.GetSelectedRowCount());

    // 7. Toggle MultiSelect back to False (collapses selection)
    tbl.MultiSelect := False;
    AssertFalse('MultiSelect toggled off', tbl.MultiSelect);
    AssertEquals('Selection collapsed to at most 1', 1, tbl.GetSelectedRowCount());

    // 8. DeleteRow consistency
    tbl.ClearSelection();
    tbl.SelectedRow := 2; // selects row 2
    tbl.DeleteRow(0); // deleting row 0 shifts row 2 to row 1
    AssertEquals('SelectedRow shifted to 1 after deleting row 0', 1, tbl.SelectedRow);
    AssertTrue('Shifted row 1 is selected', tbl.IsRowSelected(1));
  finally
    FtSetKeyboardModifiers(0);
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
  gWindowButtonClicked: Boolean = False;

procedure OnTestWindowButtonClick(Sender: Pointer; UserData: Pointer); cdecl;
begin
  gWindowButtonClicked := True;
end;

procedure TFtDesktopWidgetsTest.TestWindowButton();
var
  btn: TFtWindowButton;
  canvas: TFtCanvasAgg;
  k: TFtWindowButtonKind;
  s: TFtWindowButtonStyle;
  rawBuf: array of Byte;
begin
  btn := TFtWindowButton.Create(nil);
  try
    AssertEquals('Element type', 'windowbutton', btn.GetElementType());
    AssertEquals('Default kind is close', Ord(wbkClose), Ord(btn.Kind));
    AssertEquals('Default style is circle', Ord(wbsCircle), Ord(btn.Style));
    AssertEquals('Default width 16', 16, btn.Width);
    AssertEquals('Default height 16', 16, btn.Height);
    AssertEquals('Normal pseudo-class', '', btn.GetStatePseudoClass());

    // Transition configuration
    AssertEquals('Default transition duration is 180ms', 180, btn.TransitionDuration);
    btn.TransitionDuration := 250;
    AssertEquals('Custom transition duration 250ms', 250, btn.TransitionDuration);
    AssertEquals('Initial hover progress is 0.0', 0, Round(btn.HoverProgress * 100));

    // Kinds
    btn.Kind := wbkMinimize;
    AssertEquals('Kind minimize', Ord(wbkMinimize), Ord(btn.Kind));
    btn.Kind := wbkMaximize;
    AssertEquals('Kind maximize (Mac chevron)', Ord(wbkMaximize), Ord(btn.Kind));
    btn.Kind := wbkRestore;
    AssertEquals('Kind restore (Mac chevron)', Ord(wbkRestore), Ord(btn.Kind));
    btn.Kind := wbkAdd;
    AssertEquals('Kind add', Ord(wbkAdd), Ord(btn.Kind));

    // Styles
    btn.Style := wbsSquircle;
    AssertEquals('Style squircle', Ord(wbsSquircle), Ord(btn.Style));
    btn.Style := wbsSquare;
    AssertEquals('Style square', Ord(wbsSquare), Ord(btn.Style));
    btn.Style := wbsCircle;

    // Mouse events
    gWindowButtonClicked := False;
    btn.OnClick := @OnTestWindowButtonClick;
    btn.X := 10;
    btn.Y := 10;
    btn.Width := 20;
    btn.Height := 20;

    btn.MouseEnter();
    AssertEquals('State hover', Ord(bsHovered), Ord(btn.State));
    AssertEquals('Hover pseudo-class', ':hover', btn.GetStatePseudoClass());

    btn.MouseDown(15, 15, 1);
    AssertEquals('State pressed', Ord(bsPressed), Ord(btn.State));
    AssertEquals('Active pseudo-class', ':active', btn.GetStatePseudoClass());

    btn.MouseUp(15, 15, 1);
    AssertTrue('Click callback invoked', gWindowButtonClicked);
    AssertEquals('State back to hover', Ord(bsHovered), Ord(btn.State));

    btn.MouseLeave();
    AssertEquals('State normal after leave', Ord(bsNormal), Ord(btn.State));

    // Disabled state
    btn.Enabled := False;
    AssertEquals('Disabled pseudo-class', ':disabled', btn.GetStatePseudoClass());
    AssertEquals('Disabled resets hover progress', 0, Round(btn.HoverProgress * 100));
    btn.Enabled := True;

    // Direct rendering test for all kinds and styles in Canvas with hover transitions
    SetLength(rawBuf, 64 * 64 * 4);
    canvas := TFtCanvasAgg.Create(@rawBuf[0], 64, 64);
    try
      for s := Low(TFtWindowButtonStyle) to High(TFtWindowButtonStyle) do
        for k := Low(TFtWindowButtonKind) to High(TFtWindowButtonKind) do
        begin
          // Normal, mid-transition, full hover, and pressed states in Light and Dark
          TFtWindowButton.DrawWindowButton(canvas, 4, 4, 24, 24, k, s, bsNormal, False, 0.0, 0.0);
          TFtWindowButton.DrawWindowButton(canvas, 4, 4, 24, 24, k, s, bsNormal, False, 0.0, 0.5);
          TFtWindowButton.DrawWindowButton(canvas, 4, 4, 24, 24, k, s, bsHovered, False, 0.0, 1.0);
          TFtWindowButton.DrawWindowButton(canvas, 4, 4, 24, 24, k, s, bsPressed, False);
          TFtWindowButton.DrawWindowButton(canvas, 4, 4, 24, 24, k, s, bsNormal, True, 0.0, 0.0);
          TFtWindowButton.DrawWindowButton(canvas, 4, 4, 24, 24, k, s, bsNormal, True, 0.0, 0.5);
          TFtWindowButton.DrawWindowButton(canvas, 4, 4, 24, 24, k, s, bsHovered, True, 0.0, 1.0);
          TFtWindowButton.DrawWindowButton(canvas, 4, 4, 24, 24, k, s, bsPressed, True);
        end;
    finally
      canvas.Free();
    end;
  finally
    btn.Free();
  end;
end;

procedure TFtDesktopWidgetsTest.TestSwitch();
var
  sw: TFtSwitch;
  rawBuf: array of Byte;
  canvas: TFtCanvasAgg;
begin
  sw := TFtSwitch.Create(nil);
  try
    AssertFalse('Default switch unchecked', sw.Checked);
    AssertEquals('Initial thumb progress 0', 0, Round(sw.ThumbProgress * 100));
    AssertEquals('Default transition duration 200ms', 200, sw.TransitionDuration);

    // Custom transition duration
    sw.TransitionDuration := 150;
    AssertEquals('Custom transition duration 150ms', 150, sw.TransitionDuration);

    // Pre-render state initialization
    sw.Checked := True;
    AssertTrue('Switch checked', sw.Checked);
    AssertEquals('Pre-render snap thumb progress 1.0', 100, Round(sw.ThumbProgress * 100));

    // Render pass
    SetLength(rawBuf, 128 * 64 * 4);
    canvas := TFtCanvasAgg.Create(@rawBuf[0], 128, 64);
    try
      sw.Draw(canvas);

      // Toggle via Click() -> transition begins
      sw.Click();
      AssertFalse('Switch unchecked after click', sw.Checked);
      AssertEquals('Pseudo-class empty after click', '', sw.GetStatePseudoClass());

      // Draw frame during animation
      sw.Draw(canvas);

      // Disable duration to test instant snap
      sw.TransitionDuration := 0;
      sw.Click(); // toggle back to Checked
      AssertTrue('Switch checked again', sw.Checked);
      AssertEquals('Thumb snaps to 1.0 when duration is 0', 100, Round(sw.ThumbProgress * 100));
      AssertEquals('Pseudo-class is :checked', ':checked', sw.GetStatePseudoClass());
    finally
      canvas.Free();
    end;
  finally
    sw.Free();
  end;
end;

procedure TFtDesktopWidgetsTest.TestHints();
var
  w: TFtWidget;
  btn: TFtButton;
  wb: TFtWindowButton;
  txt: TFtText;
  cb: TFtCheckBox;
  rb: TFtRadioButton;
  sw: TFtSwitch;
begin
  // 1. Base TFtWidget Hint properties
  w := TFtWidget.Create(nil);
  try
    AssertEquals('Default Hint is empty', '', w.Hint);
    AssertTrue('Default ShowHint is True', w.ShowHint);
    AssertEquals('Default effective hint is empty', '', w.GetEffectiveHint());

    w.Hint := 'Tooltip content';
    AssertEquals('Effective hint returns Hint', 'Tooltip content', w.GetEffectiveHint());

    w.ShowHint := False;
    AssertEquals('ShowHint=False yields empty effective hint', '', w.GetEffectiveHint());

    w.ShowHint := True;
    w.Visible := False;
    AssertEquals('Visible=False yields empty effective hint', '', w.GetEffectiveHint());
  finally
    w.Free();
  end;

  // 2. TFtButton caption truncation & custom override
  btn := TFtButton.Create(nil);
  try
    btn.Width := 200;
    btn.Caption := 'OK';
    AssertEquals('Non-truncated button caption yields empty hint', '', btn.GetEffectiveHint());

    btn.Width := 30;
    btn.Caption := 'A very long button caption that exceeds width';
    AssertEquals('Truncated button caption yields full caption as hint',
                 'A very long button caption that exceeds width', btn.GetEffectiveHint());

    btn.Hint := 'Custom button override';
    AssertEquals('Custom hint overrides auto-truncated caption',
                 'Custom button override', btn.GetEffectiveHint());
  finally
    btn.Free();
  end;

  // 3. TFtWindowButton kind hints & custom override
  wb := TFtWindowButton.Create(nil);
  try
    wb.Kind := wbkClose;
    AssertEquals('wbkClose hint', 'Close', wb.GetEffectiveHint());

    wb.Kind := wbkMinimize;
    AssertEquals('wbkMinimize hint', 'Minimize', wb.GetEffectiveHint());

    wb.Kind := wbkMaximize;
    AssertEquals('wbkMaximize hint', 'Maximize', wb.GetEffectiveHint());

    wb.Kind := wbkRestore;
    AssertEquals('wbkRestore hint', 'Restore', wb.GetEffectiveHint());

    wb.Hint := 'Close Window';
    AssertEquals('Custom window button hint overrides default kind hint',
                 'Close Window', wb.GetEffectiveHint());
  finally
    wb.Free();
  end;

  // 4. TFtText truncation & custom override
  txt := TFtText.Create(nil, 'Short');
  try
    txt.Width := 200;
    AssertEquals('Non-truncated text yields empty hint', '', txt.GetEffectiveHint());

    txt.Width := 25;
    txt.Text := 'This label text exceeds twenty-five pixels';
    AssertEquals('Truncated text yields full text as hint',
                 'This label text exceeds twenty-five pixels', txt.GetEffectiveHint());

    txt.Hint := 'Information label';
    AssertEquals('Custom hint overrides label text',
                 'Information label', txt.GetEffectiveHint());
  finally
    txt.Free();
  end;

  // 5. TFtCheckBox & TFtRadioButton truncation & custom override
  cb := TFtCheckBox.Create(nil);
  try
    cb.Width := 250;
    cb.Caption := 'Enable Feature';
    AssertEquals('Non-truncated checkbox yields empty hint', '', cb.GetEffectiveHint());

    cb.Width := 35;
    cb.Caption := 'Very long checkbox caption overflowing boundary';
    AssertEquals('Truncated checkbox yields full caption',
                 'Very long checkbox caption overflowing boundary', cb.GetEffectiveHint());

    cb.Hint := 'Toggle setting';
    AssertEquals('Custom hint on checkbox', 'Toggle setting', cb.GetEffectiveHint());
  finally
    cb.Free();
  end;

  rb := TFtRadioButton.Create(nil);
  try
    rb.Width := 250;
    rb.Caption := 'Option A';
    AssertEquals('Non-truncated radio yields empty hint', '', rb.GetEffectiveHint());

    rb.Width := 35;
    rb.Caption := 'Option with long descriptive title that overflows';
    AssertEquals('Truncated radio yields full caption',
                 'Option with long descriptive title that overflows', rb.GetEffectiveHint());

    rb.Hint := 'Choose Option A';
    AssertEquals('Custom hint on radio', 'Choose Option A', rb.GetEffectiveHint());
  finally
    rb.Free();
  end;

  // 6. TFtSwitch truncation & custom override
  sw := TFtSwitch.Create(nil);
  try
    sw.Width := 250;
    sw.Caption := 'Bluetooth';
    AssertEquals('Non-truncated switch caption yields empty hint', '', sw.GetEffectiveHint());

    sw.Width := 50;
    sw.Caption := 'Bluetooth Power State Active';
    AssertEquals('Truncated switch caption yields full caption',
                 'Bluetooth Power State Active', sw.GetEffectiveHint());

    sw.Hint := 'Toggle Bluetooth Device';
    AssertEquals('Custom switch hint', 'Toggle Bluetooth Device', sw.GetEffectiveHint());
  finally
    sw.Free();
  end;

  // 7. Global hint delay getter and setter
  AssertEquals('Default hint delay is 500ms', 500, FtGetHintDelay());
  FtSetHintDelay(350);
  AssertEquals('Updated hint delay is 350ms', 350, FtGetHintDelay());
  FtSetHintDelay(500); // restore default

  // 8. Tooltip theme integration
  AssertTrue('Tooltip background color has valid brightness',
             (FtGetTheme().GetTooltipBackground().R >= 0.0) and
             (FtGetTheme().GetTooltipBackground().R <= 1.0));
  AssertTrue('Tooltip text color has valid brightness',
             (FtGetTheme().GetTooltipTextColor().R >= 0.0) and
             (FtGetTheme().GetTooltipTextColor().R <= 1.0));
end;

procedure TFtDesktopWidgetsTest.TestTextWordWrapAndClipping();
var
  txt: TFtText;
  f: TFtFont;
  lines: TFtTextLineArray;
  sumChars: Integer;
  i: Integer;
  buf: array[0..99, 0..99] of TBgraPixel;
  canvas: TFtCanvasAgg;
  pBuf: PBgraPixel;
  x, y: Integer;
begin
  txt := TFtText.Create(nil, 'The quick brown fox jumps over the lazy dog');
  try
    // 1. Default properties
    AssertFalse('Default WordWrap is False', txt.WordWrap);
    AssertFalse('Default Wrap alias is False', txt.Wrap);

    // 2. Setting WordWrap / Wrap
    txt.WordWrap := True;
    AssertTrue('WordWrap is True', txt.WordWrap);
    AssertTrue('Wrap alias is True', txt.Wrap);

    txt.Wrap := False;
    AssertFalse('WordWrap after Wrap := False', txt.WordWrap);
    AssertFalse('Wrap alias after Wrap := False', txt.Wrap);

    txt.WordWrap := True;

    // 3. BuildLines with wide vs narrow width
    f := txt.Font;
    if not Assigned(f) then f := FtGetSystemFont();

    lines := txt.BuildLines(f, 2000.0);
    AssertEquals('Wide width yields 1 line', 1, Length(lines));
    AssertEquals('Single line text matches', 'The quick brown fox jumps over the lazy dog', lines[0].Text);

    lines := txt.BuildLines(f, 80.0);
    AssertTrue('Narrow width yields multiple lines', Length(lines) > 1);
    sumChars := 0;
    for i := 0 to High(lines) do
      Inc(sumChars, lines[i].CharLen);
    AssertEquals('All characters accounted for across lines', txt.CharCount(), sumChars);

    // 4. Long unbroken word
    txt.Text := 'Supercalifragilisticexpialidocious';
    lines := txt.BuildLines(f, 50.0);
    AssertTrue('Long unbroken word splits into multiple lines', Length(lines) > 1);
    sumChars := 0;
    for i := 0 to High(lines) do
      Inc(sumChars, lines[i].CharLen);
    AssertEquals('All characters of long word preserved', txt.CharCount(), sumChars);

    // 5. Explicit newlines
    txt.Text := 'Line 1'#10'Line 2'#10'Line 3';
    lines := txt.BuildLines(f, 500.0);
    AssertEquals('Explicit newlines yield 3 lines', 3, Length(lines));
    AssertEquals('Line 1 text', 'Line 1', lines[0].Text);
    AssertEquals('Line 2 text', 'Line 2', lines[1].Text);
    AssertEquals('Line 3 text', 'Line 3', lines[2].Text);

    // 6. Hit testing multiline text
    txt.X := 10;
    txt.Y := 10;
    txt.Width := 200;
    txt.Height := 100;
    lines := txt.BuildLines(f, 196.0);
    AssertTrue('Lines count >= 2', Length(lines) >= 2);
    AssertEquals('HitTestChar line 0 start', 0, txt.HitTestChar(12, Round(lines[0].Y)));
    AssertEquals('HitTestChar line 1 start', lines[1].StartChar, txt.HitTestChar(12, Round(lines[1].Y)));

    // 7. GetEffectiveHint on vertical overflow
    txt.Height := 20; // Only enough for 1 line, but text has 3 lines
    AssertEquals('Vertical overflow yields full text hint', 'Line 1'#10'Line 2'#10'Line 3', txt.GetEffectiveHint());
    txt.Height := 200; // Enough for all 3 lines
    AssertEquals('Sufficient height yields empty hint', '', txt.GetEffectiveHint());

    // 8. Clipping test: verify no text pixels drawn outside widget bounds
    pBuf := @buf[0, 0];
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
      txt.X := 10;
      txt.Y := 10;
      txt.Width := 40;
      txt.Height := 25;
      txt.Text := 'WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW';
      txt.SetColor(0.0, 0.0, 0.0);
      txt.Draw(canvas);

      // Widget bound is X: [10..50], Y: [10..35].
      // Any pixel outside X > 50 or Y > 35 must remain untouched white (R=255)!
      for x := 52 to 99 do
        for y := 10 to 35 do
        begin
          AssertEquals('Pixel outside X bounds untouched', 255, buf[y, x].R);
        end;

      for y := 37 to 99 do
        for x := 10 to 50 do
        begin
          AssertEquals('Pixel outside Y bounds untouched', 255, buf[y, x].R);
        end;
    finally
      canvas.Free();
    end;
  finally
    txt.Free();
  end;
end;

var
  g_TestIconPainted: Boolean = False;
  g_TestButtonPainted: Boolean = False;
  g_TestIconX: Double = 0.0;
  g_TestIconY: Double = 0.0;
  g_TestIconW: Double = 0.0;
  g_TestIconH: Double = 0.0;

procedure TestButtonIconPainter(Sender: Pointer; Canvas: Pointer; X, Y, W, H: Double; State: cint32; UserData: Pointer); cdecl;
begin
  g_TestIconPainted := True;
  g_TestIconX := X;
  g_TestIconY := Y;
  g_TestIconW := W;
  g_TestIconH := H;
end;

procedure TestButtonOverlayPainter(Sender: Pointer; Canvas: Pointer; X, Y, W, H: Double; State: cint32; UserData: Pointer); cdecl;
begin
  g_TestButtonPainted := True;
end;

procedure TFtDesktopWidgetsTest.TestButtonIconAndCustomDrawing();
var
  btn: TFtButton;
  buf: array[0..99, 0..99] of TBgraPixel;
  canvas: TFtCanvasAgg;
begin
  btn := TFtButton.Create(nil);
  try
    btn.X := 10;
    btn.Y := 10;
    btn.Width := 120;
    btn.Height := 40;
    btn.Caption := 'Save';

    // 1. Icon default state
    AssertNull('Initial icon is nil', btn.Icon);
    AssertEquals('Default icon position is ftbipLeft', Ord(ftbipLeft), Ord(btn.IconPosition));
    AssertEquals('Default icon gap is 6', 6, btn.IconGap);

    // 2. Load icon from SVG
    btn.LoadIconFromSVG('<svg width="16" height="16"><rect width="16" height="16" fill="#ff0000"/></svg>');
    AssertNotNull('Icon loaded from SVG', btn.Icon);
    AssertTrue('Icon width > 0', btn.Icon.Width > 0);
    AssertTrue('Icon height > 0', btn.Icon.Height > 0);

    // 3. Icon positioning & properties
    btn.IconPosition := ftbipRight;
    AssertEquals('Position right', Ord(ftbipRight), Ord(btn.IconPosition));
    btn.IconPosition := ftbipTop;
    AssertEquals('Position top', Ord(ftbipTop), Ord(btn.IconPosition));
    btn.IconPosition := ftbipOnly;
    AssertEquals('Position only', Ord(ftbipOnly), Ord(btn.IconPosition));
    btn.IconPosition := ftbipLeft;

    btn.IconWidth := 20;
    btn.IconHeight := 20;
    btn.IconGap := 10;
    AssertEquals('IconWidth is 20', 20, btn.IconWidth);
    AssertEquals('IconHeight is 20', 20, btn.IconHeight);
    AssertEquals('IconGap is 10', 10, btn.IconGap);

    // 4. Rendering with icon
    canvas := TFtCanvasAgg.Create(@buf[0, 0], 100, 100);
    try
      btn.Draw(canvas);
    finally
      canvas.Free();
    end;

    // 5. Custom icon paint callback
    g_TestIconPainted := False;
    g_TestButtonPainted := False;
    btn.OnPaintIcon := @TestButtonIconPainter;
    btn.OnPaint := @TestButtonOverlayPainter;

    canvas := TFtCanvasAgg.Create(@buf[0, 0], 100, 100);
    try
      btn.Draw(canvas);
      AssertTrue('Custom icon paint callback invoked', g_TestIconPainted);
      AssertTrue('Icon painted within button X bounds', (g_TestIconX >= btn.X) and (g_TestIconX + g_TestIconW <= btn.X + btn.Width));
      AssertTrue('Icon painted within button Y bounds', (g_TestIconY >= btn.Y) and (g_TestIconY + g_TestIconH <= btn.Y + btn.Height));
      AssertTrue('Custom overlay paint callback invoked', g_TestButtonPainted);
    finally
      canvas.Free();
    end;

    // 6. Clear icon
    btn.ClearIcon();
    AssertNull('Icon cleared', btn.Icon);
  finally
    btn.Free();
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
