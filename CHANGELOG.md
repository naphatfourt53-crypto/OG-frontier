# Changelog

รูปแบบอ้างอิง [Keep a Changelog](https://keepachangelog.com/) และ semantic versioning

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
