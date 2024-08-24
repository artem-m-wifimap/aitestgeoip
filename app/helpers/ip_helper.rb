# frozen_string_literal: true

module IPHelper
  def request_ip
    if env['HTTP_X_FORWARDED_FOR']
      env['HTTP_X_FORWARDED_FOR'].split(',').first.strip
    else
      env['REMOTE_ADDR']
    end
  end
end
