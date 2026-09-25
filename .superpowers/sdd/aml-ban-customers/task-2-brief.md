### Task 2: API + RBAC + sidebar + titles

**Files:**
- Modify: `apps/admin_web/lib/api.ts`
- Modify: `apps/admin_web/lib/rbac.ts`
- Modify: `apps/admin_web/components/sidebar/Sidebar.tsx`
- Modify: `apps/admin_web/app/dashboard/layout.tsx`

**Interfaces:**
- Produces: `api.listAmlBanList`, `api.addAmlBanEntry`, `api.liftAmlBanEntry`, `api.listCustomers`
- Routes: `'/dashboard/aml-ban-list'`, `'/dashboard/customers'` on ADMIN + OPS + SUPPORT + FINANCE
- `'/dashboard/users'` added to OPS, SUPPORT, FINANCE (already on ADMIN via ALL_ADMIN)

- [ ] **Step 1: API methods** (offline-only throw pattern)

```ts
async listAmlBanList() {
  if (OFFLINE_DEMO) return this.store().listAmlBanList();
  throw new Error('listAmlBanList is only available in offline demo');
}
async addAmlBanEntry(data: Parameters<OfflineDemoStore['addAmlBanEntry']>[0]) {
  if (OFFLINE_DEMO) return this.store().addAmlBanEntry(data);
  throw new Error('addAmlBanEntry is only available in offline demo');
}
async liftAmlBanEntry(id: string) {
  if (OFFLINE_DEMO) return this.store().liftAmlBanEntry(id);
  throw new Error('liftAmlBanEntry is only available in offline demo');
}
async listCustomers() {
  if (OFFLINE_DEMO) return this.store().listCustomers();
  throw new Error('listCustomers is only available in offline demo');
}
```

(Use inline param types if importing OfflineDemoStore is awkward.)

- [ ] **Step 2: RBAC**

Add to `ModuleRoute` union: `'/dashboard/aml-ban-list' | '/dashboard/customers'`.

Add both to `ALL_ADMIN`.

Add to OPS, SUPPORT, and FINANCE arrays:

- `'/dashboard/aml-ban-list'`
- `'/dashboard/customers'`
- `'/dashboard/users'`

Also add `'/dashboard/customer360'` to OPS/FINANCE if missing (SUPPORT already has it) so Open 360 works for those roles — **add customer360 to OPS and FINANCE**.

- [ ] **Step 3: Sidebar**

Customers group:

```ts
{ name: 'Customers', href: '/dashboard/customers', icon: 'fa fa-address-book' },
{ name: 'Customer 360', href: '/dashboard/customer360', icon: 'fa fa-user' },
...
```

Operations group:

```ts
{ name: 'AML ban list', href: '/dashboard/aml-ban-list', icon: 'fa fa-ban' },
```

(Keep Cases nearby.)

- [ ] **Step 4: layout titles**

```ts
'/dashboard/customers': 'Customers',
'/dashboard/aml-ban-list': 'AML Ban List',
```

- [ ] **Step 5: Commit**

```bash
git add apps/admin_web/lib/api.ts apps/admin_web/lib/rbac.ts apps/admin_web/components/sidebar/Sidebar.tsx apps/admin_web/app/dashboard/layout.tsx
git commit -m "feat(admin): RBAC and nav for AML ban list and customers directory"
```

---
