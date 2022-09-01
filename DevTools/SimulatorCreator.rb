#!/usr/bin/env ruby

require 'JSON'
require 'set'

prefix = "heap-swift-core-runner-"

device_types = JSON.parse `xcrun simctl list -j devicetypes`
runtimes = JSON.parse `xcrun simctl list -j runtimes`
devices = JSON.parse `xcrun simctl list -j devices`

existing_device_names = Set[]

devices['devices'].each do |runtime, runtime_devices|
  runtime_devices.each do |device|
    if device['name'].start_with?(prefix)
        existing_device_names.add(device['name'])
    end
  end
end

def make_device(runtime, name, device_name, existing_device_names)
  device_type = runtime['supportedDeviceTypes'].find { |device_type| device_type['name'].include?(name) }
  return false if device_type.nil?

  return true unless existing_device_names.add?(device_name)

  puts "Creating #{device_type['name']} with #{runtime['name']}"
  command = "xcrun simctl create \"#{device_name}\" #{device_type['identifier']} #{runtime['identifier']}"
  command_output = `#{command}`
  sleep 0.5
  true

end


target_runtimes = runtimes['runtimes'].select{|runtime| runtime['isAvailable'] }

target_runtimes.each do |runtime|
  break if make_device runtime, 'iPhone X', "#{prefix}phone", existing_device_names
end

target_runtimes.each do |runtime|
  break if make_device runtime, 'iPad (6th generation)', "#{prefix}pad", existing_device_names
end

target_runtimes.each do |runtime|
  break if make_device runtime, 'Apple TV', "#{prefix}tv", existing_device_names
end

target_runtimes.each do |runtime|
  break if make_device runtime, 'Apple Watch', "#{prefix}watch", existing_device_names
end