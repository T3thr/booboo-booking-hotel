import axios, { AxiosInstance, AxiosRequestConfig, AxiosError } from 'axios';
import { getSession } from 'next-auth/react';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080';

// Create axios instance
const apiClient: AxiosInstance = axios.create({
  baseURL: `${API_BASE_URL}/api`,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 10000, // 10 seconds timeout
  withCredentials: true,
});

// Request interceptor to add auth token and fix trailing slash
apiClient.interceptors.request.use(
  async (config) => {
    // Fix trailing slash issue
    if (config.url && config.url.endsWith('/')) {
      config.url = config.url.slice(0, -1);
    }
    
    // Try to get token from NextAuth session first
    if (typeof window !== 'undefined') {
      try {
        const session = await getSession();
        if (session?.accessToken) {
          config.headers.Authorization = `Bearer ${session.accessToken}`;
        }
      } catch (error) {
        console.error('Failed to get session:', error);
      }
    }
    
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor for error handling
apiClient.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
    // Log error for debugging
    console.error('[API Error]', error.config?.url, error.message);
    
    if (error.response?.status === 401) {
      // Handle unauthorized - redirect to login
      if (typeof window !== 'undefined') {
        window.location.href = '/auth/signin?callbackUrl=' + encodeURIComponent(window.location.pathname);
      }
    }
    
    // Format error message
    const errorMessage = error.response?.data 
      ? (error.response.data as any).error || (error.response.data as any).message || 'An error occurred'
      : error.code === 'ECONNABORTED' 
        ? 'Request timeout'
        : error.message || 'Network error';
    
    return Promise.reject(new Error(errorMessage));
  }
);

export default apiClient;

// API helper functions with better typing
export const api = {
  get: <T = any>(url: string, config?: AxiosRequestConfig) => 
    apiClient.get<T>(url, config).then(res => res.data),
  
  post: <T = any>(url: string, data?: any, config?: AxiosRequestConfig) => 
    apiClient.post<T>(url, data, config).then(res => res.data),
  
  put: <T = any>(url: string, data?: any, config?: AxiosRequestConfig) => 
    apiClient.put<T>(url, data, config).then(res => res.data),
  
  patch: <T = any>(url: string, data?: any, config?: AxiosRequestConfig) => 
    apiClient.patch<T>(url, data, config).then(res => res.data),
  
  delete: <T = any>(url: string, config?: AxiosRequestConfig) => 
    apiClient.delete<T>(url, config).then(res => res.data),
};

// Specific API endpoints
export const authApi = {
  register: (data: any) => api.post('/auth/register', data),
  login: (data: any) => api.post('/auth/login', data),
  me: () => api.get('/auth/me'),
  resetPassword: (data: any) => api.post('/auth/reset-password', data),
};

export const roomApi = {
  search: async (params: any) => {
    const backendParams = {
      checkIn: params.check_in_date,
      checkOut: params.check_out_date,
      guests: (params.adults || 0) + (params.children || 0),
    };
    
    const response = await fetch(`/api/rooms/search?${new URLSearchParams(backendParams as any).toString()}`, {
      method: 'GET',
      headers: { 'Content-Type': 'application/json' },
    });
    
    if (!response.ok) throw new Error(`Room search failed: ${response.status}`);
    return response.json();
  },
  getTypes: async () => {
    const response = await fetch('/api/rooms/types', {
      method: 'GET',
      headers: { 'Content-Type': 'application/json' },
    });
    
    if (!response.ok) throw new Error(`Get room types failed: ${response.status}`);
    return response.json();
  },
  getType: async (id: number) => {
    const response = await fetch(`/api/rooms/types/${id}`, {
      method: 'GET',
      headers: { 'Content-Type': 'application/json' },
    });
    
    if (!response.ok) throw new Error(`Get room type failed: ${response.status}`);
    return response.json();
  },
  getPricing: async (id: number, params: any) => {
    const backendParams = {
      checkIn: params.check_in_date,
      checkOut: params.check_out_date,
    };
    
    const response = await fetch(`/api/rooms/types/${id}/pricing?${new URLSearchParams(backendParams as any).toString()}`, {
      method: 'GET',
      headers: { 'Content-Type': 'application/json' },
    });
    
    if (!response.ok) throw new Error(`Get room pricing failed: ${response.status}`);
    return response.json();
  },
};

export const bookingApi = {
  createHold: async (data: any) => {
    let sessionId = '';
    if (typeof window !== 'undefined') {
      sessionId = sessionStorage.getItem('booking_session_id') || '';
      if (!sessionId) {
        sessionId = `guest_${Date.now()}_${Math.random().toString(36).substring(2, 11)}`;
        sessionStorage.setItem('booking_session_id', sessionId);
      }
    }
    
    const backendData = {
      session_id: sessionId,
      room_type_id: data.room_type_id,
      check_in: data.check_in_date || data.check_in,
      check_out: data.check_out_date || data.check_out,
      guest_account_id: data.guest_account_id,
    };
    
    console.log('[API] Creating hold with data:', backendData);
    
    const response = await fetch('/api/bookings/hold', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(backendData),
    });
    
    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      console.error('[API] Create hold failed:', errorData);
      throw new Error(`Create hold failed: ${response.status}`);
    }
    
    const result = await response.json();
    console.log('[API] Hold created:', result);
    
    // Return with session_id for frontend use
    return { ...result, session_id: sessionId };
  },
  create: async (data: any) => {
    // Get or generate session ID
    let sessionId = '';
    if (typeof window !== 'undefined') {
      sessionId = sessionStorage.getItem('booking_session_id') || '';
      if (!sessionId) {
        sessionId = `guest_${Date.now()}_${Math.random().toString(36).substring(2, 11)}`;
        sessionStorage.setItem('booking_session_id', sessionId);
      }
    }
    
    // Validate guest data
    if (!data.guests || data.guests.length === 0) {
      throw new Error('At least one guest is required');
    }
    
    const backendData = {
      session_id: sessionId,
      details: [{
        room_type_id: data.room_type_id,
        rate_plan_id: data.rate_plan_id || 1,
        check_in: data.check_in_date,
        check_out: data.check_out_date,
        num_guests: data.num_guests,
        guests: data.guests.map((g: any) => {
          // Ensure names are at least 2 characters
          const firstName = (g.first_name || '').trim();
          const lastName = (g.last_name || '').trim();
          
          if (firstName.length < 2) {
            throw new Error(`First name must be at least 2 characters: "${firstName}"`);
          }
          if (lastName.length < 2) {
            throw new Error(`Last name must be at least 2 characters: "${lastName}"`);
          }
          
          // Phone validation: allow empty for primary guest (will be filled from account if signed in)
          // Backend will handle the phone from account
          
          return {
            first_name: firstName,
            last_name: lastName,
            phone: g.phone || null,
            email: g.email || null,
            type: g.type || 'Adult',
            is_primary: g.is_primary || false,
          };
        }),
      }],
      voucher_code: data.voucher_code || null,
    };
    
    console.log('[API] Creating booking with data:', JSON.stringify(backendData, null, 2));
    
    const response = await fetch('/api/bookings', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(backendData),
    });
    
    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      console.error('[API] Create booking failed:', errorData);
      throw new Error(`Create booking failed: ${response.status} - ${errorData.error || 'Unknown error'}`);
    }
    return response.json();
  },
  confirm: async (id: number, paymentData?: { payment_method?: string; payment_id?: string }) => {
    const response = await fetch(`/api/bookings/${id}/confirm`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        payment_method: paymentData?.payment_method || 'mock_payment',
        payment_id: paymentData?.payment_id || `MOCK_${Date.now()}`,
      }),
    });
    
    if (!response.ok) throw new Error(`Confirm booking failed: ${response.status}`);
    return response.json();
  },
  cancel: async (id: number) => {
    const response = await fetch(`/api/bookings/${id}/cancel`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    });
    
    if (!response.ok) throw new Error(`Cancel booking failed: ${response.status}`);
    return response.json();
  },
  getAll: async (params?: any) => {
    const queryString = params ? `?${new URLSearchParams(params).toString()}` : '';
    const response = await fetch(`/api/bookings${queryString}`, {
      method: 'GET',
      headers: { 'Content-Type': 'application/json' },
    });
    
    if (!response.ok) throw new Error(`Get bookings failed: ${response.status}`);
    return response.json();
  },
  getById: async (id: number) => {
    const response = await fetch(`/api/bookings/${id}`, {
      method: 'GET',
      headers: { 'Content-Type': 'application/json' },
    });
    
    if (!response.ok) throw new Error(`Get booking failed: ${response.status}`);
    return response.json();
  },
  getByIdPublic: async (id: number, phone: string) => {
    const response = await fetch(`/api/bookings/${id}/public?phone=${encodeURIComponent(phone)}`, {
      method: 'GET',
      headers: { 'Content-Type': 'application/json' },
    });
    
    if (!response.ok) throw new Error(`Get booking failed: ${response.status}`);
    const result = await response.json();
    // Unwrap the data if it's wrapped in success/data structure
    return result.data || result;
  },
};

export const checkinApi = {
  checkIn: (data: any) => api.post('/checkin', data),
  checkOut: (bookingId: number) => api.post('/checkout', { booking_id: bookingId }),
  moveRoom: (data: any) => api.post('/checkin/move-room', data),
  noShow: (bookingId: number) => api.post(`/bookings/${bookingId}/no-show`),
  getArrivals: (date?: string) => api.get('/checkin/arrivals', { params: { date } }),
  getDepartures: (date?: string) => api.get('/checkout/departures', { params: { date } }),
  getAvailableRooms: (roomTypeId: number) => api.get(`/checkin/available-rooms/${roomTypeId}`),
};

export const housekeepingApi = {
  getTasks: () => api.get('/housekeeping/tasks'),
  updateRoomStatus: (roomId: number, status: string) => 
    api.put(`/housekeeping/rooms/${roomId}/status`, { status }),
  inspectRoom: (roomId: number, approved: boolean, reason?: string) => 
    api.post(`/housekeeping/rooms/${roomId}/inspect`, { approved, reason }),
  reportMaintenance: (roomId: number, description: string) => 
    api.post(`/housekeeping/rooms/${roomId}/maintenance`, { description }),
};

export const pricingApi = {
  getTiers: () => api.get('/pricing/tiers'),
  createTier: (data: any) => api.post('/pricing/tiers', data),
  updateTier: (id: number, data: any) => api.put(`/pricing/tiers/${id}`, data),
  deleteTier: (id: number) => api.delete(`/pricing/tiers/${id}`),
  getCalendar: (params?: any) => api.get('/pricing/calendar', { params }),
  updateCalendar: (data: any) => api.put('/pricing/calendar', data),
  getRates: (params?: any) => {
    if (params?.rate_plan_id) {
      return api.get(`/pricing/rates/plan/${params.rate_plan_id}`);
    }
    return api.get('/pricing/rates', { params });
  },
  updateRates: (data: any) => api.put('/pricing/rates', data),
};

export const inventoryApi = {
  get: (params?: any) => api.get('/inventory', { params }),
  update: (data: any) => api.put('/inventory', data),
};

export const reportApi = {
  getOccupancy: (params: any) => api.get('/reports/occupancy', { params }),
  getRevenue: (params: any) => api.get('/reports/revenue', { params }),
  getVouchers: (params: any) => api.get('/reports/vouchers', { params }),
  export: (type: string, params: any) => api.get(`/reports/export`, { params: { type, ...params } }),
};
