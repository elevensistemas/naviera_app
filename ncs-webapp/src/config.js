export const API_BASE = import.meta.env.VITE_API_BASE_URL || '';
export const CENTINELA_API_BASE = import.meta.env.VITE_CENTINELA_API_BASE_URL || '';

/**
 * Resuelve un subpath de la API de Intranet de forma segura.
 * Si `VITE_API_BASE_URL` está definida, retorna la URL absoluta.
 * De lo contrario, retorna la URL relativa original (compatible con el proxy de desarrollo).
 */
export const getApiEndpoint = (subPath) => {
  if (API_BASE) {
    const cleanBase = API_BASE.replace(/\/$/, '');
    const cleanSub = subPath.startsWith('/') ? subPath : `/${subPath}`;
    return `${cleanBase}${cleanSub}`;
  }
  return subPath;
};

/**
 * Resuelve un subpath de la API de Centinela de forma segura.
 * Si `VITE_CENTINELA_API_BASE_URL` está definida, retorna la URL absoluta.
 * De lo contrario, retorna la URL con el prefijo del proxy de desarrollo.
 */
export const getCentinelaEndpoint = (subPath) => {
  const cleanSub = subPath.startsWith('/') ? subPath : `/${subPath}`;
  if (CENTINELA_API_BASE) {
    const cleanBase = CENTINELA_API_BASE.replace(/\/$/, '');
    return `${cleanBase}${cleanSub}`;
  }
  return `/centinela-api${cleanSub}`;
};
