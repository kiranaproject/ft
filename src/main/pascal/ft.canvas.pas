unit Ft.Canvas;

// Ft.Canvas
// =========
// Unified 2D graphics canvas abstraction for Floria Toolkit.
// Re-exports TFloriaCanvas, TFloriaCanvasAgg, and TFloriaCanvasGL.

{$mode objfpc}{$H+}

interface

uses
  Floria.Canvas,
  Floria.Canvas.Agg,
  Floria.Canvas.GL;

type
  TFtCanvas    = Floria.Canvas.TFloriaCanvas;
  TFtCanvasAgg = Floria.Canvas.Agg.TFloriaCanvasAgg;
  TFtCanvasGL  = Floria.Canvas.GL.TFloriaCanvasGL;
  TFtClipRect  = Floria.Canvas.TFtClipRect;

implementation

end.
