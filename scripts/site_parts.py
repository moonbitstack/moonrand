"""The pieces the generated pages share with the hand-written one.

Only the fret band so far: the home page draws it in the browser from the same
unit, and a reference page that is read with the network switched off should
still have its border. The unit is the one `docs/index.html` draws — a square
line folded four times — repeated at a 27.75 pitch across a 1440 viewBox that
stretches with the page, so the three pages line up at any width.
"""

from __future__ import annotations

PITCH = 27.75
COUNT = 56
DEF = "M1.94,13.8V1.8H24.14V9.9H11.38V5.7H17.48"


def band() -> str:
    uses = "".join(
        f'<use href="#band-fret" transform="translate({i * PITCH:.2f},0)"/>'
        for i in range(COUNT)
    )
    return (
        '<div class="band band--top" aria-hidden="true">'
        '<svg viewBox="0 0 1440 15" preserveAspectRatio="none">'
        f'<defs><path id="band-fret" d="{DEF}"/></defs>'
        '<path d="M0 .6H1440M0 14.55H1440" stroke="rgba(66,107,154,.5)" stroke-width=".8" fill="none"/>'
        '<g fill="none" stroke="rgba(62,103,150,.7)" stroke-width="1.5" stroke-linejoin="miter">'
        f"{uses}"
        "</g></svg></div>"
    )
