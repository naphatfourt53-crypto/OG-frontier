# Last Launch / OG-Frontier — Prototype (Godot 4.7.2)

เกมสำหรับ NASA Space Apps 2026 หัวข้อ **Space Mission Design Game**
เล่นครบวงจรในรอบเดียว: สถานีอวกาศ → ประกอบยาน 7 ชิ้น → เลือกภารกิจ →
บินผ่านเหตุการณ์สุ่ม → เดินสำรวจดวงจันทร์ → รายงานผลที่บอกว่า "ทำไมสำเร็จ/ล้มเหลว"

สถานะปัจจุบัน: **รันได้จริงและผ่านการตรวจแล้ว** (headless test + screenshot ทุกหน้าจอ)
รายละเอียดงานค้าง/คำถามที่ยังไม่ได้ข้อสรุปอยู่ใน [`OVERNIGHT_LOG.md`](OVERNIGHT_LOG.md)

---

## 1) สิ่งที่ต้องมี

| สิ่งที่ต้องมี | เวอร์ชัน |
| --- | --- |
| Godot Engine (รุ่น Standard ไม่ใช่ .NET) | **4.7.2** |
| Python (เฉพาะตอนรัน balance check) | 3.10+ |
| ระบบปฏิบัติการ | Windows / macOS / Linux |

โปรเจกต์ไม่มี addon, ไม่มีปลั๊กอิน, ไม่มี C#, ไม่มีไลบรารีภายนอก
รูปถ่าย NASA 4 รูปถูก import ไว้แล้ว (ดู [`assets/CREDITS.md`](assets/CREDITS.md))

## 2) เปิดเกม (3 วิธี)

> **อ่านก่อน:** โฟลเดอร์ที่ถูกต้องคือโฟลเดอร์ที่มี `project.godot` อยู่ข้างใน
> ถ้าเปิดแล้ว FileSystem ว่างและขึ้น `Can't open file 'menu.tscn'`
> แปลว่าเปิดโฟลเดอร์แม่ (ที่มีแค่ `data/docs/scripts/tools`) ไม่ใช่ตัวโปรเจกต์

### 2.1 เล่นอย่างเดียว — Windows

- แตก `LastLaunch_v0.4.1_Windows.zip` ให้ครบ แล้วดับเบิลคลิก `RUN_LAST_LAUNCH.bat`
- ถ้า SmartScreen เตือน: **More info → Run anyway**
- ถ้าขึ้น `Unable to initialize video driver` หรือจอดำ: ลอง `RUN_LAST_LAUNCH_SAFE.bat`
- ถ้ายังไม่ได้: ใช้เวอร์ชันเว็บ (2.2) ซึ่งไม่ต้องใช้ไดรเวอร์การ์ดจอ

### 2.2 เล่นบนเครื่องเก่า / การ์ดจอไม่รองรับ — Web

- แตก `LastLaunch_v0.4.1_Web.zip` แล้วดับเบิลคลิก `PLAY_WEB.bat`
- **อย่าดับเบิลคลิก `index.html`** เพราะเบราว์เซอร์โหลด `.pck/.wasm` จาก `file://` ไม่ได้
- ใช้ Chrome หรือ Edge รุ่นใหม่ — เบราว์เซอร์มี software WebGL จึงเปิดได้แม้ไดรเวอร์เก่า

### 2.3 แก้โค้ด — Godot 4.7.2

1. แตก ZIP แล้วเข้าโฟลเดอร์ที่มี `project.godot` (หรือดับเบิลคลิก `OPEN_IN_GODOT.bat`)
2. รอ import ครั้งแรกสักครู่ (จะสร้าง `.godot/` ซึ่งไม่ถูก commit)
3. กด **F5** หรือปุ่ม ▶ เกมเริ่มที่ `scenes/menu.tscn`

> ถ้า editor เปิดไม่ขึ้นเพราะไดรเวอร์ ให้ใช้ `OPEN_IN_GODOT_SAFE.bat`
> ถ้าเปิดด้วย Godot 4.3–4.6 จะมี warning เรื่อง `config/features="4.7"`
> แนะนำให้ใช้ 4.7.2 ตามที่ทีม pin ไว้

คู่มือแจกเกม/แก้ error ทั้งหมด: [`docs/TEAM_GUIDE.md`](docs/TEAM_GUIDE.md)

## 3) วิธีเล่น (5 นาทีแรก)

1. **เมนู → START** ครั้งแรกจะเห็น story briefing 3 สไลด์ (Earth กำลังร้อนจนอยู่ไม่ได้,
   ISS คือ lobby, และ loop ของเกม) แล้วจึงเข้าสถานี
   ครั้งต่อไป START จะข้าม briefing ไปที่ ISS ทันที; ปุ่ม **STORY** เปิดดูซ้ำได้
2. **ISS LAST LAUNCH** คือ lobby: คลิกโมดูลสีเพื่อเข้าห้อง, โมดูลสีม่วง `+` ใช้ Data ต่อเพิ่ม
   ปุ่ม **CREW CABIN** เข้าห้องลูกเรือ, **TERMINAL** เปิดคอมพิวเตอร์ v0.1,
   **HOW TO PLAY** เปิด tutorial 6 สไลด์ และ `?` เปิด overlay สั้น 3 ขั้น
3. **CREW CABIN** ห้องลูกเรือ: ปลูกผักใน Greenhouse, ศึกษา samples, พักผ่อน,
   และโหลด **Radiation blanket** / **Scout drone** สำหรับเที่ยวบินถัดไป
   อาหารที่ปลูกได้จะไปลดอาหารที่ต้องบรรทุก; scout เพิ่มเวลา EVA 25%
4. **Hangar** → กด **Load sample design** (ยานที่บินผ่านได้) หรือเลือกเองทั้ง 7 ชิ้น
   พร้อมเลื่อนแถบ Propellant — ตัวเลขสีเขียว = ผ่าน, สีแดง = ไม่ผ่าน
   ปุ่มที่มี `*` คือตัวเลือกที่แนะนำใน sample design
5. **Mission Control >** อ่านแผนการบิน (มี note แบบกระบวนงานจริงของ Apollo)
   กด **DETAILS** เพื่ออ่าน dossier เต็ม: environment, hazards, resources, gear,
   scout note และ station support (อาหาร, gear, EVA window) → **LAUNCH**
6. **Flight** กด **CONTINUE** ไปเรื่อยๆ เจอเหตุการณ์ให้เลือก 1 ใน 2
   ปุ่ม **CREW** เปิดกิจกรรมในเที่ยวบิน: ปลูกผัก (+2 kg food), ศึกษาตัวอย่าง (+5 science)
   หรือเตรียม EVA (+8% hull) — ทุกอย่างใช้เวลาหนึ่งวันและกินเสบียงจริง
7. **Moon Walk** (ค่าเริ่มต้น 60 วินาที, scout เพิ่มเป็น 75, ปรับได้ 30–300 วินาทีใน Settings)
   WASD/ลูกศรเดิน, `1`/`2`/`3` เลือก easy/normal/hard, `Shift` burst, Space กลับยานก่อนเวลา
   ชุดมี stamina bar; ถ้าพลังหมด EVA จบทันที เก็บตัวอย่าง 4 ชนิด:

   | ตัวอย่าง | แต้ม/ชิ้น | จำนวนสูงสุด | อยู่ที่ไหน |
   | --- | --- | --- | --- |
   | Regolith | 5 | 10 | ทั่วพื้น |
   | Ilmenite | 10 | 3 | ใกล้หิน outcrop |
   | Ice | 15 | 4 | ในหลุมมืด (เดินช้าลง) |
   | Helium-3 | 25 | 1 | ใจกลางหลุมมืด |

   คะแนนเต็มของ EVA = 165 แต้ม (เก็บครบทุกชิ้น)
8. **Report** บอกเหตุผลที่ผ่าน/ไม่ผ่าน + ตาราง 6 ทรัพยากร (Mass, Power, Budget,
   Data, Comms, Time) + สรุปตัวอย่างที่เก็บได้ + station support (food ที่ใช้,
   scout/rad kit, พลังงานชุดที่ใช้, Helios ore)
   กด **Modify ship & rerun (same seed)** เพื่อแก้ยานแล้วลองใหม่ด้วยเหตุการณ์ชุดเดิม
9. ผ่านภารกิจแรกแล้ว **ปลดล็อกดาวอังคาร** = จบ DEMO
   เอา Data ไปต่อโมดูล: Greenhouse, Science Lab, Exercise Bay, Cargo Bay, Heavy Dock,
   Relay Array, Solar Wing

### ปุ่มลัด

| ปุ่ม | ใช้ทำอะไร |
| --- | --- |
| เมาส์ | เมนู, เลือกชิ้นส่วน, ตอบเหตุการณ์ |
| WASD / ลูกศร | เดินบนดวงจันทร์ |
| 1 / 2 / 3 | เลือก pace easy / normal / hard |
| Shift | burst (เร็วที่สุด แต่ stamina หมดเร็ว) |
| Space | กลับยานก่อนหมดเวลา EVA |
| Enter | ไปต่อในหน้า Flight / tutorial |
| Esc | ย้อนกลับ (สถานี, Hangar, Mission, Report) |
| `?` (มุมขวาบนของสถานี) | เปิด tutorial overlay สั้น |
| HOW TO PLAY (เมนู/สถานี) | เปิด tutorial เต็ม 6 สไลด์ |
| SETTINGS (เมนู) | ปรับเวลา EVA, เปิด/ปิดเสียง, replay tutorial |

## 4) ตัวเลขทั้งหมดอยู่ที่เดียว

ตัวเลขสมดุลเกมทั้งหมดอยู่ใน [`data/game_data.json`](data/game_data.json):
ชิ้นส่วนยาน, ภารกิจ, เหตุการณ์, โมดูลสถานี, ทรัพยากรบนดวงจันทร์
แก้แล้วกด F5 ใหม่ ไม่ต้องแตะโค้ด

- เพิ่มตัวเลือกชิ้นส่วน: คัดลอกบล็อกใน `"options"` (ต้องมี `name, mass, power, cost, info`)
- เพิ่มเหตุการณ์: คัดลอกบล็อกใน `"events"`, ตั้ง `slot` เป็น `space` หรือ `surface`
  และใช้ `fx` ที่รองรับ: `days, supply_pct, water_kg, prop_pct, hull, rad_hull, power_mult, data_mult, data`
- เพิ่มโมดูลสถานี: คัดลอกบล็อกใน `"station_modules"` กำหนด `parent`, `x`, `y`, `cost`, `bonus`
- เพิ่มทรัพยากรบนดวงจันทร์: แก้ `"moon_resources"` (`pts`, `count`, `slow`)
  แล้วแก้ `scripts/explore.gd` เฉพาะกรณีที่อยากให้เกิดในตำแหน่งใหม่

**กฎของทีม:** ถ้าแก้สูตร/คะแนน ต้องแก้ `tools/balance_check.py` ให้ตรงกันด้วย
แล้วรัน `--emit-golden` เพื่ออัปเดต `tests/golden.json` (ดูหัวข้อถัดไป)

## 5) ตรวจสอบก่อน commit (สำคัญ)

### 5.1 Headless smoke test

```powershell
# Windows (แก้ path ให้ชี้ไฟล์ Godot ของเครื่องคุณ)
& "C:\path\to\Godot_v4.7.2-stable_win64_console.exe" --headless --path . -s tests/smoke_test.gd
```

```bash
# macOS / Linux
godot --headless --path . -s tests/smoke_test.gd
```

ผลที่ต้องเห็น:

```text
  sample run: success=false score=86 data=43
  smart run: success=true score=1117 data=48
  weak run: reason=Stranded
  parity checked 5 design(s)
PASS smoke_test (191 checks)
```

เทสต์นี้ตรวจ: เปิดได้ทุกฉาก (รวม story, tutorial, crew cabin, terminal),
สูตรจรวด/เสบียง/ไฟฟ้า, Game Over 5 แบบ, greenhouse/prep/stamina/crew activity,
คะแนน, save/load (รวม save เวอร์ชันเก่า), และตัวเลข GDScript ตรงกับ Python ภายใน 1%
และ **ไม่แตะเซฟของผู้เล่น** (`GameState.skip_save = true`)

### 5.2 Python balance check
```powershell
"C:\Program Files\Python313\python.exe" tools\balance_check.py
```

```bash
python3 tools/balance_check.py
```

ใช้เทียบสมดุลโดยไม่ต้องเปิด Godot (พิมพ์ต้นทุน EVA pool, อัตราชนะของยานตัวอย่าง,
และสำรวจ design space 2,187 แบบ)

ถ้าแก้สูตรใน `game_state.gd` ให้รัน `--emit-golden` แล้ว commit `tests/golden.json`:

```bash
python3 tools/balance_check.py --emit-golden
```

### 5.3 Screenshot ทุกหน้าจอ

ต้องรันแบบมีหน้าต่างจริง (headless ไม่มี framebuffer):

```powershell
& "C:\path\to\Godot_v4.7.2-stable_win64_console.exe" --path . -s tools/screenshots.gd --resolution 1280x720
```

ไฟล์จะออกที่ `tests/out/01_menu.png` … `18_crew.png` (โฟลเดอร์นี้ไม่ถูก commit)
รวม story briefing, tutorial เต็ม, crew cabin, terminal, mission dossier และ crew activity
ใช้ตรวจ layout หลังแก้ UI ทุกครั้ง — โดยเฉพาะข้อความยาวๆ ที่อาจล้นกรอบ

### 5.4 ตรวจเสียง

ต้องรันแบบมีอุปกรณ์เสียง (อย่าใส่ `--headless`):

```powershell
& "C:\path\to\Godot_v4.7.2-stable_win64_console.exe" --path . -s tools/audio_check.gd
```

ผลที่ต้องเห็น: `AUDIO OK (7 sounds)` พร้อมความยาวของแต่ละไฟล์
(ใช้เช็กว่า audio bus ทำงานและไฟล์ `.wav` import ครบ)

## 6) Export (เว็บ / Windows)

มี `export_presets.cfg` เตรียมไว้ 2 preset: **Web** และ **Windows Desktop**

- Windows **ฝัง `.pck` ไว้ใน exe แล้ว** (`binary_format/embed_pck=true`) — ส่งไฟล์เดียวจบ
- `RUN_LAST_LAUNCH.bat` **ลองเปิดซ้ำด้วย OpenGL 3.3 ให้อัตโนมัติ** ถ้ารอบแรก
  (Vulkan / Forward+) ขึ้น "Unable to initialize video driver"
- ไม่ตั้ง `gl_compatibility` เป็นค่าเริ่มต้นใน `project.godot` เพราะเครื่องที่ไม่มี
  ไดรเวอร์ OpenGL 3.3 จะเปิด editor ไม่ได้เลย (เครื่องที่ทดสอบอยู่ก็เป็นแบบนั้น)
  การเลือก renderer จึงเป็นหน้าที่ของ launcher/flag ไม่ใช่ค่าถาวรของโปรเจกต์
- Web ตั้ง `thread_support=false` จึงไม่ต้องตั้ง COOP/COEP header
  (เกมนี้ไม่ใช้ SharedArrayBuffer)

### 6.1 สร้างแพ็กเกจแจกทีม (แนะนำ)

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\package_team.ps1
```

ได้ไฟล์ใน `dist/` พร้อม checksum:

```text
LastLaunch_v0.4.1_Project.zip    # เปิดใน Godot (project.godot อยู่บนสุด)
LastLaunch_v0.4.1_Windows.zip    # RUN_LAST_LAUNCH.bat
LastLaunch_v0.4.1_Web.zip        # PLAY_WEB.bat (เครื่องเก่า)
LastLaunch_Legacy_v0.1.0_Project.zip
SHA256SUMS.txt / START_HERE.txt / README_UPLOAD.md
```

### 6.2 Export เอง

1. ถ้าเครื่องใหม่ยังไม่มี template: Godot → **Editor → Manage Export Templates → Download and Install**
2. **Project → Export…** → เลือก preset → **Export Project**
3. Command line:

   ```powershell
   & $godot --headless --path . --export-release "Web" "builds/web/index.html"
   & $godot --headless --path . --export-release "Windows Desktop" "builds/windows/OGFrontier.exe"
   ```

4. Web ต้องเสิร์ฟผ่าน HTTP(S) — ใช้ `PLAY_WEB.bat` (มี server ในตัว) หรือ `python -m http.server`
   **อย่าดับเบิลคลิก `index.html`** เพราะ `file://` ถูกบล็อก
5. อย่า commit `builds/` หรือ `.exe` (exe ใหญ่เกิน 100 MB ของ GitHub)
   ให้อัปโหลด ZIP เป็น **GitHub Release** (tag `v0.4.1`) แล้วส่งลิงก์ให้ทีม

## 7) โครงสร้างโปรเจกต์

```text
ogfrontier/
├── project.godot            # ตั้งค่าโปรเจกต์ (features = 4.7)
├── export_presets.cfg       # Web + Windows Desktop (embed pck)
├── OPEN_IN_GODOT.bat        # เปิดโปรเจกต์ให้ถูกโฟลเดอร์
├── OPEN_IN_GODOT_SAFE.bat   # เปิดด้วย OpenGL 3.3 ถ้าไดรเวอร์มีปัญหา
├── START_HERE.txt           # อ่านก่อนเปิดเกม
├── docs/TEAM_GUIDE.md       # คู่มือแจกเกม + แก้ error
├── tools/package_team.ps1   # สร้าง ZIP แจกทีม (Project/Windows/Web/Legacy)
├── tools/launchers/         # bat/ps1 ที่ใส่ในแพ็กเกจ
├── data/game_data.json      # ตัวเลขเกมทั้งหมด
├── data/farm.json           # ตัวเลข greenhouse (NASA BVAD)
├── data/stamina.json        # EVA stamina / pace
├── data/physics.json        # orbital mechanics + solar flux
├── scenes/*.tscn            # 11 หน้าจอ (Control + script)
├── scripts/
│   ├── game_state.gd        # autoload: สูตร, คะแนน, save/load, สถานะ run
│   ├── sfx.gd               # autoload: pool 8 players + mute
│   ├── screen.gd            # คลาสแม่: fade, Esc/Enter, พื้นหลังดาว
│   ├── pix.gd               # palette, ปุ่ม/ข้อความ, วาดยาน, โหลดรูป NASA
│   ├── menu.gd story.gd tutorial.gd station.gd ship.gd computer.gd
│   ├── hangar.gd mission.gd flight.gd explore.gd report.gd
│   ├── farm.gd stamina.gd physics.gd
├── assets/
│   ├── CREDITS.md           # ที่มาและลิขสิทธิ์รูป/เสียง
│   ├── nasa/*.jpg           # รูป NASA ขนาดกลาง 4 รูป
│   └── sfx/*.wav            # เสียง CC0 7 ไฟล์
├── docs/OG-Frontier_Game_Data_Book.pdf
├── tests/smoke_test.gd      # headless gate
├── tests/golden.json        # ตัวเลขอ้างอิงจาก Python
└── tools/
    ├── balance_check.py     # จำลองเกมด้วย Python
    ├── screenshots.gd       # ถ่ายภาพทุกหน้าจอ
    └── audio_check.gd       # ตรวจว่าเสียงทั้ง 7 ไฟล์เล่นได้
```

การเชื่อมหน้าจอ: `menu → story → station → (ship | computer | hangar | mission) → flight ⇄ explore → report`
ทุกหน้าเปลี่ยนฉากด้วย `go("ชื่อฉาก")`

## 8) ฟิสิกส์จริงที่ใช้ (จาก Game Data Book)

- สมการจรวด: `m_prop = m_f · (e^(Δv/(Isp·g0)) − 1)`, `g0 = 9.80665`
- Δv แต่ละช่วง: LEO→TLI 3.2 / TLI→วงโคจรดวงจันทร์ 0.9 / ลงจอด 1.87 / ขึ้น+กลับ LEO 2.74 km/s
  (บวก margin 10% รวม 6.06 km/s)
- ลูกเรือ 1 คน/วัน: O₂ 0.89 kg, น้ำดื่ม 2.79 kg, อาหาร 2.39 kg
- Isp: hypergolic ≈310 s, methalox ≈360 s, hydrolox ≈450 s
- น้ำแข็งที่ขั้วใต้ดวงจันทร์ (LCROSS ≈ 5.6 ± 2.9% โดยมวล)
- ค่าที่ปรับเพื่อความสนุก (ไม่ใช่ฮาร์ดแวร์จริง) ระบุด้วยคำว่า GAME ใน `game_data.json`
- ตัวง่ายที่ตั้งใจ: ใช้ยานเดียวไม่ทิ้งถัง และบูสเตอร์ของสถานีช่วย LEO→TLI
  (เขียนบอกผู้เล่นไว้ในหน้า Mission Control แล้ว)

## 9) Save game

- ตำแหน่ง: `user://ogfrontier_save.json`
  (Windows: `%APPDATA%\Godot\app_userdata\OG-Frontier Prototype\`)
- `save_version` ปัจจุบัน = **4** เพิ่ม `story`, `day`, `food`, `prep`, `plots`, `ore`
- เซฟเวอร์ชัน 1–3 ยังโหลดได้ เพราะคีย์ใหม่มีค่า default เท่ากับพฤติกรรมเดิม
- ปุ่ม **RESET SAVE** ที่เมนูลบเซฟทั้งหมด
- เครื่องมือเทสต์/สกรีนช็อตตั้ง `GameState.skip_save = true` ไม่ทับเซฟผู้เล่น

## 10) Git — ทำงานเป็นทีม

Repo นี้ทำงานบน branch `main` (งานล่าสุด) และ push ขึ้น
`https://github.com/naphatfourt53-crypto/OG-frontier.git` แบบปกติ (ไม่ force push)

```bash
# ก่อนเริ่มงาน
git pull
git checkout -b feature/ชื่องาน

# ทำเสร็จ
git add .
git commit -m "อธิบายสั้นๆ ว่าทำอะไร"
git push -u origin feature/ชื่องาน   # แล้วเปิด Pull Request
```

กฎ: ห้าม force push, ห้าม commit ลง `main` ตรงๆ, แยกคนละไฟล์/คนละหน้าจอ,
และ **เกมต้องเปิดได้ก่อน commit ทุกครั้ง** (รัน smoke test ก่อน)

## 11) ถ้าเจอ Error

| อาการ | วิธีแก้ |
| --- | --- |
| `Could not find type "Screen"` / `"Pix"` | ปิด–เปิด Godot ใหม่ หรือ Project → Reload Current Project |
| หน้าจอดำ / ปุ่มไม่ขึ้น | ตรวจว่าเปิด `project.godot` ในโฟลเดอร์นี้ และใช้ Godot 4.7.2 |
| ข้อความล้นกรอบ | ตรวจว่า Label ตั้ง `autowrap_mode` ก่อนกำหนด `size` (ดู `Pix.lbl`) |
| Export ไม่ได้ | ยังไม่ได้ติดตั้ง export templates (ดูหัวข้อ 6) |
| ไม่มีเสียง | กด SETTINGS → Sound: ON; ตรวจว่าไฟล์ใน `assets/sfx/` ถูก import (รัน `tools/audio_check.gd`) |
| อยากเริ่มเซฟใหม่ | กด RESET SAVE ที่เมนู |

## 12) เครดิต

- รูปถ่าย: NASA (public domain / NASA media usage guidelines) —
  Earthrise (Apollo 8), Lunar Module (Apollo 11), EVA (Apollo 11), Mission Control (Apollo 9)
  ดูรายละเอียดที่ [`assets/CREDITS.md`](assets/CREDITS.md)
- เสียง: The Essential Retro Video Game Sound Effects Collection โดย Juhani Junkala
  (OpenGameArt, **CC0**) — 7 ไฟล์ใน `assets/sfx/`
- กราฟิกที่เหลือวาดด้วยโค้ดใน `scripts/pix.gd` ทั้งหมด
- ฟอนต์: ฟอนต์ default ของ Godot (ยังไม่มีฟอนต์ไทย — เป็นคำถามเปิดใน `OVERNIGHT_LOG.md`)
