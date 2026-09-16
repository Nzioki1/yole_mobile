import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  UseGuards,
  Request,
  Query,
  UseInterceptors,
  UploadedFiles,
  BadRequestException,
} from '@nestjs/common';
import { FileFieldsInterceptor } from '@nestjs/platform-express';
import { JwtAuthGuard } from '../identity/jwt-auth.guard';
import { KycService } from './kyc.service';

@Controller('v1/kyc')
export class KycController {
  constructor(private kycService: KycService) {}

  @Post('submissions')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(
    FileFieldsInterceptor([
      { name: 'idDocument', maxCount: 1 },
      { name: 'selfie', maxCount: 1 },
    ]),
  )
  async submit(
    @Request() req: any,
    @UploadedFiles() files: { idDocument?: any[]; selfie?: any[] },
    @Body() body: { idNumber: string; phoneE164: string },
  ) {
    if (!files.idDocument || !files.selfie) {
      throw new BadRequestException('idDocument and selfie files are required');
    }

    const customerId = req.user.customerId;

    return await this.kycService.submitKyc({
      customerId,
      idNumber: body.idNumber,
      phoneE164: body.phoneE164,
      idDocument: files.idDocument[0].buffer,
      idDocumentFilename: files.idDocument[0].originalname,
      selfie: files.selfie[0].buffer,
      selfieFilename: files.selfie[0].originalname,
    });
  }
}

// Simple admin API key guard for Phase 1
class AdminApiKeyGuard {
  canActivate(context: any): boolean {
    const req = context.switchToHttp().getRequest();
    const apiKey = req.headers['x-admin-api-key'];
    return apiKey === (process.env.ADMIN_API_KEY || 'dev-admin-key');
  }
}

@Controller('v1/admin/kyc')
export class AdminKycController {
  constructor(private kycService: KycService) {}

  @Get('submissions')
  @UseGuards(AdminApiKeyGuard)
  async listSubmissions(@Query('status') status?: string) {
    if (status === 'PENDING_REVIEW') {
      return await this.kycService.getPendingSubmissions();
    }
    return [];
  }

  @Post('submissions/:id/decision')
  @UseGuards(AdminApiKeyGuard)
  async makeDecision(
    @Param('id') id: string,
    @Body() body: { decision: 'APPROVE' | 'REJECT'; reason?: string },
  ) {
    return await this.kycService.makeDecision(id, body.decision, body.reason);
  }
}
