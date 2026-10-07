#define _POSIX_C_SOURCE 199309L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include "ft.h"

#define MAX_PARTICLES 50000
#define PI 3.14159265358979323846

/* ─── Particle Structure ───────────────────────────────────────────────── */
typedef struct {
    float x, y;
    float vx, vy;
    float life;
    float max_life;
    float size;
    uint32_t color;
} Particle;

static Particle g_particles[MAX_PARTICLES];
static int32_t  g_particle_count = 10000;
static int32_t  g_mode = 0; /* 0: Galaxy, 1: Swarm/Attractor, 2: Bounce, 3: Fireworks */
static int32_t  g_vsync = 0; /* 0: Uncapped, 1: 60Hz Lock */
static int32_t  g_show_splines = 1;
static int32_t  g_show_polygon = 1;
static int32_t  g_aa_fringe = 1;

/* Mouse Interaction State */
static float   g_mouse_x = 512.0f;
static float   g_mouse_y = 384.0f;
static int32_t g_mouse_down = 0;
static int32_t g_mouse_btn = 0; /* 1: Left (Attract), 3: Right (Repel) */

/* Performance Metrics */
static double   g_fps = 0.0;
static double   g_frame_time_ms = 0.0;
static uint32_t g_frame_counter = 0;
static double   g_last_time_sec = 0.0;
static double   g_fps_timer = 0.0;
static uint32_t g_draw_calls = 0;
static uint32_t g_vertex_count = 0;
static double   g_start_time_sec = 0.0;
static int32_t  g_auto_exit_sec = 0;

/* Toolkit and GPU handles */
static FtWidget         g_win = NULL;
static FtRenderBatch    g_batch = NULL;
static FtGPUTessellator g_tess = NULL;
static FtTessMesh       g_mesh_spline = NULL;
static FtTessMesh       g_mesh_poly = NULL;
static FtGPURenderer    g_renderer = NULL;

/* ─── Time Helper ──────────────────────────────────────────────────────── */
static double get_time_sec(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec * 1e-9;
}

/* ─── Color Helper (ARGB) ──────────────────────────────────────────────── */
static inline uint32_t make_argb(uint8_t a, uint8_t r, uint8_t g, uint8_t b) {
    return ((uint32_t)a << 24) | ((uint32_t)r << 16) | ((uint32_t)g << 8) | (uint32_t)b;
}

static inline uint32_t hsv_to_argb(float h, float s, float v, float a) {
    float c = v * s;
    float x = c * (1.0f - fabsf(fmodf(h / 60.0f, 2.0f) - 1.0f));
    float m = v - c;
    float r = 0, g = 0, b = 0;
    if (h < 60)      { r = c; g = x; b = 0; }
    else if (h < 120){ r = x; g = c; b = 0; }
    else if (h < 180){ r = 0; g = c; b = x; }
    else if (h < 240){ r = 0; g = x; b = c; }
    else if (h < 300){ r = x; g = 0; b = c; }
    else             { r = c; g = 0; b = x; }
    return make_argb((uint8_t)(a * 255.0f),
                     (uint8_t)((r + m) * 255.0f),
                     (uint8_t)((g + m) * 255.0f),
                     (uint8_t)((b + m) * 255.0f));
}

/* ─── Particle Initialization ─────────────────────────────────────────── */
static void init_particles(void) {
    float cx = 512.0f;
    float cy = 384.0f;

    for (int i = 0; i < MAX_PARTICLES; i++) {
        Particle* p = &g_particles[i];
        p->size = 2.0f + (float)(rand() % 3);
        p->life = 1.0f;
        p->max_life = 1.0f + ((float)(rand() % 100) / 50.0f);

        if (g_mode == 0) {
            /* Cosmic Galaxy: Spiral distribution */
            float angle = ((float)(rand() % 10000) / 10000.0f) * 2.0f * (float)PI;
            float dist = 20.0f + sqrtf((float)(rand() % 10000) / 10000.0f) * 360.0f;
            float spiral = angle + dist * 0.015f;
            p->x = cx + cosf(spiral) * dist;
            p->y = cy + sinf(spiral) * dist;

            float speed = sqrtf(12000.0f / (dist + 30.0f));
            p->vx = -sinf(spiral) * speed;
            p->vy =  cosf(spiral) * speed;

            float hue = fmodf(180.0f + dist * 0.4f, 360.0f);
            p->color = hsv_to_argb(hue, 0.85f, 1.0f, 0.9f);
        } else if (g_mode == 1) {
            /* Swarm / Attractor */
            p->x = cx + ((float)(rand() % 800) - 400.0f);
            p->y = cy + ((float)(rand() % 600) - 300.0f);
            p->vx = ((float)(rand() % 100) - 50.0f) * 0.5f;
            p->vy = ((float)(rand() % 100) - 50.0f) * 0.5f;
            p->color = hsv_to_argb(200.0f + (float)(rand() % 80), 0.8f, 1.0f, 0.85f);
        } else if (g_mode == 2) {
            /* Bouncing Physics Orbs */
            p->x = 50.0f + (float)(rand() % 924);
            p->y = 50.0f + (float)(rand() % 668);
            p->vx = ((float)(rand() % 400) - 200.0f);
            p->vy = ((float)(rand() % 400) - 200.0f);
            p->color = hsv_to_argb((float)(rand() % 360), 0.9f, 1.0f, 0.9f);
        } else {
            /* Fireworks bursts */
            p->x = cx;
            p->y = cy;
            float a = ((float)(rand() % 10000) / 10000.0f) * 2.0f * (float)PI;
            float spd = 20.0f + (float)(rand() % 250);
            p->vx = cosf(a) * spd;
            p->vy = sinf(a) * spd;
            p->color = hsv_to_argb((float)(rand() % 360), 0.9f, 1.0f, 1.0f);
        }
    }
}

/* ─── Simulation Update Step ───────────────────────────────────────────── */
static void update_particles(float dt, int32_t width, int32_t height) {
    float cx = (float)width * 0.5f;
    float cy = (float)height * 0.5f;

    for (int i = 0; i < g_particle_count; i++) {
        Particle* p = &g_particles[i];

        if (g_mode == 0) {
            /* Galaxy Central Gravitation */
            float dx = cx - p->x;
            float dy = cy - p->y;
            float distSq = dx * dx + dy * dy + 400.0f;
            float invDist = 1.0f / sqrtf(distSq);
            float force = 180000.0f / distSq;
            p->vx += dx * invDist * force * dt;
            p->vy += dy * invDist * force * dt;

            p->x += p->vx * dt;
            p->y += p->vy * dt;
        } else if (g_mode == 1) {
            /* Swarm & Mouse Attractor / Repulsor */
            float target_x = g_mouse_x;
            float target_y = g_mouse_y;
            float dx = target_x - p->x;
            float dy = target_y - p->y;
            float distSq = dx * dx + dy * dy + 250.0f;
            float invDist = 1.0f / sqrtf(distSq);

            float strength = 120000.0f;
            if (g_mouse_down) {
                if (g_mouse_btn == 3) {
                    /* Repel */
                    strength = -350000.0f;
                } else {
                    /* Intense attract */
                    strength = 450000.0f;
                }
            }
            float force = strength / distSq;
            p->vx += dx * invDist * force * dt;
            p->vy += dy * invDist * force * dt;

            /* Friction / Damping */
            p->vx *= (1.0f - 1.2f * dt);
            p->vy *= (1.0f - 1.2f * dt);

            p->x += p->vx * dt;
            p->y += p->vy * dt;
        } else if (g_mode == 2) {
            /* Bouncing physics with gravity */
            p->vy += 250.0f * dt; /* Gravity */
            p->x += p->vx * dt;
            p->y += p->vy * dt;

            if (p->x < 10.0f) { p->x = 10.0f; p->vx = -p->vx * 0.95f; }
            if (p->x > (float)width - 10.0f) { p->x = (float)width - 10.0f; p->vx = -p->vx * 0.95f; }
            if (p->y < 10.0f) { p->y = 10.0f; p->vy = -p->vy * 0.95f; }
            if (p->y > (float)height - 10.0f) { p->y = (float)height - 10.0f; p->vy = -p->vy * 0.95f; }
        } else {
            /* Fireworks */
            p->vy += 80.0f * dt;
            p->x += p->vx * dt;
            p->y += p->vy * dt;
            p->life -= dt * 0.6f;
            if (p->life <= 0.0f) {
                p->life = 1.0f;
                p->x = cx + ((float)(rand() % 600) - 300.0f);
                p->y = cy + ((float)(rand() % 400) - 200.0f);
                float a = ((float)(rand() % 10000) / 10000.0f) * 2.0f * (float)PI;
                float spd = 40.0f + (float)(rand() % 220);
                p->vx = cosf(a) * spd;
                p->vy = sinf(a) * spd;
                p->color = hsv_to_argb((float)(rand() % 360), 0.9f, 1.0f, 1.0f);
            }
        }
    }
}

/* ─── Lightweight Vector Monospace Font Table (5x7) ────────────────────── */
static const uint8_t FONT_5X7[128][5] = {
    [' '] = { 0x00, 0x00, 0x00, 0x00, 0x00 },
    [':'] = { 0x00, 0x36, 0x36, 0x00, 0x00 },
    ['.'] = { 0x00, 0x60, 0x60, 0x00, 0x00 },
    ['-'] = { 0x08, 0x08, 0x08, 0x08, 0x08 },
    ['/'] = { 0x60, 0x18, 0x06, 0x01, 0x00 },
    ['%'] = { 0x62, 0x64, 0x08, 0x13, 0x23 },
    ['('] = { 0x00, 0x3E, 0x41, 0x00, 0x00 },
    [')'] = { 0x00, 0x41, 0x3E, 0x00, 0x00 },
    ['['] = { 0x00, 0x7F, 0x41, 0x00, 0x00 },
    [']'] = { 0x00, 0x41, 0x7F, 0x00, 0x00 },
    ['0'] = { 0x3E, 0x51, 0x49, 0x45, 0x3E },
    ['1'] = { 0x00, 0x42, 0x7F, 0x40, 0x00 },
    ['2'] = { 0x62, 0x51, 0x49, 0x49, 0x46 },
    ['3'] = { 0x22, 0x49, 0x49, 0x49, 0x36 },
    ['4'] = { 0x18, 0x14, 0x12, 0x7F, 0x10 },
    ['5'] = { 0x2F, 0x49, 0x49, 0x49, 0x31 },
    ['6'] = { 0x3E, 0x49, 0x49, 0x49, 0x32 },
    ['7'] = { 0x01, 0x71, 0x09, 0x05, 0x03 },
    ['8'] = { 0x36, 0x49, 0x49, 0x49, 0x36 },
    ['9'] = { 0x26, 0x49, 0x49, 0x49, 0x3E },
    ['A'] = { 0x7E, 0x11, 0x11, 0x11, 0x7E },
    ['B'] = { 0x7F, 0x49, 0x49, 0x49, 0x36 },
    ['C'] = { 0x3E, 0x41, 0x41, 0x41, 0x22 },
    ['D'] = { 0x7F, 0x41, 0x41, 0x41, 0x3E },
    ['E'] = { 0x7F, 0x49, 0x49, 0x49, 0x41 },
    ['F'] = { 0x7F, 0x09, 0x09, 0x09, 0x01 },
    ['G'] = { 0x3E, 0x41, 0x49, 0x49, 0x7A },
    ['H'] = { 0x7F, 0x08, 0x08, 0x08, 0x7F },
    ['I'] = { 0x00, 0x41, 0x7F, 0x41, 0x00 },
    ['J'] = { 0x20, 0x40, 0x41, 0x3F, 0x01 },
    ['K'] = { 0x7F, 0x08, 0x14, 0x22, 0x41 },
    ['L'] = { 0x7F, 0x40, 0x40, 0x40, 0x40 },
    ['M'] = { 0x7F, 0x02, 0x0C, 0x02, 0x7F },
    ['N'] = { 0x7F, 0x04, 0x08, 0x10, 0x7F },
    ['O'] = { 0x3E, 0x41, 0x41, 0x41, 0x3E },
    ['P'] = { 0x7F, 0x09, 0x09, 0x09, 0x06 },
    ['Q'] = { 0x3E, 0x41, 0x51, 0x21, 0x5E },
    ['R'] = { 0x7F, 0x09, 0x19, 0x29, 0x46 },
    ['S'] = { 0x46, 0x49, 0x49, 0x49, 0x31 },
    ['T'] = { 0x01, 0x01, 0x7F, 0x01, 0x01 },
    ['U'] = { 0x3F, 0x40, 0x40, 0x40, 0x3F },
    ['V'] = { 0x0F, 0x30, 0x40, 0x30, 0x0F },
    ['W'] = { 0x7F, 0x20, 0x18, 0x20, 0x7F },
    ['X'] = { 0x63, 0x14, 0x08, 0x14, 0x63 },
    ['Y'] = { 0x07, 0x08, 0x70, 0x08, 0x07 },
    ['Z'] = { 0x61, 0x51, 0x49, 0x45, 0x43 }
};

static void draw_hud_text(FtRenderBatch batch, float start_x, float start_y, const char* text,
                          uint32_t color, float scale) {
    float cur_x = start_x;
    float cur_y = start_y;
    int len = (int)strlen(text);

    for (int i = 0; i < len; i++) {
        char ch = text[i];
        if (ch >= 'a' && ch <= 'z') ch = ch - 'a' + 'A';
        if (ch == '\n') {
            cur_y += 10.0f * scale;
            cur_x = start_x;
            continue;
        }

        const uint8_t* col_data = FONT_5X7[(uint8_t)ch];
        for (int c = 0; c < 5; c++) {
            uint8_t bits = col_data[c];
            for (int r = 0; r < 7; r++) {
                if ((bits >> r) & 1) {
                    ft_batch_emit_rect(batch,
                                       cur_x + (float)c * scale,
                                       cur_y + (float)r * scale,
                                       scale, scale,
                                       color, FT_BLEND_SRCOVER);
                }
            }
        }
        cur_x += 6.0f * scale;
    }
}

/* ─── Procedural Vector Spline Ribbon Wave ─────────────────────────────── */
static void render_spline_ribbons(FtRenderBatch batch, FtGPUTessellator tess, FtTessMesh mesh,
                                  float time_sec, int32_t width, int32_t height) {
    if (!g_show_splines) return;

    ft_tessmesh_clear(mesh);

    float base_y = (float)height * 0.78f;
    float amp1 = 55.0f * sinf(time_sec * 1.5f);
    float amp2 = 65.0f * cosf(time_sec * 1.8f);

    /* Spline 1: Primary Wave */
    ft_tessellator_stroke_bezier(tess, mesh,
                                 0.0f, base_y + amp1,
                                 (float)width * 0.33f, base_y - amp2,
                                 (float)width * 0.66f, base_y + amp2 * 1.2f,
                                 (float)width, base_y - amp1,
                                 6.0f, FT_JOIN_ROUND, FT_CAP_ROUND, 4.0f, g_aa_fringe);

    /* Spline 2: Harmonic Ribbon */
    ft_tessellator_stroke_bezier(tess, mesh,
                                 0.0f, base_y - amp2,
                                 (float)width * 0.28f, base_y + amp1 * 1.4f,
                                 (float)width * 0.72f, base_y - amp1 * 1.1f,
                                 (float)width, base_y + amp2,
                                 4.0f, FT_JOIN_ROUND, FT_CAP_ROUND, 4.0f, g_aa_fringe);

    /* Emit tessellated spline mesh into the coalesced batch */
    ft_batch_emit_path_mesh(batch, mesh, make_argb(220, 56, 189, 248), FT_BLEND_SRCOVER);
}

/* ─── Procedural Rotating 12-Point Star Polygon ────────────────────────── */
static void render_polygon_star(FtRenderBatch batch, FtGPUTessellator tess, FtTessMesh mesh,
                                float time_sec, int32_t width, int32_t height) {
    if (!g_show_polygon) return;

    ft_tessmesh_clear(mesh);

    float cx = (float)width - 140.0f;
    float cy = 140.0f;
    int points_count = 24;
    FtPoint2D star_pts[24];
    float rot = time_sec * 0.8f;

    for (int i = 0; i < points_count; i++) {
        float angle = rot + ((float)i / (float)points_count) * 2.0f * (float)PI;
        float r = (i % 2 == 0) ? 60.0f : 28.0f;
        star_pts[i].x = cx + cosf(angle) * r;
        star_pts[i].y = cy + sinf(angle) * r;
    }

    /* 1. Triangulate and Fill Polygon */
    ft_tessellator_fill_polygon(tess, mesh, star_pts, points_count, g_aa_fringe);
    ft_batch_emit_path_mesh(batch, mesh, make_argb(180, 244, 63, 94), FT_BLEND_SRCOVER);

    /* 2. Stroke Polygon Outline with 1px Analytic AA Fringe Skirt */
    ft_tessmesh_clear(mesh);
    ft_tessellator_stroke_polyline(tess, mesh, star_pts, points_count, 1,
                                   2.5f, FT_JOIN_MITER, FT_CAP_BUTT, 4.0f, g_aa_fringe);
    ft_batch_emit_path_mesh(batch, mesh, make_argb(255, 255, 255, 255), FT_BLEND_SRCOVER);
}

/* ─── SDF Glassmorphic HUD & Diagnostics Card ──────────────────────────── */
static void render_hud_overlay(FtRenderBatch batch, int32_t width, int32_t height) {
    (void)height;
    /* 1. Frosted Glass Diagnostics Card (Top-Left) */
    float card_w = 420.0f;
    float card_h = 195.0f;
    float card_x = 24.0f;
    float card_y = 24.0f;

    /* Drop Shadow */
    ft_batch_emit_box_shadow(batch, card_x, card_y, card_w, card_h, 16.0f,
                             0.0f, 10.0f, 28.0f, 0.0f,
                             make_argb(170, 0, 0, 0), FT_BLEND_SRCOVER);

    /* SDF Rounded Rect Glass Panel with Glowing Border */
    ft_batch_emit_rounded_rect(batch, card_x, card_y, card_w, card_h, 16.0f,
                               make_argb(210, 15, 23, 42),   /* Deep Dark Slate Fill */
                               make_argb(120, 56, 189, 248),  /* Electric Sky Blue Border */
                               1.5f, FT_BLEND_SRCOVER);

    /* HUD Header Title */
    draw_hud_text(batch, card_x + 20.0f, card_y + 18.0f,
                  "FLORIA GPU VECTOR CORE - STRESS TEST",
                  make_argb(255, 248, 250, 252), 1.6f);

    /* Metrics Lines */
    char line[128];
    snprintf(line, sizeof(line), "FPS: %.1f  (FRAME: %.2f MS)", g_fps, g_frame_time_ms);
    draw_hud_text(batch, card_x + 20.0f, card_y + 45.0f, line,
                  make_argb(255, 74, 222, 128), 1.5f);

    snprintf(line, sizeof(line), "ENTITIES: %d PARTICLES", g_particle_count);
    draw_hud_text(batch, card_x + 20.0f, card_y + 70.0f, line,
                  make_argb(255, 56, 189, 248), 1.4f);

    snprintf(line, sizeof(line), "GPU DRAW CALLS: %u (COALESCED)", g_draw_calls);
    draw_hud_text(batch, card_x + 20.0f, card_y + 92.0f, line,
                  make_argb(255, 251, 191, 36), 1.4f);

    snprintf(line, sizeof(line), "VERTICES: %u", g_vertex_count);
    draw_hud_text(batch, card_x + 20.0f, card_y + 114.0f, line,
                  make_argb(255, 203, 213, 225), 1.3f);

    const char* mode_name = "COSMIC GALAXY VORTEX";
    if (g_mode == 1) mode_name = "SWARM / BOIDS ATTRACTOR";
    else if (g_mode == 2) mode_name = "KINETIC BOUNCE ORBS";
    else if (g_mode == 3) mode_name = "SUPERNOVA BURSTS";
    snprintf(line, sizeof(line), "MODE: %s", mode_name);
    draw_hud_text(batch, card_x + 20.0f, card_y + 135.0f, line,
                  make_argb(255, 232, 121, 249), 1.3f);

    snprintf(line, sizeof(line), "VSYNC: %s  AA FRINGE: %s",
             g_vsync ? "LOCKED (60 HZ)" : "UNCAPPED (MAX)",
             g_aa_fringe ? "ON (1PX ANALYTIC)" : "OFF");
    draw_hud_text(batch, card_x + 20.0f, card_y + 158.0f, line,
                  make_argb(255, 148, 163, 184), 1.3f);

    /* 2. Keybinds Guide Card (Bottom-Left) */
    float k_w = 460.0f;
    float k_h = 105.0f;
    float k_x = 24.0f;
    float k_y = (float)height - k_h - 24.0f;

    ft_batch_emit_box_shadow(batch, k_x, k_y, k_w, k_h, 12.0f,
                             0.0f, 6.0f, 18.0f, 0.0f,
                             make_argb(150, 0, 0, 0), FT_BLEND_SRCOVER);
    ft_batch_emit_rounded_rect(batch, k_x, k_y, k_w, k_h, 12.0f,
                               make_argb(200, 15, 23, 42),
                               make_argb(80, 255, 255, 255),
                               1.0f, FT_BLEND_SRCOVER);

    draw_hud_text(batch, k_x + 16.0f, k_y + 14.0f,
                  "[1-5] COUNT: 1K / 5K / 10K / 20K / 50K",
                  make_argb(255, 226, 232, 240), 1.3f);
    draw_hud_text(batch, k_x + 16.0f, k_y + 34.0f,
                  "[M/SPACE] MODE  [V] VSYNC  [A] AA FRINGE",
                  make_argb(255, 226, 232, 240), 1.3f);
    draw_hud_text(batch, k_x + 16.0f, k_y + 54.0f,
                  "[S] SPLINE RIBBONS  [G] POLYGON STAR",
                  make_argb(255, 226, 232, 240), 1.3f);
    draw_hud_text(batch, k_x + 16.0f, k_y + 74.0f,
                  "[MOUSE L/R] ATTRACT / REPEL PARTICLES",
                  make_argb(255, 56, 189, 248), 1.3f);

    /* 3. Interactive Attractor Ring at Cursor */
    if (g_mode == 1 || g_mouse_down) {
        uint32_t ring_col = (g_mouse_down && g_mouse_btn == 3)
            ? make_argb(200, 239, 68, 68)   /* Red Repel */
            : make_argb(200, 56, 189, 248);  /* Cyan Attract */
        ft_batch_emit_rounded_rect(batch, g_mouse_x - 16.0f, g_mouse_y - 16.0f, 32.0f, 32.0f,
                                   16.0f, make_argb(0, 0, 0, 0), ring_col, 2.0f, FT_BLEND_SRCOVER);
    }
}

/* ─── Main GPU Drawing Callback ────────────────────────────────────────── */
static void on_gl_draw(FtWidget widget, int32_t width, int32_t height, void* user_data) {
    (void)widget;
    (void)user_data;

    double now = get_time_sec();
    float time_sec = (float)now;

    /* Begin GPU Renderer frame */
    ft_renderer_begin(g_renderer, width, height);

    /* Background Void Gradient */
    ft_batch_emit_linear_gradient(g_batch, 0.0f, 0.0f, (float)width, (float)height,
                                  make_argb(255, 5, 8, 22),     /* Deep Midnight Navy */
                                  make_argb(255, 12, 10, 32),    /* Dark Cosmic Indigo */
                                  45.0f, FT_BLEND_SRCOVER);

    /* 1. High-Throughput Particles (Additive Blending) */
    for (int i = 0; i < g_particle_count; i++) {
        Particle* p = &g_particles[i];
        ft_batch_emit_rect(g_batch, p->x, p->y, p->size, p->size,
                           p->color, FT_BLEND_ADDITIVE);
    }

    /* 2. Procedural Vector Spline Ribbons */
    render_spline_ribbons(g_batch, g_tess, g_mesh_spline, time_sec, width, height);

    /* 3. Procedural Rotating Star Polygon */
    render_polygon_star(g_batch, g_tess, g_mesh_poly, time_sec, width, height);

    /* 4. SDF Glassmorphic HUD & Text Diagnostics */
    render_hud_overlay(g_batch, width, height);

    /* Query GPU Batch Statistics */
    FtBatchStats stats;
    ft_batch_get_stats(g_batch, &stats);
    g_draw_calls   = stats.draw_calls;
    g_vertex_count = stats.vertex_count;

    /* End and Flush GPU Renderer frame to screen */
    ft_renderer_end(g_renderer);
}

/* ─── Animation & Performance Tick Loop ────────────────────────────────── */
static void on_tick(void* user_data) {
    (void)user_data;

    double now = get_time_sec();
    if (g_last_time_sec == 0.0) {
        g_last_time_sec = now;
        return;
    }

    float dt = (float)(now - g_last_time_sec);
    if (dt > 0.1f) dt = 0.1f; /* Clamp huge delta on startup or drag */
    g_last_time_sec = now;

    /* Update particle physical simulation */
    update_particles(dt, 1024, 768);

    /* Calculate Smoothed FPS */
    g_frame_counter++;
    g_fps_timer += dt;
    if (g_fps_timer >= 0.5) {
        g_fps = (double)g_frame_counter / g_fps_timer;
        g_frame_time_ms = (g_fps_timer / (double)g_frame_counter) * 1000.0;
        printf("[Live GPU HUD] FPS: %6.1f (%5.2f ms) | Entities: %5d | Draw Calls: %u | Vertices: %u | VSync: %s\n",
               g_fps, g_frame_time_ms, g_particle_count, g_draw_calls, g_vertex_count,
               g_vsync ? "ON (60Hz)" : "OFF (Uncapped)");
        fflush(stdout);
        g_frame_counter = 0;
        g_fps_timer = 0.0;
    }

    if (g_auto_exit_sec > 0 && (now - g_start_time_sec) >= (double)g_auto_exit_sec) {
        printf("[INFO] Benchmark duration reached (%d seconds). Exiting...\n", g_auto_exit_sec);
        ft_quit();
        return;
    }

    /* Request zero-latency GPU repaint */
    ft_widget_invalidate(g_win);
}

/* ─── Interactive Mouse Callbacks ──────────────────────────────────────── */
static void on_mouse_down(FtWidget window, int32_t x, int32_t y, int32_t button, void* user_data) {
    (void)window;
    (void)user_data;
    g_mouse_x = (float)x;
    g_mouse_y = (float)y;
    g_mouse_down = 1;
    g_mouse_btn = button;
}

static void on_mouse_up(FtWidget window, int32_t x, int32_t y, int32_t button, void* user_data) {
    (void)window;
    (void)button;
    (void)user_data;
    g_mouse_x = (float)x;
    g_mouse_y = (float)y;
    g_mouse_down = 0;
}

static void on_mouse_move(FtWidget window, int32_t x, int32_t y, void* user_data) {
    (void)window;
    (void)user_data;
    g_mouse_x = (float)x;
    g_mouse_y = (float)y;
}

/* ─── Interactive Keybinds ─────────────────────────────────────────────── */
static void on_key(FtWidget window, uint32_t key, int32_t is_down, void* user_data) {
    (void)window;
    (void)user_data;
    if (!is_down) return;

    if (key == '1') {
        g_particle_count = 1000;
        printf("[Stress Test] Particle count: 1,000\n");
    } else if (key == '2') {
        g_particle_count = 5000;
        printf("[Stress Test] Particle count: 5,000\n");
    } else if (key == '3') {
        g_particle_count = 10000;
        printf("[Stress Test] Particle count: 10,000\n");
    } else if (key == '4') {
        g_particle_count = 20000;
        printf("[Stress Test] Particle count: 20,000\n");
    } else if (key == '5') {
        g_particle_count = 50000;
        printf("[Stress Test] Particle count: 50,000\n");
    } else if (key == 'm' || key == 'M' || key == 32 /* Space */) {
        g_mode = (g_mode + 1) % 4;
        init_particles();
        printf("[Stress Test] Switched mode: %d\n", g_mode);
    } else if (key == 'v' || key == 'V') {
        g_vsync = !g_vsync;
        ft_window_set_swap_interval(g_win, g_vsync);
        printf("[Stress Test] VSync toggled: %s\n", g_vsync ? "LOCKED (60Hz)" : "UNCAPPED (Max)");
    } else if (key == 'a' || key == 'A') {
        g_aa_fringe = !g_aa_fringe;
        printf("[Stress Test] AA Fringe toggled: %s\n", g_aa_fringe ? "ON" : "OFF");
    } else if (key == 's' || key == 'S') {
        g_show_splines = !g_show_splines;
        printf("[Stress Test] Bezier Splines toggled: %s\n", g_show_splines ? "ON" : "OFF");
    } else if (key == 'g' || key == 'G') {
        g_show_polygon = !g_show_polygon;
        printf("[Stress Test] Polygon Star toggled: %s\n", g_show_polygon ? "ON" : "OFF");
    } else if (key == 65307 /* Esc */) {
        printf("[Stress Test] Exiting...\n");
        ft_quit();
    }
}

/* ─── Entry Point ──────────────────────────────────────────────────────── */
int main(int argc, char** argv) {
    int auto_exit_seconds = 0;
    if (argc > 1) {
        auto_exit_seconds = atoi(argv[1]);
        g_auto_exit_sec = auto_exit_seconds;
    }
    if (argc > 2) {
        int cnt = atoi(argv[2]);
        if (cnt > 0 && cnt <= MAX_PARTICLES) g_particle_count = cnt;
    }
    if (argc > 3) {
        int m = atoi(argv[3]);
        if (m >= 0 && m <= 3) g_mode = m;
    }
    if (argc > 4) {
        g_vsync = atoi(argv[4]) ? 1 : 0;
    }
    g_start_time_sec = get_time_sec();

    printf("===================================================================\n");
    printf("Floria Toolkit — GPU Vector Core & Game Engine Stress Test Demo\n");
    printf("===================================================================\n");

    ft_init();

    if (!ft_egl_is_available() || !ft_gpu_is_available()) {
        fprintf(stderr, "[ERROR] EGL / GPU Vector Core is unavailable on this system!\n");
        return 1;
    }

    ft_backend_enable_egl(1);

    /* Create Direct Hardware-Accelerated EGL Window */
    g_win = ft_egl_window_create(1024, 768, "Floria Toolkit — GPU Vector Core & Game Engine Stress Test");
    if (!g_win) {
        fprintf(stderr, "[ERROR] Failed to create EGL window!\n");
        return 1;
    }

    /* Enable Direct GPU Pipeline (bypassing CPU software surface completely) */
    ft_window_set_direct_gpu_mode(g_win, 1);
    ft_window_set_swap_interval(g_win, g_vsync);

    /* Initialize GPU Renderer & Geometry Allocations */
    g_renderer = ft_renderer_create();
    if (!g_renderer) {
        fprintf(stderr, "[ERROR] Failed to initialize Floria GPU Renderer!\n");
        return 1;
    }

    g_batch       = ft_renderer_get_batch(g_renderer);
    g_tess        = ft_renderer_get_tessellator(g_renderer);
    g_mesh_spline = ft_tessmesh_create();
    g_mesh_poly   = ft_tessmesh_create();

    /* Wire up Event and Rendering Callbacks */
    ft_window_on_gl_draw(g_win, on_gl_draw, NULL);
    ft_window_on_mouse_down(g_win, on_mouse_down, NULL);
    ft_window_on_mouse_up(g_win, on_mouse_up, NULL);
    ft_window_on_mouse_move(g_win, on_mouse_move, NULL);
    ft_window_on_key(g_win, on_key, NULL);

    /* Populate initial particle simulation state */
    init_particles();

    /* Register continuous animation / game loop tick */
    ft_set_tick_callback(on_tick, NULL);

    ft_widget_show(g_win);

    printf("[INFO] Window initialized successfully (1024x768 Direct GPU Mode).\n");
    printf("[INFO] Active Particles: %d\n", g_particle_count);
    printf("[INFO] Press [1-5] for particle scaling, [M] for modes, [V] for VSync toggle.\n");

    if (auto_exit_seconds > 0) {
        printf("[INFO] Running benchmark demo for %d seconds...\n", auto_exit_seconds);
    }

    ft_main_loop();

    /* Cleanup */
    ft_tessmesh_destroy(g_mesh_spline);
    ft_tessmesh_destroy(g_mesh_poly);
    ft_renderer_destroy(g_renderer);

    printf("[INFO] Demo closed cleanly.\n");
    return 0;
}
