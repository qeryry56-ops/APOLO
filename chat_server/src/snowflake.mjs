/**
 * 64-bit time-ordered Snowflake ID generator (ByteByteGo Message ID Generator).
 *
 * Layout (63 positive bits):
 *  - 41 bits: milliseconds since custom epoch (2025-01-01T00:00:00Z)
 *  -  5 bits: datacenter ID (0..31)
 *  -  5 bits: worker ID (0..31)
 *  - 12 bits: per-millisecond sequence (0..4095)
 */
export class SnowflakeIdGenerator {
  static EPOCH_MS = 1735689600000n;
  static DATACENTER_BITS = 5n;
  static WORKER_BITS = 5n;
  static SEQUENCE_BITS = 12n;

  static MAX_DATACENTER_ID = (1n << 5n) - 1n;
  static MAX_WORKER_ID = (1n << 5n) - 1n;
  static SEQUENCE_MASK = (1n << 12n) - 1n;

  constructor({ datacenterId = 1, workerId = 1 } = {}) {
    this.datacenterId = BigInt(datacenterId) & SnowflakeIdGenerator.MAX_DATACENTER_ID;
    this.workerId = BigInt(workerId) & SnowflakeIdGenerator.MAX_WORKER_ID;
    this.lastTimestamp = -1n;
    this.sequence = 0n;
  }

  nextId() {
    let timestamp = BigInt(Date.now());

    if (timestamp < this.lastTimestamp) {
      // Guard against minor NTP clock drift by clamping to lastTimestamp
      timestamp = this.lastTimestamp;
    }

    if (timestamp === this.lastTimestamp) {
      this.sequence = (this.sequence + 1n) & SnowflakeIdGenerator.SEQUENCE_MASK;
      if (this.sequence === 0n) {
        while (timestamp <= this.lastTimestamp) {
          timestamp = BigInt(Date.now());
        }
      }
    } else {
      this.sequence = 0n;
    }

    this.lastTimestamp = timestamp;

    const shiftTs =
      SnowflakeIdGenerator.DATACENTER_BITS +
      SnowflakeIdGenerator.WORKER_BITS +
      SnowflakeIdGenerator.SEQUENCE_BITS;
    const shiftDc = SnowflakeIdGenerator.WORKER_BITS + SnowflakeIdGenerator.SEQUENCE_BITS;
    const shiftWk = SnowflakeIdGenerator.SEQUENCE_BITS;

    return (
      ((timestamp - SnowflakeIdGenerator.EPOCH_MS) << shiftTs) |
      (this.datacenterId << shiftDc) |
      (this.workerId << shiftWk) |
      this.sequence
    ).toString();
  }
}
