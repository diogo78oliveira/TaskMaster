import { InteractionManager } from 'react-native';

// Custom implementation of InteractionManager to improve perceived performance
export const runAfterInteractions = (task) => {
  InteractionManager.runAfterInteractions(() => {
    requestAnimationFrame(() => {
      task();
    });
  });
};

// Debounce function to prevent excessive execution of functions
export const debounce = (func, wait = 300) => {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
};

// Throttle function to limit execution rate
export const throttle = (func, limit = 300) => {
  let inThrottle;
  return function executedFunction(...args) {
    if (!inThrottle) {
      func(...args);
      inThrottle = true;
      setTimeout(() => {
        inThrottle = false;
      }, limit);
    }
  };
};
