# LocalSend AirGap — Benchmarks

## Test Setup

- **Sender:** Linux desktop
- **Receiver:** Pixel 10 
- **File size:** Approximately 67 KB
- **Chunk size:** 1,000 bytes
- **Trials:** 3 per configuration

Throughput was measured from the first successfully received QR frame until file reconstruction and SHA-256 verification.

## Results

Throughput in bytes/second (B/s).

| Frame interval | Trial 1 | Trial 2 | Trial 3 | Average |
|---|---:|---:|---:|---:|
| 250 ms | 1,854 | 1,323 | 1,921 | 1,667 |
| **300 ms** | **3,314** | **1,911** | **3,303** | **2,833** |
| 400 ms | 1,814 | 1,958 | 1,750 | 1,817 |

## Findings

- **300 ms achieved the highest average throughput** at approximately 2.83 KB/s.
- 250 ms performed worse, potentially because the camera missed more frames.
- 400 ms provided more consistent results but lower throughput.
- Missed frames were recovered during subsequent QR animation cycles.

## Limitations

Results are preliminary, with three trials per setting. Timing excludes the first frame's transmission and the file-saving dialog. 

## Conclusion

The current configuration is **1,000-byte chunks at 300 ms per frame**.

AirGap was also successfully tested with network connections disabled on both devices, with SHA-256 verification confirming file integrity.
