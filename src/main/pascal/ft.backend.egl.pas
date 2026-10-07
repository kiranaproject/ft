unit Ft.Backend.EGL;

// Ft.Backend.EGL
// ==============
// Hardware-accelerated presentation and compositing window backend for
// Floria Toolkit using Khronos EGL 1.4/1.5 and OpenGL ES 2.0 / OpenGL.
//
// Features:
// - Hardware VSync synchronization via eglSwapInterval(1) eliminating screen tearing.
// - Zero CPU-to-XServer socket transmission overhead: renders texture quads on the GPU.
// - Full backward-compatible fallback: if EGL/GPU is absent, gracefully falls back to XCB PutImage.
// - Support for custom OpenGL drawing hooks (OnGLDraw) inside any toolkit window.
// - Direct 32-bit BGRA texture streaming pipeline.

{$mode objfpc}{$H+}

interface

uses
  ctypes, SysUtils, Classes, Types, dynlibs,
  Floria.EGL, Floria.Canvas.Agg,
  Floria.XCB,
  Ft.Widget, Ft.Window, Ft.Backend.X11;

const
  GL_FALSE                = 0;
  GL_TRUE                 = 1;
  GL_TRIANGLES            = $0004;
  GL_NEAREST              = $2600;
  GL_LINEAR               = $2601;
  GL_TEXTURE_MAG_FILTER   = $2800;
  GL_TEXTURE_MIN_FILTER   = $2801;
  GL_TEXTURE_WRAP_S       = $2802;
  GL_TEXTURE_WRAP_T       = $2803;
  GL_CLAMP_TO_EDGE        = $812F;
  GL_TEXTURE_2D           = $0DE1;
  GL_UNSIGNED_BYTE        = $1401;
  GL_FLOAT                = $1406;
  GL_RGBA                 = $1908;
  GL_BGRA_EXT             = $80E1;
  GL_COLOR_BUFFER_BIT     = $00004000;
  GL_FRAGMENT_SHADER      = $8B30;
  GL_VERTEX_SHADER        = $8B31;
  GL_COMPILE_STATUS       = $8B81;
  GL_LINK_STATUS          = $8B82;
  GL_INFO_LOG_LENGTH      = $8B84;
  GL_UNPACK_ROW_LENGTH    = $0CF2;
  GL_UNPACK_SKIP_ROWS     = $0CF3;
  GL_UNPACK_SKIP_PIXELS   = $0CF4;
  GL_UNPACK_ALIGNMENT     = $0CF5;

type
  TFtGLDrawEvent = procedure(Sender: TObject; AWidth, AHeight: Integer) of object;
  TFtWindowGLDrawCallback = procedure(window: Pointer; width, height: cint32; user_data: Pointer); cdecl;

  // OpenGL ES 2.0 / GL Function pointer types
  TglViewport = procedure(x, y, width, height: cint); cdecl;
  TglClear = procedure(mask: cuint); cdecl;
  TglClearColor = procedure(red, green, blue, alpha: cfloat); cdecl;
  TglGenTextures = procedure(n: cint; textures: Pcuint); cdecl;
  TglBindTexture = procedure(target: cuint; texture: cuint); cdecl;
  TglTexParameteri = procedure(target, pname: cuint; param: cint); cdecl;
  TglTexImage2D = procedure(target: cuint; level, internalformat, width, height, border: cint; format, type_: cuint; pixels: Pointer); cdecl;
  TglTexSubImage2D = procedure(target: cuint; level, xoffset, yoffset, width, height: cint; format, type_: cuint; pixels: Pointer); cdecl;
  TglDeleteTextures = procedure(n: cint; textures: Pcuint); cdecl;
  TglCreateShader = function(type_: cuint): cuint; cdecl;
  TglShaderSource = procedure(shader: cuint; count: cint; const strings: PPChar; const length: Pcint); cdecl;
  TglCompileShader = procedure(shader: cuint); cdecl;
  TglGetShaderiv = procedure(shader, pname: cuint; params: Pcint); cdecl;
  TglGetShaderInfoLog = procedure(shader: cuint; bufsize: cint; length: Pcint; infolog: PChar); cdecl;
  TglCreateProgram = function(): cuint; cdecl;
  TglAttachShader = procedure(program_, shader: cuint); cdecl;
  TglLinkProgram = procedure(program_: cuint); cdecl;
  TglGetProgramiv = procedure(program_, pname: cuint; params: Pcint); cdecl;
  TglGetProgramInfoLog = procedure(program_: cuint; bufsize: cint; length: Pcint; infolog: PChar); cdecl;
  TglUseProgram = procedure(program_: cuint); cdecl;
  TglGetAttribLocation = function(program_: cuint; const name: PChar): cint; cdecl;
  TglGetUniformLocation = function(program_: cuint; const name: PChar): cint; cdecl;
  TglEnableVertexAttribArray = procedure(index: cuint); cdecl;
  TglDisableVertexAttribArray = procedure(index: cuint); cdecl;
  TglVertexAttribPointer = procedure(index: cuint; size: cint; type_: cuint; normalized: cbool; stride: cint; const pointer_: Pointer); cdecl;
  TglUniform1i = procedure(location: cint; v0: cint); cdecl;
  TglDrawArrays = procedure(mode: cuint; first: cint; count: cint); cdecl;
  TglDeleteProgram = procedure(program_: cuint); cdecl;
  TglDeleteShader = procedure(shader: cuint); cdecl;
  TglPixelStorei = procedure(pname: cuint; param: cint); cdecl;
  TglGetError = function(): cuint; cdecl;

  // TFtEGLWindow
  TFtEGLWindow = class(TFtX11Window)
  private
    FXDisplay           : Pointer;
    FEGLDisplay         : EGLDisplay;
    FEGLConfig          : EGLConfig;
    FEGLContext         : EGLContext;
    FEGLSurface         : EGLSurface;
    FHardwareAccelerated: Boolean;
    FTextureID          : Cardinal;
    FTextureWidth       : Integer;
    FTextureHeight      : Integer;
    FProgramID          : Cardinal;
    FVertShaderID       : Cardinal;
    FFragShaderID       : Cardinal;
    FPosLoc             : Integer;
    FTexLoc             : Integer;
    FTexUniformLoc      : Integer;
    FSwapInterval       : Integer;
    FDirectGPUMode      : Boolean;
    FOnGLDraw           : TFtGLDrawEvent;
    FCGLDrawCallback    : TFtWindowGLDrawCallback;
    FCGLDrawUserData    : Pointer;

    function InitEGL(): Boolean;
    procedure CleanupEGL();
    function InitGLPipeline(): Boolean;
    procedure CleanupGLPipeline();
    procedure UpdateTexture(dirtyX, dirtyY, dirtyW, dirtyH: Integer; isPartial: Boolean);
    procedure RenderQuad();
    procedure SetDirectGPUMode(AValue: Boolean);
  protected
    procedure PresentPixels(dirtyX, dirtyY, dirtyW, dirtyH: Integer; isPartial: Boolean); override;
  public
    constructor Create(W, H: Integer; const ATitle: string = ''); override;
    destructor Destroy(); override;

    procedure Resize(NewW, NewH: Integer; AApplyToBackend: Boolean = True); override;
    procedure Repaint(); override;

    function MakeCurrent(): Boolean;
    procedure ReleaseCurrent();
    procedure SetSwapInterval(AInterval: Integer);
    procedure SetHardwareAccelerated(AValue: Boolean);

    property IsHardwareAccelerated: Boolean read FHardwareAccelerated write SetHardwareAccelerated;
    property DirectGPUMode: Boolean read FDirectGPUMode write SetDirectGPUMode;
    property EGLDisplay: EGLDisplay read FEGLDisplay;
    property EGLContext: EGLContext read FEGLContext;
    property EGLSurface: EGLSurface read FEGLSurface;
    property EGLConfig: EGLConfig read FEGLConfig;
    property SwapInterval: Integer read FSwapInterval write SetSwapInterval;
    property OnGLDraw: TFtGLDrawEvent read FOnGLDraw write FOnGLDraw;
    property CGLDrawCallback: TFtWindowGLDrawCallback read FCGLDrawCallback write FCGLDrawCallback;
    property CGLDrawUserData: Pointer read FCGLDrawUserData write FCGLDrawUserData;
  end;

function FtEGLIsAvailable(): Boolean;
function FtEnableEGLBackend(AEnable: Boolean = True): Boolean;
function FtIsEGLEnabled(): Boolean;

implementation

type
  TXOpenDisplay = function(name: PChar): Pointer; cdecl;
  TXCloseDisplay = function(dpy: Pointer): cint; cdecl;

var
  GX11LibHandle    : TLibHandle = NilHandle;
  GXOpenDisplay    : TXOpenDisplay = nil;
  GXCloseDisplay   : TXCloseDisplay = nil;
  GSharedXDisplay  : Pointer = nil;
  GSharedXRefCount : Integer = 0;

  GGLESLibHandle   : TLibHandle = NilHandle;
  GGLInitialized   : Boolean = False;
  GEGLEnabled      : Boolean = False;

  // Dynamic GLES2 function pointers
  glViewport              : TglViewport = nil;
  glClear                 : TglClear = nil;
  glClearColor            : TglClearColor = nil;
  glGenTextures           : TglGenTextures = nil;
  glBindTexture           : TglBindTexture = nil;
  glTexParameteri         : TglTexParameteri = nil;
  glTexImage2D            : TglTexImage2D = nil;
  glTexSubImage2D         : TglTexSubImage2D = nil;
  glDeleteTextures        : TglDeleteTextures = nil;
  glCreateShader          : TglCreateShader = nil;
  glShaderSource          : TglShaderSource = nil;
  glCompileShader         : TglCompileShader = nil;
  glGetShaderiv           : TglGetShaderiv = nil;
  glGetShaderInfoLog      : TglGetShaderInfoLog = nil;
  glCreateProgram         : TglCreateProgram = nil;
  glAttachShader          : TglAttachShader = nil;
  glLinkProgram           : TglLinkProgram = nil;
  glGetProgramiv          : TglGetProgramiv = nil;
  glGetProgramInfoLog     : TglGetProgramInfoLog = nil;
  glUseProgram            : TglUseProgram = nil;
  glGetAttribLocation     : TglGetAttribLocation = nil;
  glGetUniformLocation    : TglGetUniformLocation = nil;
  glEnableVertexAttribArray : TglEnableVertexAttribArray = nil;
  glDisableVertexAttribArray: TglDisableVertexAttribArray = nil;
  glVertexAttribPointer   : TglVertexAttribPointer = nil;
  glUniform1i             : TglUniform1i = nil;
  glDrawArrays            : TglDrawArrays = nil;
  glDeleteProgram         : TglDeleteProgram = nil;
  glDeleteShader          : TglDeleteShader = nil;
  glPixelStorei           : TglPixelStorei = nil;
  glGetError              : TglGetError = nil;

function AcquireXDisplay(): Pointer;
const
  X11_LIBS: array[0..2] of string = ('libX11.so.6', 'libX11.so', 'libX11.dylib');
var
  i: Integer;
begin
  if GSharedXDisplay = nil then
  begin
    if GX11LibHandle = NilHandle then
    begin
      for i := Low(X11_LIBS) to High(X11_LIBS) do
      begin
        GX11LibHandle := SafeLoadLibrary(X11_LIBS[i]);
        if GX11LibHandle <> NilHandle then Break;
      end;
      if GX11LibHandle <> NilHandle then
      begin
        GXOpenDisplay  := TXOpenDisplay(GetProcAddress(GX11LibHandle, 'XOpenDisplay'));
        GXCloseDisplay := TXCloseDisplay(GetProcAddress(GX11LibHandle, 'XCloseDisplay'));
      end;
    end;

    if Assigned(GXOpenDisplay) then
      GSharedXDisplay := GXOpenDisplay(nil);
  end;

  Result := GSharedXDisplay;
end;

procedure ReleaseXDisplay();
begin
  // Keep GSharedXDisplay alive for the process lifetime; closed at finalization
end;

function LoadGLSymbols(): Boolean;
const
  GLES_LIBS: array[0..3] of string = (
    'libGLESv2.so.2',
    'libGLESv2.so',
    'libGL.so.1',
    'libGL.so'
  );

  function Resolve(const AName: string): Pointer;
  begin
    Result := nil;
    if FloriaEGLIsAvailable() then
      Result := FloriaEGL().GetProc(AName);
    if (Result = nil) and (GGLESLibHandle <> NilHandle) then
      Result := GetProcAddress(GGLESLibHandle, PChar(AName));
  end;

var
  i: Integer;
begin
  if GGLInitialized then
    Exit(True);

  for i := Low(GLES_LIBS) to High(GLES_LIBS) do
  begin
    GGLESLibHandle := SafeLoadLibrary(GLES_LIBS[i]);
    if GGLESLibHandle <> NilHandle then Break;
  end;

  glViewport              := TglViewport(Resolve('glViewport'));
  glClear                 := TglClear(Resolve('glClear'));
  glClearColor            := TglClearColor(Resolve('glClearColor'));
  glGenTextures           := TglGenTextures(Resolve('glGenTextures'));
  glBindTexture           := TglBindTexture(Resolve('glBindTexture'));
  glTexParameteri         := TglTexParameteri(Resolve('glTexParameteri'));
  glTexImage2D            := TglTexImage2D(Resolve('glTexImage2D'));
  glTexSubImage2D         := TglTexSubImage2D(Resolve('glTexSubImage2D'));
  glDeleteTextures        := TglDeleteTextures(Resolve('glDeleteTextures'));
  glCreateShader          := TglCreateShader(Resolve('glCreateShader'));
  glShaderSource          := TglShaderSource(Resolve('glShaderSource'));
  glCompileShader         := TglCompileShader(Resolve('glCompileShader'));
  glGetShaderiv           := TglGetShaderiv(Resolve('glGetShaderiv'));
  glGetShaderInfoLog      := TglGetShaderInfoLog(Resolve('glGetShaderInfoLog'));
  glCreateProgram         := TglCreateProgram(Resolve('glCreateProgram'));
  glAttachShader          := TglAttachShader(Resolve('glAttachShader'));
  glLinkProgram           := TglLinkProgram(Resolve('glLinkProgram'));
  glGetProgramiv          := TglGetProgramiv(Resolve('glGetProgramiv'));
  glGetProgramInfoLog     := TglGetProgramInfoLog(Resolve('glGetProgramInfoLog'));
  glUseProgram            := TglUseProgram(Resolve('glUseProgram'));
  glGetAttribLocation     := TglGetAttribLocation(Resolve('glGetAttribLocation'));
  glGetUniformLocation    := TglGetUniformLocation(Resolve('glGetUniformLocation'));
  glEnableVertexAttribArray := TglEnableVertexAttribArray(Resolve('glEnableVertexAttribArray'));
  glDisableVertexAttribArray:= TglDisableVertexAttribArray(Resolve('glDisableVertexAttribArray'));
  glVertexAttribPointer   := TglVertexAttribPointer(Resolve('glVertexAttribPointer'));
  glUniform1i             := TglUniform1i(Resolve('glUniform1i'));
  glDrawArrays            := TglDrawArrays(Resolve('glDrawArrays'));
  glDeleteProgram         := TglDeleteProgram(Resolve('glDeleteProgram'));
  glDeleteShader          := TglDeleteShader(Resolve('glDeleteShader'));
  glPixelStorei           := TglPixelStorei(Resolve('glPixelStorei'));
  glGetError              := TglGetError(Resolve('glGetError'));

  GGLInitialized := Assigned(glViewport) and
                    Assigned(glGenTextures) and
                    Assigned(glBindTexture) and
                    Assigned(glTexImage2D) and
                    Assigned(glCreateProgram) and
                    Assigned(glDrawArrays);

  Result := GGLInitialized;
end;

function FtEGLIsAvailable(): Boolean;
begin
  Result := FloriaEGLIsAvailable() and LoadGLSymbols();
end;

function FtEnableEGLBackend(AEnable: Boolean): Boolean;
begin
  if AEnable then
  begin
    if FtEGLIsAvailable() then
    begin
      GEGLEnabled := True;
      FtRegisterWindowClass(TFtEGLWindow);
      Result := True;
    end
    else
    begin
      GEGLEnabled := False;
      FtRegisterWindowClass(TFtX11Window);
      Result := False;
    end;
  end
  else
  begin
    GEGLEnabled := False;
    FtRegisterWindowClass(TFtX11Window);
    Result := True;
  end;
end;

function FtIsEGLEnabled(): Boolean;
begin
  Result := GEGLEnabled;
end;

// ============================================================================
// TFtEGLWindow Implementation
// ============================================================================

constructor TFtEGLWindow.Create(W, H: Integer; const ATitle: string);
begin
  inherited Create(W, H, ATitle);

  FXDisplay            := nil;
  FEGLDisplay          := EGL_NO_DISPLAY;
  FEGLConfig           := nil;
  FEGLContext          := EGL_NO_CONTEXT;
  FEGLSurface          := EGL_NO_SURFACE;
  FHardwareAccelerated := False;
  FTextureID           := 0;
  FTextureWidth        := 0;
  FTextureHeight       := 0;
  FProgramID           := 0;
  FVertShaderID        := 0;
  FFragShaderID        := 0;
  FPosLoc              := -1;
  FTexLoc              := -1;
  FTexUniformLoc       := -1;
  FSwapInterval        := 1;
  FDirectGPUMode       := False;
  FOnGLDraw            := nil;
  FCGLDrawCallback     := nil;
  FCGLDrawUserData     := nil;

  if FloriaEGLIsAvailable() and LoadGLSymbols() then
  begin
    FHardwareAccelerated := InitEGL();
  end;
end;

destructor TFtEGLWindow.Destroy();
begin
  CleanupEGL();
  inherited Destroy();
end;

function TFtEGLWindow.InitEGL(): Boolean;
var
  attribs: array[0..12] of EGLint;
  ctxAttribs: array[0..2] of EGLint;
  major, minor: EGLint;
  numConfigs: EGLint;
  configs: array of EGLConfig;
  i: Integer;
  visId: EGLint;
  targetVis: xcb_visualid_t;
  chosenConfig: EGLConfig;
  surfType: EGLint;
begin
  Result := False;
  FXDisplay := AcquireXDisplay();
  if FXDisplay = nil then
    Exit(False);

  FEGLDisplay := eglGetDisplay(EGLNativeDisplayType(FXDisplay));
  if FEGLDisplay = EGL_NO_DISPLAY then
    Exit(False);

  major := 0;
  minor := 0;
  if eglInitialize(FEGLDisplay, @major, @minor) = EGL_FALSE then
    Exit(False);

  // Match native visual of X11 window
  targetVis := FVisual;
  chosenConfig := nil;

  attribs[0] := EGL_SURFACE_TYPE;
  attribs[1] := EGL_WINDOW_BIT;
  attribs[2] := EGL_RED_SIZE;
  attribs[3] := 8;
  attribs[4] := EGL_GREEN_SIZE;
  attribs[5] := 8;
  attribs[6] := EGL_BLUE_SIZE;
  attribs[7] := 8;
  attribs[8] := EGL_RENDERABLE_TYPE;
  attribs[9] := EGL_OPENGL_ES2_BIT;
  attribs[10] := EGL_NONE;

  numConfigs := 0;
  if (eglGetConfigs(FEGLDisplay, nil, 0, @numConfigs) = EGL_TRUE) and (numConfigs > 0) then
  begin
    SetLength(configs, numConfigs);
    eglGetConfigs(FEGLDisplay, @configs[0], numConfigs, @numConfigs);

    for i := 0 to numConfigs - 1 do
    begin
      surfType := 0;
      eglGetConfigAttrib(FEGLDisplay, configs[i], EGL_SURFACE_TYPE, @surfType);
      if (surfType and EGL_WINDOW_BIT) <> 0 then
      begin
        visId := 0;
        eglGetConfigAttrib(FEGLDisplay, configs[i], EGL_NATIVE_VISUAL_ID, @visId);
        if visId = EGLint(targetVis) then
        begin
          chosenConfig := configs[i];
          Break;
        end;
      end;
    end;
  end;

  if chosenConfig = nil then
  begin
    // Fallback: request matching config via chooseConfig
    numConfigs := 0;
    if eglChooseConfig(FEGLDisplay, @attribs[0], @chosenConfig, 1, @numConfigs) <> EGL_TRUE then
      Exit(False);
    if (numConfigs = 0) or (chosenConfig = nil) then
      Exit(False);
  end;

  FEGLConfig := chosenConfig;

  // Bind OpenGL ES API
  eglBindAPI(EGL_OPENGL_ES_API);

  ctxAttribs[0] := EGL_CONTEXT_CLIENT_VERSION;
  ctxAttribs[1] := 2;
  ctxAttribs[2] := EGL_NONE;

  FEGLContext := eglCreateContext(FEGLDisplay, FEGLConfig, EGL_NO_CONTEXT, @ctxAttribs[0]);
  if FEGLContext = EGL_NO_CONTEXT then
    Exit(False);

  FEGLSurface := eglCreateWindowSurface(FEGLDisplay, FEGLConfig, EGLNativeWindowType(FWindow), nil);
  if FEGLSurface = EGL_NO_SURFACE then
  begin
    eglDestroyContext(FEGLDisplay, FEGLContext);
    FEGLContext := EGL_NO_CONTEXT;
    Exit(False);
  end;

  if not MakeCurrent() then
  begin
    eglDestroySurface(FEGLDisplay, FEGLSurface);
    FEGLSurface := EGL_NO_SURFACE;
    eglDestroyContext(FEGLDisplay, FEGLContext);
    FEGLContext := EGL_NO_CONTEXT;
    Exit(False);
  end;

  eglSwapInterval(FEGLDisplay, FSwapInterval);

  if not InitGLPipeline() then
  begin
    ReleaseCurrent();
    eglDestroySurface(FEGLDisplay, FEGLSurface);
    FEGLSurface := EGL_NO_SURFACE;
    eglDestroyContext(FEGLDisplay, FEGLContext);
    FEGLContext := EGL_NO_CONTEXT;
    Exit(False);
  end;

  ReleaseCurrent();
  Result := True;
end;

procedure TFtEGLWindow.CleanupEGL();
begin
  if FHardwareAccelerated then
  begin
    MakeCurrent();
    CleanupGLPipeline();
    ReleaseCurrent();
  end;

  if (FEGLDisplay <> EGL_NO_DISPLAY) then
  begin
    if FEGLSurface <> EGL_NO_SURFACE then
    begin
      eglDestroySurface(FEGLDisplay, FEGLSurface);
      FEGLSurface := EGL_NO_SURFACE;
    end;
    if FEGLContext <> EGL_NO_CONTEXT then
    begin
      eglDestroyContext(FEGLDisplay, FEGLContext);
      FEGLContext := EGL_NO_CONTEXT;
    end;
    FEGLDisplay := EGL_NO_DISPLAY;
  end;

  if Assigned(FXDisplay) then
  begin
    ReleaseXDisplay();
    FXDisplay := nil;
  end;

  FHardwareAccelerated := False;
end;

function TFtEGLWindow.InitGLPipeline(): Boolean;
const
  VERTEX_SRC: PChar =
    'attribute vec2 aPos;'#10 +
    'attribute vec2 aTex;'#10 +
    'varying vec2 vTex;'#10 +
    'void main() {'#10 +
    '    vTex = aTex;'#10 +
    '    gl_Position = vec4(aPos, 0.0, 1.0);'#10 +
    '}'#10;

  FRAGMENT_SRC: PChar =
    'precision mediump float;'#10 +
    'varying vec2 vTex;'#10 +
    'uniform sampler2D uTex;'#10 +
    'void main() {'#10 +
    '    gl_FragColor = texture2D(uTex, vTex);'#10 +
    '}'#10;
var
  status: cint;
begin
  Result := False;

  FVertShaderID := glCreateShader(GL_VERTEX_SHADER);
  glShaderSource(FVertShaderID, 1, @VERTEX_SRC, nil);
  glCompileShader(FVertShaderID);
  status := 0;
  glGetShaderiv(FVertShaderID, GL_COMPILE_STATUS, @status);
  if status = GL_FALSE then Exit(False);

  FFragShaderID := glCreateShader(GL_FRAGMENT_SHADER);
  glShaderSource(FFragShaderID, 1, @FRAGMENT_SRC, nil);
  glCompileShader(FFragShaderID);
  status := 0;
  glGetShaderiv(FFragShaderID, GL_COMPILE_STATUS, @status);
  if status = GL_FALSE then Exit(False);

  FProgramID := glCreateProgram();
  glAttachShader(FProgramID, FVertShaderID);
  glAttachShader(FProgramID, FFragShaderID);
  glLinkProgram(FProgramID);
  status := 0;
  glGetProgramiv(FProgramID, GL_LINK_STATUS, @status);
  if status = GL_FALSE then Exit(False);

  FPosLoc        := glGetAttribLocation(FProgramID, 'aPos');
  FTexLoc        := glGetAttribLocation(FProgramID, 'aTex');
  FTexUniformLoc := glGetUniformLocation(FProgramID, 'uTex');

  // Allocate GPU Texture
  glGenTextures(1, @FTextureID);
  glBindTexture(GL_TEXTURE_2D, FTextureID);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

  FTextureWidth  := Width;
  FTextureHeight := Height;
  if (FTextureWidth > 0) and (FTextureHeight > 0) then
  begin
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, FTextureWidth, FTextureHeight, 0,
                 GL_BGRA_EXT, GL_UNSIGNED_BYTE, FPixelBuffer);
  end;

  Result := True;
end;

procedure TFtEGLWindow.CleanupGLPipeline();
begin
  if FTextureID <> 0 then
  begin
    glDeleteTextures(1, @FTextureID);
    FTextureID := 0;
  end;
  if FProgramID <> 0 then
  begin
    glDeleteProgram(FProgramID);
    FProgramID := 0;
  end;
  if FVertShaderID <> 0 then
  begin
    glDeleteShader(FVertShaderID);
    FVertShaderID := 0;
  end;
  if FFragShaderID <> 0 then
  begin
    glDeleteShader(FFragShaderID);
    FFragShaderID := 0;
  end;
end;

function TFtEGLWindow.MakeCurrent(): Boolean;
begin
  if (FEGLDisplay <> EGL_NO_DISPLAY) and (FEGLSurface <> EGL_NO_SURFACE) and (FEGLContext <> EGL_NO_CONTEXT) then
  begin
    if eglGetCurrentContext() = FEGLContext then
      Result := True
    else
      Result := (eglMakeCurrent(FEGLDisplay, FEGLSurface, FEGLSurface, FEGLContext) = EGL_TRUE);
  end
  else
    Result := False;
end;

procedure TFtEGLWindow.ReleaseCurrent();
begin
  if (FEGLDisplay <> EGL_NO_DISPLAY) then
    eglMakeCurrent(FEGLDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
end;

procedure TFtEGLWindow.SetSwapInterval(AInterval: Integer);
begin
  FSwapInterval := AInterval;
  if FHardwareAccelerated and MakeCurrent() then
  begin
    eglSwapInterval(FEGLDisplay, FSwapInterval);
    ReleaseCurrent();
  end;
end;

procedure TFtEGLWindow.SetHardwareAccelerated(AValue: Boolean);
begin
  if FHardwareAccelerated = AValue then Exit;

  if AValue then
  begin
    if (FEGLDisplay = EGL_NO_DISPLAY) then
      FHardwareAccelerated := InitEGL()
    else
      FHardwareAccelerated := True;
  end
  else
    FHardwareAccelerated := False;

  Invalidate();
end;

procedure TFtEGLWindow.SetDirectGPUMode(AValue: Boolean);
begin
  FDirectGPUMode := AValue;
end;

procedure TFtEGLWindow.Repaint();
begin
  if FDirectGPUMode and FHardwareAccelerated then
  begin
    FNeedsRepaint := False;
    PresentPixels(0, 0, Width, Height, False);
  end
  else
    inherited Repaint();
end;

procedure TFtEGLWindow.Resize(NewW, NewH: Integer; AApplyToBackend: Boolean);
begin
  // inherited Resize invokes Repaint() which updates the GPU texture and presents pixels
  inherited Resize(NewW, NewH, AApplyToBackend);
end;

procedure TFtEGLWindow.UpdateTexture(dirtyX, dirtyY, dirtyW, dirtyH: Integer; isPartial: Boolean);
begin
  glBindTexture(GL_TEXTURE_2D, FTextureID);

  if (FTextureWidth <> Width) or (FTextureHeight <> Height) then
  begin
    FTextureWidth  := Width;
    FTextureHeight := Height;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, Width, Height, 0,
                 GL_BGRA_EXT, GL_UNSIGNED_BYTE, FPixelBuffer);
    Exit;
  end;

  if isPartial and Assigned(glPixelStorei) and (dirtyW > 0) and (dirtyH > 0) then
  begin
    glPixelStorei(GL_UNPACK_ROW_LENGTH, Width);
    glPixelStorei(GL_UNPACK_SKIP_PIXELS, dirtyX);
    glPixelStorei(GL_UNPACK_SKIP_ROWS, dirtyY);
    glTexSubImage2D(GL_TEXTURE_2D, 0, dirtyX, dirtyY, dirtyW, dirtyH,
                    GL_BGRA_EXT, GL_UNSIGNED_BYTE, FPixelBuffer);
    glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
    glPixelStorei(GL_UNPACK_SKIP_PIXELS, 0);
    glPixelStorei(GL_UNPACK_SKIP_ROWS, 0);
  end
  else
  begin
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, Width, Height,
                    GL_BGRA_EXT, GL_UNSIGNED_BYTE, FPixelBuffer);
  end;
end;

procedure TFtEGLWindow.RenderQuad();
const
  QUAD_DATA: array[0..23] of Single = (
    // X,     Y,   U,   V
    -1.0,  1.0, 0.0, 0.0,
    -1.0, -1.0, 0.0, 1.0,
     1.0, -1.0, 1.0, 1.0,

    -1.0,  1.0, 0.0, 0.0,
     1.0, -1.0, 1.0, 1.0,
     1.0,  1.0, 1.0, 0.0
  );
var
  surfW, surfH: EGLint;
  vpY: Integer;
begin
  surfW := Width;
  surfH := Height;
  if (FEGLDisplay <> EGL_NO_DISPLAY) and (FEGLSurface <> EGL_NO_SURFACE) then
  begin
    eglQuerySurface(FEGLDisplay, FEGLSurface, EGL_WIDTH, @surfW);
    eglQuerySurface(FEGLDisplay, FEGLSurface, EGL_HEIGHT, @surfH);
  end;

  // In OpenGL, origin (0, 0) is bottom-left, whereas X11 is top-left.
  // When the window is resized vertically, anchor the viewport to the top of the EGL surface:
  // Top of surface is at Y = surfH. Viewport of height Height anchored to top starts at Y = surfH - Height.
  vpY := surfH - Height;

  if (surfW <> Width) or (surfH <> Height) then
  begin
    glViewport(0, 0, surfW, surfH);
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
  end;

  glViewport(0, vpY, Width, Height);
  glUseProgram(FProgramID);

  if FPosLoc >= 0 then
  begin
    glEnableVertexAttribArray(FPosLoc);
    glVertexAttribPointer(FPosLoc, 2, GL_FLOAT, False, 16, @QUAD_DATA[0]);
  end;

  if FTexLoc >= 0 then
  begin
    glEnableVertexAttribArray(FTexLoc);
    glVertexAttribPointer(FTexLoc, 2, GL_FLOAT, False, 16, @QUAD_DATA[2]);
  end;

  if FTexUniformLoc >= 0 then
    glUniform1i(FTexUniformLoc, 0);

  glDrawArrays(GL_TRIANGLES, 0, 6);

  if FPosLoc >= 0 then
    glDisableVertexAttribArray(FPosLoc);
  if FTexLoc >= 0 then
    glDisableVertexAttribArray(FTexLoc);
end;

procedure TFtEGLWindow.PresentPixels(dirtyX, dirtyY, dirtyW, dirtyH: Integer; isPartial: Boolean);
var
  surfW, surfH: EGLint;
begin
  if not FHardwareAccelerated then
  begin
    inherited PresentPixels(dirtyX, dirtyY, dirtyW, dirtyH, isPartial);
    Exit;
  end;

  if MakeCurrent() then
  begin
    if FDirectGPUMode then
    begin
      surfW := Width;
      surfH := Height;
      if (FEGLDisplay <> EGL_NO_DISPLAY) and (FEGLSurface <> EGL_NO_SURFACE) then
      begin
        eglQuerySurface(FEGLDisplay, FEGLSurface, EGL_WIDTH, @surfW);
        eglQuerySurface(FEGLDisplay, FEGLSurface, EGL_HEIGHT, @surfH);
      end;
      glViewport(0, 0, surfW, surfH);

      // Custom OpenGL rendering if registered
      if Assigned(FOnGLDraw) then
        FOnGLDraw(Self, surfW, surfH);
      if Assigned(FCGLDrawCallback) then
        FCGLDrawCallback(Pointer(Self), surfW, surfH, FCGLDrawUserData);

      eglSwapBuffers(FEGLDisplay, FEGLSurface);
    end
    else
    begin
      UpdateTexture(dirtyX, dirtyY, dirtyW, dirtyH, isPartial);
      RenderQuad();

      // Custom OpenGL rendering overlay if registered
      if Assigned(FOnGLDraw) then
        FOnGLDraw(Self, Width, Height);
      if Assigned(FCGLDrawCallback) then
        FCGLDrawCallback(Pointer(Self), Width, Height, FCGLDrawUserData);

      eglSwapBuffers(FEGLDisplay, FEGLSurface);
    end;
  end
  else
    inherited PresentPixels(dirtyX, dirtyY, dirtyW, dirtyH, isPartial);
end;

initialization

finalization
  if GGLESLibHandle <> NilHandle then
  begin
    UnloadLibrary(GGLESLibHandle);
    GGLESLibHandle := NilHandle;
  end;

  if Assigned(GSharedXDisplay) and Assigned(GXCloseDisplay) then
  begin
    GXCloseDisplay(GSharedXDisplay);
    GSharedXDisplay := nil;
    GSharedXRefCount := 0;
  end;

  if GX11LibHandle <> NilHandle then
  begin
    UnloadLibrary(GX11LibHandle);
    GX11LibHandle := NilHandle;
  end;

end.
