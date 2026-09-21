'use client';

import { ReactNode } from 'react';

export function Panel({
  theme = 'inverse',
  className = '',
  children,
}: {
  theme?: string;
  className?: string;
  children: ReactNode;
}) {
  return <div className={`panel panel-${theme} ${className}`.trim()}>{children}</div>;
}

export function PanelHeader({
  className = '',
  children,
}: {
  className?: string;
  children?: ReactNode;
}) {
  return (
    <div className={`panel-heading ${className}`.trim()}>
      <h4 className="panel-title">{children}</h4>
    </div>
  );
}

export function PanelBody({
  className = '',
  children,
}: {
  className?: string;
  children?: ReactNode;
}) {
  return <div className={`panel-body ${className}`.trim()}>{children}</div>;
}

export function PanelFooter({
  className = '',
  children,
}: {
  className?: string;
  children?: ReactNode;
}) {
  return <div className={`panel-footer ${className}`.trim()}>{children}</div>;
}
