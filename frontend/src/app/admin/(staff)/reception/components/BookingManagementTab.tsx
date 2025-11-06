"use client";

import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { LoadingSpinner } from "@/components/ui/loading";
import { Button } from "@/components/ui/button";
import { formatCurrency, formatDate, formatDateTime } from "@/utils/date";

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
  const [selectedProof, setSelectedProof] = useState<PaymentProof | null>(null);
  const [rejectionReason, setRejectionReason] = useState("");
  const [filter, setFilter] = useState<"pending" | "all">("pending");
  const queryClient = useQueryClient();

  // Auto-refresh every 30 seconds
  const { data: proofs, isLoading, refetch } = useQuery({
    queryKey: ["payment-proofs", filter],
    queryFn: async () => {
      const response = await fetch(`/api/admin/payment-proofs?status=${filter}`);
      if (!response.ok) throw new Error("Failed to fetch payment proofs");
      const data = await response.json();
      return data.data as PaymentProof[];
    },
    refetchInterval: 30000, // Auto-refresh every 30 seconds
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

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-12">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header with Refresh Button */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-foreground">จัดการการจอง</h2>
          <p className="text-sm text-muted-foreground mt-1">
            ตรวจสอบและอนุมัติหลักฐานการโอนเงิน (อัปเดตอัตโนมัติทุก 30 วินาที)
          </p>
        </div>
        <Button
          onClick={() => refetch()}
          variant="outline"
          className="flex items-center gap-2"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
          รีเฟรช
        </Button>
      </div>

      {/* Filter Tabs */}
      <div className="flex gap-2 border-b border-border">
        <button
          onClick={() => setFilter("pending")}
          className={`px-6 py-3 font-medium transition-colors border-b-2 ${
            filter === "pending"
              ? "border-primary text-primary"
              : "border-transparent text-muted-foreground hover:text-foreground"
          }`}
        >
          รอตรวจสอบ
          {proofs && filter === "pending" && proofs.length > 0 && (
            <span className="ml-2 bg-primary text-primary-foreground text-xs px-2 py-1 rounded-full">
              {proofs.length}
            </span>
          )}
        </button>
        <button
          onClick={() => setFilter("all")}
          className={`px-6 py-3 font-medium transition-colors border-b-2 ${
            filter === "all"
              ? "border-primary text-primary"
              : "border-transparent text-muted-foreground hover:text-foreground"
          }`}
        >
          ทั้งหมด
        </button>
      </div>

      {/* Payment Proofs List */}
      {!proofs || proofs.length === 0 ? (
        <div className="bg-muted/30 rounded-lg p-12 text-center">
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
          <p className="text-muted-foreground">
            {filter === "pending"
              ? "ไม่มีหลักฐานการชำระเงินที่รอตรวจสอบ"
              : "ไม่มีหลักฐานการชำระเงิน"}
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {proofs.map((proof) => (
            <div
              key={proof.payment_proof_id}
              className="bg-background rounded-lg shadow-lg overflow-hidden border border-border"
            >
              {/* Header */}
              <div className="bg-muted/50 px-6 py-4 border-b border-border">
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="font-semibold text-foreground">
                      การจอง #{proof.booking_id}
                    </h3>
                    <p className="text-sm text-muted-foreground">{proof.guest_name}</p>
                  </div>
                  <span
                    className={`px-3 py-1 rounded-full text-xs font-medium ${
                      proof.status === "pending"
                        ? "bg-yellow-500/10 text-yellow-600 dark:text-yellow-400"
                        : proof.status === "approved"
                        ? "bg-green-500/10 text-green-600 dark:text-green-400"
                        : "bg-red-500/10 text-red-600 dark:text-red-400"
                    }`}
                  >
                    {proof.status === "pending"
                      ? "รอตรวจสอบ"
                      : proof.status === "approved"
                      ? "อนุมัติแล้ว"
                      : "ปฏิเสธ"}
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
                {proof.status === "pending" && (
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
                )}
              </div>
            </div>
          ))}
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
