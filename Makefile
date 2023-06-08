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
		protobufs

PUBLIC_REPO := git@github.com:heap/heap-swift-core-sdk.git
INTERNAL_REPO := git@github.com:heap/heap-swift-core.git
MAIN_BRANCH := main
MAKE_DIR := $(shell pwd)
CORE_VERSION := $(shell ./DevTools/LibraryVersions.py --print --library=core)
INTERFACES_VERSION := $(shell ./DevTools/LibraryVersions.py --print --library=interfaces)

# Runs the unit test suite
# USAGE: $(call run_unit_tests,name of the test run,xcodebuild parameters)
define run_unit_tests

	@echo "+++ Running unit tests ($(1))"
	@echo "$(2)"

	-rm -rf build/reports/$(1).*
	-rm -rf Development/build/reports/$(1).*
	-rm build/.success

	-(cd Development && xcodebuild \
		-scheme HeapSwiftCoreDevelopment-Package \
		$(2) \
		-resultBundlePath ${MAKE_DIR}/build/reports/$(1).xcresult \
		clean test \
		&& echo "success" > ${MAKE_DIR}/build/.success \
	) | xcbeautify --report junit --junit-report-filename $(1)-$$BUILDKITE_JOB_ID.xml
	
	-mv Development/build/$(1).* build/
	-cd build/reports && tar -zcf $(1).xcresult.tgz $(1).xcresult
	-rm -rf build/reports/$(1).xcresult

endef

# Creates a device
# USAGE: $(call create_device,runtime,device type)
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

# Sets the public repo as a remote for the current repo.
# USAGE: $(call set_public_repo)
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

dependencies:
# (LOCAL) Install the dependencies required to run build steps.

	brew install gh
	brew install cocoapods
	brew install xcbeautify
	pip3 install semver

clear_results:
# (CI) Removes all test results.

	-rm -rf build/reports/

macos_unit_tests:
# (CI) Runs unit tests on macOS.
# This can be run locally to determine why it is breaking on the CDN.

	$(call run_unit_tests,macos_unit_tests,-destination "platform=macOS")
	@if [ ! -f build/.success ]; then exit 1; fi

catalyst_unit_tests:
# (CI) Runs unit tests on catalyst.
# This can be run locally to determine why it is breaking on the CDN.

	# The "," breaks `call` so we move it to a file
	mkdir -p build
	echo "platform=macOS,variant=Mac Catalyst" > build/.destination

	$(call run_unit_tests,catalyst_unit_tests,-destination "`cat ${MAKE_DIR}/build/.destination`")
	@if [ ! -f build/.success ]; then exit 1; fi

iphone_ios12_unit_tests:
# (CI) Runs unit tests on an iPhone targetting iOS 12.
# This can be run locally to determine why it is breaking on the CDN.

	DevTools/DeleteOldSimulators.rb
	
	$(call create_device,com.apple.CoreSimulator.SimRuntime.iOS-12-4,iPhone Xs)

	# The "," breaks `call` so we move it to a file
	mkdir -p build
	echo "platform=iOS Simulator,id=`cat build/.device_udid`" > build/.destination

	$(call run_unit_tests,iphone_ios12_unit_tests,-destination "`cat ${MAKE_DIR}/build/.destination`")

	$(call delete_device)

	@if [ ! -f build/.success ]; then exit 1; fi

iphone_ios16_unit_tests:
# (CI) Runs unit tests on an iPhone targetting iOS 16.
# This can be run locally to determine why it is breaking on the CDN.

	DevTools/DeleteOldSimulators.rb
	
	$(call create_device,com.apple.CoreSimulator.SimRuntime.iOS-16-0,iPhone Xs)

	# The "," breaks `call` so we move it to a file
	mkdir -p build
	echo "platform=iOS Simulator,id=`cat build/.device_udid`" > build/.destination

	$(call run_unit_tests,iphone_ios16_unit_tests,-destination "`cat ${MAKE_DIR}/build/.destination`")

	$(call delete_device)

	@if [ ! -f build/.success ]; then exit 1; fi

ipad_unit_tests:
# (CI) Runs unit tests on an iPad targetting iOS 12.
# This can be run locally to determine why it is breaking on the CDN.

	DevTools/DeleteOldSimulators.rb
	
	$(call create_device,com.apple.CoreSimulator.SimRuntime.iOS-12-4,iPad Air (4th generation))

	# The "," breaks `call` so we move it to a file
	mkdir -p build
	echo "platform=iOS Simulator,id=`cat build/.device_udid`" > build/.destination

	$(call run_unit_tests,ipad_unit_tests,-destination "`cat ${MAKE_DIR}/build/.destination`")

	$(call delete_device)

	@if [ ! -f build/.success ]; then exit 1; fi

tvos_unit_tests:
# (CI) Runs unit tests on tvOS.
# This can be run locally to determine why it is breaking on the CDN.

	DevTools/DeleteOldSimulators.rb
	
	$(call create_device,com.apple.CoreSimulator.SimRuntime.tvOS-12-4,Apple TV)

	# The "," breaks `call` so we move it to a file
	mkdir -p build
	echo "platform=tvOS Simulator,id=`cat build/.device_udid`" > build/.destination

	$(call run_unit_tests,tvos_unit_tests,-destination "`cat ${MAKE_DIR}/build/.destination`")

	$(call delete_device)

	@if [ ! -f build/.success ]; then exit 1; fi

watchos_unit_tests:
# (CI) Runs unit tests on watchOS.
# This can be run locally to determine why it is breaking on the CDN.

	DevTools/DeleteOldSimulators.rb
	
	$(call create_device,com.apple.CoreSimulator.SimRuntime.watchOS-9-0,Apple Watch Series 4 (40mm))

	# The "," breaks `call` so we move it to a file
	mkdir -p build
	echo "platform=watchOS Simulator,id=`cat build/.device_udid`" > build/.destination

	$(call run_unit_tests,watchos_unit_tests,-destination "`cat ${MAKE_DIR}/build/.destination`")

	$(call delete_device)

	@if [ ! -f build/.success ]; then exit 1; fi

macos_sample_app:
# (CI) Builds the macOS sample app.
# This can be run locally to determine why it is breaking on the CDN.

	set -o pipefail && \
	xcodebuild \
		-project Examples/SwiftCoreMacExample/SwiftCoreMacExample.xcodeproj \
		-scheme SwiftCoreMacExample \
		clean build \
	| xcbeautify

ios_sample_app:
# (CI) Builds the iOS sample app.
# This can be run locally to determine why it is breaking on the CDN.

	set -o pipefail && \
	xcodebuild \
		-project Examples/SwiftCoreiOSExample/SwiftCoreiOSExample.xcodeproj \
		-scheme SwiftCoreiOSExample \
		-destination "generic/platform=iOS Simulator" \
		clean build \
	| xcbeautify

ios_sample_extension:
# (CI) Builds the iOS sample extension.
# This can be run locally to determine why it is breaking on the CDN.

	set -o pipefail && \
	xcodebuild \
		-project Examples/SwiftCoreiOSExample/SwiftCoreiOSExample.xcodeproj \
		-scheme iOSWidgetExtension \
		-destination "generic/platform=iOS Simulator" \
		clean build \
	| xcbeautify

protobufs:
# (LOCAL) Rebuilds the protobuf Swift files.

	-rm Development/Sources/HeapSwiftCore/Protobufs/*.pb.swift
	cd Development/Sources/Protobufs && protoc --swift_out=../HeapSwiftCore/Protobufs *.proto

push_branch_to_public:
# (CI) Pushes the current branch to the public repo if it is `main`.
# This can be run locally if it is failing on the CDN.

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
# (CI) Pushes the current tag to the public repo.
# This can be run locally if it is failing on the CDN.

ifndef BUILDKITE_TAG
	$(error BUILDKITE_TAG is not set)
endif

	$(call set_public_repo)

	git fetch origin --tags
	git push public ${BUILDKITE_TAG}

publish_github_release_from_public_tag:
# (CI) Creates a GitHub release at https://github.com/heap/heap-swift-core-sdk/releases by checking out the tag a $BUILDKITE_TAG

ifndef BUILDKITE_TAG
	$(error BUILDKITE_TAG is not set)
endif

ifndef GITHUB_TOKEN
	$(error GITHUB_TOKEN is not set)
endif

	@GH_TOKEN="$${GITHUB_TOKEN}" ./DevTools/PublishGithubRelease.sh "$${BUILDKITE_TAG}"

release_core_from_origin_main:
# (LOCAL) Creates a tag for the core version on orgin/main using the version on that commit rather than the local version.
# This mitigate the risk of tagging from the wrong branch or commit.

	./DevTools/ReleaseFromRemoteBranch.sh core

release_interfaces_from_origin_main:
# (LOCAL) Creates a tag for the interfaces version on orgin/main using the version on that commit rather than the local version.
# This mitigate the risk of tagging from the wrong branch or commit.

	./DevTools/ReleaseFromRemoteBranch.sh interfaces

apply_interfaces_to_public_packages:
# (LOCAL) Updates HeapSwiftCore.podspec and Package.swift with the current version of HeapSwiftCoreInterfaces.
# This is to be run after the interfaces are deployed to the CDN.

	./DevTools/UpdatePackageDependency.sh "${INTERFACES_VERSION}"
	./DevTools/UpdatePodspecDependency.py --library=core HeapSwiftCoreInterfaces "${INTERFACES_VERSION}"

interfaces_xcframework:
# (CI) Builds and zips the interfaces XCFramework.
# This can be run locally to determine why it is breaking on the CDN.

	./DevTools/BuildInterfacesFramework.sh "${INTERFACES_VERSION}"
	./DevTools/CreateInterfacesXcframework.sh "${INTERFACES_VERSION}"

deploy_interfaces_to_s3:
# (CI) Uploads the already built interfaces zip file to the CDN. This should be called after `interfaces_xcframework`.  E.g.
# `make interfaces_xcframework deploy_interfaces_to_s3`.
# This command requires the CDN, an AWS token, and permission to upload to heapcdn, so it is not trivial to run locally.

ifndef BUILDKITE_TAG
	$(error BUILDKITE_TAG is not set)
endif

ifneq (${BUILDKITE_TAG},interfaces/${INTERFACES_VERSION})
	$(error Version mismatch between tag ${BUILDKITE_TAG} and ${INTERFACES_VERSION} from HeapSwiftCoreInterfaces.podspec)
endif

	@echo "--- Deploying heap-swift-core-interfaces-${INTERFACES_VERSION}.zip to S3"

	./DevTools/upload-to-s3.sh \
		'./build/xcframework/heap-swift-core-interfaces-${INTERFACES_VERSION}.zip' \
		'${INTERFACES_VERSION}' \
		"heapcdn" \
		'ios/heap-swift-core-interfaces-${INTERFACES_VERSION}.zip'

test_core_podspec:
	./DevTools/ValidateCorePodspec.sh

test_interfaces_podspec: interfaces_xcframework
	./DevTools/ValidateInterfacesPodspec.sh

deploy_core_podspec:
	@echo "--- Deploying HeapSwiftCore.podspec"
	pod trunk push HeapSwiftCore.podspec

deploy_interfaces_podspec:
	@echo "--- Deploying HeapSwiftCoreInterfaces.podspec"
	pod trunk push HeapSwiftCoreInterfaces.podspec

dynamic_xcframework:
# (CI) Builds and zips the dynamic XCFramework, used for Xamarin.
# This can be run locally to determine why it is breaking on the CDN.

	./DevTools/BuildDynamicFramework.sh "${CORE_VERSION}"
	./DevTools/CreateDynamicXcframework.sh "${CORE_VERSION}"

deploy_dynamic_to_s3:
# (CI) Uploads the already built dynamic zip file to the CDN. This should be called after `dynamic_xcframework`.  E.g.
# `make dynamic_xcframework deploy_dynamic_to_s3`.
# This command requires the CDN, an AWS token, and permission to upload to heapcdn, so it is not trivial to run locally.

ifndef BUILDKITE_TAG
	$(error BUILDKITE_TAG is not set)
endif

ifneq (${BUILDKITE_TAG},${CORE_VERSION})
	$(error Version mismatch between tag ${BUILDKITE_TAG} and ${CORE_VERSION} from HeapSwiftCore.podspec)
endif

	@echo "--- Deploying heap-swift-core-dynamic-${CORE_VERSION}.zip to S3"

	./DevTools/upload-to-s3.sh \
		'./build/xcframework/heap-swift-core-dynamic-${CORE_VERSION}.zip' \
		'${CORE_VERSION}' \
		"heapcdn" \
		'ios/heap-swift-core-dynamic-${CORE_VERSION}.zip'
