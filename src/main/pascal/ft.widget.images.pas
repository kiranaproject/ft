unit Ft.Widget.Images;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes,
  Floria.SVG.DOM,
  Floria.SVG.Parser,
  Floria.SVG.Rasterizer,
  Floria.Canvas.Agg,
  Floria.Image.Core,
  Ft.Widget,
  Ft.Theme,
  Ft.Css;

type
  TFtImageScaleMode = (
    ftismFit = 0,     { Aspect fit centered }
    ftismStretch = 1, { Stretch to full widget bounds }
    ftismCenter = 2,  { 1:1 original size centered }
    ftismNone = 3     { 1:1 original size at (0, 0) }
  );

  TFtImage = class(TFtWidget)
  private
    FBitmap: TFloriaImage;
    FOwnsBitmap: Boolean;
    FScaleMode: TFtImageScaleMode;
    FSVGDoc: TSVGDocument;
    FCachedSVG: TFloriaImage;
    FCachedSVGWidth: Integer;
    FCachedSVGHeight: Integer;
    procedure SetScaleMode(AValue: TFtImageScaleMode);
    function GetBitmap(): TFloriaImage;
    procedure ClearImage();
  public
    constructor Create(AParent: TFtWidget; AX, AY, AW, AH: Integer; const AFilePath: string = ''); reintroduce;
    destructor Destroy(); override;

    procedure LoadFromFile(const AFilePath: string);
    procedure LoadFromMemory(AData: Pointer; ASize: Integer);
    procedure LoadSVGFromFile(const AFilePath: string);
    procedure LoadSVGFromString(const ASVGContent: string);
    procedure SetBitmap(ABitmap: TFloriaImage; AOwnsBitmap: Boolean = False);
    procedure InvalidateSVGCache();

    procedure Draw(ACanvas: TFtCanvasAgg); override;
    function GetElementType(): string; override;

    property Bitmap: TFloriaImage read GetBitmap;
    property Image: TFloriaImage read GetBitmap;
    property SVGDocument: TSVGDocument read FSVGDoc;
    property OwnsBitmap: Boolean read FOwnsBitmap write FOwnsBitmap;
    property ScaleMode: TFtImageScaleMode read FScaleMode write SetScaleMode;
  end;

implementation

procedure TFtImage.InvalidateSVGCache();
begin
  if Assigned(FCachedSVG) then
  begin
    FCachedSVG.Free();
    FCachedSVG := nil;
  end;
  FCachedSVGWidth := 0;
  FCachedSVGHeight := 0;
end;

procedure TFtImage.SetScaleMode(AValue: TFtImageScaleMode);
begin
  if FScaleMode <> AValue then
  begin
    FScaleMode := AValue;
    InvalidateSVGCache();
    Invalidate();
  end;
end;

procedure TFtImage.ClearImage();
begin
  InvalidateSVGCache();
  if FOwnsBitmap and Assigned(FBitmap) then
  begin
    FBitmap.Free();
    FBitmap := nil;
  end
  else
    FBitmap := nil;

  if Assigned(FSVGDoc) then
  begin
    FSVGDoc.Free();
    FSVGDoc := nil;
  end;
end;

function TFtImage.GetBitmap(): TFloriaImage;
begin
  if (FBitmap = nil) and Assigned(FSVGDoc) then
  begin
    if Assigned(FCachedSVG) then
      Exit(FCachedSVG);
    FBitmap := TFloriaSVGRenderer.RenderToImage(FSVGDoc, Width, Height);
    FOwnsBitmap := True;
  end;
  Result := FBitmap;
end;

constructor TFtImage.Create(AParent: TFtWidget; AX, AY, AW, AH: Integer; const AFilePath: string = '');
begin
  inherited Create(AParent);
  X := AX;
  Y := AY;
  Width := AW;
  Height := AH;
  FBitmap := nil;
  FOwnsBitmap := False;
  FSVGDoc := nil;
  FCachedSVG := nil;
  FCachedSVGWidth := 0;
  FCachedSVGHeight := 0;
  FScaleMode := ftismFit;

  if AFilePath <> '' then
    LoadFromFile(AFilePath);
end;

destructor TFtImage.Destroy();
begin
  ClearImage();
  inherited Destroy();
end;

procedure TFtImage.LoadFromFile(const AFilePath: string);
begin
  ClearImage();
  if LowerCase(ExtractFileExt(AFilePath)) = '.svg' then
  begin
    LoadSVGFromFile(AFilePath);
    Exit;
  end;

  FBitmap := TFloriaImage.CreateFromFile(AFilePath);
  FOwnsBitmap := True;
  Invalidate();
end;

procedure TFtImage.LoadSVGFromFile(const AFilePath: string);
begin
  ClearImage();
  try
    FSVGDoc := TSVGParser.ParseFile(AFilePath);
  except
    FSVGDoc := nil;
  end;
  Invalidate();
end;

procedure TFtImage.LoadSVGFromString(const ASVGContent: string);
begin
  ClearImage();
  try
    FSVGDoc := TSVGParser.ParseString(ASVGContent);
  except
    FSVGDoc := nil;
  end;
  Invalidate();
end;

procedure TFtImage.LoadFromMemory(AData: Pointer; ASize: Integer);
begin
  ClearImage();
  FBitmap := TFloriaImage.CreateFromMemory(AData, ASize);
  FOwnsBitmap := True;
  Invalidate();
end;

procedure TFtImage.SetBitmap(ABitmap: TFloriaImage; AOwnsBitmap: Boolean = False);
begin
  ClearImage();
  FBitmap := ABitmap;
  FOwnsBitmap := AOwnsBitmap;
  Invalidate();
end;

function TFtImage.GetElementType(): string;
begin
  Result := 'image';
end;

procedure TFtImage.Draw(ACanvas: TFtCanvasAgg);
var
  st: TFtWidgetStyle;
  drawX, drawY, drawW, drawH: Double;
  scale, scaleX, scaleY: Double;
  r: Double;
  targetW, targetH: Integer;
begin
  if not Visible then Exit;

  st := GetResolvedStyle();
  r := st.BorderRadius;

  // Background if styled
  if st.HasBgColor then
  begin
    if r > 0.0 then
      ACanvas.DrawRoundedRect(X, Y, Width, Height, r, st.BgColor.R, st.BgColor.G, st.BgColor.B, 1.0)
    else
      ACanvas.DrawRect(X, Y, Width, Height, st.BgColor.R, st.BgColor.G, st.BgColor.B);
  end;

  if Assigned(FSVGDoc) then
  begin
    case FScaleMode of
      ftismStretch:
      begin
        drawX := X;
        drawY := Y;
        drawW := Width;
        drawH := Height;
      end;
      ftismCenter:
      begin
        drawW := FSVGDoc.GetIntrinsicWidth();
        drawH := FSVGDoc.GetIntrinsicHeight();
        drawX := X + (Width - drawW) / 2.0;
        drawY := Y + (Height - drawH) / 2.0;
      end;
      ftismNone:
      begin
        drawX := X;
        drawY := Y;
        drawW := FSVGDoc.GetIntrinsicWidth();
        drawH := FSVGDoc.GetIntrinsicHeight();
      end;
      else // ftismFit
      begin
        if (FSVGDoc.GetIntrinsicWidth() > 0.0) and (FSVGDoc.GetIntrinsicHeight() > 0.0) then
        begin
          scaleX := Width / FSVGDoc.GetIntrinsicWidth();
          scaleY := Height / FSVGDoc.GetIntrinsicHeight();
          if scaleX < scaleY then
            scale := scaleX
          else
            scale := scaleY;
          drawW := FSVGDoc.GetIntrinsicWidth() * scale;
          drawH := FSVGDoc.GetIntrinsicHeight() * scale;
        end
        else
        begin
          drawW := Width;
          drawH := Height;
        end;
        drawX := X + (Width - drawW) / 2.0;
        drawY := Y + (Height - drawH) / 2.0;
      end;
    end;

    targetW := Round(drawW);
    targetH := Round(drawH);
    if (targetW > 0) and (targetH > 0) then
    begin
      if (FCachedSVG = nil) or (FCachedSVGWidth <> targetW) or (FCachedSVGHeight <> targetH) then
      begin
        InvalidateSVGCache();
        FCachedSVG := TFloriaSVGRenderer.RenderToImage(FSVGDoc, targetW, targetH);
        FCachedSVGWidth := targetW;
        FCachedSVGHeight := targetH;
      end;

      if Assigned(FCachedSVG) and (FCachedSVG.Width > 0) and (FCachedSVG.Height > 0) then
      begin
        ACanvas.PushClipRect(Round(X), Round(Y), Round(Width), Round(Height));
        try
          ACanvas.DrawImage(drawX, drawY, FCachedSVG, 1.0);
        finally
          ACanvas.PopClipRect();
        end;
      end;
    end;
  end
  else if Assigned(FBitmap) and (FBitmap.Width > 0) and (FBitmap.Height > 0) then
  begin
    case FScaleMode of
      ftismStretch:
      begin
        drawX := X;
        drawY := Y;
        drawW := Width;
        drawH := Height;
      end;
      ftismCenter:
      begin
        drawW := FBitmap.Width;
        drawH := FBitmap.Height;
        drawX := X + (Width - drawW) / 2.0;
        drawY := Y + (Height - drawH) / 2.0;
      end;
      ftismNone:
      begin
        drawX := X;
        drawY := Y;
        drawW := FBitmap.Width;
        drawH := FBitmap.Height;
      end;
      else // ftismFit
      begin
        scaleX := Width / FBitmap.Width;
        scaleY := Height / FBitmap.Height;
        if scaleX < scaleY then
          scale := scaleX
        else
          scale := scaleY;
        drawW := FBitmap.Width * scale;
        drawH := FBitmap.Height * scale;
        drawX := X + (Width - drawW) / 2.0;
        drawY := Y + (Height - drawH) / 2.0;
      end;
    end;

    if (Round(drawW) = FBitmap.Width) and (Round(drawH) = FBitmap.Height) then
      ACanvas.DrawImage(drawX, drawY, FBitmap, 1.0)
    else
      ACanvas.DrawImageScaled(drawX, drawY, drawW, drawH, FBitmap, 1.0);
  end;

  // Border outline if styled
  if (st.BorderWidth > 0.0) and st.HasBorderColor then
  begin
    if r > 0.0 then
      ACanvas.DrawRoundedRectOutline(X, Y, Width, Height, r, st.BorderWidth, st.BorderColor.R, st.BorderColor.G, st.BorderColor.B, 1.0)
    else
      ACanvas.DrawRect(Round(X), Round(Y), Width, Round(st.BorderWidth), st.BorderColor.R, st.BorderColor.G, st.BorderColor.B);
  end;

  inherited Draw(ACanvas);
end;

end.
