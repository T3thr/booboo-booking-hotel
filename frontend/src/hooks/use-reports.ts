import { useQuery } from '@tanstack/react-query';
import { reportApi } from '@/lib/api';

// Occupancy report
export function useOccupancyReport(params: {
  start_date: string;
  end_date: string;
  room_type_id?: number;
}) {
  return useQuery({
    queryKey: ['reports', 'occupancy', params],
    queryFn: () => reportApi.getOccupancy(params),
    enabled: !!params.start_date && !!params.end_date,
  });
}

// Revenue report
export function useRevenueReport(params: {
  start_date: string;
  end_date: string;
  room_type_id?: number;
  rate_plan_id?: number;
}) {
  return useQuery({
    queryKey: ['reports', 'revenue', params],
    queryFn: () => reportApi.getRevenue(params),
    enabled: !!params.start_date && !!params.end_date,
  });
}

// Voucher report
export function useVoucherReport(params: {
  start_date: string;
  end_date: string;
  voucher_id?: number;
}) {
  return useQuery({
    queryKey: ['reports', 'vouchers', params],
    queryFn: () => reportApi.getVouchers(params),
    enabled: !!params.start_date && !!params.end_date,
  });
}

// Export report
export function useExportReport(
  type: 'occupancy' | 'revenue' | 'vouchers',
  params: any,
  enabled: boolean = false
) {
  return useQuery({
    queryKey: ['reports', 'export', type, params],
    queryFn: () => reportApi.export(type, params),
    enabled: enabled && !!params.start_date && !!params.end_date,
  });
}
