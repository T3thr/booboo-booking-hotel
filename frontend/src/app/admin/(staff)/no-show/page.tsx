'use client';

import { useState } from 'react';
import { useBookings } from '@/hooks/use-bookings';
import { useNoShow } from '@/hooks/use-checkin';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Loading } from '@/components/ui/loading';
import { formatDate } from '@/utils/date';

export default function NoShowPage() {
  const [selectedBooking, setSelectedBooking] = useState<any>(null);
  const [showConfirm, setShowConfirm] = useState(false);

  // Get confirmed bookings where check-in date has passed
  const { data: bookingsData, isLoading: bookingsLoading } = useBookings({ 
    status: 'Confirmed' 
  });
  const noShowMutation = useNoShow();

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  // Filter bookings where check-in date has passed
  const overdueBookings = (bookingsData?.bookings || []).filter((booking: any) => {
    const checkInDate = new Date(booking.check_in_date);
    checkInDate.setHours(0, 0, 0, 0);
    return checkInDate < today;
  });

  const handleMarkNoShow = async () => {
    if (!selectedBooking) return;

    try {
      await noShowMutation.mutateAsync(selectedBooking.booking_id);
      
      alert('ทำเครื่องหมาย No-Show สำเร็จ!');
      setSelectedBooking(null);
      setShowConfirm(false);
    } catch (error: any) {
      alert(`เกิดข้อผิดพลาด: ${error.message}`);
    }
  };

  if (bookingsLoading) return <Loading />;

  return (
    <div className="container mx-auto p-6">
      <h1 className="text-3xl font-bold mb-6">จัดการ No-Show</h1>

      <div className="mb-6">
        <Card className="p-4 bg-blue-50 border-blue-200">
          <p className="text-sm text-blue-800">
            ℹ️ หน้านี้แสดงการจองที่ยืนยันแล้วแต่แขกยังไม่มาเช็คอิน และวันเช็คอินผ่านไปแล้ว
          </p>
        </Card>
      </div>

      {/* Overdue Bookings List */}
      <div className="mb-6">
        <h2 className="text-xl font-semibold mb-4">
          การจองที่ค้างเช็คอิน ({overdueBookings.length})
        </h2>
        
        {overdueBookings.length === 0 ? (
          <Card className="p-6 text-center text-gray-500">
            ไม่มีการจองที่ค้างเช็คอิน
          </Card>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {overdueBookings.map((booking: any) => {
              const checkInDate = new Date(booking.check_in_date);
              const daysOverdue = Math.floor((today.getTime() - checkInDate.getTime()) / (1000 * 60 * 60 * 24));
              
              return (
                <Card
                  key={booking.booking_id}
                  className={`p-4 cursor-pointer transition-all ${
                    selectedBooking?.booking_id === booking.booking_id
                      ? 'ring-2 ring-red-500 bg-red-50'
                      : 'hover:bg-gray-50'
                  }`}
                  onClick={() => {
                    setSelectedBooking(booking);
                    setShowConfirm(false);
                  }}
                >
                  <div className="space-y-2">
                    <div className="flex justify-between items-start">
                      <h3 className="font-semibold text-lg">{booking.guest_name}</h3>
                      <span className="px-2 py-1 rounded text-xs bg-red-100 text-red-800">
                        เกิน {daysOverdue} วัน
                      </span>
                    </div>
                    
                    <div className="text-sm text-gray-600">
                      <p>ประเภทห้อง: {booking.room_type_name}</p>
                      <p>วันเช็คอิน: <span className="font-semibold text-red-600">
                        {formatDate(booking.check_in_date)}
                      </span></p>
                      <p>วันเช็คเอาท์: {formatDate(booking.check_out_date)}</p>
                      <p className="text-lg font-bold text-gray-800 mt-2">
                        ฿{booking.total_amount?.toLocaleString()}
                      </p>
                    </div>

                    {booking.guest_phone && (
                      <div className="pt-2 border-t">
                        <p className="text-xs text-gray-500">ติดต่อ:</p>
                        <p className="text-sm font-medium">{booking.guest_phone}</p>
                      </div>
                    )}
                  </div>
                </Card>
              );
            })}
          </div>
        )}
      </div>

      {/* No-Show Confirmation */}
      {selectedBooking && (
        <Card className="p-6">
          <h2 className="text-xl font-semibold mb-4">ยืนยันการทำเครื่องหมาย No-Show</h2>
          
          <div className="grid grid-cols-2 gap-4 mb-6">
            <div>
              <p className="text-sm text-gray-600">ชื่อแขก</p>
              <p className="font-semibold">{selectedBooking.guest_name}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">ประเภทห้อง</p>
              <p className="font-semibold">{selectedBooking.room_type_name}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">วันเช็คอิน (ที่พลาด)</p>
              <p className="font-semibold text-red-600">{formatDate(selectedBooking.check_in_date)}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">ยอดรวม</p>
              <p className="font-semibold text-lg">
                ฿{selectedBooking.total_amount?.toLocaleString()}
              </p>
            </div>
          </div>

          {!showConfirm ? (
            <Button
              onClick={() => setShowConfirm(true)}
              className="w-full bg-red-600 hover:bg-red-700"
            >
              ทำเครื่องหมาย No-Show
            </Button>
          ) : (
            <div className="space-y-3">
              <div className="bg-red-50 border border-red-200 rounded p-4">
                <p className="text-sm text-red-800 font-semibold mb-2">
                  ⚠️ คุณแน่ใจหรือไม่ว่าต้องการทำเครื่องหมาย No-Show?
                </p>
                <ul className="text-sm text-red-700 space-y-1 list-disc list-inside">
                  <li>การจองจะถูกเปลี่ยนสถานะเป็น "No-Show"</li>
                  <li>ห้องจะไม่ถูกปล่อยอัตโนมัติ (ต้องให้ผู้จัดการตัดสินใจ)</li>
                  <li>อาจมีการเรียกเก็บค่าปรับตามนโยบาย</li>
                  <li>ควรติดต่อแขกก่อนทำเครื่องหมาย No-Show</li>
                </ul>
              </div>
              
              <div className="flex gap-3">
                <Button
                  onClick={handleMarkNoShow}
                  disabled={noShowMutation.isPending}
                  className="flex-1 bg-red-600 hover:bg-red-700"
                >
                  {noShowMutation.isPending ? 'กำลังดำเนินการ...' : 'ยืนยัน No-Show'}
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

      {/* Help Section */}
      <Card className="mt-6 p-6 bg-gray-50">
        <h3 className="font-semibold mb-3">คำแนะนำ</h3>
        <ul className="text-sm text-gray-700 space-y-2 list-disc list-inside">
          <li>ควรพยายามติดต่อแขกก่อนทำเครื่องหมาย No-Show</li>
          <li>ตรวจสอบว่าแขกอาจมาสายหรือมีปัญหาในการเดินทาง</li>
          <li>หากแขกมาถึงหลังจากทำเครื่องหมาย No-Show สามารถเปลี่ยนสถานะกลับได้</li>
          <li>การทำเครื่องหมาย No-Show จะส่งผลต่อสถิติและอาจมีค่าปรับ</li>
        </ul>
      </Card>
    </div>
  );
}
