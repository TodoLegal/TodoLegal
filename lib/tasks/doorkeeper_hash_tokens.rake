namespace :doorkeeper do
  desc "Hash all existing plaintext access tokens and refresh tokens (SHA256)"
  task hash_existing_tokens: :environment do
    hashed_re = /\A[a-f0-9]{64}\z/

    total = 0
    skipped = 0

    Doorkeeper::AccessToken.find_each(batch_size: 1000) do |record|
      token_changed = false

      unless record.token.match?(hashed_re)
        record.update_column(:token, ::Digest::SHA256.hexdigest(record.token))
        token_changed = true
      end

      if record.refresh_token.present? && !record.refresh_token.match?(hashed_re)
        record.update_column(:refresh_token, ::Digest::SHA256.hexdigest(record.refresh_token))
        token_changed = true
      end

      if token_changed
        total += 1
      else
        skipped += 1
      end
    end

    puts "Hashed #{total} tokens. Skipped #{skipped} (already hashed)."
  end
end
