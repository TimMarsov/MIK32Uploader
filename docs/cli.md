# Командная строка

MIK32 Flasher можно использовать из командной строки.

```powershell
.\mik32_upload.exe --help
```

## Использование

```text
mik32_upload.exe firmware.hex [параметры]
```

Поддерживаемые форматы:

- `.hex`
- `.bin`
- `.elf`

## Основные параметры

```text
-h, --help              Показать справку и завершить работу
--run-openocd           Самостоятельно запустить OpenOCD
--use-quad-spi          Использовать Quad SPI для SPIFI
--boot-mode MODE        undefined/auto, eeprom, ram или spifi
--no-driver             Не использовать RAM-драйверы EEPROM/SPIFI
-t, --mcu-type TYPE     MIK32V0 или MIK32V2 (по умолчанию MIK32V2)
```

## Подключение к OpenOCD

```text
--openocd-host HOST     Адрес TCL-сервера (по умолчанию 127.0.0.1)
--openocd-port PORT     Порт TCL-сервера (по умолчанию 6666)
--adapter-speed SPEED   Скорость адаптера, кГц (по умолчанию 500)
--openocd-exec PATH     Путь к исполняемому файлу OpenOCD
--openocd-scripts PATH  Путь к каталогу scripts
--openocd-interface CFG Interface cfg относительно scripts или полный путь
--openocd-target CFG    Target cfg относительно scripts или полный путь
--open-console          Открыть OpenOCD в отдельной консоли
--log-path PATH         Файл журнала OpenOCD
--post-action ACTION    Команда после записи (по умолчанию reset run)
```

## Reset Peripherals

```text
--reset-registers       Сбросить периферию МК после успешной записи (включено по умолчанию)
--no-reset-registers    Не сбрасывать периферию МК после успешной записи
```

## Boot Mode

```text
auto/undefined  BOOT-сегменты файла пропускаются
eeprom          BOOT-сегменты записываются в EEPROM
ram             BOOT-сегменты записываются в RAM
spifi           BOOT-сегменты записываются во внешнюю Flash
```

После записи выполняются верификация и `reset run` если не указано иное действие. 

## Примеры

Запустить OpenOCD из программы и прошить HEX в EEPROM:

```powershell
.\mik32_upload.exe firmware.hex --run-openocd --boot-mode eeprom
```

Прошить ELF в RAM и продолжить выполнение с адреса RAM-программы:

```powershell
.\mik32_upload.exe firmware.elf --run-openocd --boot-mode ram --post-action "resume 0x02000000"
```

Подключиться к уже запущенному OpenOCD:

```powershell
.\mik32_upload.exe firmware.bin --openocd-host 127.0.0.1 --openocd-port 6666 --boot-mode spifi
```
