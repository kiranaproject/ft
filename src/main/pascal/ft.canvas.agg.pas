unit Ft.Canvas.Agg;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  agg_color,
  agg_rendering_buffer,
  agg_pixfmt,
  agg_pixfmt_rgba,
  agg_renderer_base,
  agg_renderer_scanline,
  agg_render_scanlines,
  agg_rasterizer_scanline_aa,
  agg_scanline_u,
  agg_font_cache_manager,
  agg_gsv_text,
  agg_conv_stroke,
  agg_conv_curve,
  agg_bounding_rect,
  agg_rounded_rect,
  agg_path_storage,
  agg_math_stroke,
  agg_basics,
  agg_span_gradient,
  agg_gradient_lut,
  agg_span_interpolator_linear,
  agg_span_allocator,
  agg_trans_affine,
  Math,
  Contnrs,
  Floria.SVG.Types,
  Floria.SVG.DOM,
  Ft.Font,
  Ft.Bitmap,
  Ft.Blur;

type
  TFtClipRect = record
    X1, Y1, X2, Y2: Integer;
  end;

  TFtCanvasAgg = class
  private
    FBuffer: Pointer;
    FWidth, FHeight: Integer;
    FRenderingBuf: rendering_buffer;
    FPixFormat: pixel_formats;
    FRendererBase: renderer_base;
    FRasterizer: rasterizer_scanline_aa;
    FScanline: scanline_u8;
    FClipStack: array[0..63] of TFtClipRect;
    FClipStackCount: Integer;
    FAlphaStack: array[0..63] of Double;
    FAlphaStackCount: Integer;
    FCurrentAlpha: Double;
    procedure DrawTextHershey(X, Y: Double; const AText: string; ASize: Double; R, G, B: Double);
    procedure DrawTextCenteredHershey(X, Y, W, H: Integer; const AText: string; ASize: Double; R, G, B: Double);
  public
    constructor Create(ABuffer: Pointer; AWidth, AHeight: Integer);
    destructor Destroy(); override;
    procedure Resize(ABuffer: Pointer; AWidth, AHeight: Integer);
    procedure Clear(R, G, B: Double);
    procedure DrawRect(X, Y, W, H: Integer; R, G, B: Double; A: Double = 1.0);
    procedure DrawRoundedRect(X, Y, W, H: Double; Radius: Double; R, G, B: Double; A: Double = 1.0);
    procedure DrawRoundedRectOutline(X, Y, W, H: Double; Radius: Double; BorderWidth: Double; R, G, B: Double; A: Double = 1.0);
    procedure DrawShadow(X, Y, W, H: Double; Radius: Double; OffsetX, OffsetY: Double; BlurRadius: Double; ShadowR, ShadowG, ShadowB, ShadowOpacity: Double);
    procedure BlurRoundedRect(X, Y, W, H: Double; Radius: Double; BlurRadius: Double);
    procedure BlurRect(X, Y, W, H: Double; BlurRadius: Double);
    procedure PushClipRect(X, Y, W, H: Integer);
    procedure PopClipRect();
    procedure SetClipRect(X, Y, W, H: Integer);
    procedure ResetClipRect();
    procedure ResetAllClipping();
    function GetClipRect(out X, Y, W, H: Integer): Boolean;
    function IntersectsClip(X, Y, W, H: Integer): Boolean;

    procedure PushAlpha(AAlpha: Double);
    procedure PopAlpha();
    procedure ResetAlpha();
    property CurrentAlpha: Double read FCurrentAlpha;

    procedure DrawText(X, Y: Double; const AText: string; AFont: TFtFont; R, G, B: Double);
    procedure DrawTextCentered(X, Y, W, H: Integer; const AText: string; AFont: TFtFont; R, G, B: Double);

    procedure DrawCheckMark(CX, CY: Double; R, G, B: Double; A: Double = 1.0);
    procedure DrawSubMenuArrow(CX, CY: Double; R, G, B: Double; A: Double = 1.0);
    procedure DrawCircle(CX, CY, Radius: Double; R, G, B: Double; A: Double = 1.0);
    procedure DrawCircleOutline(CX, CY, Radius, BorderWidth: Double; R, G, B: Double; A: Double = 1.0);
    procedure DrawLine(X1, Y1, X2, Y2, Width: Double; R, G, B: Double; A: Double = 1.0);
    procedure DrawTextLeft(X, Y, W, H: Double; const AText: string; AFont: TFtFont; R, G, B: Double);

    { Image & Bitmap Drawing }
    procedure DrawImage(X, Y: Double; AImage: TFtBitmap; AOpacity: Double = 1.0);
    procedure DrawImageScaled(X, Y, W, H: Double; AImage: TFtBitmap; AOpacity: Double = 1.0);
    procedure DrawImagePart(X, Y, W, H: Double; AImage: TFtBitmap; SrcX, SrcY, SrcW, SrcH: Integer; AOpacity: Double = 1.0);

    { Vector & Path Drawing }
    procedure RenderPath(var APath: path_storage; const AStyle: TSVGStyleRecord; Scale: Double = 1.0);
    procedure RenderPathGradient(var APath: path_storage; const AStyle: TSVGStyleRecord;
      AGradient: TSVGGradientElement; const ABounds: TSVGRect; const AMatrix: TSVGMatrix;
      IsStroke: Boolean = False; Scale: Double = 1.0);
    procedure DrawSVG(X, Y: Double; ADoc: TSVGDocument);
    procedure DrawSVGScaled(X, Y, W, H: Double; ADoc: TSVGDocument);
    procedure DrawSVGFile(X, Y, W, H: Double; const AFileName: string);
    procedure DrawSVGString(X, Y, W, H: Double; const ASVGContent: string);

    { Legacy overloads }
    procedure DrawText(X, Y: Double; const AText: string; ASize: Double; R, G, B: Double);
    procedure DrawTextCentered(X, Y, W, H: Integer; const AText: string; ASize: Double; R, G, B: Double);
  end;

implementation

uses
  Ft.Svg;

constructor TFtCanvasAgg.Create(ABuffer: Pointer; AWidth, AHeight: Integer);
begin
  FBuffer := ABuffer;
  FWidth := AWidth;
  FHeight := AHeight;

  FRenderingBuf.Construct();
  FRenderingBuf.attach(FBuffer, FWidth, FHeight, FWidth * 4);

  pixfmt_bgra32(FPixFormat, @FRenderingBuf);
  FRendererBase.Construct(@FPixFormat);
  FRasterizer.Construct();
  FScanline.Construct();
  FClipStackCount := 0;
  FAlphaStackCount := 0;
  FCurrentAlpha := 1.0;
end;

destructor TFtCanvasAgg.Destroy();
begin
  FScanline.Destruct();
  FRasterizer.Destruct();
  FRenderingBuf.Destruct();
  inherited Destroy();
end;

procedure TFtCanvasAgg.Resize(ABuffer: Pointer; AWidth, AHeight: Integer);
begin
  FBuffer := ABuffer;
  FWidth := AWidth;
  FHeight := AHeight;

  FRenderingBuf.attach(FBuffer, FWidth, FHeight, FWidth * 4);
  pixfmt_bgra32(FPixFormat, @FRenderingBuf);
  FRendererBase.Construct(@FPixFormat);
  FClipStackCount := 0;
  FAlphaStackCount := 0;
  FCurrentAlpha := 1.0;
end;

procedure TFtCanvasAgg.PushClipRect(X, Y, W, H: Integer);
var
  newR: TFtClipRect;
  topR: TFtClipRect;
begin
  if (W <= 0) or (H <= 0) then
  begin
    newR.X1 := 0;
    newR.Y1 := 0;
    newR.X2 := -1;
    newR.Y2 := -1;
  end
  else
  begin
    newR.X1 := X;
    newR.Y1 := Y;
    newR.X2 := X + W - 1;
    newR.Y2 := Y + H - 1;
  end;

  if FClipStackCount > 0 then
  begin
    topR := FClipStack[FClipStackCount - 1];
    if newR.X1 < topR.X1 then newR.X1 := topR.X1;
    if newR.Y1 < topR.Y1 then newR.Y1 := topR.Y1;
    if newR.X2 > topR.X2 then newR.X2 := topR.X2;
    if newR.Y2 > topR.Y2 then newR.Y2 := topR.Y2;
  end;

  if FClipStackCount <= High(FClipStack) then
  begin
    FClipStack[FClipStackCount] := newR;
    Inc(FClipStackCount);
  end;

  if (newR.X2 < newR.X1) or (newR.Y2 < newR.Y1) then
    FRendererBase.clip_box_(0, 0, 0, 0)
  else
    FRendererBase.clip_box_(newR.X1, newR.Y1, newR.X2, newR.Y2);
end;

procedure TFtCanvasAgg.PopClipRect();
var
  topR: TFtClipRect;
begin
  if FClipStackCount > 0 then
    Dec(FClipStackCount);

  if FClipStackCount > 0 then
  begin
    topR := FClipStack[FClipStackCount - 1];
    if (topR.X2 < topR.X1) or (topR.Y2 < topR.Y1) then
      FRendererBase.clip_box_(0, 0, 0, 0)
    else
      FRendererBase.clip_box_(topR.X1, topR.Y1, topR.X2, topR.Y2);
  end
  else
  begin
    FRendererBase.reset_clipping(True);
  end;
end;

procedure TFtCanvasAgg.SetClipRect(X, Y, W, H: Integer);
begin
  PushClipRect(X, Y, W, H);
end;

procedure TFtCanvasAgg.ResetClipRect();
begin
  PopClipRect();
end;

procedure TFtCanvasAgg.ResetAllClipping();
begin
  FClipStackCount := 0;
  FRendererBase.reset_clipping(True);
end;

procedure TFtCanvasAgg.PushAlpha(AAlpha: Double);
begin
  if AAlpha < 0.0 then AAlpha := 0.0;
  if AAlpha > 1.0 then AAlpha := 1.0;
  if FAlphaStackCount <= High(FAlphaStack) then
  begin
    FAlphaStack[FAlphaStackCount] := FCurrentAlpha;
    Inc(FAlphaStackCount);
  end;
  FCurrentAlpha := FCurrentAlpha * AAlpha;
end;

procedure TFtCanvasAgg.PopAlpha();
begin
  if FAlphaStackCount > 0 then
  begin
    Dec(FAlphaStackCount);
    FCurrentAlpha := FAlphaStack[FAlphaStackCount];
  end
  else
    FCurrentAlpha := 1.0;
end;

procedure TFtCanvasAgg.ResetAlpha();
begin
  FAlphaStackCount := 0;
  FCurrentAlpha := 1.0;
end;

function TFtCanvasAgg.GetClipRect(out X, Y, W, H: Integer): Boolean;
var
  cr: TFtClipRect;
begin
  if FClipStackCount > 0 then
  begin
    cr := FClipStack[FClipStackCount - 1];
    X := cr.X1;
    Y := cr.Y1;
    W := cr.X2 - cr.X1 + 1;
    H := cr.Y2 - cr.Y1 + 1;
    Result := True;
  end
  else
  begin
    X := 0;
    Y := 0;
    W := FWidth;
    H := FHeight;
    Result := False;
  end;
end;

function TFtCanvasAgg.IntersectsClip(X, Y, W, H: Integer): Boolean;
var
  cr: TFtClipRect;
begin
  if (W <= 0) or (H <= 0) then Exit(False);
  if FClipStackCount > 0 then
    cr := FClipStack[FClipStackCount - 1]
  else
  begin
    cr.X1 := 0;
    cr.Y1 := 0;
    cr.X2 := FWidth - 1;
    cr.Y2 := FHeight - 1;
  end;

  if (cr.X2 < cr.X1) or (cr.Y2 < cr.Y1) then Exit(False);

  Result := (X <= cr.X2) and (X + W > cr.X1) and
            (Y <= cr.Y2) and (Y + H > cr.Y1);
end;

procedure TFtCanvasAgg.Clear(R, G, B: Double);
var
  C: aggclr;
begin
  C.ConstrDbl(R, G, B);
  FRendererBase.clear(@C);
end;

procedure TFtCanvasAgg.DrawRect(X, Y, W, H: Integer; R, G, B: Double; A: Double = 1.0);
var
  C: aggclr;
  effA: Double;
begin
  effA := A * FCurrentAlpha;
  if (W <= 0) or (H <= 0) or (effA <= 0.0) then Exit;
  C.ConstrDbl(R, G, B, effA);
  FRasterizer.reset();
  FRasterizer.move_to_d(X, Y);
  FRasterizer.line_to_d(X + W, Y);
  FRasterizer.line_to_d(X + W, Y + H);
  FRasterizer.line_to_d(X, Y + H);

  render_scanlines_aa_solid(@FRasterizer, @FScanline, @FRendererBase, @C);
end;

procedure TFtCanvasAgg.DrawRoundedRect(X, Y, W, H: Double; Radius: Double; R, G, B: Double; A: Double = 1.0);
var
  C: aggclr;
  RR: rounded_rect;
  effA: Double;
begin
  if (W <= 0) or (H <= 0) then Exit;
  effA := A * FCurrentAlpha;
  if effA <= 0.0 then Exit;
  C.ConstrDbl(R, G, B, effA);
  if Radius <= 0.5 then
  begin
    FRasterizer.reset();
    FRasterizer.move_to_d(X, Y);
    FRasterizer.line_to_d(X + W, Y);
    FRasterizer.line_to_d(X + W, Y + H);
    FRasterizer.line_to_d(X, Y + H);
    render_scanlines_aa_solid(@FRasterizer, @FScanline, @FRendererBase, @C);
  end
  else
  begin
    RR.Construct(X, Y, X + W, Y + H, Radius);
    RR.normalize_radius();
    FRasterizer.reset();
    FRasterizer.add_path(@RR);
    render_scanlines_aa_solid(@FRasterizer, @FScanline, @FRendererBase, @C);
  end;
end;

procedure TFtCanvasAgg.DrawRoundedRectOutline(X, Y, W, H: Double; Radius: Double; BorderWidth: Double; R, G, B: Double; A: Double = 1.0);
var
  C: aggclr;
  RR: rounded_rect;
  Stroke: conv_stroke;
  halfW, effA: Double;
begin
  if (W <= 0) or (H <= 0) or (BorderWidth <= 0) then Exit;
  effA := A * FCurrentAlpha;
  if effA <= 0.0 then Exit;
  C.ConstrDbl(R, G, B, effA);
  halfW := BorderWidth / 2.0;

  if Radius <= 0.5 then
  begin
    DrawRect(Round(X), Round(Y), Round(W), Round(BorderWidth), R, G, B);
    DrawRect(Round(X), Round(Y + H - BorderWidth), Round(W), Round(BorderWidth), R, G, B);
    DrawRect(Round(X), Round(Y), Round(BorderWidth), Round(H), R, G, B);
    DrawRect(Round(X + W - BorderWidth), Round(Y), Round(BorderWidth), Round(H), R, G, B);
  end
  else
  begin
    RR.Construct(X + halfW, Y + halfW, X + W - halfW, Y + H - halfW, Radius);
    RR.normalize_radius();
    Stroke.Construct(@RR);
    Stroke.width_(BorderWidth);
    FRasterizer.reset();
    FRasterizer.add_path(@Stroke);
    render_scanlines_aa_solid(@FRasterizer, @FScanline, @FRendererBase, @C);
    Stroke.Destruct();
  end;
end;

procedure TFtCanvasAgg.DrawShadow(X, Y, W, H: Double; Radius: Double; OffsetX, OffsetY: Double; BlurRadius: Double; ShadowR, ShadowG, ShadowB, ShadowOpacity: Double);
var
  steps: Integer;
  i: Integer;
  stepAlpha, effOpacity: Double;
  expand: Double;
  C: aggclr;
  RR: rounded_rect;
  curR: Double;
begin
  effOpacity := ShadowOpacity * FCurrentAlpha;
  if (W <= 0) or (H <= 0) or (BlurRadius <= 0) or (effOpacity <= 0) then Exit;
  steps := Round(BlurRadius);
  if steps < 1 then steps := 1;
  if steps > 6 then steps := 6;

  for i := steps downto 1 do
  begin
    expand := i * (BlurRadius / steps);
    curR := Radius + expand;
    stepAlpha := (effOpacity / steps) * (1.0 - (i - 1) / (steps + 1));
    if stepAlpha <= 0 then Continue;

    C.ConstrDbl(ShadowR, ShadowG, ShadowB, stepAlpha);
    RR.Construct(X + OffsetX - expand * 0.5, Y + OffsetY - expand * 0.25,
                 X + OffsetX + W + expand * 0.5, Y + OffsetY + H + expand * 0.75, curR);
    RR.normalize_radius();
    FRasterizer.reset();
    FRasterizer.add_path(@RR);
    render_scanlines_aa_solid(@FRasterizer, @FScanline, @FRendererBase, @C);
  end;
end;

procedure TFtCanvasAgg.BlurRoundedRect(X, Y, W, H: Double; Radius: Double; BlurRadius: Double);
begin
  if (BlurRadius <= 0.0) or (W <= 0) or (H <= 0) or not Assigned(FBuffer) then Exit;
  FtFastBlurRoundedRect(FBuffer, FWidth, FHeight, Round(X), Round(Y), Round(W), Round(H), Radius, BlurRadius);
end;

procedure TFtCanvasAgg.BlurRect(X, Y, W, H: Double; BlurRadius: Double);
begin
  BlurRoundedRect(X, Y, W, H, 0.0, BlurRadius);
end;

procedure TFtCanvasAgg.DrawCheckMark(CX, CY: Double; R, G, B: Double; A: Double = 1.0);
var
  Path: path_storage;
  Stroke: conv_stroke;
  C: aggclr;
  effA: Double;
begin
  effA := A * FCurrentAlpha;
  if effA <= 0.0 then Exit;
  Path.Construct();
  Path.move_to(CX - 4.5, CY + 0.0);
  Path.line_to(CX - 1.5, CY + 3.2);
  Path.line_to(CX + 4.5, CY - 3.8);
  Stroke.Construct(@Path);
  Stroke.width_(1.8);
  Stroke.line_cap_(round_cap);
  Stroke.line_join_(round_join);
  C.ConstrDbl(R, G, B, effA);
  FRasterizer.reset();
  FRasterizer.add_path(@Stroke);
  render_scanlines_aa_solid(@FRasterizer, @FScanline, @FRendererBase, @C);
  Stroke.Destruct();
  Path.Destruct();
end;

procedure TFtCanvasAgg.DrawSubMenuArrow(CX, CY: Double; R, G, B: Double; A: Double = 1.0);
var
  C: aggclr;
  effA: Double;
begin
  effA := A * FCurrentAlpha;
  if effA <= 0.0 then Exit;
  C.ConstrDbl(R, G, B, effA);
  FRasterizer.reset();
  FRasterizer.move_to_d(CX - 2.5, CY - 4.0);
  FRasterizer.line_to_d(CX + 2.5, CY);
  FRasterizer.line_to_d(CX - 2.5, CY + 4.0);
  render_scanlines_aa_solid(@FRasterizer, @FScanline, @FRendererBase, @C);
end;

procedure TFtCanvasAgg.DrawCircle(CX, CY, Radius: Double; R, G, B: Double; A: Double = 1.0);
begin
  DrawRoundedRect(CX - Radius, CY - Radius, Radius * 2.0, Radius * 2.0, Radius, R, G, B, A);
end;

procedure TFtCanvasAgg.DrawCircleOutline(CX, CY, Radius, BorderWidth: Double; R, G, B: Double; A: Double = 1.0);
begin
  DrawRoundedRectOutline(CX - Radius, CY - Radius, Radius * 2.0, Radius * 2.0, Radius, BorderWidth, R, G, B, A);
end;

procedure TFtCanvasAgg.DrawLine(X1, Y1, X2, Y2, Width: Double; R, G, B: Double; A: Double = 1.0);
var
  Path: path_storage;
  Stroke: conv_stroke;
  C: aggclr;
  effA: Double;
begin
  effA := A * FCurrentAlpha;
  if effA <= 0.0 then Exit;
  Path.Construct();
  Path.move_to(X1, Y1);
  Path.line_to(X2, Y2);
  Stroke.Construct(@Path);
  Stroke.width_(Width);
  Stroke.line_cap_(round_cap);
  C.ConstrDbl(R, G, B, effA);
  FRasterizer.reset();
  FRasterizer.add_path(@Stroke);
  render_scanlines_aa_solid(@FRasterizer, @FScanline, @FRendererBase, @C);
  Stroke.Destruct();
  Path.Destruct();
end;

procedure TFtCanvasAgg.DrawTextLeft(X, Y, W, H: Double; const AText: string; AFont: TFtFont; R, G, B: Double);
var
  actualFont: TFtFont;
  ty: Double;
begin
  if AText = '' then Exit;
  if not Assigned(AFont) then actualFont := FtGetSystemFont() else actualFont := AFont;
  ty := Y + (H / 2.0) + (actualFont.Ascent - actualFont.Descent) / 2.0;
  DrawText(X, ty, AText, actualFont, R, G, B);
end;

procedure TFtCanvasAgg.DrawTextHershey(X, Y: Double; const AText: string; ASize: Double; R, G, B: Double);
var
  C: aggclr;
  T: gsv_text;
  ST: conv_stroke;
begin
  if AText = '' then Exit;
  T.Construct();
  T.size_(ASize);
  T.flip_(True);
  ST.Construct(@T);
  ST.width_(1.5);
  T.start_point_(X, Y);
  T.text_(PChar(AText));

  C.ConstrDbl(R, G, B);
  FRasterizer.reset();
  FRasterizer.add_path(@ST);
  render_scanlines_aa_solid(@FRasterizer, @FScanline, @FRendererBase, @C);
  ST.Destruct();
  T.Destruct();
end;

procedure TFtCanvasAgg.DrawTextCenteredHershey(X, Y, W, H: Integer; const AText: string; ASize: Double; R, G, B: Double);
var
  C: aggclr;
  T: gsv_text;
  ST: conv_stroke;
  BX1, BY1, BX2, BY2: Double;
  TW, TH, TX, TY: Double;
begin
  if AText = '' then Exit;
  T.Construct();
  T.size_(ASize);
  T.flip_(True);
  ST.Construct(@T);
  ST.width_(1.5);
  T.start_point_(0, 0);
  T.text_(PChar(AText));

  if bounding_rect_single(@ST, 0, @BX1, @BY1, @BX2, @BY2) then
  begin
    TW := BX2 - BX1;
    TH := BY2 - BY1;
    TX := X + (W - TW) / 2.0 - BX1;
    TY := Y + (H + TH) / 2.0;
    T.start_point_(TX, TY);
  end
  else
    T.start_point_(X + 10, Y + H / 2.0);

  C.ConstrDbl(R, G, B, FCurrentAlpha);
  FRasterizer.reset();
  FRasterizer.add_path(@ST);
  render_scanlines_aa_solid(@FRasterizer, @FScanline, @FRendererBase, @C);
  ST.Destruct();
  T.Destruct();
end;

procedure TFtCanvasAgg.DrawText(X, Y: Double; const AText: string; AFont: TFtFont; R, G, B: Double);
var
  renSolid: renderer_scanline_aa_solid;
  C: aggclr;
  str_: PChar;
  charLen: LongInt;
  charId: Cardinal;
  glyph: glyph_cache_ptr;
  curX, curY: Double;
  first: Boolean;
  cm, curCM: font_cache_manager_ptr;
  fb: TFtFont;
begin
  if (AText = '') or (FCurrentAlpha <= 0.0) then Exit;
  if not Assigned(AFont) then AFont := FtGetSystemFont();

  if not AFont.Loaded then
  begin
    DrawTextHershey(X, Y, AText, AFont.Size, R, G, B);
    Exit;
  end;

  cm := AFont.CacheManagerPtr();
  C.ConstrDbl(R, G, B, FCurrentAlpha);
  renSolid.Construct(@FRendererBase);
  renSolid.color_(@C);

  curX := X;
  curY := Y;
  str_ := PChar(AText);
  first := True;

  while str_^ <> #0 do
  begin
    charId := UTF8CharToUnicode(str_, charLen);
    Inc(str_, charLen);

    glyph := cm^.glyph(charId);
    curCM := cm;
    if (glyph = nil) or (glyph^.glyph_index = 0) then
    begin
      fb := AFont.FallbackFont;
      if Assigned(fb) and fb.Loaded and (fb <> AFont) then
      begin
        glyph := fb.CacheManagerPtr()^.glyph(charId);
        if (glyph <> nil) and (glyph^.glyph_index <> 0) then
          curCM := fb.CacheManagerPtr();
      end;
    end;

    if glyph <> nil then
    begin
      if not first then
        curCM^.add_kerning(@curX, @curY);
      first := False;

      curCM^.init_embedded_adaptors(glyph, curX, curY);
      if glyph^.data_type = glyph_data_gray8 then
        render_scanlines(curCM^.gray8_adaptor, curCM^.gray8_scanline, @renSolid);

      curX := curX + glyph^.advance_x;
      curY := curY + glyph^.advance_y;
    end;
  end;
end;

procedure TFtCanvasAgg.DrawTextCentered(X, Y, W, H: Integer; const AText: string; AFont: TFtFont; R, G, B: Double);
var
  TW, TX, TY: Double;
begin
  if AText = '' then Exit;
  if not Assigned(AFont) then AFont := FtGetSystemFont();

  if not AFont.Loaded then
  begin
    DrawTextCenteredHershey(X, Y, W, H, AText, AFont.Size, R, G, B);
    Exit;
  end;

  TW := AFont.GetTextWidth(AText);
  TX := X + (W - TW) / 2.0;
  TY := Y + (H / 2.0) + (AFont.Ascent - AFont.Descent) / 2.0;

  DrawText(TX, TY, AText, AFont, R, G, B);
end;

procedure TFtCanvasAgg.DrawText(X, Y: Double; const AText: string; ASize: Double; R, G, B: Double);
var
  F: TFtFont;
begin
  F := FtGetSystemFont();
  if Assigned(F) and (Abs(F.Size - ASize) > 0.5) then
    F := FtFontManager().GetFont(Format('%s-%.1f', [F.FamilyName, ASize]));
  DrawText(X, Y, AText, F, R, G, B);
end;

procedure TFtCanvasAgg.DrawTextCentered(X, Y, W, H: Integer; const AText: string; ASize: Double; R, G, B: Double);
var
  F: TFtFont;
begin
  F := FtGetSystemFont();
  if Assigned(F) and (Abs(F.Size - ASize) > 0.5) then
    F := FtFontManager().GetFont(Format('%s-%.1f', [F.FamilyName, ASize]));
  DrawTextCentered(X, Y, W, H, AText, F, R, G, B);
end;

procedure TFtCanvasAgg.DrawImage(X, Y: Double; AImage: TFtBitmap; AOpacity: Double = 1.0);
var
  cover: int8u;
  dstX, dstY: Integer;
  effOpacity: Double;
begin
  if not Assigned(AImage) or (AImage.Width <= 0) or (AImage.Height <= 0) or (AImage.PixelBuffer = nil) then Exit;
  effOpacity := AOpacity * FCurrentAlpha;
  if effOpacity <= 0.0 then Exit;

  dstX := Round(X);
  dstY := Round(Y);

  if effOpacity >= 1.0 then
    cover := 255
  else
    cover := Round(effOpacity * 255.0);

  FRendererBase.blend_from(AImage.PixFormatPtr, nil, dstX, dstY, cover);
end;

procedure TFtCanvasAgg.DrawImagePart(X, Y, W, H: Double; AImage: TFtBitmap; SrcX, SrcY, SrcW, SrcH: Integer; AOpacity: Double = 1.0);
var
  dstX, dstY, dstW, dstH: Integer;
  clip: rect_ptr;
  minX, maxX, minY, maxY: Integer;
  dx, dy: Integer;
  stepX_fp, stepY_fp: Int64;
  curSrcY_fp, curSrcX_fp: Int64;
  sx, sy: Integer;
  fx, fy, invFx, invFy: Integer;
  srcStride, dstStride: Integer;
  srcPixels, dstPixels, dstRow: PByte;
  p00, p10, p01, p11: PByte;
  b, g, r, a: Integer;
  invA, dstB, dstG, dstR, dstA, finalA: Integer;
  globalAlpha: Integer;
  srcX0_fp, srcY0_fp: Int64;
  effOpacity: Double;
begin
  if not Assigned(AImage) or (AImage.Width <= 0) or (AImage.Height <= 0) or (AImage.PixelBuffer = nil) then Exit;
  effOpacity := AOpacity * FCurrentAlpha;
  if (W <= 0) or (H <= 0) or (SrcW <= 0) or (SrcH <= 0) or (effOpacity <= 0.0) then Exit;

  dstX := Round(X);
  dstY := Round(Y);
  dstW := Round(W);
  dstH := Round(H);

  if (dstW <= 0) or (dstH <= 0) then Exit;

  // Clip destination to active clip rect
  clip := FRendererBase._clip_box;
  minX := dstX;
  if minX < clip^.x1 then minX := clip^.x1;
  if minX < 0 then minX := 0;

  maxX := dstX + dstW - 1;
  if maxX > clip^.x2 then maxX := clip^.x2;
  if maxX >= FWidth then maxX := FWidth - 1;

  minY := dstY;
  if minY < clip^.y1 then minY := clip^.y1;
  if minY < 0 then minY := 0;

  maxY := dstY + dstH - 1;
  if maxY > clip^.y2 then maxY := clip^.y2;
  if maxY >= FHeight then maxY := FHeight - 1;

  if (minX > maxX) or (minY > maxY) then Exit;

  if effOpacity >= 1.0 then
    globalAlpha := 255
  else
    globalAlpha := Round(effOpacity * 255.0);

  stepX_fp := (Int64(SrcW) shl 16) div dstW;
  stepY_fp := (Int64(SrcH) shl 16) div dstH;
  srcX0_fp := Int64(SrcX) shl 16;
  srcY0_fp := Int64(SrcY) shl 16;

  srcStride := AImage.Stride;
  dstStride := FWidth * 4;
  srcPixels := PByte(AImage.PixelBuffer);
  dstPixels := PByte(FBuffer);

  for dy := minY to maxY do
  begin
    curSrcY_fp := srcY0_fp + Int64(dy - dstY) * stepY_fp;
    sy := curSrcY_fp shr 16;
    fy := (curSrcY_fp shr 8) and $FF;
    invFy := 255 - fy;

    if sy < 0 then sy := 0;
    if sy >= AImage.Height - 1 then sy := AImage.Height - 2;
    if sy < 0 then sy := 0;

    dstRow := dstPixels + dy * dstStride + minX * 4;

    for dx := minX to maxX do
    begin
      curSrcX_fp := srcX0_fp + Int64(dx - dstX) * stepX_fp;
      sx := curSrcX_fp shr 16;
      fx := (curSrcX_fp shr 8) and $FF;
      invFx := 255 - fx;

      if sx < 0 then sx := 0;
      if sx >= AImage.Width - 1 then sx := AImage.Width - 2;
      if sx < 0 then sx := 0;

      p00 := srcPixels + sy * srcStride + sx * 4;
      p10 := p00 + 4;
      p01 := p00 + srcStride;
      p11 := p01 + 4;

      b := (p00[0] * invFx * invFy + p10[0] * fx * invFy + p01[0] * invFx * fy + p11[0] * fx * fy) shr 16;
      g := (p00[1] * invFx * invFy + p10[1] * fx * invFy + p01[1] * invFx * fy + p11[1] * fx * fy) shr 16;
      r := (p00[2] * invFx * invFy + p10[2] * fx * invFy + p01[2] * invFx * fy + p11[2] * fx * fy) shr 16;
      a := (p00[3] * invFx * invFy + p10[3] * fx * invFy + p01[3] * invFx * fy + p11[3] * fx * fy) shr 16;

      if globalAlpha < 255 then
        a := (a * globalAlpha) shr 8;

      if a > 0 then
      begin
        if a >= 255 then
        begin
          dstRow[0] := b;
          dstRow[1] := g;
          dstRow[2] := r;
          dstRow[3] := 255;
        end
        else
        begin
          invA := 255 - a;
          dstB := dstRow[0];
          dstG := dstRow[1];
          dstR := dstRow[2];
          dstA := dstRow[3];

          dstRow[0] := (b * a + dstB * invA) shr 8;
          dstRow[1] := (g * a + dstG * invA) shr 8;
          dstRow[2] := (r * a + dstR * invA) shr 8;
          finalA := a + ((dstA * invA) shr 8);
          if finalA > 255 then finalA := 255;
          dstRow[3] := finalA;
        end;
      end;

      Inc(dstRow, 4);
    end;
  end;
end;

procedure TFtCanvasAgg.DrawImageScaled(X, Y, W, H: Double; AImage: TFtBitmap; AOpacity: Double = 1.0);
begin
  if not Assigned(AImage) then Exit;
  if (Round(W) = AImage.Width) and (Round(H) = AImage.Height) then
    DrawImage(X, Y, AImage, AOpacity)
  else
    DrawImagePart(X, Y, W, H, AImage, 0, 0, AImage.Width, AImage.Height, AOpacity);
end;

procedure TFtCanvasAgg.RenderPath(var APath: path_storage; const AStyle: TSVGStyleRecord; Scale: Double = 1.0);
var
  curved: conv_curve;
  stroke: conv_stroke;
  c: aggclr;
  effA: Double;
  miterLim: Double;
begin
  if APath.total_vertices() = 0 then Exit;

  curved.Construct(@APath);
  try
    // 1. Fill pass
    if (AStyle.Fill.Kind <> pkNone) and (AStyle.FillOpacity > 0.0) then
    begin
      effA := AStyle.FillOpacity * FCurrentAlpha;
      if effA > 0.0 then
      begin
        c.ConstrDbl(AStyle.Fill.Color.R / 255.0, AStyle.Fill.Color.G / 255.0, AStyle.Fill.Color.B / 255.0, effA);
        FRasterizer.reset();
        if AStyle.FillRule = sfrEvenOdd then
          FRasterizer.filling_rule(fill_even_odd)
        else
          FRasterizer.filling_rule(fill_non_zero);
        FRasterizer.add_path(@curved);
        render_scanlines_aa_solid(@FRasterizer, @FScanline, @FRendererBase, @c);
      end;
    end;

    // 2. Stroke pass
    if (AStyle.Stroke.Kind <> pkNone) and (AStyle.StrokeWidth > 0.0) and (AStyle.StrokeOpacity > 0.0) then
    begin
      effA := AStyle.StrokeOpacity * FCurrentAlpha;
      if effA > 0.0 then
      begin
        c.ConstrDbl(AStyle.Stroke.Color.R / 255.0, AStyle.Stroke.Color.G / 255.0, AStyle.Stroke.Color.B / 255.0, effA);
        stroke.Construct(@curved);
        try
          stroke.width_(AStyle.StrokeWidth * Scale);

          case AStyle.StrokeLineCap of
            slcRound: stroke.line_cap_(round_cap);
            slcSquare: stroke.line_cap_(square_cap);
            else stroke.line_cap_(butt_cap);
          end;

          case AStyle.StrokeLineJoin of
            sljRound: stroke.line_join_(round_join);
            sljBevel: stroke.line_join_(bevel_join);
            else stroke.line_join_(miter_join);
          end;

          miterLim := AStyle.StrokeMiterLimit;
          if miterLim <= 0.0 then miterLim := 4.0;
          stroke.miter_limit_(miterLim);

          FRasterizer.reset();
          FRasterizer.filling_rule(fill_non_zero);
          FRasterizer.add_path(@stroke);
          render_scanlines_aa_solid(@FRasterizer, @FScanline, @FRendererBase, @c);
        finally
          stroke.Destruct();
        end;
      end;
    end;
  finally
    curved.Destruct();
  end;
end;

procedure TFtCanvasAgg.RenderPathGradient(var APath: path_storage; const AStyle: TSVGStyleRecord;
  AGradient: TSVGGradientElement; const ABounds: TSVGRect; const AMatrix: TSVGMatrix;
  IsStroke: Boolean = False; Scale: Double = 1.0);
var
  effStops: TObjectList;
  effAlpha, stopA, off, lastOffset: Double;
  i: Integer;
  stop: TSVGStopElement;
  c: aggclr;
  glut: gradient_lut;
  alloc: span_allocator;
  inter: span_interpolator_linear;
  span: span_gradient;
  ren: renderer_scanline_aa;
  curved: conv_curve;
  stroke: conv_stroke;
  gradM: trans_affine;
  tar: trans_affine_rotation;
  tat: trans_affine_translation;
  gradTrans: trans_affine;
  elemTrans: trans_affine;
  repAdaptor: gradient_repeat_adaptor;
  refAdaptor: gradient_reflect_adaptor;
  activeGradPtr: gradient_ptr;
  linGradFunc: gradient_x;
  radGradFunc: gradient_radial;
  focusGradFunc: gradient_radial_focus;
  linElem: TSVGLinearGradientElement;
  radElem: TSVGRadialGradientElement;
  units: TSVGGradientUnits;
  spread: TSVGGradientSpread;
  x1, y1, x2, y2, dx, dy, len, angle: Double;
  cx, cy, r, fx, fy, diag: Double;
  d1, d2: Double;
  miterLim: Double;
  bboxW, bboxH: Double;
begin
  if (APath.total_vertices() = 0) or not Assigned(AGradient) then Exit;

  effStops := AGradient.GetEffectiveStops();
  if not Assigned(effStops) or (effStops.Count = 0) then Exit;

  if IsStroke then
    effAlpha := AStyle.StrokeOpacity * FCurrentAlpha
  else
    effAlpha := AStyle.FillOpacity * FCurrentAlpha;

  if effAlpha <= 0.0 then Exit;

  bboxW := ABounds.Width;
  if bboxW < 0.0001 then bboxW := 1.0;
  bboxH := ABounds.Height;
  if bboxH < 0.0001 then bboxH := 1.0;

  glut.Construct(256);
  try
    glut.remove_all();
    if effStops.Count = 1 then
    begin
      stop := TSVGStopElement(effStops[0]);
      stopA := (stop.Color.A / 255.0) * effAlpha;
      c.ConstrDbl(stop.Color.R / 255.0, stop.Color.G / 255.0, stop.Color.B / 255.0, stopA);
      glut.add_color(0.0, @c);
      glut.add_color(1.0, @c);
    end
    else
    begin
      lastOffset := -1.0;
      for i := 0 to effStops.Count - 1 do
      begin
        stop := TSVGStopElement(effStops[i]);
        stopA := (stop.Color.A / 255.0) * effAlpha;
        c.ConstrDbl(stop.Color.R / 255.0, stop.Color.G / 255.0, stop.Color.B / 255.0, stopA);
        off := stop.Offset;
        if off < 0.0 then off := 0.0;
        if off > 1.0 then off := 1.0;
        if off <= lastOffset then
          off := lastOffset + 0.00001;
        if off > 1.0 then off := 1.0;
        lastOffset := off;
        glut.add_color(off, @c);
      end;
    end;
    glut.build_lut();

    if AGradient is TSVGLinearGradientElement then
    begin
      linElem := TSVGLinearGradientElement(AGradient);
      units := linElem.GradientUnits;
      spread := linElem.SpreadMethod;

      if units = sguObjectBoundingBox then
      begin
        if linElem.X1.UnitType = suPercent then x1 := ABounds.X + (linElem.X1.Value * 0.01) * bboxW
        else x1 := ABounds.X + linElem.X1.Value * bboxW;

        if linElem.Y1.UnitType = suPercent then y1 := ABounds.Y + (linElem.Y1.Value * 0.01) * bboxH
        else y1 := ABounds.Y + linElem.Y1.Value * bboxH;

        if linElem.X2.UnitType = suPercent then x2 := ABounds.X + (linElem.X2.Value * 0.01) * bboxW
        else x2 := ABounds.X + linElem.X2.Value * bboxW;

        if linElem.Y2.UnitType = suPercent then y2 := ABounds.Y + (linElem.Y2.Value * 0.01) * bboxH
        else y2 := ABounds.Y + linElem.Y2.Value * bboxH;
      end
      else
      begin
        x1 := SVGLengthToPixels(linElem.X1);
        y1 := SVGLengthToPixels(linElem.Y1);
        x2 := SVGLengthToPixels(linElem.X2);
        y2 := SVGLengthToPixels(linElem.Y2);
      end;

      dx := x2 - x1;
      dy := y2 - y1;
      len := Sqrt(dx * dx + dy * dy);
      if len < 0.0001 then len := 0.0001;
      angle := ArcTan2(dy, dx);

      tar.Construct(angle);
      tat.Construct(x1, y1);
      gradTrans.Construct(AGradient.GradientTransform.A, AGradient.GradientTransform.B,
                          AGradient.GradientTransform.C, AGradient.GradientTransform.D,
                          AGradient.GradientTransform.E, AGradient.GradientTransform.F);
      elemTrans.Construct(AMatrix.A, AMatrix.B, AMatrix.C, AMatrix.D, AMatrix.E, AMatrix.F);
      gradM.Construct;
      gradM.multiply(@tar);
      gradM.multiply(@tat);
      gradM.multiply(@gradTrans);
      gradM.multiply(@elemTrans);
      gradM.invert;

      linGradFunc.Construct();
      activeGradPtr := @linGradFunc;
      if spread = sgsRepeat then
      begin
        repAdaptor.Construct(activeGradPtr);
        activeGradPtr := @repAdaptor;
      end
      else if spread = sgsReflect then
      begin
        refAdaptor.Construct(activeGradPtr);
        activeGradPtr := @refAdaptor;
      end;

      d1 := 0.0;
      d2 := len;
    end
    else if AGradient is TSVGRadialGradientElement then
    begin
      radElem := TSVGRadialGradientElement(AGradient);
      units := radElem.GradientUnits;
      spread := radElem.SpreadMethod;

      if units = sguObjectBoundingBox then
      begin
        if radElem.Cx.UnitType = suPercent then cx := ABounds.X + (radElem.Cx.Value * 0.01) * bboxW
        else cx := ABounds.X + radElem.Cx.Value * bboxW;

        if radElem.Cy.UnitType = suPercent then cy := ABounds.Y + (radElem.Cy.Value * 0.01) * bboxH
        else cy := ABounds.Y + radElem.Cy.Value * bboxH;

        diag := Sqrt((bboxW * bboxW + bboxH * bboxH) * 0.5);
        if radElem.R.UnitType = suPercent then r := (radElem.R.Value * 0.01) * diag
        else r := radElem.R.Value * diag;

        if radElem.Fx.UnitType = suPercent then fx := ABounds.X + (radElem.Fx.Value * 0.01) * bboxW
        else fx := ABounds.X + radElem.Fx.Value * bboxW;

        if radElem.Fy.UnitType = suPercent then fy := ABounds.Y + (radElem.Fy.Value * 0.01) * bboxH
        else fy := ABounds.Y + radElem.Fy.Value * bboxH;
      end
      else
      begin
        cx := SVGLengthToPixels(radElem.Cx);
        cy := SVGLengthToPixels(radElem.Cy);
        r  := SVGLengthToPixels(radElem.R);
        fx := SVGLengthToPixels(radElem.Fx);
        fy := SVGLengthToPixels(radElem.Fy);
      end;

      if r < 0.0001 then r := 0.0001;

      tat.Construct(cx, cy);
      gradTrans.Construct(AGradient.GradientTransform.A, AGradient.GradientTransform.B,
                          AGradient.GradientTransform.C, AGradient.GradientTransform.D,
                          AGradient.GradientTransform.E, AGradient.GradientTransform.F);
      elemTrans.Construct(AMatrix.A, AMatrix.B, AMatrix.C, AMatrix.D, AMatrix.E, AMatrix.F);

      gradM.Construct;
      gradM.multiply(@tat);
      gradM.multiply(@gradTrans);
      gradM.multiply(@elemTrans);
      gradM.invert;

      if (Abs(fx - cx) < 0.001) and (Abs(fy - cy) < 0.001) then
      begin
        radGradFunc.Construct();
        activeGradPtr := @radGradFunc;
      end
      else
      begin
        focusGradFunc.Construct(r, fx - cx, fy - cy);
        activeGradPtr := @focusGradFunc;
      end;

      if spread = sgsRepeat then
      begin
        repAdaptor.Construct(activeGradPtr);
        activeGradPtr := @repAdaptor;
      end
      else if spread = sgsReflect then
      begin
        refAdaptor.Construct(activeGradPtr);
        activeGradPtr := @refAdaptor;
      end;

      d1 := 0.0;
      d2 := r;
    end
    else
      Exit;

    alloc.Construct();
    try
      inter.Construct(@gradM);
      span.Construct(@alloc, @inter, activeGradPtr, @glut, d1, d2);
      ren.Construct(@FRendererBase, @span);

      curved.Construct(@APath);
      try
        FRasterizer.reset();
        if IsStroke then
        begin
          stroke.Construct(@curved);
          try
            stroke.width_(AStyle.StrokeWidth * Scale);
            case AStyle.StrokeLineCap of
              slcRound: stroke.line_cap_(round_cap);
              slcSquare: stroke.line_cap_(square_cap);
              else stroke.line_cap_(butt_cap);
            end;
            case AStyle.StrokeLineJoin of
              sljRound: stroke.line_join_(round_join);
              sljBevel: stroke.line_join_(bevel_join);
              else stroke.line_join_(miter_join);
            end;
            miterLim := AStyle.StrokeMiterLimit;
            if miterLim <= 0.0 then miterLim := 4.0;
            stroke.miter_limit_(miterLim);

            FRasterizer.filling_rule(fill_non_zero);
            FRasterizer.add_path(@stroke);
            render_scanlines(@FRasterizer, @FScanline, @ren);
          finally
            stroke.Destruct();
          end;
        end
        else
        begin
          if AStyle.FillRule = sfrEvenOdd then
            FRasterizer.filling_rule(fill_even_odd)
          else
            FRasterizer.filling_rule(fill_non_zero);
          FRasterizer.add_path(@curved);
          render_scanlines(@FRasterizer, @FScanline, @ren);
        end;
      finally
        curved.Destruct();
      end;
    finally
      alloc.Destruct();
    end;
  finally
    glut.Destruct();
  end;
end;

procedure TFtCanvasAgg.DrawSVG(X, Y: Double; ADoc: TSVGDocument);
begin
  TFtSVGRenderer.Render(Self, ADoc, X, Y);
end;

procedure TFtCanvasAgg.DrawSVGScaled(X, Y, W, H: Double; ADoc: TSVGDocument);
begin
  TFtSVGRenderer.Render(Self, ADoc, X, Y, W, H);
end;

procedure TFtCanvasAgg.DrawSVGFile(X, Y, W, H: Double; const AFileName: string);
begin
  TFtSVGRenderer.RenderFile(Self, AFileName, X, Y, W, H);
end;

procedure TFtCanvasAgg.DrawSVGString(X, Y, W, H: Double; const ASVGContent: string);
begin
  TFtSVGRenderer.RenderString(Self, ASVGContent, X, Y, W, H);
end;

end.
