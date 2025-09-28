package entities

type InvoiceStruct struct {
	Id         string      `bson:"_id,omitempty" json:"id"`
	Date       string      `bson:"date" json:"date"`
	TotalPrice float64     `bson:"totalPrice" json:"totalPrice"`
	Order      OrderStruct `bson:"order" json:"order"` // Embedded order details
	Archived   bool        `bson:"archived" json:"archived"`
}

type InvoiceOrderStruct struct {
	Id         string                  `bson:"_id,omitempty" json:"id"`
	Date       string                  `bson:"date" json:"date"`
	TotalPrice float64                 `bson:"totalPrice" json:"totalPrice"`
	Order      OrderWithProductDetails `bson:"order" json:"order"`
	Archived   bool                    `bson:"archived" json:"archived"`
}

type UserInvoiceSummary struct {
	Date       string  `bson:"date" json:"date"`
	TotalPrice float64 `bson:"totalPrice" json:"totalPrice"`
	ID         string  `bson:"_id" json:"id"`
}
