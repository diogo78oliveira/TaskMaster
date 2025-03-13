import { useCallback, useRef, useEffect } from 'react';

// Custom hook for memoizing expensive calculations
export const useMemoizedCalculation = (calculation, dependencies) => {
  const resultRef = useRef(null);
  const depsRef = useRef(dependencies);

  // Only recalculate if dependencies have changed
  if (!areEqual(depsRef.current, dependencies)) {
    resultRef.current = calculation();
    depsRef.current = dependencies;
  }

  return resultRef.current;
};

// Deep comparison helper
function areEqual(a, b) {
  if (a === b) return true;
  if (a === null || b === null) return false;
  if (typeof a !== 'object' || typeof b !== 'object') return a === b;

  const keysA = Object.keys(a);
  const keysB = Object.keys(b);

  if (keysA.length !== keysB.length) return false;

  return keysA.every(key => areEqual(a[key], b[key]));
}

// Handle expensive operations without blocking the UI
export const useNonBlockingOperation = (operation, dependencies = []) => {
  return useCallback(() => {
    return new Promise(resolve => {
      setTimeout(() => {
        const result = operation();
        resolve(result);
      }, 0);
    });
  }, dependencies);
};
