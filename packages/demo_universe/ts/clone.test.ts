import { loadUniverse } from './load';

test('loadUniverse deep clones so mutations do not stick', () => {
  const a = loadUniverse();
  a.customers.find((c) => c.id === 'cust_kasee')!.firstName = 'MUTATED';
  const b = loadUniverse();
  expect(b.customers.find((c) => c.id === 'cust_kasee')!.firstName).toBe('Kasee');
});
