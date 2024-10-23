import { useState, useEffect, useMemo } from "react";
import { useDebounce } from 'use-debounce';
import { v4 as uuidv4 } from 'uuid';
import { getAddressSuggestions } from './utils/api';

function App() {
  const [query, setQuery] = useState("");
  const [address, setAddress] = useState(null);
  const [manualSelect, setManualSelect] = useState(false);
  const [suggestions, setSuggestions] = useState([]);
  const [sessionId, setSessionId] = useState("");
  const [debouncedSearch] = useDebounce(query, 500);

  useEffect(() => {
    setSessionId(uuidv4());
  }, []);

  useEffect(() => {
    (async () => {
      if (!manualSelect && debouncedSearch.length > 2) {
        try {
          const response =
            await getAddressSuggestions(debouncedSearch, sessionId);
          setSuggestions(response.data.data);
        } catch (error) {
          console.error("Error fetching address suggestions: ", error);
          setSuggestions([]);
        }
      } else {
        setSuggestions([]);
      }
    })();
    setManualSelect(false);
  }, [debouncedSearch]);

  const handleSelectSuggestion = async (suggestion) => {
    setAddress(suggestion);
    setQuery(suggestion.address);
    setSuggestions([]);
    setManualSelect(true);
  };

  const suggestionsList = useMemo(() => (
    suggestions.length > 0 && (
      <ul className="border rounded mb-4">
        {suggestions.map((suggestion) => (
          <li
            key={suggestion.latitude + suggestion.longitude}
            className="p-2 cursor-pointer hover:bg-gray-100"
            onClick={() => handleSelectSuggestion(suggestion)}
          >
            {suggestion.address}
          </li>
        ))}
      </ul>
    )
  ), [suggestions]);

  return (
    <>
      <div className="container mx-auto p-4">
        <h1 className="text-2xl font-bold mb-4">Weather Forecast</h1>
        <input
          type="text"
          className="w-full p-2 border rounded mb-2"
          placeholder="Enter an address"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
        {suggestionsList}
        {address && (
          <div className="p-6 border rounded shadow mb-6">
            <h2 className="text-xl font-bold">Coordinates for {address.address}</h2>
            <p>Lat: {address.latitude}</p>
            <p>Lon: {address.longitude}</p>
          </div>
        )}
      </div>
    </>
  );
}

export default App;
