/**
 * Fixed-window limiter keyed by a hash of the client address.
 *
 * The raw address is never stored: it's hashed with a per-process random
 * salt that dies with the process, so the limiter can count without
 * keeping anything that identifies a visitor.
 */
import { createHash, randomBytes } from 'node:crypto';

const SALT = randomBytes(16);

export class RateLimiter {
  constructor({ limit = 10, windowMs = 60_000 } = {}) {
    this.limit = limit;
    this.windowMs = windowMs;
    this.buckets = new Map();
  }

  #key(address) {
    return createHash('sha256')
      .update(SALT)
      .update(address ?? 'unknown')
      .digest('hex');
  }

  /** True when the request is allowed. */
  allow(address, now = Date.now()) {
    const key = this.#key(address);
    const bucket = this.buckets.get(key);
    if (!bucket || now - bucket.start >= this.windowMs) {
      this.buckets.set(key, { start: now, count: 1 });
      this.#sweep(now);
      return true;
    }
    if (bucket.count >= this.limit) return false;
    bucket.count += 1;
    return true;
  }

  /** Drops expired buckets so memory can't grow without bound. */
  #sweep(now) {
    if (this.buckets.size < 1000) return;
    for (const [key, bucket] of this.buckets) {
      if (now - bucket.start >= this.windowMs) this.buckets.delete(key);
    }
  }
}
