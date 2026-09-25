# V79 Commerce API — Current Routes

All `/v1/*` routes require an authenticated Vision79 user and a verified tenant membership. Local development may use the explicit dev-auth headers documented in the README.

## Identity and team
- `GET /v1/me`
- `GET /v1/team`
- `POST /v1/team`

## Catalogue and customers
- `GET /v1/products`
- `POST /v1/products`
- `GET /v1/customers`
- `POST /v1/customers`

## POS sales
- `GET /v1/sales`
- `POST /v1/sales`
- `POST /v1/sales/:id/returns`

## Inventory
- `GET /v1/inventory`
- `POST /v1/inventory/adjustments`
- `GET /v1/transfers`
- `POST /v1/transfers`
- `POST /v1/transfers/:id/approve`
- `POST /v1/transfers/:id/dispatch`
- `POST /v1/transfers/:id/receive`

## Suppliers and purchasing
- `GET /v1/suppliers`
- `POST /v1/suppliers`
- `POST /v1/suppliers/:supplierId/products`
- `GET /v1/purchase-orders`
- `POST /v1/purchase-orders`
- `POST /v1/purchase-orders/:id/approve`
- `POST /v1/purchase-orders/:id/receive`

## Logistics
- `GET /v1/shipments`
- `POST /v1/shipments`
- `PATCH /v1/shipments/:id/status`

## Smart replenishment
- `GET /v1/replenishment`
- `PUT /v1/replenishment/policies`
- `POST /v1/replenishment/recalculate`
- `POST /v1/replenishment/create-draft-pos`
- `GET /v1/notifications`

## Service health
- `GET /health`
- `GET /ready`
