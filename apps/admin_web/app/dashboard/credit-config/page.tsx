'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { authService, StaffRole } from '../../../lib/auth';
import { OfflineDemoStore } from '../../../lib/offline/store';

type Product = {
  id: string;
  code: string;
  name: string;
  segment: string;
  maxAdvancePct?: number;
  autoApproveMaxMinor?: number;
  status: string;
  annualRate?: number;
  maxTenorMonths?: number;
};

type ScoringConfig = {
  id: string;
  name: string;
  weights: {
    kycScore: number;
    salaryHistory: number;
    loanHistory: number;
    savingsBalance: number;
  };
  thresholds: {
    minScore: number;
    maxLoanMinor: number;
  };
};

export default function CreditConfigPage() {
  const router = useRouter();
  const [products, setProducts] = useState<Product[]>([]);
  const [scoringConfigs, setScoringConfigs] = useState<ScoringConfig[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);

  useEffect(() => {
    const user = authService.getCurrentUser();
    if (!user || ![StaffRole.ADMIN, StaffRole.FINANCE].includes(user.role as StaffRole)) {
      router.push('/login');
      return;
    }

    loadData();
  }, [router]);

  const loadData = () => {
    const store = OfflineDemoStore.createFresh();
    const prods = store.listCreditProducts();
    const configs = store.listScoringConfigs();
    setProducts(prods);
    setScoringConfigs(configs);
    setLoading(false);
  };

  const handleEdit = (product: Product) => {
    setEditingProduct({ ...product });
  };

  const handleSave = () => {
    if (!editingProduct) return;
    
    const store = OfflineDemoStore.createFresh();
    store.updateCreditProduct(editingProduct.id, {
      annualRate: editingProduct.annualRate,
      maxTenorMonths: editingProduct.maxTenorMonths,
      autoApproveMaxMinor: editingProduct.autoApproveMaxMinor,
      status: editingProduct.status,
    });
    
    setEditingProduct(null);
    loadData();
    alert('Product updated successfully. Changes require approval in Pending Approvals.');
  };

  if (loading) {
    return <div className="p-6">Loading...</div>;
  }

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-6">Credit Products & Scoring Configuration</h1>

      <div className="mb-8">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-bold">Credit Products</h2>
          <div className="px-3 py-1 bg-yellow-100 text-yellow-800 text-sm rounded">
            Offline demo — changes pending approval
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="min-w-full bg-white border">
            <thead>
              <tr className="bg-gray-100">
                <th className="px-4 py-2 border text-left">Code</th>
                <th className="px-4 py-2 border text-left">Name</th>
                <th className="px-4 py-2 border text-left">Segment</th>
                <th className="px-4 py-2 border text-right">Annual Rate</th>
                <th className="px-4 py-2 border text-right">Max Tenor</th>
                <th className="px-4 py-2 border text-right">Auto-Approve Max</th>
                <th className="px-4 py-2 border text-center">Status</th>
                <th className="px-4 py-2 border text-center">Actions</th>
              </tr>
            </thead>
            <tbody>
              {products.map((prod) => (
                <tr key={prod.id} className="hover:bg-gray-50">
                  {editingProduct?.id === prod.id ? (
                    <>
                      <td className="px-4 py-2 border">{prod.code}</td>
                      <td className="px-4 py-2 border">{prod.name}</td>
                      <td className="px-4 py-2 border">{prod.segment}</td>
                      <td className="px-4 py-2 border">
                        <input
                          type="number"
                          step="0.01"
                          value={editingProduct.annualRate || 0}
                          onChange={(e) => setEditingProduct({ ...editingProduct, annualRate: parseFloat(e.target.value) })}
                          className="w-full px-2 py-1 border rounded text-right"
                        />
                      </td>
                      <td className="px-4 py-2 border">
                        <input
                          type="number"
                          value={editingProduct.maxTenorMonths || 12}
                          onChange={(e) => setEditingProduct({ ...editingProduct, maxTenorMonths: parseInt(e.target.value) })}
                          className="w-full px-2 py-1 border rounded text-right"
                        />
                      </td>
                      <td className="px-4 py-2 border">
                        <input
                          type="number"
                          value={editingProduct.autoApproveMaxMinor || 0}
                          onChange={(e) => setEditingProduct({ ...editingProduct, autoApproveMaxMinor: parseInt(e.target.value) })}
                          className="w-full px-2 py-1 border rounded text-right"
                        />
                      </td>
                      <td className="px-4 py-2 border">
                        <select
                          value={editingProduct.status}
                          onChange={(e) => setEditingProduct({ ...editingProduct, status: e.target.value })}
                          className="w-full px-2 py-1 border rounded"
                        >
                          <option value="ACTIVE">ACTIVE</option>
                          <option value="INACTIVE">INACTIVE</option>
                        </select>
                      </td>
                      <td className="px-4 py-2 border text-center">
                        <button
                          onClick={handleSave}
                          className="px-2 py-1 bg-green-600 text-white rounded text-sm hover:bg-green-700 mr-1"
                        >
                          Save
                        </button>
                        <button
                          onClick={() => setEditingProduct(null)}
                          className="px-2 py-1 bg-gray-300 rounded text-sm hover:bg-gray-400"
                        >
                          Cancel
                        </button>
                      </td>
                    </>
                  ) : (
                    <>
                      <td className="px-4 py-2 border">{prod.code}</td>
                      <td className="px-4 py-2 border">{prod.name}</td>
                      <td className="px-4 py-2 border">{prod.segment}</td>
                      <td className="px-4 py-2 border text-right">{prod.annualRate ? `${(prod.annualRate * 100).toFixed(1)}%` : '-'}</td>
                      <td className="px-4 py-2 border text-right">{prod.maxTenorMonths ? `${prod.maxTenorMonths} mo` : '-'}</td>
                      <td className="px-4 py-2 border text-right">
                        {prod.autoApproveMaxMinor ? `FC ${(prod.autoApproveMaxMinor / 100).toLocaleString()}` : '-'}
                      </td>
                      <td className="px-4 py-2 border text-center">
                        <span className={`px-2 py-1 rounded text-xs ${prod.status === 'ACTIVE' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'}`}>
                          {prod.status}
                        </span>
                      </td>
                      <td className="px-4 py-2 border text-center">
                        <button
                          onClick={() => handleEdit(prod)}
                          className="px-2 py-1 bg-blue-600 text-white rounded text-sm hover:bg-blue-700"
                        >
                          Edit
                        </button>
                      </td>
                    </>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <div className="mb-8">
        <h2 className="text-xl font-bold mb-4">Scoring Model Configuration</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {scoringConfigs.map((config) => (
            <div key={config.id} className="bg-white p-6 border rounded">
              <h3 className="font-bold text-lg mb-4">{config.name}</h3>
              <div className="mb-4">
                <h4 className="font-semibold mb-2">Weights</h4>
                <div className="space-y-2">
                  <div className="flex justify-between">
                    <span>KYC Score:</span>
                    <span className="font-mono">{(config.weights.kycScore * 100).toFixed(0)}%</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Salary History:</span>
                    <span className="font-mono">{(config.weights.salaryHistory * 100).toFixed(0)}%</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Loan History:</span>
                    <span className="font-mono">{(config.weights.loanHistory * 100).toFixed(0)}%</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Savings Balance:</span>
                    <span className="font-mono">{(config.weights.savingsBalance * 100).toFixed(0)}%</span>
                  </div>
                </div>
              </div>
              <div>
                <h4 className="font-semibold mb-2">Thresholds</h4>
                <div className="space-y-2">
                  <div className="flex justify-between">
                    <span>Min Score:</span>
                    <span className="font-mono">{config.thresholds.minScore}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Max Loan:</span>
                    <span className="font-mono">FC {(config.thresholds.maxLoanMinor / 100).toLocaleString()}</span>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="mt-6 p-4 bg-blue-50 border border-blue-200 rounded">
        <p className="text-sm text-blue-800">
          <strong>Note:</strong> Product changes require maker-checker approval. Submit changes via the Pending Approvals page. Scoring model weights are read-only in this offline demo.
        </p>
      </div>
    </div>
  );
}
