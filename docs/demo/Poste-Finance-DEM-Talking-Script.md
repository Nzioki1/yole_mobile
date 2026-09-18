# Poste Finance — Live Demo Talking Script
**Audience:** customer / RFP showcase (Appendix A DEM-01…DEM-12)  
**Length:** ~30–45 minutes  
**Mode:** offline demo — API on :3000 is stopped  
**Admin:** http://localhost:3001  

Use this as spoken lines. Bracketed notes are for you, not for the room.

---

## Opening (1–2 min)

"Thanks for joining. Today we’re walking the Poste Finance digital financial services platform through the mandatory demonstration scenarios in your cahier des charges — self-onboarding and wallets, payments and agents, payroll and credit, product fees with maker-checker, cards, remittance, AML, recon, export, and resilience.

Important honesty up front: this build is running as an **offline demo**. There is **no live API**, no live mobile-money or bank rail, and we’re not claiming Visa or Mastercard certification or a live high-availability failover. Where something is mocked, you’ll see an exact banner — I’ll call those out.

Staff and customer logins use `@postefinance.com` with password `Password1!`. Offline OTP is always `123456`. If we mutate data, we can **Reset demo** and return to the seed."

[Login admin@postefinance.com / Password1!. Point at header: Offline demo — no live API.]

---

## Beat 1 — Back-office orientation (2 min)

"Starting in the admin portal. From here operations, support, and finance staff work the same universe the customer and agent apps use.

Quick tour of three surfaces we added for day-to-day ops:

- **Customers** — full directory of seeded customers; Open 360 jumps straight into Customer 360.
- **AML ban list** — internal ban / screening list for the demo. Banner says exactly: *Offline demo — not a live sanctions feed.* We’re not plugged into a live watchlist.
- **Users** — every staff role can *view* the staff list; only ADMIN can create users or change roles. That’s separation of duties in a thin form."

[Optional: log in as support@postefinance.com later to prove view-only Users.]

---

## Beat 2 — DEM-06 Payments & dual wallet (5 min) — lead story

"This is the Phase-one payments story — wallet to wallet, mobile money, bank, and bill pay, with a receipt and a journal trail.

I’m logging in as Kasee, our open-market customer — `kasee.demo@postefinance.com`. Home shows **CDF and USD** wallets. That’s dual-currency from day one.

In history you’ll see four seeded payments: wallet-to-wallet, MNO, bank, and bill. Each receipt carries a journal reference.

Now back in admin — either search payments or open **Customers**, find Kasee, **Open 360**, and you’ll see the same payment IDs and journals. Same customer universe, same ledger story, no live rail."

Talk track if asked about live MNO/bank: "Adapters are mocked for the showcase. Production would sit on certified connectors; today we’re proving UX, ledger linkage, and ops visibility."

---

## Beat 3 — Agent channel (3 min)

"Agents are the branchless channel. Agent ID is `agent-001` — not a staff email.

Float shows CDF and USD. Enroll and cash-in/out work offline in this session. On the admin side, the cross-channel journals you see are **pre-seeded** in the demo universe — we’re not doing live sync between apps in this offline mode. That’s intentional for a stable demo."

---

## Beat 4 — DEM-03 Payroll → salary advance (5 min)

"Corporate payroll and salary advance.

In admin **Payroll**, employer **Poste Demo SARL** — `emp_poste` — with Amina on the roster and salary history.

Customer login: `amina.payroll@postefinance.com`. Under **Credit**, salary advance eligibility comes from that salary history — it’s not an always-true button.

After terms and PIN, she gets wallet credit and a loan. Back in admin Customer 360 for `cust_amina`, you’ll see the active loan and **installment schedule**. That’s the payroll-to-credit loop your RFP asks for."

---

## Beat 5 — DEM-02 Products & maker-checker (4 min)

"Product configuration with four-eyes.

**Products & rules** lists products plus fee and limit rows. Changes don’t go live as a silent edit — they propose into **Pending approvals**.

Here’s a seeded fee change, `apr_fee_w2w_001`. I approve it. Status updates and the fee becomes effective. Reject would leave the prior rule in force.

That’s maker-checker for pricing — the control your back-office chapter cares about."

---

## Beat 6 — DEM-04 Credit exception (3 min)

"**Credit exceptions** — when an advance sits above a threshold and needs a human decision.

Row `loan_kasee_exception_001` starts as pending exception. On approve it becomes active, gets a schedule, credits the wallet, and posts a journal. Customer 360 for Kasee shows the schedule.

Reset demo puts the exception back if you want to replay."

---

## Beat 7 — DEM-05 Idempotency (3 min)

"**Idempotency lab** — interrupted or replayed payment must not double-post.

Key `idem_replay_demo_001`: I confirm replay twice — same payment ID, no duplicate. Then compensate on the demo payment — reversing journal and a notification. That’s safe retry semantics for flaky networks."

---

## Beat 8 — DEM-07 Cards (4 min) — honesty mandatory

"Virtual cards.

Banner on customer and admin — exact words: **MOCK — not Visa/Mastercard certified.** Please treat that as binding for this room.

You’ll see a virtual debit, controls and limits, a mock 3DS authentication trail, and a dispute case linked from admin. We’re showing the journey and ops hooks, not a certified scheme stack."

---

## Beat 9 — DEM-08 Remittance (3 min)

"Inbound remittance: a clear payout path and a screening-hit exception.

Customer remittance shows both. Admin **Remittance** lets us **Clear** or **Refund** the screening hit, plus a partner recon stub. Again — mocked partners, real workflow shape."

---

## Beat 10 — DEM-09 AML case + ban list (3 min)

"Financial crime ops.

**Cases** — confidential AML case `case_aml_conf_001`. Badge CONFIDENTIAL. Workflow: Investigate, Recommend, then maker-checker approve. Separation of duties is soft in the demo but the stages are visible.

Alongside that, the **AML ban list** is where blocked names and entities live for the offline universe. Remember the banner: not a live sanctions feed. Together they answer ‘how do you case and how do you list?’ without overclaiming screening providers."

---

## Beat 11 — DEM-11 Recon + DEM-12 Export (3 min)

"**Reconciliation** for the demo day — matched rails, open exceptions, **Run EOD** to write an end-of-day snapshot and GL / suspense view.

Then **Export pack** — download the open-format JSON of the customer universe: customers, wallets, loans, transactions, cases. That’s the exit / portability story for the RFP."

---

## Beat 12 — DEM-10 Resilience (2 min)

"**Resilience** page. Banner — exact: **DEMO STORYBOARD — not a live HA failover.**

We walk failure, failover narrative, and balanced journals / ledger integrity. We are **not** measuring RTO/RPO in this room; we’re showing how we’d tell that story with ledger honesty."

---

## Beat 13 — DEM-01 Onboarding close (2 min)

"Closing on self-registration.

Prefer the seeded Kasee path you already saw — dual wallets after login. If we show register: phone, OTP `123456`, eKYC submit in offline mode. Device binding is thin in this build; the must-show is OTP, KYC gate, and CDF/USD wallet."

---

## Close (1 min)

"To summarize what you saw against Appendix A:

1. Dual-currency wallet and multi-rail payments with journal traceability.  
2. Agent float and cash channel.  
3. Payroll-linked salary advance with schedule.  
4. Fee changes under maker-checker.  
5. Credit exceptions under maker-checker.  
6. Idempotent replay and compensate.  
7. Virtual card journey under an explicit MOCK banner.  
8. Remittance clear vs screening exception.  
9. Confidential AML case workflow plus ban list.  
10. EOD recon and open export.  
11. Resilience as an honest storyboard.  
12. Self-reg / OTP / KYC / wallet path.

Everything today ran with the API stopped. Production connectors, scheme certification, and live HA are separate workstreams — this showcase proves product shape, controls, and demo readiness.

Happy to take questions or replay any single DEM."

---

## Quick recovery lines

| If this happens… | Say… |
| --- | --- |
| Page 500 / blank | "Local Next cache hiccup — we restart admin on 3001; seed is intact." |
| Someone asks for live M-Pesa | "Connector is mocked here; the receipt and journal path is what we’re proving." |
| Someone asks Visa cert | Point at MOCK banner — "Out of scope for this build; journey only." |
| Agent cash-in not on admin | "Offline mode: pre-seeded continuity, not live sync — by design for a stable demo." |
| Login fails | Confirm `@postefinance.com` not `@yole.com`, password `Password1!`. |

---

## Timing cheat sheet

| Block | Minutes |
| --- | ---: |
| Open + orientation | 3 |
| DEM-06 + Agent | 8 |
| DEM-03 | 5 |
| DEM-02 + 04 + 05 | 10 |
| DEM-07 + 08 | 7 |
| DEM-09 + ban list | 3 |
| DEM-11 + 12 + 10 | 5 |
| DEM-01 + close | 4 |
| **Total** | **~45** |

Shorter 25-min cut: Open → DEM-06 → DEM-03 → DEM-02 → DEM-07 (MOCK) → DEM-09 → DEM-11/12 → Close.
