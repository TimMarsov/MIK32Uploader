#!/usr/bin/env bash
set -u

# ==========================================================
# MIK32 firmware write + verification tests for RAM/EEPROM/SPIFI
# ==========================================================

PROJECT_NAME="firmware"

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$ROOT_DIR/.." && pwd)"

# Paths can be overridden before launch:
#   UPLOADER_EXE=/path/to/MIK32_Uploader-x86_64_v1.0.0.AppImage
#   OPENOCD_BIN=/path/to/openocd
#   OPENOCD_SCRIPTS=/path/to/openocd-scripts
#   EEPROM_FILE=/path/to/eeprom.hex
#   FLASH_FILE=/path/to/spifi.hex
#   RAM_FILE=/path/to/ram.hex

UPLOADER_EXE="${UPLOADER_EXE:-$REPO_ROOT/release/MIK32_Uploader-x86_64_v1.0.0.AppImage}"
if [[ ! -x "$UPLOADER_EXE" && -x "$REPO_ROOT/release/mik32_upload" ]]; then
    UPLOADER_EXE="$REPO_ROOT/release/mik32_upload"
fi

OPENOCD_BIN="${OPENOCD_BIN:-$(command -v openocd || true)}"
if [[ ! -x "$OPENOCD_BIN" ]]; then
    OPENOCD_BIN="$(command -v openocd || true)"
fi

OPENOCD_SCRIPTS="${OPENOCD_SCRIPTS:-$ROOT_DIR/openocd-scripts}"
INTERFACE_CFG="${INTERFACE_CFG:-$OPENOCD_SCRIPTS/interface/KoteLink.cfg}"
TARGET_CFG="${TARGET_CFG:-$OPENOCD_SCRIPTS/target/mik32.cfg}"

EEPROM_FILE="${EEPROM_FILE:-$ROOT_DIR/firmware/eeprom.hex}"
FLASH_FILE="${FLASH_FILE:-$ROOT_DIR/firmware/spifi.hex}"
RAM_FILE="${RAM_FILE:-$ROOT_DIR/firmware/ram.hex}"
MCU_TYPE="${MCU_TYPE:-MIK32V2}"
ADAPTER_SPEED="${ADAPTER_SPEED:-500}"
REPEAT_COUNT="${REPEAT_COUNT:-1}"

# 1 - pause before every next test, 0 - run all tests without pauses.
PAUSE_BETWEEN_TESTS="${PAUSE_BETWEEN_TESTS:-0}"
DRY_RUN="${DRY_RUN:-0}"

TOTAL_TESTS=0
EXPECTED_GROUPS=14
EXPECTED_TESTS=$((EXPECTED_GROUPS * REPEAT_COUNT))
PASSED_TESTS=0
FAILED_TESTS=0
FAILED_LIST=""
SUMMARY_FILE="$(mktemp -t mik32_upload_stats.XXXXXX)"
: > "$SUMMARY_FILE"

cleanup() {
    rm -f "$SUMMARY_FILE"
}
trap cleanup EXIT

error_exit() {
    echo "[ERROR] $*" >&2
    exit 1
}

require_file() {
    local label="$1"
    local file="$2"
    [[ -n "$file" && -f "$file" ]] || error_exit "$label not found: $file"
}

require_executable() {
    local label="$1"
    local file="$2"
    [[ -n "$file" && -x "$file" ]] || error_exit "$label not found or not executable: $file"
}

require_dir() {
    local label="$1"
    local dir="$2"
    [[ -n "$dir" && -d "$dir" ]] || error_exit "$label not found: $dir"
}

next_test() {
    if [[ "$PAUSE_BETWEEN_TESTS" == "1" ]]; then
        echo
        read -r -n 1 -p "[INFO] Press any key to start next test..." _
        echo
        echo
    fi
}

run_test() {
    local label="$1"
    local firmware_file="$2"
    local extra_args_string="$3"
    local repeat_index="$4"
    local file_size start_ms end_ms elapsed_ms speed_kbps test_result

    file_size=$(stat -c '%s' "$firmware_file")
    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    echo "=========================================================="
    echo "[TEST $TOTAL_TESTS] $label (repeat $repeat_index/$REPEAT_COUNT)"
    echo "[FILE] $firmware_file"
    echo "[SIZE] $file_size bytes"
    echo "[ARGS] $extra_args_string"
    echo "=========================================================="

    # Split static test arguments exactly like the .bat EXTRA_ARGS string.
    local -a extra_args=()
    read -r -a extra_args <<< "$extra_args_string"

    if [[ "$DRY_RUN" == "1" ]]; then
        echo "[DRY-RUN] $UPLOADER_EXE" "$firmware_file" \
            --run-openocd \
            --openocd-exec="$OPENOCD_BIN" \
            --openocd-scripts="$OPENOCD_SCRIPTS" \
            --openocd-interface="$INTERFACE_CFG" \
            --openocd-target="$TARGET_CFG" \
            --adapter-speed="$ADAPTER_SPEED" \
            --mcu-type="$MCU_TYPE" \
            "${extra_args[@]}"
        LAST_RESULT=0
        LAST_ELAPSED_MS=1
        LAST_SPEED_KBPS=$((file_size * 1000 / 1 / 1024))
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo "[PASS] $label (dry-run)"
        return
    fi

    start_ms=$(date +%s%3N)

    "$UPLOADER_EXE" "$firmware_file" \
        --run-openocd \
        --openocd-exec="$OPENOCD_BIN" \
        --openocd-scripts="$OPENOCD_SCRIPTS" \
        --openocd-interface="$INTERFACE_CFG" \
        --openocd-target="$TARGET_CFG" \
        --adapter-speed="$ADAPTER_SPEED" \
        --mcu-type="$MCU_TYPE" \
        "${extra_args[@]}"
    test_result=$?

    end_ms=$(date +%s%3N)
    elapsed_ms=$((end_ms - start_ms))
    (( elapsed_ms <= 0 )) && elapsed_ms=1
    speed_kbps=$((file_size * 1000 / elapsed_ms / 1024))

    echo
    echo "[$label] Exit code: $test_result"
    echo "[$label] Time: $elapsed_ms ms"
    echo "[$label] Speed: $speed_kbps KB/s"
    echo "[$label] Repeat: $repeat_index/$REPEAT_COUNT"
    echo

    LAST_RESULT=$test_result
    LAST_ELAPSED_MS=$elapsed_ms
    LAST_SPEED_KBPS=$speed_kbps

    if [[ "$test_result" == "0" ]]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo "[PASS] $label"
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_LIST+=" $label repeat $repeat_index;"
        echo "[FAIL] $label"
    fi
}

run_repeated_test() {
    local label="$1"
    local firmware_file="$2"
    local extra_args="$3"
    local group_bytes group_pass=0 group_fail=0 group_total_ms=0 group_min_ms=2147483647 group_max_ms=0 group_total_kbps=0
    local repeat group_avg_ms group_avg_kbps

    group_bytes=$(stat -c '%s' "$firmware_file")

    for ((repeat = 1; repeat <= REPEAT_COUNT; repeat++)); do
        run_test "$label" "$firmware_file" "$extra_args" "$repeat"
        if [[ "$LAST_RESULT" == "0" ]]; then
            group_pass=$((group_pass + 1))
            group_total_ms=$((group_total_ms + LAST_ELAPSED_MS))
            group_total_kbps=$((group_total_kbps + LAST_SPEED_KBPS))
            (( LAST_ELAPSED_MS < group_min_ms )) && group_min_ms=$LAST_ELAPSED_MS
            (( LAST_ELAPSED_MS > group_max_ms )) && group_max_ms=$LAST_ELAPSED_MS
        else
            group_fail=$((group_fail + 1))
        fi
        if (( repeat != REPEAT_COUNT )); then
            next_test
        fi
    done

    if (( group_pass > 0 )); then
        group_avg_ms=$((group_total_ms / group_pass))
        group_avg_kbps=$((group_total_kbps / group_pass))
        echo "$label: pass=$group_pass fail=$group_fail size=$group_bytes bytes min=$group_min_ms ms avg=$group_avg_ms ms max=$group_max_ms ms avg_speed=$group_avg_kbps KB/s" >> "$SUMMARY_FILE"
    else
        echo "$label: pass=0 fail=$group_fail size=$group_bytes bytes avg_speed=N/A" >> "$SUMMARY_FILE"
    fi
}

require_file "EEPROM firmware file" "$EEPROM_FILE"
require_file "Flash firmware file" "$FLASH_FILE"
require_file "RAM firmware file" "$RAM_FILE"
require_executable "Uploader" "$UPLOADER_EXE"
require_executable "OpenOCD" "$OPENOCD_BIN"
require_dir "OpenOCD scripts directory" "$OPENOCD_SCRIPTS"
require_file "Interface cfg" "$INTERFACE_CFG"
require_file "Target cfg" "$TARGET_CFG"

cat <<INFO
[INFO] EEPROM:    $EEPROM_FILE
[INFO] Flash:     $FLASH_FILE
[INFO] RAM:       $RAM_FILE
[INFO] Uploader:  $UPLOADER_EXE
[INFO] OpenOCD:   $OPENOCD_BIN
[INFO] Scripts:   $OPENOCD_SCRIPTS
[INFO] Interface: $INTERFACE_CFG
[INFO] Target:    $TARGET_CFG
[INFO] MCU type:  $MCU_TYPE
[INFO] Repeats:   $REPEAT_COUNT per parameter combination
[INFO] Speed:     $ADAPTER_SPEED kHz
[INFO] Dry run:   $DRY_RUN

Verification is performed by mik32_upload after every write.
Speed statistics are calculated from firmware file size and elapsed time.
INFO

run_repeated_test "RAM no-reset-registers" "$RAM_FILE" "--boot-mode=ram --no-reset-registers"
next_test
run_repeated_test "RAM reset-registers" "$RAM_FILE" "--boot-mode=ram --reset-registers"
next_test
run_repeated_test "EEPROM driver no-reset-registers" "$EEPROM_FILE" "--boot-mode=eeprom --no-reset-registers"
next_test
run_repeated_test "EEPROM driver reset-registers" "$EEPROM_FILE" "--boot-mode=eeprom --reset-registers"
next_test
run_repeated_test "EEPROM no-driver no-reset-registers" "$EEPROM_FILE" "--boot-mode=eeprom --no-driver --no-reset-registers"
next_test
run_repeated_test "EEPROM no-driver reset-registers" "$EEPROM_FILE" "--boot-mode=eeprom --no-driver --reset-registers"
next_test
run_repeated_test "FLASH driver no-reset-registers" "$FLASH_FILE" "--boot-mode=spifi --no-reset-registers"
next_test
run_repeated_test "FLASH driver reset-registers" "$FLASH_FILE" "--boot-mode=spifi --reset-registers"
next_test
run_repeated_test "FLASH Quad SPI no-reset-registers" "$FLASH_FILE" "--boot-mode=spifi --use-quad-spi --no-reset-registers"
next_test
run_repeated_test "FLASH Quad SPI reset-registers" "$FLASH_FILE" "--boot-mode=spifi --use-quad-spi --reset-registers"
next_test
run_repeated_test "FLASH no-driver no-reset-registers" "$FLASH_FILE" "--boot-mode=spifi --no-driver --no-reset-registers"
next_test
run_repeated_test "FLASH no-driver reset-registers" "$FLASH_FILE" "--boot-mode=spifi --no-driver --reset-registers"
next_test
run_repeated_test "FLASH Quad SPI no-driver no-reset-registers" "$FLASH_FILE" "--boot-mode=spifi --use-quad-spi --no-driver --no-reset-registers"
next_test
run_repeated_test "FLASH Quad SPI no-driver reset-registers" "$FLASH_FILE" "--boot-mode=spifi --use-quad-spi --no-driver --reset-registers"

echo
echo "=========================================================="
echo "RESULT"
echo "=========================================================="
echo "Total:  $TOTAL_TESTS"
echo "Expected: $EXPECTED_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $FAILED_TESTS"

echo
echo "=========================================================="
echo "SPEED STATISTICS (successful runs only)"
echo "=========================================================="
cat "$SUMMARY_FILE"

if [[ "$TOTAL_TESTS" != "$EXPECTED_TESTS" ]]; then
    echo
    echo "[ERROR] Unexpected number of checks."
    echo "[ERROR] Expected $EXPECTED_TESTS checks: final RAM/EEPROM/FLASH parameter matrix."
    exit 1
fi

if [[ "$FAILED_TESTS" != "0" ]]; then
    echo
    echo "Failed tests:$FAILED_LIST"
    echo
    echo "[ERROR] One or more firmware verification tests failed."
    exit 1
fi

echo
echo "[OK] All firmware verification tests completed successfully."
exit 0
