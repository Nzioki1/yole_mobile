'use client';

import { useState, useEffect } from 'react';
import { api } from '@/lib/api';

export default function ConfigPage() {
  const [fees, setFees] = useState<any[]>([]);
  const [limits, setLimits] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const [feesData, limitsData] = await Promise.all([
        api.listFeeConfigs().catch(() => []),
        api.listLimitConfigs().catch(() => []),
      ]);
      setFees(Array.isArray(feesData) ? feesData : feesData.fees || []);
      setLimits(Array.isArray(limitsData) ? limitsData : limitsData.limits || []);
    } catch (err) {
      console.error('Failed to load config:', err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      {loading ? (
        <div className="text-center py-8">Loading...</div>
      ) : (
        <div className="space-y-6">
          {/* Fee Configs */}
          <div className="bg-white rounded-lg shadow">
            <div className="p-4 bg-gray-50 border-b flex justify-between items-center">
              <h2 className="text-xl font-bold">Fee Configurations</h2>
              <button className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 text-sm">
                + Add Fee Rule
              </button>
            </div>
            <div className="p-6">
              {fees.length === 0 ? (
                <div className="text-center py-8 text-gray-500">
                  <p>No fee configurations found.</p>
                  <p className="text-sm mt-2">Mock fees are currently calculated in PaymentsService (1% or 100 minor, whichever is greater)</p>
                </div>
              ) : (
                <table className="w-full">
                  <thead className="border-b">
                    <tr>
                      <th className="text-left p-2">ID</th>
                      <th className="text-left p-2">Payment Type</th>
                      <th className="text-left p-2">Fee Type</th>
                      <th className="text-left p-2">Value</th>
                      <th className="text-left p-2">Currency</th>
                    </tr>
                  </thead>
                  <tbody>
                    {fees.map((fee: any) => (
                      <tr key={fee.id} className="border-b hover:bg-gray-50">
                        <td className="p-2 font-mono text-xs">{fee.id}</td>
                        <td className="p-2">{fee.paymentType}</td>
                        <td className="p-2">{fee.feeType}</td>
                        <td className="p-2">{fee.value}</td>
                        <td className="p-2">{fee.currency}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </div>
          </div>

          {/* Limit Configs */}
          <div className="bg-white rounded-lg shadow">
            <div className="p-4 bg-gray-50 border-b flex justify-between items-center">
              <h2 className="text-xl font-bold">Limit Configurations</h2>
              <button className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 text-sm">
                + Add Limit Rule
              </button>
            </div>
            <div className="p-6">
              {limits.length === 0 ? (
                <div className="text-center py-8 text-gray-500">
                  <p>No limit configurations found.</p>
                  <p className="text-sm mt-2">Mock limits are currently hardcoded in WalletsService by KYC tier</p>
                  <div className="mt-4 text-left max-w-md mx-auto bg-gray-50 p-4 rounded">
                    <div className="text-sm font-semibold">Current Mock Limits (TIER_1):</div>
                    <ul className="text-xs mt-2 space-y-1">
                      <li>• USD Daily: $1,000 | Monthly: $10,000</li>
                      <li>• CDF Daily: FC 1,000,000 | Monthly: FC 10,000,000</li>
                    </ul>
                  </div>
                </div>
              ) : (
                <table className="w-full">
                  <thead className="border-b">
                    <tr>
                      <th className="text-left p-2">ID</th>
                      <th className="text-left p-2">KYC Tier</th>
                      <th className="text-left p-2">Currency</th>
                      <th className="text-left p-2">Daily Limit</th>
                      <th className="text-left p-2">Monthly Limit</th>
                    </tr>
                  </thead>
                  <tbody>
                    {limits.map((limit: any) => (
                      <tr key={limit.id} className="border-b hover:bg-gray-50">
                        <td className="p-2 font-mono text-xs">{limit.id}</td>
                        <td className="p-2">{limit.kycTier}</td>
                        <td className="p-2">{limit.currency}</td>
                        <td className="p-2">{limit.dailyLimit}</td>
                        <td className="p-2">{limit.monthlyLimit}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
