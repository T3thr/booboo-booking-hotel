"use client";

import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { LoadingSpinner } from "@/components/ui/loading";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { formatCurrency, formatDate, formatDateTime } from "@/utils/date";
import { api } from "@/lib/api";

interface Booking {
  booking_id: number;
  guest_id: number;
  total_amount: number;
  status: string;
  created_at: string;
  updated_at: string;
  booking_details?: BookingDetail[];
  booking_guests?: BookingGuest[];
  guest_name?: string;
  guest_email?: string;
  guest_phone?: string;
}

interface BookingDetail {
  booking_detail_id: number;
  booking_id: number;
  room_type_id: number;
  check_in_date: string;
  check_out_date: string;
  num_guests: number;
  room_type_name?: string;
  room_assignment?: RoomAssignment;
}

interface RoomAssignment {
  room_assignment_id: number;
  room_id: number;
  room_number?: string;
  check_in_datetime: string;
  check_out_datetime?: string;
  status: string;
}

interface BookingGuest {
  booking_guest_id: number;
  first_name: string;
  last_name: string;
  phone?: string;
  type: string;
  is_primary: boolean;
}

interface PaymentProof {
  payment_proof_id: number;
  booking_id: number;
  guest_name: string;
  guest_email: string;
  guest_phone: string;
  payment_method: string;
  amount: number;
  proof_url: string;
  status: string;
  created_at: string;
  booking_total: number;
  booking_status: string;
  check_in_date: string;
  check_out_date: string;
  room_type_name: string;
}

export default function BookingManagementTab() {
  const [selectedBooking, setSelectedBooking] = useState<Booking | null>(null);
  const [selectedProof, setSelectedProof] = useState<PaymentProof | null>(null);
  const [rejectionReason, setRejectionReason] = useState("");
  const [activeView, setActiveView] = useState<"bookings" | "payments">("bookings");
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [searchTerm, setSearchTerm] = useState("");
  const queryClient = useQueryClient();

  // Fetch bookings
  const { data: bookingsData, isLoading: bookingsLoading, refetch: refetchBookings } = useQuery({
    queryKey: ["admin-bookings", statusFilter],
    queryFn: async () => {
      const params = statusFilter !== "all" ? `?status=${statusFilter}` : "";
      const response = await fetch(`/api/admin/bookings${params}`);
      if (!response.ok) throw new Error("Failed to fetch bookings");
      const data = await response.json();
      return data.data || [];
    },
    refetchInterval: 30000,
    enabled: activeView === "bookings",
  });

  // Fetch payment proofs
  const { data: proofs, isLoading: proofsLoading, refetch: refetchProofs } = useQuery({
    queryKey: ["payment-proofs", "pending"],
    queryFn: async () => {
      const response = await fetch(`/api/admin/payment-proofs?status=pending`);
      if (!response.ok) throw new Error("Failed to fetch payment proofs");
      const data = await response.json();
      return data.data as PaymentProof[];
    },
    refetchInterval: 30000,
    enabled: activeView === "payments",
  });

  // Approve payment mutation
  const approveMutation = useMutation({
    mutationFn: async (paymentProofId: number) => {
      const response = await fetch(`/api/admin/payment-proofs/${paymentProofId}/approve`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
      });
      if (!response.ok) throw new Error("Failed to approve payment");
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["payment-proofs"] });
      queryClient.invalidateQueries({ queryKey: ["admin-bookings"] });
      setSelectedProof(null);
    },
  });

  // Reject payment mutation
  const rejectMutation = useMutation({
    mutationFn: async ({ paymentProofId, reason }: { paymentProofId: number; reason: string }) => {
      const response = await fetch(`/api/admin/payment-proofs/${paymentProofId}/reject`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ rejection_reason: reason }),
      });
      if (!response.ok) throw new Error("Failed to reject payment");
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["payment-proofs"] });
      queryClient.invalidateQueries({ queryKey: ["admin-bookings"] });
      setSelectedProof(null);
      setRejectionReason("");
    },
  });

  const handleApprove = (proof: PaymentProof) => {
    if (confirm(`ยืนยันการอนุมัติการชำระเงินสำหรับการจอง #${proof.booking_id}?`)) {
      approveMutation.mutate(proof.payment_proof_id);
    }
  };

  const handleReject = (proof: PaymentProof) => {
    if (!rejectionReason.trim()) {
      alert("กรุณาระบุเหตุผลในการปฏิเสธ");
      return;
    }
    if (confirm(`ยืนยันการปฏิเสธการชำระเงินสำหรับการจอง #${proof.booking_id}?`)) {
      rejectMutation.mutate({
        paymentProofId: proof.payment_proof_id,
        reason: rejectionReason,
      });
    }
  };

  const getStatusBadge = (status: string) => {
    const statusMap: Record<string, { label: string; className: string }> = {
      PendingPayment: { label: "รอชำระเงิน", className: "bg-yellow-500/10 text-yellow-600 dark:text-yellow-400" },
      Confirmed: { label: "ยืนยันแล้ว", className: "bg-green-500/10 text-green-600 dark:text-green-400" },
      CheckedIn: { label: "เช็คอินแล้ว", className: "bg-blue-500/10 text-blue-600 dark:text-blue-400" },
      Completed: { label: "เสร็จสิ้น", className: "bg-gray-500/10 text-gray-600 dark:text-gray-400" },
      Cancelled: { label: "ยกเลิก", className: "bg-red-500/10 text-red-600 dark:text-red-400" },
      NoShow: { label: "ไม่มาเช็คอิน", className: "bg-orange-500/10 text-orange-600 dark:text-orange-400" },
    };
    const config = statusMap[status] || { label: status, className: "bg-gray-500/10 text-gray-600" };
    return (
      <span className={`px-3 py-1 rounded-full text-xs font-medium ${config.className}`}>
        {config.label}
      </span>
    );
  };

  const bookings = Array.isArray(bookingsData) ? bookingsData : [];
  const filteredBookings = bookings.filter((booking: Booking) => {
    const matchesSearch = searchTerm === "" || 
      booking.booking_id.toString().includes(searchTerm) ||
      booking.guest_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      booking.guest_email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      booking.guest_phone?.includes(searchTerm);
    return matchesSearch;
  });

  const pendingPaymentsCount = proofs?.length || 0;

  if (bookingsLoading || proofsLoading) {
    return (
      <div className="flex items-center justify-center py-12">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-foreground">จัดการการจอง</h2>
          <p className="text-sm text-muted-foreground mt-1">
            ดูและจัดการการจองทั้งหมด (อัปเดตอัตโนมัติทุก 30 วินาที)
          </p>
        </div>
        <Button
          onClick={() => activeView === "bookings" ? refetchBookings() : refetchProofs()}
          variant="outline"
          className="flex items-center gap-2"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
          รีเฟรช
        </Button>
      </div>

      {/* View Tabs */}
      <div className="flex gap-2 border-b border-border">
        <button
          onClick={() => setActiveView("bookings")}
          className={`px-6 py-3 font-medium transition-colors border-b-2 ${
            activeView === "bookings"
              ? "border-primary text-primary"
              : "border-transparent text-muted-foreground hover:text-foreground"
          }`}
        >
          การจองทั้งหมด
        </button>
        <button
          onClick={() => setActiveView("payments")}
          className={`px-6 py-3 font-medium transition-colors border-b-2 ${
            activeView === "payments"
              ? "border-primary text-primary"
              : "border-transparent text-muted-foreground hover:text-foreground"
          }`}
        >
          รอตรวจสอบการชำระเงิน
          {pendingPaymentsCount > 0 && (
            <span className="ml-2 bg-primary text-primary-foreground text-xs px-2 py-1 rounded-full">
              {pendingPaymentsCount}
            </span>
          )}
        </button>
      </div>

      {/* Bookings View */}
      {activeView === "bookings" && (
        <div className="space-y-4">
          {/* Filters */}
          <div className="flex flex-col md:flex-row gap-4">
            <div className="flex-1">
              <Input
                type="text"
                placeholder="ค้นหาด้วยหมายเลขการจอง, ชื่อ, อีเมล, หรือเบอร์โทร..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full"
              />
            </div>
            <div className="flex gap-2 flex-wrap">
              <Button
                onClick={() => setStatusFilter("all")}
                variant={statusFilter === "all" ? "default" : "outline"}
                size="sm"
              >
                ทั้งหมด
              </Button>
              <Button
                onClick={() => setStatusFilter("PendingPayment")}
                variant={statusFilter === "PendingPayment" ? "default" : "outline"}
                size="sm"
              >
                รอชำระเงิน
              </Button>
              <Button
                onClick={() => setStatusFilter("Confirmed")}
                variant={statusFilter === "Confirmed" ? "default" : "outline"}
                size="sm"
              >
                ยืนยันแล้ว
              </Button>
              <Button
                onClick={() => setStatusFilter("CheckedIn")}
                variant={statusFilter === "CheckedIn" ? "default" : "outline"}
                size="sm"
              >
                เช็คอินแล้ว
              </Button>
            </div>
          </div>

          {/* Bookings List */}
          {filteredBookings.length === 0 ? (
            <Card className="p-12 text-center">
              <svg
                className="w-16 h-16 text-muted-foreground mx-auto mb-4"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                />
              </svg>
              <h3 className="text-xl font-semibold text-foreground mb-2">ไม่มีรายการ</h3>
              <p className="text-muted-foreground">ไม่พบการจองที่ตรงกับเงื่อนไขการค้นหา</p>
            </Card>
          ) : (
            <div className="grid grid-cols-1 gap-4">
              {filteredBookings.map((booking: Booking) => (
                <Card key={booking.booking_id} className="p-6">
                  <div className="flex items-start justify-between mb-4">
                    <div>
                      <div className="flex items-center gap-3 mb-2">
                        <h3 className="text-lg font-semibold text-foreground">
                          การจอง #{booking.booking_id}
                        </h3>
                        {getStatusBadge(booking.status)}
                      </div>
                      <div className="text-sm text-muted-foreground space-y-1">
                        {booking.guest_name && <p>ผู้จอง: {booking.guest_name}</p>}
                        {booking.guest_email && <p>อีเมล: {booking.guest_email}</p>}
                        {booking.guest_phone && <p>โทร: {booking.guest_phone}</p>}
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="text-sm text-muted-foreground">ยอดรวม</p>
                      <p className="text-xl font-bold text-primary">{formatCurrency(booking.total_amount)}</p>
                    </div>
                  </div>

                  {/* Booking Details */}
                  {booking.booking_details && booking.booking_details.length > 0 && (
                    <div className="border-t border-border pt-4 space-y-2">
                      {booking.booking_details.map((detail) => (
                        <div key={detail.booking_detail_id} className="flex items-center justify-between text-sm">
                          <div>
                            <p className="font-medium text-foreground">{detail.room_type_name || "ห้องพัก"}</p>
                            <p className="text-muted-foreground">
                              {formatDate(detail.check_in_date, "dd MMM")} - {formatDate(detail.check_out_date, "dd MMM yyyy")}
                            </p>
                            {detail.room_assignment && (
                              <p className="text-muted-foreground">
                                ห้อง: {detail.room_assignment.room_number || detail.room_assignment.room_id}
                              </p>
                            )}
                          </div>
                          <div className="text-right">
                            <p className="text-muted-foreground">{detail.num_guests} ท่าน</p>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}

                  {/* Guests */}
                  {booking.booking_guests && booking.booking_guests.length > 0 && (
                    <div className="border-t border-border pt-4 mt-4">
                      <p className="text-sm font-medium text-foreground mb-2">ผู้เข้าพัก:</p>
                      <div className="flex flex-wrap gap-2">
                        {booking.booking_guests.map((guest) => (
                          <span
                            key={guest.booking_guest_id}
                            className="px-3 py-1 bg-muted rounded-full text-xs"
                          >
                            {guest.first_name} {guest.last_name}
                            {guest.is_primary && " (หลัก)"}
                          </span>
                        ))}
                      </div>
                    </div>
                  )}

                  <div className="border-t border-border pt-4 mt-4 text-xs text-muted-foreground">
                    จองเมื่อ: {formatDateTime(booking.created_at)}
                  </div>
                </Card>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Payment Proofs View */}
      {activeView === "payments" && (
        <div className="space-y-4">
          {!proofs || proofs.length === 0 ? (
            <Card className="p-12 text-center">
              <svg
                className="w-16 h-16 text-muted-foreground mx-auto mb-4"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                />
              </svg>
              <h3 className="text-xl font-semibold text-foreground mb-2">ไม่มีรายการ</h3>
              <p className="text-muted-foreground">ไม่มีหลักฐานการชำระเงินที่รอตรวจสอบ</p>
            </Card>
          ) : (
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {proofs.map((proof) => (
                <Card key={proof.payment_proof_id} className="overflow-hidden">
                  {/* Header */}
                  <div className="bg-muted/50 px-6 py-4 border-b border-border">
                    <div className="flex items-center justify-between">
                      <div>
                        <h3 className="font-semibold text-foreground">
                          การจอง #{proof.booking_id}
                        </h3>
                        <p className="text-sm text-muted-foreground">{proof.guest_name}</p>
                      </div>
                      <span className="px-3 py-1 rounded-full text-xs font-medium bg-yellow-500/10 text-yellow-600 dark:text-yellow-400">
                        รอตรวจสอบ
                      </span>
                    </div>
                  </div>

                  {/* Content */}
                  <div className="p-6 space-y-4">
                    {/* Booking Info */}
                    <div className="grid grid-cols-2 gap-4 text-sm">
                      <div>
                        <p className="text-muted-foreground mb-1">ห้องพัก</p>
                        <p className="font-medium text-foreground">{proof.room_type_name}</p>
                      </div>
                      <div>
                        <p className="text-muted-foreground mb-1">วันที่เข้าพัก</p>
                        <p className="font-medium text-foreground">
                          {formatDate(proof.check_in_date, "dd MMM")} -{" "}
                          {formatDate(proof.check_out_date, "dd MMM yyyy")}
                        </p>
                      </div>
                      <div>
                        <p className="text-muted-foreground mb-1">วิธีชำระเงิน</p>
                        <p className="font-medium text-foreground">
                          {proof.payment_method === "bank_transfer"
                            ? "โอนเงินผ่านธนาคาร"
                            : proof.payment_method === "qr_code"
                            ? "QR Code พร้อมเพย์"
                            : proof.payment_method}
                        </p>
                      </div>
                      <div>
                        <p className="text-muted-foreground mb-1">จำนวนเงิน</p>
                        <p className="font-bold text-primary text-lg">
                          {formatCurrency(proof.amount)}
                        </p>
                      </div>
                    </div>

                    {/* Contact Info */}
                    <div className="bg-muted/30 rounded-lg p-3 text-sm">
                      <p className="text-muted-foreground mb-1">ข้อมูลติดต่อ</p>
                      <p className="text-foreground">{proof.guest_email}</p>
                      <p className="text-foreground">{proof.guest_phone}</p>
                    </div>

                    {/* Payment Proof Image */}
                    <div>
                      <p className="text-sm text-muted-foreground mb-2">หลักฐานการโอนเงิน</p>
                      <button
                        onClick={() => setSelectedProof(proof)}
                        className="w-full aspect-video bg-muted rounded-lg overflow-hidden hover:opacity-80 transition-opacity"
                      >
                        <img
                          src={proof.proof_url}
                          alt="Payment proof"
                          className="w-full h-full object-cover"
                        />
                      </button>
                    </div>

                    {/* Timestamp */}
                    <p className="text-xs text-muted-foreground">
                      ส่งเมื่อ {formatDateTime(proof.created_at)}
                    </p>

                    {/* Actions */}
                    <div className="flex gap-3 pt-2">
                      <button
                        onClick={() => handleApprove(proof)}
                        disabled={approveMutation.isPending}
                        className="flex-1 bg-green-600 text-white px-4 py-2 rounded-lg font-medium hover:bg-green-700 transition-colors disabled:opacity-50"
                      >
                        {approveMutation.isPending ? "กำลังดำเนินการ..." : "อนุมัติ"}
                      </button>
                      <button
                        onClick={() => {
                          setSelectedProof(proof);
                          setRejectionReason("");
                        }}
                        disabled={rejectMutation.isPending}
                        className="flex-1 bg-red-600 text-white px-4 py-2 rounded-lg font-medium hover:bg-red-700 transition-colors disabled:opacity-50"
                      >
                        ปฏิเสธ
                      </button>
                    </div>
                  </div>
                </Card>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Modal for viewing proof and rejection */}
      {selectedProof && (
        <div
          className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50"
          onClick={() => setSelectedProof(null)}
        >
          <div
            className="bg-background rounded-lg max-w-4xl w-full max-h-[90vh] overflow-y-auto"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="sticky top-0 bg-background border-b border-border px-6 py-4 flex items-center justify-between">
              <h3 className="text-xl font-bold text-foreground">
                หลักฐานการโอนเงิน - การจอง #{selectedProof.booking_id}
              </h3>
              <button
                onClick={() => setSelectedProof(null)}
                className="text-muted-foreground hover:text-foreground"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>

            <div className="p-6">
              <img
                src={selectedProof.proof_url}
                alt="Payment proof"
                className="w-full rounded-lg mb-6"
              />

              {selectedProof.status === "pending" && (
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-foreground mb-2">
                      เหตุผลในการปฏิเสธ (ถ้ามี)
                    </label>
                    <textarea
                      value={rejectionReason}
                      onChange={(e) => setRejectionReason(e.target.value)}
                      placeholder="ระบุเหตุผล..."
                      className="w-full px-4 py-3 bg-background border border-border rounded-lg text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary"
                      rows={3}
                    />
                  </div>

                  <div className="flex gap-3">
                    <button
                      onClick={() => handleApprove(selectedProof)}
                      disabled={approveMutation.isPending}
                      className="flex-1 bg-green-600 text-white px-6 py-3 rounded-lg font-medium hover:bg-green-700 transition-colors disabled:opacity-50"
                    >
                      {approveMutation.isPending ? "กำลังดำเนินการ..." : "อนุมัติการชำระเงิน"}
                    </button>
                    <button
                      onClick={() => handleReject(selectedProof)}
                      disabled={rejectMutation.isPending || !rejectionReason.trim()}
                      className="flex-1 bg-red-600 text-white px-6 py-3 rounded-lg font-medium hover:bg-red-700 transition-colors disabled:opacity-50"
                    >
                      {rejectMutation.isPending ? "กำลังดำเนินการ..." : "ปฏิเสธการชำระเงิน"}
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
