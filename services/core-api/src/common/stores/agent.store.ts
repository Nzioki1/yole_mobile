import { Injectable } from '@nestjs/common';

export interface Agent {
  id: string;
  firstName: string;
  lastName: string;
  phoneE164: string;
  email: string | null;
  status: string;
  floatWalletId: string;
  createdAt: Date;
}

export interface AgentStore {
  create(data: Omit<Agent, 'id' | 'createdAt'>): Promise<Agent>;
  findById(id: string): Promise<Agent | null>;
  findByPhone(phoneE164: string): Promise<Agent | null>;
  list(): Promise<Agent[]>;
}

@Injectable()
export class InMemoryAgentStore implements AgentStore {
  private agents = new Map<string, Agent>();
  private idCounter = 1;

  async create(data: Omit<Agent, 'id' | 'createdAt'>): Promise<Agent> {
    const agent: Agent = {
      ...data,
      id: `agent_${this.idCounter++}`,
      createdAt: new Date(),
    };
    this.agents.set(agent.id, agent);
    return agent;
  }

  async findById(id: string): Promise<Agent | null> {
    return this.agents.get(id) || null;
  }

  async findByPhone(phoneE164: string): Promise<Agent | null> {
    return Array.from(this.agents.values()).find((a) => a.phoneE164 === phoneE164) || null;
  }

  async list(): Promise<Agent[]> {
    return Array.from(this.agents.values());
  }

  clear(): void {
    this.agents.clear();
    this.idCounter = 1;
  }
}
