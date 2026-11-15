# Asset credits

All artwork in this project is either generated in code (`scripts/pix.gd`) or a NASA
photograph downloaded from the NASA Image and Video Library.

NASA does not generally assert copyright over its media, and most of these images are
in the public domain. NASA imagery may be used for educational and informational
purposes; do not imply NASA endorsement of this game. Source policy:
<https://www.nasa.gov/nasa-brand-center/images-and-media/>

If an image file is removed, the game still runs: every photo call falls back to the
code-drawn art.

## Photographs in `assets/nasa/`| File | NASA ID | Subject | Date | Source |
| --- | --- | --- | --- | --- |
| `as08-14-2383.jpg` | AS08-14-2383 | Earthrise from Apollo 8, lunar horizon in the foreground | 1968-12-24 | <https://images.nasa.gov/details/as08-14-2383> |
| `as11-40-5927.jpg` | AS11-40-5927 | Apollo 11 Lunar Module Eagle on the lunar surface | 1969-07-20 | <https://images.nasa.gov/details/as11-40-5927> |
| `KSC-AS-11-40-5902.jpg` | KSC-AS-11-40-5902 | Apollo 11 astronaut during the lunar surface EVA | 1969-07-20 | <https://images.nasa.gov/details/KSC-AS-11-40-5902> |
| `S69-26301.jpg` | S69-26301 | Mission Control Center during the Apollo 9 mission | 1969-03-03 | <https://images.nasa.gov/details/S69-26301> |

Where each photo appears:

- Menu background: Earthrise, Apollo 8.
- Station hub (bottom right): Mission Control, Apollo 9.
- Mission report (top right): Lunar Module on success, astronaut EVA on failure.

All four files were fetched as `~medium.jpg` derivatives (about 65-185 KB each) from
`images-assets.nasa.gov`, so the repository stays small enough to clone over a phone
hotspot.

## Sound effects in `assets/sfx/`

Source: **The Essential Retro Video Game Sound Effects Collection (512 sounds)**
by Juhani Junkala, published on OpenGameArt under **CC0 1.0 (public domain)**:
<https://opengameart.org/content/512-sound-effects-8-bit-style>

CC0 means no attribution is required; the author is credited here anyway.

| File | Original file | Used for | Length |
| --- | --- | --- | --- |
| `click.wav` | `sfx_menu_select2.wav` | every UI button | 0.31 s |
| `launch.wav` | `sfx_exp_long3.wav` | the moment the ship leaves the pad | 1.96 s |
| `pickup.wav` | `sfx_coin_single1.wav` | collecting a Moon sample | 0.42 s |
| `build.wav` | `sfx_sounds_powerup4.wav` | building a station module | 0.74 s |
| `damage.wav` | `sfx_damage_hit2.wav` | an event that damages the hull | 0.05 s |
| `success.wav` | `sfx_sounds_fanfare1.wav` | mission report, success | 0.52 s |
| `fail.wav` | `sfx_sounds_negative2.wav` | mission report, failure | 0.76 s |

The player can turn all sound off in **Menu → SETTINGS → Sound**. The setting is
saved with the rest of the profile.

## Fonts

The project uses Godot's built-in default font (no external font files). See
`OVERNIGHT_LOG.md` for the open question about Thai font licensing.
