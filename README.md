# Last Launch / OG-Frontier — Prototype (Godot 4)

เกมตัวอย่างสำหรับ NASA Space Apps 2026 หัวข้อ **Space Mission Design Game**
เปิดแล้วกด **F5** เล่นได้ครบวงจร:
สถานีแม่แบบกิ่งก้าน → ประกอบยาน 7 ชิ้น → เลือกภารกิจ → บิน (มีเหตุการณ์สุ่มให้ตัดสินใจ) → เดินสำรวจดวงจันทร์ 60 วินาที → รายงานผลที่อธิบายว่า "ทำไมสำเร็จ/ล้มเหลว"

> **ข้อควรรู้ (ตรงไปตรงมา):** ผมเขียนโค้ดนี้ในเครื่องที่ไม่มี Godot จึง **ยังไม่ได้รันเกมจริง** ตรวจได้แค่ไวยากรณ์เบื้องต้น และตรวจสมดุลตัวเลขด้วย Python (`tools/balance_check.py`) ครั้งแรกที่เปิดอาจมี error เล็กน้อย — ดูหัวข้อ "ถ้าเจอ Error" แล้วส่งข้อความ error มาให้ผม ผมแก้ให้ได้ทันที

---

## 1) ติดตั้งและเปิดเกม (ทำตามทีละข้อ)

1. ดาวน์โหลด **Godot 4.3 ขึ้นไป** (รุ่น *Standard* ไม่ใช่ .NET) จาก https://godotengine.org/download
   - ไม่ต้องติดตั้ง แตก zip แล้วดับเบิลคลิกไฟล์ Godot ได้เลย
2. แตกไฟล์ `ogfrontier.zip` ไว้ในโฟลเดอร์ที่ชื่อไม่มีภาษาไทย (เช่น `C:\dev\ogfrontier`)
3. เปิด Godot → กด **Import** → เลือกไฟล์ `project.godot` → **Import & Edit**
4. รอ Godot สแกนไฟล์ครั้งแรก (ไม่กี่วินาที) แล้วกด **F5** (หรือปุ่มสามเหลี่ยม ▶ มุมขวาบน)
5. ถ้าถามเลือก main scene ให้เลือก `scenes/menu.tscn` (ตั้งไว้ให้แล้วในโปรเจกต์)

## 2) วิธีเล่น (ลอง 5 นาทีแรก)

1. เมนู → **START** → เห็นสถานีแม่เป็นกิ่งก้าน (Core ตรงกลาง, Habitat/Hangar/Mission Ctrl แตกออก, ช่องสีม่วง `+` คือโมดูลที่ต่อเพิ่มได้ด้วย Data)
2. คลิก **Hangar** → กด **Load sample design** (ยานตัวอย่างที่ผ่านได้) หรือเลือกชิ้นส่วนเอง 7 ชิ้น + เลื่อนแถบ Propellant
   - ตัวเลขฝั่งขวาเป็นสีเขียว=ผ่าน แดง=ไม่ผ่าน (มวล, งบ, ไฟฟ้า, Δv, เสบียง)
3. กด **Mission Control >** → ดูแผนการบิน → **LAUNCH**
4. หน้า Flight: กด **CONTINUE** ไปเรื่อยๆ เจอเหตุการณ์ให้เลือก 1 ใน 2 (ทุกทางมีผลดีผลเสีย)
5. ลงจอดแล้วจะเข้า **Moon Walk 60 วินาที** — WASD/ลูกศรเดิน เก็บตัวอย่างสีเหลือง (5 แต้ม) และน้ำแข็งสีฟ้าในหลุมมืด (15 แต้ม แต่เดินช้าลง) กด Space เพื่อกลับก่อนเวลา
6. หน้า **Report** บอกเหตุผลทำไมผ่าน/ไม่ผ่าน + ตาราง 6 ทรัพยากรของโจทย์ (Mass, Power, Budget, Data, Comms, Time) → กด **Modify ship & rerun (same seed)** เพื่อแก้ยานแล้วลองใหม่ด้วยเหตุการณ์ชุดเดิม (เทียบผลได้ยุติธรรม)
7. ผ่านภารกิจแรกแล้ว **ปลดล็อกดาวอังคาร** = จบ DEMO; เอา Data ไปต่อโมดูลสถานีเพิ่ม (Greenhouse, Lab, Cargo Bay, Heavy Dock, Relay Array, Solar Wing)

## 3) ไฟล์ไหนทำอะไร

| ไฟล์ | หน้าที่ |
|---|---|
| `data/game_data.json` | **ตัวเลขทั้งหมดของเกม** (ชิ้นส่วน, ภารกิจ, เหตุการณ์, โมดูลสถานี) แก้ได้โดยไม่ต้องแตะโค้ด |
| `scripts/game_state.gd` | สมองของเกม (autoload ชื่อ `GameState`): สมการจรวด, เสบียง, ไฟฟ้า, Game Over 5 แบบ, คะแนน, เซฟ |
| `scripts/pix.gd` | ตัววาดพิกเซลอาร์ต (ยาน ดาว) และสร้างปุ่ม/ข้อความ ไม่ใช้รูปภายนอก = ไม่มีปัญหาลิขสิทธิ์ |
| `scripts/screen.gd` | คลาสแม่ของทุกหน้าจอ |
| `scripts/menu.gd` `station.gd` `hangar.gd` `mission.gd` `flight.gd` `explore.gd` `report.gd` | 7 หน้าจอ ตามลำดับการเล่น |
| `scenes/*.tscn` | ไฟล์ฉากของแต่ละหน้า (แต่ละอันมีแค่ Control + สคริปต์) |
| `tools/balance_check.py` | จำลองเกมด้วย Python เพื่อเช็กสมดุล (ไม่ต้องใช้ Godot) |

การเชื่อมหน้าจอ: `menu → station → (hangar | mission) → flight ⇄ explore → report → (hangar | station)`
ทุกหน้าเปลี่ยนด้วย `go("ชื่อฉาก")`

## 4) ฟิสิกส์จริงที่ใช้ (จาก Game Data Book)

- สมการจรวด: `m_prop = m_f · (e^(Δv/(Isp·g0)) − 1)`, g0 = 9.80665
- Δv แต่ละช่วง: LEO→TLI 3.2 / TLI→วงโคจรดวงจันทร์ 0.9 / ลงจอด 1.87 / ขึ้น+กลับ LEO 2.74 km/s (บวก margin 10%)
- ลูกเรือ 1 คน/วัน: O₂ 0.89 kg, น้ำดื่ม 2.79 kg, อาหาร 2.39 kg
- Isp: hypergolic ≈310, methalox ≈360, hydrolox ≈450 วินาที
- น้ำแข็งที่ขั้วใต้ดวงจันทร์ (LCROSS ≈ 5.6 ± 2.9% โดยมวล)
- **ค่าที่ปรับเองเพื่อให้เล่นสนุก (ไม่ใช่ฮาร์ดแวร์จริง)** ระบุด้วยคำว่า GAME ใน json เช่น ECLSS Advanced, งบ, มวลชิ้นส่วน, คะแนน
- ตัวง่ายที่ตั้งใจ: ใช้ยานเดียวไม่ทิ้งถัง (จริงใช้หลายท่อน) และให้บูสเตอร์ของสถานีทำ LEO→TLI ให้ — เขียนบอกผู้เล่นในหน้า Mission Control แล้ว

## 5) แก้เกมโดยไม่ต้องเขียนโค้ด

เปิด `data/game_data.json` ด้วย VS Code/Notepad แล้วแก้ แล้วกด F5 ใหม่

- เปลี่ยนงบ: `"budget": 340.0` → ตัวเลขอื่น
- เพิ่มตัวเลือกชิ้นส่วน: คัดลอกบล็อกใน `"options"` ของชิ้นนั้น (ต้องมี `name, mass, power, cost, info` และฟิลด์เฉพาะ เช่น `isp`)
- เพิ่มเหตุการณ์: คัดลอกบล็อกใน `"events"` แล้วแก้ `slot` (`space` หรือ `surface`) และ `fx`
  - `fx` ที่ใช้ได้: `days, supply_pct, water_kg, prop_pct, hull, rad_hull, power_mult, data_mult, data`
- เพิ่มโมดูลสถานี: คัดลอกบล็อกใน `"station_modules"` กำหนด `parent`, ตำแหน่ง `x,y`, `cost` (Data) และ `bonus`
- ตรวจสมดุลหลังแก้: `python3 tools/balance_check.py`

ผลตรวจปัจจุบัน: ยานตัวอย่างชนะ 100% ถ้าเลือกดี และ ~81% ถ้าสุ่มเลือก; ยานแย่ล้มเหลวด้วยเหตุผลที่ตั้งใจ (เชื้อเพลิงน้อย→Stranded, ล็อกเกอร์เล็ก→Starvation, ไฟไม่พอ→Power Failure); ประมาณ 24% ของแบบยานที่ปล่อยได้ผ่านภารกิจได้

## 6) Git — ทำงานเป็นทีม (คำสั่งตามลำดับ)

```bash
# ทำครั้งเดียวโดยหัวหน้าทีม
cd ogfrontier
git init
git add .
git commit -m "Initial prototype"
git branch -M main
git remote add origin https://github.com/<ทีมคุณ>/<ชื่อrepo>.git
git push -u origin main

# เพื่อนร่วมทีม
git clone https://github.com/<ทีมคุณ>/<ชื่อrepo>.git

# ก่อนเริ่มงานทุกครั้ง
git pull
git checkout -b feature/ชื่องาน     # เช่น feature/mars-mission

# ทำเสร็จ
git add .
git commit -m "อธิบายสั้นๆ ว่าทำอะไร"
git push -u origin feature/ชื่องาน   # แล้วเปิด Pull Request บน GitHub
```
กฎง่ายๆ: **คนละไฟล์/คนละหน้าจอ** จะได้ไม่ชนกัน (ไฟล์ `.tscn` กับ `game_data.json` ให้คุยกันก่อนแก้)

## 7) ส่งงานเป็นเกมที่เปิดบนเว็บ/เครื่อง (Export)

1. Godot → **Project → Export…** → **Add…** → เลือก **Web** (หรือ Windows Desktop)
2. ถ้ามีข้อความ "export templates missing" กด **Manage Export Templates → Download and Install**
3. กด **Export Project** เลือกโฟลเดอร์ `builds/`
4. สำหรับ Web ต้องเปิดผ่านเซิร์ฟเวอร์ (เช่น อัปโหลดขึ้น itch.io เลือก "HTML5 / playable in browser") ดับเบิลคลิกไฟล์ html ตรงๆ จะไม่ทำงาน

## 8) ถ้าเจอ Error

- **Parse Error / Identifier not declared:** ดูแถบ *Output* หรือ *Debugger* ด้านล่าง Godot จะบอกชื่อไฟล์+เลขบรรทัด — คัดลอกข้อความมาส่งให้ผม
- **หน้าจอดำ/ปุ่มไม่ขึ้น:** ตรวจว่าเปิดด้วย `project.godot` ในโฟลเดอร์นี้ และ Godot เป็นรุ่น 4.3+
- **Could not find type "Screen" หรือ "Pix":** ปิด Godot เปิดใหม่ (ให้สแกน class ใหม่) หรือเมนู *Project → Reload Current Project*
- **อยากเริ่มเซฟใหม่:** กด RESET SAVE ที่เมนู (เซฟอยู่ที่ `user://ogfrontier_save.json`)

## 9) ขั้นต่อไปที่แนะนำ (แบ่งงานทีม)

1. ผู้เล่นโค้ด: ทดสอบทุกหน้า แก้บั๊ก, เพิ่มเสียง/ภาพเคลื่อนไหว
2. ผู้ดูแลข้อมูล: ทบทวนตัวเลขใน json เทียบ Game Data Book, เพิ่มเหตุการณ์จริงจาก NASA
3. ผู้ออกแบบ: ทำ sprite พิกเซลจริงแทนการวาดด้วยสี่เหลี่ยม, ปรับ UI
4. ส่วนที่โจทย์บอกเป็นทางเลือก: leaderboard/เทียบผล (ตอนนี้มีประวัติ 6 รอบ + best score แล้ว), โหมด 2–4 ผู้เล่น
