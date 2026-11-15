LAST LAUNCH v0.4.1 - WINDOWS BUILD
==================================

1. แตกไฟล์ ZIP ทั้งหมดก่อน (คลิกขวา -> Extract All)
   อย่าเปิด exe จากใน ZIP

2. ดับเบิลคลิก RUN_LAST_LAUNCH.bat
   (เกมฝัง .pck ไว้ใน OGFrontier.exe แล้ว จึงเป็นไฟล์เดียวจริง ๆ ไม่มี DLL ให้ก็อป)

3. ถ้า Windows SmartScreen ขึ้น "Windows protected your PC"
   คลิก "More info" -> "Run anyway"

4. ถ้าขึ้น "Unable to initialize video driver" หรือหน้าต่างดำ
   - สคริปต์จะลอง OpenGL 3.3 ให้เอง (กด OK ที่กล่องข้อความก่อน)
   - ถ้ายังไม่ได้ ลอง RUN_LAST_LAUNCH_SAFE.bat
   - ถ้ายังไม่ได้ แสดงว่าเครื่องนี้ไม่มีไดรเวอร์ 3D ที่ใช้ได้
     ให้ใช้เวอร์ชันเว็บ (LastLaunch_v0.4.1_Web.zip -> PLAY_WEB.bat)

ข้อมูลเกม
---------
- Save อยู่ที่: %APPDATA%\Godot\app_userdata\OG-Frontier Prototype\
- ลบ save ได้จากปุ่ม RESET SAVE ในเมนู
- เกมเวอร์ชันนี้ใช้ Godot 4.7.2 (Standard, ไม่ใช่ .NET)
