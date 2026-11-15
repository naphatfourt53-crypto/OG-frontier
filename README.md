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

## 2) เปิดเกม

1. เปิด Godot 4.7.2 → **Import** → เลือก `project.godot` → **Import & Edit**
2. รอ import ครั้งแรกสักครู่ (จะสร้างโฟลเดอร์ `.godot/` ซึ่งไม่ถูก commit)
3. กด **F5** หรือปุ่ม ▶ มุมขวาบน เกมเริ่มที่ `scenes/menu.tscn`

> ถ้าเปิดด้วย Godot 4.3–4.6 จะมี warning เรื่อง `config/features="4.7"`
> แนะนำให้ใช้ 4.7.2 ตามที่ทีม pin ไว้

## 3) วิธีเล่น (5 นาทีแรก)

1. **เมนู → START** เข้าสถานีอวกาศ โมดูลสีม่วง `+` คือส่วนที่ต่อเพิ่มได้ด้วย Data
2. **Hangar** → กด **Load sample design** (ยานที่บินผ่านได้) หรือเลือกเองทั้ง 7 ชิ้น
   พร้อมเลื่อนแถบ Propellant — ตัวเลขสีเขียว = ผ่าน, สีแดง = ไม่ผ่าน
   ปุ่มที่มี `*` คือตัวเลือกที่แนะนำใน sample design
3. **Mission Control >** อ่านแผนการบิน (มี note แบบกระบวนงานจริงของ Apollo) → **LAUNCH**
4. **Flight** กด **CONTINUE** ไปเรื่อยๆ เจอเหตุการณ์ให้เลือก 1 ใน 2
   ทุกทางมีผลดี–ผลเสีย และข้อความใน log คือร่องรอยว่าอะไรทำให้ภารกิจพัง
5. **Moon Walk** (ค่าเริ่มต้น 60 วินาที, ปรับได้ 30–300 วินาทีใน Settings)
   WASD/ลูกศรเดิน, Space กลับยานก่อนเวลา เก็บตัวอย่าง 4 ชนิด:

   | ตัวอย่าง | แต้ม/ชิ้น | จำนวนสูงสุด | อยู่ที่ไหน |
   | --- | --- | --- | --- |
   | Regolith | 5 | 10 | ทั่วพื้น |
   | Ilmenite | 10 | 3 | ใกล้หิน outcrop |
   | Ice | 15 | 4 | ในหลุมมืด (เดินช้าลง) |
   | Helium-3 | 25 | 1 | ใจกลางหลุมมืด |

   คะแนนเต็มของ EVA = 165 แต้ม (เก็บครบทุกชิ้น)
6. **Report** บอกเหตุผลที่ผ่าน/ไม่ผ่าน + ตาราง 6 ทรัพยากร (Mass, Power, Budget,
   Data, Comms, Time) + สรุปตัวอย่างที่เก็บได้
   กด **Modify ship & rerun (same seed)** เพื่อแก้ยานแล้วลองใหม่ด้วยเหตุการณ์ชุดเดิม
7. ผ่านภารกิจแรกแล้ว **ปลดล็อกดาวอังคาร** = จบ DEMO
   เอา Data ไปต่อโมดูล: Greenhouse, Science Lab, Cargo Bay, Heavy Dock, Relay Array, Solar Wing

### ปุ่มลัด

| ปุ่ม | ใช้ทำอะไร |
| --- | --- |
| เมาส์ | เมนู, เลือกชิ้นส่วน, ตอบเหตุการณ์ |
| WASD / ลูกศร | เดินบนดวงจันทร์ |
| Space | กลับยานก่อนหมดเวลา EVA |
| Enter | ไปต่อในหน้า Flight |
| Esc | ย้อนกลับ (สถานี, Hangar, Mission, Report) |
| `?` (มุมขวาบนของสถานี) | เปิด tutorial ซ้ำ |
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
PASS smoke_test (121 checks)
```

เทสต์นี้ตรวจ: เปิดได้ทุกฉาก, สูตรจรวด/เสบียง/ไฟฟ้า, Game Over 5 แบบ,
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

ไฟล์จะออกที่ `tests/out/01_menu.png` … `11_tutorial.png` (โฟลเดอร์นี้ไม่ถูก commit)
ใช้ตรวจ layout หลังแก้ UI ทุกครั้ง — โดยเฉพาะข้อความยาวๆ ที่อาจล้นกรอบ

### 5.4 ตรวจเสียง

ต้องรันแบบมีอุปกรณ์เสียง (อย่าใส่ `--headless`):

```powershell
& "C:\path\to\Godot_v4.7.2-stable_win64_console.exe" --path . -s tools/audio_check.gd
```

ผลที่ต้องเห็น: `AUDIO OK (7 sounds)` พร้อมความยาวของแต่ละไฟล์
(ใช้เช็กว่า audio bus ทำงานและไฟล์ `.wav` import ครบ)

## 6) Export (เว็บ / Windows)

มี `export_presets.cfg` เตรียมไว้แล้ว 2 preset: **Web** และ **Windows Desktop**
ปลายทางอยู่ที่ `builds/web/` และ `builds/windows/` (ถูก ignore)
เครื่องที่ทำ repo นี้ติดตั้ง export templates 4.7.2 แล้ว และ **build ผ่านทั้งสอง preset**

1. ถ้าเครื่องใหม่ยังไม่มี template: Godot → **Editor → Manage Export Templates → Download and Install**
2. **Project → Export…** → เลือก preset → **Export Project**
   (หรือใช้ command line ตามหัวข้อ 8 ใน `OVERNIGHT_LOG.md`)
3. Web: ต้องเสิร์ฟผ่าน HTTP(S) เท่านั้น เปิดไฟล์ `.html` ด้วยการดับเบิลคลิกจะไม่ทำงาน
   (`file://` ถูกบล็อก) — อัปโหลดขึ้น itch.io ช่อง "HTML5" หรือรันเซิร์ฟเวอร์ในโฟลเดอร์นั้น
4. Web preset ตั้ง `thread_support=false` ไว้ เพื่อให้อัปโหลดง่ายและไม่ต้องตั้ง
   COOP/COEP header (เกมนี้ไม่ต้องใช้ SharedArrayBuffer)
5. `builds/` ไม่ถูก commit — ถ้าจะส่งไฟล์ ให้ zip โฟลเดอร์ `builds/web` ทั้งโฟลเดอร์
   (ไม่ใช่แค่ `index.html`) หรือส่ง `builds/windows` ทั้งคู่ `.exe` + `.pck`

## 7) โครงสร้างโปรเจกต์

```text
ogfrontier/
├── project.godot            # ตั้งค่าโปรเจกต์ (features = 4.7)
├── export_presets.cfg       # Web + Windows Desktop
├── data/game_data.json      # ตัวเลขเกมทั้งหมด
├── scenes/*.tscn            # 7 หน้าจอ (Control + script)
├── scripts/
│   ├── game_state.gd        # autoload: สูตร, คะแนน, save/load, สถานะ run
│   ├── sfx.gd               # autoload: pool 8 players + mute
│   ├── screen.gd            # คลาสแม่: fade, Esc/Enter, พื้นหลังดาว
│   ├── pix.gd               # palette, ปุ่ม/ข้อความ, วาดยาน, โหลดรูป NASA
│   ├── menu.gd station.gd hangar.gd mission.gd flight.gd explore.gd report.gd
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

การเชื่อมหน้าจอ: `menu → station → (hangar | mission) → flight ⇄ explore → report → (hangar | station)`
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
- `save_version` ปัจจุบัน = **3** เพิ่ม `eva`, `tutorial` และ `sound`
- เซฟเวอร์ชัน 1–2 ยังโหลดได้ เพราะคีย์ใหม่มีค่า default เท่ากับพฤติกรรมเดิม
- ปุ่ม **RESET SAVE** ที่เมนูลบเซฟทั้งหมด
- เครื่องมือเทสต์/สกรีนช็อตตั้ง `GameState.skip_save = true` ไม่ทับเซฟผู้เล่น

## 10) Git — ทำงานเป็นทีม

Repo นี้มี branch `main` (snapshot แรก) และ `overnight/opencode` (งานคืนนี้)

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
