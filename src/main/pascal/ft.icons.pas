unit Ft.Icons;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes,
  Floria.Image.Core, Floria.SVG.DOM, Floria.SVG.Parser, Floria.SVG.Rasterizer;

{ ────────────────────────── Default SVG Icon Constants ────────────────────────── }

const
  { Navigation Icons }
  FT_ICON_NAV_BACK =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 10 3 L 5 8 L 10 13" fill="none" stroke="#64748b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>' +
    '</svg>';

  FT_ICON_NAV_FORWARD =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 6 3 L 11 8 L 6 13" fill="none" stroke="#64748b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>' +
    '</svg>';

  FT_ICON_NAV_UP =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 3 10 L 8 5 L 13 10" fill="none" stroke="#64748b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>' +
    '</svg>';

  FT_ICON_NEW_FOLDER =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 1.5 3.5 C 1.5 2.7 2.2 2 3 2 L 6 2 L 7.5 3.5 L 13 3.5 C 13.8 3.5 14.5 4.2 14.5 5 L 14.5 12.5 C 14.5 13.3 13.8 14 13 14 L 3 14 C 2.2 14 1.5 13.3 1.5 12.5 Z" fill="none" stroke="#64748b" stroke-width="1.5" stroke-linejoin="round"/>' +
    '<path d="M 8 6.5 L 8 11.5 M 5.5 9 L 10.5 9" stroke="#64748b" stroke-width="1.5" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_HIDDEN =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 1 8 C 3 4 5.5 2.5 8 2.5 C 10.5 2.5 13 4 15 8 C 13 12 10.5 13.5 8 13.5 C 5.5 13.5 3 12 1 8 Z" fill="none" stroke="#64748b" stroke-width="1.5"/>' +
    '<circle cx="8" cy="8" r="2.5" fill="#64748b"/>' +
    '</svg>';

  { File & Directory Items }
  FT_ICON_FOLDER =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 1 3.5 C 1 2.7 1.7 2 2.5 2 L 6 2 L 7.5 3.5 L 13.5 3.5 C 14.3 3.5 15 4.2 15 5 L 15 12.5 C 15 13.3 14.3 14 13.5 14 L 2.5 14 C 1.7 14 1 13.3 1 12.5 Z" fill="#eab308"/>' +
    '</svg>';

  FT_ICON_FILE =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 3 1.5 C 3 1.2 3.2 1 3.5 1 L 9.5 1 L 13 4.5 L 13 14.5 C 13 14.8 12.8 15 12.5 15 L 3.5 15 C 3.2 15 3 14.8 3 14.5 Z" fill="#94a3b8"/>' +
    '<path d="M 9.5 1 L 9.5 4.5 L 13 4.5 Z" fill="#cbd5e1"/>' +
    '</svg>';

  FT_ICON_FILE_IMAGE =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 3 1.5 C 3 1.2 3.2 1 3.5 1 L 9.5 1 L 13 4.5 L 13 14.5 C 13 14.8 12.8 15 12.5 15 L 3.5 15 C 3.2 15 3 14.8 3 14.5 Z" fill="#38bdf8"/>' +
    '<path d="M 9.5 1 L 9.5 4.5 L 13 4.5 Z" fill="#bae6fd"/>' +
    '<circle cx="5.5" cy="6.5" r="1.2" fill="#ffffff"/>' +
    '<path d="M 4 12 L 6.5 8.5 L 8.5 10.5 L 10.5 7.5 L 12 12 Z" fill="#ffffff"/>' +
    '</svg>';

  FT_ICON_FILE_CODE =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 3 1.5 C 3 1.2 3.2 1 3.5 1 L 9.5 1 L 13 4.5 L 13 14.5 C 13 14.8 12.8 15 12.5 15 L 3.5 15 C 3.2 15 3 14.8 3 14.5 Z" fill="#6366f1"/>' +
    '<path d="M 9.5 1 L 9.5 4.5 L 13 4.5 Z" fill="#c7d2fe"/>' +
    '<path d="M 6 8 L 4.5 9.5 L 6 11 M 10 8 L 11.5 9.5 L 10 11" stroke="#ffffff" stroke-width="1.2" stroke-linecap="round" fill="none"/>' +
    '</svg>';

  FT_ICON_FILE_ARCHIVE =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 3 1.5 C 3 1.2 3.2 1 3.5 1 L 9.5 1 L 13 4.5 L 13 14.5 C 13 14.8 12.8 15 12.5 15 L 3.5 15 C 3.2 15 3 14.8 3 14.5 Z" fill="#f97316"/>' +
    '<path d="M 9.5 1 L 9.5 4.5 L 13 4.5 Z" fill="#fed7aa"/>' +
    '<rect x="7" y="6" width="2" height="1" fill="#ffffff"/>' +
    '<rect x="7" y="8" width="2" height="1" fill="#ffffff"/>' +
    '<rect x="6.5" y="10" width="3" height="3" rx="0.5" fill="#ffffff"/>' +
    '</svg>';

  { Places Icons }
  FT_ICON_PLACE_HOME =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 2 7 L 8 2 L 14 7 L 14 13.5 C 14 13.8 13.8 14 13.5 14 L 9.5 14 L 9.5 9.5 L 6.5 9.5 L 6.5 14 L 2.5 14 C 2.2 14 2 13.8 2 13.5 Z" fill="#3b82f6"/>' +
    '</svg>';

  FT_ICON_PLACE_DESKTOP =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<rect x="1.5" y="2" width="13" height="9" rx="1" fill="none" stroke="#64748b" stroke-width="1.4"/>' +
    '<path d="M 5 14 L 11 14 M 8 11 L 8 14" stroke="#64748b" stroke-width="1.4" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_PLACE_DOCUMENTS =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 3 1.5 C 3 1.2 3.2 1 3.5 1 L 9.5 1 L 13 4.5 L 13 14.5 C 13 14.8 12.8 15 12.5 15 L 3.5 15 C 3.2 15 3 14.8 3 14.5 Z" fill="#0ea5e9"/>' +
    '<path d="M 9.5 1 L 9.5 4.5 L 13 4.5 Z" fill="#bae6fd"/>' +
    '<path d="M 5.5 7 L 10.5 7 M 5.5 9.5 L 10.5 9.5 M 5.5 12 L 9 12" stroke="#ffffff" stroke-width="1.2" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_PLACE_DOWNLOADS =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<circle cx="8" cy="8" r="7" fill="#10b981"/>' +
    '<path d="M 8 4 L 8 10.5 M 5.5 8.5 L 8 11 L 10.5 8.5" fill="none" stroke="#ffffff" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>' +
    '</svg>';

  FT_ICON_PLACE_PICTURES =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<rect x="1.5" y="2" width="13" height="11" rx="1.5" fill="#8b5cf6"/>' +
    '<circle cx="5" cy="5.5" r="1.2" fill="#ffffff"/>' +
    '<path d="M 3 11 L 6.5 7 L 9 9.5 L 11 7.5 L 13 10 L 13 12 C 13 12.5 12.5 13 12 13 L 4 13 C 3.5 13 3 12.5 3 12 Z" fill="#ffffff"/>' +
    '</svg>';

  FT_ICON_PLACE_MUSIC =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<circle cx="8" cy="8" r="7" fill="#ec4899"/>' +
    '<path d="M 6 10 C 6 10.8 5.3 11.5 4.5 11.5 C 3.7 11.5 3 10.8 3 10 C 3 9.2 3.7 8.5 4.5 8.5 C 4.8 8.5 5 8.6 5.2 8.7 L 5.2 4.5 L 11 3.5 L 11 8 C 11 8.8 10.3 9.5 9.5 9.5 C 8.7 9.5 8 8.8 8 8 C 8 7.2 8.7 6.5 9.5 6.5 C 9.8 6.5 10 6.6 10.2 6.7 L 10.2 4.5 L 6 5.2 Z" fill="#ffffff"/>' +
    '</svg>';

  FT_ICON_PLACE_DRIVE =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<rect x="1.5" y="4" width="13" height="8" rx="1.5" fill="#64748b"/>' +
    '<circle cx="11.5" cy="8" r="1" fill="#22c55e"/>' +
    '<path d="M 3.5 8 L 8.5 8" stroke="#ffffff" stroke-width="1.2" stroke-linecap="round"/>' +
    '</svg>';

  { Outline Icons (macOS Style) }
  FT_ICON_OUTLINE_HOME =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 2 7.5 L 8 2.5 L 14 7.5" fill="none" stroke="#64748b" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>' +
    '<path d="M 3.5 7 L 3.5 13.5 C 3.5 13.8 3.7 14 4 14 L 12 14 C 12.3 14 12.5 13.8 12.5 13.5 L 12.5 7" fill="none" stroke="#64748b" stroke-width="1.4" stroke-linecap="round"/>' +
    '<path d="M 6.5 14 L 6.5 10.5 C 6.5 10.2 6.7 10 7 10 L 9 10 C 9.3 10 9.5 10.2 9.5 10.5 L 9.5 14" fill="none" stroke="#64748b" stroke-width="1.3"/>' +
    '</svg>';

  FT_ICON_OUTLINE_DESKTOP =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<rect x="1.5" y="2" width="13" height="9.5" rx="1.5" fill="none" stroke="#64748b" stroke-width="1.4"/>' +
    '<path d="M 5.5 14 L 10.5 14 M 8 11.5 L 8 14" stroke="#64748b" stroke-width="1.4" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_OUTLINE_DOCUMENTS =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 3.5 1.5 L 9.5 1.5 L 13 5 L 13 14 C 13 14.3 12.8 14.5 12.5 14.5 L 3.5 14.5 C 3.2 14.5 3 14.3 3 14 L 3 2 C 3 1.7 3.2 1.5 3.5 1.5 Z" fill="none" stroke="#64748b" stroke-width="1.4" stroke-linejoin="round"/>' +
    '<path d="M 9.5 1.5 L 9.5 5 L 13 5" fill="none" stroke="#64748b" stroke-width="1.3" stroke-linejoin="round"/>' +
    '<path d="M 5.5 8 L 10.5 8 M 5.5 10.5 L 9 10.5" stroke="#64748b" stroke-width="1.2" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_OUTLINE_DOWNLOADS =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<circle cx="8" cy="8" r="6.5" fill="none" stroke="#64748b" stroke-width="1.4"/>' +
    '<path d="M 8 4.5 L 8 10.5 M 5.5 8.5 L 8 11 L 10.5 8.5" fill="none" stroke="#64748b" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>' +
    '</svg>';

  FT_ICON_OUTLINE_PICTURES =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<rect x="1.5" y="2.5" width="13" height="11" rx="1.5" fill="none" stroke="#64748b" stroke-width="1.4"/>' +
    '<circle cx="5" cy="6" r="1.2" fill="#64748b"/>' +
    '<path d="M 2.5 12 L 6.5 8 L 9 10.5 L 11 8.5 L 13.5 11" fill="none" stroke="#64748b" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round"/>' +
    '</svg>';

  FT_ICON_OUTLINE_MUSIC =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<circle cx="5" cy="11.5" r="2" fill="none" stroke="#64748b" stroke-width="1.4"/>' +
    '<path d="M 7 11.5 L 7 4.5 C 7 4.5 9 4 12 3 L 12 8" fill="none" stroke="#64748b" stroke-width="1.4" stroke-linecap="round"/>' +
    '<circle cx="10" cy="10" r="1.8" fill="none" stroke="#64748b" stroke-width="1.4"/>' +
    '<path d="M 12 10 L 12 3" stroke="#64748b" stroke-width="1.4"/>' +
    '</svg>';

  FT_ICON_OUTLINE_DRIVE =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<rect x="1.5" y="4.5" width="13" height="7.5" rx="1.5" fill="none" stroke="#64748b" stroke-width="1.4"/>' +
    '<circle cx="11.5" cy="8.25" r="0.9" fill="#64748b"/>' +
    '<path d="M 3.5 8.25 L 9 8.25" stroke="#64748b" stroke-width="1.2" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_OUTLINE_FOLDER =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 1.5 3.5 C 1.5 2.7 2.2 2 3 2 L 6 2 L 7.5 3.5 L 13 3.5 C 13.8 3.5 14.5 4.2 14.5 5 L 14.5 12.5 C 14.5 13.3 13.8 14 13 14 L 3 14 C 2.2 14 1.5 13.3 1.5 12.5 Z" fill="none" stroke="#64748b" stroke-width="1.4" stroke-linejoin="round"/>' +
    '</svg>';

  FT_ICON_OUTLINE_FILE =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 3 1.5 C 3 1.2 3.2 1 3.5 1 L 9.5 1 L 13 4.5 L 13 14.5 C 13 14.8 12.8 15 12.5 15 L 3.5 15 C 3.2 15 3 14.8 3 14.5 Z" fill="none" stroke="#64748b" stroke-width="1.4" stroke-linejoin="round"/>' +
    '<path d="M 9.5 1 L 9.5 4.5 L 13 4.5" fill="none" stroke="#64748b" stroke-width="1.3" stroke-linejoin="round"/>' +
    '</svg>';

  FT_ICON_OUTLINE_TRASH =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 2.5 4.5 L 13.5 4.5 M 5.5 4.5 L 5.5 2.5 C 5.5 2 6 1.5 6.5 1.5 L 9.5 1.5 C 10 1.5 10.5 2 10.5 2.5 L 10.5 4.5" fill="none" stroke="#64748b" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round"/>' +
    '<path d="M 3.5 4.5 L 4.5 14 C 4.5 14.5 5 15 5.5 15 L 10.5 15 C 11 15 11.5 14.5 11.5 14 L 12.5 4.5" fill="none" stroke="#64748b" stroke-width="1.3" stroke-linejoin="round"/>' +
    '<path d="M 6.5 7 L 6.5 12.5 M 9.5 7 L 9.5 12.5" stroke="#64748b" stroke-width="1.2" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_OUTLINE_VIDEOS =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<rect x="1.5" y="2.5" width="13" height="11" rx="1.5" fill="none" stroke="#64748b" stroke-width="1.4"/>' +
    '<path d="M 6.5 5.5 L 11 8 L 6.5 10.5 Z" fill="#64748b"/>' +
    '</svg>';

  FT_ICON_OUTLINE_BOOKMARK =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 3.5 2 C 3.5 1.7 3.7 1.5 4 1.5 L 12 1.5 C 12.3 1.5 12.5 1.7 12.5 2 L 12.5 14.5 L 8 11.5 L 3.5 14.5 Z" fill="none" stroke="#64748b" stroke-width="1.4" stroke-linejoin="round"/>' +
    '</svg>';

  { General UI / Utility Icons }
  FT_ICON_GEAR =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 8 5.5 C 6.6 5.5 5.5 6.6 5.5 8 C 5.5 9.4 6.6 10.5 8 10.5 C 9.4 10.5 10.5 9.4 10.5 8 C 10.5 6.6 9.4 5.5 8 5.5 Z" fill="none" stroke="#64748b" stroke-width="1.3"/>' +
    '<path d="M 7.3 1.5 L 8.7 1.5 L 9 3 C 9.4 3.2 9.8 3.4 10.2 3.7 L 11.6 3.1 L 12.6 4.1 L 12 5.5 C 12.3 5.9 12.5 6.3 12.7 6.7 L 14.2 7 L 14.2 8.4 L 12.7 8.7 C 12.5 9.1 12.3 9.5 12 9.9 L 12.6 11.3 L 11.6 12.3 L 10.2 11.7 C 9.8 12 9.4 12.2 9 12.4 L 8.7 13.9 L 7.3 13.9 L 7 12.4 C 6.6 12.2 6.2 12 5.8 11.7 L 4.4 12.3 L 3.4 11.3 L 4 9.9 C 3.7 9.5 3.5 9.1 3.3 8.7 L 1.8 8.4 L 1.8 7 L 3.3 6.7 C 3.5 6.3 3.7 5.9 4 5.5 L 3.4 4.1 L 4.4 3.1 L 5.8 3.7 C 6.2 3.4 6.6 3.2 7 3 Z" fill="none" stroke="#64748b" stroke-width="1.2" stroke-linejoin="round"/>' +
    '</svg>';

  FT_ICON_INFO =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<circle cx="8" cy="8" r="6.5" fill="none" stroke="#64748b" stroke-width="1.4"/>' +
    '<circle cx="8" cy="5" r="0.9" fill="#64748b"/>' +
    '<path d="M 8 7.5 L 8 11.5" stroke="#64748b" stroke-width="1.5" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_INFO_ACCENT =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<circle cx="8" cy="8" r="6.5" fill="none" stroke="#3b82f6" stroke-width="1.4"/>' +
    '<circle cx="8" cy="5" r="0.9" fill="#3b82f6"/>' +
    '<path d="M 8 7.5 L 8 11.5" stroke="#3b82f6" stroke-width="1.5" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_INFO_ACCENT_DARK =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<circle cx="8" cy="8" r="6.5" fill="none" stroke="#60a5fa" stroke-width="1.4"/>' +
    '<circle cx="8" cy="5" r="0.9" fill="#60a5fa"/>' +
    '<path d="M 8 7.5 L 8 11.5" stroke="#60a5fa" stroke-width="1.5" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_CHECK =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 3.5 8.5 L 6.5 11.5 L 12.5 4.5" fill="none" stroke="#22c55e" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>' +
    '</svg>';

  FT_ICON_CLOSE =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 4 4 L 12 12 M 12 4 L 4 12" fill="none" stroke="#64748b" stroke-width="1.8" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_SEARCH =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<circle cx="7" cy="7" r="4.5" fill="none" stroke="#64748b" stroke-width="1.5"/>' +
    '<path d="M 10.5 10.5 L 14 14" stroke="#64748b" stroke-width="1.8" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_REFRESH =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 13.5 8 C 13.5 11 11 13.5 8 13.5 C 5 13.5 2.5 11 2.5 8 C 2.5 5 5 2.5 8 2.5 C 10.5 2.5 12.6 4.2 13.3 6.5" fill="none" stroke="#64748b" stroke-width="1.5" stroke-linecap="round"/>' +
    '<path d="M 13.5 2.5 L 13.5 6.5 L 9.5 6.5" fill="none" stroke="#64748b" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>' +
    '</svg>';

  FT_ICON_VIEW_LIST =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 2.5 4 L 13.5 4 M 2.5 8 L 13.5 8 M 2.5 12 L 13.5 12" fill="none" stroke="#64748b" stroke-width="1.8" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_VIEW_GRID =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<rect x="2" y="2" width="5" height="5" rx="1" fill="#64748b"/>' +
    '<rect x="9" y="2" width="5" height="5" rx="1" fill="#64748b"/>' +
    '<rect x="2" y="9" width="5" height="5" rx="1" fill="#64748b"/>' +
    '<rect x="9" y="9" width="5" height="5" rx="1" fill="#64748b"/>' +
    '</svg>';

  { Settings & System Icons }
  FT_ICON_WLAN =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 1.5 5 C 5.5 1.5 10.5 1.5 14.5 5" fill="none" stroke="#64748b" stroke-width="1.5" stroke-linecap="round"/>' +
    '<path d="M 3.8 7.8 C 6.2 5.5 9.8 5.5 12.2 7.8" fill="none" stroke="#64748b" stroke-width="1.5" stroke-linecap="round"/>' +
    '<path d="M 6.1 10.6 C 7.2 9.5 8.8 9.5 9.9 10.6" fill="none" stroke="#64748b" stroke-width="1.5" stroke-linecap="round"/>' +
    '<circle cx="8" cy="13.2" r="1.1" fill="#64748b"/>' +
    '</svg>';

  FT_ICON_WIRED =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<rect x="2.5" y="2.5" width="11" height="11" rx="2.5" fill="none" stroke="#64748b" stroke-width="1.4"/>' +
    '<path d="M 5.5 5.5 L 5.5 8.5 M 8 5.5 L 8 8.5 M 10.5 5.5 L 10.5 8.5" stroke="#64748b" stroke-width="1.3" stroke-linecap="round"/>' +
    '<path d="M 6 13.5 L 6 11.5 L 10 11.5 L 10 13.5" fill="none" stroke="#64748b" stroke-width="1.3" stroke-linejoin="round"/>' +
    '</svg>';

  FT_ICON_DISPLAY =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<rect x="1.5" y="2.5" width="13" height="9" rx="1.5" fill="none" stroke="#64748b" stroke-width="1.4"/>' +
    '<path d="M 8 11.5 L 8 14 M 5 14 L 11 14" stroke="#64748b" stroke-width="1.4" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_APPEARANCE =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 8 1.5 C 3.8 1.5 1.5 4.5 1.5 8 C 1.5 11.5 4.2 14.5 7.5 14.5 C 8.6 14.5 9.2 13.8 9.2 13 C 9.2 12.4 8.9 11.9 8.9 11.3 C 8.9 10.4 9.6 9.8 10.5 9.8 L 11.8 9.8 C 13.6 9.8 14.5 8.2 14.5 6.5 C 14.5 3.5 11.8 1.5 8 1.5 Z M 4.5 5 C 5.052 5 5.5 5.448 5.5 6 C 5.5 6.552 5.052 7 4.5 7 C 3.948 7 3.5 6.552 3.5 6 C 3.5 5.448 3.948 5 4.5 5 Z M 7.5 3.5 C 8.052 3.5 8.5 3.948 8.5 4.5 C 8.5 5.052 8.052 5.5 7.5 5.5 C 6.948 5.5 6.5 5.052 6.5 4.5 C 6.5 3.948 6.948 3.5 7.5 3.5 Z M 10.8 4.5 C 11.352 4.5 11.8 4.948 11.8 5.5 C 11.8 6.052 11.352 6.5 10.8 6.5 C 10.248 6.5 9.8 6.052 9.8 5.5 C 9.8 4.948 10.248 4.5 10.8 4.5 Z M 5 8.5 C 5.552 8.5 6 8.948 6 9.5 C 6 10.052 5.552 10.5 5 10.5 C 4.448 10.5 4 10.052 4 9.5 C 4 8.948 4.448 8.5 5 8.5 Z" fill="#64748b" fill-rule="evenodd"/>' +
    '</svg>';

  FT_ICON_BACKGROUND =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<rect x="1.5" y="2.5" width="13" height="11" rx="2" fill="none" stroke="#64748b" stroke-width="1.4"/>' +
    '<circle cx="5.2" cy="6" r="1.1" fill="#64748b"/>' +
    '<path d="M 2.2 12.5 L 6.2 7.5 L 9 10.5 L 11 8.5 L 13.8 12.5 Z" fill="#64748b"/>' +
    '</svg>';

  FT_ICON_DOCK =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<rect x="1.5" y="2.5" width="13" height="11" rx="2" fill="none" stroke="#64748b" stroke-width="1.4"/>' +
    '<line x1="1.5" y1="9.5" x2="14.5" y2="9.5" stroke="#64748b" stroke-width="1.3"/>' +
    '<rect x="5.5" y="11" width="5" height="1.2" rx="0.6" fill="#64748b"/>' +
    '</svg>';

  FT_ICON_USER =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<circle cx="8" cy="8" r="6.5" fill="none" stroke="#64748b" stroke-width="1.4"/>' +
    '<circle cx="8" cy="5.8" r="2" fill="#64748b"/>' +
    '<path d="M 3.8 12.5 C 4.5 10.2 6.1 9.2 8 9.2 C 9.9 9.2 11.5 10.2 12.2 12.5" fill="none" stroke="#64748b" stroke-width="1.4" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_LANGUAGE =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 2.5 13.5 L 7.4 2.5 L 8.6 2.5 L 13.5 13.5 M 4.8 9.5 L 11.2 9.5" fill="none" stroke="#64748b" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>' +
    '</svg>';

  FT_ICON_BATTERY =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<rect x="1.5" y="4.5" width="11.5" height="7" rx="1.5" fill="none" stroke="#64748b" stroke-width="1.4"/>' +
    '<path d="M 14.5 6.8 L 14.5 9.2" stroke="#64748b" stroke-width="1.4" stroke-linecap="round"/>' +
    '<rect x="3.5" y="6.5" width="5.5" height="3" rx="0.8" fill="#64748b"/>' +
    '</svg>';

  FT_ICON_LOCK =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<rect x="3" y="6.5" width="10" height="7.5" rx="1.5" fill="none" stroke="#64748b" stroke-width="1.4"/>' +
    '<path d="M 5.5 6.5 L 5.5 4.5 C 5.5 3.1 6.6 2 8 2 C 9.4 2 10.5 3.1 10.5 4.5 L 10.5 6.5" fill="none" stroke="#64748b" stroke-width="1.4" stroke-linecap="round"/>' +
    '<circle cx="8" cy="10.2" r="1" fill="#64748b"/>' +
    '</svg>';

  FT_ICON_BLUETOOTH =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 4.7 4.7 L 11.3 11.3 L 8 14.6 L 8 1.4 L 11.3 4.7 L 4.7 11.3" fill="none" stroke="#64748b" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>' +
    '</svg>';

  FT_ICON_SOUND =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 2.5 5.5 L 5.5 5.5 L 9 2.5 L 9 13.5 L 5.5 10.5 L 2.5 10.5 Z" fill="#64748b"/>' +
    '<path d="M 11.5 5.5 C 12.5 6.5 12.5 9.5 11.5 10.5" stroke="#64748b" stroke-width="1.3" stroke-linecap="round" fill="none"/>' +
    '<path d="M 13.5 3.5 C 15 5.5 15 10.5 13.5 12.5" stroke="#64748b" stroke-width="1.3" stroke-linecap="round" fill="none"/>' +
    '</svg>';

  FT_ICON_VOLUME_LOW =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 2.5 5.5 L 5.5 5.5 L 9 2.5 L 9 13.5 L 5.5 10.5 L 2.5 10.5 Z" fill="#64748b"/>' +
    '<path d="M 11.5 6 C 12.2 6.8 12.2 9.2 11.5 10" stroke="#64748b" stroke-width="1.3" stroke-linecap="round" fill="none"/>' +
    '</svg>';

  FT_ICON_VOLUME_MUTE =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 2.5 5.5 L 5.5 5.5 L 9 2.5 L 9 13.5 L 5.5 10.5 L 2.5 10.5 Z" fill="#64748b"/>' +
    '<line x1="11.5" y1="6" x2="14.5" y2="10" stroke="#64748b" stroke-width="1.3" stroke-linecap="round"/>' +
    '<line x1="14.5" y1="6" x2="11.5" y2="10" stroke="#64748b" stroke-width="1.3" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_POWER =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 5.2 4.2 C 3.5 5.6 2.8 8.1 3.5 10.3 C 4.2 12.5 6.3 14 8.6 14 C 11 14 13.1 12.5 13.8 10.3 C 14.5 8.1 13.8 5.6 12.1 4.2" stroke="#64748b" stroke-width="1.4" stroke-linecap="round" fill="none"/>' +
    '<line x1="8.6" y1="2" x2="8.6" y2="7.5" stroke="#64748b" stroke-width="1.4" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_BRIGHTNESS_LOW =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<circle cx="8" cy="8" r="3" fill="none" stroke="#64748b" stroke-width="1.3"/>' +
    '<path d="M 8 1.5 L 8 3 M 8 13 L 8 14.5 M 1.5 8 L 3 8 M 13 8 L 14.5 8" stroke="#64748b" stroke-width="1.3" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_BRIGHTNESS_HIGH =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<circle cx="8" cy="8" r="3.4" fill="#64748b"/>' +
    '<path d="M 8 1.2 L 8 3 M 8 13 L 8 14.8 M 1.2 8 L 3 8 M 13 8 L 14.8 8 M 3.2 3.2 L 4.5 4.5 M 11.5 11.5 L 12.8 12.8 M 3.2 12.8 L 4.5 11.5 M 11.5 4.5 L 12.8 3.2" stroke="#64748b" stroke-width="1.4" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_SELECTOR =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 5 6 L 8 3 L 11 6 M 5 10 L 8 13 L 11 10" stroke="#64748b" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round" fill="none"/>' +
    '</svg>';

  FT_ICON_ROTATE_0 =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<rect x="2" y="3.5" width="12" height="8.5" rx="1.5" fill="none" stroke="#64748b" stroke-width="1.3"/>' +
    '<line x1="2" y1="6" x2="14" y2="6" stroke="#64748b" stroke-width="1"/>' +
    '<path d="M 8 12 L 8 14 M 5.5 14 L 10.5 14" stroke="#64748b" stroke-width="1.3" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_ROTATE_90 =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<rect x="3.5" y="2" width="8.5" height="12" rx="1.5" fill="none" stroke="#64748b" stroke-width="1.3"/>' +
    '<line x1="3.5" y1="4.5" x2="12" y2="4.5" stroke="#64748b" stroke-width="1"/>' +
    '<path d="M 12 8 L 14 8 M 14 5.5 L 14 10.5" stroke="#64748b" stroke-width="1.3" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_ROTATE_180 =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<rect x="2" y="4" width="12" height="8.5" rx="1.5" fill="none" stroke="#64748b" stroke-width="1.3"/>' +
    '<line x1="2" y1="10" x2="14" y2="10" stroke="#64748b" stroke-width="1"/>' +
    '<path d="M 8 4 L 8 2 M 5.5 2 L 10.5 2" stroke="#64748b" stroke-width="1.3" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_ROTATE_270 =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<rect x="4" y="2" width="8.5" height="12" rx="1.5" fill="none" stroke="#64748b" stroke-width="1.3"/>' +
    '<line x1="4" y1="11.5" x2="12.5" y2="11.5" stroke="#64748b" stroke-width="1"/>' +
    '<path d="M 4 8 L 2 8 M 2 5.5 L 2 10.5" stroke="#64748b" stroke-width="1.3" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_THEME_LIGHT =
    '<svg viewBox="0 0 104 76" width="104" height="76">' +
    '<rect x="1.5" y="1.5" width="101" height="73" rx="8" fill="#f6f6f6" stroke="#dcdce0" stroke-width="1.5"/>' +
    '<circle cx="22" cy="25" r="9" fill="#acacb4"/>' +
    '<rect x="38" y="19" width="32" height="5" rx="2.5" fill="#acacb4"/>' +
    '<rect x="38" y="27" width="46" height="5" rx="2.5" fill="#acacb4"/>' +
    '<circle cx="22" cy="51" r="9" fill="#acacb4"/>' +
    '<rect x="38" y="48" width="46" height="5" rx="2.5" fill="#acacb4"/>' +
    '</svg>';

  FT_ICON_THEME_DARK =
    '<svg viewBox="0 0 104 76" width="104" height="76">' +
    '<rect x="1.5" y="1.5" width="101" height="73" rx="8" fill="#2d2d30" stroke="#444448" stroke-width="1.5"/>' +
    '<circle cx="22" cy="25" r="9" fill="#7a7a82"/>' +
    '<rect x="38" y="19" width="32" height="5" rx="2.5" fill="#7a7a82"/>' +
    '<rect x="38" y="27" width="46" height="5" rx="2.5" fill="#7a7a82"/>' +
    '<circle cx="22" cy="51" r="9" fill="#7a7a82"/>' +
    '<rect x="38" y="48" width="46" height="5" rx="2.5" fill="#7a7a82"/>' +
    '</svg>';

  FT_ICON_DISTRO_LOGO_LIGHT =
    '<svg width="8.9767046mm" height="8.9767008mm" viewBox="0 0 8.9767046 8.9767008" ' +
    'version="1.1" id="svg1" xml:space="preserve" xmlns="http://www.w3.org/2000/svg" ' +
    'xmlns:svg="http://www.w3.org/2000/svg"><defs id="defs1" /><g id="layer1" transfo' +
    'rm="translate(-85.829456,-57.641576)"><g id="g33"><path style="fill:#aa0000;fill' +
    '-opacity:1;stroke:none;stroke-width:0.780001;stroke-linecap:round;stroke-linejoi' +
    'n:round;stroke-dasharray:none;stroke-opacity:1" d="m 85.829453,62.129926 v -4.48' +
    '8354 l 2.100851,5e-6 c 1.155467,4e-6 3.175228,0.0045 4.488353,0.01004 l 2.387503' +
    ',0.01003 v 4.478314 4.478311 h -4.488353 -4.488354 z m 7.87962,4.316799 c 0.0267' +
    ',-0.01137 0.06268,-0.03684 0.07995,-0.05658 0.01727,-0.01975 0.161539,-0.314534 ' +
    '0.320597,-0.655099 l 0.289194,-0.619206 -5.5e-5,-3.009194 c -5.6e-5,-2.976087 -4' +
    '.13e-4,-3.009734 -0.03004,-3.058363 -0.01649,-0.02705 -0.0521,-0.06266 -0.07915,' +
    '-0.07915 -0.04714,-0.02874 -0.07724,-0.02998 -0.728317,-0.03003 -0.773398,-6.6e-' +
    '5 -0.754634,-0.0029 -0.81823,0.121179 l -0.03395,0.0662 4.12e-4,2.821826 c 4.13e' +
    '-4,2.736719 0.0012,2.823725 0.02891,2.884769 0.03457,0.07614 0.0852,0.111857 0.1' +
    '72513,0.121699 0.08279,0.0093 0.168354,-0.02902 0.207316,-0.09291 0.02744,-0.045' +
    '01 0.02834,-0.131857 0.02839,-2.765885 l 5.6e-5,-2.719413 h 0.407346 0.407347 v ' +
    '2.813606 2.813606 l -0.274617,0.584719 c -0.238838,0.508541 -0.274709,0.594547 -' +
    '0.275337,0.660154 -0.0015,0.15977 0.150411,0.260846 0.297733,0.198074 z m -3.490' +
    '265,-0.05307 c 0.02025,-0.0144 0.05039,-0.0444 0.06702,-0.06667 0.04151,-0.0556 ' +
    '0.04134,-0.176558 -4.13e-4,-0.233035 -0.01681,-0.02279 -0.174271,-0.163042 -0.34' +
    '99,-0.311683 l -0.319324,-0.270252 v -0.199851 -0.199853 l 0.158412,-0.401458 0.' +
    '158413,-0.401458 V 62.91415 61.518907 h 0.106091 c 0.125373,0 0.189753,-0.02351 ' +
    '0.245384,-0.08963 0.07875,-0.09359 0.04423,-0.268866 -0.06396,-0.324816 -0.04052' +
    ',-0.02095 -0.171889,-0.02318 -1.153605,-0.0196 l -1.107872,0.0041 -0.04036,0.037' +
    '71 c -0.06363,0.05946 -0.08709,0.117044 -0.07855,0.192809 0.0091,0.08059 0.04767' +
    ',0.137387 0.117562,0.173025 0.04718,0.02405 0.117179,0.02638 0.794764,0.0264 l 0' +
    '.743028,2.5e-5 v 1.347307 1.347309 l -0.15921,0.403148 -0.159214,0.403148 0.0046' +
    ',0.338017 c 0.0042,0.314837 0.0067,0.340934 0.03599,0.380569 0.02616,0.03544 0.5' +
    '19286,0.464314 0.720243,0.626405 0.09291,0.07494 0.20055,0.08599 0.28086,0.02885' +
    ' z m -3.302205,-0.08772 c 0.09562,-0.08046 0.08963,0.09776 0.08963,-2.664643 v -' +
    '2.525353 l 0.105559,-0.0089 c 0.12617,-0.01058 0.188764,-0.04338 0.227786,-0.119' +
    '392 0.02591,-0.05048 0.02874,-0.09168 0.02874,-0.419263 0,-0.327589 -0.0028,-0.3' +
    '68789 -0.02874,-0.419263 -0.03955,-0.07703 -0.105565,-0.111623 -0.229976,-0.1205' +
    '25 l -0.103369,-0.0074 v -0.18656 -0.186559 h 0.111992 c 0.0997,0 0.117317,-0.00' +
    '44 0.160464,-0.04079 0.08392,-0.07062 0.08963,-0.102333 0.08963,-0.498323 0,-0.3' +
    '18213 -0.0031,-0.365011 -0.02752,-0.411603 -0.03842,-0.0734 -0.13501,-0.120459 -' +
    '0.247243,-0.120459 h -0.08732 l -2.5e-5,-0.267793 c -1.9e-5,-0.225136 -0.0042,-0' +
    '.276033 -0.0264,-0.319525 -0.03564,-0.06989 -0.09243,-0.108479 -0.173026,-0.1175' +
    '63 -0.07925,-0.0089 -0.140424,0.01785 -0.198555,0.08693 l -0.03951,0.04696 v 0.2' +
    '83945 0.283945 l -0.127031,0.0053 c -0.110454,0.0046 -0.132366,0.01023 -0.167902' +
    ',0.04304 -0.07637,0.07048 -0.08224,0.105462 -0.08224,0.490324 0,0.392173 0.0058,' +
    '0.424276 0.08963,0.4948 0.04375,0.03682 0.06011,0.04079 0.168007,0.04079 h 0.119' +
    '537 v 0.188588 0.188584 h -0.11092 c -0.0902,0 -0.120496,0.0064 -0.162185,0.0342' +
    '5 -0.09756,0.06517 -0.104018,0.09623 -0.104045,0.500346 -2e-5,0.328997 0.0027,0.' +
    '366576 0.02983,0.422764 0.04046,0.08358 0.09853,0.11444 0.234771,0.124742 l 0.11' +
    '2548,0.0085 v 2.540713 c 0,2.264308 0.0026,2.545631 0.02336,2.585894 0.05567,0.1' +
    '07663 0.231181,0.141955 0.324529,0.06341 z m 5.003366,-0.69781 c 0.06476,-0.0394' +
    '8 0.08173,-0.0683 0.174183,-0.295775 l 0.07934,-0.195214 v -3.009838 c 0,-2.9827' +
    '45 -2.07e-4,-3.010298 -0.03017,-3.060934 -0.01659,-0.02811 -0.05383,-0.06375 -0.' +
    '08274,-0.07921 -0.04904,-0.02622 -0.098,-0.02811 -0.728693,-0.02811 -0.73091,0 -' +
    '0.716599,-0.0015 -0.79532,0.08276 l -0.03771,0.04037 v 2.88671 2.886713 l 0.0377' +
    '1,0.04037 c 0.115443,0.123552 0.293922,0.104897 0.365834,-0.03824 0.02482,-0.049' +
    '4 0.02638,-0.212301 0.02641,-2.75683 l 2.3e-5,-2.704328 h 0.399802 0.399804 v 2.' +
    '825148 2.825148 l -0.06789,0.173248 c -0.03734,0.09529 -0.06786,0.197068 -0.0678' +
    '3,0.22618 1.67e-4,0.157599 0.192105,0.264242 0.327263,0.181832 z m -5.597154,-1.' +
    '448397 c 0.09998,-0.06096 0.09503,0.01106 0.09503,-1.381061 0,-1.109183 -0.0028,' +
    '-1.266704 -0.02336,-1.306435 -0.07058,-0.136485 -0.290973,-0.138661 -0.379393,-0' +
    '.0037 -0.02557,0.03902 -0.0275,0.115251 -0.03173,1.256707 -0.0025,0.668341 -4.13' +
    'e-4,1.243988 0.0047,1.279216 0.0098,0.068 0.06644,0.148885 0.119297,0.170268 0.0' +
    '5763,0.02331 0.164943,0.01587 0.215486,-0.01494 z m 1.161693,0 c 0.02656,-0.0162' +
    ' 0.06051,-0.05181 0.07543,-0.07915 0.0255,-0.04671 0.02713,-0.124932 0.02713,-1.' +
    '301912 0,-1.176981 -0.0016,-1.255201 -0.02713,-1.301914 -0.07695,-0.140939 -0.29' +
    '3174,-0.145601 -0.383164,-0.0083 -0.0257,0.03921 -0.02723,0.11281 -0.02723,1.310' +
    '173 0,1.19736 0.0015,1.27096 0.02723,1.310172 0.06364,0.09713 0.209568,0.130743 ' +
    '0.307729,0.07089 z m 1.55987,-0.657622 c 0.02485,-0.01285 0.05844,-0.0451 0.0746' +
    '3,-0.07166 0.02794,-0.04583 0.02945,-0.07992 0.02945,-0.666864 0,-0.586943 -0.00' +
    '15,-0.621032 -0.02945,-0.666863 -0.06026,-0.09883 -0.20459,-0.129932 -0.307579,-' +
    '0.06628 -0.04008,0.02477 -0.06169,0.0536 -0.08105,0.108122 l -0.0264,0.07435 h -' +
    '0.109612 c -0.103596,0 -0.109614,-0.0019 -0.109666,-0.03395 -8.7e-5,-0.05138 -0.' +
    '05294,-0.127416 -0.108656,-0.156345 -0.10961,-0.0569 -0.2463,-0.01688 -0.30007,0' +
    '.08785 -0.02684,0.05227 -0.02874,0.09557 -0.02874,0.653258 0,0.654207 -0.0012,0.' +
    '644509 0.09114,0.722225 l 0.04696,0.03952 h 0.406939 c 0.337884,0 0.414603,-0.00' +
    '4 0.452116,-0.02336 z m 2.513593,-1.33385 c 0.06016,-0.03668 0.09503,-0.102093 0' +
    '.09503,-0.17826 0,-0.08877 -0.224821,-1.299499 -0.250539,-1.349232 -0.03365,-0.0' +
    '6508 -0.105663,-0.102382 -0.197771,-0.102448 -0.06648,-4.7e-5 -0.08692,0.0072 -0' +
    '.131824,0.0466 -0.09878,0.08673 -0.09875,0.08774 0.02106,0.745402 0.05895,0.3236' +
    '14 0.114308,0.624101 0.123016,0.667747 0.01652,0.08278 0.07094,0.163043 0.125553' +
    ',0.185133 0.05763,0.02332 0.164943,0.01587 0.215485,-0.01494 z m 2.25325,-0.0280' +
    '3 c 0.03168,-0.03168 0.06251,-0.07715 0.0685,-0.101055 0.01407,-0.05602 -0.21349' +
    '6,-1.320293 -0.251142,-1.395301 -0.03457,-0.06889 -0.09963,-0.105609 -0.187091,-' +
    '0.105609 -0.127741,0 -0.219278,0.08242 -0.219397,0.197536 -9.9e-5,0.09339 0.2250' +
    '71,1.300803 0.252714,1.355121 0.03696,0.07262 0.100207,0.106779 0.197839,0.10684' +
    '7 0.07375,5.2e-5 0.08612,-0.0051 0.138575,-0.05754 z m -3.867547,-1.465572 c 0.0' +
    '6396,-0.03899 0.09502,-0.102999 0.09502,-0.195754 0,-0.06166 -0.0078,-0.08458 -0' +
    '.04149,-0.121843 -0.02282,-0.02524 -0.211216,-0.162948 -0.418662,-0.306007 l -0.' +
    '377172,-0.26011 -0.0041,-0.335863 -0.0041,-0.335864 0.177561,0.1228 c 0.3833,0.2' +
    '65081 0.376268,0.261089 0.457639,0.259861 0.08568,-0.0012 0.138485,-0.03042 0.18' +
    '0736,-0.09972 0.0383,-0.06281 0.03849,-0.169074 4.13e-4,-0.231497 -0.01873,-0.03' +
    '072 -0.16732,-0.142648 -0.420592,-0.316825 l -0.391628,-0.269322 -0.0055,-0.1741' +
    '74 c -0.0062,-0.193038 -0.02155,-0.233798 -0.108212,-0.286641 -0.09508,-0.05797 ' +
    '-0.249141,-0.02512 -0.299955,0.06397 -0.01221,0.02141 -0.02272,0.109799 -0.02736' +
    ',0.230293 l -0.0076,0.195542 -0.324369,0.231665 c -0.378136,0.270069 -0.387479,0' +
    '.278094 -0.409553,0.351772 -0.04787,0.15977 0.08577,0.309713 0.248777,0.279134 0' +
    '.03249,-0.0061 0.136069,-0.06881 0.264883,-0.160364 0.116342,-0.0827 0.215192,-0' +
    '.150358 0.219667,-0.150358 0.0044,0 0.0081,0.145558 0.0081,0.323461 v 0.323461 l' +
    ' -0.342823,0.24607 c -0.202119,0.145077 -0.356918,0.267111 -0.377172,0.297335 -0' +
    '.103383,0.154281 0.0415,0.362204 0.228009,0.327216 0.03162,-0.0059 0.173245,-0.0' +
    '9694 0.373302,-0.239889 0.177297,-0.126682 0.330829,-0.235541 0.341183,-0.241908' +
    ' 0.01192,-0.0073 0.155458,0.08273 0.391657,0.245771 0.361928,0.249823 0.375053,0' +
    '.257346 0.448868,0.257293 0.04878,-3.7e-5 0.09335,-0.01063 0.124338,-0.02951 z m' +
    ' 4.405608,-2.24358 c 0.149262,-0.07083 0.147982,-0.316909 -0.002,-0.388089 -0.04' +
    '604,-0.02184 -0.232871,-0.02424 -1.894661,-0.02424 -1.66179,0 -1.848623,0.0024 -' +
    '1.894661,0.02424 -0.148814,0.07062 -0.150268,0.326555 -0.0023,0.390916 0.04094,0' +
    '.0178 0.343882,0.02128 1.894601,0.02177 1.693766,6.2e-4 1.850241,-0.0015 1.89895' +
    '9,-0.0246 z" id="path25" /><path style="fill:#aa0000;fill-opacity:1;stroke:none;' +
    'stroke-width:0.780001;stroke-linecap:round;stroke-linejoin:round;stroke-dasharra' +
    'y:none;stroke-opacity:1" d="m 86.629245,59.10965 v -0.104338 l 0.06854,0.0058 c ' +
    '0.0377,0.0032 0.10623,0.0058 0.152295,0.0058 h 0.08375 v 0.09854 0.09854 h -0.15' +
    '229 -0.152294 z" id="path30" /><path style="fill:#aa0000;fill-opacity:1;stroke:n' +
    'one;stroke-width:0.780001;stroke-linecap:round;stroke-linejoin:round;stroke-dash' +
    'array:none;stroke-opacity:1" d="m 86.629245,60.562238 v -0.103024 l 0.06495,4.8e' +
    '-5 c 0.03572,2.4e-5 0.104253,0.0027 0.152293,0.0058 l 0.08735,0.0058 v 0.09719 0' +
    '.09719 h -0.152295 -0.152294 z" id="path31" /><path style="fill:#aa0000;fill-opa' +
    'city:1;stroke:none;stroke-width:0.780001;stroke-linecap:round;stroke-linejoin:ro' +
    'und;stroke-dasharray:none;stroke-opacity:1" d="m 88.483649,62.869045 v -0.223962' +
    ' h 0.11646 0.116461 v 0.223962 0.223961 h -0.116461 -0.11646 z" id="path32" /></' +
    'g></g></svg>';

  FT_ICON_DISTRO_LOGO_DARK =
    '<svg width="8.9767046mm" height="8.9767094mm" viewBox="0 0 8.9767046 8.9767094" ' +
    'version="1.1" id="svg1" xml:space="preserve" xmlns="http://www.w3.org/2000/svg" ' +
    'xmlns:svg="http://www.w3.org/2000/svg"><defs id="defs1" /><g id="layer1" transfo' +
    'rm="translate(-71.317164,-57.641572)"><g id="g32"><path style="fill:#ef4444;fill' +
    '-opacity:1;stroke:none;stroke-width:0.78;stroke-linecap:round;stroke-linejoin:ro' +
    'und;stroke-dasharray:none;stroke-opacity:1" d="m 71.317164,62.129925 v -4.488353' +
    ' l 2.100851,4e-6 c 1.155468,4e-6 3.175228,0.0045 4.488353,0.01005 l 2.387503,0.0' +
    '1003 v 4.478313 4.478311 h -4.488353 -4.488354 z m 7.87962,4.3168 c 0.0267,-0.01' +
    '137 0.06268,-0.03684 0.07995,-0.05657 0.01727,-0.01975 0.161539,-0.314535 0.3205' +
    '97,-0.655099 l 0.289195,-0.619206 -5.6e-5,-3.009194 c -5.6e-5,-2.976087 -4.13e-4' +
    ',-3.009735 -0.03004,-3.058364 -0.01649,-0.02704 -0.05211,-0.06266 -0.07915,-0.07' +
    '915 -0.04714,-0.02874 -0.07725,-0.02998 -0.728317,-0.03004 -0.773397,-6.6e-5 -0.' +
    '754633,-0.0028 -0.81823,0.121179 l -0.03394,0.0662 4.12e-4,2.821826 c 4.13e-4,2.' +
    '736719 0.0012,2.823725 0.02891,2.884769 0.03457,0.07614 0.0852,0.111857 0.172513' +
    ',0.121699 0.08279,0.0093 0.168354,-0.02902 0.207317,-0.09291 0.02745,-0.04501 0.' +
    '02834,-0.131857 0.02839,-2.765884 l 5.5e-5,-2.719413 h 0.407347 0.407347 v 2.813' +
    '606 2.813605 l -0.274617,0.58472 c -0.238838,0.50854 -0.27471,0.594547 -0.275337' +
    ',0.660153 -0.0014,0.159771 0.150411,0.260846 0.297733,0.198075 z m -3.490264,-0.' +
    '05307 c 0.02024,-0.0144 0.05039,-0.0444 0.06702,-0.06667 0.04151,-0.05561 0.0413' +
    '4,-0.176558 -4.13e-4,-0.233034 -0.01682,-0.02279 -0.174271,-0.163043 -0.349901,-' +
    '0.311683 L 75.103905,65.512014 V 65.312163 65.11231 l 0.158412,-0.401458 0.15841' +
    '3,-0.401458 v -1.395245 -1.395243 h 0.106092 c 0.125372,0 0.189753,-0.02352 0.24' +
    '5383,-0.08963 0.07875,-0.09359 0.04423,-0.268866 -0.06396,-0.324816 -0.04053,-0.' +
    '02096 -0.171889,-0.02319 -1.153605,-0.0196 l -1.107872,0.0041 -0.04036,0.03772 c' +
    ' -0.06363,0.05946 -0.08709,0.117044 -0.07855,0.192809 0.0091,0.08059 0.04767,0.1' +
    '37386 0.117562,0.173025 0.04718,0.02405 0.117179,0.02638 0.794764,0.0264 l 0.743' +
    '028,2.4e-5 v 1.347307 1.347309 l -0.159211,0.403148 -0.159213,0.403148 0.0046,0.' +
    '338017 c 0.0043,0.314836 0.0067,0.340934 0.03599,0.380569 0.02616,0.03544 0.5192' +
    '86,0.464314 0.720243,0.626405 0.09291,0.07494 0.200551,0.08599 0.280861,0.02885 ' +
    'z m -3.302206,-0.08772 c 0.09562,-0.08046 0.08963,0.09776 0.08963,-2.664643 V 61' +
    '.11594 l 0.105559,-0.0089 c 0.12617,-0.01058 0.188765,-0.04339 0.227787,-0.11939' +
    '2 0.02591,-0.05048 0.02874,-0.09168 0.02874,-0.419263 0,-0.327589 -0.0028,-0.368' +
    '788 -0.02874,-0.419262 -0.03954,-0.07702 -0.105566,-0.111624 -0.229976,-0.120525' +
    ' l -0.10337,-0.0074 v -0.186561 -0.186559 h 0.111993 c 0.09969,0 0.117316,-0.004' +
    '5 0.160463,-0.04078 0.08392,-0.07062 0.08963,-0.102333 0.08963,-0.498323 0,-0.31' +
    '8213 -0.0031,-0.36501 -0.02752,-0.411603 -0.03842,-0.0734 -0.13501,-0.120459 -0.' +
    '247242,-0.120459 h -0.08732 l -2.5e-5,-0.267793 c -1.9e-5,-0.225136 -0.0042,-0.2' +
    '76033 -0.0264,-0.319524 -0.03564,-0.06989 -0.09243,-0.108479 -0.173025,-0.117564' +
    ' -0.07926,-0.0089 -0.140424,0.01785 -0.198555,0.08693 l -0.03952,0.04696 v 0.283' +
    '945 0.283946 l -0.127031,0.0053 c -0.110453,0.0046 -0.132366,0.01024 -0.167902,0' +
    '.04304 -0.07637,0.07049 -0.08224,0.105462 -0.08224,0.490325 0,0.392172 0.0058,0.' +
    '424276 0.08963,0.4948 0.04375,0.03681 0.06011,0.04078 0.168008,0.04078 h 0.11953' +
    '6 v 0.188587 0.188585 h -0.11092 c -0.0902,0 -0.120496,0.0064 -0.162184,0.03425 ' +
    '-0.09756,0.06517 -0.104018,0.09624 -0.104045,0.500347 -2.1e-5,0.328996 0.0026,0.' +
    '366576 0.02983,0.422764 0.04046,0.08358 0.09853,0.11444 0.234771,0.124742 l 0.11' +
    '2548,0.0085 v 2.540714 c 0,2.264308 0.0025,2.545631 0.02336,2.585893 0.05567,0.1' +
    '07664 0.231181,0.141955 0.324529,0.06341 z m 5.003367,-0.69781 c 0.06476,-0.0394' +
    '9 0.08173,-0.0683 0.174182,-0.295774 l 0.07934,-0.195215 v -3.009837 c 0,-2.9827' +
    '46 -2.06e-4,-3.010298 -0.03017,-3.060935 -0.01659,-0.0281 -0.05383,-0.06375 -0.0' +
    '8274,-0.07921 -0.04903,-0.02622 -0.098,-0.02811 -0.728692,-0.02811 -0.730911,0 -' +
    '0.716599,-0.0014 -0.795321,0.08276 l -0.03772,0.04037 v 2.886711 2.886713 l 0.03' +
    '772,0.04037 c 0.115443,0.123552 0.293922,0.104897 0.365834,-0.03824 0.02482,-0.0' +
    '494 0.02638,-0.212301 0.0264,-2.75683 l 2.3e-5,-2.704328 h 0.399803 0.399803 v 2' +
    '.825148 2.825148 l -0.06789,0.173248 c -0.03734,0.09529 -0.06787,0.197068 -0.067' +
    '84,0.22618 1.67e-4,0.157599 0.192105,0.264242 0.327264,0.181831 z m -5.597155,-1' +
    '.448397 c 0.09998,-0.06096 0.09503,0.01106 0.09503,-1.381061 0,-1.109183 -0.0028' +
    ',-1.266704 -0.02336,-1.306434 -0.07058,-0.136485 -0.290973,-0.138662 -0.379392,-' +
    '0.0038 -0.02557,0.03902 -0.0275,0.115251 -0.03174,1.256706 -0.0025,0.668342 -4.1' +
    '3e-4,1.243989 0.0047,1.279216 0.0098,0.068 0.06644,0.148886 0.119297,0.170269 0.' +
    '05763,0.02331 0.164943,0.01587 0.215485,-0.01494 z m 1.161693,0 c 0.02656,-0.016' +
    '2 0.06051,-0.05181 0.07543,-0.07915 0.0255,-0.04671 0.02713,-0.124933 0.02713,-1' +
    '.301913 0,-1.176981 -0.0017,-1.255201 -0.02713,-1.301913 -0.07695,-0.14094 -0.29' +
    '3175,-0.145601 -0.383164,-0.0083 -0.02569,0.03921 -0.02722,0.112811 -0.02722,1.3' +
    '10173 0,1.19736 0.0014,1.27096 0.02722,1.310172 0.06364,0.09713 0.209567,0.13074' +
    '3 0.307729,0.07089 z m 1.559871,-0.657622 c 0.02485,-0.01286 0.05843,-0.0451 0.0' +
    '7463,-0.07166 0.02794,-0.04583 0.02945,-0.07992 0.02945,-0.666864 0,-0.586943 -0' +
    '.0014,-0.621032 -0.02945,-0.666863 -0.06026,-0.09883 -0.20459,-0.129932 -0.30757' +
    '9,-0.06628 -0.04007,0.02477 -0.06169,0.0536 -0.08105,0.108122 l -0.02641,0.07435' +
    ' h -0.109612 c -0.103595,0 -0.109614,-0.0019 -0.109665,-0.03395 -8.7e-5,-0.05138' +
    ' -0.05293,-0.127417 -0.108657,-0.156345 -0.10961,-0.0569 -0.246299,-0.01688 -0.3' +
    '0007,0.08785 -0.02683,0.05226 -0.02874,0.09557 -0.02874,0.653258 0,0.654207 -0.0' +
    '012,0.64451 0.09114,0.722226 l 0.04696,0.03951 h 0.406938 c 0.337884,0 0.414604,' +
    '-0.004 0.452116,-0.02336 z m 2.513592,-1.33385 c 0.06016,-0.03668 0.09503,-0.102' +
    '093 0.09503,-0.17826 0,-0.08877 -0.224822,-1.299498 -0.25054,-1.349232 -0.03365,' +
    '-0.06508 -0.105663,-0.102381 -0.197771,-0.102447 -0.06648,-4.8e-5 -0.08692,0.007' +
    '2 -0.131824,0.0466 -0.09878,0.08673 -0.09875,0.08773 0.02105,0.745401 0.05895,0.' +
    '323614 0.114309,0.624101 0.123016,0.667747 0.01653,0.08278 0.07095,0.163043 0.12' +
    '5553,0.185133 0.05763,0.02331 0.164943,0.01587 0.215485,-0.01494 z m 2.253251,-0' +
    '.02803 c 0.03168,-0.03168 0.0625,-0.07715 0.0685,-0.101056 0.01407,-0.05602 -0.2' +
    '13496,-1.320293 -0.251142,-1.3953 -0.03457,-0.06889 -0.09963,-0.105609 -0.187091' +
    ',-0.105609 -0.12774,0 -0.219277,0.08242 -0.219397,0.197536 -9.9e-5,0.09338 0.225' +
    '071,1.300803 0.252714,1.355121 0.03695,0.07262 0.100207,0.106778 0.19784,0.10684' +
    '7 0.07375,5.1e-5 0.08612,-0.0051 0.138575,-0.05754 z m -3.867548,-1.465573 c 0.0' +
    '6396,-0.03899 0.09502,-0.102999 0.09502,-0.195753 0,-0.06166 -0.0078,-0.08458 -0' +
    '.04149,-0.121844 -0.02282,-0.02525 -0.211216,-0.162947 -0.418662,-0.306006 l -0.' +
    '377172,-0.26011 -0.0041,-0.335863 -0.0041,-0.335864 0.17756,0.122799 c 0.383301,' +
    '0.265082 0.376269,0.261089 0.45764,0.259862 0.08568,-0.0012 0.138484,-0.03042 0.' +
    '180736,-0.09972 0.0383,-0.06281 0.0385,-0.169073 4.12e-4,-0.231496 -0.01873,-0.0' +
    '3072 -0.16732,-0.142649 -0.420591,-0.316825 L 74.68501,58.58451 74.67941,58.4103' +
    '36 c -0.0062,-0.193038 -0.02155,-0.233798 -0.108213,-0.28664 -0.09508,-0.05798 -' +
    '0.24914,-0.02512 -0.299955,0.06397 -0.01221,0.02142 -0.02272,0.1098 -0.02736,0.2' +
    '30294 l -0.0076,0.195541 -0.324368,0.231666 c -0.378136,0.270069 -0.387479,0.278' +
    '093 -0.409553,0.351772 -0.04787,0.15977 0.08577,0.309712 0.248777,0.279133 0.032' +
    '49,-0.0061 0.136069,-0.0688 0.264882,-0.160364 0.116343,-0.0827 0.215192,-0.1503' +
    '57 0.219668,-0.150357 0.0045,0 0.0081,0.145558 0.0081,0.323461 v 0.32346 l -0.34' +
    '2824,0.246071 c -0.202118,0.145077 -0.356918,0.26711 -0.377172,0.297334 -0.10338' +
    '3,0.154282 0.0415,0.362205 0.22801,0.327216 0.03162,-0.0059 0.173244,-0.09694 0.' +
    '373301,-0.239888 0.177296,-0.126682 0.330829,-0.235541 0.341183,-0.241909 0.0119' +
    '3,-0.0073 0.155458,0.08273 0.391657,0.245771 0.361928,0.249824 0.375053,0.257347' +
    ' 0.448868,0.257293 0.04878,-3.7e-5 0.09335,-0.01063 0.124338,-0.02951 z m 4.4056' +
    '09,-2.243579 c 0.149261,-0.07083 0.147982,-0.31691 -0.0021,-0.38809 -0.04604,-0.' +
    '02185 -0.232871,-0.02424 -1.894661,-0.02424 -1.66179,0 -1.848623,0.0024 -1.89466' +
    '1,0.02424 -0.148813,0.07062 -0.150268,0.326556 -0.0022,0.390917 0.04094,0.01781 ' +
    '0.343882,0.02128 1.894601,0.02178 1.693766,6.19e-4 1.850241,-0.0014 1.898959,-0.' +
    '0246 z" id="path17" /><path style="fill:#ef4444;fill-opacity:1;stroke:none;strok' +
    'e-width:0.78;stroke-linecap:round;stroke-linejoin:round;stroke-dasharray:none;st' +
    'roke-opacity:1" d="m 72.116956,59.109649 v -0.104338 l 0.06854,0.0058 c 0.0377,0' +
    '.0032 0.10623,0.0058 0.152294,0.0058 h 0.08375 v 0.09854 0.09854 h -0.152294 -0.' +
    '152295 z" id="path19" /><path style="fill:#ef4444;fill-opacity:1;stroke:none;str' +
    'oke-width:0.78;stroke-linecap:round;stroke-linejoin:round;stroke-dasharray:none;' +
    'stroke-opacity:1" d="m 72.116956,60.562237 v -0.103023 l 0.06495,4.7e-5 c 0.0357' +
    '2,2.5e-5 0.104253,0.0026 0.152292,0.0058 l 0.08735,0.0058 v 0.09719 0.09719 h -0' +
    '.152294 -0.152295 z" id="path23" /><path style="fill:#ef4444;fill-opacity:1;stro' +
    'ke:none;stroke-width:0.78;stroke-linecap:round;stroke-linejoin:round;stroke-dash' +
    'array:none;stroke-opacity:1" d="m 73.971361,62.869044 v -0.223961 h 0.11646 0.11' +
    '646 v 0.223961 0.223962 h -0.11646 -0.11646 z" id="path24" /></g></g></svg>';

  FT_ICON_BATTERY_BOLT =
    '<svg viewBox="0 0 64 64" width="64" height="64">' +
    '<rect x="10" y="20" width="40" height="24" rx="5" fill="none" stroke="#ffffff" stroke-width="3"/>' +
    '<path d="M 50 28 L 50 36" stroke="#ffffff" stroke-width="3" stroke-linecap="round"/>' +
    '<path d="M 31 16 L 23 33 L 31 33 L 28 48 L 40 29 L 32 29 Z" fill="#ffffff"/>' +
    '</svg>';

  FT_ICON_DISPLAY_SCALE =
    '<svg viewBox="0 0 48 36" width="48" height="36">' +
    '<rect x="3" y="3" width="42" height="26" rx="3" fill="none" stroke="#64748b" stroke-width="1.8"/>' +
    '<line x1="3" y1="8" x2="45" y2="8" stroke="#64748b" stroke-width="1.2"/>' +
    '<path d="M 24 29 L 24 33 M 18 33 L 30 33" stroke="#64748b" stroke-width="1.8" stroke-linecap="round"/>' +
    '<rect x="8" y="13" width="8" height="8" rx="1.5" fill="#64748b"/>' +
    '<rect x="19" y="13" width="21" height="3" rx="1" fill="#64748b"/>' +
    '<rect x="19" y="18" width="16" height="3" rx="1" fill="#64748b"/>' +
    '</svg>';

  { Dialog Icons (48x48) }
  FT_ICON_DIALOG_INFO =
    '<svg viewBox="0 0 48 48" width="48" height="48">' +
    '<circle cx="24" cy="24" r="21" fill="#0284c7"/>' +
    '<circle cx="24" cy="14" r="2.8" fill="#ffffff"/>' +
    '<path d="M 21.5 21 L 24 21 L 24 34 M 21.5 34 L 26.5 34" stroke="#ffffff" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>' +
    '</svg>';

  FT_ICON_DIALOG_WARNING =
    '<svg viewBox="0 0 48 48" width="48" height="48">' +
    '<path d="M 24 5 L 43 39 C 43.8 40.5 42.8 42 41 42 L 7 42 C 5.2 42 4.2 40.5 5 39 Z" fill="#f59e0b"/>' +
    '<path d="M 24 18 L 24 28" stroke="#ffffff" stroke-width="3.6" stroke-linecap="round"/>' +
    '<circle cx="24" cy="34" r="2.2" fill="#ffffff"/>' +
    '</svg>';

  FT_ICON_DIALOG_ERROR =
    '<svg viewBox="0 0 48 48" width="48" height="48">' +
    '<circle cx="24" cy="24" r="21" fill="#ef4444"/>' +
    '<path d="M 16 16 L 32 32 M 32 16 L 16 32" stroke="#ffffff" stroke-width="3.6" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_DIALOG_QUESTION =
    '<svg viewBox="0 0 48 48" width="48" height="48">' +
    '<circle cx="24" cy="24" r="21" fill="#6366f1"/>' +
    '<path d="M 18 19 C 18 15.5 20.5 13 24 13 C 27.5 13 30 15.5 30 19 C 30 22 28 23.5 26 25 C 24.5 26.2 24 27.5 24 29" stroke="#ffffff" stroke-width="3.2" stroke-linecap="round" fill="none"/>' +
    '<circle cx="24" cy="34" r="2.2" fill="#ffffff"/>' +
    '</svg>';

  FT_ICON_DIALOG_SUCCESS =
    '<svg viewBox="0 0 48 48" width="48" height="48">' +
    '<circle cx="24" cy="24" r="21" fill="#10b981"/>' +
    '<path d="M 14 25 L 21 32 L 34 17" stroke="#ffffff" stroke-width="3.8" stroke-linecap="round" stroke-linejoin="round" fill="none"/>' +
    '</svg>';

{ ── Extensible Icon Manager & Theming System ── }

type
  TFtIconItem = class
  public
    Name: string;
    SvgLight: string;
    SvgDark: string;
    constructor Create(const AName, ASvgLight, ASvgDark: string);
  end;

  TFtIconManager = class
  private
    FCurrentTheme: string;
    FIcons: TStringList;
    FMonochromeLightColor: string;
    FMonochromeDarkColor: string;
    procedure RegisterDefaults();
  public
    constructor Create();
    destructor Destroy(); override;

    { Retrieve SVG markup — automatically adapts monochrome strokes in dark mode }
    function GetIconSvg(const AName: string; ADarkMode: Boolean = False): string;

    { Render icon SVG directly to a TFloriaImage bitmap at requested dimensions }
    function GetIconBitmap(const AName: string; AW: Integer = 16; AH: Integer = 16; ADarkMode: Boolean = False): TFloriaImage;

    { Register or override an icon for icon-theming support }
    procedure RegisterIcon(const AName, ASvgLight: string; const ASvgDark: string = '');
    function HasIcon(const AName: string): Boolean;

    { Customize palette for monochrome outline icons }
    procedure SetMonochromeColors(const ALightColor, ADarkColor: string);
    property MonochromeLightColor: string read FMonochromeLightColor write FMonochromeLightColor;
    property MonochromeDarkColor: string read FMonochromeDarkColor write FMonochromeDarkColor;
    property CurrentTheme: string read FCurrentTheme write FCurrentTheme;
  end;

{ Global singleton and convenience helpers }
function FtIconManager(): TFtIconManager;
function FtGetIconSvg(const AName: string; ADarkMode: Boolean = False): string;
function FtGetIconBitmap(const AName: string; AW: Integer = 16; AH: Integer = 16; ADarkMode: Boolean = False): TFloriaImage;
procedure FtRegisterIcon(const AName, ASvgLight: string; const ASvgDark: string = '');

implementation

var
  GIconManager: TFtIconManager = nil;

{ TFtIconItem }

constructor TFtIconItem.Create(const AName, ASvgLight, ASvgDark: string);
begin
  inherited Create();
  Name := AName;
  SvgLight := ASvgLight;
  SvgDark := ASvgDark;
end;

{ TFtIconManager }

constructor TFtIconManager.Create();
begin
  inherited Create();
  FCurrentTheme := 'default';
  FIcons := TStringList.Create();
  FIcons.Sorted := True;
  FIcons.Duplicates := dupIgnore;
  FMonochromeLightColor := '#64748b';
  FMonochromeDarkColor  := '#cbd5e1';
  RegisterDefaults();
end;

destructor TFtIconManager.Destroy();
var
  i: Integer;
begin
  if Assigned(FIcons) then
  begin
    for i := 0 to FIcons.Count - 1 do
      FIcons.Objects[i].Free();
    FreeAndNil(FIcons);
  end;
  inherited Destroy();
end;

procedure TFtIconManager.RegisterIcon(const AName, ASvgLight: string; const ASvgDark: string = '');
var
  lowerName: string;
  idx: Integer;
  item: TFtIconItem;
begin
  lowerName := LowerCase(Trim(AName));
  if lowerName = '' then Exit;

  idx := FIcons.IndexOf(lowerName);
  if idx >= 0 then
  begin
    item := TFtIconItem(FIcons.Objects[idx]);
    item.SvgLight := ASvgLight;
    if ASvgDark <> '' then
      item.SvgDark := ASvgDark;
  end
  else
  begin
    item := TFtIconItem.Create(lowerName, ASvgLight, ASvgDark);
    FIcons.AddObject(lowerName, item);
  end;
end;

function TFtIconManager.HasIcon(const AName: string): Boolean;
begin
  Result := FIcons.IndexOf(LowerCase(Trim(AName))) >= 0;
end;

procedure TFtIconManager.SetMonochromeColors(const ALightColor, ADarkColor: string);
begin
  if ALightColor <> '' then FMonochromeLightColor := ALightColor;
  if ADarkColor <> '' then FMonochromeDarkColor := ADarkColor;
end;

function TFtIconManager.GetIconSvg(const AName: string; ADarkMode: Boolean = False): string;
var
  lowerName: string;
  idx: Integer;
  item: TFtIconItem;
  svg: string;
begin
  Result := '';
  lowerName := LowerCase(Trim(AName));
  idx := FIcons.IndexOf(lowerName);
  if idx < 0 then Exit;

  item := TFtIconItem(FIcons.Objects[idx]);
  if ADarkMode then
  begin
    if item.SvgDark <> '' then
      Result := item.SvgDark
    else
    begin
      svg := item.SvgLight;
      // Dynamically replace default slate with lighter dark mode palette
      Result := StringReplace(svg, '#64748b', FMonochromeDarkColor, [rfReplaceAll, rfIgnoreCase]);
    end;
  end
  else
    Result := item.SvgLight;
end;

function TFtIconManager.GetIconBitmap(const AName: string; AW: Integer = 16; AH: Integer = 16; ADarkMode: Boolean = False): TFloriaImage;
var
  svg: string;
  doc: TSVGDocument;
begin
  Result := nil;
  svg := GetIconSvg(AName, ADarkMode);
  if svg = '' then Exit;

  try
    doc := TSVGParser.ParseString(svg);
    if Assigned(doc) then
    begin
      try
        Result := TFloriaSVGRenderer.RenderToImage(doc, AW, AH, True);
      finally
        doc.Free();
      end;
    end;
  except
    Result := nil;
  end;
end;

procedure TFtIconManager.RegisterDefaults();

  procedure RegisterWithWhite(const AName, ASvg: string);
  begin
    RegisterIcon(AName, ASvg);
    RegisterIcon(AName + '-white', StringReplace(ASvg, '#64748b', '#ffffff', [rfReplaceAll, rfIgnoreCase]));
  end;

begin
  { Navigation }
  RegisterIcon('nav-back', FT_ICON_NAV_BACK);
  RegisterIcon('nav-forward', FT_ICON_NAV_FORWARD);
  RegisterIcon('nav-up', FT_ICON_NAV_UP);
  RegisterIcon('new-folder', FT_ICON_NEW_FOLDER);
  RegisterIcon('hidden', FT_ICON_HIDDEN);
  RegisterIcon('eye', FT_ICON_HIDDEN);

  { Files & Directories }
  RegisterIcon('folder', FT_ICON_FOLDER);
  RegisterIcon('file', FT_ICON_FILE);
  RegisterIcon('file-image', FT_ICON_FILE_IMAGE);
  RegisterIcon('file-code', FT_ICON_FILE_CODE);
  RegisterIcon('file-archive', FT_ICON_FILE_ARCHIVE);

  { Places }
  RegisterIcon('place-home', FT_ICON_PLACE_HOME);
  RegisterIcon('home', FT_ICON_PLACE_HOME);
  RegisterIcon('place-desktop', FT_ICON_PLACE_DESKTOP);
  RegisterIcon('desktop', FT_ICON_PLACE_DESKTOP);
  RegisterIcon('place-documents', FT_ICON_PLACE_DOCUMENTS);
  RegisterIcon('documents', FT_ICON_PLACE_DOCUMENTS);
  RegisterIcon('place-downloads', FT_ICON_PLACE_DOWNLOADS);
  RegisterIcon('downloads', FT_ICON_PLACE_DOWNLOADS);
  RegisterIcon('place-pictures', FT_ICON_PLACE_PICTURES);
  RegisterIcon('pictures', FT_ICON_PLACE_PICTURES);
  RegisterIcon('place-music', FT_ICON_PLACE_MUSIC);
  RegisterIcon('music', FT_ICON_PLACE_MUSIC);
  RegisterIcon('place-drive', FT_ICON_PLACE_DRIVE);
  RegisterIcon('drive', FT_ICON_PLACE_DRIVE);

  { Outline Icons (macOS Style) }
  RegisterIcon('outline-home', FT_ICON_OUTLINE_HOME);
  RegisterIcon('home-outline', FT_ICON_OUTLINE_HOME);
  RegisterIcon('place-home-outline', FT_ICON_OUTLINE_HOME);
  RegisterIcon('outline-desktop', FT_ICON_OUTLINE_DESKTOP);
  RegisterIcon('desktop-outline', FT_ICON_OUTLINE_DESKTOP);
  RegisterIcon('place-desktop-outline', FT_ICON_OUTLINE_DESKTOP);
  RegisterIcon('outline-documents', FT_ICON_OUTLINE_DOCUMENTS);
  RegisterIcon('documents-outline', FT_ICON_OUTLINE_DOCUMENTS);
  RegisterIcon('place-documents-outline', FT_ICON_OUTLINE_DOCUMENTS);
  RegisterIcon('outline-downloads', FT_ICON_OUTLINE_DOWNLOADS);
  RegisterIcon('downloads-outline', FT_ICON_OUTLINE_DOWNLOADS);
  RegisterIcon('place-downloads-outline', FT_ICON_OUTLINE_DOWNLOADS);
  RegisterIcon('outline-pictures', FT_ICON_OUTLINE_PICTURES);
  RegisterIcon('pictures-outline', FT_ICON_OUTLINE_PICTURES);
  RegisterIcon('place-pictures-outline', FT_ICON_OUTLINE_PICTURES);
  RegisterIcon('outline-music', FT_ICON_OUTLINE_MUSIC);
  RegisterIcon('music-outline', FT_ICON_OUTLINE_MUSIC);
  RegisterIcon('place-music-outline', FT_ICON_OUTLINE_MUSIC);
  RegisterIcon('outline-drive', FT_ICON_OUTLINE_DRIVE);
  RegisterIcon('drive-outline', FT_ICON_OUTLINE_DRIVE);
  RegisterIcon('place-drive-outline', FT_ICON_OUTLINE_DRIVE);
  RegisterIcon('outline-folder', FT_ICON_OUTLINE_FOLDER);
  RegisterIcon('folder-outline', FT_ICON_OUTLINE_FOLDER);
  RegisterIcon('outline-file', FT_ICON_OUTLINE_FILE);
  RegisterIcon('file-outline', FT_ICON_OUTLINE_FILE);
  RegisterIcon('outline-trash', FT_ICON_OUTLINE_TRASH);
  RegisterIcon('trash-outline', FT_ICON_OUTLINE_TRASH);
  RegisterIcon('place-trash-outline', FT_ICON_OUTLINE_TRASH);
  RegisterIcon('trash', FT_ICON_OUTLINE_TRASH);
  RegisterIcon('place-trash', FT_ICON_OUTLINE_TRASH);
  RegisterIcon('outline-videos', FT_ICON_OUTLINE_VIDEOS);
  RegisterIcon('videos-outline', FT_ICON_OUTLINE_VIDEOS);
  RegisterIcon('place-videos-outline', FT_ICON_OUTLINE_VIDEOS);
  RegisterIcon('videos', FT_ICON_OUTLINE_VIDEOS);
  RegisterIcon('place-videos', FT_ICON_OUTLINE_VIDEOS);
  RegisterIcon('outline-bookmark', FT_ICON_OUTLINE_BOOKMARK);
  RegisterIcon('bookmark-outline', FT_ICON_OUTLINE_BOOKMARK);
  RegisterIcon('place-bookmark-outline', FT_ICON_OUTLINE_BOOKMARK);
  RegisterIcon('bookmark', FT_ICON_OUTLINE_BOOKMARK);
  RegisterIcon('place-bookmark', FT_ICON_OUTLINE_BOOKMARK);

  { Utility Icons }
  RegisterIcon('gear', FT_ICON_GEAR);
  RegisterIcon('settings', FT_ICON_GEAR);
  RegisterIcon('info', FT_ICON_INFO);
  RegisterIcon('info-accent', FT_ICON_INFO_ACCENT, FT_ICON_INFO_ACCENT_DARK);
  RegisterIcon('about-accent', FT_ICON_INFO_ACCENT, FT_ICON_INFO_ACCENT_DARK);
  RegisterIcon('info-blue', FT_ICON_INFO_ACCENT, FT_ICON_INFO_ACCENT_DARK);
  RegisterIcon('check', FT_ICON_CHECK);
  RegisterIcon('close', FT_ICON_CLOSE);
  RegisterIcon('search', FT_ICON_SEARCH);
  RegisterIcon('refresh', FT_ICON_REFRESH);
  RegisterIcon('view-list', FT_ICON_VIEW_LIST);
  RegisterIcon('list', FT_ICON_VIEW_LIST);
  RegisterIcon('view-grid', FT_ICON_VIEW_GRID);
  RegisterIcon('grid', FT_ICON_VIEW_GRID);

  { Settings & System Icons }
  RegisterWithWhite('wlan', FT_ICON_WLAN);
  RegisterWithWhite('wifi', FT_ICON_WLAN);
  RegisterWithWhite('network-wireless', FT_ICON_WLAN);
  RegisterWithWhite('wired', FT_ICON_WIRED);
  RegisterWithWhite('network-wired', FT_ICON_WIRED);
  RegisterWithWhite('ethernet', FT_ICON_WIRED);
  RegisterWithWhite('display', FT_ICON_DISPLAY);
  RegisterWithWhite('monitor', FT_ICON_DISPLAY);
  RegisterWithWhite('preferences-desktop-display', FT_ICON_DISPLAY);
  RegisterWithWhite('appearance', FT_ICON_APPEARANCE);
  RegisterWithWhite('palette', FT_ICON_APPEARANCE);
  RegisterWithWhite('theme', FT_ICON_APPEARANCE);
  RegisterWithWhite('preferences-desktop-theme', FT_ICON_APPEARANCE);
  RegisterWithWhite('background', FT_ICON_BACKGROUND);
  RegisterWithWhite('wallpaper', FT_ICON_BACKGROUND);
  RegisterWithWhite('preferences-desktop-wallpaper', FT_ICON_BACKGROUND);
  RegisterWithWhite('dock', FT_ICON_DOCK);
  RegisterWithWhite('preferences-desktop-dock', FT_ICON_DOCK);
  RegisterWithWhite('user', FT_ICON_USER);
  RegisterWithWhite('avatar', FT_ICON_USER);
  RegisterWithWhite('account', FT_ICON_USER);
  RegisterWithWhite('system-users', FT_ICON_USER);
  RegisterWithWhite('language', FT_ICON_LANGUAGE);
  RegisterWithWhite('locale', FT_ICON_LANGUAGE);
  RegisterWithWhite('preferences-desktop-locale', FT_ICON_LANGUAGE);
  RegisterWithWhite('battery', FT_ICON_BATTERY);
  RegisterWithWhite('power', FT_ICON_POWER);
  RegisterWithWhite('battery-full', FT_ICON_BATTERY);
  RegisterWithWhite('lock', FT_ICON_LOCK);
  RegisterWithWhite('security', FT_ICON_LOCK);
  RegisterWithWhite('padlock', FT_ICON_LOCK);
  RegisterWithWhite('bluetooth', FT_ICON_BLUETOOTH);
  RegisterWithWhite('sound', FT_ICON_SOUND);
  RegisterWithWhite('audio', FT_ICON_SOUND);
  RegisterWithWhite('volume', FT_ICON_SOUND);
  RegisterWithWhite('volume-high', FT_ICON_SOUND);
  RegisterWithWhite('volume-low', FT_ICON_VOLUME_LOW);
  RegisterWithWhite('volume-mute', FT_ICON_VOLUME_MUTE);
  RegisterWithWhite('mute', FT_ICON_VOLUME_MUTE);
  RegisterWithWhite('about', FT_ICON_INFO);

  { Display, Appearance & Power Glyphs }
  RegisterWithWhite('brightness-low', FT_ICON_BRIGHTNESS_LOW);
  RegisterWithWhite('sun-low', FT_ICON_BRIGHTNESS_LOW);
  RegisterWithWhite('brightness-high', FT_ICON_BRIGHTNESS_HIGH);
  RegisterWithWhite('sun-high', FT_ICON_BRIGHTNESS_HIGH);
  RegisterWithWhite('brightness', FT_ICON_BRIGHTNESS_HIGH);
  RegisterWithWhite('selector', FT_ICON_SELECTOR);
  RegisterWithWhite('chevron-up-down', FT_ICON_SELECTOR);
  RegisterWithWhite('rotate-0', FT_ICON_ROTATE_0);
  RegisterWithWhite('rotate-standard', FT_ICON_ROTATE_0);
  RegisterWithWhite('rotate-90', FT_ICON_ROTATE_90);
  RegisterWithWhite('rotate-180', FT_ICON_ROTATE_180);
  RegisterWithWhite('rotate-270', FT_ICON_ROTATE_270);
  RegisterIcon('theme-light', FT_ICON_THEME_LIGHT);
  RegisterIcon('theme-dark', FT_ICON_THEME_DARK);
  RegisterIcon('battery-bolt', FT_ICON_BATTERY_BOLT);
  RegisterIcon('distro-logo', FT_ICON_DISTRO_LOGO_LIGHT, FT_ICON_DISTRO_LOGO_DARK);
  RegisterIcon('samarinda-logo', FT_ICON_DISTRO_LOGO_LIGHT, FT_ICON_DISTRO_LOGO_DARK);
  RegisterIcon('kirana-logo', FT_ICON_DISTRO_LOGO_LIGHT, FT_ICON_DISTRO_LOGO_DARK);
  RegisterWithWhite('display-scale', FT_ICON_DISPLAY_SCALE);

  { Dialog Severity Icons }
  RegisterIcon('dialog-info', FT_ICON_DIALOG_INFO);
  RegisterIcon('dialog-warning', FT_ICON_DIALOG_WARNING);
  RegisterIcon('dialog-error', FT_ICON_DIALOG_ERROR);
  RegisterIcon('dialog-question', FT_ICON_DIALOG_QUESTION);
  RegisterIcon('dialog-success', FT_ICON_DIALOG_SUCCESS);
end;

{ Global Accessors }

function FtIconManager(): TFtIconManager;
begin
  if not Assigned(GIconManager) then
    GIconManager := TFtIconManager.Create();
  Result := GIconManager;
end;

function FtGetIconSvg(const AName: string; ADarkMode: Boolean = False): string;
begin
  Result := FtIconManager().GetIconSvg(AName, ADarkMode);
end;

function FtGetIconBitmap(const AName: string; AW: Integer = 16; AH: Integer = 16; ADarkMode: Boolean = False): TFloriaImage;
begin
  Result := FtIconManager().GetIconBitmap(AName, AW, AH, ADarkMode);
end;

procedure FtRegisterIcon(const AName, ASvgLight: string; const ASvgDark: string = '');
begin
  FtIconManager().RegisterIcon(AName, ASvgLight, ASvgDark);
end;

initialization

finalization
  if Assigned(GIconManager) then
    FreeAndNil(GIconManager);

end.
