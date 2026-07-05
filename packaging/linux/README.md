# Linux AppImage

Публичный файл:

```text
MIK32_Uploader-x86_64_v1.0.0.AppImage
```

## Перед публикацией

1. Выдать права на запуск:

```bash
chmod +x MIK32_Uploader-x86_64_v1.0.0.AppImage
```

2. Запустить AppImage на чистой системе или виртуальной машине Linux.
3. Проверить, что приложение открывается без установки дополнительных файлов из рабочего каталога.
4. Проверить выбор файла прошивки и основной сценарий `START FLASHING`.
5. Проверить поведение на системе с FUSE/AppImage-совместимостью.
6. При наличии тестовой платы прогнать автотест из корня репозитория:

```bash
UPLOADER_EXE=./release/MIK32_Uploader-x86_64_v1.0.0.AppImage \
OPENOCD_BIN=/usr/bin/openocd \
OPENOCD_SCRIPTS=/opt/openocd-scripts \
EEPROM_FILE=/path/to/eeprom.hex \
FLASH_FILE=/path/to/spifi.hex \
RAM_FILE=/path/to/ram.hex \
./tests/firmware_test_linux.sh
```

7. Посчитать SHA-256 из корня репозитория:

```bash
sha256sum release/MIK32_Uploader-x86_64_v1.0.0.AppImage
```

8. Обновить `checksums.txt` и `SECURITY.md`.
9. Загрузить файл на VirusTotal и добавить ссылку в `SECURITY.md`.
10. Загрузить файл в GitHub Release.
