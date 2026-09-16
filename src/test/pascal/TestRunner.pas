program TestRunner;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, Math, fpcunit, testregistry, consoletestrunner,
  Ft.Css;

type
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

var
  Application: TTestRunner;

begin
  Application := TTestRunner.Create(nil);
  try
    RegisterTest(TFtCssTest);
    Application.Initialize;
    Application.Run;
  finally
    Application.Free;
  end;
end.
