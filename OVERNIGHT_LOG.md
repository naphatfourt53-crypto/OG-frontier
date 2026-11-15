# OVERNIGHT_LOG — งานคืนวันที่ 2026-11-14

branch: `overnight/opencode` (แยกจาก `main` ที่เป็น snapshot แรก)
เป้าหมาย: ทำให้ prototype เดโมได้จริง ตรวจสอบได้ และส่งต่อทีมได้ทันที

---

## 1) สรุปสถานะตามงานใน brief

| งาน | สถานะ | สิ่งที่ทำ | หลักฐาน |
| --- | --- | --- | --- |
| **T0** bootstrap & รันได้ | ✅ เสร็จ | import โปรเจกต์, แก้ label wrapping, แก้ Control sizing warning, ทำ overlay เหตุการณ์ให้อ่านง่าย | commit `6b07dd2`, เปิดเกม/headless ได้ |
| **T1** headless smoke test | ✅ เสร็จ | `tests/smoke_test.gd` 121 checks ครอบทุกฉาก/สูตร/Game Over/save | `PASS smoke_test (121 checks)` |
| **T2** Python parity | ✅ เสร็จ | `--emit-golden` + เทียบ 5 designs ภายใน 1% | `parity checked 5 design(s)` |
| **T3** assets & NASA images | ✅ เสร็จ (แบบไม่ต้องมี artist) | `Pix.tex/photo/photo_frame` + cache, รูป NASA 4 รูป, fallback วาดด้วยโค้ด, `assets/CREDITS.md` | screenshot 01/02/09 |
| **T4** data & gameplay | ✅ เสร็จ | ทรัพยากรบนดวงจันทร์ 4 ชนิด + ตัวนับ + สรุปรายงาน + mirror ใน Python | smoke test + screenshot 08/09 |
| **T5** audio | ✅ เสร็จ | เสียง CC0 7 ไฟล์ + autoload `Sfx` (pool 8), mute ใน Settings, `audio_check.gd` | `AUDIO OK (7 sounds)` |
| **T6** UX/game feel & settings | ✅ เสร็จ (ตามการตีความ) | fade 0.25 s, Esc back, tutorial 3 ขั้น, settings EVA 30–300 s, typewriter, flash/shake, `*` recommended, delta-v tooltip | screenshot 10/11, commit `fae92b6` |
| **T7** export presets | ✅ เสร็จ | ติดตั้ง templates 4.7.2, build Web + Windows สำเร็จ | `builds/web/`, `builds/windows/`, หัวข้อ 3.4 |
| **T8** เอกสาร | ✅ เสร็จ | README ไทยฉบับใหม่, CHANGELOG, AGENTS.md, OVERNIGHT_LOG (ไฟล์นี้) | commit สุดท้าย |

> หมายเหตุ: T5/T6 อ้างอิงชื่อจาก brief ที่ได้รับตอนเริ่มงาน ถ้าลำดับใน brief ต่างจากนี้
> ให้ถือว่า "สิ่งที่ทำ" คือของจริง

---

## 2) Commit log

| commit | เนื้อหา |
| --- | --- |
| `532f97e` | import prototype snapshot + Game Data Book |
| `6b07dd2` | fix UI label wrapping/screen sizing, dim flight events, screenshot harness |
| `e0c9bb4` | headless smoke test + golden parity กับ `balance_check.py` |
| `1847cfb` | moon resource pool + saved settings (save v2) |
| `fae92b6` | settings overlay, tutorial, fade, flight juice, mission notes, hangar stars |
| `57549af` | NASA photo loader + fallbacks + CREDITS |
| `59adbd8` | docs: README/CHANGELOG/AGENTS/OVERNIGHT_LOG + export presets |
| (ถัดไป) | feat(audio): SFX 7 ไฟล์ CC0 + mute + audio check; build Web/Windows |

ทุก commit ผ่าน `tests/smoke_test.gd` ก่อน commit (ไม่แตะ `main`, ไม่ force push)

---

## 3) หลักฐานการตรวจ (คัดลอก output จริง)

### 3.1 Smoke test

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

  sample run: success=false score=86 data=43
  smart run: success=true score=1117 data=48
  weak run: reason=Stranded
  parity checked 5 design(s)
PASS smoke_test (121 checks)
```

- sample design + เลือกตัวเลือก 0 ทุกครั้ง → ล้มเหลวด้วย `Oxygen Depletion` (ตรงตามดีไซน์: ต้องเล่นฉลาด)
- heuristic "sensible player" + seed `424242` → ชนะ score 1117
- weak design → `Stranded`

### 3.2 Screenshot

```text
shot 01_menu          1280x720
shot 02_station       1280x720
shot 03_hangar        1280x720
shot 04_mission       1280x720
shot 05_flight        1280x720
shot 06_event         1280x720
shot 07_event_result  1280x720
shot 08_explore       1280x720
shot 09_report        1280x720
shot 10_settings      1280x720
shot 11_tutorial      1280x720
SCREENSHOTS OK
```

ตรวจด้วยตาทุกภาพ: เมนู (Earthrise + ยาน), สถานี (แผนผัง + รูป Mission Control),
Hangar (ตัวเลขสี + `*`), Mission (note กระบวนงาน), Flight/Event (ข้อความไม่ทับ HUD),
Explore (ตัวนับ 4 ชนิด), Report (รูป + samples + คะแนน), Settings (สไลเดอร์ 60 s), Tutorial (3 ขั้น)

### 3.3 Python balance

```text
EVA sample pool: 165 pts if you collect everything; a good walk (about half) = 82 pts
SAMPLE DESIGN  mass 94.4 t  cost 307/340  dv 6.18 (need 6.06)  power net +6.5 kW  launchable=True
```

### 3.4 Export (build ผ่านแล้ว)

หลังติดตั้ง export templates 4.7.2 (242 MB ที่ใช้จริง: web + windows x86_64):

```text
EXIT=0
builds/web/index.html        5538
builds/web/index.pck          3.09 MB
builds/web/index.wasm        39.5 MB
builds/web/index.js          280 KB

EXIT=0
builds/windows/OGFrontier.exe  109 MB
builds/windows/OGFrontier.pck    3.1 MB
```

ก่อนติดตั้ง template ข้อความ error คือ:

```text
No export template found at the expected path:
C:/Users/narong/AppData/Roaming/Godot/export_templates/4.7.2.stable/web_nothreads_release.zip
   at: _fs_changed (editor/editor_node.cpp:1401)
ERROR: Project export for preset "Web" failed.
```

(เก็บไว้เป็นหลักฐานว่า preset ถูกอ่านถูกต้องตั้งแต่แรก และเพื่อให้ทีมรู้จัก error นี้)

### 3.5 เสียง

```text
  click    ok  0.31 s
  launch   ok  1.96 s
  pickup   ok  0.42 s
  build    ok  0.74 s
  damage   ok  0.05 s
  success  ok  0.52 s
  fail     ok  0.76 s
AUDIO OK (7 sounds)
```

---

## 4) ปัญหาที่เจอและวิธีแก้ (เก็บไว้ให้ทีม)

1. **Label ข้อความล้นกรอบ** — `Label.autowrap_mode` ต้องตั้งก่อน `size`
   เพราะ `set_size()` ถูก clamp ด้วย minimum width ของข้อความที่ยังไม่ wrap
   แก้ใน `Pix.lbl` (T0)
2. **Warning "Control was not set to full rect"** — หน้า scene root ใช้ anchor เต็มจอ
   แต่โค้ดไป set `size` ทับ; ลบการ set size และเรียก `set_anchors_and_offsets_preset` (T0)
3. **Console แสดงภาษาไทยเพี้ยน** — Windows console ที่ใช้เป็น cp932
   ไฟล์ทั้งหมดเป็น UTF-8 ถูกต้อง; หลีกเลี่ยงการ print ข้อความหรือ path ภาษาไทย
   (ใช้ `Get-Content` ดูใน editor แทน)
4. **`Godot.exe --version` ค้าง** — ต้องใส่ `--headless` ทุกครั้งที่รันแบบไม่มีหน้าต่าง
5. **`python` เฉยๆ ค้าง** — ใช้ path เต็ม `C:\Program Files\Python313\python.exe`
6. **ดาวน์โหลด NASA รูปหนึ่งได้ 403** — URL ตรง `images-assets.nasa.gov/image/AS11-40-5902/...`
   ใช้ไม่ได้; ต้องใช้ ID จาก search result (`KSC-AS-11-40-5902`) แล้วโหลด `~medium.jpg`
   บทเรียน: ใช้ URL จาก `images-api.nasa.gov/search` ไม่เดา path เอง
7. **Screenshot ต้องมีหน้าต่างจริง** — `--headless` ไม่มี framebuffer ทำให้ได้ภาพดำ/ไม่มีไฟล์

---

## 5) สิ่งที่ยังไม่ได้ทำ / ความเสี่ยง

| เรื่อง | ผลกระทบ | ทางแก้ที่แนะนำ |
| --- | --- | --- |
| ยังไม่ได้อัปโหลดขึ้น itch.io | เดโมยังไม่ได้อยู่บนเน็ต | ต้องมีบัญชี itch.io + `butler` ของทีม; build พร้อมแล้วที่ `builds/web/` (zip ทั้งโฟลเดอร์) |
| ยังไม่มีฟอนต์ไทย | ถ้าจะแปลเกมเป็นไทยต้องเปลี่ยนฟอนต์ | ใช้ฟอนต์ OFL (เช่น Noto Sans Thai) แล้วบันทึก license ใน CREDITS |
| EVA 165 แต้มอาจมาก/น้อยเกินไป | คะแนนรวมอาจเฟ้อ | ปรับ `moon_resources[].pts` ใน JSON และ mirror ใน `balance_check.py` |
| รูป NASA เป็นภาพนิ่ง ไม่มี artist asset | ภาพยังเป็น pixel-art + รูปจริง | ถ้ามีเวลาว่าง ทำ sprite pixel จริงแทน `Pix.draw_ship` |
| เสียงเป็น 8-bit SFX ไม่มีเพลงประกอบ | อาจฟังดูเรียบในเดโมยาว | เพิ่มเพลง loop CC0 ในเมนู/flight และ bus แยกสำหรับ music |

---

## 6) จุดต่อสำหรับงานถัดไป (เรียงตามความคุ้มค่า)

1. อัปโหลด `builds/web/` ขึ้น itch.io (ช่อง HTML5) แล้วทดสอบบนมือถือ/เน็ตจริง
2. ใส่เพลงประกอบ CC0 2 ท่อน (เมนู + flight) และทำ bus Music/SFX ใน `default_bus_layout`
3. ทำ mission ที่ 2 (ดาวอังคาร) ให้ใช้ระบบเดิมซ้ำ — เปลี่ยนแค่ข้อมูลใน JSON
4. ปรับสมดุล EVA จาก playtest จริง 2–3 คน แล้วรัน `--emit-golden`
5. ถ้าต้องการภาษาไทย: เพิ่ม font + ปุ่มสลับภาษา แล้วแยกสตริงออกจากโค้ด (ตอนนี้ฝังใน `.gd`)

---

## 7) คำถามที่ยังไม่ได้ข้อสรุป (ต้องการคำตอบจากทีม)

1. **การเปิดเผยการใช้ AI** — ข้อกำหนด Space Apps ต้องการให้ระบุว่าใช้ AI ช่วยอะไร
   ต้องเขียนใน submission หรือไม่ และต้องการถ้อยคำแบบไหน
2. **ขอบเขตเดโม** — เอาแค่ภารกิจดวงจันทร์ + ปลดล็อกดาวอังคาร (ตอนนี้) หรือต้องมีภารกิจดาวอังคารเล่นได้จริง
3. **ขนาดลูกเรือ** — ข้อมูลภารกิจบอก crew 3 คน แต่สูตรเสบียงใน `game_state.gd`
   คิดต่อคนต่อวัน ต้องยืนยันว่าค่าในเกมควรคิด 3 เท่าหรือคงเป็น 1 เท่าเพื่อความสนุก
4. **ภาษาไทย / ฟอนต์** — เกมเป็นอังกฤษตาม brief แต่ทีมอาจต้องการปุ่มสลับภาษา
   ถ้าใช้ฟอนต์ภายนอกต้องเช็ก license (OFL) และเพิ่มใน CREDITS
5. **ไฟล์ที่ต้องส่ง** — ต้องการแค่ repo + วิดีโอเดโม หรือต้องมี `.exe`/ลิงก์เว็บ/สไลด์ด้วย
6. **"ลบปีศาจยานแม่"** — ข้อความในแชททีมไม่ตรงกับคอนเซปต์ใดในโค้ด
   (ไม่มี enemy/mothership) ต้องให้ผู้ส่งอธิบายว่าหมายถึงอะไรก่อนแก้

---

## 8) วิธีตรวจซ้ำแบบเร็ว (สำหรับคนที่มารับช่วงต่อ)

```powershell
$godot = "C:\Users\narong\OneDrive\VS_Code_Python\อบรม สจล\โปรเจคแก้ปัญหา01\Godot_v4.7.2-stable_win64_console.exe"
& $godot --headless --path . -s tests/smoke_test.gd
& $godot --path . -s tools/screenshots.gd --resolution 1280x720
& $godot --path . -s tools/audio_check.gd
& "C:\Program Files\Python313\python.exe" tools\balance_check.py
# build ใหม่หลังแก้โค้ด (ต้องมี templates)
& $godot --headless --path . --export-release "Web" "builds/web/index.html"
& $godot --headless --path . --export-release "Windows Desktop" "builds/windows/OGFrontier.exe"
```

ถ้าทุกคำสั่งผ่าน (PASS / 11 ภาพ / AUDIO OK / ตัวเลขตรง / export EXIT=0) ถือว่าพร้อมเดโม
