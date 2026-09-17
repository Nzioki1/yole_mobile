'use client';

import { useState } from 'react';
import { api } from '@/lib/api';
import { Panel, PanelHeader, PanelBody } from '@/components/panel/Panel';

export default function ExportPage() {
  const [busy, setBusy] = useState(false);
  const [meta, setMeta] = useState<any>(null);

  const download = async () => {
    setBusy(true);
    try {
      const pack = await api.buildExportPack();
      const blob = new Blob([JSON.stringify(pack, null, 2)], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'yole-demo-export.json';
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
      setMeta({
        exportedAt: pack.exportedAt,
        filename: pack.filename || 'yole-demo-export.json',
        customers: pack.customers?.length,
        wallets: pack.wallets?.length,
        loans: pack.loans?.length,
        payments: pack.payments?.length,
        cases: pack.cases?.length,
      });
    } catch (e: any) {
      alert(e.message || 'Export failed');
    } finally {
      setBusy(false);
    }
  };

  return (
    <div>
      <Panel>
        <PanelHeader>Export pack (DEM-12)</PanelHeader>
        <PanelBody>
          <p>
            Download an open-format JSON export of the offline demo universe (customers, wallets,
            loans, payments, journals, cases, remittances, cards).
          </p>
          <button className="btn btn-theme" disabled={busy} onClick={download}>
            {busy ? 'Building...' : 'Download yole-demo-export.json'}
          </button>
          {meta && (
            <div className="mt-3">
              <div className="alert alert-success mb-0">
                Exported <strong>{meta.filename}</strong> at {meta.exportedAt}
                <ul className="mb-0 mt-2">
                  <li>Customers: {meta.customers}</li>
                  <li>Wallets: {meta.wallets}</li>
                  <li>Loans: {meta.loans}</li>
                  <li>Payments: {meta.payments}</li>
                  <li>Cases: {meta.cases}</li>
                </ul>
              </div>
            </div>
          )}
        </PanelBody>
      </Panel>
    </div>
  );
}
