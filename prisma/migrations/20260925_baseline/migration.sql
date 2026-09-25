-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "LocationType" AS ENUM ('STORE', 'WAREHOUSE', 'OFFICE', 'POPUP', 'MOBILE');

-- CreateEnum
CREATE TYPE "ProductType" AS ENUM ('STANDARD', 'VARIANT', 'SERVICE', 'BUNDLE', 'KIT', 'SERIALIZED', 'LOT_TRACKED', 'WEIGHTED', 'NON_STOCK');

-- CreateEnum
CREATE TYPE "InventoryMovementType" AS ENUM ('PURCHASE_RECEIPT', 'SALE', 'SALE_RETURN', 'TRANSFER_OUT', 'TRANSFER_IN', 'ADJUSTMENT_GAIN', 'ADJUSTMENT_LOSS', 'DAMAGE', 'EXPIRY', 'QUARANTINE_IN', 'QUARANTINE_RELEASE', 'RESERVATION', 'RESERVATION_RELEASE');

-- CreateEnum
CREATE TYPE "ReservationStatus" AS ENUM ('ACTIVE', 'RELEASED', 'CONSUMED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "SaleStatus" AS ENUM ('OPEN', 'COMPLETED', 'VOIDED', 'PARTIALLY_REFUNDED', 'REFUNDED');

-- CreateEnum
CREATE TYPE "ReturnStatus" AS ENUM ('COMPLETED', 'VOIDED');

-- CreateEnum
CREATE TYPE "StockTransferStatus" AS ENUM ('REQUESTED', 'APPROVED', 'IN_TRANSIT', 'RECEIVED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "PaymentStatus" AS ENUM ('PENDING', 'COMPLETED', 'FAILED', 'VOIDED', 'REFUNDED', 'PARTIALLY_REFUNDED');

-- CreateEnum
CREATE TYPE "PaymentMethod" AS ENUM ('CASH', 'CARD', 'EXTERNAL_TERMINAL', 'BANK_TRANSFER', 'MOBILE_WALLET', 'STORE_CREDIT', 'GIFT_CARD', 'LOYALTY_POINTS', 'OTHER');

-- CreateEnum
CREATE TYPE "PurchaseOrderStatus" AS ENUM ('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'SUBMITTED', 'CONFIRMED', 'PARTIALLY_RECEIVED', 'RECEIVED', 'CANCELLED', 'CLOSED');

-- CreateEnum
CREATE TYPE "ShipmentStatus" AS ENUM ('PLANNED', 'CONFIRMED', 'PREPARING', 'DISPATCHED', 'IN_TRANSIT', 'ARRIVED_CUSTOMS', 'CUSTOMS_RELEASED', 'OUT_FOR_DELIVERY', 'RECEIVED', 'EXCEPTION', 'CANCELLED');

-- CreateEnum
CREATE TYPE "ReplenishmentStatus" AS ENUM ('HEALTHY', 'PLAN', 'ORDER_SOON', 'ORDER_NOW', 'STOCKOUT_RISK', 'STOCKED_OUT');

-- CreateEnum
CREATE TYPE "NotificationSeverity" AS ENUM ('INFO', 'WARNING', 'CRITICAL');

-- CreateEnum
CREATE TYPE "RegisterSessionStatus" AS ENUM ('OPEN', 'CLOSED');

-- CreateEnum
CREATE TYPE "CashMovementType" AS ENUM ('PAID_IN', 'PAID_OUT', 'CASH_DROP', 'CASH_PICKUP');

-- CreateEnum
CREATE TYPE "StockCountStatus" AS ENUM ('DRAFT', 'IN_PROGRESS', 'SUBMITTED', 'COMPLETED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "StockCountType" AS ENUM ('FULL', 'CYCLE', 'BLIND');

-- CreateEnum
CREATE TYPE "PromotionType" AS ENUM ('PERCENTAGE', 'FIXED_AMOUNT');

-- CreateEnum
CREATE TYPE "ValueTransactionType" AS ENUM ('CREDIT', 'DEBIT', 'ADJUSTMENT');

-- CreateEnum
CREATE TYPE "GiftCardStatus" AS ENUM ('ACTIVE', 'BLOCKED', 'EXPIRED', 'DEPLETED');

-- CreateEnum
CREATE TYPE "PaymentIntentStatus" AS ENUM ('CREATED', 'REQUIRES_ACTION', 'PROCESSING', 'SUCCEEDED', 'FAILED', 'CANCELLED', 'REFUNDED');

-- CreateEnum
CREATE TYPE "CommerceOrderType" AS ENUM ('QUOTE', 'ORDER', 'LAYAWAY', 'INVOICE');

-- CreateEnum
CREATE TYPE "CommerceOrderStatus" AS ENUM ('DRAFT', 'SENT', 'ACCEPTED', 'PARTIALLY_PAID', 'PAID', 'FULFILLING', 'COMPLETED', 'CANCELLED', 'EXPIRED');

-- CreateEnum
CREATE TYPE "SerialStatus" AS ENUM ('AVAILABLE', 'RESERVED', 'SOLD', 'IN_TRANSIT', 'DAMAGED', 'RETIRED');

-- CreateEnum
CREATE TYPE "FulfillmentMethod" AS ENUM ('PICKUP', 'LOCAL_DELIVERY', 'SHIPMENT');

-- CreateEnum
CREATE TYPE "FulfillmentStatus" AS ENUM ('PENDING', 'PICKING', 'READY', 'DISPATCHED', 'DELIVERED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "CommissionBasis" AS ENUM ('REVENUE', 'GROSS_PROFIT');

-- CreateEnum
CREATE TYPE "ShiftStatus" AS ENUM ('OPEN', 'CLOSED');

-- CreateTable
CREATE TABLE "Tenant" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'XCD',
    "timezone" TEXT NOT NULL DEFAULT 'America/St_Lucia',
    "active" BOOLEAN NOT NULL DEFAULT true,
    "offlineSalesEnabled" BOOLEAN NOT NULL DEFAULT true,
    "offlineMaxSnapshotHours" INTEGER NOT NULL DEFAULT 72,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Tenant_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TenantRole" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "builtIn" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "TenantRole_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RolePermission" (
    "id" TEXT NOT NULL,
    "roleId" TEXT NOT NULL,
    "permission" TEXT NOT NULL,

    CONSTRAINT "RolePermission_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Membership" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "roleKey" TEXT NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Membership_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "UserLocationAccess" (
    "id" TEXT NOT NULL,
    "membershipId" TEXT NOT NULL,
    "locationId" TEXT NOT NULL,

    CONSTRAINT "UserLocationAccess_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Location" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "type" "LocationType" NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "address" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Location_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Register" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "locationId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Register_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Product" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "productType" "ProductType" NOT NULL,
    "category" TEXT,
    "brand" TEXT,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Product_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ProductVariant" (
    "id" TEXT NOT NULL,
    "productId" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "sku" TEXT NOT NULL,
    "barcode" TEXT,
    "name" TEXT NOT NULL,
    "baseCost" DECIMAL(18,4) NOT NULL DEFAULT 0,
    "sellPrice" DECIMAL(18,4) NOT NULL,
    "taxRate" DECIMAL(7,6) NOT NULL DEFAULT 0,
    "trackStock" BOOLEAN NOT NULL DEFAULT true,
    "requiresExpiry" BOOLEAN NOT NULL DEFAULT false,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "attributes" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ProductVariant_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Customer" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "externalRef" TEXT,
    "name" TEXT NOT NULL,
    "email" TEXT,
    "phone" TEXT,
    "marketingConsent" BOOLEAN NOT NULL DEFAULT false,
    "notes" TEXT,
    "priceListId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Customer_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "InventoryBalance" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "locationId" TEXT NOT NULL,
    "productVariantId" TEXT NOT NULL,
    "onHand" DECIMAL(18,4) NOT NULL DEFAULT 0,
    "reserved" DECIMAL(18,4) NOT NULL DEFAULT 0,
    "committed" DECIMAL(18,4) NOT NULL DEFAULT 0,
    "quarantined" DECIMAL(18,4) NOT NULL DEFAULT 0,
    "damaged" DECIMAL(18,4) NOT NULL DEFAULT 0,
    "expired" DECIMAL(18,4) NOT NULL DEFAULT 0,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "InventoryBalance_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "InventoryLedger" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "locationId" TEXT NOT NULL,
    "productVariantId" TEXT NOT NULL,
    "movementType" "InventoryMovementType" NOT NULL,
    "deltaQty" DECIMAL(18,4) NOT NULL,
    "referenceType" TEXT NOT NULL,
    "referenceId" TEXT NOT NULL,
    "reason" TEXT,
    "performedBy" TEXT,
    "deviceId" TEXT,
    "metadata" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "InventoryLedger_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "InventoryCostLayer" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "locationId" TEXT NOT NULL,
    "productVariantId" TEXT NOT NULL,
    "sourceType" TEXT NOT NULL,
    "sourceId" TEXT NOT NULL,
    "quantityReceived" DECIMAL(18,4) NOT NULL,
    "quantityRemaining" DECIMAL(18,4) NOT NULL,
    "unitCost" DECIMAL(18,4) NOT NULL,
    "receivedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "InventoryCostLayer_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "InventoryReservation" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "locationId" TEXT NOT NULL,
    "productVariantId" TEXT NOT NULL,
    "referenceType" TEXT NOT NULL,
    "referenceId" TEXT NOT NULL,
    "quantity" DECIMAL(18,4) NOT NULL,
    "status" "ReservationStatus" NOT NULL DEFAULT 'ACTIVE',
    "expiresAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "InventoryReservation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Sale" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "locationId" TEXT NOT NULL,
    "registerId" TEXT,
    "registerSessionId" TEXT,
    "deviceId" TEXT,
    "clientReference" TEXT,
    "offline" BOOLEAN NOT NULL DEFAULT false,
    "customerId" TEXT,
    "number" TEXT NOT NULL,
    "status" "SaleStatus" NOT NULL DEFAULT 'OPEN',
    "currency" TEXT NOT NULL,
    "subtotal" DECIMAL(18,4) NOT NULL,
    "discount" DECIMAL(18,4) NOT NULL DEFAULT 0,
    "tax" DECIMAL(18,4) NOT NULL DEFAULT 0,
    "total" DECIMAL(18,4) NOT NULL,
    "amountPaid" DECIMAL(18,4) NOT NULL DEFAULT 0,
    "changeDue" DECIMAL(18,4) NOT NULL DEFAULT 0,
    "createdBy" TEXT NOT NULL,
    "salespersonUserId" TEXT,
    "completedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Sale_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SaleLine" (
    "id" TEXT NOT NULL,
    "saleId" TEXT NOT NULL,
    "productVariantId" TEXT NOT NULL,
    "sku" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "quantity" DECIMAL(18,4) NOT NULL,
    "unitPrice" DECIMAL(18,4) NOT NULL,
    "discount" DECIMAL(18,4) NOT NULL DEFAULT 0,
    "taxRate" DECIMAL(7,6) NOT NULL DEFAULT 0,
    "taxAmount" DECIMAL(18,4) NOT NULL DEFAULT 0,
    "lineTotal" DECIMAL(18,4) NOT NULL,
    "unitCostSnapshot" DECIMAL(18,4) NOT NULL DEFAULT 0,

    CONSTRAINT "SaleLine_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Payment" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "saleId" TEXT,
    "commerceOrderId" TEXT,
    "registerSessionId" TEXT,
    "method" "PaymentMethod" NOT NULL,
    "status" "PaymentStatus" NOT NULL DEFAULT 'PENDING',
    "amount" DECIMAL(18,4) NOT NULL,
    "provider" TEXT,
    "providerRef" TEXT,
    "metadata" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Payment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SaleReturn" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "saleId" TEXT NOT NULL,
    "number" TEXT NOT NULL,
    "status" "ReturnStatus" NOT NULL DEFAULT 'COMPLETED',
    "reason" TEXT NOT NULL,
    "total" DECIMAL(18,4) NOT NULL,
    "createdBy" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SaleReturn_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SaleReturnLine" (
    "id" TEXT NOT NULL,
    "saleReturnId" TEXT NOT NULL,
    "saleLineId" TEXT NOT NULL,
    "productVariantId" TEXT NOT NULL,
    "quantity" DECIMAL(18,4) NOT NULL,
    "refundAmount" DECIMAL(18,4) NOT NULL,
    "unitCostSnapshot" DECIMAL(18,4) NOT NULL,
    "restocked" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "SaleReturnLine_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Refund" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "saleReturnId" TEXT NOT NULL,
    "method" "PaymentMethod" NOT NULL,
    "amount" DECIMAL(18,4) NOT NULL,
    "provider" TEXT,
    "providerRef" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Refund_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SaleReturnLotAllocation" (
    "id" TEXT NOT NULL,
    "saleReturnLineId" TEXT NOT NULL,
    "lotId" TEXT NOT NULL,
    "quantity" DECIMAL(18,4) NOT NULL,

    CONSTRAINT "SaleReturnLotAllocation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SaleReturnSerial" (
    "id" TEXT NOT NULL,
    "saleReturnLineId" TEXT NOT NULL,
    "serialId" TEXT NOT NULL,

    CONSTRAINT "SaleReturnSerial_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StockTransfer" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "number" TEXT NOT NULL,
    "fromLocationId" TEXT NOT NULL,
    "toLocationId" TEXT NOT NULL,
    "status" "StockTransferStatus" NOT NULL DEFAULT 'REQUESTED',
    "notes" TEXT,
    "createdBy" TEXT NOT NULL,
    "approvedBy" TEXT,
    "dispatchedBy" TEXT,
    "receivedBy" TEXT,
    "dispatchedAt" TIMESTAMP(3),
    "receivedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "StockTransfer_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StockTransferLine" (
    "id" TEXT NOT NULL,
    "stockTransferId" TEXT NOT NULL,
    "productVariantId" TEXT NOT NULL,
    "quantity" DECIMAL(18,4) NOT NULL,
    "unitCostSnapshot" DECIMAL(18,4),

    CONSTRAINT "StockTransferLine_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Supplier" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'XCD',
    "quotedLeadDays" INTEGER,
    "email" TEXT,
    "phone" TEXT,
    "paymentTerms" TEXT,
    "minimumOrderValue" DECIMAL(18,4),
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Supplier_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SupplierProduct" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "supplierId" TEXT NOT NULL,
    "productVariantId" TEXT NOT NULL,
    "supplierSku" TEXT,
    "unitCost" DECIMAL(18,4) NOT NULL,
    "minimumOrderQty" DECIMAL(18,4) NOT NULL DEFAULT 0,
    "casePack" DECIMAL(18,4) NOT NULL DEFAULT 1,
    "preferred" BOOLEAN NOT NULL DEFAULT false,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SupplierProduct_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PurchaseOrder" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "supplierId" TEXT NOT NULL,
    "shipToLocationId" TEXT NOT NULL,
    "number" TEXT NOT NULL,
    "status" "PurchaseOrderStatus" NOT NULL DEFAULT 'DRAFT',
    "orderDate" TIMESTAMP(3),
    "expectedAt" TIMESTAMP(3),
    "currency" TEXT NOT NULL,
    "notes" TEXT,
    "createdBy" TEXT NOT NULL,
    "approvedBy" TEXT,
    "approvedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PurchaseOrder_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PurchaseOrderLine" (
    "id" TEXT NOT NULL,
    "purchaseOrderId" TEXT NOT NULL,
    "productVariantId" TEXT NOT NULL,
    "orderedQty" DECIMAL(18,4) NOT NULL,
    "receivedQty" DECIMAL(18,4) NOT NULL DEFAULT 0,
    "unitCost" DECIMAL(18,4) NOT NULL,

    CONSTRAINT "PurchaseOrderLine_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "GoodsReceipt" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "purchaseOrderId" TEXT NOT NULL,
    "locationId" TEXT NOT NULL,
    "number" TEXT NOT NULL,
    "receivedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "receivedBy" TEXT NOT NULL,
    "additionalCosts" DECIMAL(18,4) NOT NULL DEFAULT 0,
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "GoodsReceipt_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "GoodsReceiptLine" (
    "id" TEXT NOT NULL,
    "goodsReceiptId" TEXT NOT NULL,
    "purchaseOrderLineId" TEXT NOT NULL,
    "productVariantId" TEXT NOT NULL,
    "receivedQty" DECIMAL(18,4) NOT NULL,
    "unitCost" DECIMAL(18,4) NOT NULL,
    "allocatedLandedCost" DECIMAL(18,4) NOT NULL DEFAULT 0,
    "landedUnitCost" DECIMAL(18,4) NOT NULL,

    CONSTRAINT "GoodsReceiptLine_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Shipment" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "purchaseOrderId" TEXT,
    "trackingNumber" TEXT,
    "carrier" TEXT,
    "status" "ShipmentStatus" NOT NULL DEFAULT 'PLANNED',
    "origin" TEXT,
    "destination" TEXT,
    "etd" TIMESTAMP(3),
    "eta" TIMESTAMP(3),
    "actualDeparture" TIMESTAMP(3),
    "actualArrival" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Shipment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ShipmentLine" (
    "id" TEXT NOT NULL,
    "shipmentId" TEXT NOT NULL,
    "purchaseOrderLineId" TEXT NOT NULL,
    "productVariantId" TEXT NOT NULL,
    "quantity" DECIMAL(18,4) NOT NULL,

    CONSTRAINT "ShipmentLine_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ShipmentEvent" (
    "id" TEXT NOT NULL,
    "shipmentId" TEXT NOT NULL,
    "status" "ShipmentStatus" NOT NULL,
    "occurredAt" TIMESTAMP(3) NOT NULL,
    "notes" TEXT,
    "source" TEXT,

    CONSTRAINT "ShipmentEvent_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ReplenishmentPolicy" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "locationId" TEXT NOT NULL,
    "productVariantId" TEXT NOT NULL,
    "preferredSupplierId" TEXT,
    "safetyStockQty" DECIMAL(18,4) NOT NULL DEFAULT 0,
    "safetyDays" INTEGER,
    "serviceLevel" DECIMAL(6,5),
    "reviewPeriodDays" INTEGER NOT NULL DEFAULT 14,
    "manualLeadDays" INTEGER,
    "manualDailyDemand" DECIMAL(18,4),
    "enabled" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ReplenishmentPolicy_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ReorderRecommendation" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "locationId" TEXT NOT NULL,
    "productVariantId" TEXT NOT NULL,
    "supplierId" TEXT,
    "status" "ReplenishmentStatus" NOT NULL,
    "inventoryPosition" DECIMAL(18,4) NOT NULL,
    "forecastDailyDemand" DECIMAL(18,4) NOT NULL,
    "planningLeadDays" INTEGER NOT NULL,
    "safetyStockQty" DECIMAL(18,4) NOT NULL,
    "reorderPoint" DECIMAL(18,4) NOT NULL,
    "recommendedQty" DECIMAL(18,4) NOT NULL,
    "projectedStockoutAt" TIMESTAMP(3),
    "safetyStockBreachAt" TIMESTAMP(3),
    "orderByAt" TIMESTAMP(3),
    "explanation" JSONB NOT NULL,
    "calculatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ReorderRecommendation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Notification" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "userId" TEXT,
    "type" TEXT NOT NULL,
    "severity" "NotificationSeverity" NOT NULL,
    "title" TEXT NOT NULL,
    "message" TEXT NOT NULL,
    "actionUrl" TEXT,
    "dedupeKey" TEXT NOT NULL,
    "readAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Notification_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TeamProfile" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "membershipId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "employeeCode" TEXT NOT NULL,
    "displayName" TEXT NOT NULL,
    "pinSalt" TEXT,
    "pinHash" TEXT,
    "hourlyRate" DECIMAL(18,4),
    "commissionBasis" "CommissionBasis",
    "commissionRate" DECIMAL(8,6),
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "TeamProfile_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Shift" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "locationId" TEXT NOT NULL,
    "status" "ShiftStatus" NOT NULL DEFAULT 'OPEN',
    "clockedInAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "clockedOutAt" TIMESTAMP(3),
    "breakMinutes" INTEGER NOT NULL DEFAULT 0,
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Shift_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CommissionEntry" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "saleId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "basis" "CommissionBasis" NOT NULL,
    "baseAmount" DECIMAL(18,4) NOT NULL,
    "rate" DECIMAL(8,6) NOT NULL,
    "amount" DECIMAL(18,4) NOT NULL,
    "reversedAmount" DECIMAL(18,4) NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CommissionEntry_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Fulfillment" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "locationId" TEXT NOT NULL,
    "saleId" TEXT,
    "commerceOrderId" TEXT,
    "number" TEXT NOT NULL,
    "method" "FulfillmentMethod" NOT NULL,
    "status" "FulfillmentStatus" NOT NULL DEFAULT 'PENDING',
    "recipientName" TEXT,
    "recipientPhone" TEXT,
    "deliveryAddress" JSONB,
    "driverUserId" TEXT,
    "trackingNumber" TEXT,
    "promisedAt" TIMESTAMP(3),
    "dispatchedAt" TIMESTAMP(3),
    "deliveredAt" TIMESTAMP(3),
    "proof" JSONB,
    "notes" TEXT,
    "createdBy" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Fulfillment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "FulfillmentLine" (
    "id" TEXT NOT NULL,
    "fulfillmentId" TEXT NOT NULL,
    "saleLineId" TEXT,
    "commerceOrderLineId" TEXT,
    "productVariantId" TEXT NOT NULL,
    "quantity" DECIMAL(18,4) NOT NULL,
    "pickedQty" DECIMAL(18,4) NOT NULL DEFAULT 0,

    CONSTRAINT "FulfillmentLine_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "FulfillmentEvent" (
    "id" TEXT NOT NULL,
    "fulfillmentId" TEXT NOT NULL,
    "status" "FulfillmentStatus" NOT NULL,
    "notes" TEXT,
    "actorUserId" TEXT,
    "occurredAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "FulfillmentEvent_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "InventoryLot" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "locationId" TEXT NOT NULL,
    "productVariantId" TEXT NOT NULL,
    "goodsReceiptLineId" TEXT,
    "lotNumber" TEXT NOT NULL,
    "expiryDate" TIMESTAMP(3),
    "quantityOnHand" DECIMAL(18,4) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "InventoryLot_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "InventorySerial" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "locationId" TEXT NOT NULL,
    "productVariantId" TEXT NOT NULL,
    "goodsReceiptLineId" TEXT,
    "serialNumber" TEXT NOT NULL,
    "status" "SerialStatus" NOT NULL DEFAULT 'AVAILABLE',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "InventorySerial_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SaleLineLotAllocation" (
    "id" TEXT NOT NULL,
    "saleLineId" TEXT NOT NULL,
    "lotId" TEXT NOT NULL,
    "productVariantId" TEXT NOT NULL,
    "quantity" DECIMAL(18,4) NOT NULL,

    CONSTRAINT "SaleLineLotAllocation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SaleLineSerial" (
    "id" TEXT NOT NULL,
    "saleLineId" TEXT NOT NULL,
    "serialId" TEXT NOT NULL,
    "productVariantId" TEXT NOT NULL,

    CONSTRAINT "SaleLineSerial_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StockTransferLotAllocation" (
    "id" TEXT NOT NULL,
    "stockTransferLineId" TEXT NOT NULL,
    "lotId" TEXT NOT NULL,
    "quantity" DECIMAL(18,4) NOT NULL,

    CONSTRAINT "StockTransferLotAllocation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StockTransferSerialAllocation" (
    "id" TEXT NOT NULL,
    "stockTransferLineId" TEXT NOT NULL,
    "serialId" TEXT NOT NULL,

    CONSTRAINT "StockTransferSerialAllocation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CommerceOrder" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "locationId" TEXT NOT NULL,
    "customerId" TEXT,
    "number" TEXT NOT NULL,
    "type" "CommerceOrderType" NOT NULL,
    "status" "CommerceOrderStatus" NOT NULL DEFAULT 'DRAFT',
    "currency" TEXT NOT NULL,
    "subtotal" DECIMAL(18,4) NOT NULL,
    "discount" DECIMAL(18,4) NOT NULL DEFAULT 0,
    "tax" DECIMAL(18,4) NOT NULL DEFAULT 0,
    "total" DECIMAL(18,4) NOT NULL,
    "amountPaid" DECIMAL(18,4) NOT NULL DEFAULT 0,
    "depositRequired" DECIMAL(18,4),
    "validUntil" TIMESTAMP(3),
    "dueAt" TIMESTAMP(3),
    "notes" TEXT,
    "createdBy" TEXT NOT NULL,
    "acceptedAt" TIMESTAMP(3),
    "completedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CommerceOrder_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CommerceOrderLine" (
    "id" TEXT NOT NULL,
    "commerceOrderId" TEXT NOT NULL,
    "productVariantId" TEXT NOT NULL,
    "sku" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "quantity" DECIMAL(18,4) NOT NULL,
    "unitPrice" DECIMAL(18,4) NOT NULL,
    "discount" DECIMAL(18,4) NOT NULL DEFAULT 0,
    "taxRate" DECIMAL(7,6) NOT NULL DEFAULT 0,
    "taxAmount" DECIMAL(18,4) NOT NULL DEFAULT 0,
    "lineTotal" DECIMAL(18,4) NOT NULL,
    "reservedQty" DECIMAL(18,4) NOT NULL DEFAULT 0,

    CONSTRAINT "CommerceOrderLine_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Device" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "locationId" TEXT NOT NULL,
    "registerId" TEXT,
    "name" TEXT NOT NULL,
    "deviceKey" TEXT NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "lastSeenAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Device_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CatalogRevision" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "revision" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CatalogRevision_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CatalogSnapshotItem" (
    "id" TEXT NOT NULL,
    "catalogRevisionId" TEXT NOT NULL,
    "productVariantId" TEXT NOT NULL,
    "sku" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "sellPrice" DECIMAL(18,4) NOT NULL,
    "taxRate" DECIMAL(7,6) NOT NULL,
    "active" BOOLEAN NOT NULL,

    CONSTRAINT "CatalogSnapshotItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "InventoryException" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "locationId" TEXT NOT NULL,
    "saleId" TEXT NOT NULL,
    "productVariantId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "quantityShort" DECIMAL(18,4) NOT NULL,
    "resolvedAt" TIMESTAMP(3),
    "resolvedBy" TEXT,
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "InventoryException_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PaymentProviderConnection" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "providerType" TEXT NOT NULL,
    "encryptedConfig" TEXT NOT NULL,
    "encryptedWebhookSecret" TEXT,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PaymentProviderConnection_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PaymentIntent" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "connectionId" TEXT NOT NULL,
    "saleId" TEXT,
    "paymentId" TEXT,
    "idempotencyKey" TEXT NOT NULL,
    "status" "PaymentIntentStatus" NOT NULL DEFAULT 'CREATED',
    "amount" DECIMAL(18,4) NOT NULL,
    "currency" TEXT NOT NULL,
    "providerRef" TEXT,
    "clientSecretRef" TEXT,
    "failureCode" TEXT,
    "failureMessage" TEXT,
    "metadata" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PaymentIntent_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PaymentWebhookEvent" (
    "id" TEXT NOT NULL,
    "connectionId" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "eventType" TEXT NOT NULL,
    "payload" JSONB NOT NULL,
    "processedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PaymentWebhookEvent_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StoreCreditAccount" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "customerId" TEXT NOT NULL,
    "balance" DECIMAL(18,4) NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "StoreCreditAccount_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StoreCreditTransaction" (
    "id" TEXT NOT NULL,
    "accountId" TEXT NOT NULL,
    "type" "ValueTransactionType" NOT NULL,
    "amount" DECIMAL(18,4) NOT NULL,
    "referenceType" TEXT NOT NULL,
    "referenceId" TEXT NOT NULL,
    "notes" TEXT,
    "createdBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "StoreCreditTransaction_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "GiftCard" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "codeHash" TEXT NOT NULL,
    "last4" TEXT NOT NULL,
    "balance" DECIMAL(18,4) NOT NULL DEFAULT 0,
    "initialValue" DECIMAL(18,4) NOT NULL,
    "status" "GiftCardStatus" NOT NULL DEFAULT 'ACTIVE',
    "expiresAt" TIMESTAMP(3),
    "createdBy" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "GiftCard_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "GiftCardTransaction" (
    "id" TEXT NOT NULL,
    "giftCardId" TEXT NOT NULL,
    "type" "ValueTransactionType" NOT NULL,
    "amount" DECIMAL(18,4) NOT NULL,
    "referenceType" TEXT NOT NULL,
    "referenceId" TEXT NOT NULL,
    "createdBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "GiftCardTransaction_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "LoyaltyProgram" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT false,
    "earnPointsPerCurrency" DECIMAL(12,4) NOT NULL DEFAULT 1,
    "redemptionValue" DECIMAL(12,6) NOT NULL DEFAULT 0.01,
    "minimumRedeemPoints" INTEGER NOT NULL DEFAULT 100,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "LoyaltyProgram_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "LoyaltyAccount" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "customerId" TEXT NOT NULL,
    "points" INTEGER NOT NULL DEFAULT 0,
    "lifetimeEarned" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "LoyaltyAccount_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "LoyaltyTransaction" (
    "id" TEXT NOT NULL,
    "accountId" TEXT NOT NULL,
    "delta" INTEGER NOT NULL,
    "referenceType" TEXT NOT NULL,
    "referenceId" TEXT NOT NULL,
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "LoyaltyTransaction_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PriceList" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "currency" TEXT NOT NULL,
    "priority" INTEGER NOT NULL DEFAULT 0,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "startsAt" TIMESTAMP(3),
    "endsAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PriceList_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PriceListItem" (
    "id" TEXT NOT NULL,
    "priceListId" TEXT NOT NULL,
    "productVariantId" TEXT NOT NULL,
    "price" DECIMAL(18,4) NOT NULL,

    CONSTRAINT "PriceListItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Promotion" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "code" TEXT,
    "type" "PromotionType" NOT NULL,
    "value" DECIMAL(18,4) NOT NULL,
    "minimumSubtotal" DECIMAL(18,4),
    "maximumDiscount" DECIMAL(18,4),
    "appliesToAll" BOOLEAN NOT NULL DEFAULT false,
    "stackable" BOOLEAN NOT NULL DEFAULT false,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "startsAt" TIMESTAMP(3),
    "endsAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Promotion_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PromotionProduct" (
    "id" TEXT NOT NULL,
    "promotionId" TEXT NOT NULL,
    "productVariantId" TEXT NOT NULL,

    CONSTRAINT "PromotionProduct_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SaleAppliedPromotion" (
    "id" TEXT NOT NULL,
    "saleId" TEXT NOT NULL,
    "promotionId" TEXT NOT NULL,
    "discount" DECIMAL(18,4) NOT NULL,

    CONSTRAINT "SaleAppliedPromotion_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StockCount" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "locationId" TEXT NOT NULL,
    "number" TEXT NOT NULL,
    "type" "StockCountType" NOT NULL,
    "status" "StockCountStatus" NOT NULL DEFAULT 'DRAFT',
    "blind" BOOLEAN NOT NULL DEFAULT false,
    "notes" TEXT,
    "createdBy" TEXT NOT NULL,
    "submittedBy" TEXT,
    "completedBy" TEXT,
    "startedAt" TIMESTAMP(3),
    "submittedAt" TIMESTAMP(3),
    "completedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "StockCount_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StockCountLine" (
    "id" TEXT NOT NULL,
    "stockCountId" TEXT NOT NULL,
    "productVariantId" TEXT NOT NULL,
    "expectedQty" DECIMAL(18,4) NOT NULL,
    "countedQty" DECIMAL(18,4),
    "varianceQty" DECIMAL(18,4),
    "countedBy" TEXT,
    "countedAt" TIMESTAMP(3),
    "notes" TEXT,

    CONSTRAINT "StockCountLine_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RegisterSession" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "registerId" TEXT NOT NULL,
    "locationId" TEXT NOT NULL,
    "status" "RegisterSessionStatus" NOT NULL DEFAULT 'OPEN',
    "openedBy" TEXT NOT NULL,
    "openingFloat" DECIMAL(18,4) NOT NULL DEFAULT 0,
    "openedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "closedBy" TEXT,
    "closedAt" TIMESTAMP(3),
    "closingCash" DECIMAL(18,4),
    "expectedCash" DECIMAL(18,4),
    "cashVariance" DECIMAL(18,4),
    "closingNotes" TEXT,
    "denominationCount" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "RegisterSession_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CashMovement" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "registerSessionId" TEXT NOT NULL,
    "type" "CashMovementType" NOT NULL,
    "amount" DECIMAL(18,4) NOT NULL,
    "reason" TEXT NOT NULL,
    "performedBy" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "CashMovement_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "IntegrationEndpoint" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "targetType" TEXT NOT NULL,
    "url" TEXT NOT NULL,
    "eventTypes" TEXT[],
    "encryptedSecret" TEXT NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "IntegrationEndpoint_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OutboxDelivery" (
    "id" TEXT NOT NULL,
    "outboxEventId" TEXT NOT NULL,
    "endpointId" TEXT NOT NULL,
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "nextAttemptAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deliveredAt" TIMESTAMP(3),
    "responseCode" INTEGER,
    "lastError" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "OutboxDelivery_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AuditEvent" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "actorUserId" TEXT,
    "action" TEXT NOT NULL,
    "resourceType" TEXT NOT NULL,
    "resourceId" TEXT,
    "before" JSONB,
    "after" JSONB,
    "ipAddress" TEXT,
    "deviceId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AuditEvent_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OutboxEvent" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "eventType" TEXT NOT NULL,
    "aggregateType" TEXT NOT NULL,
    "aggregateId" TEXT NOT NULL,
    "payload" JSONB NOT NULL,
    "publishedAt" TIMESTAMP(3),
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "lastError" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "OutboxEvent_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Tenant_slug_key" ON "Tenant"("slug");

-- CreateIndex
CREATE INDEX "TenantRole_tenantId_idx" ON "TenantRole"("tenantId");

-- CreateIndex
CREATE UNIQUE INDEX "TenantRole_tenantId_key_key" ON "TenantRole"("tenantId", "key");

-- CreateIndex
CREATE INDEX "RolePermission_permission_idx" ON "RolePermission"("permission");

-- CreateIndex
CREATE UNIQUE INDEX "RolePermission_roleId_permission_key" ON "RolePermission"("roleId", "permission");

-- CreateIndex
CREATE INDEX "Membership_userId_active_idx" ON "Membership"("userId", "active");

-- CreateIndex
CREATE UNIQUE INDEX "Membership_tenantId_userId_key" ON "Membership"("tenantId", "userId");

-- CreateIndex
CREATE INDEX "UserLocationAccess_locationId_idx" ON "UserLocationAccess"("locationId");

-- CreateIndex
CREATE UNIQUE INDEX "UserLocationAccess_membershipId_locationId_key" ON "UserLocationAccess"("membershipId", "locationId");

-- CreateIndex
CREATE INDEX "Location_tenantId_active_idx" ON "Location"("tenantId", "active");

-- CreateIndex
CREATE UNIQUE INDEX "Location_tenantId_code_key" ON "Location"("tenantId", "code");

-- CreateIndex
CREATE INDEX "Register_tenantId_locationId_active_idx" ON "Register"("tenantId", "locationId", "active");

-- CreateIndex
CREATE UNIQUE INDEX "Register_tenantId_code_key" ON "Register"("tenantId", "code");

-- CreateIndex
CREATE INDEX "Product_tenantId_active_idx" ON "Product"("tenantId", "active");

-- CreateIndex
CREATE INDEX "Product_tenantId_category_idx" ON "Product"("tenantId", "category");

-- CreateIndex
CREATE INDEX "ProductVariant_productId_active_idx" ON "ProductVariant"("productId", "active");

-- CreateIndex
CREATE UNIQUE INDEX "ProductVariant_tenantId_sku_key" ON "ProductVariant"("tenantId", "sku");

-- CreateIndex
CREATE UNIQUE INDEX "ProductVariant_tenantId_barcode_key" ON "ProductVariant"("tenantId", "barcode");

-- CreateIndex
CREATE INDEX "Customer_tenantId_name_idx" ON "Customer"("tenantId", "name");

-- CreateIndex
CREATE INDEX "Customer_tenantId_email_idx" ON "Customer"("tenantId", "email");

-- CreateIndex
CREATE INDEX "Customer_tenantId_phone_idx" ON "Customer"("tenantId", "phone");

-- CreateIndex
CREATE INDEX "InventoryBalance_tenantId_productVariantId_idx" ON "InventoryBalance"("tenantId", "productVariantId");

-- CreateIndex
CREATE UNIQUE INDEX "InventoryBalance_tenantId_locationId_productVariantId_key" ON "InventoryBalance"("tenantId", "locationId", "productVariantId");

-- CreateIndex
CREATE INDEX "InventoryLedger_tenantId_locationId_productVariantId_create_idx" ON "InventoryLedger"("tenantId", "locationId", "productVariantId", "createdAt");

-- CreateIndex
CREATE INDEX "InventoryLedger_tenantId_referenceType_referenceId_idx" ON "InventoryLedger"("tenantId", "referenceType", "referenceId");

-- CreateIndex
CREATE INDEX "InventoryCostLayer_tenantId_locationId_productVariantId_rec_idx" ON "InventoryCostLayer"("tenantId", "locationId", "productVariantId", "receivedAt");

-- CreateIndex
CREATE INDEX "InventoryCostLayer_tenantId_sourceType_sourceId_idx" ON "InventoryCostLayer"("tenantId", "sourceType", "sourceId");

-- CreateIndex
CREATE INDEX "InventoryReservation_tenantId_referenceType_referenceId_idx" ON "InventoryReservation"("tenantId", "referenceType", "referenceId");

-- CreateIndex
CREATE INDEX "InventoryReservation_tenantId_locationId_productVariantId_s_idx" ON "InventoryReservation"("tenantId", "locationId", "productVariantId", "status");

-- CreateIndex
CREATE INDEX "Sale_tenantId_locationId_createdAt_idx" ON "Sale"("tenantId", "locationId", "createdAt");

-- CreateIndex
CREATE INDEX "Sale_tenantId_customerId_createdAt_idx" ON "Sale"("tenantId", "customerId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "Sale_tenantId_number_key" ON "Sale"("tenantId", "number");

-- CreateIndex
CREATE UNIQUE INDEX "Sale_tenantId_clientReference_key" ON "Sale"("tenantId", "clientReference");

-- CreateIndex
CREATE INDEX "SaleLine_saleId_idx" ON "SaleLine"("saleId");

-- CreateIndex
CREATE INDEX "SaleLine_productVariantId_idx" ON "SaleLine"("productVariantId");

-- CreateIndex
CREATE INDEX "Payment_tenantId_saleId_idx" ON "Payment"("tenantId", "saleId");

-- CreateIndex
CREATE INDEX "Payment_tenantId_commerceOrderId_idx" ON "Payment"("tenantId", "commerceOrderId");

-- CreateIndex
CREATE INDEX "Payment_tenantId_registerSessionId_idx" ON "Payment"("tenantId", "registerSessionId");

-- CreateIndex
CREATE INDEX "Payment_tenantId_providerRef_idx" ON "Payment"("tenantId", "providerRef");

-- CreateIndex
CREATE INDEX "SaleReturn_tenantId_saleId_createdAt_idx" ON "SaleReturn"("tenantId", "saleId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "SaleReturn_tenantId_number_key" ON "SaleReturn"("tenantId", "number");

-- CreateIndex
CREATE INDEX "SaleReturnLine_saleReturnId_idx" ON "SaleReturnLine"("saleReturnId");

-- CreateIndex
CREATE INDEX "SaleReturnLine_saleLineId_idx" ON "SaleReturnLine"("saleLineId");

-- CreateIndex
CREATE INDEX "Refund_tenantId_saleReturnId_idx" ON "Refund"("tenantId", "saleReturnId");

-- CreateIndex
CREATE UNIQUE INDEX "SaleReturnLotAllocation_saleReturnLineId_lotId_key" ON "SaleReturnLotAllocation"("saleReturnLineId", "lotId");

-- CreateIndex
CREATE UNIQUE INDEX "SaleReturnSerial_saleReturnLineId_serialId_key" ON "SaleReturnSerial"("saleReturnLineId", "serialId");

-- CreateIndex
CREATE INDEX "StockTransfer_tenantId_status_createdAt_idx" ON "StockTransfer"("tenantId", "status", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "StockTransfer_tenantId_number_key" ON "StockTransfer"("tenantId", "number");

-- CreateIndex
CREATE INDEX "StockTransferLine_stockTransferId_idx" ON "StockTransferLine"("stockTransferId");

-- CreateIndex
CREATE INDEX "Supplier_tenantId_active_idx" ON "Supplier"("tenantId", "active");

-- CreateIndex
CREATE INDEX "SupplierProduct_tenantId_productVariantId_active_idx" ON "SupplierProduct"("tenantId", "productVariantId", "active");

-- CreateIndex
CREATE UNIQUE INDEX "SupplierProduct_supplierId_productVariantId_key" ON "SupplierProduct"("supplierId", "productVariantId");

-- CreateIndex
CREATE INDEX "PurchaseOrder_tenantId_status_idx" ON "PurchaseOrder"("tenantId", "status");

-- CreateIndex
CREATE INDEX "PurchaseOrder_tenantId_supplierId_createdAt_idx" ON "PurchaseOrder"("tenantId", "supplierId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "PurchaseOrder_tenantId_number_key" ON "PurchaseOrder"("tenantId", "number");

-- CreateIndex
CREATE INDEX "PurchaseOrderLine_purchaseOrderId_idx" ON "PurchaseOrderLine"("purchaseOrderId");

-- CreateIndex
CREATE INDEX "PurchaseOrderLine_productVariantId_idx" ON "PurchaseOrderLine"("productVariantId");

-- CreateIndex
CREATE INDEX "GoodsReceipt_tenantId_purchaseOrderId_receivedAt_idx" ON "GoodsReceipt"("tenantId", "purchaseOrderId", "receivedAt");

-- CreateIndex
CREATE UNIQUE INDEX "GoodsReceipt_tenantId_number_key" ON "GoodsReceipt"("tenantId", "number");

-- CreateIndex
CREATE INDEX "GoodsReceiptLine_goodsReceiptId_idx" ON "GoodsReceiptLine"("goodsReceiptId");

-- CreateIndex
CREATE INDEX "GoodsReceiptLine_purchaseOrderLineId_idx" ON "GoodsReceiptLine"("purchaseOrderLineId");

-- CreateIndex
CREATE INDEX "Shipment_tenantId_status_idx" ON "Shipment"("tenantId", "status");

-- CreateIndex
CREATE INDEX "Shipment_tenantId_trackingNumber_idx" ON "Shipment"("tenantId", "trackingNumber");

-- CreateIndex
CREATE INDEX "ShipmentLine_shipmentId_idx" ON "ShipmentLine"("shipmentId");

-- CreateIndex
CREATE INDEX "ShipmentEvent_shipmentId_occurredAt_idx" ON "ShipmentEvent"("shipmentId", "occurredAt");

-- CreateIndex
CREATE INDEX "ReplenishmentPolicy_tenantId_enabled_idx" ON "ReplenishmentPolicy"("tenantId", "enabled");

-- CreateIndex
CREATE UNIQUE INDEX "ReplenishmentPolicy_tenantId_locationId_productVariantId_key" ON "ReplenishmentPolicy"("tenantId", "locationId", "productVariantId");

-- CreateIndex
CREATE INDEX "ReorderRecommendation_tenantId_status_orderByAt_idx" ON "ReorderRecommendation"("tenantId", "status", "orderByAt");

-- CreateIndex
CREATE INDEX "ReorderRecommendation_tenantId_locationId_productVariantId__idx" ON "ReorderRecommendation"("tenantId", "locationId", "productVariantId", "calculatedAt");

-- CreateIndex
CREATE INDEX "Notification_tenantId_readAt_createdAt_idx" ON "Notification"("tenantId", "readAt", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "Notification_tenantId_dedupeKey_key" ON "Notification"("tenantId", "dedupeKey");

-- CreateIndex
CREATE UNIQUE INDEX "TeamProfile_membershipId_key" ON "TeamProfile"("membershipId");

-- CreateIndex
CREATE INDEX "TeamProfile_tenantId_active_idx" ON "TeamProfile"("tenantId", "active");

-- CreateIndex
CREATE UNIQUE INDEX "TeamProfile_tenantId_employeeCode_key" ON "TeamProfile"("tenantId", "employeeCode");

-- CreateIndex
CREATE UNIQUE INDEX "TeamProfile_tenantId_userId_key" ON "TeamProfile"("tenantId", "userId");

-- CreateIndex
CREATE INDEX "Shift_tenantId_userId_status_idx" ON "Shift"("tenantId", "userId", "status");

-- CreateIndex
CREATE INDEX "Shift_tenantId_locationId_clockedInAt_idx" ON "Shift"("tenantId", "locationId", "clockedInAt");

-- CreateIndex
CREATE INDEX "CommissionEntry_tenantId_userId_createdAt_idx" ON "CommissionEntry"("tenantId", "userId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "CommissionEntry_saleId_userId_key" ON "CommissionEntry"("saleId", "userId");

-- CreateIndex
CREATE INDEX "Fulfillment_tenantId_status_promisedAt_idx" ON "Fulfillment"("tenantId", "status", "promisedAt");

-- CreateIndex
CREATE INDEX "Fulfillment_tenantId_driverUserId_status_idx" ON "Fulfillment"("tenantId", "driverUserId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "Fulfillment_tenantId_number_key" ON "Fulfillment"("tenantId", "number");

-- CreateIndex
CREATE INDEX "FulfillmentLine_fulfillmentId_idx" ON "FulfillmentLine"("fulfillmentId");

-- CreateIndex
CREATE INDEX "FulfillmentEvent_fulfillmentId_occurredAt_idx" ON "FulfillmentEvent"("fulfillmentId", "occurredAt");

-- CreateIndex
CREATE INDEX "InventoryLot_tenantId_expiryDate_idx" ON "InventoryLot"("tenantId", "expiryDate");

-- CreateIndex
CREATE UNIQUE INDEX "InventoryLot_tenantId_locationId_productVariantId_lotNumber_key" ON "InventoryLot"("tenantId", "locationId", "productVariantId", "lotNumber");

-- CreateIndex
CREATE INDEX "InventorySerial_tenantId_locationId_productVariantId_status_idx" ON "InventorySerial"("tenantId", "locationId", "productVariantId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "InventorySerial_tenantId_serialNumber_key" ON "InventorySerial"("tenantId", "serialNumber");

-- CreateIndex
CREATE UNIQUE INDEX "SaleLineLotAllocation_saleLineId_lotId_key" ON "SaleLineLotAllocation"("saleLineId", "lotId");

-- CreateIndex
CREATE UNIQUE INDEX "SaleLineSerial_serialId_key" ON "SaleLineSerial"("serialId");

-- CreateIndex
CREATE UNIQUE INDEX "StockTransferLotAllocation_stockTransferLineId_lotId_key" ON "StockTransferLotAllocation"("stockTransferLineId", "lotId");

-- CreateIndex
CREATE UNIQUE INDEX "StockTransferSerialAllocation_stockTransferLineId_serialId_key" ON "StockTransferSerialAllocation"("stockTransferLineId", "serialId");

-- CreateIndex
CREATE INDEX "CommerceOrder_tenantId_status_createdAt_idx" ON "CommerceOrder"("tenantId", "status", "createdAt");

-- CreateIndex
CREATE INDEX "CommerceOrder_tenantId_customerId_createdAt_idx" ON "CommerceOrder"("tenantId", "customerId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "CommerceOrder_tenantId_number_key" ON "CommerceOrder"("tenantId", "number");

-- CreateIndex
CREATE INDEX "CommerceOrderLine_commerceOrderId_idx" ON "CommerceOrderLine"("commerceOrderId");

-- CreateIndex
CREATE INDEX "CommerceOrderLine_productVariantId_idx" ON "CommerceOrderLine"("productVariantId");

-- CreateIndex
CREATE INDEX "Device_tenantId_active_idx" ON "Device"("tenantId", "active");

-- CreateIndex
CREATE UNIQUE INDEX "Device_tenantId_deviceKey_key" ON "Device"("tenantId", "deviceKey");

-- CreateIndex
CREATE INDEX "CatalogRevision_tenantId_createdAt_idx" ON "CatalogRevision"("tenantId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "CatalogRevision_tenantId_revision_key" ON "CatalogRevision"("tenantId", "revision");

-- CreateIndex
CREATE UNIQUE INDEX "CatalogSnapshotItem_catalogRevisionId_productVariantId_key" ON "CatalogSnapshotItem"("catalogRevisionId", "productVariantId");

-- CreateIndex
CREATE INDEX "InventoryException_tenantId_resolvedAt_createdAt_idx" ON "InventoryException"("tenantId", "resolvedAt", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "InventoryException_tenantId_saleId_productVariantId_type_key" ON "InventoryException"("tenantId", "saleId", "productVariantId", "type");

-- CreateIndex
CREATE INDEX "PaymentProviderConnection_tenantId_active_idx" ON "PaymentProviderConnection"("tenantId", "active");

-- CreateIndex
CREATE UNIQUE INDEX "PaymentProviderConnection_tenantId_name_key" ON "PaymentProviderConnection"("tenantId", "name");

-- CreateIndex
CREATE UNIQUE INDEX "PaymentIntent_paymentId_key" ON "PaymentIntent"("paymentId");

-- CreateIndex
CREATE INDEX "PaymentIntent_tenantId_status_createdAt_idx" ON "PaymentIntent"("tenantId", "status", "createdAt");

-- CreateIndex
CREATE INDEX "PaymentIntent_connectionId_providerRef_idx" ON "PaymentIntent"("connectionId", "providerRef");

-- CreateIndex
CREATE UNIQUE INDEX "PaymentIntent_tenantId_idempotencyKey_key" ON "PaymentIntent"("tenantId", "idempotencyKey");

-- CreateIndex
CREATE UNIQUE INDEX "PaymentWebhookEvent_connectionId_eventId_key" ON "PaymentWebhookEvent"("connectionId", "eventId");

-- CreateIndex
CREATE UNIQUE INDEX "StoreCreditAccount_customerId_key" ON "StoreCreditAccount"("customerId");

-- CreateIndex
CREATE UNIQUE INDEX "StoreCreditAccount_tenantId_customerId_key" ON "StoreCreditAccount"("tenantId", "customerId");

-- CreateIndex
CREATE INDEX "StoreCreditTransaction_accountId_createdAt_idx" ON "StoreCreditTransaction"("accountId", "createdAt");

-- CreateIndex
CREATE INDEX "GiftCard_tenantId_status_idx" ON "GiftCard"("tenantId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "GiftCard_tenantId_codeHash_key" ON "GiftCard"("tenantId", "codeHash");

-- CreateIndex
CREATE INDEX "GiftCardTransaction_giftCardId_createdAt_idx" ON "GiftCardTransaction"("giftCardId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "LoyaltyProgram_tenantId_key" ON "LoyaltyProgram"("tenantId");

-- CreateIndex
CREATE UNIQUE INDEX "LoyaltyAccount_customerId_key" ON "LoyaltyAccount"("customerId");

-- CreateIndex
CREATE UNIQUE INDEX "LoyaltyAccount_tenantId_customerId_key" ON "LoyaltyAccount"("tenantId", "customerId");

-- CreateIndex
CREATE INDEX "LoyaltyTransaction_accountId_createdAt_idx" ON "LoyaltyTransaction"("accountId", "createdAt");

-- CreateIndex
CREATE INDEX "PriceList_tenantId_active_priority_idx" ON "PriceList"("tenantId", "active", "priority");

-- CreateIndex
CREATE INDEX "PriceListItem_productVariantId_idx" ON "PriceListItem"("productVariantId");

-- CreateIndex
CREATE UNIQUE INDEX "PriceListItem_priceListId_productVariantId_key" ON "PriceListItem"("priceListId", "productVariantId");

-- CreateIndex
CREATE INDEX "Promotion_tenantId_active_startsAt_endsAt_idx" ON "Promotion"("tenantId", "active", "startsAt", "endsAt");

-- CreateIndex
CREATE UNIQUE INDEX "Promotion_tenantId_code_key" ON "Promotion"("tenantId", "code");

-- CreateIndex
CREATE UNIQUE INDEX "PromotionProduct_promotionId_productVariantId_key" ON "PromotionProduct"("promotionId", "productVariantId");

-- CreateIndex
CREATE UNIQUE INDEX "SaleAppliedPromotion_saleId_promotionId_key" ON "SaleAppliedPromotion"("saleId", "promotionId");

-- CreateIndex
CREATE INDEX "StockCount_tenantId_locationId_status_idx" ON "StockCount"("tenantId", "locationId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "StockCount_tenantId_number_key" ON "StockCount"("tenantId", "number");

-- CreateIndex
CREATE INDEX "StockCountLine_productVariantId_idx" ON "StockCountLine"("productVariantId");

-- CreateIndex
CREATE UNIQUE INDEX "StockCountLine_stockCountId_productVariantId_key" ON "StockCountLine"("stockCountId", "productVariantId");

-- CreateIndex
CREATE INDEX "RegisterSession_tenantId_registerId_status_idx" ON "RegisterSession"("tenantId", "registerId", "status");

-- CreateIndex
CREATE INDEX "RegisterSession_tenantId_locationId_openedAt_idx" ON "RegisterSession"("tenantId", "locationId", "openedAt");

-- CreateIndex
CREATE INDEX "CashMovement_tenantId_registerSessionId_createdAt_idx" ON "CashMovement"("tenantId", "registerSessionId", "createdAt");

-- CreateIndex
CREATE INDEX "IntegrationEndpoint_tenantId_active_idx" ON "IntegrationEndpoint"("tenantId", "active");

-- CreateIndex
CREATE UNIQUE INDEX "IntegrationEndpoint_tenantId_name_key" ON "IntegrationEndpoint"("tenantId", "name");

-- CreateIndex
CREATE INDEX "OutboxDelivery_deliveredAt_nextAttemptAt_idx" ON "OutboxDelivery"("deliveredAt", "nextAttemptAt");

-- CreateIndex
CREATE UNIQUE INDEX "OutboxDelivery_outboxEventId_endpointId_key" ON "OutboxDelivery"("outboxEventId", "endpointId");

-- CreateIndex
CREATE INDEX "AuditEvent_tenantId_createdAt_idx" ON "AuditEvent"("tenantId", "createdAt");

-- CreateIndex
CREATE INDEX "AuditEvent_tenantId_resourceType_resourceId_idx" ON "AuditEvent"("tenantId", "resourceType", "resourceId");

-- CreateIndex
CREATE INDEX "OutboxEvent_publishedAt_createdAt_idx" ON "OutboxEvent"("publishedAt", "createdAt");

-- CreateIndex
CREATE INDEX "OutboxEvent_tenantId_eventType_createdAt_idx" ON "OutboxEvent"("tenantId", "eventType", "createdAt");

-- AddForeignKey
ALTER TABLE "TenantRole" ADD CONSTRAINT "TenantRole_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RolePermission" ADD CONSTRAINT "RolePermission_roleId_fkey" FOREIGN KEY ("roleId") REFERENCES "TenantRole"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Membership" ADD CONSTRAINT "Membership_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Membership" ADD CONSTRAINT "Membership_tenantId_roleKey_fkey" FOREIGN KEY ("tenantId", "roleKey") REFERENCES "TenantRole"("tenantId", "key") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserLocationAccess" ADD CONSTRAINT "UserLocationAccess_membershipId_fkey" FOREIGN KEY ("membershipId") REFERENCES "Membership"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserLocationAccess" ADD CONSTRAINT "UserLocationAccess_locationId_fkey" FOREIGN KEY ("locationId") REFERENCES "Location"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Location" ADD CONSTRAINT "Location_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Register" ADD CONSTRAINT "Register_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Register" ADD CONSTRAINT "Register_locationId_fkey" FOREIGN KEY ("locationId") REFERENCES "Location"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Product" ADD CONSTRAINT "Product_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProductVariant" ADD CONSTRAINT "ProductVariant_productId_fkey" FOREIGN KEY ("productId") REFERENCES "Product"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Customer" ADD CONSTRAINT "Customer_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Customer" ADD CONSTRAINT "Customer_priceListId_fkey" FOREIGN KEY ("priceListId") REFERENCES "PriceList"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InventoryBalance" ADD CONSTRAINT "InventoryBalance_locationId_fkey" FOREIGN KEY ("locationId") REFERENCES "Location"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InventoryBalance" ADD CONSTRAINT "InventoryBalance_productVariantId_fkey" FOREIGN KEY ("productVariantId") REFERENCES "ProductVariant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InventoryLedger" ADD CONSTRAINT "InventoryLedger_locationId_fkey" FOREIGN KEY ("locationId") REFERENCES "Location"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InventoryLedger" ADD CONSTRAINT "InventoryLedger_productVariantId_fkey" FOREIGN KEY ("productVariantId") REFERENCES "ProductVariant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InventoryCostLayer" ADD CONSTRAINT "InventoryCostLayer_locationId_fkey" FOREIGN KEY ("locationId") REFERENCES "Location"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InventoryCostLayer" ADD CONSTRAINT "InventoryCostLayer_productVariantId_fkey" FOREIGN KEY ("productVariantId") REFERENCES "ProductVariant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InventoryReservation" ADD CONSTRAINT "InventoryReservation_locationId_fkey" FOREIGN KEY ("locationId") REFERENCES "Location"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InventoryReservation" ADD CONSTRAINT "InventoryReservation_productVariantId_fkey" FOREIGN KEY ("productVariantId") REFERENCES "ProductVariant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Sale" ADD CONSTRAINT "Sale_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Sale" ADD CONSTRAINT "Sale_locationId_fkey" FOREIGN KEY ("locationId") REFERENCES "Location"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Sale" ADD CONSTRAINT "Sale_registerId_fkey" FOREIGN KEY ("registerId") REFERENCES "Register"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Sale" ADD CONSTRAINT "Sale_registerSessionId_fkey" FOREIGN KEY ("registerSessionId") REFERENCES "RegisterSession"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Sale" ADD CONSTRAINT "Sale_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "Customer"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Sale" ADD CONSTRAINT "Sale_deviceId_fkey" FOREIGN KEY ("deviceId") REFERENCES "Device"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SaleLine" ADD CONSTRAINT "SaleLine_saleId_fkey" FOREIGN KEY ("saleId") REFERENCES "Sale"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SaleLine" ADD CONSTRAINT "SaleLine_productVariantId_fkey" FOREIGN KEY ("productVariantId") REFERENCES "ProductVariant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_saleId_fkey" FOREIGN KEY ("saleId") REFERENCES "Sale"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_commerceOrderId_fkey" FOREIGN KEY ("commerceOrderId") REFERENCES "CommerceOrder"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_registerSessionId_fkey" FOREIGN KEY ("registerSessionId") REFERENCES "RegisterSession"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SaleReturn" ADD CONSTRAINT "SaleReturn_saleId_fkey" FOREIGN KEY ("saleId") REFERENCES "Sale"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SaleReturnLine" ADD CONSTRAINT "SaleReturnLine_saleReturnId_fkey" FOREIGN KEY ("saleReturnId") REFERENCES "SaleReturn"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SaleReturnLine" ADD CONSTRAINT "SaleReturnLine_saleLineId_fkey" FOREIGN KEY ("saleLineId") REFERENCES "SaleLine"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SaleReturnLine" ADD CONSTRAINT "SaleReturnLine_productVariantId_fkey" FOREIGN KEY ("productVariantId") REFERENCES "ProductVariant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Refund" ADD CONSTRAINT "Refund_saleReturnId_fkey" FOREIGN KEY ("saleReturnId") REFERENCES "SaleReturn"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SaleReturnLotAllocation" ADD CONSTRAINT "SaleReturnLotAllocation_saleReturnLineId_fkey" FOREIGN KEY ("saleReturnLineId") REFERENCES "SaleReturnLine"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SaleReturnLotAllocation" ADD CONSTRAINT "SaleReturnLotAllocation_lotId_fkey" FOREIGN KEY ("lotId") REFERENCES "InventoryLot"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SaleReturnSerial" ADD CONSTRAINT "SaleReturnSerial_saleReturnLineId_fkey" FOREIGN KEY ("saleReturnLineId") REFERENCES "SaleReturnLine"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SaleReturnSerial" ADD CONSTRAINT "SaleReturnSerial_serialId_fkey" FOREIGN KEY ("serialId") REFERENCES "InventorySerial"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StockTransfer" ADD CONSTRAINT "StockTransfer_fromLocationId_fkey" FOREIGN KEY ("fromLocationId") REFERENCES "Location"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StockTransfer" ADD CONSTRAINT "StockTransfer_toLocationId_fkey" FOREIGN KEY ("toLocationId") REFERENCES "Location"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StockTransferLine" ADD CONSTRAINT "StockTransferLine_stockTransferId_fkey" FOREIGN KEY ("stockTransferId") REFERENCES "StockTransfer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StockTransferLine" ADD CONSTRAINT "StockTransferLine_productVariantId_fkey" FOREIGN KEY ("productVariantId") REFERENCES "ProductVariant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Supplier" ADD CONSTRAINT "Supplier_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SupplierProduct" ADD CONSTRAINT "SupplierProduct_supplierId_fkey" FOREIGN KEY ("supplierId") REFERENCES "Supplier"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SupplierProduct" ADD CONSTRAINT "SupplierProduct_productVariantId_fkey" FOREIGN KEY ("productVariantId") REFERENCES "ProductVariant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PurchaseOrder" ADD CONSTRAINT "PurchaseOrder_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PurchaseOrder" ADD CONSTRAINT "PurchaseOrder_supplierId_fkey" FOREIGN KEY ("supplierId") REFERENCES "Supplier"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PurchaseOrder" ADD CONSTRAINT "PurchaseOrder_shipToLocationId_fkey" FOREIGN KEY ("shipToLocationId") REFERENCES "Location"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PurchaseOrderLine" ADD CONSTRAINT "PurchaseOrderLine_purchaseOrderId_fkey" FOREIGN KEY ("purchaseOrderId") REFERENCES "PurchaseOrder"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PurchaseOrderLine" ADD CONSTRAINT "PurchaseOrderLine_productVariantId_fkey" FOREIGN KEY ("productVariantId") REFERENCES "ProductVariant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GoodsReceipt" ADD CONSTRAINT "GoodsReceipt_purchaseOrderId_fkey" FOREIGN KEY ("purchaseOrderId") REFERENCES "PurchaseOrder"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GoodsReceipt" ADD CONSTRAINT "GoodsReceipt_locationId_fkey" FOREIGN KEY ("locationId") REFERENCES "Location"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GoodsReceiptLine" ADD CONSTRAINT "GoodsReceiptLine_goodsReceiptId_fkey" FOREIGN KEY ("goodsReceiptId") REFERENCES "GoodsReceipt"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GoodsReceiptLine" ADD CONSTRAINT "GoodsReceiptLine_purchaseOrderLineId_fkey" FOREIGN KEY ("purchaseOrderLineId") REFERENCES "PurchaseOrderLine"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GoodsReceiptLine" ADD CONSTRAINT "GoodsReceiptLine_productVariantId_fkey" FOREIGN KEY ("productVariantId") REFERENCES "ProductVariant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Shipment" ADD CONSTRAINT "Shipment_purchaseOrderId_fkey" FOREIGN KEY ("purchaseOrderId") REFERENCES "PurchaseOrder"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ShipmentLine" ADD CONSTRAINT "ShipmentLine_shipmentId_fkey" FOREIGN KEY ("shipmentId") REFERENCES "Shipment"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ShipmentLine" ADD CONSTRAINT "ShipmentLine_purchaseOrderLineId_fkey" FOREIGN KEY ("purchaseOrderLineId") REFERENCES "PurchaseOrderLine"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ShipmentLine" ADD CONSTRAINT "ShipmentLine_productVariantId_fkey" FOREIGN KEY ("productVariantId") REFERENCES "ProductVariant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ShipmentEvent" ADD CONSTRAINT "ShipmentEvent_shipmentId_fkey" FOREIGN KEY ("shipmentId") REFERENCES "Shipment"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ReplenishmentPolicy" ADD CONSTRAINT "ReplenishmentPolicy_productVariantId_fkey" FOREIGN KEY ("productVariantId") REFERENCES "ProductVariant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TeamProfile" ADD CONSTRAINT "TeamProfile_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TeamProfile" ADD CONSTRAINT "TeamProfile_membershipId_fkey" FOREIGN KEY ("membershipId") REFERENCES "Membership"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Shift" ADD CONSTRAINT "Shift_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Shift" ADD CONSTRAINT "Shift_locationId_fkey" FOREIGN KEY ("locationId") REFERENCES "Location"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CommissionEntry" ADD CONSTRAINT "CommissionEntry_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CommissionEntry" ADD CONSTRAINT "CommissionEntry_saleId_fkey" FOREIGN KEY ("saleId") REFERENCES "Sale"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Fulfillment" ADD CONSTRAINT "Fulfillment_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Fulfillment" ADD CONSTRAINT "Fulfillment_locationId_fkey" FOREIGN KEY ("locationId") REFERENCES "Location"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Fulfillment" ADD CONSTRAINT "Fulfillment_saleId_fkey" FOREIGN KEY ("saleId") REFERENCES "Sale"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Fulfillment" ADD CONSTRAINT "Fulfillment_commerceOrderId_fkey" FOREIGN KEY ("commerceOrderId") REFERENCES "CommerceOrder"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "FulfillmentLine" ADD CONSTRAINT "FulfillmentLine_fulfillmentId_fkey" FOREIGN KEY ("fulfillmentId") REFERENCES "Fulfillment"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "FulfillmentLine" ADD CONSTRAINT "FulfillmentLine_saleLineId_fkey" FOREIGN KEY ("saleLineId") REFERENCES "SaleLine"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "FulfillmentLine" ADD CONSTRAINT "FulfillmentLine_commerceOrderLineId_fkey" FOREIGN KEY ("commerceOrderLineId") REFERENCES "CommerceOrderLine"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "FulfillmentEvent" ADD CONSTRAINT "FulfillmentEvent_fulfillmentId_fkey" FOREIGN KEY ("fulfillmentId") REFERENCES "Fulfillment"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InventoryLot" ADD CONSTRAINT "InventoryLot_locationId_fkey" FOREIGN KEY ("locationId") REFERENCES "Location"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InventoryLot" ADD CONSTRAINT "InventoryLot_productVariantId_fkey" FOREIGN KEY ("productVariantId") REFERENCES "ProductVariant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InventoryLot" ADD CONSTRAINT "InventoryLot_goodsReceiptLineId_fkey" FOREIGN KEY ("goodsReceiptLineId") REFERENCES "GoodsReceiptLine"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InventorySerial" ADD CONSTRAINT "InventorySerial_locationId_fkey" FOREIGN KEY ("locationId") REFERENCES "Location"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InventorySerial" ADD CONSTRAINT "InventorySerial_productVariantId_fkey" FOREIGN KEY ("productVariantId") REFERENCES "ProductVariant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InventorySerial" ADD CONSTRAINT "InventorySerial_goodsReceiptLineId_fkey" FOREIGN KEY ("goodsReceiptLineId") REFERENCES "GoodsReceiptLine"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SaleLineLotAllocation" ADD CONSTRAINT "SaleLineLotAllocation_saleLineId_fkey" FOREIGN KEY ("saleLineId") REFERENCES "SaleLine"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SaleLineLotAllocation" ADD CONSTRAINT "SaleLineLotAllocation_lotId_fkey" FOREIGN KEY ("lotId") REFERENCES "InventoryLot"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SaleLineLotAllocation" ADD CONSTRAINT "SaleLineLotAllocation_productVariantId_fkey" FOREIGN KEY ("productVariantId") REFERENCES "ProductVariant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SaleLineSerial" ADD CONSTRAINT "SaleLineSerial_saleLineId_fkey" FOREIGN KEY ("saleLineId") REFERENCES "SaleLine"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SaleLineSerial" ADD CONSTRAINT "SaleLineSerial_serialId_fkey" FOREIGN KEY ("serialId") REFERENCES "InventorySerial"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SaleLineSerial" ADD CONSTRAINT "SaleLineSerial_productVariantId_fkey" FOREIGN KEY ("productVariantId") REFERENCES "ProductVariant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StockTransferLotAllocation" ADD CONSTRAINT "StockTransferLotAllocation_stockTransferLineId_fkey" FOREIGN KEY ("stockTransferLineId") REFERENCES "StockTransferLine"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StockTransferLotAllocation" ADD CONSTRAINT "StockTransferLotAllocation_lotId_fkey" FOREIGN KEY ("lotId") REFERENCES "InventoryLot"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StockTransferSerialAllocation" ADD CONSTRAINT "StockTransferSerialAllocation_stockTransferLineId_fkey" FOREIGN KEY ("stockTransferLineId") REFERENCES "StockTransferLine"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StockTransferSerialAllocation" ADD CONSTRAINT "StockTransferSerialAllocation_serialId_fkey" FOREIGN KEY ("serialId") REFERENCES "InventorySerial"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CommerceOrder" ADD CONSTRAINT "CommerceOrder_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CommerceOrder" ADD CONSTRAINT "CommerceOrder_locationId_fkey" FOREIGN KEY ("locationId") REFERENCES "Location"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CommerceOrder" ADD CONSTRAINT "CommerceOrder_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "Customer"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CommerceOrderLine" ADD CONSTRAINT "CommerceOrderLine_commerceOrderId_fkey" FOREIGN KEY ("commerceOrderId") REFERENCES "CommerceOrder"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CommerceOrderLine" ADD CONSTRAINT "CommerceOrderLine_productVariantId_fkey" FOREIGN KEY ("productVariantId") REFERENCES "ProductVariant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Device" ADD CONSTRAINT "Device_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Device" ADD CONSTRAINT "Device_locationId_fkey" FOREIGN KEY ("locationId") REFERENCES "Location"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Device" ADD CONSTRAINT "Device_registerId_fkey" FOREIGN KEY ("registerId") REFERENCES "Register"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CatalogRevision" ADD CONSTRAINT "CatalogRevision_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CatalogSnapshotItem" ADD CONSTRAINT "CatalogSnapshotItem_catalogRevisionId_fkey" FOREIGN KEY ("catalogRevisionId") REFERENCES "CatalogRevision"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CatalogSnapshotItem" ADD CONSTRAINT "CatalogSnapshotItem_productVariantId_fkey" FOREIGN KEY ("productVariantId") REFERENCES "ProductVariant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InventoryException" ADD CONSTRAINT "InventoryException_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InventoryException" ADD CONSTRAINT "InventoryException_locationId_fkey" FOREIGN KEY ("locationId") REFERENCES "Location"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PaymentProviderConnection" ADD CONSTRAINT "PaymentProviderConnection_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PaymentIntent" ADD CONSTRAINT "PaymentIntent_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PaymentIntent" ADD CONSTRAINT "PaymentIntent_connectionId_fkey" FOREIGN KEY ("connectionId") REFERENCES "PaymentProviderConnection"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PaymentIntent" ADD CONSTRAINT "PaymentIntent_paymentId_fkey" FOREIGN KEY ("paymentId") REFERENCES "Payment"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PaymentWebhookEvent" ADD CONSTRAINT "PaymentWebhookEvent_connectionId_fkey" FOREIGN KEY ("connectionId") REFERENCES "PaymentProviderConnection"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StoreCreditAccount" ADD CONSTRAINT "StoreCreditAccount_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StoreCreditAccount" ADD CONSTRAINT "StoreCreditAccount_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "Customer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StoreCreditTransaction" ADD CONSTRAINT "StoreCreditTransaction_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES "StoreCreditAccount"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GiftCard" ADD CONSTRAINT "GiftCard_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GiftCardTransaction" ADD CONSTRAINT "GiftCardTransaction_giftCardId_fkey" FOREIGN KEY ("giftCardId") REFERENCES "GiftCard"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LoyaltyProgram" ADD CONSTRAINT "LoyaltyProgram_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LoyaltyAccount" ADD CONSTRAINT "LoyaltyAccount_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LoyaltyAccount" ADD CONSTRAINT "LoyaltyAccount_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "Customer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LoyaltyTransaction" ADD CONSTRAINT "LoyaltyTransaction_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES "LoyaltyAccount"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PriceList" ADD CONSTRAINT "PriceList_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PriceListItem" ADD CONSTRAINT "PriceListItem_priceListId_fkey" FOREIGN KEY ("priceListId") REFERENCES "PriceList"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PriceListItem" ADD CONSTRAINT "PriceListItem_productVariantId_fkey" FOREIGN KEY ("productVariantId") REFERENCES "ProductVariant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Promotion" ADD CONSTRAINT "Promotion_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PromotionProduct" ADD CONSTRAINT "PromotionProduct_promotionId_fkey" FOREIGN KEY ("promotionId") REFERENCES "Promotion"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PromotionProduct" ADD CONSTRAINT "PromotionProduct_productVariantId_fkey" FOREIGN KEY ("productVariantId") REFERENCES "ProductVariant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SaleAppliedPromotion" ADD CONSTRAINT "SaleAppliedPromotion_saleId_fkey" FOREIGN KEY ("saleId") REFERENCES "Sale"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SaleAppliedPromotion" ADD CONSTRAINT "SaleAppliedPromotion_promotionId_fkey" FOREIGN KEY ("promotionId") REFERENCES "Promotion"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StockCount" ADD CONSTRAINT "StockCount_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StockCount" ADD CONSTRAINT "StockCount_locationId_fkey" FOREIGN KEY ("locationId") REFERENCES "Location"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StockCountLine" ADD CONSTRAINT "StockCountLine_stockCountId_fkey" FOREIGN KEY ("stockCountId") REFERENCES "StockCount"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StockCountLine" ADD CONSTRAINT "StockCountLine_productVariantId_fkey" FOREIGN KEY ("productVariantId") REFERENCES "ProductVariant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RegisterSession" ADD CONSTRAINT "RegisterSession_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RegisterSession" ADD CONSTRAINT "RegisterSession_registerId_fkey" FOREIGN KEY ("registerId") REFERENCES "Register"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CashMovement" ADD CONSTRAINT "CashMovement_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CashMovement" ADD CONSTRAINT "CashMovement_registerSessionId_fkey" FOREIGN KEY ("registerSessionId") REFERENCES "RegisterSession"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "IntegrationEndpoint" ADD CONSTRAINT "IntegrationEndpoint_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OutboxDelivery" ADD CONSTRAINT "OutboxDelivery_outboxEventId_fkey" FOREIGN KEY ("outboxEventId") REFERENCES "OutboxEvent"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OutboxDelivery" ADD CONSTRAINT "OutboxDelivery_endpointId_fkey" FOREIGN KEY ("endpointId") REFERENCES "IntegrationEndpoint"("id") ON DELETE CASCADE ON UPDATE CASCADE;

