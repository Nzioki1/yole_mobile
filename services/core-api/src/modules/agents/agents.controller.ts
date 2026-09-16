import { Controller, Post, Get, Body, Param, UseGuards, Req, Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { AgentsService } from './agents.service';

// Simple admin API key guard (Phase 1 mock)
@Injectable()
class AdminApiKeyGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const apiKey = request.headers['x-admin-api-key'];
    return apiKey === 'dev-admin-key';
  }
}

// Admin endpoints for agent management
@Controller('v1/admin/agents')
@UseGuards(AdminApiKeyGuard)
export class AdminAgentsController {
  constructor(private agentsService: AgentsService) {}

  @Post()
  async enrollAgent(
    @Body()
    body: {
      firstName: string;
      lastName: string;
      phoneE164: string;
      email?: string;
    },
  ) {
    return this.agentsService.enrollAgent(body);
  }

  @Get()
  async listAgents() {
    return this.agentsService.listAgents();
  }

  @Get(':id')
  async getAgent(@Param('id') id: string) {
    return this.agentsService.getAgent(id);
  }
}

// Agent endpoints (agents acting on behalf of customers)
// For now, use a simple header-based auth (X-Agent-Id)
// In production, this would use proper agent JWT or API keys
@Controller('v1/agent')
export class AgentController {
  constructor(private agentsService: AgentsService) {}

  @Post('customers')
  async enrollCustomer(
    @Req() req: any,
    @Body()
    body: {
      firstName: string;
      lastName: string;
      phoneE164?: string;
      email?: string;
      password: string;
    },
  ) {
    const agentId = req.headers['x-agent-id'];
    if (!agentId) {
      throw new Error('X-Agent-Id header required');
    }
    return this.agentsService.enrollCustomer(agentId, body);
  }

  @Post('cash-in')
  async cashIn(
    @Req() req: any,
    @Body()
    body: {
      customerId: string;
      amountMinor: string;
      currency: string;
    },
  ) {
    const agentId = req.headers['x-agent-id'];
    if (!agentId) {
      throw new Error('X-Agent-Id header required');
    }
    return this.agentsService.cashIn(agentId, {
      customerId: body.customerId,
      amountMinor: BigInt(body.amountMinor),
      currency: body.currency as any,
    });
  }

  @Post('cash-out')
  async cashOut(
    @Req() req: any,
    @Body()
    body: {
      customerId: string;
      amountMinor: string;
      currency: string;
    },
  ) {
    const agentId = req.headers['x-agent-id'];
    if (!agentId) {
      throw new Error('X-Agent-Id header required');
    }
    return this.agentsService.cashOut(agentId, {
      customerId: body.customerId,
      amountMinor: BigInt(body.amountMinor),
      currency: body.currency as any,
    });
  }
}
