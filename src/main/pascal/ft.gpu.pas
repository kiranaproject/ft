unit Ft.Gpu;

{$mode objfpc}{$H+}

interface

uses
  ctypes, SysUtils, Types, Math,
  Floria.Image.Core,
  Floria.Colorspace,
  Floria.Canvas.Blend,
  Floria.Path.Clipper.Core,
  Floria.Path.Ops,
  Floria.DisplayList,
  Floria.DisplayList.Clip,
  Floria.GL,
  Floria.GPU.Context,
  Floria.GPU.Batch,
  Floria.GPU.Tessellator,
  Floria.GPU.Shaders,
  Floria.GPU.Renderer;

type
  TFtPoint2D = record
    X, Y: Single;
  end;
  PFtPoint2D = ^TFtPoint2D;

  TFtBatchStats = record
    DrawCalls  : Cardinal;
    VertexCount: Cardinal;
  end;
  PFtBatchStats = ^TFtBatchStats;

  PFtTessMesh = ^TFloriaTessMesh;

// --- Global GPU Status ---
function ft_gpu_is_available(): cint32; cdecl;

// --- Render Batch C API ---
function ft_batch_create(): Pointer; cdecl;
procedure ft_batch_destroy(batch: Pointer); cdecl;
procedure ft_batch_clear(batch: Pointer); cdecl;
procedure ft_batch_get_stats(batch: Pointer; stats: PFtBatchStats); cdecl;
procedure ft_batch_emit_rect(batch: Pointer; x, y, w, h: Single; color: Cardinal; blend_mode: cint32); cdecl;
procedure ft_batch_emit_textured_rect(batch: Pointer; x, y, w, h, u0, v0, u1, v1: Single;
                                     tex_id: Cardinal; opacity: Single; blend_mode: cint32); cdecl;
procedure ft_batch_emit_rounded_rect(batch: Pointer; x, y, w, h, radius: Single;
                                     fill_color, border_color: Cardinal; border_width: Single;
                                     blend_mode: cint32); cdecl;
procedure ft_batch_emit_box_shadow(batch: Pointer; x, y, w, h, radius, offset_x, offset_y,
                                   blur_radius, spread: Single; shadow_color: Cardinal;
                                   blend_mode: cint32); cdecl;
procedure ft_batch_emit_linear_gradient(batch: Pointer; x, y, w, h: Single;
                                        color_start, color_end: Cardinal; angle_deg: Single;
                                        blend_mode: cint32); cdecl;
procedure ft_batch_emit_path_mesh(batch: Pointer; mesh: Pointer; color: Cardinal; blend_mode: cint32); cdecl;

// --- Tessellator & Vector Geometry C API ---
function ft_tessmesh_create(): Pointer; cdecl;
procedure ft_tessmesh_destroy(mesh: Pointer); cdecl;
procedure ft_tessmesh_clear(mesh: Pointer); cdecl;
procedure ft_tessmesh_get_counts(mesh: Pointer; out vertex_count, index_count: cint32); cdecl;

function ft_tessellator_create(): Pointer; cdecl;
procedure ft_tessellator_destroy(tess: Pointer); cdecl;
procedure ft_tessellator_stroke_polyline(tess: Pointer; mesh: Pointer;
                                         points: PFtPoint2D; count: cint32;
                                         closed: cint32;
                                         stroke_width: Single;
                                         join_style: cint32;
                                         cap_style: cint32;
                                         miter_limit: Single;
                                         aa_fringe: cint32); cdecl;
procedure ft_tessellator_stroke_bezier(tess: Pointer; mesh: Pointer;
                                       p0x, p0y, p1x, p1y, p2x, p2y, p3x, p3y: Single;
                                       stroke_width: Single;
                                       join_style: cint32;
                                       cap_style: cint32;
                                       miter_limit: Single;
                                       aa_fringe: cint32); cdecl;
procedure ft_tessellator_fill_polygon(tess: Pointer; mesh: Pointer;
                                      points: PFtPoint2D; count: cint32;
                                      aa_fringe: cint32); cdecl;

// --- High-Level GPU Renderer C API ---
function ft_renderer_create(): Pointer; cdecl;
procedure ft_renderer_destroy(renderer: Pointer); cdecl;
procedure ft_renderer_begin(renderer: Pointer; viewport_w, viewport_h: cint32); cdecl;
procedure ft_renderer_end(renderer: Pointer); cdecl;
function ft_renderer_get_batch(renderer: Pointer): Pointer; cdecl;
function ft_renderer_get_tessellator(renderer: Pointer): Pointer; cdecl;

implementation

function ARGBToBgraPixel(AColor: Cardinal): TBgraPixel; inline;
begin
  Result.A := (AColor shr 24) and $FF;
  Result.R := (AColor shr 16) and $FF;
  Result.G := (AColor shr 8) and $FF;
  Result.B := AColor and $FF;
end;

function MapBlendMode(AMode: cint32): TFloriaBlendMode; inline;
begin
  case AMode of
    0: Result := fbmSrcOver;
    1: Result := fbmPlus;
    2: Result := fbmMultiply;
    3: Result := fbmScreen;
    4: Result := fbmSrc;
    else Result := fbmSrcOver;
  end;
end;

function MapJoinStyle(AJoin: cint32): TFloriaPathJoinType; inline;
begin
  case AJoin of
    0: Result := fpjtMiter;
    1: Result := fpjtBevel;
    2: Result := fpjtRound;
    else Result := fpjtMiter;
  end;
end;

function MapCapStyle(ACap: cint32): TFloriaPathEndType; inline;
begin
  case ACap of
    0: Result := fpetButt;
    1: Result := fpetSquare;
    2: Result := fpetRound;
    else Result := fpetButt;
  end;
end;

// -----------------------------------------------------------------------------
// Global GPU Status
// -----------------------------------------------------------------------------
function ft_gpu_is_available(): cint32; cdecl;
begin
  if FloriaGPUIsBackendAvailable(gbeEGL) then
    Result := 1
  else
    Result := 0;
end;

// -----------------------------------------------------------------------------
// Render Batch C API Implementation
// -----------------------------------------------------------------------------
function ft_batch_create(): Pointer; cdecl;
begin
  Result := Pointer(TFloriaRenderBatch.Create());
end;

procedure ft_batch_destroy(batch: Pointer); cdecl;
begin
  if Assigned(batch) then
    TFloriaRenderBatch(batch).Free();
end;

procedure ft_batch_clear(batch: Pointer); cdecl;
begin
  if Assigned(batch) then
    TFloriaRenderBatch(batch).Clear();
end;

procedure ft_batch_get_stats(batch: Pointer; stats: PFtBatchStats); cdecl;
begin
  if Assigned(batch) and Assigned(stats) then
  begin
    stats^.DrawCalls   := TFloriaRenderBatch(batch).DrawCallCount;
    stats^.VertexCount := TFloriaRenderBatch(batch).VertexCount;
  end;
end;

procedure ft_batch_emit_rect(batch: Pointer; x, y, w, h: Single; color: Cardinal; blend_mode: cint32); cdecl;
begin
  if Assigned(batch) then
    TFloriaRenderBatch(batch).EmitSolidRect(RectD(x, y, x + w, y + h),
                                            ARGBToBgraPixel(color),
                                            MapBlendMode(blend_mode));
end;

procedure ft_batch_emit_textured_rect(batch: Pointer; x, y, w, h, u0, v0, u1, v1: Single;
                                     tex_id: Cardinal; opacity: Single; blend_mode: cint32); cdecl;
begin
  if Assigned(batch) then
    TFloriaRenderBatch(batch).EmitTexturedRect(RectD(x, y, x + w, y + h),
                                               RectD(u0, v0, u1, v1),
                                               tex_id, opacity,
                                               MapBlendMode(blend_mode));
end;

procedure ft_batch_emit_rounded_rect(batch: Pointer; x, y, w, h, radius: Single;
                                     fill_color, border_color: Cardinal; border_width: Single;
                                     blend_mode: cint32); cdecl;
var
  radii: TFloriaClipCornerRadii;
begin
  if Assigned(batch) then
  begin
    radii := TFloriaClipCornerRadii.Uniform(radius);
    TFloriaRenderBatch(batch).EmitRoundedRect(RectD(x, y, x + w, y + h), radii,
                                              ARGBToBgraPixel(fill_color),
                                              ARGBToBgraPixel(border_color),
                                              border_width,
                                              MapBlendMode(blend_mode));
  end;
end;

procedure ft_batch_emit_box_shadow(batch: Pointer; x, y, w, h, radius, offset_x, offset_y,
                                   blur_radius, spread: Single; shadow_color: Cardinal;
                                   blend_mode: cint32); cdecl;
var
  params: TFloriaShadowParams;
begin
  if Assigned(batch) then
  begin
    params.OffsetX      := offset_x;
    params.OffsetY      := offset_y;
    params.BlurRadius   := blur_radius;
    params.SpreadRadius := spread;
    params.Color        := ARGBToBgraPixel(shadow_color);
    TFloriaRenderBatch(batch).EmitBoxShadow(RectD(x, y, x + w, y + h), radius,
                                            params, MapBlendMode(blend_mode));
  end;
end;

procedure ft_batch_emit_linear_gradient(batch: Pointer; x, y, w, h: Single;
                                        color_start, color_end: Cardinal; angle_deg: Single;
                                        blend_mode: cint32); cdecl;
begin
  if Assigned(batch) then
    TFloriaRenderBatch(batch).EmitLinearGradient(RectD(x, y, x + w, y + h),
                                                 ARGBToBgraPixel(color_start),
                                                 ARGBToBgraPixel(color_end),
                                                 angle_deg,
                                                 MapBlendMode(blend_mode));
end;

procedure ft_batch_emit_path_mesh(batch: Pointer; mesh: Pointer; color: Cardinal; blend_mode: cint32); cdecl;
begin
  if Assigned(batch) and Assigned(mesh) then
    TFloriaRenderBatch(batch).EmitPathMesh(PFtTessMesh(mesh)^,
                                           ARGBToBgraPixel(color),
                                           MapBlendMode(blend_mode));
end;

// -----------------------------------------------------------------------------
// Tessellator & Vector Geometry C API Implementation
// -----------------------------------------------------------------------------
function ft_tessmesh_create(): Pointer; cdecl;
var
  mesh: PFtTessMesh;
begin
  New(mesh);
  mesh^.Clear();
  Result := mesh;
end;

procedure ft_tessmesh_destroy(mesh: Pointer); cdecl;
var
  m: PFtTessMesh;
begin
  if Assigned(mesh) then
  begin
    m := PFtTessMesh(mesh);
    SetLength(m^.Vertices, 0);
    SetLength(m^.Indices, 0);
    Dispose(m);
  end;
end;

procedure ft_tessmesh_clear(mesh: Pointer); cdecl;
begin
  if Assigned(mesh) then
    PFtTessMesh(mesh)^.Clear();
end;

procedure ft_tessmesh_get_counts(mesh: Pointer; out vertex_count, index_count: cint32); cdecl;
begin
  if Assigned(mesh) then
  begin
    vertex_count := PFtTessMesh(mesh)^.VertexCount;
    index_count  := PFtTessMesh(mesh)^.IndexCount;
  end
  else
  begin
    vertex_count := 0;
    index_count  := 0;
  end;
end;

function ft_tessellator_create(): Pointer; cdecl;
begin
  Result := Pointer(TFloriaGPUTessellator.Create());
end;

procedure ft_tessellator_destroy(tess: Pointer); cdecl;
begin
  if Assigned(tess) then
    TFloriaGPUTessellator(tess).Free();
end;

procedure ft_tessellator_stroke_polyline(tess: Pointer; mesh: Pointer;
                                         points: PFtPoint2D; count: cint32;
                                         closed: cint32;
                                         stroke_width: Single;
                                         join_style: cint32;
                                         cap_style: cint32;
                                         miter_limit: Single;
                                         aa_fringe: cint32); cdecl;
var
  pts: TPathD;
  i: Integer;
begin
  if not Assigned(tess) or not Assigned(mesh) or not Assigned(points) or (count < 2) then Exit;
  SetLength(pts, count);
  for i := 0 to count - 1 do
  begin
    pts[i].X := points[i].X;
    pts[i].Y := points[i].Y;
  end;
  TFloriaGPUTessellator(tess).TessellatePolyline(pts, (closed <> 0), stroke_width,
                                                MapJoinStyle(join_style),
                                                MapCapStyle(cap_style),
                                                miter_limit, (aa_fringe <> 0),
                                                PFtTessMesh(mesh)^);
end;

procedure ft_tessellator_stroke_bezier(tess: Pointer; mesh: Pointer;
                                       p0x, p0y, p1x, p1y, p2x, p2y, p3x, p3y: Single;
                                       stroke_width: Single;
                                       join_style: cint32;
                                       cap_style: cint32;
                                       miter_limit: Single;
                                       aa_fringe: cint32); cdecl;
var
  pts: TPathD;
  p0, p1, p2, p3: TPointD;
begin
  if not Assigned(tess) or not Assigned(mesh) then Exit;
  p0 := PointD(p0x, p0y);
  p1 := PointD(p1x, p1y);
  p2 := PointD(p2x, p2y);
  p3 := PointD(p3x, p3y);
  SetLength(pts, 0);
  TFloriaGPUTessellator(tess).SubdivideCubic(p0, p1, p2, p3, pts);
  if Length(pts) >= 2 then
    TFloriaGPUTessellator(tess).TessellatePolyline(pts, False, stroke_width,
                                                  MapJoinStyle(join_style),
                                                  MapCapStyle(cap_style),
                                                  miter_limit, (aa_fringe <> 0),
                                                  PFtTessMesh(mesh)^);
end;

procedure ft_tessellator_fill_polygon(tess: Pointer; mesh: Pointer;
                                      points: PFtPoint2D; count: cint32;
                                      aa_fringe: cint32); cdecl;
var
  pts: TPathD;
  i: Integer;
begin
  if not Assigned(tess) or not Assigned(mesh) or not Assigned(points) or (count < 3) then Exit;
  SetLength(pts, count);
  for i := 0 to count - 1 do
  begin
    pts[i].X := points[i].X;
    pts[i].Y := points[i].Y;
  end;
  TFloriaGPUTessellator(tess).TessellatePolygonFill(pts, (aa_fringe <> 0),
                                                  PFtTessMesh(mesh)^);
end;

// -----------------------------------------------------------------------------
// High-Level GPU Renderer C API Implementation
// -----------------------------------------------------------------------------
function ft_renderer_create(): Pointer; cdecl;
begin
  Result := Pointer(TFloriaGPURenderer.Create(FloriaGL()));
  if Assigned(Result) then
    TFloriaGPURenderer(Result).AutoSwapBuffers := False;
end;

procedure ft_renderer_destroy(renderer: Pointer); cdecl;
begin
  if Assigned(renderer) then
    TFloriaGPURenderer(renderer).Free();
end;

procedure ft_renderer_begin(renderer: Pointer; viewport_w, viewport_h: cint32); cdecl;
begin
  if Assigned(renderer) then
    TFloriaGPURenderer(renderer).BeginFrame(viewport_w, viewport_h);
end;

procedure ft_renderer_end(renderer: Pointer); cdecl;
begin
  if Assigned(renderer) then
    TFloriaGPURenderer(renderer).EndFrame();
end;

function ft_renderer_get_batch(renderer: Pointer): Pointer; cdecl;
begin
  if Assigned(renderer) then
    Result := Pointer(TFloriaGPURenderer(renderer).Batch)
  else
    Result := nil;
end;

function ft_renderer_get_tessellator(renderer: Pointer): Pointer; cdecl;
begin
  if Assigned(renderer) then
    Result := Pointer(TFloriaGPURenderer(renderer).Tessellator)
  else
    Result := nil;
end;

end.
