# Установка

## Windows

1. Скачайте `mik32_upload_v1.0.0.exe` из GitHub Releases.
2. Запустите приложение.

Если Windows показывает предупреждение SmartScreen или Microsoft Defender, проверьте, что файл скачан именно из этого репозитория, а SHA-256 совпадает с [../checksums.txt](../checksums.txt). Для Windows-сборки также опубликован [VirusTotal report](https://www.virustotal.com/gui/file/4470fed452f1ef0e9ba1cbf78211f6f7b349b2f806bf78a7b52b4eb0f30c750b).

## Linux

1. Скачайте `MIK32_Uploader-x86_64_v1.0.0.AppImage` из GitHub Releases.
2. Выдайте права на запуск:

```bash
chmod +x MIK32_Uploader-x86_64_v1.0.0.AppImage
```

3. Запустите AppImage:

```bash
./MIK32_Uploader-x86_64_v1.0.0.AppImage
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
Get-FileHash -Algorithm SHA256 .\mik32_upload_v1.0.0.exe
Get-FileHash -Algorithm SHA256 .\MIK32_Uploader-x86_64_v1.0.0.AppImage
```
