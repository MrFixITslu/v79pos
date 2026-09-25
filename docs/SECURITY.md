# Security Baseline

- Hub-issued SSO tokens are validated against issuer, audience and JWKS in production.
- `AUTH_MODE=dev` is explicitly rejected when `NODE_ENV=production`.
- Tenant context is checked against an active server-side membership; a tenant header never grants membership by itself.
- Server-side RBAC and location scope are checked for protected operations.
- MFA remains a Hub responsibility for privileged roles.
- Raw card data is not represented or stored by V79 Commerce.
- Until payment adapters are connected, non-cash payments/refunds require external provider references and remain auditable.
- Rate limiting, secure headers, request validation and restricted CORS are enabled in the API.
- Inventory/sale/receipt/transfer mutations use serializable transactions with retry on write conflicts.
- Immutable audit records cover refunds, purchase approvals, inventory adjustments, transfers and logistics events.
- Secrets belong in runtime environment/secret storage, never the repository.
- Production release still requires dependency/container scanning, baseline migration testing, restore testing, end-to-end tenant-isolation tests and payment-webhook signature verification.
