import { Injectable, Inject } from '@nestjs/common';
import * as crypto from 'crypto';
import { OtpSender } from './otp.port';

/**
 * OTP Service for phone verification
 * 
 * Storage: In-memory Map with TTL for Phase 1 (no Redis required)
 * Production: Should use Redis with TTL
 */
@Injectable()
export class OtpService {
  // In-memory storage: phoneE164 -> { hashedCode: string, expiresAt: number }
  private otpStore = new Map<string, { hashedCode: string; expiresAt: number }>();
  
  constructor(@Inject('OTP_SENDER') private otpSender: OtpSender) {
    // Cleanup expired OTPs every minute
    setInterval(() => this.cleanupExpired(), 60000);
  }

  /**
   * Generate and send OTP code to phone number
   */
  async requestOtp(phoneE164: string): Promise<void> {
    // Generate 6-digit code
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Hash code for storage (same as password hashing)
    const hashedCode = crypto
      .createHash('sha256')
      .update(code)
      .digest('hex');
    
    // Store with 5-minute TTL
    const expiresAt = Date.now() + 5 * 60 * 1000;
    this.otpStore.set(phoneE164, { hashedCode, expiresAt });
    
    // Send via configured sender
    await this.otpSender.send(phoneE164, code);
  }

  /**
   * Verify OTP code for phone number
   */
  async verifyOtp(phoneE164: string, code: string): Promise<boolean> {
    const stored = this.otpStore.get(phoneE164);
    
    if (!stored) {
      return false; // No OTP requested
    }
    
    if (Date.now() > stored.expiresAt) {
      this.otpStore.delete(phoneE164);
      return false; // Expired
    }
    
    const hashedInput = crypto
      .createHash('sha256')
      .update(code)
      .digest('hex');
    
    const isValid = hashedInput === stored.hashedCode;
    
    if (isValid) {
      // Remove after successful verification
      this.otpStore.delete(phoneE164);
    }
    
    return isValid;
  }

  private cleanupExpired() {
    const now = Date.now();
    for (const [phone, data] of this.otpStore.entries()) {
      if (now > data.expiresAt) {
        this.otpStore.delete(phone);
      }
    }
  }
}
