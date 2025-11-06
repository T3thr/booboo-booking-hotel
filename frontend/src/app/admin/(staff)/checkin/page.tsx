'use client';

import { useState } from 'react';
import { useArrivals, useCheckIn } from '@/hooks/use-checkin';
import { useRooms } from '@/hooks/use-rooms';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Loading } from '@/components/ui/loading';
import { formatDate } from '@/utils/date';

export default function CheckInPage() {
  const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split('T')[0]);
  const [selectedArrival, setSelectedArrival] = useState<any>(null);
  const [selectedRoom, setSelectedRoom] = useState<number | null>(null);

  const { data: arrivalsData, isLoading: arrivalsLoading } = useArrivals(selectedDate);
  const checkInMutation = useCheckIn();

  const arrivals = arrivalsData?.arrivals || [];

  const handleCheckIn = async () => {
    if (!selectedArrival || !selectedRoom) return;

    try {
      await checkInMutation.mutateAsync({
        booking_detail_id: selectedArrival.booking_detail_id,
        room_id: selectedRoom,
      });
      
      alert('เช็คอินสำเร็จ!');
      setSelectedArrival(null);
      setSelectedRoom(null);
    } catch (error: any) {
      alert(`เกิดข้อผิดพลาด: ${error.message}`);
    }
  };

  if (arrivalsLoading) return <Loading />;

  return (
    <div className="container mx-auto p-6">
      <h1 className="text-3xl font-bold mb-6">เช็คอิน</h1>

      {/* Date Selector */}
      <Card className="p-4 mb-6">
        <label className="block text-sm font-medium mb-2">เลือกวันที่</label>
        <input
          type="date"
          value={selectedDate}
          onChange={(e) => setSelectedDate(e.target.value)}
          className="border rounded px-3 py-2"
        />
      </Card>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Arrivals List */}
        <div>
          <h2 className="text-xl font-semibold mb-4">
            รายการแขกที่จะมาถึง ({arrivals.length})
          </h2>
          
          {arrivals.length === 0 ? (
            <Card className="p-6 text-center text-gray-500">
              ไม่มีแขกที่จะมาถึงในวันนี้
            </Card>
          ) : (
            <div className="space-y-3">
              {arrivals.map((arrival: any) => (
                <Card
                  key={arrival.booking_detail_id}
                  className={`p-4 cursor-pointer transition-all ${
                    selectedArrival?.booking_detail_id === arrival.booking_detail_id
                      ? 'ring-2 ring-blue-500 bg-blue-50 dark:bg-blue-950'
                      : 'hover:bg-gray-50 dark:hover:bg-gray-800'
                  }`}
                  onClick={() => {
                    setSelectedArrival(arrival);
                    setSelectedRoom(null);
                  }}
                >
                  <div className="flex justify-between items-start">
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="font-semibold text-lg">{arrival.guest_name}</h3>
                        <span className="text-xs text-gray-500">#{arrival.booking_id}</span>
                      </div>
                      <p className="text-sm text-gray-600 dark:text-gray-400 font-medium">
                        {arrival.room_type_name}
                      </p>
                      <div className="mt-2 space-y-1">
                        <p className="text-sm text-gray-500 dark:text-gray-400">
                          📅 {formatDate(arrival.check_in_date)} - {formatDate(arrival.check_out_date)}
                        </p>
                        <p className="text-sm text-gray-500 dark:text-gray-400">
                          👥 {arrival.num_guests} คน
                        </p>
                        {arrival.room_number && (
                          <p className="text-sm text-green-600 dark:text-green-400 font-medium">
                            🚪 ห้อง {arrival.room_number} (เช็คอินแล้ว)
                          </p>
                        )}
                      </div>
                    </div>
                    <div className="text-right">
                      <span className={`px-2 py-1 rounded text-xs font-medium ${
                        arrival.status === 'Confirmed' 
                          ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200'
                          : arrival.status === 'CheckedIn'
                          ? 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200'
                          : 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200'
                      }`}>
                        {arrival.status === 'Confirmed' ? 'ยืนยันแล้ว' : 
                         arrival.status === 'CheckedIn' ? 'เช็คอินแล้ว' : 
                         arrival.status}
                      </span>
                    </div>
                  </div>
                </Card>
              ))}
            </div>
          )}
        </div>

        {/* Room Selection */}
        <div>
          {selectedArrival ? (
            <RoomSelector
              roomTypeId={selectedArrival.room_type_id}
              selectedRoom={selectedRoom}
              onSelectRoom={setSelectedRoom}
            />
          ) : (
            <Card className="p-6 text-center text-gray-500">
              เลือกแขกจากรายการด้านซ้ายเพื่อเลือกห้อง
            </Card>
          )}
        </div>
      </div>

      {/* Check-in Button */}
      {selectedArrival && selectedRoom && (
        <div className="mt-6 flex justify-end">
          <Button
            onClick={handleCheckIn}
            disabled={checkInMutation.isPending}
            className="px-8 py-3 text-lg"
          >
            {checkInMutation.isPending ? 'กำลังเช็คอิน...' : 'ยืนยันเช็คอิน'}
          </Button>
        </div>
      )}
    </div>
  );
}

function RoomSelector({ 
  roomTypeId, 
  selectedRoom, 
  onSelectRoom 
}: { 
  roomTypeId: number;
  selectedRoom: number | null;
  onSelectRoom: (roomId: number) => void;
}) {
  const { data: roomsData, isLoading } = useRooms({ 
    roomTypeId,
    status: 'available' 
  });

  const rooms = roomsData?.rooms || [];

  if (isLoading) return <Loading />;

  return (
    <div>
      <h2 className="text-xl font-semibold mb-4">
        เลือกห้อง ({rooms.length} ห้องว่าง)
      </h2>
      
      {rooms.length === 0 ? (
        <Card className="p-6 text-center text-gray-500">
          ไม่มีห้องว่างสำหรับประเภทห้องนี้
        </Card>
      ) : (
        <div className="grid grid-cols-2 gap-3">
          {rooms.map((room: any) => (
            <Card
              key={room.room_id}
              className={`p-4 cursor-pointer transition-all ${
                selectedRoom === room.room_id
                  ? 'ring-2 ring-blue-500 bg-blue-50'
                  : 'hover:bg-gray-50'
              }`}
              onClick={() => onSelectRoom(room.room_id)}
            >
              <div className="text-center">
                <div className="text-2xl font-bold mb-2">{room.room_number}</div>
                <div className={`text-xs px-2 py-1 rounded inline-block ${
                  room.housekeeping_status === 'Inspected'
                    ? 'bg-green-100 text-green-800'
                    : 'bg-yellow-100 text-yellow-800'
                }`}>
                  {room.housekeeping_status === 'Inspected' ? 'ตรวจสอบแล้ว' : 'สะอาด'}
                </div>
              </div>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
