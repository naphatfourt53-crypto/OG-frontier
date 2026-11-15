# AGENTS.md — คู่มือสำหรับคนและ AI ที่ทำงานต่อ

ไฟล์นี้อธิบายกฎของ repo นี้ อ่านก่อนแก้โค้ดทุกครั้ง
(มนุษย์อ่านคู่กับ `README.md`; AI agent อ่านคู่กับ `OVERNIGHT_LOG.md`)

## 1) Stack และข้อกำหนดตายตัว

- **Godot 4.7.2 Standard** (ไม่ใช่ .NET), GDScript เท่านั้น
- ไม่มี addon / plugin / C# / ไลบรารีภายนอก / npm / build step
- เกมข้อความเป็นภาษาอังกฤษ (ตาม brief) แต่เอกสารทีมเป็นภาษาไทยได้
- **ตัวเลขสมดุลทั้งหมดอยู่ใน `data/game_data.json`** ห้าม hardcode ในสคริปต์
  (ยกเว้นค่าคงที่ของการวาด/ความเร็วเดิน/ขนาด UI)
- ถ้าแก้สูตรหรือคะแนน ต้องแก้ `tools/balance_check.py` ให้ตรงกันและอัปเดต `tests/golden.json`
- Save format ต้อง backward compatible: เพิ่มคีย์ใหม่ได้, ห้ามลบคีย์เก่า,
  bump `GameState.SAVE_VERSION` และใส่ default ที่เท่ากับพฤติกรรมเดิม
- Repo workflow: ทำงานบน branch `overnight/opencode` หรือ `feature/*`
  **ห้าม force push, ห้าม commit ลง `main` ตรงๆ**
- Commit หลังงานเสร็จแต่ละก้อน และ **เกมต้องเปิดได้ก่อน commit** (รัน smoke test)

## 2) คำสั่งที่ใช้บ่อย (Windows PowerShell)

```powershell
$godot = "C:\Users\narong\OneDrive\VS_Code_Python\อบรม สจล\โปรเจคแก้ปัญหา01\Godot_v4.7.2-stable_win64_console.exe"

# 1. gate หลัก (ไม่ต้องมีหน้าต่าง)
& $godot --headless --path . -s tests/smoke_test.gd
#    ต้องจบด้วย: PASS smoke_test (161 checks)

# 1b. เทสต์ตัวเลข stamina/physics/farm (T10)
& $godot --headless --path . -s tests/test_stamina_physics_farm.gd
#    ต้องจบด้วย: PASS test_stamina_physics_farm (18 checks)

# 1c. ตัวเลขฟิสิกส์ด้วย Python (tags ครบทุกคีย์)
& "C:\Program Files\Python313\python.exe" tools\check_physics.py
#    ต้องจบด้วย: ALL PASS (exit 0)

# 2. ภาพทุกหน้าจอ (ต้องมีหน้าต่างจริง)
& $godot --path . -s tools/screenshots.gd --resolution 1280x720
#    ผลลัพธ์: tests/out/01_menu.png ... 18_crew.png

# 2b. ตรวจเสียง (ต้องมีหน้าต่างจริง/อุปกรณ์เสียง)
& $godot --path . -s tools/audio_check.gd
#    ต้องจบด้วย: AUDIO OK (7 sounds)

# 3. สมดุลด้วย Python (bare `python` อาจค้าง ใช้ path เต็ม)
& "C:\Program Files\Python313\python.exe" tools\balance_check.py
& "C:\Program Files\Python313\python.exe" tools\balance_check.py --emit-golden

# 4. import asset ใหม่ (รูป/เสียง/ฟอนต์) แบบ headless
& $godot --headless --path . --import

# 5. build (templates 4.7.2 ติดตั้งแล้วในเครื่องนี้)
& $godot --headless --path . --export-release "Web" "builds/web/index.html"
& $godot --headless --path . --export-release "Windows Desktop" "builds/windows/OGFrontier.exe"

# 6. แพ็กเกจแจกทีม (Project / Windows / Web / Legacy + SHA256)
powershell -NoProfile -ExecutionPolicy Bypass -File tools\package_team.ps1
#    ผลลัพธ์: dist/*.zip, dist/SHA256SUMS.txt, dist/START_HERE.txt
```

หมายเหตุสภาพเครื่องนี้:

- Console เป็น codepage cp932 → **อย่า print ข้อความไทยหรือ path ไทยลง console**
  (ไฟล์เป็น UTF-8 ถูกต้อง แค่การแสดงผลเพี้ยน)
- `Godot.exe --version` ค้างถ้าไม่ใส่ `--headless`
- Screenshot/เทสต์ตั้ง `GameState.skip_save = true` เพื่อไม่ทับเซฟผู้เล่น

## 3) แผนที่โค้ด

| ไฟล์ | บทบาท |
| --- | --- |
| `scripts/game_state.gd` | autoload `GameState`: โหลด JSON, analyze(), run/advance(), events, save/load, คะแนน |
| `scripts/sfx.gd` | autoload `Sfx`: pool 8 players, mute ตาม `GameState.sound_on`, no-op ใน headless |
| `scripts/screen.gd` | คลาสแม่ของทุกหน้า: วาดดาว, fade 0.25 s, Esc back, Enter |
| `scripts/pix.gd` | palette, `lbl/btn/panel`, `draw_ship`, `tex/photo/photo_frame` |
| `scripts/menu.gd` | เมนู + settings overlay + story/tutorial links |
| `scripts/story.gd` | briefing 3 สไลด์ (Earth crisis → ISS → loop) |
| `scripts/tutorial.gd` | tutorial เต็ม 6 สไลด์ |
| `scripts/station.gd` | ต้นไม้โมดูล + tutorial overlay + links ไปห้องลูกเรือ/terminal |
| `scripts/ship.gd` | crew cabin: greenhouse, science, suit locker, galley, bunk, terminal |
| `scripts/computer.gd` | ISS terminal v0.1 + mission dossiers + smelter status |
| `scripts/hangar.gd` | เลือก 7 ชิ้นส่วน + สไลเดอร์ propellant + stats + food/prep |
| `scripts/mission.gd` | แผนการบิน + DETAILS dossier + LAUNCH |
| `scripts/flight.gd` | step ภารกิจ, event dialog, HUD, crew activities, typewriter, flash/shake |
| `scripts/explore.gd` | EVA เก็บตัวอย่างตามเวลา + stamina/pace + scout time |
| `scripts/report.gd` | อธิบายผล + 6 ทรัพยากร + samples + station support + rerun |
| `scripts/farm.gd` | greenhouse crop math (NASA BVAD) |
| `scripts/stamina.gd` | EVA stamina model (Btu, pace, reserve) |
| `scripts/physics.gd` | orbital mechanics + solar flux |
| `OPEN_IN_GODOT.bat` | เปิดโปรเจกต์ให้ถูกโฟลเดอร์ (มี `project.godot`) |
| `OPEN_IN_GODOT_SAFE.bat` | เปิด editor ด้วย OpenGL 3.3 ถ้าไดรเวอร์มีปัญหา |
| `START_HERE.txt` | คำแนะนำสั้นสำหรับทีม |
| `docs/TEAM_GUIDE.md` | คู่มือแจกเกม + ตารางแก้ error |
| `tools/package_team.ps1` | สร้าง ZIP แจกทีม + checksum |
| `tools/launchers/` | `RUN_LAST_LAUNCH*.bat`, `PLAY_WEB.bat`, `serve_web.ps1` |
| `data/game_data.json` | ข้อมูลทั้งหมด |
| `data/farm.json`, `data/stamina.json`, `data/physics.json` | ตัวเลขระบบใหม่ |
| `tools/screenshots.gd` | harness ถ่ายภาพ (SceneTree script) |
| `tools/audio_check.gd` | ตรวจเสียงทั้ง 7 ไฟล์ว่ามี stream และเล่นได้ |
| `tests/smoke_test.gd` | gate 161 checks + parity กับ golden |

Flow: `menu → station → (hangar | mission) → flight ⇄ explore → report → (hangar | station)`

## 4) แบบแผนการเขียนโค้ด

- ใช้ **tabs** ตามไฟล์เดิม, ประกาศชนิดตัวแปรเมื่อเป็นไปได้ (`var x: int = 0`)
- สร้าง UI ผ่าน `Pix.lbl/btn/panel` เพื่อคุมสไตล์ให้เหมือนกัน
- **`Pix.lbl` ตั้ง `autowrap_mode` ก่อน `size` เสมอ** — ถ้าสลับกัน ข้อความจะดันความกว้างขั้นต่ำ
  และล้นจอ (บั๊กที่เคยเจอ)
- เปลี่ยนหน้าจอด้วย `Screen.go("scene")` (มี fade ให้) ไม่เรียก `change_scene_to_file` ตรงๆ
- หน้าที่มีปุ่มย้อนกลับให้ override `back_scene()` คืนชื่อฉาก (Esc ใช้ค่านี้)
- อย่าล็อกอินพุตด้วย `_input` ถ้าไม่จำเป็น ใช้ `_unhandled_input` เพื่อไม่กินอีเวนต์ของปุ่ม
- รูปภาพ: `Pix.photo_frame()` คืน `false` เมื่อไม่มีไฟล์ — ต้องมี fallback ที่ยังเล่นได้
- ห้ามเพิ่ม asset ที่มีลิขสิทธิ์ไม่ชัดเจน ถ้าเป็น NASA ให้บันทึกใน `assets/CREDITS.md`

## 5) เพิ่มคอนเทนต์แบบไม่แตะสูตร

1. **เหตุการณ์ใหม่**: เพิ่มใน `"events"` ของ JSON (`slot`, `text`, `choices[].fx`, `label`)
   แล้วรัน smoke test (จำนวน event ต่อ run ยังเป็น 3)
2. **ชิ้นส่วนใหม่**: เพิ่มใน `"options"` ของ part ที่มีอยู่ (ต้องมี `name, mass, power, cost, info`)
   ถ้าเพิ่มจำนวนตัวเลือก ต้องตรวจ layout `hangar.gd` (ปุ่มกว้าง 188 px, ระยะ 195 px)
3. **โมดูลสถานี**: เพิ่มใน `"station_modules"` พร้อม `x,y` ที่ไม่ทับของเดิม (ปุ่ม 198×48)
4. **ทรัพยากรบนดวงจันทร์**: แก้ `"moon_resources"` แล้วตรวจ `explore.gd` (`_spawn`) และ
   `report.gd` (`_samples_text`) ว่ายังรองรับคีย์ครบ
5. **ภารกิจใหม่**: เพิ่มใน `"missions"` + `legs` และตรวจ `mission_days()`, `analyze()`

## 6) Definition of done (ทุกงาน)

- [ ] เกมเปิดได้ และ `PASS smoke_test (161 checks)` (จำนวน check อาจเพิ่มได้)
- [ ] ถ้าแตะ UI: ถ่าย screenshot หน้าที่เกี่ยวข้องแล้วเปิดดูจริง ไม่มีข้อความล้น/ทับ
- [ ] ถ้าแตะเสียง: `AUDIO OK (7 sounds)` จาก `tools/audio_check.gd`
- [ ] ถ้าแตะสูตร/คะแนน: `balance_check.py` ตรงกับ GDScript และ commit `tests/golden.json`
- [ ] ถ้าแตะ save: เซฟเก่ายังโหลดได้ (มีเทสต์ใน smoke test)
- [ ] ถ้าแตะ build/packaging: รัน `tools/package_team.ps1` แล้วแตก ZIP ตรวจว่า
      `project.godot` อยู่บนสุด, exe เปิดได้, และ Web มี `PLAY_WEB.bat` + `index.wasm`
- [ ] อัปเดต `CHANGELOG.md` และ `OVERNIGHT_LOG.md` (ถ้าเป็นงานคืนนี้)
- [ ] commit message รูปแบบ `feat|fix|docs|test|chore(scope): ...`

## 7) จุดที่พลาดง่าย

- ลืม `--headless` ตอนรัน script → หน้าต่างเกมค้าง/ไม่จบ
- ลืม `--import` หลังเพิ่มรูป → `load()` คืน null และ fallback ทำงานเงียบๆ
- ใช้ `queue_free()` แล้วอ้าง node ในเฟรมเดียวกัน → "previously freed instance"
- แก้ `size` ของ Control ที่ anchor เต็มจอ → warning "was not set to full rect"
- เปิดไฟล์ `.html` ของ Web export ด้วย `file://` → จอดำ (ต้องใช้ HTTP server)
- เปิดโฟลเดอร์แม่ที่มีแค่ `data/docs/scripts` ใน Godot → FileSystem ว่าง /
  "Can't open file 'menu.tscn'" (ต้องเปิดโฟลเดอร์ที่มี `project.godot`)
- **Renderer**: เครื่องที่ใช้ทดสอบนี้ **ไม่มี OpenGL 3.3 และ ANGLE/D3D11 ก็ใช้ไม่ได้**
  (Vulkan ใช้ได้) จึงห้ามตั้ง `rendering_method="gl_compatibility"` ใน `project.godot`
  เพราะ editor จะเปิดไม่ได้ — ให้เลือก renderer ที่ launcher แทน
  (`RUN_LAST_LAUNCH.bat`: Vulkan → OpenGL 3.3 → แนะนำเวอร์ชันเว็บ)
- **`project.godot` เป็น ConfigFile**: comment ใช้ `;` เท่านั้น ถ้าใส่ `#`
  ตัวแปรในบรรทัดถัด ๆ ไปจะถูกอ่านข้าม (เคยทำให้ setting renderer หายไปเงียบ ๆ)
- **อย่าใช้ `tar.exe` กับ path ที่มีอักษรไทย** (`package_team.ps1` จึงใช้
  `git archive --format=zip` แล้วแตกด้วย .NET)
- รัน Python ด้วย `python` เฉยๆ ในเครื่องนี้ → ค้าง (ใช้ path เต็ม)

## 8) คำถามที่ยังเปิดอยู่

ดูหัวข้อ "Open questions" ใน `OVERNIGHT_LOG.md` ก่อนตัดสินใจเรื่อง
การเปิดเผยการใช้ AI, ขนาดลูกเรือ, ภาษาไทย/ฟอนต์, ขอบเขตเดโม และไฟล์ที่ต้องส่ง
