package controllers

import (
	"context"
	"fmt"
	"math"
	"net/http"
	"os"
	"sort"
	"strconv"
	"time"

	"trinity/backend/items/entities"
	"trinity/backend/items/models"

	echo "github.com/labstack/echo/v4"
	paypal "github.com/plutov/paypal/v4"
)

func CreatePayment(c echo.Context) error {
	type CartItem struct {
		ProductID string `json:"productId" validate:"required"`
		Quantity  int    `json:"quantity" validate:"required,gt=0"`
	}
	var req struct {
		Cart []CartItem `json:"cart" validate:"required,dive"`
	}
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request payload"})
	}
	if err := c.Validate(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "request malformed"})
	}

	//cancel the last invoice before creating a new one
	_, err := models.CancelLastInvoice(c)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error": "failed to cancel last invoice: " + err.Error(),
		})
	}

	var totalPrice float64
	var orderProducts []entities.OrderProductStruct
	for _, item := range req.Cart {
		product, err := models.GetProductById(item.ProductID)
		if err != nil {
			return c.JSON(http.StatusBadRequest, map[string]string{
				"error": "product not found: " + item.ProductID,
			})
		}
		price := product.PriceVat * float64(item.Quantity)
		totalPrice += price
		orderProducts = append(orderProducts, entities.OrderProductStruct{
			ProductId: product.Id,
			Quantity:  item.Quantity,
			Price:     price,
		})
	}

	order := entities.OrderStruct{
		Date:          time.Now(),
		Status:        "pending",
		PaymentMethod: "PAYPAL",
		Products:      orderProducts,
	}

	invoice := entities.InvoiceStruct{
		Date:       time.Now().Format(time.RFC3339),
		TotalPrice: totalPrice,
		Order:      order,
		Archived:   false,
	}

	invoiceInserted, err := models.CreateInvoiceSelf(c, invoice)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error": "failed to save order: " + err.Error(),
		})
	}

	return c.JSON(http.StatusOK, map[string]string{
		"message":   "Order created successfully",
		"invoiceId": invoiceInserted.Id,
	})
}

func CapturePayment(c echo.Context) error {
	user, ok := c.Get("user").(entities.UserBasicStruct)
	if !ok {
		return c.JSON(http.StatusUnauthorized, map[string]string{"error": "user not authenticated"})
	}

	var req struct {
		PaypalOrderID string `json:"paypalOrderId" validate:"required"`
	}
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request payload"})
	}
	if err := c.Validate(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "request malformed"})
	}

	// Initialize PayPal client
	paypalClient, err := paypal.NewClient(
		os.Getenv("PAYPAL_CLIENT_ID"),
		os.Getenv("PAYPAL_SECRET"),
		os.Getenv("PAYPAL_API_BASE"),
	)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error": "failed to initialize PayPal client: " + err.Error(),
		})
	}

	// Fetch PayPal order details
	order, err := paypalClient.GetOrder(context.Background(), req.PaypalOrderID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "failed to retrieve PayPal order details: " + err.Error(),
		})
	}

	// Extract total amount from PayPal order
	var paypalAmount float64
	if len(order.PurchaseUnits) > 0 && order.PurchaseUnits[0].Amount != nil {
		paypalAmount, err = strconv.ParseFloat(order.PurchaseUnits[0].Amount.Value, 64)
		if err != nil {
			return c.JSON(http.StatusInternalServerError, map[string]string{
				"error": "failed to parse PayPal order amount: " + err.Error(),
			})
		}
	} else {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "no purchase units found in PayPal order",
		})
	}

	userDetailed, err := models.GetUserDetails(user.Id)
	if err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{"error": "user not found"})
	}

	invoices := userDetailed.Invoices

	if len(invoices) == 0 {
		return c.JSON(http.StatusNotFound, map[string]string{"error": "pending invoice not found"})
	}

	sort.Slice(invoices, func(i, j int) bool {
		return invoices[i].Date > invoices[j].Date
	})

	pendingInvoice := invoices[0]

	// Verify that the amount matches
	// Allow for a small difference (0.01) to account for floating point precision issues
	if math.Abs(pendingInvoice.TotalPrice-paypalAmount) > 0.01 {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error":    "payment amount does not match order total",
			"expected": fmt.Sprintf("%.2f", pendingInvoice.TotalPrice),
			"received": fmt.Sprintf("%.2f", paypalAmount),
		})
	}

	pendingInvoice.Order.Status = "paid"

	invoiceValid, err := models.UpdateInvoiceSelf(c, pendingInvoice)

	if err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{"error": "order not found or already updated"})
	}

	return c.JSON(http.StatusOK, map[string]string{
		"message":   "Order updated successfully",
		"invoiceId": invoiceValid.Id,
	})
}

func ReturnPayment(c echo.Context) error {
	return c.Redirect(http.StatusFound, "com.baptistegrimaldi.trinity://paypalpay")
}
