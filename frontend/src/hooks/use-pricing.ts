import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { pricingApi } from '@/lib/api';
import type { RateTier, PricingCalendar, RatePricing } from '@/types';

// Query hooks for Rate Tiers
export function useRateTiers() {
  return useQuery<RateTier[]>({
    queryKey: ['rateTiers'],
    queryFn: async () => {
      const response = await pricingApi.getTiers();
      return response.data || response;
    },
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
}

// Query hooks for Pricing Calendar
export function usePricingCalendar(params?: { start_date?: string; end_date?: string }) {
  return useQuery<PricingCalendar[]>({
    queryKey: ['pricingCalendar', params],
    queryFn: async () => {
      const response = await pricingApi.getCalendar(params);
      return response.data || response;
    },
  });
}

// Query hooks for Rate Pricing (matrix)
export function useRatePricing(params?: {
  rate_plan_id?: number;
  room_type_id?: number;
  rate_tier_id?: number;
}) {
  return useQuery<RatePricing[]>({
    queryKey: ['ratePricing', params],
    queryFn: async () => {
      const response = await pricingApi.getRates(params);
      return response.data || response;
    },
  });
}

// Mutation hooks for Rate Tiers
export function useCreateRateTier() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: { name: string }) => pricingApi.createTier(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['rateTiers'] });
    },
  });
}

export function useUpdateRateTier() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ rate_tier_id, name }: { rate_tier_id: number; name: string }) =>
      pricingApi.updateTier(rate_tier_id, { name }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['rateTiers'] });
    },
  });
}

export function useDeleteRateTier() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (rate_tier_id: number) => pricingApi.deleteTier(rate_tier_id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['rateTiers'] });
    },
  });
}

// Mutation hooks for Pricing Calendar
export function useUpdatePricingCalendar() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: {
      start_date: string;
      end_date: string;
      rate_tier_id: number;
    }) => pricingApi.updateCalendar(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['pricingCalendar'] });
    },
  });
}

// Mutation hooks for Rate Pricing
export function useUpdateRatePricing() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: {
      rate_plan_id: number;
      room_type_id: number;
      rate_tier_id: number;
      price: number;
    }[]) => pricingApi.updateRates(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['ratePricing'] });
    },
  });
}
