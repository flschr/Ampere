#!/usr/bin/env python3
import plistlib
import struct
import sys


def read_sized_int(blob, offset, size):
    return int.from_bytes(blob[offset:offset + size], "big")


def bplist_spans(store_data):
    start = 0
    while True:
        start = store_data.find(b"bplist00", start)
        if start == -1:
            break

        for end in range(start + 40, len(store_data) + 1):
            try:
                plistlib.loads(store_data[start:end])
            except Exception:
                continue
            yield start, end
            break

        start += 8


def object_offsets(blob):
    if len(blob) < 40 or blob[:8] != b"bplist00":
        raise ValueError("not a binary plist")

    trailer = blob[-32:]
    offset_size = trailer[6]
    ref_size = trailer[7]
    object_count = struct.unpack(">Q", trailer[8:16])[0]
    top_object = struct.unpack(">Q", trailer[16:24])[0]
    offset_table = struct.unpack(">Q", trailer[24:32])[0]
    offsets = [
        read_sized_int(blob, offset_table + index * offset_size, offset_size)
        for index in range(object_count)
    ]
    return offsets, ref_size, top_object


def read_length(blob, offset, marker_low_nibble):
    if marker_low_nibble != 0xF:
        return marker_low_nibble, offset + 1

    int_offset = offset + 1
    marker = blob[int_offset]
    if marker >> 4 != 0x1:
        raise ValueError("expected integer length object")

    int_size = 1 << (marker & 0xF)
    value_offset = int_offset + 1
    return read_sized_int(blob, value_offset, int_size), value_offset + int_size


def read_key(blob, offset):
    marker = blob[offset]
    kind = marker >> 4
    length, value_offset = read_length(blob, offset, marker & 0xF)

    if kind == 0x5:
        return blob[value_offset:value_offset + length].decode("ascii")
    if kind == 0x6:
        byte_count = length * 2
        return blob[value_offset:value_offset + byte_count].decode("utf-16be")

    return None


def patch_show_tab_view(blob):
    offsets, ref_size, top_object = object_offsets(blob)
    dictionary_offset = offsets[top_object]
    marker = blob[dictionary_offset]
    if marker >> 4 != 0xD:
        return False

    entry_count, refs_offset = read_length(blob, dictionary_offset, marker & 0xF)
    key_refs_offset = refs_offset
    value_refs_offset = key_refs_offset + entry_count * ref_size

    for index in range(entry_count):
        key_ref = read_sized_int(blob, key_refs_offset + index * ref_size, ref_size)
        key = read_key(blob, offsets[key_ref])
        if key != "ShowTabView":
            continue

        value_ref = read_sized_int(
            blob,
            value_refs_offset + index * ref_size,
            ref_size,
        )
        value_offset = offsets[value_ref]

        if blob[value_offset] == 0x08:
            return True
        if blob[value_offset] != 0x09:
            raise ValueError("ShowTabView is not a boolean true value")

        blob[value_offset] = 0x08
        return True

    return False


def patch_file(path):
    with open(path, "rb") as file:
        data = bytearray(file.read())

    for start, end in bplist_spans(data):
        candidate = data[start:end]
        try:
            plist = plistlib.loads(candidate)
        except Exception:
            continue

        if not isinstance(plist, dict) or "ShowTabView" not in plist:
            continue

        if patch_show_tab_view(candidate):
            data[start:end] = candidate
            with open(path, "wb") as file:
                file.write(data)
            return

    raise ValueError("ShowTabView metadata was not found in .DS_Store")


def main():
    if len(sys.argv) != 2:
        raise SystemExit("Usage: patch-ds-store-tab-view.py /path/to/.DS_Store")

    patch_file(sys.argv[1])


if __name__ == "__main__":
    main()
