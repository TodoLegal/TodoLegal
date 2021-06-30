# opus-ruby

OPUS-Ruby is a Ruby Gem for working with the OPUS Audio Codec.
OPUS-Ruby uses the Ruby-FFI extension to wrap the native OPUS library code.
This means that you must have OPUS installed in order for this gem to work.

## Installation

Add this line to your application's Gemfile:

    gem 'opus-ruby'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install opus-ruby

## Usage

    # Create new encoder with a sample rate of 48 kHz, a frame size of 480 bytes and 1 channel
    encoder = Opus::Encoder.new 48000, 480, 1
    # Set the bitrate to 32 kbit/s
    encoder.bitrate = 32000
    # Set the VBR rate to 0 (CBR)
    encoder.vbr_rate = 0

    # Encode some raw audio
    encoded = encoder.encode(raw_audio, 960)

    # Safely destroy encoder
    encoder.destroy

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
