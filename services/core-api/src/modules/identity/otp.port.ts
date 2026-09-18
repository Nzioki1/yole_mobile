export interface OtpSender {
  send(phoneE164: string, code: string): Promise<void>;
}

export class ConsoleOtpSender implements OtpSender {
  async send(phoneE164: string, code: string): Promise<void> {
    console.log(`[OTP] Sending code to ${phoneE164}: ${code}`);
    // In production, this would integrate with SMS provider
  }
}
