'use client';

import { FormEvent, useEffect, useState } from 'react';
import { api } from '@/lib/api';
import { authService } from '@/lib/auth';
import { Panel, PanelHeader, PanelBody } from '@/components/panel/Panel';

export default function ProductsPage() {
  const [products, setProducts] = useState<any[]>([]);
  const [fees, setFees] = useState<any[]>([]);
  const [limits, setLimits] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  
  const [showFeeForm, setShowFeeForm] = useState(false);
  const [showLimitForm, setShowLimitForm] = useState(false);
  const [editingFee, setEditingFee] = useState<any | null>(null);
  const [editingLimit, setEditingLimit] = useState<any | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const [feeForm, setFeeForm] = useState({
    paymentType: 'W2W',
    feePercent: '',
    minFeeMinor: '',
    maxFeeMinor: '',
    currency: 'USD',
    effectiveFrom: '',
  });

  const [limitForm, setLimitForm] = useState({
    limitType: 'CUSTOMER_DAILY',
    currency: 'USD',
    dailyLimitMinor: '',
    monthlyLimitMinor: '',
    effectiveFrom: '',
  });

  useEffect(() => {
    const today = new Date().toISOString().slice(0, 10);
    setFeeForm((f) => (f.effectiveFrom ? f : { ...f, effectiveFrom: today }));
    setLimitForm((f) => (f.effectiveFrom ? f : { ...f, effectiveFrom: today }));
  }, []);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const [p, f, l] = await Promise.all([
        api.listProducts(),
        api.listFeeConfigs(),
        api.listLimitConfigs(),
      ]);
      setProducts(Array.isArray(p) ? p : []);
      setFees(Array.isArray(f) ? f : []);
      setLimits(Array.isArray(l) ? l : []);
    } finally {
      setLoading(false);
    }
  };

  const handleFeeSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);
    setMessage(null);
    try {
      const currentUser = authService.getCurrentUser();
      const result = await api.proposeFeeRule({
        paymentType: feeForm.paymentType,
        feePercent: Number(feeForm.feePercent),
        minFeeMinor: Number(feeForm.minFeeMinor),
        maxFeeMinor: Number(feeForm.maxFeeMinor),
        currency: feeForm.currency,
        effectiveFrom: feeForm.effectiveFrom,
        makerStaffId: currentUser?.id,
        supersedesId: editingFee?.id,
      });
      setMessage(`Fee rule proposed: ${result.approval.id}`);
      setShowFeeForm(false);
      setEditingFee(null);
      setFeeForm({
        paymentType: 'W2W',
        feePercent: '',
        minFeeMinor: '',
        maxFeeMinor: '',
        currency: 'USD',
        effectiveFrom: new Date().toISOString().slice(0, 10),
      });
      await loadData();
    } catch (err) {
      setError(String(err));
    }
  };

  const handleLimitSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);
    setMessage(null);
    try {
      const currentUser = authService.getCurrentUser();
      const result = await api.proposeLimitRule({
        limitType: limitForm.limitType,
        currency: limitForm.currency,
        dailyLimitMinor: Number(limitForm.dailyLimitMinor),
        monthlyLimitMinor: Number(limitForm.monthlyLimitMinor),
        effectiveFrom: limitForm.effectiveFrom,
        makerStaffId: currentUser?.id,
        supersedesId: editingLimit?.id,
      });
      setMessage(`Limit rule proposed: ${result.approval.id}`);
      setShowLimitForm(false);
      setEditingLimit(null);
      setLimitForm({
        limitType: 'CUSTOMER_DAILY',
        currency: 'USD',
        dailyLimitMinor: '',
        monthlyLimitMinor: '',
        effectiveFrom: new Date().toISOString().slice(0, 10),
