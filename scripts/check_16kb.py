"""APK·AAB 안의 네이티브 라이브러리(.so)가 16KB 페이지 기기에서 돌 수 있는지 검사한다.

Android 15+ 16KB 페이지 기기는 ELF LOAD 세그먼트가 16KB(2**14) 이상으로 정렬돼야 한다.
Play는 2027-02-01부터 정렬되지 않은 업데이트를 막는다(LAUNCH_AUDIT P0-11).

사용: python scripts/check_16kb.py build/app/outputs/bundle/release/app-release.aab
     python scripts/check_16kb.py build/app/outputs/flutter-apk/app-release.apk
종료 코드: 모두 통과 0, 하나라도 미달 1.
"""
import struct
import sys
import zipfile

PAGE_16K = 1 << 14
PT_LOAD = 1


def load_alignments(data: bytes):
    """ELF 프로그램 헤더에서 LOAD 세그먼트의 p_align 목록을 돌려준다."""
    if data[:4] != b'\x7fELF':
        raise ValueError('ELF 아님')
    is64 = data[4] == 2
    endian = '<' if data[5] == 1 else '>'
    if is64:
        phoff, = struct.unpack_from(endian + 'Q', data, 0x20)
        phentsize, phnum = struct.unpack_from(endian + 'HH', data, 0x36)
    else:
        phoff, = struct.unpack_from(endian + 'I', data, 0x1C)
        phentsize, phnum = struct.unpack_from(endian + 'HH', data, 0x2A)
    aligns = []
    for i in range(phnum):
        off = phoff + i * phentsize
        p_type, = struct.unpack_from(endian + 'I', data, off)
        if p_type != PT_LOAD:
            continue
        if is64:
            p_align, = struct.unpack_from(endian + 'Q', data, off + 0x30)
        else:
            p_align, = struct.unpack_from(endian + 'I', data, off + 0x1C)
        aligns.append(p_align)
    return aligns


def main(path: str) -> int:
    failures = 0
    checked = 0
    with zipfile.ZipFile(path) as archive, open(path, 'rb') as raw:
        for info in archive.infolist():
            if not info.filename.endswith('.so'):
                continue
            checked += 1
            aligns = load_alignments(archive.read(info))
            worst = min(aligns) if aligns else 0
            ok = worst >= PAGE_16K
            # APK에 압축 없이 담긴 .so는 zip 안의 위치도 16KB 정렬이어야 한다(AAB는 Play가 다시 묶는다).
            note = ''
            if path.endswith('.apk') and info.compress_type == zipfile.ZIP_STORED:
                # 데이터 시작은 로컬 헤더의 이름·extra 길이로 구한다. zipalign은 로컬 헤더 extra를
                # 채워 정렬하므로 중앙 디렉터리의 info.extra 길이와 다르다.
                raw.seek(info.header_offset)
                name_len, extra_len = struct.unpack_from('<HH', raw.read(30), 26)
                data_offset = info.header_offset + 30 + name_len + extra_len
                if data_offset % PAGE_16K:
                    ok = False
                    note = f' (zip 위치 {data_offset}가 16KB 정렬 아님)'
            print(f"{'OK  ' if ok else 'FAIL'} 2**{worst.bit_length() - 1 if worst else 0}  {info.filename}{note}")
            failures += 0 if ok else 1
    print(f'검사 {checked}개, 미달 {failures}개')
    return 1 if failures or checked == 0 else 0


if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    sys.exit(main(sys.argv[1]))
