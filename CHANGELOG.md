# Changelog

รูปแบบอ้างอิง [Keep a Changelog](https://keepachangelog.com/) และ semantic versioning

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
