# Cross-App Sync Verification (Phase 7)

## Singleton Pattern Verification

### Agent Mobile (`apps/agent_mobile/lib/main.dart`)
✅ **VERIFIED**: Uses `OfflineAgentRepository.instance` singleton pattern throughout the app.
- Repository instance is created once via `OfflineAgentRepository.instance` getter
- All services use the same singleton: `OfflineAgentRepository.instance`
- No `createFresh()` calls in main.dart - singleton is lazy-initialized on first access
- Singleton ensures all mutations are on the same in-memory universe

### Customer Mobile (`apps/yole_mobile/lib/main.dart`)
❌ **NOT PRESENT**: Customer app does not exist in this workspace yet.
- Expected to use `OfflineDemoRepository.instance` pattern (similar to agent)
- Expected to share the same `DemoUniverse.load()` data source
- Cross-app sync would work automatically via shared embedded JSON seed

## Integration Test Status

### Cross-App Sync Test (Task 7.2)
**Status**: NOT FEASIBLE - Customer app not present in workspace

**Expected behavior** (when both apps exist):
1. Agent app uses `OfflineAgentRepository.instance`
2. Customer app uses `OfflineDemoRepository.instance`
3. Both repositories load from shared `DemoUniverse.load()` embedded JSON
4. Agent cash-in to customer → balance visible in customer app
5. Mutations stay in-memory per app session, but seed is identical

**Example test scenario** (blocked):
```dart
test('cash-in on agent → balance visible in customer', () {
  // Agent login
  final agentRepo = OfflineAgentRepository.instance;
  agentRepo.login(agentId: 'agent-001');
  
  // Cash-in FC 5,000 to Jean-Paul (cust_kasee)
  agentRepo.cashIn(
    customerId: 'cust_kasee',
    amountMinor: '500000',
    currency: 'CDF',
  );
  
  // Customer repo reads wallet
  final customerRepo = OfflineDemoRepository.instance;
  final wallet = customerRepo.getWallet(
    customerId: 'cust_kasee',
    currency: 'CDF',
  );
  
  // Verify balance increased
  expect(wallet['availableMinor'], greaterThan(25000000));
});
```

## Recommendations

1. **When customer app is implemented**: Create integration test file at:
   - `apps/agent_mobile/test_integration/cross_app_sync_test.dart`
   - Or shared integration test directory if workspace supports it

2. **Verify both apps use**:
   - Same `DemoUniverse.load()` source
   - Singleton pattern for repositories
   - No duplicate universe instances created

3. **Test scenarios to implement**:
   - Agent enrolls customer → customer appears in customer app seed
   - Agent cash-in → customer wallet balance updates
   - Agent cash-out → customer wallet balance decreases
   - Verify journal records are shared between apps

## Conclusion

**Phase 7 Status**: PARTIALLY COMPLETE
- ✅ Task 7.1: Singleton pattern verified in agent app
- ❌ Task 7.2: Integration test blocked - customer app not present
- 📋 Documented expected behavior and test scenarios for future implementation
