import PropTypes from 'prop-types';

function CurrentWeather({ weather, cacheStatus, cacheAge }) {
  return (
    <div className="p-6 border rounded shadow mb-6">
      <h2 className="text-xl font-semibold mb-4">Current Weather</h2>
      {cacheStatus && (
        <p className="text-sm text-gray-600 mb-2">
          Data retrieved from cache (Age: {cacheAge} seconds)
        </p>
      )}
      <div className="flex items-center">
        <div className="justify-center mr-4">
          <div className="flex justify-center">
            <img src={`/images/${weather.status}.png`} alt={weather.status} className="w-16 h-16" />
          </div>
          <p className="text-lg flex justify-center">{weather.temperature} &#8451;</p>
        </div>
        <div>
          <p>Feels Like: {weather.feels_like} &#8451;</p>
          <p>Humidity: {weather.humidity}%</p>
          <p>Wind Speed: {weather.wind_speed} m/s</p>
        </div>
      </div>
    </div>
  );
}

CurrentWeather.propTypes = {
  weather: PropTypes.shape({
    status: PropTypes.string.isRequired,
    temperature: PropTypes.number.isRequired,
    feels_like: PropTypes.number.isRequired,
    humidity: PropTypes.number.isRequired,
    wind_speed: PropTypes.number.isRequired,
  }).isRequired,
  cacheStatus: PropTypes.bool,
  cacheAge: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
};

export default CurrentWeather;
