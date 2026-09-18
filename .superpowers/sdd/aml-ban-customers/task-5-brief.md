### Task 5: Users page — view for all roles, mutate ADMIN-only

**Files:**
- Modify: `apps/admin_web/app/dashboard/users/page.tsx`
- Optional: `docs/demo/DEM-SCRIPT.md` URLs for ban list + customers

- [ ] **Step 1: Change auth guard**

```ts
const [currentUser, setCurrentUser] = useState<ReturnType<typeof authService.getCurrentUser>>(null);
const isAdmin = currentUser?.role === StaffRole.ADMIN;

useEffect(() => {
  const user = authService.getCurrentUser();
  if (!user) {
    router.replace('/login');
    return;
  }
  setCurrentUser(user);
  loadStaff();
}, [router]);
```

Remove redirect that sent non-ADMIN to `/dashboard`.

- [ ] **Step 2: Conditional mutate UI**

- Show **+ Create staff** form only if `isAdmin`
- Role column: if `isAdmin` → `<select>` as today; else → badge text only
- Helper text: non-ADMIN sees “View only — ask an ADMIN to create users or change roles.”

- [ ] **Step 3: DEM-SCRIPT one-liners**

```
| — | `/dashboard/aml-ban-list` | AML ban list |
| — | `/dashboard/customers` | Customers directory |
```

- [ ] **Step 4: Manual acceptance**

1. Admin: see ban list, customers, users mutate
2. Login as `support@postefinance.com`: see Customers, AML ban, Users list; no create/role select
3. Reset demo restores bans
4. No hydration error on shell (auth already deferred)

- [ ] **Step 5: Commit + push when asked**

```bash
git add apps/admin_web/app/dashboard/users/page.tsx docs/demo/DEM-SCRIPT.md
git commit -m "feat(admin): allow all staff roles to view Users list"
```

---
