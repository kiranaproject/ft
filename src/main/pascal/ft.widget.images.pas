unit Ft.Widget.Images;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Math,
  Floria.SVG.DOM,
  Floria.SVG.Parser,
  Floria.SVG.Rasterizer,
  Floria.Canvas.Agg,
  Ft.Canvas,
  Floria.Image.Core,
  Floria.Image.BMP,
  Floria.Image.PNG,
  Floria.Image.GIF,
  Floria.Image.JPEG,
  Floria.Image.WebP,
  Ft.Widget,
  Ft.Animation,
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
    FAnimatedImage: TFloriaAnimatedImage;
    FCurrentFrameIndex: Integer;
    FIsPlaying: Boolean;
    FAutoPlay: Boolean;
    FAnimStartTick: QWord;
    FPausedOffset: QWord;
    procedure SetScaleMode(AValue: TFtImageScaleMode);
    procedure SetCurrentFrame(AValue: Integer);
    procedure SetAutoPlay(AValue: Boolean);
    function GetBitmap(): TFloriaImage;
    function GetFrameCount(): Integer;
    procedure ClearImage();
  protected
    procedure SetVisible(AValue: Boolean); override;
  public
    constructor Create(AParent: TFtWidget; AX, AY, AW, AH: Integer; const AFilePath: string = ''); reintroduce;
    destructor Destroy(); override;

    procedure LoadFromFile(const AFilePath: string);
    procedure LoadFromMemory(AData: Pointer; ASize: Integer);
    procedure LoadAnimationFromFile(const AFilePath: string);
    procedure LoadAnimationFromMemory(AData: Pointer; ASize: Integer);
    procedure LoadSVGFromFile(const AFilePath: string);
    procedure LoadSVGFromString(const ASVGContent: string);
    procedure SetBitmap(ABitmap: TFloriaImage; AOwnsBitmap: Boolean = False);
    procedure InvalidateSVGCache();

    procedure Play();
    procedure Pause();
    procedure Stop();

    procedure Draw(ACanvas: TFtCanvas); override;
    function GetElementType(): string; override;

    property Bitmap: TFloriaImage read GetBitmap;
    property Image: TFloriaImage read GetBitmap;
    property AnimatedImage: TFloriaAnimatedImage read FAnimatedImage;
    property SVGDocument: TSVGDocument read FSVGDoc;
    property OwnsBitmap: Boolean read FOwnsBitmap write FOwnsBitmap;
    property ScaleMode: TFtImageScaleMode read FScaleMode write SetScaleMode;
    property IsPlaying: Boolean read FIsPlaying;
    property AutoPlay: Boolean read FAutoPlay write SetAutoPlay;
    property CurrentFrame: Integer read FCurrentFrameIndex write SetCurrentFrame;
    property FrameCount: Integer read GetFrameCount;
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

procedure TFtImage.SetCurrentFrame(AValue: Integer);
begin
  if Assigned(FSVGDoc) and FSVGDoc.HasAnimation() then
  begin
    if AValue < 0 then AValue := 0;
    FCurrentFrameIndex := AValue;
    FSVGDoc.SetCurrentTime(AValue / 60.0);
    InvalidateSVGCache();
    Invalidate();
    Exit;
  end;

  if not Assigned(FAnimatedImage) or (FAnimatedImage.FrameCount() = 0) then Exit;
  if AValue < 0 then AValue := 0;
  if AValue >= FAnimatedImage.FrameCount() then AValue := FAnimatedImage.FrameCount() - 1;
  if FCurrentFrameIndex <> AValue then
  begin
    FCurrentFrameIndex := AValue;
    Invalidate();
  end;
end;

procedure TFtImage.SetAutoPlay(AValue: Boolean);
begin
  if FAutoPlay <> AValue then
  begin
    FAutoPlay := AValue;
    if (Assigned(FAnimatedImage) and (FAnimatedImage.FrameCount() > 1)) or
       (Assigned(FSVGDoc) and FSVGDoc.HasAnimation()) then
    begin
      if FAutoPlay and not FIsPlaying then
        Play()
      else if not FAutoPlay and FIsPlaying then
        Pause();
    end;
  end;
end;

function TFtImage.GetFrameCount(): Integer;
begin
  if Assigned(FAnimatedImage) then
    Result := FAnimatedImage.FrameCount()
  else if Assigned(FSVGDoc) and FSVGDoc.HasAnimation() then
  begin
    if FSVGDoc.GetAnimationDuration() > 0.0 then
      Result := Max(1, Round(FSVGDoc.GetAnimationDuration() * 60.0))
    else
      Result := 60;
  end
  else if Assigned(FBitmap) or Assigned(FSVGDoc) then
    Result := 1
  else
    Result := 0;
end;

procedure TFtImage.SetVisible(AValue: Boolean);
begin
  inherited SetVisible(AValue);
  if not AValue then
  begin
    if FIsPlaying then
      FtGetAnimator().UnregisterContinuous(Self);
  end
  else
  begin
    if FIsPlaying then
      FtGetAnimator().RegisterContinuous(Self);
  end;
end;

procedure TFtImage.ClearImage();
begin
  Stop();
  InvalidateSVGCache();
  if Assigned(FAnimatedImage) then
  begin
    FAnimatedImage.Free();
    FAnimatedImage := nil;
  end;
  FCurrentFrameIndex := 0;
  FAnimStartTick := 0;
  FPausedOffset := 0;

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

procedure TFtImage.Play();
begin
  if not ((Assigned(FAnimatedImage) and (FAnimatedImage.FrameCount() > 1)) or
          (Assigned(FSVGDoc) and FSVGDoc.HasAnimation())) then Exit;
  if FIsPlaying then Exit;

  FAnimStartTick := GetTickCount64() - FPausedOffset;
  FIsPlaying := True;
  if Showing then
    FtGetAnimator().RegisterContinuous(Self);
  Invalidate();
end;

procedure TFtImage.Pause();
begin
  if not FIsPlaying then Exit;
  FPausedOffset := GetTickCount64() - FAnimStartTick;
  FIsPlaying := False;
  FtGetAnimator().UnregisterContinuous(Self);
  Invalidate();
end;

procedure TFtImage.Stop();
begin
  if FIsPlaying then
  begin
    FIsPlaying := False;
    FtGetAnimator().UnregisterContinuous(Self);
  end;
  FPausedOffset := 0;
  FCurrentFrameIndex := 0;
  if Assigned(FSVGDoc) and FSVGDoc.HasAnimation() then
  begin
    FSVGDoc.ResetAnimation();
    InvalidateSVGCache();
  end;
  Invalidate();
end;

function TFtImage.GetBitmap(): TFloriaImage;
begin
  if Assigned(FAnimatedImage) and (FAnimatedImage.FrameCount() > 0) then
    Exit(FAnimatedImage.GetCompositedFrame(FCurrentFrameIndex));

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
  FAnimatedImage := nil;
  FCurrentFrameIndex := 0;
  FIsPlaying := False;
  FAutoPlay := True;
  FAnimStartTick := 0;
  FPausedOffset := 0;
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
var
  FS: TFileStream;
  AnimFmt: TFloriaImageFormat;
begin
  ClearImage();
  if not FileExists(AFilePath) then Exit;

  if LowerCase(ExtractFileExt(AFilePath)) = '.svg' then
  begin
    LoadSVGFromFile(AFilePath);
    Exit;
  end;

  AnimFmt := fifUnknown;
  try
    FS := TFileStream.Create(AFilePath, fmOpenRead or fmShareDenyNone);
    try
      AnimFmt := DetectAnimationFormat(FS);
    finally
      FS.Free();
    end;
  except
    AnimFmt := fifUnknown;
  end;

  if AnimFmt in [fifGIF, fifPNG] then
  begin
    try
      FAnimatedImage := TFloriaAnimatedImage.CreateFromFile(AFilePath);
      if FAnimatedImage.FrameCount() > 1 then
      begin
        FCurrentFrameIndex := 0;
        if FAutoPlay then
          Play()
        else
          Invalidate();
        Exit;
      end
      else if FAnimatedImage.FrameCount() = 1 then
      begin
        FBitmap := FAnimatedImage.GetCompositedFrame(0).Clone();
        FOwnsBitmap := True;
        FAnimatedImage.Free();
        FAnimatedImage := nil;
        Invalidate();
        Exit;
      end
      else
      begin
        FAnimatedImage.Free();
        FAnimatedImage := nil;
      end;
    except
      if Assigned(FAnimatedImage) then
      begin
        FAnimatedImage.Free();
        FAnimatedImage := nil;
      end;
    end;
  end;

  FBitmap := TFloriaImage.CreateFromFile(AFilePath);
  FOwnsBitmap := True;
  Invalidate();
end;

procedure TFtImage.LoadFromMemory(AData: Pointer; ASize: Integer);
var
  MS: TMemoryStream;
  AnimFmt: TFloriaImageFormat;
  HeaderStr: string;
begin
  ClearImage();
  if (AData = nil) or (ASize <= 0) then Exit;

  if ASize >= 4 then
  begin
    SetLength(HeaderStr, Min(ASize, 512));
    Move(AData^, HeaderStr[1], Length(HeaderStr));
    if (Pos('<svg', LowerCase(HeaderStr)) > 0) or (Pos('<?xml', LowerCase(HeaderStr)) > 0) then
    begin
      LoadSVGFromString(PAnsiChar(AData));
      Exit;
    end;
  end;

  AnimFmt := fifUnknown;
  try
    MS := TMemoryStream.Create();
    try
      MS.WriteBuffer(AData^, ASize);
      MS.Position := 0;
      AnimFmt := DetectAnimationFormat(MS);
    finally
      MS.Free();
    end;
  except
    AnimFmt := fifUnknown;
  end;

  if AnimFmt in [fifGIF, fifPNG] then
  begin
    try
      FAnimatedImage := TFloriaAnimatedImage.CreateFromMemory(AData, ASize);
      if FAnimatedImage.FrameCount() > 1 then
      begin
        FCurrentFrameIndex := 0;
        if FAutoPlay then
          Play()
        else
          Invalidate();
        Exit;
      end
      else if FAnimatedImage.FrameCount() = 1 then
      begin
        FBitmap := FAnimatedImage.GetCompositedFrame(0).Clone();
        FOwnsBitmap := True;
        FAnimatedImage.Free();
        FAnimatedImage := nil;
        Invalidate();
        Exit;
      end
      else
      begin
        FAnimatedImage.Free();
        FAnimatedImage := nil;
      end;
    except
      if Assigned(FAnimatedImage) then
      begin
        FAnimatedImage.Free();
        FAnimatedImage := nil;
      end;
    end;
  end;

  FBitmap := TFloriaImage.CreateFromMemory(AData, ASize);
  FOwnsBitmap := True;
  Invalidate();
end;

procedure TFtImage.LoadAnimationFromFile(const AFilePath: string);
begin
  ClearImage();
  if not FileExists(AFilePath) then Exit;

  FAnimatedImage := TFloriaAnimatedImage.CreateFromFile(AFilePath);
  FCurrentFrameIndex := 0;
  if FAutoPlay then
    Play()
  else
    Invalidate();
end;

procedure TFtImage.LoadAnimationFromMemory(AData: Pointer; ASize: Integer);
begin
  ClearImage();
  if (AData = nil) or (ASize <= 0) then Exit;

  FAnimatedImage := TFloriaAnimatedImage.CreateFromMemory(AData, ASize);
  FCurrentFrameIndex := 0;
  if FAutoPlay then
    Play()
  else
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
  if Assigned(FSVGDoc) and FSVGDoc.HasAnimation() and FAutoPlay then
    Play()
  else
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
  if Assigned(FSVGDoc) and FSVGDoc.HasAnimation() and FAutoPlay then
    Play()
  else
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

procedure TFtImage.Draw(ACanvas: TFtCanvas);
var
  st: TFtWidgetStyle;
  drawX, drawY, drawW, drawH: Double;
  scale, scaleX, scaleY: Double;
  r: Double;
  targetW, targetH: Integer;
  imgToDraw: TFloriaImage;
  NowMs, Elapsed: QWord;
  canvasAgg: TFloriaCanvasAgg;
  animTicked: Boolean;
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
      animTicked := False;
      if Assigned(FSVGDoc) and FSVGDoc.HasAnimation() and FIsPlaying then
      begin
        NowMs := GetTickCount64();
        Elapsed := NowMs - FAnimStartTick;
        if (FSVGDoc.GetAnimationDuration() > 0.0) and (Elapsed >= Round(FSVGDoc.GetAnimationDuration() * 1000.0)) then
        begin
          FSVGDoc.SetCurrentTime(FSVGDoc.GetAnimationDuration());
          FIsPlaying := False;
          FtGetAnimator().UnregisterContinuous(Self);
        end
        else
        begin
          FSVGDoc.SetCurrentTime(Elapsed / 1000.0);
        end;
        animTicked := True;
      end;

      if (FCachedSVG = nil) or (FCachedSVGWidth <> targetW) or (FCachedSVGHeight <> targetH) then
      begin
        InvalidateSVGCache();
        FCachedSVG := TFloriaSVGRenderer.RenderToImage(FSVGDoc, targetW, targetH);
        FCachedSVGWidth := targetW;
        FCachedSVGHeight := targetH;
      end
      else if animTicked then
      begin
        FCachedSVG.Clear(0, 0, 0, 0);
        canvasAgg := TFloriaCanvasAgg.Create(FCachedSVG.PixelBuffer, FCachedSVG.Width, FCachedSVG.Height);
        try
          TFloriaSVGRenderer.Render(canvasAgg, FSVGDoc, 0.0, 0.0, targetW, targetH);
        finally
          canvasAgg.Free();
        end;
        FCachedSVG.InvalidateTexture();
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
  else
  begin
    imgToDraw := nil;
    if Assigned(FAnimatedImage) and (FAnimatedImage.FrameCount() > 0) then
    begin
      if FIsPlaying then
      begin
        NowMs := GetTickCount64();
        Elapsed := NowMs - FAnimStartTick;
        if (FAnimatedImage.LoopCount > 0) and (FAnimatedImage.TotalDurationMs > 0) and
           (Elapsed >= QWord(FAnimatedImage.LoopCount) * FAnimatedImage.TotalDurationMs) then
        begin
          FIsPlaying := False;
          FCurrentFrameIndex := FAnimatedImage.FrameCount() - 1;
          FtGetAnimator().UnregisterContinuous(Self);
        end
        else
        begin
          FCurrentFrameIndex := FAnimatedImage.GetFrameAtTime(Elapsed);
        end;
      end;
      imgToDraw := FAnimatedImage.GetCompositedFrame(FCurrentFrameIndex);
    end
    else if Assigned(FBitmap) and (FBitmap.Width > 0) and (FBitmap.Height > 0) then
      imgToDraw := FBitmap;

    if Assigned(imgToDraw) and (imgToDraw.Width > 0) and (imgToDraw.Height > 0) then
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
          drawW := imgToDraw.Width;
          drawH := imgToDraw.Height;
          drawX := X + (Width - drawW) / 2.0;
          drawY := Y + (Height - drawH) / 2.0;
        end;
        ftismNone:
        begin
          drawX := X;
          drawY := Y;
          drawW := imgToDraw.Width;
          drawH := imgToDraw.Height;
        end;
        else // ftismFit
        begin
          scaleX := Width / imgToDraw.Width;
          scaleY := Height / imgToDraw.Height;
          if scaleX < scaleY then
            scale := scaleX
          else
            scale := scaleY;
          drawW := imgToDraw.Width * scale;
          drawH := imgToDraw.Height * scale;
          drawX := Round(X + (Width - drawW) / 2.0);
          drawY := Round(Y + (Height - drawH) / 2.0);
        end;
      end;

      if (Round(drawW) = imgToDraw.Width) and (Round(drawH) = imgToDraw.Height) then
        ACanvas.DrawImage(drawX, drawY, imgToDraw, 1.0)
      else
        ACanvas.DrawImageScaled(drawX, drawY, drawW, drawH, imgToDraw, 1.0);
    end;
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

end.
