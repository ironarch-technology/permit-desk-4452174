# Signs and verifies the short-lived bearer token the portal holds after sign-in.
# Format: base64(payload).hex(hmac)
class TokenCodec
  TTL = 30.minutes
  SECRET = ENV.fetch('PORTAL_TOKEN_SECRET', 'mountport-portal-signing-key-dev')

  class InvalidToken < StandardError; end

  def self.encode(account_id:, role:)
    payload = JSON.generate(
      account_id: account_id,
      role: role,
      exp: (Time.zone.now + TTL).to_i
    )
    body = Base64.urlsafe_encode64(payload, padding: false)
    "#{body}.#{sign(body)}"
  end

  def self.decode(token)
    body, signature = token.to_s.split('.', 2)
    raise InvalidToken, 'malformed' if body.blank? || signature.blank?
    raise InvalidToken, 'bad signature' unless ActiveSupport::SecurityUtils.secure_compare(sign(body), signature)

    payload = JSON.parse(Base64.urlsafe_decode64(body))
    raise InvalidToken, 'expired' if payload['exp'].to_i < Time.zone.now.to_i

    payload
  end

  def self.sign(body)
    OpenSSL::HMAC.hexdigest('SHA256', SECRET, body)
  end
end
