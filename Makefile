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
		ios_sample_extension \
		add_prerelease_pod_repo \
		remove_prerelease_pod_repo \
		push_prerelease_podspec \
		protobufs

PUBLIC_REPO := git@github.com:heap/heap-swift-core-sdk.git
INTERNAL_REPO := git@github.com:heap/heap-swift-core.git
MAIN_BRANCH := main
MAKE_DIR := $(shell pwd)

# 1 - test name, 2 - xcodebuild parameters
define run_unit_tests

	@echo "+++ Running unit tests ($(1))"
	@echo "$(2)"

	-rm -rf build/reports/$(1).*
	-rm -rf Development/build/reports/$(1).*
	-rm build/.success

	-(cd Development && xcodebuild \
		-scheme HeapSwiftCore \
		$(2) \
		-resultBundlePath ${MAKE_DIR}/build/reports/$(1).xcresult \
		clean test \
		&& echo "success" > ${MAKE_DIR}/build/.success \
	) | xcbeautify --report junit --junit-report-filename $(1)-$$BUILDKITE_JOB_ID.xml
	
	-mv Development/build/$(1).* build/
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

define set_public_repo

	if [ "$$(git remote get-url --push origin)" != '${INTERNAL_REPO}' ]; then \
		echo 'Incorrect origin. Aborting.'; \
		exit 1; \
	elif [ "$$(git remote get-url --push public)" = "" ]; then \
		git remote add public '${PUBLIC_REPO}'; \
	elif [ "$$(git remote get-url --push public)" != '${PUBLIC_REPO}' ]; then \
		git remote set-url --push public '${PUBLIC_REPO}'; \
	fi

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

	$(call run_unit_tests,catalyst_unit_tests,-destination "`cat ${MAKE_DIR}/build/.destination`")
	@if [ ! -f build/.success ]; then exit 1; fi

iphone_ios12_unit_tests:

	DevTools/DeleteOldSimulators.rb
	
	$(call create_device,com.apple.CoreSimulator.SimRuntime.iOS-12-4,iPhone Xs)

	# The "," breaks `call` so we move it to a file
	mkdir -p build
	echo "platform=iOS Simulator,id=`cat build/.device_udid`" > build/.destination

	$(call run_unit_tests,iphone_ios12_unit_tests,-destination "`cat ${MAKE_DIR}/build/.destination`")

	$(call delete_device)

	@if [ ! -f build/.success ]; then exit 1; fi

iphone_ios16_unit_tests:

	DevTools/DeleteOldSimulators.rb
	
	$(call create_device,com.apple.CoreSimulator.SimRuntime.iOS-16-0,iPhone Xs)

	# The "," breaks `call` so we move it to a file
	mkdir -p build
	echo "platform=iOS Simulator,id=`cat build/.device_udid`" > build/.destination

	$(call run_unit_tests,iphone_ios16_unit_tests,-destination "`cat ${MAKE_DIR}/build/.destination`")

	$(call delete_device)

	@if [ ! -f build/.success ]; then exit 1; fi

ipad_unit_tests:

	DevTools/DeleteOldSimulators.rb
	
	$(call create_device,com.apple.CoreSimulator.SimRuntime.iOS-12-4,iPad Air (4th generation))

	# The "," breaks `call` so we move it to a file
	mkdir -p build
	echo "platform=iOS Simulator,id=`cat build/.device_udid`" > build/.destination

	$(call run_unit_tests,ipad_unit_tests,-destination "`cat ${MAKE_DIR}/build/.destination`")

	$(call delete_device)

	@if [ ! -f build/.success ]; then exit 1; fi

tvos_unit_tests:

	DevTools/DeleteOldSimulators.rb
	
	$(call create_device,com.apple.CoreSimulator.SimRuntime.tvOS-12-4,Apple TV)

	# The "," breaks `call` so we move it to a file
	mkdir -p build
	echo "platform=tvOS Simulator,id=`cat build/.device_udid`" > build/.destination

	$(call run_unit_tests,tvos_unit_tests,-destination "`cat ${MAKE_DIR}/build/.destination`")

	$(call delete_device)

	@if [ ! -f build/.success ]; then exit 1; fi

watchos_unit_tests:

	DevTools/DeleteOldSimulators.rb
	
	$(call create_device,com.apple.CoreSimulator.SimRuntime.watchOS-9-0,Apple Watch Series 4 (40mm))

	# The "," breaks `call` so we move it to a file
	mkdir -p build
	echo "platform=watchOS Simulator,id=`cat build/.device_udid`" > build/.destination

	$(call run_unit_tests,watchos_unit_tests,-destination "`cat ${MAKE_DIR}/build/.destination`")

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

add_prerelease_pod_repo:

	@if [ ! -d ~/.cocoapods/repos/pre-release-cocoapods ]; then \
		pod repo add pre-release-cocoapods git@github.com:heap/pre-release-cocoapods.git main; \
	else \
		echo "Repo pre-release-cocoapods was already added."; \
	fi

protobufs:

	-rm Development/Sources/HeapSwiftCore/Protobufs/*.pb.swift
	cd Development/Sources/Protobufs && protoc --swift_out=../HeapSwiftCore/Protobufs *.proto
	./DevTools/FixProtoImports.sh

remove_prerelease_pod_repo:

	@if [ -d ~/.cocoapods/repos/pre-release-cocoapods ]; then \
		pod repo remove pre-release-cocoapods; \
	else \
		echo "Repo pre-release-cocoapods was already removed."; \
	fi

push_prerelease_podspec: add_prerelease_pod_repo

	pod repo push pre-release-cocoapods HeapSwiftCore.podspec

push_branch_to_public:

ifndef BUILDKITE_BRANCH
	$(error BUILDKITE_BRANCH is not set)
endif

ifneq (${BUILDKITE_BRANCH},${MAIN_BRANCH})
	$(error Current branch ${BUILDKITE_BRANCH} is not ${MAIN_BRANCH})
endif

	$(call set_public_repo)

	git fetch origin '${MAIN_BRANCH}:${MAIN_BRANCH}'
	git push public '${MAIN_BRANCH}'

push_tag_to_public:

ifndef BUILDKITE_TAG
	$(error BUILDKITE_TAG is not set)
endif

	$(call set_public_repo)

	git fetch origin --tags
	git push public ${BUILDKITE_TAG}

release_from_origin_main:

	./DevTools/ReleaseFromRemoteBranch.sh
