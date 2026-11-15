# คู่มือแจกเกมให้ทีม — Last Launch v0.4.1

ไฟล์นี้อธิบายวิธีเปิดเกมให้ทีม **ทุกเครื่อง** รวมถึงเครื่องเก่าที่การ์ดจอไม่รองรับ
และวิธีแก้ error ที่ทีมเจอจริง (เปิด Godot แล้วไม่เห็นไฟล์ / exe เปิดไม่ได้)

---

## 0) สรุปสั้น (เลือก 1 ข้อ)

| ต้องการ | ใช้ไฟล์ | เปิดด้วย |
| --- | --- | --- |
| เล่นบนเครื่องเก่า / การ์ดจอมีปัญหา | `LastLaunch_v0.4.1_Web.zip` | `PLAY_WEB.bat` |
| เล่นบน Windows ทั่วไป | `LastLaunch_v0.4.1_Windows.zip` | `RUN_LAST_LAUNCH.bat` |
| แก้โค้ด / เปิดใน Godot | `LastLaunch_v0.4.1_Project.zip` | `OPEN_IN_GODOT.bat` |
| ดูเวอร์ชันเก่าต้นฉบับ | `LastLaunch_Legacy_v0.1.0_Project.zip` | เปิดใน Godot 4.7.2 |

> **เวอร์ชันเว็บคือคำตอบสำหรับเครื่องที่ขึ้น "Unable to initialize video driver"**
> เพราะเบราว์เซอร์มี software WebGL ไม่ต้องพึ่งไดรเวอร์การ์ดจอ

---

## 1) ทำไมทีมเปิดใน Godot แล้วไม่เห็นไฟล์

Error:

```text
Can't open file 'menu.tscn'. The file could have been moved or deleted.
```

และ FileSystem ด้านซ้ายว่างเปล่า / เห็นแค่ `res://`
สาเหตุคือ **เปิดผิดโฟลเดอร์** — Godot ถูกเปิดที่โฟลเดอร์แม่ ซึ่งมีแค่

```text
โปรเจคแก้ปัญหา01\
├── data\        <- มาจาก ogfrontier_addon.zip
├── docs\
├── scripts\
├── tools\
├── ogfrontier\  <- ตัวโปรเจกต์จริง (มี project.godot)
└── ...
```

โฟลเดอร์ที่ถูกต้องต้องมีโครงสร้างแบบนี้:

```text
ogfrontier\
├── project.godot      <- ต้องเห็นไฟล์นี้
├── scenes\menu.tscn
├── scripts\
├── data\
├── assets\
├── tests\
└── tools\
```

### วิธีเปิดที่ถูกต้อง

1. แตก ZIP ให้เสร็จก่อน
2. เข้าไปในโฟลเดอร์ที่มี `project.godot`
3. ดับเบิลคลิก `OPEN_IN_GODOT.bat` (สคริปต์ตรวจให้ว่าเปิดถูกโฟลเดอร์)
4. รอ import ครั้งแรก (จะสร้าง `.godot/` ซึ่งไม่ถูก commit) แล้วกด **F5**

หรือเปิดด้วยมือ: Godot → **Import** → เลือก `project.godot` → **Import & Edit**

> ถ้า editor เปิดไม่ขึ้นเพราะไดรเวอร์ ให้ใช้ `OPEN_IN_GODOT_SAFE.bat`
> (บังคับ OpenGL 3.3)

---

## 2) เล่นบน Windows (ไม่ต้องมี Godot)

1. แตก `LastLaunch_v0.4.1_Windows.zip` **ทั้งไฟล์**
2. ดับเบิลคลิก `RUN_LAST_LAUNCH.bat`
3. เกมเป็นไฟล์เดียว (`OGFrontier.exe` ฝัง .pck ไว้แล้ว) ไม่ต้องก็อปไฟล์อื่นตาม

### Windows ไม่ให้เปิด (SmartScreen)

เกมไม่ได้ sign certificate จึงอาจขึ้น `Windows protected your PC`:

**More info → Run anyway**

### ขึ้น "Unable to initialize video driver"

แปลว่าเครื่องนี้เปิด Vulkan (ค่าเริ่มต้น) ไม่ได้ — พบบ่อยบน VM / Remote Desktop / เครื่องเก่า
`RUN_LAST_LAUNCH.bat` จะลอง OpenGL 3.3 ให้เองอัตโนมัติ (กด **OK** ที่กล่องข้อความก่อน)

ถ้ายังไม่ขึ้น:

1. ลอง `RUN_LAST_LAUNCH_SAFE.bat` (บังคับ OpenGL 3.3)
2. ถ้ายังไม่ได้ แปลว่าเครื่องนี้ไม่มีไดรเวอร์ 3D ที่ใช้ได้เลย → ใช้เวอร์ชันเว็บ (ข้อ 3)
   ซึ่งใช้ software WebGL ของเบราว์เซอร์ ไม่พึ่งไดรเวอร์การ์ดจอ

---

## 3) เล่นบนเว็บ (แนะนำสำหรับเครื่องเก่า / VM / AnyDesk)

1. แตก `LastLaunch_v0.4.1_Web.zip`
2. ดับเบิลคลิก `PLAY_WEB.bat`
3. รอ 1–2 วินาที เบราว์เซอร์จะเปิด `http://localhost:8000/` เอง

**ห้ามดับเบิลคลิก `index.html`** เพราะเบราว์เซอร์โหลด `.pck` / `.wasm`
จาก `file://` ไม่ได้ (จะค้างหรือ error ใน Console)
`PLAY_WEB.bat` จะเปิด local server ให้ (มี Python หรือไม่ก็ได้)

- ใช้ Chrome หรือ Edge รุ่นใหม่
- ถ้าจอดำ ให้เปิด hardware acceleration ในการตั้งค่าเบราว์เซอร์
- ปิดหน้าต่างดำเมื่อเล่นเสร็จ

---

## 4) เวอร์ชันเก่า (Legacy v0.1.0)

`LastLaunch_Legacy_v0.1.0_Project.zip` คือต้นฉบับ 7 หน้าจอ
(ก่อนมี story / tutorial / crew cabin / terminal / EVA stamina)
เปิดด้วย Godot 4.7.2 เหมือนกัน แต่ไม่มีรูป NASA และเสียง

ใช้เมื่ออาจารย์ต้องการเทียบให้เห็นพัฒนาการ หรือเครื่องมือใหม่มีปัญหาเท่านั้น
เวอร์ชันที่ควรใช้จริงคือ **v0.4.1**

---

## 5) Error ที่อาจเจอ — ตารางแก้เร็ว

| อาการ | สาเหตุ | แก้ |
| --- | --- | --- |
| `Can't open file 'menu.tscn'` | เปิดโฟลเดอร์แม่ | เปิดโฟลเดอร์ที่มี `project.godot` |
| FileSystem ว่าง | เหมือนข้างบน | กด `Project → Reload Current Project` หลังเปิดถูกโฟลเดอร์ |
| `Unable to initialize video driver` | เครื่องไม่มี Vulkan (VM/RD/เครื่องเก่า) | `RUN_LAST_LAUNCH.bat` ลอง OpenGL ให้เอง, ถ้ายังไม่ได้ใช้เวอร์ชันเว็บ |
| SmartScreen บล็อก | exe ไม่ได้ sign | More info → Run anyway |
| ดับเบิลคลิก `index.html` แล้วค้าง | เบราว์เซอร์บล็อก file:// | ใช้ `PLAY_WEB.bat` |
| เปิดเกมแล้วหน้าต่างเล็ก/ตัดขอบ | ความละเอียดจอ | ลากขยาย หรือใช้เวอร์ชันเว็บ (ปรับขนาดอัตโนมัติ) |
| Save หายหลังย้ายเครื่อง | save อยู่แยกตามเครื่อง | เวอร์ชัน Windows: `%APPDATA%\Godot\app_userdata\OG-Frontier Prototype\` |
| เกม말고 editor ค้างตอน import | import ครั้งแรกใช้เวลา | รอจนแถบล่างหายไป |

---

## 6) ตรวจว่าไฟล์ที่โหลดมาครบ

ในโฟลเดอร์โปรเจกต์ต้องมีอย่างน้อย:

```text
project.godot
scenes\menu.tscn
scripts\game_state.gd
data\game_data.json
assets\CREDITS.md
```

ถ้าไม่มี `project.godot` หรือ `scenes\` แปลว่าโหลด/แตกไฟล์ไม่ครบ
ให้โหลด ZIP ใหม่ทั้งไฟล์

---

## 7) สำหรับคนดูแลโปรเจกต์ — สร้างแพ็กเกจแจก

```powershell
# ต้องมี Godot 4.7.2 export templates ติดตั้งแล้ว
powershell -NoProfile -ExecutionPolicy Bypass -File tools\package_team.ps1
```

จะได้ไฟล์ใน `dist\`:

```text
LastLaunch_v0.4.1_Project.zip
LastLaunch_v0.4.1_Windows.zip
LastLaunch_v0.4.1_Web.zip
LastLaunch_Legacy_v0.1.0_Project.zip
SHA256SUMS.txt
START_HERE.txt
```

อัปโหลด ZIP ทั้ง 4 ไฟล์เป็น **GitHub Release** (แท็ก `v0.4.1`)
แล้วส่งลิงก์ให้ทีม — อย่าฝากไฟล์ exe ไว้ใน git (เกิน 100 MB)

### ตรวจก่อนแจก

```powershell
# 1. headless test
& $godot --headless --path . -s tests/smoke_test.gd
# ต้องได้: PASS smoke_test (161 checks)

# 2. ภาพทุกหน้าจอ
& $godot --path . -s tools/screenshots.gd
# ต้องได้: SCREENSHOTS OK (23 ภาพ)

# 3. export
& $godot --headless --path . --export-release "Web" "builds/web/index.html"
& $godot --headless --path . --export-release "Windows Desktop" "builds/windows/OGFrontier.exe"
```

---

## 8) ปุ่มควบคุม

| ปุ่ม | การทำงาน |
| --- | --- |
| เมาส์ | เมนู / ปุ่มทั้งหมด / มินิเกมเล็งดาว (ชี้ในวงกลมค้างไว้) |
| WASD / ลูกศร | เดินบนดวงจันทร์ (3 รอบ/ภารกิจ พักระหว่างรอบ) |
| 1 / 2 / 3 | pace easy / normal / hard |
| Shift | burst (เร็ว แต่ stamina หมดเร็ว) |
| Space | กลับยานก่อนหมดเวลา EVA / เผาเครื่องแก้ทาง (กดค้าง 3 วิใน Flight) |
| F | ถ่ายภาพตัวอย่างก่อนเก็บ (คะแนน ×1.5, ต้องเลือกกล้องตอน prep) |
| E | เจาะแท่งดินที่โขดหิน / วางเครื่องวัดที่จุด deploy (กดค้าง) |
| Enter | ไปต่อใน Flight / tutorial |
| Esc | ย้อนกลับ / ปิด dossier |
| ? (มุมขวาบนสถานี) | tutorial overlay |

หมายเหตุ: ก่อนเดินรอบแรกมีจอเลือกเครื่องมือ 2 อย่างจาก 3 (camera/drill/meter);
ก่อนบินมีจอเลือกชั่วโมงออกกำลังกายลูกเรือ + เปิด/ปิด thermal roll
