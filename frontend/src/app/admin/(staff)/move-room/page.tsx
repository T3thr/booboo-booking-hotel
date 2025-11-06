'use client';

import { useState } from 'react';
import { useBookings } from '@/hooks/use-bookings';
import { useRooms } from '@/hooks/use-rooms';
import { useMoveRoom } from '@/hooks/use-checkin';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Loading } from '@/components/ui/loading';
import { formatDate } from '@/utils/date';

export default function MoveRoomPage() {
  const [selectedBooking, setSelectedBooking] = useState<any>(null);
  const [selectedNewRoom, setSelectedNewRoom] = useState<number | null>(null);
  const [reason, setReason] = useState('');
  const [showConfirm, setShowConfirm] = useState(false);

  const { data: bookingsData, isLoading: bookingsLoading } = useBookings({ 
    status: 'CheckedIn' 
  });
  const moveRoomMutation = useMoveRoom();

  const bookings = bookingsData?.bookings || [];

  const handleMoveRoom = async () => {
    if (!selectedBooking || !selectedNewRoom) return;

    try {
      await moveRoomMutation.mutateAsync({
        assignment_id: selectedBooking.room_assignment_id,
        new_room_id: selectedNewRoom,
        reason: reason || undefined,
      });
      
      alert('ย้ายห้องสำเร็จ!');
      setSelectedBooking(null);
      setSelectedNewRoom(null);
      setReason('');
      setShowConfirm(false);
    } catch (error: any) {
      alert(`เกิดข้อผิดพลาด: ${error.message}`);
    }
  };

  if (bookingsLoading) return <Loading />;

  return (
    <div className="container mx-auto p-6">
      <h1 className="text-3xl font-bold mb-6">ย้ายห้อง</h1>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Current Bookings */}
        <div>
          <h2 className="text-xl font-semibold mb-4">
            แขกที่เข้าพักอยู่ ({bookings.length})
          </h2>
          
          {bookings.length === 0 ? (
            <Card className="p-6 text-center text-gray-500">
              ไม่มีแขกที่เข้าพักอยู่ในขณะนี้
            </Card>
          ) : (
            <div className="space-y-3">
              {bookings.map((booking: any) => (
                <Card
                  key={booking.booking_id}
                  className={`p-4 cursor-pointer transition-all ${
                    selectedBooking?.booking_id === booking.booking_id
                      ? 'ring-2 ring-blue-500 bg-blue-50'
                      : 'hover:bg-gray-50'
                  }`}
                  onClick={() => {
                    setSelectedBooking(booking);
                    setSelectedNewRoom(null);
                    setShowConfirm(false);
                  }}
                >
                  <div className="space-y-2">
                    <div className="flex justify-between items-start">
                      <h3 className="font-semibold text-lg">{booking.guest_name}</h3>
                      <span className="px-2 py-1 rounded text-xs bg-blue-100 text-blue-800">
                        {booking.status}
                      </span>
                    </div>
                    
                    <div className="text-sm text-gray-600">
                      <p>ห้องปัจจุบัน: <span className="font-semibold text-lg">{booking.room_number}</span></p>
                      <p>ประเภทห้อง: {booking.room_type_name}</p>
                      <p>เช็คเอาท์: {formatDate(booking.check_out_date)}</p>
                    </div>
                  </div>
                </Card>
              ))}
            </div>
          )}
        </div>

        {/* New Room Selection */}
        <div>
          {selectedBooking ? (
            <div className="space-y-4">
              <h2 className="text-xl font-semibold">เลือกห้องใหม่</h2>
              
              <NewRoomSelector
                currentRoomTypeId={selectedBooking.room_type_id}
                currentRoomId={selectedBooking.room_id}
                selectedRoom={selectedNewRoom}
                onSelectRoom={setSelectedNewRoom}
              />

              {selectedNewRoom && (
                <Card className="p-4">
                  <label className="block text-sm font-medium mb-2">
                    เหตุผลในการย้ายห้อง (ไม่บังคับ)
                  </label>
                  <textarea
                    value={reason}
                    onChange={(e) => setReason(e.target.value)}
                    placeholder="เช่น แอร์เสีย, น้ำไม่ไหล, ขอเปลี่ยนห้อง"
                    className="w-full border rounded px-3 py-2 min-h-[100px]"
                  />
                </Card>
              )}
            </div>
          ) : (
            <Card className="p-6 text-center text-gray-500">
              เลือกแขกจากรายการด้านซ้ายเพื่อย้ายห้อง
            </Card>
          )}
        </div>
      </div>

      {/* Move Room Confirmation */}
      {selectedBooking && selectedNewRoom && (
        <Card className="mt-6 p-6">
          {!showConfirm ? (
            <Button
              onClick={() => setShowConfirm(true)}
              className="w-full"
            >
              ดำเนินการย้ายห้อง
            </Button>
          ) : (
            <div className="space-y-4">
              <div className="bg-yellow-50 border border-yellow-200 rounded p-4">
                <p className="text-sm text-yellow-800 mb-2">
                  ⚠️ คุณแน่ใจหรือไม่ว่าต้องการย้ายห้อง?
                </p>
                <div className="text-sm space-y-1">
                  <p>• ห้องเดิม ({selectedBooking.room_number}) จะถูกทำเครื่องหมายเป็น "รอทำความสะอาด"</p>
                  <p>• แขกจะย้ายไปห้องใหม่ทันที</p>
                  <p>• แผนกแม่บ้านจะได้รับการแจ้งเตือน</p>
                </div>
              </div>
              
              <div className="flex gap-3">
                <Button
                  onClick={handleMoveRoom}
                  disabled={moveRoomMutation.isPending}
                  className="flex-1 bg-green-600 hover:bg-green-700"
                >
                  {moveRoomMutation.isPending ? 'กำลังดำเนินการ...' : 'ยืนยันย้ายห้อง'}
                </Button>
                <Button
                  onClick={() => setShowConfirm(false)}
                  variant="outline"
                  className="flex-1"
                >
                  ยกเลิก
                </Button>
              </div>
            </div>
          )}
        </Card>
      )}
    </div>
  );
}

function NewRoomSelector({ 
  currentRoomTypeId,
  currentRoomId,
  selectedRoom, 
  onSelectRoom 
}: { 
  currentRoomTypeId: number;
  currentRoomId: number;
  selectedRoom: number | null;
  onSelectRoom: (roomId: number) => void;
}) {
  const { data: roomsData, isLoading } = useRooms({ 
    roomTypeId: currentRoomTypeId,
    status: 'available' 
  });

  const rooms = (roomsData?.rooms || []).filter((room: any) => room.room_id !== currentRoomId);

  if (isLoading) return <Loading />;

  return (
    <div>
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
