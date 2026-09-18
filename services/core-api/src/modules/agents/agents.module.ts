import { Module } from '@nestjs/common';
import { AgentsService } from './agents.service';
import { AdminAgentsController, AgentController } from './agents.controller';
import { LedgerModule } from '../ledger/ledger.module';

@Module({
  imports: [LedgerModule],
  controllers: [AdminAgentsController, AgentController],
  providers: [AgentsService],
  exports: [AgentsService],
})
export class AgentsModule {}
