'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { toast } from 'sonner';
import { formatDate } from '@/utils/date';
import Image from 'next/image';

interface Arrival {
  booking_id: number;
  booking_detail_id: number;
  guest_name: string;
  room_type_name: string;
  room_type_id: number;
  check_in_date: string;
  check_out_date: string;
  num_guests: number;
  status: string;
  room_number?: string;
  payment_status: string;
  payment_proof_url?: string;
  payment_proof_id?: number;
}

interface Room {
  room_id: number;
  room_number: string;
  floor: number;
  occupancy_status: string;
  housekeeping_status: string;
}

export default function CheckInPage() {
  const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split('T')[0]);
  const [selectedArrival, setSelectedArrival] = useState<Arrival | null>(null);
  const [selectedRoom, setSelectedRoom] = useState<number | null>(null);
  const [showPaymentProof, setShowPaymentProof] = useState(false);
  const queryClient = useQueryClient();

  // Fetch arrivals
  const { data: arrivalsData, isLoading: arrivalsLoading } = useQuery({
    queryKey: ['arrivals', selectedDate],
    queryFn: async () => {
      const res = await fetch(`/api/admin/checkin/arrivals?date=${selectedDate}`);
      if (!res.ok) throw new Error('Failed to fetch arrivals');
      return res.json();
    },
  });

  // Fetch available rooms for selected room type
  const { data: availableRooms } = useQuery({
    queryKey: ['availableRooms', selectedArrival?.room_type_id],
    queryFn: async () => {
      if (!selectedArrival?.room_type_id) return [];
      const res = await fetch(`/api/admin/checkin/available-rooms/${selectedArrival.room_type_id}`);
      if (!res.ok) throw new Error('Failed to fetch available rooms');
      return res.json();
    },
    enabled: !!selectedArrival?.room_type_id,
  });

  // Approve payment proof
  const approvePaymentMutation = useMutation({
    mutationFn: async (paymentProofId: number) => {
      const res = await fetch(`/api/admin/payment-proofs/${paymentProofId}/approve`, {
        method: 'POST',
      });
      if (!res.ok) throw new Error('Failed to approve payment');
      return res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['arrivals'] });
      toast.success('อนุมัติการชำระเงินสำเร็จ');
      setShowPaymentProof(false);
    },
    onError: () => toast.error('ไม่สามารถอนุมัติการชำระเงินได้'),
  });

  // Reject payment proof
  const rejectPaymentMutation = useMutation({
    mutationFn: async ({ paymentProofId, reason }: { paymentProofId: number; reason: string }) => {
      const res = await fetch(`/api/admin/payment-proofs/${paymentProofId}/reject`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ reason }),
      });
      if (!res.ok) throw new Error('Failed to reject payment');
      return res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['arrivals'] });
      toast.success('ปฏิเสธการชำระเงินสำเร็จ');
      setShowPaymentProof(false);
    },
    onError: () => toast.error('ไม่สามารถปฏิเสธการชำระเงินได้'),
  });

  // Check-in mutation
  const checkInMutation = useMutation({
    mutationFn: async (data: { booking_detail_id: number; room_id: number }) => {
      const res = await fetch('/api/admin/checkin', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      });
      if (!res.ok) throw new Error('Failed to check in');
      return res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['arrivals'] });
      toast.success('เช็คอินสำเร็จ!');
      setSelectedArrival(null);
      setSelectedRoom(null);
    },
    onError: (error: any) => toast.error(`เกิดข้อผิดพลาด: ${error.message}`),
  });

  const handleCheckIn = () => {
    if (!selectedArrival || !selectedRoom) {
      toast.error('กรุณาเลือกห้องก่อนเช็คอิน');
      return;
    }

    // Check payment status
    if (selectedArrival.payment_status !== 'approved') {
      toast.error('ต้องอนุมัติการชำระเงินก่อนเช็คอิน');
      return;
    }

    checkInMutation.mutate({
      booking_detail_id: selectedArrival.booking_detail_id,
      room_id: selectedRoom,
    });
  };

  const handleApprovePayment = () => {
    if (!selectedArrival?.payment_proof_id) return;
    approvePaymentMutation.mutate(selectedArrival.payment_proof_id);
  };

  const handleRejectPayment = () => {
    if (!selectedArrival?.payment_proof_id) return;
    const reason = prompt('กรุณาระบุเหตุผลในการปฏิเสธ:');
    if (!reason) return;
    rejectPaymentMutation.mutate({
      paymentProofId: selectedArrival.payment_proof_id,
      reason,
    });
  };

  const arrivals = arrivalsData?.arrivals || [];

  if (arrivalsLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div className="container mx-auto p-6 max-w-7xl">
      <h1 className="text-3xl font-bold mb-6 text-foreground">เช็คอิน</h1>

      {/* Date Selector */}
      <Card className="p-4 mb-6 bg-card border-border">
        <label className="block text-sm font-medium mb-2 text-foreground">เลือกวันที่</label>
        <input
          type="date"
          value={selectedDate}
          onChange={(e) => setSelectedDate(e.target.value)}
          className="border border-input rounded px-3 py-2 bg-background text-foreground"
        />
      </Card>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Arrivals List */}
        <div>
          <h2 className="text-xl font-semibold mb-4 text-foreground">
            รายการแขกที่จะมาถึง ({arrivals.length})
          </h2>

          {arrivals.length === 0 ? (
            <Card className="p-6 text-center text-muted-foreground bg-card border-border">
              ไม่มีแขกที่จะมาถึงในวันนี้
            </Card>
          ) : (
            <div className="space-y-3">
              {arrivals.map((arrival: Arrival) => (
                <Card
                  key={arrival.booking_detail_id}
                  className={`p-4 cursor-pointer transition-all border ${
                    selectedArrival?.booking_detail_id === arrival.booking_detail_id
                      ? 'ring-2 ring-primary bg-accent border-primary'
                      : 'bg-card border-border hover:bg-accent'
                  }`}
                  onClick={() => {
                    setSelectedArrival(arrival);
                    setSelectedRoom(null);
                  }}
                >
                  <div className="flex justify-between items-start">
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="font-semibold text-lg text-foreground">{arrival.guest_name}</h3>
                        <span className="text-xs text-muted-foreground">#{arrival.booking_id}</span>
                      </div>
                      <p className="text-sm text-muted-foreground font-medium">
                        {arrival.room_type_name}
                      </p>
                      <div className="mt-2 space-y-1">
                        <p className="text-sm text-muted-foreground">
                          📅 {formatDate(arrival.check_in_date)} - {formatDate(arrival.check_out_date)}
                        </p>
                        <p className="text-sm text-muted-foreground">
                          👥 {arrival.num_guests} คน
                        </p>
                        {arrival.room_number && (
                          <p className="text-sm text-green-600 dark:text-green-400 font-medium">
                            🚪 ห้อง {arrival.room_number} (เช็คอินแล้ว)
                          </p>
                        )}
                        {/* Status Badges */}
                        <div className="mt-2 flex flex-wrap gap-2">
                          {/* Booking Status */}
                          {arrival.status === 'Confirmed' && (
                            <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200">
                              ✓ ยืนยันแล้ว
                            </span>
                          )}
                          {arrival.status === 'CheckedIn' && (
                            <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
                              ✓ เช็คอินแล้ว
                            </span>
                          )}
                          
                          {/* Payment Status */}
                          {arrival.payment_status === 'approved' ? (
                            <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
                              💰 ชำระเงินแล้ว
                            </span>
                          ) : arrival.payment_status === 'pending' ? (
                            <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200">
                              ⏳ รอตรวจสอบ
                            </span>
                          ) : (
                            <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200">
                              ✗ ยังไม่ชำระ
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>
                </Card>
              ))}
            </div>
          )}
        </div>

        {/* Details & Actions */}
        <div>
          {!selectedArrival ? (
            <Card className="p-6 text-center text-muted-foreground bg-card border-border">
              เลือกแขกจากรายการด้านซ้ายเพื่อดูรายละเอียด
            </Card>
          ) : (
            <div className="space-y-4">
              {/* Guest Details */}
              <Card className="p-6 bg-card border-border">
                <h3 className="text-lg font-semibold mb-4 text-foreground">รายละเอียดการจอง</h3>
                <div className="space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">ชื่อแขก:</span>
                    <span className="font-medium text-foreground">{selectedArrival.guest_name}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">ประเภทห้อง:</span>
                    <span className="font-medium text-foreground">{selectedArrival.room_type_name}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">จำนวนผู้เข้าพัก:</span>
                    <span className="font-medium text-foreground">{selectedArrival.num_guests} คน</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">เช็คอิน:</span>
                    <span className="font-medium text-foreground">{formatDate(selectedArrival.check_in_date)}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">เช็คเอาท์:</span>
                    <span className="font-medium text-foreground">{formatDate(selectedArrival.check_out_date)}</span>
                  </div>
                </div>
              </Card>

              {/* Quick Link to Reception */}
              <Card className="p-4 bg-blue-50 dark:bg-blue-950 border-blue-200 dark:border-blue-800">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <span className="text-sm text-blue-800 dark:text-blue-200">
                      💼 ต้องการดูหลักฐานการชำระเงินหรือจัดการ booking?
                    </span>
                  </div>
                  <a
                    href="/admin/reception"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors text-sm font-medium"
                  >
                    ไปที่หน้า Reception →
                  </a>
                </div>
              </Card>

              {/* Payment Proof Section */}
              {selectedArrival.payment_proof_url && (
                <Card className="p-6 bg-card border-border">
                  <h3 className="text-lg font-semibold mb-4 text-foreground">หลักฐานการชำระเงิน</h3>
                  <div className="space-y-4">
                    <Button
                      onClick={() => setShowPaymentProof(true)}
                      className="w-full bg-accent text-accent-foreground"
                    >
                      ดูหลักฐานการชำระเงิน
                    </Button>
                    {selectedArrival.payment_status === 'pending' && (
                      <div className="flex gap-2">
                        <Button
                          onClick={handleApprovePayment}
                          disabled={approvePaymentMutation.isPending}
                          className="flex-1 bg-green-600 text-white hover:bg-green-700"
                        >
                          {approvePaymentMutation.isPending ? 'กำลังอนุมัติ...' : '✓ อนุมัติ'}
                        </Button>
                        <Button
                          onClick={handleRejectPayment}
                          disabled={rejectPaymentMutation.isPending}
                          className="flex-1 bg-red-600 text-white hover:bg-red-700"
                        >
                          {rejectPaymentMutation.isPending ? 'กำลังปฏิเสธ...' : '✗ ปฏิเสธ'}
                        </Button>
                      </div>
                    )}
                  </div>
                </Card>
              )}

              {/* Room Selection */}
              {selectedArrival.payment_status === 'approved' && !selectedArrival.room_number && (
                <Card className="p-6 bg-card border-border">
                  <h3 className="text-lg font-semibold mb-4 text-foreground">เลือกห้อง</h3>
                  {!availableRooms || availableRooms.length === 0 ? (
                    <p className="text-muted-foreground">ไม่มีห้องว่าง</p>
                  ) : (
                    <div className="grid grid-cols-3 gap-2 mb-4">
                      {availableRooms.map((room: Room) => (
                        <button
                          key={room.room_id}
                          onClick={() => setSelectedRoom(room.room_id)}
                          className={`p-3 rounded border text-sm font-medium transition-all ${
                            selectedRoom === room.room_id
                              ? 'bg-primary text-primary-foreground border-primary'
                              : 'bg-muted text-foreground border-border hover:bg-accent'
                          }`}
                        >
                          {room.room_number}
                        </button>
                      ))}
                    </div>
                  )}
                  <Button
                    onClick={handleCheckIn}
                    disabled={!selectedRoom || checkInMutation.isPending}
                    className="w-full bg-primary text-primary-foreground"
                  >
                    {checkInMutation.isPending ? 'กำลังเช็คอิน...' : 'เช็คอิน'}
                  </Button>
                </Card>
              )}

              {/* Already Checked In */}
              {selectedArrival.room_number && (
                <Card className="p-6 bg-green-50 dark:bg-green-950 border-green-200 dark:border-green-800">
                  <div className="text-center">
                    <div className="text-4xl mb-2">✓</div>
                    <h3 className="text-lg font-semibold text-green-800 dark:text-green-200">
                      เช็คอินแล้ว
                    </h3>
                    <p className="text-green-600 dark:text-green-400 mt-2">
                      ห้อง {selectedArrival.room_number}
                    </p>
                  </div>
                </Card>
              )}

              {/* Waiting for Payment Approval */}
              {selectedArrival.payment_status !== 'approved' && !selectedArrival.room_number && (
                <Card className="p-6 bg-yellow-50 dark:bg-yellow-950 border-yellow-200 dark:border-yellow-800">
                  <div className="text-center">
                    <div className="text-4xl mb-2">⏳</div>
                    <h3 className="text-lg font-semibold text-yellow-800 dark:text-yellow-200">
                      รอการอนุมัติการชำระเงิน
                    </h3>
                    <p className="text-yellow-600 dark:text-yellow-400 mt-2 text-sm">
                      กรุณาตรวจสอบและอนุมัติหลักฐานการชำระเงินก่อนเช็คอิน
                    </p>
                  </div>
                </Card>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Payment Proof Modal */}
      {showPaymentProof && selectedArrival?.payment_proof_url && (
        <div
          className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
          onClick={() => setShowPaymentProof(false)}
        >
          <div
            className="bg-card rounded-lg p-6 max-w-2xl w-full max-h-[90vh] overflow-auto"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-lg font-semibold text-foreground">หลักฐานการชำระเงิน</h3>
              <button
                onClick={() => setShowPaymentProof(false)}
                className="text-muted-foreground hover:text-foreground"
              >
                ✕
              </button>
            </div>
            <div className="relative w-full h-96 bg-muted rounded">
              <Image
                src={selectedArrival.payment_proof_url}
                alt="Payment Proof"
                fill
                className="object-contain"
              />
            </div>
            {selectedArrival.payment_status === 'pending' && (
              <div className="flex gap-2 mt-4">
                <Button
                  onClick={handleApprovePayment}
                  disabled={approvePaymentMutation.isPending}
                  className="flex-1 bg-green-600 text-white hover:bg-green-700"
                >
                  {approvePaymentMutation.isPending ? 'กำลังอนุมัติ...' : '✓ อนุมัติ'}
                </Button>
                <Button
                  onClick={handleRejectPayment}
                  disabled={rejectPaymentMutation.isPending}
                  className="flex-1 bg-red-600 text-white hover:bg-red-700"
                >
                  {rejectPaymentMutation.isPending ? 'กำลังปฏิเสธ...' : '✗ ปฏิเสธ'}
                </Button>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
