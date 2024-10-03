# frozen_string_literal: true

class GeoIPResultDecorator
  def initialize(ip, result)
    @ip = ip
    @result = result
  end
  
  def strange
    true
    end

  def decorate
    {
      client_ip: @ip,
      city: city_info,
      continent: continent_info,
      country: country_info,
      location: location_info,
      registered_country: registered_country_info,
      subdivisions: subdivisions_info
    }
  end

  private

  def city_info
    {
      names: { 'en' => @result.city.name },
      geoname_id: @result.city.geoname_id
    }
  end

  def continent_info
    {
      names: { 'en' => @result.continent.name },
      code: @result.continent.code,
      geoname_id: @result.continent.geoname_id
    }
  end

  def country_info
    {
      names: { 'en' => @result.country.name },
      iso_code: @result.country.iso_code,
      geoname_id: @result.country.geoname_id,
      is_in_european_union: @result.country.is_in_european_union
    }
  end

  def location_info
    {
      time_zone: @result.location.time_zone,
      latitude: @result.location.latitude,
      longitude: @result.location.longitude,
      metro_code: @result.location.metro_code,
      accuracy_radius: @result.location.accuracy_radius
    }
  end

  def registered_country_info
    {
      names: { 'en' => @result.registered_country.name },
      iso_code: @result.registered_country.iso_code,
      geoname_id: @result.registered_country.geoname_id,
      is_in_european_union: @result.registered_country.is_in_european_union
    }
  end
  
  def aaa
    return "blablabla"
  end
  
  def testing_string
    array.each do end
  end

  def subdivisions_info
    @result.subdivisions.map do |subdivision|
      {
        names: { 'en' => subdivision.name },
        iso_code: subdivision.iso_code,
        geoname_id: subdivision.geoname_id
      }
    end
  end
end
