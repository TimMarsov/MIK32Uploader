# Windows-сборка

Публичный файл:

```text
mik32_upload_v1.0.0.exe
```

## Перед публикацией

1. Запустить файл на чистой системе или виртуальной машине Windows.
2. Проверить, что приложение открывается без дополнительных файлов рядом с `.exe`.
3. Проверить выбор файла прошивки и основной сценарий `START FLASHING`.
4. Проверить, что OpenOCD запускается или подключается согласно настройкам.
5. При наличии тестовой платы прогнать автотест из корня репозитория:

```bat
set UPLOADER_EXE=.\release\mik32_upload_v1.0.0.exe
set OPENOCD_BIN=C:\tools\openocd\bin\openocd.exe
set OPENOCD_SCRIPTS=C:\tools\openocd-scripts
set EEPROM_FILE=C:\firmware\eeprom.hex
set FLASH_FILE=C:\firmware\spifi.hex
set RAM_FILE=C:\firmware\ram.hex
.\tests\firmware_test_windows.bat
```

6. Посчитать SHA-256 из корня репозитория:

```powershell
Get-FileHash -Algorithm SHA256 .\release\mik32_upload_v1.0.0.exe
```

7. Обновить `checksums.txt` и `SECURITY.md`.
8. Загрузить файл на VirusTotal и добавить ссылку в `SECURITY.md`.
9. Загрузить файл в GitHub Release.

## Возможные предупреждения Windows

SmartScreen или Microsoft Defender могут предупреждать о новой неподписанной сборке. Для публичного релиза важно, чтобы пользователь мог проверить происхождение файла по SHA-256 и ссылке VirusTotal.
