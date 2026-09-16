import { Injectable } from '@nestjs/common';
import { KycSubmission, KycStatus } from './types';

export interface KycStore {
  create(data: Omit<KycSubmission, 'id' | 'createdAt' | 'updatedAt'>): Promise<KycSubmission>;
  findById(id: string): Promise<KycSubmission | null>;
  findByStatus(status: KycStatus): Promise<KycSubmission[]>;
  update(id: string, data: Partial<KycSubmission>): Promise<KycSubmission>;
}

@Injectable()
export class InMemoryKycStore implements KycStore {
  private submissions = new Map<string, KycSubmission>();
  private idCounter = 1;

  async create(
    data: Omit<KycSubmission, 'id' | 'createdAt' | 'updatedAt'>,
  ): Promise<KycSubmission> {
    const submission: KycSubmission = {
      ...data,
      id: `kyc_${this.idCounter++}`,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    this.submissions.set(submission.id, submission);
    return submission;
  }

  async findById(id: string): Promise<KycSubmission | null> {
    return this.submissions.get(id) || null;
  }

  async findByStatus(status: KycStatus): Promise<KycSubmission[]> {
    return Array.from(this.submissions.values()).filter(
      (s) => s.status === status,
    );
  }

  async update(
    id: string,
    data: Partial<KycSubmission>,
  ): Promise<KycSubmission> {
    const submission = this.submissions.get(id);
    if (!submission) {
      throw new Error(`KYC submission ${id} not found`);
    }
    const updated = {
      ...submission,
      ...data,
      updatedAt: new Date(),
    };
    this.submissions.set(id, updated);
    return updated;
  }

  // Test helper
  clear() {
    this.submissions.clear();
  }
}
