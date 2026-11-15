# Changelog

รูปแบบอ้างอิง [Keep a Changelog](https://keepachangelog.com/) และ semantic versioning

## [0.5.0] - 2026-11-15 (Phase 1 + Phase 2 + guide; Phase 3 pending)

### Added (Phase 2 + guide)

- **ISS walkable**: crew member walks with WASD/arrows, rooms block the way,
  E enters or builds the room next to you; hover any room for a picture card.
- **First-mission guide**: the top line of the ISS names the next step
  (Hangar -> Mission Control -> Moon -> home). Hangar and Mission Control
  have a GUIDE line; the flight and Moon-walk screens have HOW TO lines.
- **Story on first visit** plays on the ISS (embedded overlay); STORY button
  replays it.
- **HOW TO PLAY** (5 pages) and **TECH BOOK** (STATION, SHIP, FLIGHT, EVA,
  MISSIONS) built from the data files; facts tagged Real basis / Game rule.
- Menu cleaned: START / SETTINGS / RESET SAVE / QUIT.
- UI pass: rounded panels with shadows, hover border on buttons, station header bar.

### Changed (Phase 2 + guide)

- Insufficient Data now shows a red message naming the shortfall.

### Added (Phase 3: campaign)

- **8-mission campaign**: the crewed Moon mission plus seven robotic probes (Mars lander and sample return, Venus, Mercury, Jupiter, Saturn, Uranus, Neptune). Mars is a robot, not a crewed flight: a crewed Mars round trip needs about 11 km/s and 16 t of supplies for 900 days, which this ship cannot carry.
- **Real flight times**: each probe flies its Hohmann transit (calc from physics.json orbit constants). It arrives on the real day and waits for the encounter.
- **Real launch windows**: a probe launches only in its synodic window (Mercury 116 d, Venus 584 d, Mars 780 d, Jupiter 399 d, Saturn 378 d, Uranus 370 d, Neptune 367 d). The window start uses a game epoch on day 1 (game rule).
- **PROBE CONTROL** (from the ISS): launch, wait for the window, run the encounter on arrival.
- **Encounters**: station-keeping (hold the cursor inside the moving zone; 70% pass line) for lander and orbiter probes; gas scoop (choose a depth: more gas, more risk) for gas giants.
- **Deadline**: 12,000 game days (game rule) and a 180-day epilogue after the last completed mission. Win = all eight done and the epilogue passed. Lose = the deadline first.
- **Result screen** (win and lose) and a RESULT button on the ISS once the campaign is over.
- Tech Book: PROBES tab (real transit and window numbers; costs tagged game).
- Save version 8 (campaign). Version 7 saves migrate: a Moon success becomes a completed Moon mission.
- check_physics: campaign mirror (transits, synodic periods, and the best finish order: day 11,215 with the epilogue at 11,395, under the 12,000 deadline).

### Changed (Phase 3)

- Crewed Mars dossier removed from Mission Control (Mars is a probe now).
- Thermal roll skip can now destroy the hull (hull floor at zero, ends the run).

### Not yet (later)

- Gas-giant, Mercury and Venus numbers are game values until the team adds them to the Data Book.
- Comms delay on Mars is shown as text only (3 to 22 minutes); no timed decisions yet.
- Crewed Mars (one-way plus ISRU) is a future redesign.
- Further visual polish (Phase 4 continues).

รอบแก้ตาม feedback ทีม + ไฟล์งาน T10–T19 (เฟส 1 จากทั้งหมด 3 เฟส)

### Added

- **T17 กิจกรรมระหว่างบิน**: เล็งดาวนำทาง 2 ครั้ง (ถือเมาส์ในวง 6 วิ), เผาเครื่อง
  แก้ทาง (กดค้าง 3 วิ, nominal 6.37 m/s จาก Apollo 11), thermal roll (ข้าม = hull
  -2%/วัน), ตารางออกกำลังกายลูกเรือ (0/1/2 ชม. กระทบ stamina ตอนถึง), มินิเกม
  ทั้งหมดอ่านสัดส่วน trigger จาก `data/activities.json`
- **T18 เดิน 3 รอบ**: จอพักระหว่างรอบ + stamina เติมเต็ม, งานย่อยบนผิว
  (prep เลือกเครื่องมือ / document ถ่ายภาพ ×1.5 / core เจาะแท่งดิน ×2.0 /
  deploy วางเครื่องวัด +3 แต้มทุกรอบถัดไป), มวลตัวอย่างเข้าระบบ rocket equation
  ก่อน burn กลับ, จอทิ้งตัวอย่างก่อนขึ้นยาน
- ระบบ **run plan** ใน `GameState` แทน STEPS ตายตัว + ค่า penalty dv เมื่อเผา
  เครื่องไม่ครบ + morale gate เหตุการณ์ ("Rally the crew" ต้องเก็บเกี่ยวผักก่อน)
- **Delayed comms** (Mars-class): เหตุการณ์มีเวลาจำกัด 15 วิ (ยังไม่ถูกใช้จนกว่า
  ภารกิจ Mars มีข้อมูลในเฟส 3)
- ไฟล์ทีมเข้า repo: `data/activities.json`, `data/destinations.json`,
  `tools/check_physics.py` (45 checks, tags ครบทุกคีย์)
- `tests/test_stamina_physics_farm.gd` (18 checks เทียบ AC ของ T10)

### Changed

- Save v5 (`harvest_count`); save เก่ายังโหลดได้
- `finish_explore()` รับ `sample_kg/walks_log/deploys` (default ครบ, ของเดิมไม่พัง)
- `Stamina.create()` รับ `capacity_mult` (ตารางออกกำลังกาย)
- ป้าย "Real basis: Apollo 11" / "Game rule" บนทุกจอ T17/T18

### Fixed

- (ไม่มีบั๊กเก่า; smoke test ขยาย 161 → 191 checks)

## [0.4.1] - 2026-11-15

แพ็กเกจสำหรับแจกทีม: แก้ปัญหาเปิดโปรเจกต์ผิดโฟลเดอร์, เครื่องเก่าเปิด exe ไม่ได้
และเพิ่มช่องทางเล่นผ่านเว็บที่ไม่ต้องใช้ไดรเวอร์การ์ดจอ

### Added

- **`START_HERE.txt`** และ **`docs/TEAM_GUIDE.md`**: ขั้นตอนเปิดเกม 3 ทาง
  (Windows / Web / Godot) พร้อมตารางแก้ error ที่ทีมเจอจริง
- **`OPEN_IN_GODOT.bat`** / **`OPEN_IN_GODOT_SAFE.bat`**: ตรวจว่าอยู่โฟลเดอร์ที่มี
  `project.godot` แล้วเปิด editor ให้ (safe mode บังคับ OpenGL 3.3)
- **`tools/package_team.ps1`**: สร้าง ZIP แจกทีมครบชุด
  (Project / Windows / Web / Legacy) + `SHA256SUMS.txt`
- **`tools/launchers/`**: `RUN_LAST_LAUNCH.bat` (ลอง Vulkan → OpenGL 3.3 ให้อัตโนมัติ),
  `RUN_LAST_LAUNCH_SAFE.bat` (บังคับ OpenGL 3.3),
  `PLAY_WEB.bat` + `serve_web.ps1` (local server ในตัว ไม่ต้องมี Python)
- แพ็กเกจ **Legacy v0.1.0** จาก commit แรก (ต้นฉบับ 7 หน้าจอ) สำหรับเทียบพัฒนาการ

### Changed

- **`RUN_LAST_LAUNCH.bat` เลือก renderer ให้เอง**: เปิดด้วย Vulkan ก่อน ถ้าไม่ขึ้น
  จะลอง OpenGL 3.3 แล้วค่อยบอกให้ไปใช้เวอร์ชันเว็บ — ไม่ต้องตั้ง `gl_compatibility`
  เป็นค่าเริ่มต้นของโปรเจกต์ (เครื่องที่ไม่มี OpenGL 3.3 จะเปิด editor ไม่ได้)
- Windows export **ฝัง `.pck` ใน exe** (`embed_pck=true`) — แจกแล้วไม่ต้องก็อป `.pck` แยก
- เพิ่ม `config/version="0.4.1"`
- README/AGENTS อัปเดตวิธีเปิดเกม การ build และการแจกไฟล์

### Fixed

- เปิดโปรเจกต์ในโฟลเดอร์แม่ (ที่มีแค่ `data/docs/scripts` จาก addon zip)
  ทำให้ FileSystem ว่างและขึ้น `Can't open file 'menu.tscn'` — ตอนนี้มีสคริปต์ตรวจและคู่มือ
- Windows SmartScreen และ error `Unable to initialize video driver`
  มีคู่มือ + ทางออกเว็บที่ใช้ software WebGL
- ดับเบิลคลิก `index.html` แล้วเกมไม่ขึ้น — `PLAY_WEB.bat` เปิด local server ให้อัตโนมัติ

## [0.4.0] - 2026-11-15

เดโมตาม brief ใหม่: Earth กำลังร้อน, ISS เป็น lobby, ปลูกอาหาร, ออกแบบยานตามจุดหมาย
และ EVA แบบมีขีดจำกัดเพื่อหา ore ให้เตา Helios

### Added

- **Story briefing 3 สไลด์** (`story.gd` / `story.tscn`) ก่อนเข้าสถานีครั้งแรก
  พร้อมปุ่ม STORY ที่เมนูเพื่อเปิดดูซ้ำ
- **Tutorial เต็ม 6 สไลด์** (`tutorial.gd` / `tutorial.tscn`) เปิดจากเมนู สถานี
  และ Settings; ยังคง overlay สั้น 3 ขั้นเดิมไว้ที่สถานี
- **Crew cabin** (`ship.gd` / `ship.tscn`): greenhouse, science desk, suit locker,
  galley, bunk และ terminal — ปลูกผัก ศึกษา samples พักผ่อน และโหลด gear
- **ISS Terminal v0.1** (`computer.gd` / `computer.tscn`): วัน/วันที่/ตำแหน่ง,
  smelter ore, mission files และ dossier ของ Moon/Mars
- **Mission dossier modal** ใน Mission Control: environment, hazards, resources,
  recommended gear, scout note และ station support
- **In-flight crew activities** ในหน้า Flight: hydroponics (+2 kg food),
  study (+5 science), EVA prep (+8% hull) — ใช้เวลาหนึ่งวันและกินเสบียงจริง
- **EVA stamina/pace**: `1` easy, `2` normal, `3` hard, `Shift` burst,
  stamina bar, reserve warning และจบ EVA เมื่อพลังหมด
- **Scout drone** เพิ่มเวลา EVA 25%; **radiation blanket** ลด flare damage 40%;
  อาหารจาก ISS ลดอาหารที่ต้องบรรทุก
- **Helios ore/smelter progress** บันทึกใน save และแสดงในสถานี/terminal/report
- **ฟาร์มจริง**: `farm.gd` + `data/farm.json` (NASA BVAD crop data), 1 plot,
  วงจร lettuce 28 วัน, harvest เข้า food store
- **Stamina/physics data**: `stamina.gd`, `physics.gd` พร้อม JSON และตัวเลขจริง
- **Smoke test 161 checks**: ฉากใหม่, farm, prep, food offset, stamina, crew activity,
  dossier fields และ save version
- **Screenshot 18 ภาพ**: story, tutorial เต็ม, crew cabin, terminal, dossier, crew overlay

### Changed

- `save_version` = **4** เพิ่ม `story`, `day`, `food`, `prep`, `plots`, `ore`
  (เซฟ v1–v3 ยังโหลดได้ด้วยค่า default)
- เมนูมี START → story ครั้งแรก, HOW TO PLAY, STORY, SETTINGS, RESET, QUIT
- สถานีมีปุ่ม CREW CABIN, TERMINAL, HOW TO PLAY และจัดตำแหน่งโมดูลใหม่
  (Exercise Bay ไม่ทับ header)
- Hangar มีลิงก์ Crew cabin/Terminal และแสดง ISS food/scout/rad kit
- Hangar/สถานี/Flight ไม่มี full-screen Control ที่บล็อกเมาส์แล้ว (mouse filter fix)
- `balance_check.py` อ่าน JSON แบบ UTF-8 และรองรับ food store
- README/AGENTS อัปเดตจำนวน test, ภาพหน้าจอ, save version และแผนที่โค้ด

### Fixed

- อาหารจาก ISS ถูกหักออกจาก food store ตอน launch แต่ไม่ถูกโหลดขึ้นยาน
  ทำให้เที่ยวบินที่มี delay 2 วันอดอาหารทั้งที่ควรมีอาหารพอ ตอนนี้โหลดเข้าคลังบนยานแล้ว
  และมี smoke check ยืนยันว่าอาหารที่ offset ไม่หายไป
- ปุ่มใน Hangar/Station/Flight กดไม่ติดเพราะ overlay โปร่งใสกิน mouse input
- ข้อความ typewriter ใน event ถูกถ่ายภาพตอนยังพิมพ์ไม่จบ (screenshot harness)
- HUD ของ EVA ล้นบรรทัดทับ stamina bar
- ข้อความประวัติการเล่นในเมนูถูกตัดขอบล่าง
- ปุ่ม NEXT/SKIP ของ story/tutorial คาบเส้นขอบ panel

## [0.3.0] - 2026-11-14

เสียง, build จริง และสถานะ T5/T7 ที่ปิดได้

### Added

- **เสียง 7 จุด**: ปุ่มทุกปุ่ม, launch, เก็บตัวอย่าง, สร้างโมดูล, hull damage,
  mission success และ failure — ผ่าน autoload `Sfx` (pool 8 players, ไม่ตัดเสียงกัน)
- **ปุ่ม Sound: ON/OFF** ใน Settings พร้อมบันทึกค่าลงเซฟ
- `tools/audio_check.gd` ตรวจว่าไฟล์เสียงทั้ง 7 โหลดและเล่นได้จริง
- Build จริง: `builds/web/` (Web) และ `builds/windows/OGFrontier.exe`
  หลังติดตั้ง export templates 4.7.2

### Changed

- `save_version` = **3** เพิ่มคีย์ `sound` (เซฟ v1–v2 ยังโหลดได้)
- README มีหัวข้อตรวจเสียง, วิธี build และเครดิตเสียง

## [0.2.0] - 2026-11-14

งานคืนเดียวเพื่อทำให้เดโมพร้อม (branch `overnight/opencode`)

### Added

- **Tutorial ในเกม**: overlay 3 ขั้นในหน้าสถานี เปิดอัตโนมัติครั้งแรก
  และเปิดซ้ำได้ด้วยปุ่ม `?`
- **Settings**: สไลเดอร์เวลา EVA 30–300 วินาที (ค่าเริ่มต้น 60) และปุ่มเล่น tutorial ซ้ำ
- **ทรัพยากรบนดวงจันทร์ 4 ชนิด**: Regolith 5 แต้ม, Ilmenite 10, Ice 15,
  Helium-3 25 (รวม 165 แต้ม) พร้อมที่อยู่เฉพาะ (หลุมมืด / outcrop)
- **ตัวนับรายชนิด** บน HUD ของ EVA และสรุปในรายงานผล
- **NASA photos**: Earthrise (เมนู), Mission Control (สถานี), Lunar Module / EVA (รายงาน)
  โหลดผ่าน `Pix.tex()` แบบ cache และมี fallback เป็นภาพวาดโค้ดถ้าไฟล์หาย
  พร้อม `assets/CREDITS.md`
- **Export presets**: Web (ไม่ใช้ threads) และ Windows Desktop ใน `export_presets.cfg`
- **เทสต์และเครื่องมือ**: `tests/smoke_test.gd` (121 checks), `tests/golden.json`,
  `tools/screenshots.gd` (11 ภาพ), `tools/balance_check.py --emit-golden`
- **เอกสาร**: README ภาษาไทยฉบับตรวจสอบแล้ว, `AGENTS.md`, `OVERNIGHT_LOG.md`

### Changed

- **สมดุล EVA**: เปลี่ยนจากการเก็บแต้มลอยตัวเป็นการเก็บตัวอย่างรายชนิด
  และปรับ `tools/balance_check.py` ให้ตรงกัน
- **รายงานผล**: เพิ่มบรรทัด `MOON SAMPLES (xx s EVA)` และย้าย layout ให้เห็นคะแนนชัดขึ้น
- **Mission Control**: เพิ่ม note กระบวนงานจริง (Apollo 8 LOI, PDI ~12 นาที,
  ascent rendezvous) ในแต่ละ leg
- **Hangar**: ปุ่มตัวเลือกที่แนะนำมี `*`, tooltip อธิบาย delta-v
- **Save format**: `save_version` = 2 (เพิ่ม `eva`, `tutorial`; เซฟ v1 ยังโหลดได้)
- `project.godot` ตั้ง `config/features` เป็น `4.7`

### Fixed

- Label ที่ autowrap ไม่ทำงานเพราะตั้ง `size` ก่อน `autowrap_mode` (ข้อความล้นกรอบ)
- Warning เรื่องการกำหนด `size` บน Control ที่ใช้ anchor เต็มจอ
- ข้อความเหตุการณ์บนหน้า Flight อ่านยากเมื่อทับ HUD — เพิ่มฉากมืดและ typewriter

### Known issues

- ~~ยังไม่มีเสียง (T5)~~ แก้แล้วใน 0.3.0
- ~~เครื่องที่ทำยังไม่ได้ติดตั้ง export templates จึงยังไม่ได้ build จริง~~ แก้แล้วใน 0.3.0
- ยังไม่มีฟอนต์ไทยในเกม (ข้อความในเกมเป็นอังกฤษตาม brief)

## [0.1.0] - 2026-11-13

### Added

- Prototype แรกจาก Game Data Book: สถานีแบบกิ่งก้าน, Hangar 7 ชิ้นส่วน,
  Mission Control, Flight + เหตุการณ์สุ่ม, Moon Walk, Mission Report
- สมการจรวด, ระบบเสบียง O₂/น้ำ/อาหาร, ไฟฟ้า, Hull, Game Over 5 แบบ
- `tools/balance_check.py` จำลองสมดุลด้วย Python
- `docs/OG-Frontier_Game_Data_Book.pdf`
