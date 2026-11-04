#!/usr/bin/env python3
"""Checks popup dismissal end to end, with real pointer and keyboard input.

Drives XTEST against examples/c/popup_dismiss.c and reads the demo's own stdout to decide
what happened, so nothing here reaches into the toolkit's internals. A passing run means
the grab, the dispatch and the dismissal callback all work on a live server.

    Xephyr :2 -screen 1280x800 -ac &
    DISPLAY=:2 ./target/example_c_popup_dismiss > /tmp/popup.log &
    python3 examples/probe_popup_dismiss.py :2 /tmp/popup.log

Checks, in order:

  1. a click inside the popup reaches its drawing area and does not close it;
  2. a click on the demo's main window closes it, even though that window belongs to the
     same client. This is the case owner_events decides, and the reason a menu-style grab
     is not enough;
  3. a second click reopens it;
  4. Escape closes it.
"""
import sys
import time

from Xlib import X, XK, display
from Xlib.ext import xtest


def count(path, needle):
    try:
        with open(path, 'r', errors='replace') as f:
            return sum(1 for line in f if needle in line)
    except FileNotFoundError:
        return 0


def wait_for_count(path, needle, want, timeout=10.0):
    deadline = time.time() + timeout
    while time.time() < deadline:
        if count(path, needle) >= want:
            return True
        time.sleep(0.1)
    return False


def popup_rect(dpy):
    """The popup is override-redirect and has no title, so match on its size."""
    d = display.Display(dpy)
    for w in d.screen().root.query_tree().children:
        g = w.get_geometry()
        if (g.width, g.height) == (300, 200) and w.get_attributes().map_state == 2:
            return (g.width, g.height, g.x, g.y)
    return None


def click(d, x, y):
    xtest.fake_input(d, X.MotionNotify, x=x, y=y)
    d.sync()
    time.sleep(0.15)
    xtest.fake_input(d, X.ButtonPress, 1)
    d.sync()
    time.sleep(0.05)
    xtest.fake_input(d, X.ButtonRelease, 1)
    d.sync()
    time.sleep(0.4)


def press_escape(d):
    code = d.keysym_to_keycode(XK.string_to_keysym('Escape'))
    xtest.fake_input(d, X.KeyPress, code)
    d.sync()
    time.sleep(0.05)
    xtest.fake_input(d, X.KeyRelease, code)
    d.sync()
    time.sleep(0.4)


def main():
    dpy = sys.argv[1]
    log = sys.argv[2]
    d = display.Display(dpy)

    if not wait_for_count(log, 'READY', 1):
        print('FAIL: the demo never reported READY')
        return 1

    rect = popup_rect(dpy)
    if rect is None:
        print('FAIL: the popup window was not found')
        return 1
    w, h, px, py = rect
    print('popup: %dx%d at %d,%d' % (w, h, px, py))

    # 1. Inside the popup: the child sees it, and the popup stays open.
    click(d, px + w // 2, py + h // 2)
    if not wait_for_count(log, 'CLICK', 1):
        print('FAIL: a click inside the popup did not reach the drawing area')
        return 1
    print('ok: a click inside reached the drawing area')
    if count(log, 'DISMISSED') != 0:
        print('FAIL: a click inside closed the popup')
        return 1
    print('ok: a click inside did not close the popup')

    # 2. Outside the popup but inside the demo's main window: same client, different
    #    window. With owner_events = 1 this click would go to the main window and the
    #    popup would never learn it had been dismissed.
    click(d, 120, 120)
    if not wait_for_count(log, 'DISMISSED', 1):
        print('FAIL: a click on another window of the same client did not close the popup')
        return 1
    print('ok: a click on the same client but outside the popup closed it')

    # 3. The click above was swallowed by the grab, so it must not have reopened anything.
    if count(log, 'READY') != 1:
        print('FAIL: the dismissing click also reached the main window')
        return 1
    print('ok: the dismissing click did not reach the window underneath')

    # A second click now reaches the main window and reopens the popup.
    click(d, 120, 120)
    if not wait_for_count(log, 'READY', 2):
        print('FAIL: the popup did not reopen')
        return 1
    print('ok: the popup reopened')

    # 4. Escape closes it. The keyboard grab is what delivers this.
    press_escape(d)
    if not wait_for_count(log, 'DISMISSED', 2):
        print('FAIL: Escape did not close the popup')
        return 1
    print('ok: Escape closed the popup')

    print('RESULT OK')
    return 0


if __name__ == '__main__':
    sys.exit(main())
