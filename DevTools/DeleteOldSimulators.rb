#!/usr/bin/env ruby
# DevTools/DeleteOldSimulators.rb - A script to delete stray simulators created by `make`.
#
# All simulators created for testing are tagged with a timestamp. While they typically close on their own at the end of testing,
# stray simulators can get stuck if builds are aborted or there are other unexpected failures. This script deletes those orphaned
# simulators.

require 'JSON'
require 'date'

list = JSON.parse `xcrun simctl list -j devices`

# Remove timezone consistently
now_as_string = DateTime.now.strftime('%Y-%m-%d.%H.%M.%S')
now = DateTime.strptime(now_as_string, '%Y-%m-%d.%H.%M.%S')

for deviceType, devices in list["devices"]
  for device in devices
    begin
      creation_date = DateTime.strptime(device["name"][0..18], '%Y-%m-%d.%H.%M.%S')
    rescue
      next
    end

    age_in_minutes = ((now - creation_date) * 24 * 60).to_i
    next if age_in_minutes < 60

    puts "Removing #{device["name"]} which is #{age_in_minutes} minutes old"

    `xcrun simctl delete '#{device["name"]}'`
  end
end
