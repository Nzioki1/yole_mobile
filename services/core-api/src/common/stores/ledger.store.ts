import { Injectable } from '@nestjs/common';
import { JournalEntry, Posting, IdempotencyRecord, JournalStatus, CurrencyCode } from './types';

export interface LedgerStore {
  // Idempotency
  findIdempotencyRecord(key: string): Promise<IdempotencyRecord | null>;
  createIdempotencyRecord(data: Omit<IdempotencyRecord, 'createdAt'>): Promise<IdempotencyRecord>;
  
  // Journals
  createJournal(data: Omit<JournalEntry, 'id' | 'createdAt'>): Promise<JournalEntry>;
  findJournalByIdempotencyKey(key: string): Promise<JournalEntry | null>;
  findJournalByReference(ref: string): Promise<JournalEntry | null>;
  
  // Postings
  createPosting(data: Omit<Posting, 'id'>): Promise<Posting>;
  findPostingsByJournalId(journalId: string): Promise<Posting[]>;
}

@Injectable()
export class InMemoryLedgerStore implements LedgerStore {
  private idempotencyRecords = new Map<string, IdempotencyRecord>();
  private journals = new Map<string, JournalEntry>();
  private postings = new Map<string, Posting>();
  private journalIdCounter = 1;
  private postingIdCounter = 1;
  private idempotencyKeyIndex = new Map<string, string>(); // key -> journalId
  private referenceIndex = new Map<string, string>(); // reference -> journalId

  async findIdempotencyRecord(key: string): Promise<IdempotencyRecord | null> {
    return this.idempotencyRecords.get(key) || null;
  }

  async createIdempotencyRecord(
    data: Omit<IdempotencyRecord, 'createdAt'>,
  ): Promise<IdempotencyRecord> {
    const record: IdempotencyRecord = {
      ...data,
      createdAt: new Date(),
    };
    this.idempotencyRecords.set(record.key, record);
    return record;
  }

  async createJournal(
    data: Omit<JournalEntry, 'id' | 'createdAt'>,
  ): Promise<JournalEntry> {
    // Check for duplicate keys
    if (this.idempotencyKeyIndex.has(data.idempotencyKey)) {
      throw new Error(`Duplicate idempotencyKey: ${data.idempotencyKey}`);
    }
    if (this.referenceIndex.has(data.yoleReference)) {
      throw new Error(`Duplicate yoleReference: ${data.yoleReference}`);
    }

    const journal: JournalEntry = {
      ...data,
      id: `journal_${this.journalIdCounter++}`,
      createdAt: new Date(),
    };

    this.journals.set(journal.id, journal);
    this.idempotencyKeyIndex.set(journal.idempotencyKey, journal.id);
    this.referenceIndex.set(journal.yoleReference, journal.id);

    return journal;
  }

  async findJournalByIdempotencyKey(key: string): Promise<JournalEntry | null> {
    const id = this.idempotencyKeyIndex.get(key);
    return id ? this.journals.get(id) || null : null;
  }

  async findJournalByReference(ref: string): Promise<JournalEntry | null> {
    const id = this.referenceIndex.get(ref);
    return id ? this.journals.get(id) || null : null;
  }

  async listJournals(): Promise<JournalEntry[]> {
    return Array.from(this.journals.values());
  }

  async createPosting(data: Omit<Posting, 'id'>): Promise<Posting> {
    const posting: Posting = {
      ...data,
      id: `posting_${this.postingIdCounter++}`,
    };
    this.postings.set(posting.id, posting);
    return posting;
  }

  async findPostingsByJournalId(journalId: string): Promise<Posting[]> {
    return Array.from(this.postings.values()).filter(
      (p) => p.journalId === journalId,
    );
  }

  // Test helper
  clear() {
    this.idempotencyRecords.clear();
    this.journals.clear();
    this.postings.clear();
    this.idempotencyKeyIndex.clear();
    this.referenceIndex.clear();
  }
}
