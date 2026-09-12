unit Ft.Canvas.Agg;

{$mode objfpc}{$H+}

interface

uses
  agg_basics,
  agg_color,
  agg_rendering_buffer,
  agg_pixfmt,
  agg_pixfmt_rgb,
  agg_renderer_base,
  agg_renderer_scanline,
  agg_rasterizer_scanline_aa,
  agg_scanline_u;

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
  public
    constructor Create(ABuffer: Pointer; AWidth, AHeight: Integer);
    destructor Destroy; override;
    procedure Clear(R, G, B: Double);
    procedure DrawRect(X, Y, W, H: Integer; R, G, B: Double);
  end;

implementation

constructor TFtCanvasAgg.Create(ABuffer: Pointer; AWidth, AHeight: Integer);
begin
  FBuffer := ABuffer;
  FWidth := AWidth;
  FHeight := AHeight;

  FRenderingBuf.Construct;
  FRenderingBuf.attach(FBuffer, FWidth, FHeight, FWidth * 3);

  pixfmt_bgr24_pre(FPixFormat, @FRenderingBuf);
  FRendererBase.Construct(@FPixFormat);
  FRasterizer.Construct;
  FScanline.Construct;
end;

destructor TFtCanvasAgg.Destroy;
begin
  FScanline.Destruct;
  FRasterizer.Destruct;
  FRenderingBuf.Destruct;
  inherited Destroy;
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
  FRasterizer.reset;
  FRasterizer.move_to(X, Y);
  FRasterizer.line_to(X + W, Y);
  FRasterizer.line_to(X + W, Y + H);
  FRasterizer.line_to(X, Y + H);

  render_scanlines_aa_solid(@FRasterizer, @FScanline, @FRendererBase, @C);
end;

end.
