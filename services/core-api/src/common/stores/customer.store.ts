import { Injectable } from '@nestjs/common';
import { Customer } from './types';

export interface CustomerStore {
  create(data: Omit<Customer, 'id' | 'createdAt'>): Promise<Customer>;
  findById(id: string): Promise<Customer | null>;
  findByEmail(email: string): Promise<Customer | null>;
  findByPhone(phoneE164: string): Promise<Customer | null>;
}

@Injectable()
export class InMemoryCustomerStore implements CustomerStore {
  private customers = new Map<string, Customer>();
  private emailIndex = new Map<string, string>(); // email -> id
  private phoneIndex = new Map<string, string>(); // phone -> id
  private idCounter = 1;

  async create(data: Omit<Customer, 'id' | 'createdAt'>): Promise<Customer> {
    const customer: Customer = {
      ...data,
      id: `cust_${this.idCounter++}`,
      createdAt: new Date(),
    };

    this.customers.set(customer.id, customer);
    
    if (customer.email) {
      this.emailIndex.set(customer.email, customer.id);
    }
    if (customer.phoneE164) {
      this.phoneIndex.set(customer.phoneE164, customer.id);
    }

    return customer;
  }

  async findById(id: string): Promise<Customer | null> {
    return this.customers.get(id) || null;
  }

  async findByEmail(email: string): Promise<Customer | null> {
    const id = this.emailIndex.get(email);
    return id ? this.customers.get(id) || null : null;
  }

  async findByPhone(phoneE164: string): Promise<Customer | null> {
    const id = this.phoneIndex.get(phoneE164);
    return id ? this.customers.get(id) || null : null;
  }

  // Test helper
  clear() {
    this.customers.clear();
    this.emailIndex.clear();
    this.phoneIndex.clear();
  }
}
