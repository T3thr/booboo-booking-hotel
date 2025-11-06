import { useMutation } from '@tanstack/react-query';
import { api } from '@/lib/api';
import { useAuthStore } from '@/store/useAuthStore';
import type { LoginCredentials, RegisterData, AuthResponse } from '@/types';

export function useAuth() {
  const { setAuth, clearAuth, isAuthenticated } = useAuthStore();

  const loginMutation = useMutation({
    mutationFn: async (credentials: LoginCredentials) => {
      const response = await api.post<AuthResponse>('/auth/login', credentials);
      return response;
    },
    onSuccess: (data) => {
      setAuth(data.token, data.guest, data.account);
    },
  });

  const registerMutation = useMutation({
    mutationFn: async (data: RegisterData) => {
      const response = await api.post<AuthResponse>('/auth/register', data);
      return response;
    },
    onSuccess: (data) => {
      setAuth(data.token, data.guest, data.account);
    },
  });

  const logout = () => {
    clearAuth();
  };

  return {
    login: loginMutation.mutate,
    register: registerMutation.mutate,
    logout,
    isAuthenticated: isAuthenticated(),
    isLoading: loginMutation.isPending || registerMutation.isPending,
    error: loginMutation.error || registerMutation.error,
  };
}
