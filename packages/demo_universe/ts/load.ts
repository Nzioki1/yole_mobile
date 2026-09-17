import raw from '../data/universe.json';
import type { Universe } from './types';

export function loadUniverse(): Universe {
  return structuredClone(raw) as Universe;
}
