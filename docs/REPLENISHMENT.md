# Smart Replenishment Engine

## Inventory position

Sellable inventory excludes stock that is reserved, committed, quarantined, damaged or expired.

`available = onHand - reserved - committed - quarantined - damaged - expired`

Inventory position adds confirmed incoming stock, but the projection engine also keeps each incoming quantity's expected arrival date so late stock is not treated as if it were available today.

## Demand forecast

The current production-independent deterministic baseline uses weighted unit-sales velocity:

- 50%: last 7 days
- 30%: last 30 days
- 20%: last 90 days

A policy may use manual daily demand during cold start. More advanced seasonal models can replace this estimator later without changing the replenishment contract.

## Safety stock

The engine uses the largest configured/calculated protection:

- fixed safety-stock quantity;
- forecast daily demand × safety days;
- service-factor × daily-demand standard deviation × square root of planning lead time.

This allows volatile items to receive more protection when a service level is configured.

## Planning lead time

Manual lead time wins when configured. Otherwise the engine compares supplier quoted lead time with the 80th percentile of observed PO-to-receipt lead times and uses the more conservative figure.

## Reorder point

`reorderPoint = forecastDemandDuringPlanningLeadTime + safetyStock`

## Stock projection and order-by date

The engine simulates inventory day by day, subtracting forecast demand and adding inbound PO/shipment quantities only on their expected arrival dates. It records the first projected safety-stock breach and stock-out date.

`mustOrderBy ≈ safetyStockBreachDate - planningLeadTime`

The simulation is the authoritative calculation because it can account for delayed and partial inbound quantities.

## Recommended quantity

Target stock covers planning lead time plus the review period and safety stock. The shortfall is rounded upward to supplier case-pack and minimum-order constraints.

## Explainability

Each recommendation stores the inventory, demand, inbound, supplier lead-time, safety-stock and pack/MOQ inputs used in the calculation so the UI can provide a transparent **Why?** panel.
