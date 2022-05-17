require 'dalli'
options = { namespace: "app_v1" }
dc = Dalli::Client.new('localhost:11211', options)
dc.set('abc', 123)
from_cache = dc.get('abc')
puts from_cache