#! /usr/bin/python3
# DevTools/LibraryVersions.py - Helper for the library's version number
#
# Copyright (c) 2014 - 2017 Apple Inc. and the project authors
# Copyright (c) 2022 Heap Inc.
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See LICENSE.txt for license information:
# https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
#

"""Helper script for the versions numbers in the project sources."""

import optparse
import os
import re
import sys

_VERSION_RE = re.compile(r'^(?P<major>\d+)\.(?P<minor>\d+)(.(?P<revision>\d+))?(-(?P<prerelease>(alpha|beta|rc).\d+))?$')

_PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_PODSPEC_PATH = os.path.join(_PROJECT_ROOT, 'HeapSwiftCore.podspec')
_VERSION_SWIFT_PATH = os.path.join(_PROJECT_ROOT, 'Development/Sources/HeapSwiftCore/Version.swift')

def Fail(message):
  sys.stderr.write('Error: %s\n' % message)
  sys.exit(1)


def ExtractVersion(s):
  match = _VERSION_RE.match(s)
  return (match.group('major'), match.group('minor'), match.group('revision') or '0', match.group('prerelease'))


def ValidateFiles():
  # Extra from HeapSwiftCore.podspec
  pod_content = open(_PODSPEC_PATH).read()
  match = re.search(r'version = \'(\d+.\d+.\d+(-(alpha|beta|rc).\d+)?)\'', pod_content)
  if not match:
    Fail('Failed to extract a version from HeapSwiftCore.podspec')
  (major, minor, revision, prerelease) = ExtractVersion(match.group(1))

  # Test Development/Sources/HeapSwiftCore/Version.swift
  version_swift_content = open(_VERSION_SWIFT_PATH).read()
  major_line = 'static let major = %s\n' % major
  minor_line = 'static let minor = %s\n' % minor
  revision_line = 'static let revision = %s\n' % revision
  if prerelease:
    prerelease_line = 'static let prerelease: String? = "%s"\n' % prerelease
  else:
    prerelease_line = 'static let prerelease: String? = nil\n'

  had_major = major_line in version_swift_content
  had_minor = minor_line in version_swift_content
  had_revision = revision_line in version_swift_content
  had_prerelease = prerelease_line in version_swift_content
  if not had_major or not had_minor or not had_revision or not had_prerelease:
    Fail('Version in Development/Sources/HeapSwiftCore/Version.swift did not match HeapSwiftCore.podspec')


def UpdateFiles(version_string):
  (major, minor, revision, prerelease) = ExtractVersion(version_string)

  # Update HeapSwiftCore.podspec
  if prerelease:
    pod_version = '%s.%s.%s-%s' % (major, minor, revision, prerelease)
  else:
    pod_version = '%s.%s.%s' % (major, minor, revision)
  pod_content = open(_PODSPEC_PATH).read()
  pod_content = re.sub(r'version = \'(\d+\.\d+\.\d+(-(alpha|beta|rc).\d+)?)\'',
                       'version = \'%s\'' % pod_version,
                       pod_content)
  open(_PODSPEC_PATH, 'w').write(pod_content)

  # Update Development/Sources/HeapSwiftCore/Version.swift
  if prerelease:
    version_swift_prerelease = '"%s"' % prerelease
  else:
    version_swift_prerelease = 'nil'
  version_swift_content = open(_VERSION_SWIFT_PATH).read()
  version_swift_content = re.sub(r'static let major = \d+\n',
                                 'static let major = %s\n' % major,
                                 version_swift_content)
  version_swift_content = re.sub(r'static let minor = \d+\n',
                                 'static let minor = %s\n' % minor,
                                 version_swift_content)
  version_swift_content = re.sub(r'static let revision = \d+\n',
                                 'static let revision = %s\n' % revision,
                                 version_swift_content)
  version_swift_content = re.sub(r'static let prerelease: String\? = (nil|"[^"]+")\n',
                                 'static let prerelease: String? = %s\n' % version_swift_prerelease,
                                 version_swift_content)
  open(_VERSION_SWIFT_PATH, 'w').write(version_swift_content)


def main(args):
  usage = '%prog [OPTIONS] [VERSION]'
  description = (
      'Helper for the version numbers in the project sources.'
  )
  parser = optparse.OptionParser(usage=usage, description=description)
  parser.add_option('--validate',
                    default=False, action='store_true',
                    help='Check if the versions in all the files match.')
  opts, extra_args = parser.parse_args(args)

  if opts.validate:
    if extra_args:
      parser.error('No version can be given when using --validate.')
  else:
    if len(extra_args) != 1:
      parser.error('Expected one argument, the version number to ensure is in the sources.')
    if not _VERSION_RE.match(extra_args[0]):
      parser.error('Version does not appear to be in the form of x.y.z.')

  # Always validate, just use the flag to tell if we're expected to also have set something.
  if not opts.validate:
    UpdateFiles(extra_args[0])
  ValidateFiles()
  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))
