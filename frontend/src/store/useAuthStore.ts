import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { Guest, GuestAccount } from '@/types';

interface AuthState {
  token: string | null;
  guest: Guest | null;
  account: GuestAccount | null;
  setAuth: (token: string, guest: Guest, account: GuestAccount) => void;
  clearAuth: () => void;
  isAuthenticated: () => boolean;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      token: null,
      guest: null,
      account: null,
      setAuth: (token, guest, account) => {
        if (typeof window !== 'undefined') {
          localStorage.setItem('token', token);
          localStorage.setItem('accessToken', token); // backward compatibility
        }
        set({ token, guest, account });
      },
      clearAuth: () => {
        if (typeof window !== 'undefined') {
          localStorage.removeItem('token');
          localStorage.removeItem('accessToken');
        }
        set({ token: null, guest: null, account: null });
      },
      isAuthenticated: () => {
        return !!get().token;
      },
    }),
    {
      name: 'auth-storage',
    }
  )
);
