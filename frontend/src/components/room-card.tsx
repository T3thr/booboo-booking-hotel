'use client';

import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { RoomSearchResult } from '@/types';
import { formatCurrency, calculateNights } from '@/utils/date';

interface RoomCardProps {
  room: RoomSearchResult;
  checkInDate: string;
  checkOutDate: string;
  onBook: (roomTypeId: number) => void;
}

export function RoomCard({ room, checkInDate, checkOutDate, onBook }: RoomCardProps) {
  const nights = calculateNights(checkInDate, checkOutDate);
  const totalPrice = room.total_price || 0;
  const avgNightlyRate = nights > 0 ? totalPrice / nights : 0;
  
  // Backend returns available_rooms from database calculation
  // Debug: Log the room data to see what we're getting
  console.log('Room data:', {
    name: room.name,
    available_rooms: room.available_rooms,
    room_data: room
  });
  
  const availableRooms = room.available_rooms ?? 0;

  return (
    <Card className="overflow-hidden hover:shadow-lg transition-shadow">
      <div className="md:flex">
        {/* Room Image */}
        <div className="md:w-1/3 bg-muted min-h-[200px] flex items-center justify-center">
          {(room.images && room.images.length > 0) || room.image_url ? (
            <img
              src={room.images?.[0] || room.image_url || ''}
              alt={room.name}
              className="w-full h-full object-cover"
            />
          ) : (
            <div className="text-muted-foreground text-center p-4">
              <svg
                className="w-16 h-16 mx-auto mb-2"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"
                />
              </svg>
              <p className="text-sm">ไม่มีรูปภาพ</p>
            </div>
          )}
        </div>

        {/* Room Details */}
        <div className="md:w-2/3 p-6">
          <div className="flex justify-between items-start mb-4">
            <div>
              <h3 className="text-2xl font-bold text-foreground mb-2">{room.name}</h3>
              <p className="text-muted-foreground mb-2">{room.description}</p>
              <div className="flex items-center gap-4 text-sm text-muted-foreground">
                <span className="flex items-center gap-1">
                  <svg
                    className="w-4 h-4"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
                    />
                  </svg>
                  สูงสุด {room.max_occupancy} คน
                </span>
                <span className="flex items-center gap-1">
                  <svg
                    className="w-4 h-4"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
                    />
                  </svg>
                  ห้องว่าง {availableRooms} ห้อง
                </span>
              </div>
            </div>
          </div>

          {/* Amenities */}
          {room.amenities && room.amenities.length > 0 && (
            <div className="mb-4">
              <h4 className="font-semibold text-foreground mb-2 text-sm">สิ่งอำนวยความสะดวก:</h4>
              <div className="flex flex-wrap gap-2">
                {room.amenities.map((amenity) => (
                  <span
                    key={amenity.amenity_id}
                    className="px-3 py-1 bg-secondary text-secondary-foreground rounded-full text-xs"
                  >
                    {amenity.name}
                  </span>
                ))}
              </div>
            </div>
          )}

          {/* Pricing Details */}
          <div className="border-t border-border pt-4 mt-4">
            <div className="flex justify-between items-end">
              <div>
                <p className="text-sm text-muted-foreground mb-1">
                  ราคาเฉลี่ย {formatCurrency(avgNightlyRate)} / คืน
                </p>
                <p className="text-xs text-muted-foreground">
                  {nights} คืน × {formatCurrency(avgNightlyRate)}
                </p>
                
                {/* Show nightly breakdown if prices vary */}
                {room.nightly_prices && room.nightly_prices.length > 0 && (
                  <details className="mt-2">
                    <summary className="text-xs text-primary cursor-pointer hover:underline">
                      ดูรายละเอียดราคาแต่ละคืน
                    </summary>
                    <div className="mt-2 space-y-1">
                      {room.nightly_prices.map((night) => (
                        <div
                          key={night.date}
                          className="text-xs text-muted-foreground flex justify-between"
                        >
                          <span>{new Date(night.date).toLocaleDateString('th-TH')}</span>
                          <span>{formatCurrency(night.price)}</span>
                        </div>
                      ))}
                    </div>
                  </details>
                )}
              </div>
              
              <div className="text-right">
                <p className="text-3xl font-bold text-primary mb-2">
                  {formatCurrency(totalPrice)}
                </p>
                <Button
                  onClick={() => onBook(room.room_type_id)}
                  disabled={availableRooms === 0}
                  className="w-full"
                >
                  {availableRooms === 0 ? 'เต็ม' : 'จองห้องนี้'}
                </Button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Card>
  );
}
