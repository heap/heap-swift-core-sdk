#!/usr/bin/env bash

set -o errexit
set -x

get_sim_id () {
    xcrun simctl list devices |grep "$1" | head -1 | cut -d "(" -f2 | cut -d ")" -f1
} 

echo '--- Creating simulators'
DevTools/SimulatorCreator.rb

echo '--- Testing macOS'
xcodebuild -scheme HeapSwiftCore -destination "platform=macOS" clean test |xcpretty

echo '--- Testing macOS Catalyst'
xcodebuild -scheme HeapSwiftCore -destination "platform=macOS,variant=Mac Catalyst" clean test |xcpretty

echo '--- Testing iOS'
xcodebuild -scheme HeapSwiftCore -destination "platform=iOS Simulator,id=$(get_sim_id heap-swift-core-runner-phone)" clean test |xcpretty

echo '--- Testing iPadOS'
xcodebuild -scheme HeapSwiftCore -destination "platform=iOS Simulator,id=$(get_sim_id heap-swift-core-runner-pad)" clean test |xcpretty

echo '--- Testing tvOS'
xcodebuild -scheme HeapSwiftCore -destination "platform=tvOS Simulator,id=$(get_sim_id heap-swift-core-runner-tv)" clean test |xcpretty

echo '--- Testing watchOS'
xcodebuild -scheme HeapSwiftCore -destination "platform=watchOS Simulator,id=$(get_sim_id heap-swift-core-runner-watch)" clean test |xcpretty
