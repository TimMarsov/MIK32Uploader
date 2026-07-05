# Автотесты прошивки

Эта папка содержит публичные копии скриптов, которыми проверяется MIK32 Flasher перед релизом. Они запускают матрицу записи и верификации прошивки для RAM, EEPROM и SPIFI Flash через OpenOCD.

Тесты не содержат тестовых прошивок и OpenOCD scripts. Пути к ним нужно передать через переменные окружения или положить файлы в ожидаемые локальные папки.

## Что проверяется

Скрипты запускают 14 комбинаций:

* RAM с `--reset-registers` и `--no-reset-registers`;
* EEPROM с драйвером и без драйвера;
* SPIFI Flash с драйвером и без драйвера;
* SPIFI Flash с Quad SPI;
* все основные варианты также проверяются с reset/no-reset режимами.

После каждой записи uploader выполняет `verify`. В конце печатается сводка: количество успешных/ошибочных прогонов, время и средняя скорость для успешных запусков.

## Windows

Файл: `firmware_test_windows.bat`

Пример запуска:

```bat
set UPLOADER_EXE=..\release\mik32_upload_v1.0.0.exe
set OPENOCD_BIN=C:\tools\openocd\bin\openocd.exe
set OPENOCD_SCRIPTS=C:\tools\openocd-scripts
set INTERFACE_CFG=C:\tools\openocd-scripts\interface\KoteLink.cfg
set TARGET_CFG=C:\tools\openocd-scripts\target\mik32.cfg
set EEPROM_FILE=C:\firmware\eeprom.hex
set FLASH_FILE=C:\firmware\spifi.hex
set RAM_FILE=C:\firmware\ram.hex
set REPEAT_COUNT=1
firmware_test_windows.bat
```

Если переменные не заданы, скрипт ожидает:

```text
tests/firmware/eeprom.hex
tests/firmware/spifi.hex
tests/firmware/ram.hex
tests/openocd-scripts/
release/mik32_upload_v1.0.0.exe
```

## Linux

Файл: `firmware_test_linux.sh`

Пример запуска:

```bash
chmod +x tests/firmware_test_linux.sh
UPLOADER_EXE=./release/MIK32_Uploader-x86_64_v1.0.0.AppImage \
OPENOCD_BIN=/usr/bin/openocd \
OPENOCD_SCRIPTS=/opt/openocd-scripts \
INTERFACE_CFG=/opt/openocd-scripts/interface/KoteLink.cfg \
TARGET_CFG=/opt/openocd-scripts/target/mik32.cfg \
EEPROM_FILE=/path/to/eeprom.hex \
FLASH_FILE=/path/to/spifi.hex \
RAM_FILE=/path/to/ram.hex \
REPEAT_COUNT=1 \
tests/firmware_test_linux.sh
```

Если переменные не заданы, скрипт ожидает:

```text
tests/firmware/eeprom.hex
tests/firmware/spifi.hex
tests/firmware/ram.hex
tests/openocd-scripts/
release/MIK32_Uploader-x86_64_v1.0.0.AppImage
```

## Повторные прогоны

Для стресс-проверки можно увеличить количество повторов:

```bash
REPEAT_COUNT=10 tests/firmware_test_linux.sh
```

На Windows:

```bat
set REPEAT_COUNT=10
firmware_test_windows.bat
```
