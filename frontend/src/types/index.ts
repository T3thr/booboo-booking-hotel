// User & Authentication Types
export interface User {
  id: number;
  email: string;
  name?: string;
  role: 'guest' | 'receptionist' | 'housekeeper' | 'manager';
}

export interface Guest {
  id: number;
  guest_id: number;
  first_name: string;
  last_name: string;
  email: string;
  phone?: string;
  created_at: string;
  updated_at: string;
}

export interface GuestAccount {
  id: number;
  guest_id: number;
  username: string;
  role: 'guest' | 'receptionist' | 'housekeeper' | 'manager';
  is_active: boolean;
}

// Auth API Types
export interface LoginCredentials {
  username: string;
  password: string;
}

export interface RegisterData {
  first_name: string;
  last_name: string;
  email: string;
  phone: string;
  username: string;
  password: string;
}

export interface AuthResponse {
  token: string;
  guest: Guest;
  account: GuestAccount;
}

// Room Types
export interface RoomType {
  room_type_id: number;
  name: string;
  description?: string;
  max_occupancy: number;
  default_allotment: number;
  amenities?: Amenity[];
  images?: string[];
  image_url?: string;
  base_price?: number;
}

export interface Room {
  room_id: number;
  room_type_id: number;
  room_number: string;
  occupancy_status: 'Vacant' | 'Occupied';
  housekeeping_status: 'Dirty' | 'Cleaning' | 'Clean' | 'Inspected' | 'MaintenanceRequired' | 'OutOfService';
  room_type?: RoomType;
}

export interface Amenity {
  amenity_id: number;
  name: string;
}

// Booking Types
export interface Booking {
  booking_id: number;
  guest_id: number;
  voucher_id?: number;
  total_amount: number;
  status: 'PendingPayment' | 'Confirmed' | 'CheckedIn' | 'Completed' | 'Cancelled' | 'NoShow';
  created_at: string;
  updated_at: string;
  policy_name: string;
  policy_description: string;
  guest?: Guest;
  booking_details?: BookingDetail[];
  booking_guests?: BookingGuest[];
  booking_nightly_log?: BookingNightlyLog[];
}

export interface BookingDetail {
  booking_detail_id: number;
  booking_id: number;
  room_type_id: number;
  rate_plan_id: number;
  check_in_date: string;
  check_out_date: string;
  num_guests: number;
  room_type?: RoomType;
  room_assignment?: RoomAssignment;
}

export interface RoomAssignment {
  room_assignment_id: number;
  booking_detail_id: number;
  room_id: number;
  check_in_datetime: string;
  check_out_datetime?: string;
  status: 'Active' | 'Moved' | 'Completed';
  room?: Room;
}

export interface BookingGuest {
  booking_guest_id: number;
  booking_detail_id: number;
  first_name: string;
  last_name?: string;
  phone?: string;
  type: 'Adult' | 'Child';
  is_primary: boolean;
}

export interface BookingNightlyLog {
  booking_nightly_log_id: number;
  booking_detail_id: number;
  date: string;
  quoted_price: number;
}

// Pricing Types
export interface RateTier {
  rate_tier_id: number;
  name: string;
}

export interface RatePlan {
  rate_plan_id: number;
  name: string;
  description?: string;
  policy_id: number;
  policy?: CancellationPolicy;
}

export interface RatePricing {
  rate_plan_id: number;
  room_type_id: number;
  rate_tier_id: number;
  price: number;
}

export interface PricingCalendar {
  date: string;
  rate_tier_id: number;
  rate_tier?: RateTier;
}

export interface CancellationPolicy {
  policy_id: number;
  name: string;
  description?: string;
  days_before_check_in?: number;
  refund_percentage: number;
}

// Inventory Types
export interface RoomInventory {
  room_type_id: number;
  date: string;
  allotment: number;
  booked_count: number;
  tentative_count: number;
  available?: number;
}

// Voucher Types
export interface Voucher {
  voucher_id: number;
  code: string;
  discount_type: 'Percentage' | 'FixedAmount';
  discount_value: number;
  expiry_date: string;
  max_uses: number;
  current_uses: number;
}

// Search Types
export interface RoomSearchParams {
  check_in_date: string;
  check_out_date: string;
  adults?: number;
  children?: number;
}

export interface RoomAvailability {
  room_type: RoomType;
  available_rooms: number;
  total_price: number;
  nightly_rate: number;
  nights: number;
}

export interface RoomSearchResult extends RoomType {
  available_rooms?: number;
  total_price?: number;
  nightly_prices?: { date: string; price: number }[];
}

export interface RoomSearchResponse {
  room_types: RoomSearchResult[];
  check_in: string;
  check_out: string;
  guests: number;
  total_nights: number;
  alternative_dates?: string[];
}

// API Response Types
export interface ApiResponse<T> {
  data?: T;
  error?: string;
  message?: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
}

// Form Types
export interface LoginFormData {
  email: string;
  password: string;
}

export interface RegisterFormData {
  first_name: string;
  last_name: string;
  email: string;
  phone?: string;
  password: string;
  confirm_password: string;
}

export interface BookingFormData {
  room_type_id: number;
  rate_plan_id: number;
  check_in_date: string;
  check_out_date: string;
  num_guests: number;
  guests: BookingGuest[];
  voucher_code?: string;
}
