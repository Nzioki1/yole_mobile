-- CreateEnum
CREATE TYPE "CurrencyCode" AS ENUM ('CDF', 'USD');

-- CreateEnum
CREATE TYPE "PocketKind" AS ENUM ('AVAILABLE', 'LEDGER');

-- CreateEnum
CREATE TYPE "JournalStatus" AS ENUM ('PENDING', 'POSTED', 'FAILED', 'REVERSED');

-- CreateTable
CREATE TABLE "Customer" (
    "id" TEXT NOT NULL,
    "email" TEXT,
    "phoneE164" TEXT,
    "firstName" TEXT NOT NULL,
    "lastName" TEXT NOT NULL,
    "segment" TEXT NOT NULL DEFAULT 'OPEN_MARKET',
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "enrolledByAgentId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Customer_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Wallet" (
    "id" TEXT NOT NULL,
    "customerId" TEXT NOT NULL,

    CONSTRAINT "Wallet_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WalletPocket" (
    "id" TEXT NOT NULL,
    "walletId" TEXT NOT NULL,
    "currency" "CurrencyCode" NOT NULL,
    "ledgerMinor" BIGINT NOT NULL DEFAULT 0,
    "blockedMinor" BIGINT NOT NULL DEFAULT 0,
    "pendingOutMinor" BIGINT NOT NULL DEFAULT 0,
    "pendingInMinor" BIGINT NOT NULL DEFAULT 0,

    CONSTRAINT "WalletPocket_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "JournalEntry" (
    "id" TEXT NOT NULL,
    "yoleReference" TEXT NOT NULL,
    "idempotencyKey" TEXT NOT NULL,
    "status" "JournalStatus" NOT NULL,
    "currency" "CurrencyCode" NOT NULL,
    "correlationId" TEXT NOT NULL,
    "actorType" TEXT NOT NULL,
    "actorId" TEXT,
    "externalRefsJson" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "JournalEntry_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Posting" (
    "id" TEXT NOT NULL,
    "journalId" TEXT NOT NULL,
    "accountCode" TEXT NOT NULL,
    "direction" TEXT NOT NULL,
    "amountMinor" BIGINT NOT NULL,
    "currency" "CurrencyCode" NOT NULL,
    "walletPocketId" TEXT,

    CONSTRAINT "Posting_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "IdempotencyRecord" (
    "key" TEXT NOT NULL,
    "requestHash" TEXT NOT NULL,
    "responseJson" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "IdempotencyRecord_pkey" PRIMARY KEY ("key")
);

-- CreateIndex
CREATE UNIQUE INDEX "Customer_email_key" ON "Customer"("email");

-- CreateIndex
CREATE UNIQUE INDEX "Customer_phoneE164_key" ON "Customer"("phoneE164");

-- CreateIndex
CREATE UNIQUE INDEX "WalletPocket_walletId_currency_key" ON "WalletPocket"("walletId", "currency");

-- CreateIndex
CREATE UNIQUE INDEX "JournalEntry_yoleReference_key" ON "JournalEntry"("yoleReference");

-- CreateIndex
CREATE UNIQUE INDEX "JournalEntry_idempotencyKey_key" ON "JournalEntry"("idempotencyKey");

-- AddForeignKey
ALTER TABLE "Wallet" ADD CONSTRAINT "Wallet_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "Customer"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WalletPocket" ADD CONSTRAINT "WalletPocket_walletId_fkey" FOREIGN KEY ("walletId") REFERENCES "Wallet"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Posting" ADD CONSTRAINT "Posting_journalId_fkey" FOREIGN KEY ("journalId") REFERENCES "JournalEntry"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
