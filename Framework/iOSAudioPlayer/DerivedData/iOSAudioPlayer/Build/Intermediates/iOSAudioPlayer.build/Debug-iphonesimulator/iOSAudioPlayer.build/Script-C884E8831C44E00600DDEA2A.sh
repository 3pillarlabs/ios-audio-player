#!/bin/sh
# This script is based on Jacob Van Order's answer on apple dev forums https://devforums.apple.com/message/971277
# See also http://spin.atomicobject.com/2011/12/13/building-a-universal-framework-for-ios/ for the start
# To get this to work with a Xcode 6 or later Cocoa Touch Framework, create Framework (or additionally an Aggregate Target)
# Then add this script into a Build Script Phase

if [ "false" == ${ALREADYINVOKED:-false} ]; then
export ALREADYINVOKED="true"

### Options ###
SIMULATOR_FRAMEWORK_PATH="${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${PROJECT_NAME}.framework"
IOS_FRAMEWORK_PATH="${BUILD_DIR}/${CONFIGURATION}-iphoneos/${PROJECT_NAME}.framework"
UNIVERSAL_FRAMEWORK_DIR="${BUILD_DIR}/${CONFIGURATION}-iphoneuniversal"
UNIVERSAL_FRAMEWORK_PATH="${UNIVERSAL_FRAMEWORK_DIR}/${PROJECT_NAME}.framework"

### Build Frameworks ###
# build for iphonesimulator
# default VALID_ARCHS="arm64 armv7 armv7s" but it is required to force it to "i386 x86_64"
# xcodebuild -target ${PROJECT_NAME} ONLY_ACTIVE_ARCH=NO -configuration ${CONFIGURATION} -sdk iphonesimulator  BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" VALID_ARCHS="i386 x86_64" clean build

xcodebuild -UseSanitizedBuildSystemEnvironment=YES -project ${PROJECT_NAME}.xcodeproj -scheme ${PROJECT_NAME} -sdk iphonesimulator -configuration ${CONFIGURATION} -destination 'platform=iOS Simulator,name=iPad' clean build CONFIGURATION_BUILD_DIR=${BUILD_DIR}/${CONFIGURATION}-iphonesimulator 2>&1

### Create directory for universal ###
rm -rf "${UNIVERSAL_FRAMEWORK_DIR}"
mkdir "${UNIVERSAL_FRAMEWORK_DIR}"
if [ ! -d "${UNIVERSAL_FRAMEWORK_DIR}" ]; then # check that universal framework directory is created
exit 1
fi

### Copy files Framework ###
cp -r "${IOS_FRAMEWORK_PATH}" "${UNIVERSAL_FRAMEWORK_PATH}"

### Make fat universal binary ###
lipo "${SIMULATOR_FRAMEWORK_PATH}/${PROJECT_NAME}" "${IOS_FRAMEWORK_PATH}/${PROJECT_NAME}" -create -output "${UNIVERSAL_FRAMEWORK_PATH}/${PROJECT_NAME}"

### If framework was written in Swift, we need to copy .swiftmodule files ###
SIMULATOR_SWIFT_MODULES_DIR="${SIMULATOR_FRAMEWORK_PATH}/Modules/${PROJECT_NAME}.swiftmodule/."
UNIVERSAL_SWIFT_MODULES_DIR="${UNIVERSAL_FRAMEWORK_PATH}/Modules/${PROJECT_NAME}.swiftmodule/."
if [ -d "${SIMULATOR_SWIFT_MODULES_DIR}" ]; then
cp -r "${SIMULATOR_SWIFT_MODULES_DIR}" "${UNIVERSAL_SWIFT_MODULES_DIR}"
fi
fi
