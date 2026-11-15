# Design: v0.5.0 — Team feedback round (walkable station, clarity, T17/T18, solar-system campaign)

วันที่: 2026-11-15
สถานะ: อัปเดตตามคำตอบทีมแล้ว — **รออนุมัติครั้งสุดท้าย**

---

## 1) Intent — ทำไมต้องทำ

ทีมทดสอบจริงแล้วเจอ 3 ปัญหา: (1) เปิดหน้าแรกแล้วงง ไม่รู้เริ่มยังไง (2) ช่อง/ปุ่มบางอันกดแล้วไม่รู้ว่ามันทำอะไรหรือกดไม่ได้ (3) ระหว่างบินกับบนผิวดาวมีแต่ CONTINUE — ไม่สนุก รู้สึกว่าไม่ได้เล่น
เป้าหมาย: ให้เกม**อธิบายตัวเองได้** และให้ผู้เล่น**ตัดสินใจ/ลงมือ**ระหว่างทางกับบนผิวดาวตามสิ่งที่ภารกิจจริงทำ (Apollo 11/17, Artemis III) โดยไม่เพิ่ม asset จากภายนอก (วาดด้วยโค้ดทั้งหมดเหมือนเดิม)

## 2) Goals

1. **ยานแม่เดินได้ (แนวทาง ก)**: นักบินอวกาศเดินบนแผนภาพสถานี (WASD หรือคลิกจุดหมาย) **ชนกำแพงได้** เดินใกล้ห้อง → ขึ้นปุ่ม **E** กดเปิดห้อง/จุดที่ทำอะไรได้
2. **ล้างหน้าแรก**: เมนูเหลือ START / SETTINGS / RESET SAVE / QUIT — HOW TO PLAY และ STORY ย้ายไปอยู่ในยานแม่
3. **Tooltip มีภาพ**: ชี้เมาส์ที่ห้อง/ปุ่ม/ชิ้นส่วน → แผงเล็กมีรูปวาด + คำอธิบาย + ป้าย real/calc/game
4. **Tech Book หน้าใหม่**: ภาพ + คำอธิบายของทุกระบบ (โมดูลสถานี, ชิ้นส่วนยาน, ระบบ stamina, ภารกิจ, ทรัพยากร) — เปิดจากสถานีเท่านั้น (เมนูยังโล่งอยู่)
5. **บอกชัดเมื่อ Data ไม่พอ**: ป้ายแดงแสดงจำนวนที่ขาด ไม่ใช่แค่ข้อความบรรทัดล่าง
6. **T17 กิจกรรมระหว่างบิน** (Flight Log): เล็งดาวนำทาง, เผาเครื่องแก้ทาง, thermal roll, crew schedule
7. **T18 พื้นผิวดาว**: เดิน 3 รอบพร้อมจอพักระหว่างรอบ, งานย่อยบนผิว (prep/document/core/deploy), มวลตัวอย่างกลับยานมีผลจริง
8. **delta-v ไม่พอมีผลจริงและเห็นชัด**: เตือนก่อนปล่อย + ผลระหว่างบิน + รายงานอธิบาย
9. **Campaign ครบระบบสุริยะ + เดดไลน์วันจริง**: 8 ภารกิจ (Moon, Mars + โพรบ 6 ดวง: Mercury, Venus, Jupiter, Saturn, Uranus, Neptune) — ชนะเมื่อครบก่อนเดดไลน์, เกิน = โลกอยู่ไม่ได้
10. **Lobby ดูแลฟาร์ม** + **ช่องแบบยาน 3 ช่อง** (บันทึก/สลับแบบยานได้)
11. ทำตาม `OPENCODE_TASKS_STAMINA_PHYSICS_FARM.md` ลำดับ T10 → T11 → T17 → T18 และกฎความจริงของข้อมูล

## 3) Non-goals (ไม่ทำในรอบนี้)

- แนวทาง ข (ฉากเดิน 3 มิติ/World2D ใหม่) — ทีมตัดออกแล้ว
- Rover (ปุ่ม R) — "ไว้ทีหลัง" ตามที่ทีมสั่ง
- Multiplayer, addons, C#, asset ภายนอก
- T12–T16 เต็มรูปแบบ (ส่วนใหญ่มีแล้ว; T14 ฟาร์มทำแบบย่อพอใช้ได้)

## 4) Anti-goals (ทำแล้วถือว่าพลาด)

- แก้ค่า `real`/`calc` เพื่อบาลานซ์ — ห้าม; แก้ได้เฉพาะ `game`
- ค่า `game` โผล่ให้ผู้เล่นเห็นโดยไม่มีป้าย "game value / game rule"
- Save เก่าพัง (ต้อง bump `save_version` + ค่า default)
- 1 ภารกิจยาวเกิน ~5 นาที (ตกลงกับทีมแล้ว: ต่อ 1 ภารกิจ; ทั้งแคมเปญยาวได้ ~30–40 นาที)
- ใส่ตัวเลขที่ไม่มีแหล่งลง JSON (tag ครบทุกคีย์, `null` = "not researched")

## 5) Constraints

- Godot 4.7.2, GDScript เท่านั้น, ในเกมเป็นภาษาอังกฤษ, ตัวเลขทั้งหมดอยู่ใน `data/*.json`
- เครื่องทดสอบ: Vulkan ได้, OpenGL 3.3/D3D11 **ไม่ได้** → ห้ามบังคับ gl_compatibility ใน project.godot
- Console เป็น cp932: ห้าม print ไทยลงคอนโซล; ไฟล์ไทยเป็น UTF-8
- ห้าม force push branch; commit+push ทุกครั้งหลังแก้
- Gates: smoke test, `check_physics.py`, `balance_check.py`, screenshots ทุกหน้า, export ทั้ง 2 preset, `package_team.ps1`

## 6) Approach (เลือกแล้วโดยทีม)

**ก. เดินบนแผนภาพสถานี** — หน้าจอ station เดิม (1280×720, Control + draw) กลายเป็น "พื้นยาน": ตัวละคร = นักบินอวกาศวาดด้วยโค้ด, เคลื่อน WASD/คลิกจุดหมาย, **ชนกำแพง** = ตัวละครถูกบล็อกด้วยเส้น/กล่องของผนังยาน (circle-vs-segment กันหลุด) ไม่ต้องสร้าง World2D ใหม่ — เข้ากับสถาปัตยกรรมเดิม เสี่ยงต่ำ

## 7) สิ่งที่ทีมตัดสินแล้ว (คำตอบเมื่อ 15 พ.ย. 2026)

| ข้อ | คำตอบทีม |
| --- | --- |
| เดดไลน์ | **ขยายเป็นวันจริง** (ไม่ใช่ 180 วันแบบเกม) — ดูข้อ 8.9 |
| ตัวเลขดาวนอก | **สร้างค่า game ใหม่ติดป้ายก่อน** (Saturn/Uranus/Neptune) — **อนาคตเปลี่ยนตาม Data Book เมื่อทีมเพิ่มข้อมูล** (log เป็น open question) |
| ดาวแก๊ส + Mercury/Venus | **ระบบโพรบแยก** — ไม่ผ่านออกแบบยาน/rocket equation |
| ความยาว | **~5 นาทีต่อ 1 ภารกิจ** (EVA 60 s × 3 ยังอยู่) |
| Story | **อยู่ในสถานี** — START เข้าสถานีตรง ๆ; ครั้งแรก story เล่นอัตโนมัติ**บนหน้าสถานี** (overlay) แล้วปิดเข้าสถานี; เมนูไม่มีปุ่ม story |
| สร้างยานเพิ่มเติม | **ช่องแบบยาน 3 ช่อง** บันทึก/สลับได้ใน hangar — ทีมยืนยัน "ยานหลายรูปแบบ" |
| ครบทุกดวง | **นับ Mercury + Venus ด้วย** (ภารกิจโพรบ) = 8 ภารกิจรวม |

## 8) รายละเอียดระบบ (สรุปสำหรับคนสร้าง)

### 8.1 Station walk + E (station.gd)
- แผนผังยาน = ภาพ station เดิม (โมดูลเป็นกล่องสี) ตัวละครวาดบน `draw_extra`
- พื้นที่เดินได้ = พื้นหลังยาน; กำแพง = ขอบยาน + กล่องโมดูล (ชนไม่ได้; โมดูลที่ยังไม่สร้าง = แผงขวางที่กด E สร้างได้)
- ใกล้ประตู (ระยะ < ~48px): ป้าย **[E] Hangar** ฯลฯ ขึ้น; กด E → เข้าห้องเดิม (`go(...)`)
- ห้องเสริม (CREW CABIN, TERMINAL, HOW TO PLAY, TECH BOOK) เป็นจุดบนแผนที่ ไม่ใช่ปุ่มมุมขวา
- คลิกจุดหมาย = auto-walk ตามเส้นตรง (ชนกำแพงแล้วหยุดที่ผนัง); กด ? เปิด tutorial เดิม
- สร้างโมดูล: เดินไปช่อง + สีม่วง → E → กรอบยืนยัน "Build Greenhouse (20 Data)" พร้อมผลลัพธ์

### 8.2 เมนูหน้าแรก (menu.gd)
- ลบปุ่ม HOW TO PLAY / STORY; START → station ตรง ๆ (ทีมยืนยัน: "เอาสอนเล่นกับสตอรี่ออกจากหน้าแรกก่อนเข้าเกม")
- **Story**: ครั้งแรกที่เข้าสถานี สไลด์ story เล่นเป็น overlay บนหน้าสถานีเอง แล้วปิดเข้าสถานี (มีปุ่ม STORY ในสถานีเปิดซ้ำ)

### 8.3 Tooltip พร้อมภาพ (pix.gd เพิ่ม `hover_card`)
- แผง ~260×200 ที่ตำแหน่งใกล้เมาส์: รูปวาด (ไอคอนโค้ดวาด) + ชื่อ + คำอธิบาย + ป้าย tag
- ใช้กับ: ห้องทุกห้องในสถานี, ชิ้นส่วนใน hangar, ปุ่มหลักทุกหน้า

### 8.4 Tech Book (ฉากใหม่ techbook.tscn + techbook.gd)
- แท็บ: STATION / SHIP / EVA / MISSIONS / RESOURCES; ไอคอนวาด + ชื่อ + "ช่วยอะไร" + "ได้มายังไง" + ป้าย real/calc/game
- เนื้อหาอ่านจาก JSON เดิม ไม่ hardcode ตัวเลข; เข้าถึงจากสถานีเท่านั้น

### 8.5 ข้อความ Data ไม่พอ
- มาตรฐานเดียว: แผงแดงกลางจอ "Not enough Data: need 30, have 12. Earn Data by completing missions." — ใช้ทุกที่ที่ใช้ Data

### 8.6 T17 Flight Log (flight.gd + data/activities.json)
- ไทม์ไลน์ตามสัดส่วน trip (อ่าน `trigger_fraction_of_trip` จาก JSON): nav sighting ×2 (8.2%, 32.8%), midcourse burn (36.3%), thermal roll, crew schedule
- **Nav sighting**: ถือเมาส์ค้างในวง `window_s` วินาทีบนเป้าเลื่อนช้า — ความแม่นลด dv-error ของ burn (สูงสุด `max_extra_dv_error_m_s`); พลาด = เสีย propellant ไม่จบ run
- **Midcourse burn**: nominal 6.37 m/s (real: Apollo 11 = 20.9 ft/s), ถือปุ่ม `burn_hold_s` — เผาเกิน/ขาด → propellant เปลี่ยนตาม rocket equation เดิม
- **Thermal roll**: เปิด default; ข้าม → hull -2%/วัน (game)
- **Crew schedule**: 0/1/2 ชม. ออกกำลังกาย/วัน (ISS จริง 2) → กระทบ stamina ตอนถึง (rule เดิม 10%)
- ป้าย "Real basis: Apollo 11" หรือ "Game rule" ทุกจอ; Mars-class: delayed comms จำกัดเวลา `decision_time_s`

### 8.7 T18 Surface (explore.gd + data/activities.json)
- เดิน `eva_count_default` = 3 รอบ, รอบละ `eva_window_s` (75 s; ใช้ค่า settings เดิม default 60 s) มีจอพักระหว่างรอบ (stamina เติมเต็ม, คะแนนสะสมต่อ)
- งานย่อย: **prep** (เลือกเครื่องมือก่อนเดิน), **document** (ถ่ายภาพก่อนเก็บ, คะแนน ×1.5), **core** (ถือปุ่มเจาะแท่งดิน, ×2.0, pace hard), **deploy** (วางเครื่องวัด, ให้คะแนนทุก walk ถัดไป)
- ตัวอย่างหนักขึ้น = dry mass ขึ้นจริง (Apollo 17: 110.4 kg) — เลือกทิ้งก่อนขึ้นได้; เอาเข้าตอน `finish_explore` ก่อน burn กลับ
- ป้าย: ชื่องาน = "Artemis III plan", ตัวเลข = "Game rule"

### 8.8 Delta-v ไม่พอ → ผลจริง
- ก่อน LAUNCH: แถบแดงที่ mission.gd แสดงขาดเท่าไร (km/s) และผลที่จะเกิด
- ระหว่างบิน: propellant ไม่พอในขา burn → event บังคับ "Partial burn" เลือกใช้สำรอง/ตัดภารกิจ
- report: บรรทัดสรุปสาเหตุชัดเจน (ระบบเดิมมี — ตรวจว่าแสดงชัด)

### 8.9 Campaign: เดดไลน์วันจริง + ภารกิจโพรบ (ตัดสินแล้ว)
- **นาฬิกาโลก = วันจริง** นับเฉพาะ: วันบนสถานี + วันภารกิจคน (Moon, Mars) — ตัวเลขจาก physics.json (Hohmann จริง 972 วัน ฯลฯ) ไม่ถูกแตะ
- **เดดไลน์ `earth_survival_days` = 1,200 วัน** (ค่า game, ติดป้าย "game rule"): Moon 9 + Mars 972 (Hohmann) + เผื่อวันสถานี — เลือก transfer เร็ว/ช้า (T13) จึงตัดสินใจได้จริง (เร็วกว่า = เสีย dv มากกว่า)
- **+180 วัน (ตามที่ทีมสั่งตอนแรก)**: เกมจบอย่างเป็นทางการเมื่อทำครบ 8 ภารกิจแล้ว **+180 วัน** (ช่วง stabilization epilogue) — ถ้าทำไม่ครบก่อน 1,200 วัน = จบแบบแพ้ (Earth fails)
- **ภารกิจโพรบ 6 ดวง** (Mercury, Venus, Jupiter, Saturn, Uranus, Neptune): ระบบแยก ไม่ผ่านออกแบบยาน
  - **Launch window = synodic period จริง** (physics.gd `synodic_days`, เช่น Jupiter 399 d) — เปิดเฉพาะช่วงนั้น พลาดต้องรอรอบถัดไป (นับเวลาจริงบนสถานี)
  - ค่าใช้จ่าย: Data + 1–3 วันสถานี (game) — ปล่อย = เสร็จภารกิจ (นับ win)
  - มินิเกมโพรบ 2 อัน: **station-keeping** (ถือแนวในโซนเสถียร X วินาที) + **gas scoop** (เลือกความลึก = เสี่ยง/ได้คะแนน) — รางวัล = คะแนน smelter (แก๊ส) / Data (สำรวจ)
  - ตัวเลข legs/dv/ทรัพยากรของ Saturn/Uranus/Neptune = **ค่า game ติดป้ายทั้งหมด**; destinations.json เพิ่ม null key "not researched" + block game — **อนาคตทีมเปลี่ยนตาม Data Book** (log เป็น open question)
- HUD ทุกหน้า: "DAY xxx / 1200"; จอจบใหม่ win/lose
- ลำดับภารกิจแนะนำ: Moon → Mars → Jupiter → Saturn → Mercury → Venus → Uranus → Neptune

### 8.10 Lobby ฟาร์ม + ช่องแบบยาน
- Greenhouse (ถ้าสร้างแล้ว) → หน้าฟาร์ม: เลือกผัก (farm.json), ดูโต, เก็บเกี่ยวเข้า food (T14 แบบย่อ)
- **ช่องแบบยาน 3 ช่อง** (`designs[0..2]` ใน save, bump `save_version`): hangar เลือกช่อง/บันทึก/โหลด

## 9) งานเตรียมข้อมูล (ไม่ใช่ feature แต่จำเป็น)

- คัดลอก `data/activities.json` + `data/destinations.json` จากโฟลเดอร์แม่เข้าโปรเจกต์ (ตอนนี้หายไปจาก repo!)
- คัดลอก `tools/check_physics.py` เข้า `tools/` และรันให้ผ่าน
- T10/T11 ตรวจกับ AC (Stamina ต่อใน explore แล้ว, exercise module มีแล้ว) — เทสต์จริงแล้วเก็บ gap

## 10) การตรวจ (gates ก่อน merge ทุกครั้ง)

1. `check_physics.py` ผ่าน (tag ครบทุกคีย์)
2. smoke test ผ่าน (161+ checks)
3. `balance_check.py` ตรง GDScript (เพิ่ม mirror ของ propellant/activities)
4. Screenshots ครบทุกหน้าใหม่ (station-walk, tooltip, techbook, T17, T18, จอจบ, farm, hangar slots)
5. Save เก่าโหลดได้ (bump version)
6. Export Web + Windows, `package_team.ps1`, commit+push

## 11) ลำดับการสร้าง (หลังอนุมัติ)

1. T10 verify + copy ไฟล์ data/tools → 2. T11 verify/gap-fix → 3. T17 → 4. T18 → 5. Station walk + E + กำแพง → 6. เมนูล้าง + ย้าย story/howto → 7. Tooltip framework → 8. Tech Book → 9. ข้อความ Data ไม่พอ → 10. delta-v warnings → 11. Campaign + โพรบ + synodic windows → 12. Farm + ช่องแบบยาน → 13. เอกสาร/CHANGELOG/gates/package

## 12) Open questions (คงเหลือสำหรับทีม)

1. **ช่องที่ "กดไม่ได้"**: ทีมยืนยันแล้ว = **ปุ่ม `+` สีม่วง** (สร้างโมดูล) — แก้ตามข้อ 8.5: แผงแดงชัดเจน + ปุ่มเทาแสดงราคาเมื่อ Data ไม่พอ + tooltip อธิบาย
2. ตัวเลขดาวนอก (Saturn/Uranus/Neptune) = ค่า game ชั่วคราว → **ทีมเพิ่มหน้าใน Data Book แล้วค่อยเปลี่ยน** (บันทึกใน OVERNIGHT_LOG)
3. (จากไฟล์ task ข้อ 5 เดิม) เร็ว/ช้า transfer ของ Moon: fast-coast dv ไม่มีในข้อมูล → ใส่ 0 แล้ว log ไว้

## 13) สิ่งที่ผมตัดสินใจเอง (my calls — ตรวจได้ตอนอนุมัติ)

- `earth_survival_days` = 1,200 (game), epilogue +180 วัน, synodic window = กลไกนับเวลาจริง
- สัดส่วน/ตำแหน่งแผนที่เดิน, ความเร็วเดิน, รัศมีประตู E, หน้าตาไอคอน tooltip/techbook (วาดโค้ด)
- แผง confirm สร้างโมดูล, หน้าจอจบ win/lose, ตัวเลข `game` ทั้งหมด (ปรับได้)
- Tech Book เปิดจากสถานีเท่านั้น (เมนูโล่งตามที่ทีมสั่ง)
