export interface KycStoragePort {
  saveFile(file: Buffer, filename: string): Promise<string>;
  getFile(filepath: string): Promise<Buffer>;
}

export class LocalFileSystemStorage implements KycStoragePort {
  private baseDir: string;

  constructor(baseDir: string = './.data/kyc') {
    this.baseDir = baseDir;
  }

  async saveFile(file: Buffer, filename: string): Promise<string> {
    const fs = await import('fs/promises');
    const path = await import('path');
    
    // Ensure directory exists
    await fs.mkdir(this.baseDir, { recursive: true });
    
    // Generate unique filename
    const timestamp = Date.now();
    const safeName = filename.replace(/[^a-zA-Z0-9.-]/g, '_');
    const filepath = path.join(this.baseDir, `${timestamp}-${safeName}`);
    
    await fs.writeFile(filepath, file);
    
    return filepath;
  }

  async getFile(filepath: string): Promise<Buffer> {
    const fs = await import('fs/promises');
    return await fs.readFile(filepath);
  }
}
