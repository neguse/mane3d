#!/usr/bin/env python3
"""Extract WAV files from hakotai_c82.exe (cdbpp embedded data)"""

import os
import struct

def extract_wavs(exe_path, output_dir):
    """Extract WAV files by searching for RIFF headers"""
    with open(exe_path, 'rb') as f:
        data = f.read()

    os.makedirs(output_dir, exist_ok=True)

    # Search for RIFF....WAVE patterns
    pos = 0
    wav_count = 0
    while True:
        # Find RIFF header
        riff_pos = data.find(b'RIFF', pos)
        if riff_pos == -1:
            break

        # Check if it's a WAVE file
        if data[riff_pos+8:riff_pos+12] == b'WAVE':
            # Get file size from RIFF header
            chunk_size = struct.unpack('<I', data[riff_pos+4:riff_pos+8])[0]
            wav_size = chunk_size + 8  # RIFF header is 8 bytes

            # Extract WAV data
            wav_data = data[riff_pos:riff_pos+wav_size]

            # Try to find filename (cdbpp stores filename before data)
            # Search backwards for a null-terminated string
            filename = None
            search_start = max(0, riff_pos - 100)
            for i in range(riff_pos - 1, search_start, -1):
                if data[i] == 0:
                    # Found null terminator, extract string
                    name_start = i + 1
                    name_bytes = data[name_start:riff_pos]
                    try:
                        name = name_bytes.decode('ascii').strip('\x00')
                        if name.endswith('.wav') and len(name) < 50:
                            filename = name
                            break
                    except:
                        pass

            if not filename:
                filename = f"extracted_{wav_count:02d}.wav"

            output_path = os.path.join(output_dir, filename)
            with open(output_path, 'wb') as out:
                out.write(wav_data)

            print(f"Extracted: {filename} ({wav_size} bytes)")
            wav_count += 1
            pos = riff_pos + wav_size
        else:
            pos = riff_pos + 4

    print(f"\nTotal: {wav_count} WAV files extracted")

if __name__ == '__main__':
    exe_path = r"D:\github.com\neguse\mane3d\examples\hakonotaiatari\hakotai_c82.exe"
    output_dir = r"D:\github.com\neguse\mane3d\deps\hakonotaiatari\ftm"
    extract_wavs(exe_path, output_dir)
