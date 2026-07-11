# Установка

## Windows

1. Скачайте `mik32_upload.exe` из GitHub Releases.
2. Запустите приложение.

Если Windows показывает предупреждение SmartScreen или Microsoft Defender, проверьте, что файл скачан именно из этого репозитория, а SHA-256 совпадает с [../checksums.txt](../checksums.txt). Для Windows-сборки также опубликован [VirusTotal report](https://www.virustotal.com/gui/file/4bd81ce8813e56d351403f59b6e534d1c8c302e3960373b93cdbf3c2eeec5d34).

## Linux

1. Скачайте `mik32_uploader.AppImage` из GitHub Releases.
2. Выдайте права на запуск:

```bash
chmod +x mik32_uploader.AppImage
```

3. Запустите AppImage:

```bash
./mik32_uploader.AppImage
```

## Проверка файла

Контрольные суммы SHA-256 опубликованы в [../checksums.txt](../checksums.txt).

Дополнительные сведения о проверке файлов и возможных предупреждениях SmartScreen/Defender находятся в [../SECURITY.md](../SECURITY.md).

Linux:

```bash
sha256sum -c checksums.txt
```

Windows PowerShell:

```powershell
Get-FileHash -Algorithm SHA256 .\mik32_upload.exe
Get-FileHash -Algorithm SHA256 .\mik32_uploader.AppImage
```
