export interface ScreeningPort {
  screenPerson(input: {
    fullName: string;
    idNumber: string;
  }): Promise<{ hit: boolean; providerRef: string }>;
}

export class StubScreeningService implements ScreeningPort {
  async screenPerson(input: {
    fullName: string;
    idNumber: string;
  }): Promise<{ hit: boolean; providerRef: string }> {
    // Stub: always returns no hit for Phase 1
    return {
      hit: false,
      providerRef: `STUB-${Date.now()}`,
    };
  }
}
