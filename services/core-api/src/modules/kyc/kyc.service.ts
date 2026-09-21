import { Injectable, NotFoundException } from '@nestjs/common';
import { InMemoryKycStore } from '../../common/stores/kyc.store';
import { KycStoragePort } from './kyc-storage.port';
import { ScreeningPort } from './screening.port';

export interface SubmitKycInput {
  customerId: string;
  idNumber: string;
  phoneE164: string;
  idDocument: Buffer;
  idDocumentFilename: string;
  selfie: Buffer;
  selfieFilename: string;
}

@Injectable()
export class KycService {
  constructor(
    private kycStore: InMemoryKycStore,
  ) {
    // Use concrete implementations for Phase 1
    this.storage = new (require('./kyc-storage.port').LocalFileSystemStorage)(
      './services/core-api/.data/kyc',
    );
    this.screening = new (require('./screening.port').StubScreeningService)();
  }

  private storage: KycStoragePort;
  private screening: ScreeningPort;

  async submitKyc(input: SubmitKycInput) {
    // Save files
    const idDocumentPath = await this.storage.saveFile(
      input.idDocument,
      input.idDocumentFilename,
    );
    const selfiePath = await this.storage.saveFile(
      input.selfie,
      input.selfieFilename,
    );

    // Screen person (stub for Phase 1)
    const screeningResult = await this.screening.screenPerson({
      fullName: `Customer ${input.customerId}`, // In real app, get from customer record
      idNumber: input.idNumber,
    });

    // Create submission (defaults to PENDING_REVIEW)
    const submission = await this.kycStore.create({
      customerId: input.customerId,
      idNumber: input.idNumber,
      phoneE164: input.phoneE164,
      idDocumentPath,
      selfiePath,
      status: 'PENDING_REVIEW',
      screeningHit: screeningResult.hit,
      screeningRef: screeningResult.providerRef,
      decision: null,
      decisionReason: null,
      decidedAt: null,
    });

    return {
      submissionId: submission.id,
      status: submission.status,
    };
  }

  async getPendingSubmissions() {
    return await this.kycStore.findByStatus('PENDING_REVIEW');
  }

  async makeDecision(submissionId: string, decision: 'APPROVE' | 'REJECT', reason?: string) {
    const submission = await this.kycStore.findById(submissionId);
    if (!submission) {
      throw new NotFoundException(`KYC submission ${submissionId} not found`);
    }

    const newStatus = decision === 'APPROVE' ? 'APPROVED' : 'REJECTED';
    
    await this.kycStore.update(submissionId, {
      status: newStatus,
      decision,
      decisionReason: reason || null,
      decidedAt: new Date(),
    });

    return { submissionId, status: newStatus };
  }
}
