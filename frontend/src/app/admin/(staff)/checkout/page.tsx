'use client';

import { useState } from 'react';
import { useDepartures, useCheckOut } from '@/hooks/use-checkin';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Loading } from '@/components/ui/loading';
import { formatDate } from '@/utils/date';

export default function CheckOutPage() {
  const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split('T')[0]);
  const [selectedDeparture, setSelectedDeparture] = useState<any>(null);
  const [showConfirm, setShowConfirm] = useState(false);

  const { data: departuresData, isLoading: departuresLoading } = useDepartures(selectedDate);
  const checkOutMutation = useCheckOut();

  const departures = departuresData?.departures || [];

  const handleCheckOut = async () => {
    if (!selectedDeparture) return;

    try {
      await checkOutMutation.mutateAsync(selectedDeparture.booking_id);
      
      alert('เช็คเอาท์สำเร็จ!');
      setSelectedDeparture(null);
      setShowConfirm(false);
    } catch (error: any) {
      alert(`เกิดข้อผิดพลาด: ${error.message}`);
    }
  };

  if (departuresLoading) return <Loading />;

  return (
    <div className="container mx-auto p-6">
      <h1 className="text-3xl font-bold mb-6">เช็คเอาท์</h1>

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

      {/* Departures List */}
      <div className="mb-6">
        <h2 className="text-xl font-semibold mb-4">
          รายการแขกที่จะเช็คเอาท์ ({departures.length})
        </h2>
        
        {departures.length === 0 ? (
          <Card className="p-6 text-center text-gray-500">
            ไม่มีแขกที่จะเช็คเอาท์ในวันนี้
          </Card>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {departures.map((departure: any) => (
              <Card
                key={departure.booking_id}
                className={`p-4 cursor-pointer transition-all ${
                  selectedDeparture?.booking_id === departure.booking_id
                    ? 'ring-2 ring-blue-500 bg-blue-50'
                    : 'hover:bg-gray-50'
                }`}
                onClick={() => {
                  setSelectedDeparture(departure);
                  setShowConfirm(false);
                }}
              >
                <div className="space-y-2">
                  <div className="flex justify-between items-start">
                    <h3 className="font-semibold text-lg">{departure.guest_name}</h3>
                    <span className={`px-2 py-1 rounded text-xs ${
                      departure.status === 'CheckedIn' 
                        ? 'bg-blue-100 text-blue-800'
                        : 'bg-gray-100 text-gray-800'
                    }`}>
                      {departure.status}
                    </span>
                  </div>
                  
                  <div className="text-sm text-gray-600">
                    <p>ห้อง: <span className="font-semibold">{departure.room_number}</span></p>
                    <p>เช็คเอาท์: {formatDate(departure.check_out_date)}</p>
                    <p className="text-lg font-bold text-green-600 mt-2">
                      ยอดรวม: ฿{departure.total_amount?.toLocaleString()}
                    </p>
                  </div>
                </div>
              </Card>
            ))}
          </div>
        )}
      </div>

      {/* Checkout Confirmation */}
      {selectedDeparture && (
        <Card className="p-6">
          <h2 className="text-xl font-semibold mb-4">รายละเอียดการเช็คเอาท์</h2>
          
          <div className="grid grid-cols-2 gap-4 mb-6">
            <div>
              <p className="text-sm text-gray-600">ชื่อแขก</p>
              <p className="font-semibold">{selectedDeparture.guest_name}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">หมายเลขห้อง</p>
              <p className="font-semibold">{selectedDeparture.room_number}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">วันที่เช็คเอาท์</p>
              <p className="font-semibold">{formatDate(selectedDeparture.check_out_date)}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">ยอดรวมทั้งหมด</p>
              <p className="font-semibold text-lg text-green-600">
                ฿{selectedDeparture.total_amount?.toLocaleString()}
              </p>
            </div>
          </div>

          {!showConfirm ? (
            <Button
              onClick={() => setShowConfirm(true)}
              className="w-full"
            >
              ดำเนินการเช็คเอาท์
            </Button>
          ) : (
            <div className="space-y-3">
              <div className="bg-yellow-50 border border-yellow-200 rounded p-4">
                <p className="text-sm text-yellow-800">
                  ⚠️ คุณแน่ใจหรือไม่ว่าต้องการเช็คเอาท์แขกท่านนี้? 
                  ห้องจะถูกทำเครื่องหมายเป็น "รอทำความสะอาด" โดยอัตโนมัติ
                </p>
              </div>
              
              <div className="flex gap-3">
                <Button
                  onClick={handleCheckOut}
                  disabled={checkOutMutation.isPending}
                  className="flex-1 bg-green-600 hover:bg-green-700"
                >
                  {checkOutMutation.isPending ? 'กำลังดำเนินการ...' : 'ยืนยันเช็คเอาท์'}
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
