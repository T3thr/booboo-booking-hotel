'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { RoomSearchForm } from '@/components/room-search-form';
import { RoomCard } from '@/components/room-card';
import { useRoomSearch } from '@/hooks/use-rooms';
import { LoadingSpinner } from '@/components/ui/loading';
import { RoomSearchResult } from '@/types';
import { useBookingStore } from '@/store/useBookingStore';

export default function RoomSearchPage() {
  const router = useRouter();
  const [searchParams, setSearchParams] = useState<{
    check_in_date: string;
    check_out_date: string;
    adults: number;
    children: number;
  } | null>(null);

  const { data: rooms, isLoading, error } = useRoomSearch(
    searchParams || {
      check_in_date: '',
      check_out_date: '',
      adults: 2,
      children: 0,
    }
  );

  const handleSearch = (params: {
    check_in_date: string;
    check_out_date: string;
    adults: number;
    children: number;
  }) => {
    setSearchParams(params);
  };

  const { setSearchParams: setBookingSearchParams, setSelectedRoomType } = useBookingStore();

  const handleBook = (roomTypeId: number) => {
    if (!searchParams) return;
    
    // Find the selected room type
    const selectedRoom = rooms?.find(
      (room: RoomSearchResult) => room.room_type_id === roomTypeId
    );
    
    // Store search params and selected room in booking store
    setBookingSearchParams(searchParams);
    setSelectedRoomType(roomTypeId, selectedRoom);
    
    // Navigate to guest info page
    router.push('/booking/guest-info');
  };

  return (
    <div className="container mx-auto px-4 py-8 max-w-7xl">
      <div className="mb-8">
        <h1 className="text-4xl font-bold text-foreground mb-2">ค้นหาห้องพัก</h1>
        <p className="text-muted-foreground">
          เลือกวันที่และจำนวนผู้เข้าพักเพื่อค้นหาห้องว่าง
        </p>
      </div>

      <RoomSearchForm onSearch={handleSearch} isLoading={isLoading} />

      {/* Loading State */}
      {isLoading && (
        <div className="flex justify-center py-12">
          <LoadingSpinner size="lg" />
        </div>
      )}

      {/* Error State */}
      {error && (
        <div className="bg-destructive/10 border border-destructive/20 rounded-lg p-6">
          <div className="flex items-start gap-4">
            <svg
              className="w-12 h-12 text-destructive flex-shrink-0"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
            <div className="flex-1">
              <h3 className="text-lg font-semibold text-destructive mb-2">
                เกิดข้อผิดพลาดในการค้นหาห้องพัก
              </h3>
              <p className="text-destructive/80 mb-4">
                {error instanceof Error ? error.message : 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้'}
              </p>
              <div className="bg-background/50 rounded-lg p-4 text-sm">
                <p className="font-semibold text-foreground mb-2">วิธีแก้ไข:</p>
                <ul className="list-disc list-inside space-y-1 text-muted-foreground">
                  <li>ตรวจสอบว่า Backend Server ทำงานอยู่หรือไม่</li>
                  <li>ลองรีเฟรชหน้าเว็บ (F5)</li>
                  <li>ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต</li>
                  <li>ถ้ายังไม่ได้ ลอง restart backend server</li>
                </ul>
              </div>
              <button
                onClick={() => {
                  if (typeof window !== 'undefined') {
                    window.location.reload();
                  }
                }}
                className="mt-4 bg-destructive text-destructive-foreground px-6 py-2 rounded-lg hover:bg-destructive/90 transition-colors"
              >
                รีเฟรชหน้าเว็บ
              </button>
            </div>
          </div>
        </div>
      )}

      {/* No Results */}
      {!isLoading && !error && searchParams && rooms && rooms.length === 0 && (
        <div className="bg-accent/50 border border-accent rounded-lg p-8 text-center">
          <svg
            className="w-16 h-16 text-accent-foreground mx-auto mb-4"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
          <h3 className="text-xl font-semibold text-foreground mb-2">ไม่พบห้องว่าง</h3>
          <p className="text-muted-foreground mb-4">
            ขออภัย ไม่มีห้องว่างสำหรับวันที่ที่เลือก
          </p>
          <p className="text-sm text-muted-foreground">
            ลองเปลี่ยนวันที่หรือลดจำนวนผู้เข้าพัก
          </p>
        </div>
      )}

      {/* Results */}
      {!isLoading && !error && rooms && rooms.length > 0 && (
        <div>
          <div className="mb-6">
            <h2 className="text-2xl font-semibold text-foreground">
              พบห้องว่าง {rooms.length} ประเภท
            </h2>
            <p className="text-muted-foreground text-sm mt-1">
              สำหรับวันที่ {new Date(searchParams!.check_in_date).toLocaleDateString('th-TH')} -{' '}
              {new Date(searchParams!.check_out_date).toLocaleDateString('th-TH')}
            </p>
          </div>

          <div className="space-y-6">
            {rooms.map((room: RoomSearchResult) => (
              <RoomCard
                key={room.room_type_id}
                room={room}
                checkInDate={searchParams!.check_in_date}
                checkOutDate={searchParams!.check_out_date}
                onBook={handleBook}
              />
            ))}
          </div>
        </div>
      )}

      {/* Initial State - No Search Yet */}
      {!isLoading && !error && !searchParams && (
        <div className="text-center py-12">
          <svg
            className="w-20 h-20 text-muted-foreground/50 mx-auto mb-4"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
            />
          </svg>
          <h3 className="text-xl font-semibold text-muted-foreground mb-2">
            เริ่มค้นหาห้องพัก
          </h3>
          <p className="text-muted-foreground">
            กรอกข้อมูลด้านบนเพื่อค้นหาห้องว่าง
          </p>
        </div>
      )}
    </div>
  );
}
