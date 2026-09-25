'use client';

import { useState, useEffect } from 'react';
import { api } from '@/lib/api';
import { Panel, PanelHeader, PanelBody } from '@/components/panel/Panel';

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
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <Panel><PanelBody className="text-center py-4">Loading...</PanelBody></Panel>;
  }

  return (
    <div>
      <Panel>
        <PanelHeader>Fee Configurations</PanelHeader>
        <PanelBody className="p-0">
          {fees.length === 0 ? (
            <div className="p-4 text-center text-gray-500">No fee configurations found</div>
          ) : (
            <div className="table-responsive">
              <table className="table table-striped mb-0 align-middle">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Payment Type</th>
                    <th>Fee Type</th>
                    <th>Value</th>
                    <th>Currency</th>
                  </tr>
                </thead>
                <tbody>
                  {fees.map((fee: any) => (
                    <tr key={fee.id}>
                      <td className="font-monospace small">{fee.id}</td>
                      <td>{fee.paymentType}</td>
                      <td>{fee.feeType}</td>
                      <td>{fee.value}</td>
                      <td>{fee.currency}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </PanelBody>
      </Panel>

      <Panel>
        <PanelHeader>Limit Configurations</PanelHeader>
        <PanelBody className="p-0">
          {limits.length === 0 ? (
            <div className="p-4 text-center text-gray-500">No limit configurations found</div>
          ) : (
            <div className="table-responsive">
              <table className="table table-striped mb-0 align-middle">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>KYC Tier</th>
                    <th>Currency</th>
                    <th>Daily Limit</th>
                    <th>Monthly Limit</th>
                  </tr>
                </thead>
                <tbody>
                  {limits.map((limit: any) => (
                    <tr key={limit.id}>
                      <td className="font-monospace small">{limit.id}</td>
                      <td>{limit.kycTier}</td>
                      <td>{limit.currency}</td>
                      <td>{limit.dailyLimit}</td>
                      <td>{limit.monthlyLimit}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </PanelBody>
      </Panel>
    </div>
  );
}
