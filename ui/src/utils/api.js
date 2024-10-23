import axios from 'axios';

export const getAddressSuggestions = async (query, sessionId) => {
  return axios.get('/api/v1/geo/address', { params: { q: query, session_id: sessionId } });
};
