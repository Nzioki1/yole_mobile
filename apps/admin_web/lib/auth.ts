import { jwtDecode } from 'jwt-decode';

const TOKEN_KEY = 'admin_access_token';

export enum StaffRole {
  ADMIN = 'ADMIN',
  OPS = 'OPS',
  SUPPORT = 'SUPPORT',
  FINANCE = 'FINANCE',
}

export interface StaffUser {
  id: string;
  email: string;
  role: StaffRole;
  firstName?: string;
  lastName?: string;
}

export interface JWTPayload {
  sub: string;
  email: string;
  role: StaffRole;
  exp: number;
}

export const authService = {
  getToken(): string | null {
    if (typeof window === 'undefined') return null;
    return localStorage.getItem(TOKEN_KEY);
  },

  setToken(token: string): void {
    if (typeof window === 'undefined') return;
    localStorage.setItem(TOKEN_KEY, token);
  },

  removeToken(): void {
    if (typeof window === 'undefined') return;
    localStorage.removeItem(TOKEN_KEY);
  },

  decodeToken(token?: string): JWTPayload | null {
    const t = token || this.getToken();
    if (!t) return null;
    
    try {
      return jwtDecode<JWTPayload>(t);
    } catch (error) {
      return null;
    }
  },

  isTokenValid(token?: string): boolean {
    const payload = this.decodeToken(token);
    if (!payload) return false;
    
    const now = Date.now() / 1000;
    return payload.exp > now;
  },

  getCurrentUser(): StaffUser | null {
    const token = this.getToken();
    if (!token || !this.isTokenValid(token)) {
      return null;
    }

    const payload = this.decodeToken(token);
    if (!payload) return null;

    return {
      id: payload.sub,
      email: payload.email,
      role: payload.role,
    };
  },

  isAuthenticated(): boolean {
    return this.isTokenValid();
  },

  logout(): void {
    this.removeToken();
  },
};
