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
  agg_path_storage,
  agg_math_stroke,
  Ft.Font;

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
    procedure PushClipRect(X, Y, W, H: Integer);
    procedure PopClipRect();
    procedure SetClipRect(X, Y, W, H: Integer);
    procedure ResetClipRect();
    procedure ResetAllClipping();

    procedure DrawText(X, Y: Double; const AText: string; AFont: TFtFont; R, G, B: Double);
    procedure DrawTextCentered(X, Y, W, H: Integer; const AText: string; AFont: TFtFont; R, G, B: Double);

    procedure DrawCheckMark(CX, CY: Double; R, G, B: Double; A: Double = 1.0);
    procedure DrawSubMenuArrow(CX, CY: Double; R, G, B: Double; A: Double = 1.0);

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
  FClipStackCount := 0;
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

procedure TFtCanvasAgg.DrawCheckMark(CX, CY: Double; R, G, B: Double; A: Double = 1.0);
var
  Path: path_storage;
  Stroke: conv_stroke;
  C: aggclr;
begin
  Path.Construct();
  Path.move_to(CX - 4.5, CY + 0.0);
  Path.line_to(CX - 1.5, CY + 3.2);
  Path.line_to(CX + 4.5, CY - 3.8);
  Stroke.Construct(@Path);
  Stroke.width_(1.8);
  Stroke.line_cap_(round_cap);
  Stroke.line_join_(round_join);
  C.ConstrDbl(R, G, B, A);
  FRasterizer.reset();
  FRasterizer.add_path(@Stroke);
  render_scanlines_aa_solid(@FRasterizer, @FScanline, @FRendererBase, @C);
  Stroke.Destruct();
  Path.Destruct();
end;

procedure TFtCanvasAgg.DrawSubMenuArrow(CX, CY: Double; R, G, B: Double; A: Double = 1.0);
var
  C: aggclr;
begin
  C.ConstrDbl(R, G, B, A);
  FRasterizer.reset();
  FRasterizer.move_to_d(CX - 2.5, CY - 4.0);
  FRasterizer.line_to_d(CX + 2.5, CY);
  FRasterizer.line_to_d(CX - 2.5, CY + 4.0);
  render_scanlines_aa_solid(@FRasterizer, @FScanline, @FRendererBase, @C);
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
