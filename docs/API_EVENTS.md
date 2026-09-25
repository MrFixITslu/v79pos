# Ecosystem Event Contract

Initial event names:
- sale.completed
- sale.refunded
- inventory.received
- inventory.adjusted
- inventory.transferred
- inventory.stockout_risk
- purchase_order.created
- purchase_order.approved
- shipment.dispatched
- shipment.delayed
- shipment.received
- customer.created
- payment.completed

Events are written to the database outbox in the same transaction as the business change, then published asynchronously. This prevents a successful sale from being committed while the FFPRO2/V79Marketing event is silently lost.
