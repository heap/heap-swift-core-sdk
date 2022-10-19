.PHONY: \
		macos_unit_tests \
		catalyst_unit_tests \
		iphone_ios12_unit_tests \
		iphone_ios16_unit_tests \
		ipad_unit_tests \
		tvos_unit_tests \
		watchos_unit_tests \
		macos_sample_app \
		ios_sample_app \
		ios_sample_extension


# 1 - test name, 2 - xcodebuild parameters
define run_unit_tests

	@echo "+++ Running unit tests ($(1))"
	@echo "$(2)"

	-rm -rf build/reports/$(1).*
	-rm build/.success

	-(xcodebuild \
		-scheme HeapSwiftCore \
		$(2) \
		-resultBundlePath build/reports/$(1).xcresult \
		clean test \
		&& echo "success" > build/.success \
	) | xcbeautify --report junit --junit-report-filename $(1)-$$BUILDKITE_JOB_ID.xml
	
	-cd build/reports && tar -zcf $(1).xcresult.tgz $(1).xcresult
	-rm -rf build/reports/$(1).xcresult

endef

# 1 - runtime, 2 - device type
define create_device

	@echo "--- Creating device ($(1), $(2))"

	mkdir -p build
	-rm build/.device_name
	-rm build/.device_udid
	echo "`date +'%Y-%m-%d.%H.%M.%S'`-$(1)" > build/.device_name

	xcrun simctl create "`cat build/.device_name`" "$(2)" "$(1)" > build/.device_udid

	xcrun simctl boot "`cat build/.device_udid`"

endef

define delete_device

	@echo "--- Deleting device"
	-xcrun simctl delete "`cat build/.device_udid`"

endef

clear_results:

	-rm -rf build/reports/

macos_unit_tests:

	$(call run_unit_tests,macos_unit_tests,-destination "platform=macOS")
	@if [ ! -f build/.success ]; then exit 1; fi

catalyst_unit_tests:

	# The "," breaks `call` so we move it to a file
	mkdir -p build
	echo "platform=macOS,variant=Mac Catalyst" > build/.destination

	$(call run_unit_tests,catalyst_unit_tests,-destination "`cat build/.destination`")
	@if [ ! -f build/.success ]; then exit 1; fi

iphone_ios12_unit_tests:

	DevTools/DeleteOldSimulators.rb
	
	$(call create_device,com.apple.CoreSimulator.SimRuntime.iOS-12-4,iPhone Xs)

	# The "," breaks `call` so we move it to a file
	mkdir -p build
	echo "platform=iOS Simulator,id=`cat build/.device_udid`" > build/.destination

	$(call run_unit_tests,iphone_ios12_unit_tests,-destination "`cat build/.destination`")

	$(call delete_device)

	@if [ ! -f build/.success ]; then exit 1; fi

iphone_ios16_unit_tests:

	DevTools/DeleteOldSimulators.rb
	
	$(call create_device,com.apple.CoreSimulator.SimRuntime.iOS-16-0,iPhone Xs)

	# The "," breaks `call` so we move it to a file
	mkdir -p build
	echo "platform=iOS Simulator,id=`cat build/.device_udid`" > build/.destination

	$(call run_unit_tests,iphone_ios16_unit_tests,-destination "`cat build/.destination`")

	$(call delete_device)

	@if [ ! -f build/.success ]; then exit 1; fi

ipad_unit_tests:

	DevTools/DeleteOldSimulators.rb
	
	$(call create_device,com.apple.CoreSimulator.SimRuntime.iOS-12-4,iPad Air (4th generation))

	# The "," breaks `call` so we move it to a file
	mkdir -p build
	echo "platform=iOS Simulator,id=`cat build/.device_udid`" > build/.destination

	$(call run_unit_tests,ipad_unit_tests,-destination "`cat build/.destination`")

	$(call delete_device)

	@if [ ! -f build/.success ]; then exit 1; fi

tvos_unit_tests:

	DevTools/DeleteOldSimulators.rb
	
	$(call create_device,com.apple.CoreSimulator.SimRuntime.tvOS-12-4,Apple TV)

	# The "," breaks `call` so we move it to a file
	mkdir -p build
	echo "platform=tvOS Simulator,id=`cat build/.device_udid`" > build/.destination

	$(call run_unit_tests,tvos_unit_tests,-destination "`cat build/.destination`")

	$(call delete_device)

	@if [ ! -f build/.success ]; then exit 1; fi

watchos_unit_tests:

	DevTools/DeleteOldSimulators.rb
	
	$(call create_device,com.apple.CoreSimulator.SimRuntime.watchOS-9-0,Apple Watch Series 4 (40mm))

	# The "," breaks `call` so we move it to a file
	mkdir -p build
	echo "platform=watchOS Simulator,id=`cat build/.device_udid`" > build/.destination

	$(call run_unit_tests,watchos_unit_tests,-destination "`cat build/.destination`")

	$(call delete_device)

	@if [ ! -f build/.success ]; then exit 1; fi

macos_sample_app:

	set -o pipefail && \
	xcodebuild \
		-project Examples/SwiftCoreMacExample/SwiftCoreMacExample.xcodeproj \
		-scheme SwiftCoreMacExample \
		clean build \
	| xcbeautify

ios_sample_app:

	set -o pipefail && \
	xcodebuild \
		-project Examples/SwiftCoreiOSExample/SwiftCoreiOSExample.xcodeproj \
		-scheme SwiftCoreiOSExample \
		-destination "generic/platform=iOS Simulator" \
		clean build \
	| xcbeautify

ios_sample_extension:

	set -o pipefail && \
	xcodebuild \
		-project Examples/SwiftCoreiOSExample/SwiftCoreiOSExample.xcodeproj \
		-scheme iOSWidgetExtension \
		-destination "generic/platform=iOS Simulator" \
		clean build \
	| xcbeautify

