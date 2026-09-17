# Poste Finance Admin Portal - Access Guide

## Server Status
✅ **Running**: http://localhost:3001  
✅ **Login Page**: http://localhost:3001/login  
✅ **All mock data loaded** - No backend API needed

## Access Methods

### Method 1: Port Forwarding (Recommended for Local Access)
1. In VS Code/Cursor, open the **Ports** panel
2. Click "Forward a Port"
3. Enter port: `3001`
4. Access via the forwarded URL (usually `https://localhost:3001` or similar)

### Method 2: Within Cloud Agent VM
If you have desktop/GUI access to the Cloud Agent:
```bash
# Open in browser within the VM
google-chrome http://localhost:3001/login
```

### Method 3: Command Line Access
```bash
# Test the server is responding
curl http://localhost:3001/login

# Or use a text-based browser
lynx http://localhost:3001/login
```

## Demo Credentials

All passwords: `Password1!`

| Email | Role | Access |
|-------|------|--------|
| admin@yole.com | ADMIN | Full access to all modules |
| ops@yole.com | OPS | KYC, Agents, Payments, Recon, Cases |
| support@yole.com | SUPPORT | Customer 360, Cases only |
| finance@yole.com | FINANCE | Payments, Cards, Payroll, Fees & Limits, Recon |

## Quick Demo Flow

1. **Login** - Use any credential above or click quick login buttons
2. **Dashboard Home** - See KPIs and interactive charts with real data
3. **Explore Modules**:
   - 2 Pending KYC submissions
   - 13 Payments (various types and statuses)
   - 5 Virtual cards
   - 4 Employers
   - 2 Open support cases
   - All Congo DRC themed (Vodacom, Airtel, CDF/USD)
4. **Try Interactions**:
   - Click KPI cards to filter views
   - Click chart segments to drill down
   - Approve/reject KYC submissions
   - Create new cases
   - Search Customer 360 (try `cust_001`)

## Demo Data Highlights

### Sample Customers
- **cust_001**: Jean-Paul Kabila (Active, has wallet balances)
- **cust_002**: Marie Tshala (Pending KYC)
- **cust_003**: Joseph Mukendi (Premium, multiple cards)
- **cust_004**: Grace Mbuyi (Open case)

### Sample Transactions
- W2W transfers between customers
- Mobile money via Vodacom, Airtel
- Bill payments (SNEL, REGIDESO)
- Airtime purchases
- Bank transfers (Rawbank, Equity BCDC)
- Failed transactions for error states

## Troubleshooting

### Server Not Responding?
```bash
# Check if server is running
lsof -i :3001

# Restart if needed
cd /workspace/apps/admin_web
PORT=3001 pnpm dev
```

### Can't Access from Browser?
- Ensure port forwarding is configured
- Check firewall rules
- Try accessing from within the VM environment

### Need to Stop Server?
```bash
# Kill the Next.js process
pkill -f "next-server"
```

## Architecture

- **Frontend**: Next.js 14 with App Router
- **Styling**: Color Admin default + teal theme
- **Auth**: JWT-based (in-memory mock)
- **Data**: 100% mock data, localStorage persistence
- **Charts**: Recharts (donut + bar charts)
- **RBAC**: Role-based navigation and access control

## Features

✅ Staff authentication with 4 roles  
✅ Color Admin teal-themed shell  
✅ Dashboard with live KPIs and charts  
✅ 10+ admin modules fully functional  
✅ Customer 360 view  
✅ KYC approval workflow  
✅ Payments search and filtering  
✅ Card management  
✅ Payroll (employers + employees)  
✅ Support cases CRUD  
✅ Reconciliation reports  
✅ Fees & limits configuration  
✅ All data persists in localStorage  
✅ Congo DRC context throughout  

---

**Last Updated**: 2026-09-17  
**Branch**: cursor/task1-monorepo-scaffold-1d8a  
**Status**: Demo-ready 🎉
