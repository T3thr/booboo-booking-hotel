package service

import (
	"context"

	"github.com/hotel-booking-system/backend/internal/models"
	"github.com/hotel-booking-system/backend/internal/repository"
)

type PaymentProofService struct {
	paymentProofRepo *repository.PaymentProofRepository
}

func NewPaymentProofService(paymentProofRepo *repository.PaymentProofRepository) *PaymentProofService {
	return &PaymentProofService{
		paymentProofRepo: paymentProofRepo,
	}
}

// GetPaymentProofs retrieves all bookings with PendingPayment status with pagination
func (s *PaymentProofService) GetPaymentProofs(ctx context.Context, status string, limit, offset int) ([]models.PaymentProof, int, error) {
	// Set default limit if not provided
	if limit <= 0 {
		limit = 20 // Default 20 items per page
	}
	if offset < 0 {
		offset = 0
	}
	
	return s.paymentProofRepo.GetPaymentProofs(ctx, status, limit, offset)
}

// ApprovePaymentProof approves a booking (using booking_id as paymentProofID for now)
func (s *PaymentProofService) ApprovePaymentProof(ctx context.Context, bookingID int, notes *string) error {
	return s.paymentProofRepo.UpdatePaymentProofStatus(ctx, bookingID, "approved", notes)
}

// RejectPaymentProof rejects a booking
func (s *PaymentProofService) RejectPaymentProof(ctx context.Context, bookingID int, notes *string) error {
	return s.paymentProofRepo.UpdatePaymentProofStatus(ctx, bookingID, "rejected", notes)
}

// GetPaymentProofByID retrieves a single payment proof
func (s *PaymentProofService) GetPaymentProofByID(ctx context.Context, paymentProofID int) (*models.PaymentProof, error) {
	return s.paymentProofRepo.GetPaymentProofByID(ctx, paymentProofID)
}
