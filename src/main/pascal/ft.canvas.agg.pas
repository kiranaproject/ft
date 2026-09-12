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
  agg_bounding_rect,
  agg_rounded_rect,
  Ft.Font;

type
  TFtCanvasAgg = class
  private
    FBuffer: Pointer;
    FWidth, FHeight: Integer;
    FRenderingBuf: rendering_buffer;
    FPixFormat: pixel_formats;
    FRendererBase: renderer_base;
    FRasterizer: rasterizer_scanline_aa;
    FScanline: scanline_u8;
    procedure DrawTextHershey(X, Y: Double; const AText: string; ASize: Double; R, G, B: Double);
    procedure DrawTextCenteredHershey(X, Y, W, H: Integer; const AText: string; ASize: Double; R, G, B: Double);
  public
    constructor Create(ABuffer: Pointer; AWidth, AHeight: Integer);
    destructor Destroy(); override;
    procedure Resize(ABuffer: Pointer; AWidth, AHeight: Integer);
    procedure Clear(R, G, B: Double);
    procedure DrawRect(X, Y, W, H: Integer; R, G, B: Double);
    procedure DrawRoundedRect(X, Y, W, H: Double; Radius: Double; R, G, B: Double; A: Double = 1.0);
    procedure DrawRoundedRectOutline(X, Y, W, H: Double; Radius: Double; BorderWidth: Double; R, G, B: Double; A: Double = 1.0);
    procedure DrawShadow(X, Y, W, H: Double; Radius: Double; OffsetX, OffsetY: Double; BlurRadius: Double; ShadowR, ShadowG, ShadowB, ShadowOpacity: Double);

    procedure DrawText(X, Y: Double; const AText: string; AFont: TFtFont; R, G, B: Double);
    procedure DrawTextCentered(X, Y, W, H: Integer; const AText: string; AFont: TFtFont; R, G, B: Double);

    { Legacy overloads }
    procedure DrawText(X, Y: Double; const AText: string; ASize: Double; R, G, B: Double);
    procedure DrawTextCentered(X, Y, W, H: Integer; const AText: string; ASize: Double; R, G, B: Double);
  end;

implementation

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
end;

procedure TFtCanvasAgg.Clear(R, G, B: Double);
var
  C: aggclr;
begin
  C.ConstrDbl(R, G, B);
  FRendererBase.clear(@C);
end;

procedure TFtCanvasAgg.DrawRect(X, Y, W, H: Integer; R, G, B: Double);
var
  C: aggclr;
begin
  C.ConstrDbl(R, G, B);
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
begin
  if (W <= 0) or (H <= 0) then Exit;
  C.ConstrDbl(R, G, B, A);
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
  halfW: Double;
begin
  if (W <= 0) or (H <= 0) or (BorderWidth <= 0) then Exit;
  C.ConstrDbl(R, G, B, A);
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
  stepAlpha: Double;
  expand: Double;
  C: aggclr;
  RR: rounded_rect;
  curR: Double;
begin
  if (W <= 0) or (H <= 0) or (BlurRadius <= 0) or (ShadowOpacity <= 0) then Exit;
  steps := Round(BlurRadius);
  if steps < 1 then steps := 1;
  if steps > 6 then steps := 6;

  for i := steps downto 1 do
  begin
    expand := i * (BlurRadius / steps);
    curR := Radius + expand;
    stepAlpha := (ShadowOpacity / steps) * (1.0 - (i - 1) / (steps + 1));
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

  C.ConstrDbl(R, G, B);
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
  if AText = '' then Exit;
  if not Assigned(AFont) then AFont := FtGetSystemFont();

  if not AFont.Loaded then
  begin
    DrawTextHershey(X, Y, AText, AFont.Size, R, G, B);
    Exit;
  end;

  cm := AFont.CacheManagerPtr();
  C.ConstrDbl(R, G, B);
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

end.
