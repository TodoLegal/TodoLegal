require 'ffi'
require 'opus-ruby/version'
require 'opus-ruby/encoder'
require 'opus-ruby/decoder'

module Opus
  extend FFI::Library

  ffi_lib 'opus'

  module Constants
    OPUS_OK                               = 0
    OPUS_BAD_ARG                          = -1
    OPUS_BUFFER_TOO_SMALL                 = -2
    OPUS_INTERNAL_ERROR                   = -3
    OPUS_INVALID_PACKET                   = -4
    OPUS_UNIMPLEMENTED                    = -5
    OPUS_INVALID_STATE                    = -6
    OPUS_ALLOC_FAIL                       = -7
    OPUS_APPLICATION_VOIP                 = 2048
    OPUS_APPLICATION_AUDIO                = 2049
    OPUS_APPLICATION_RESTRICTED_LOWDELAY  = 2051
    OPUS_SIGNAL_VOICE                     = 3001
    OPUS_SIGNAL_MUSIC                     = 3002
    OPUS_SET_BITRATE_REQUEST              = 4002
    OPUS_SET_VBR_REQUEST                  = 4006
    OPUS_RESET_STATE                      = 4028
  end

  attach_function :opus_encoder_get_size, [:int], :int
  attach_function :opus_encoder_create, [:int32, :int, :int, :pointer], :pointer
  attach_function :opus_encoder_init, [:pointer, :int32, :int, :int], :int
  attach_function :opus_encode, [:pointer, :pointer, :int, :pointer, :int32], :int32
  attach_function :opus_encode_float, [:pointer, :pointer, :int, :pointer, :int32], :int32
  attach_function :opus_encoder_destroy, [:pointer], :void
  attach_function :opus_encoder_ctl, [:pointer, :int, :varargs], :int

  attach_function :opus_decoder_get_size, [:int], :int
  attach_function :opus_decoder_create, [:int32, :int, :pointer], :pointer
  attach_function :opus_decoder_init, [:pointer, :int32, :int], :int
  attach_function :opus_decode, [:pointer, :pointer, :int32, :pointer, :int, :int], :int
  attach_function :opus_decode_float, [:pointer, :pointer, :int32, :pointer, :int, :int], :int
  attach_function :opus_decoder_ctl, [:pointer, :int, :varargs], :int
  attach_function :opus_decoder_destroy, [:pointer], :void
end
