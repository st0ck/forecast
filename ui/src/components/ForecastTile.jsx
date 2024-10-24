import PropTypes from 'prop-types';

function ForecastTile({ forecast, cacheStatus, cacheAge }) {
  const convertDate = (dateString) => {
    const date = new Date(dateString + "T00:00:00");
    return new Intl.DateTimeFormat('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    }).format(date);
  }
  return (
    <div>
      <h2 className="text-xl font-semibold mb-2">Weather Forecast</h2>
      {cacheStatus && (
        <p className="text-sm text-gray-600 mb-4">
          Data retrieved from cache (Age: {cacheAge} seconds)
        </p>
      )}
      <div className={`grid grid-cols-1 md:grid-cols-3 lg:grid-cols-6 gap-4`}>
        {forecast.map((day) => (
          <div key={day.date} className="p-4 border rounded shadow">
            <h3 className="font-semibold flex justify-center">{convertDate(day.date)}</h3>
            <div className="flex justify-center">
              <img src={`/images/${day.status}.png`} alt={day.status} className="w-12 h-12 mb-2" />
            </div>
            <p className="flex justify-center">{day.min_temp} / {day.max_temp} &#8451;</p>
            <br />
            <p>Humidity: {day.humidity}%</p>
            <p>Wind: {day.wind_speed} m/s</p>
          </div>
        ))}
      </div>
    </div>
  );
}

ForecastTile.propTypes = {
  forecast: PropTypes.arrayOf(PropTypes.shape({
    date: PropTypes.string.isRequired,
    status: PropTypes.string.isRequired,
    temperature: PropTypes.number.isRequired,
    feels_like: PropTypes.number.isRequired,
    humidity: PropTypes.number.isRequired,
    wind_speed: PropTypes.number.isRequired,
  })).isRequired,
  cacheStatus: PropTypes.bool,
  cacheAge: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
};

export default ForecastTile;
