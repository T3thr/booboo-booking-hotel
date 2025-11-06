import { create } from 'zustand';
import { RoomSearchParams } from '@/types';

interface GuestInfo {
  first_name: string;
  last_name: string;
  type: 'Adult' | 'Child';
  is_primary: boolean;
}

interface BookingState {
  searchParams: RoomSearchParams | null;
  selectedRoomTypeId: number | null;
  selectedRoomType: any | null;
  holdExpiry: Date | null;
  guestInfo: GuestInfo[] | null;
  voucherCode: string | null;
  setSearchParams: (params: RoomSearchParams) => void;
  setSelectedRoomType: (roomTypeId: number, roomType?: any) => void;
  setHoldExpiry: (expiry: Date | null) => void;
  setGuestInfo: (guests: GuestInfo[]) => void;
  setVoucherCode: (code: string | null) => void;
  clearBooking: () => void;
}

export const useBookingStore = create<BookingState>((set) => ({
  searchParams: null,
  selectedRoomTypeId: null,
  selectedRoomType: null,
  holdExpiry: null,
  guestInfo: null,
  voucherCode: null,
  setSearchParams: (params) => set({ searchParams: params }),
  setSelectedRoomType: (roomTypeId, roomType) => set({ 
    selectedRoomTypeId: roomTypeId,
    selectedRoomType: roomType 
  }),
  setHoldExpiry: (expiry) => set({ holdExpiry: expiry }),
  setGuestInfo: (guests) => set({ guestInfo: guests }),
  setVoucherCode: (code) => set({ voucherCode: code }),
  clearBooking: () =>
    set({
      searchParams: null,
      selectedRoomTypeId: null,
      selectedRoomType: null,
      holdExpiry: null,
      guestInfo: null,
      voucherCode: null,
    }),
}));
