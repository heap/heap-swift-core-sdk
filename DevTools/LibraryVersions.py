#! /usr/bin/python3
# DevTools/LibraryVersions.py - Helper for the library's version number
#
# Copyright (c) 2014 - 2017 Apple Inc. and the project authors
# Copyright (c) 2022 - 2023 Heap Inc.
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

def Fail(message):
  sys.stderr.write('Error: %s\n' % message)
  sys.exit(1)


def ExtractVersion(s):
  match = _VERSION_RE.match(s)
  return (match.group('major'), match.group('minor'), match.group('revision') or '0', match.group('prerelease'))


def ValidateFiles(podspec_path, version_swift_path):

  if podspec_path is None or version_swift_path is None:
    return
  
  podspec_version = ReadPodspecVersion(podspec_path)
  version_swift_version = ReadVersionSwiftVersion(version_swift_path)

  if podspec_version != version_swift_version:
    Fail('Version in %s did not match %s' % [podspec_path, version_swift_path])

def UpdatePodspec(podspec_path, version_string):
  if podspec_path is None:
    return
  
  (major, minor, revision, prerelease) = ExtractVersion(version_string)

  if prerelease:
    pod_version = '%s.%s.%s-%s' % (major, minor, revision, prerelease)
  else:
    pod_version = '%s.%s.%s' % (major, minor, revision)
  pod_content = open(podspec_path).read()
  pod_content = re.sub(r'version = \'(\d+\.\d+\.\d+(-(alpha|beta|rc).\d+)?)\'',
                       'version = \'%s\'' % pod_version,
                       pod_content)
  open(podspec_path, 'w').write(pod_content)

def UpdateVersionSwift(version_swift_path, version_string):
  if version_swift_path is None:
    return
  
  (major, minor, revision, prerelease) = ExtractVersion(version_string)

  if prerelease:
    version_swift_prerelease = '"%s"' % prerelease
  else:
    version_swift_prerelease = 'nil'
  version_swift_content = open(version_swift_path).read()
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
  open(version_swift_path, 'w').write(version_swift_content)

def ReadVersionSwiftVersion(version_swift_path):
  version_swift_content = open(version_swift_path).read()
  major = re.search(r'static let major = (\d+)\n', version_swift_content).group(1)
  minor = re.search(r'static let minor = (\d+)\n', version_swift_content).group(1)
  revision = re.search(r'static let revision = (\d+)\n', version_swift_content).group(1)
  prerelease = re.search(r'static let prerelease: String\? = "([^"]+)"\n', version_swift_content)

  if prerelease:
    return '%s.%s.%s-%s' % ( major, minor, revision, prerelease.group(1) )
  else:
    return '%s.%s.%s' % ( major, minor, revision )

def ReadPodspecVersion(podspec_path):

  pod_content = open(podspec_path).read()
  match = re.search(r'version = \'(\d+.\d+.\d+(-(alpha|beta|rc).\d+)?)\'', pod_content)
  if not match:
    Fail('Failed to extract a version from podspec')
  return match.group(1)

def main(args):
  usage = '%prog [OPTIONS] [VERSION]'
  description = (
      'Helper for the version numbers in the project sources.'
  )
  parser = optparse.OptionParser(usage=usage, description=description)
  parser.add_option('--library',
                    default='core', action='store', type='string',
                    help='The library to use.')
  parser.add_option('--validate',
                    default=False, action='store_true',
                    help='Check if the versions in all the files match.')
  parser.add_option('--print',
                    default=False, action='store_true',
                    help='Prints the version string.')
  opts, extra_args = parser.parse_args(args)

  if opts.validate and opts.print:
    parser.error('--print and --validate are mutually exclusive.')
  
  if opts.library == 'core' or opts.library == 'HeapSwiftCore':
    podspec_path = os.path.join(_PROJECT_ROOT, 'HeapSwiftCore.podspec')
    version_swift_path = os.path.join(_PROJECT_ROOT, 'Development/Sources/HeapSwiftCore/Version.swift')
  elif opts.library == 'interfaces' or opts.library == 'HeapSwiftCoreInterfaces':
    podspec_path = os.path.join(_PROJECT_ROOT, 'HeapSwiftCoreInterfaces.podspec')
    version_swift_path = None
  else:
    parser.error('Unknown library %s. Expected "core" or "interfaces"' % opts.library)

  if opts.print:
    if extra_args:
      parser.error('No version can be given when using --print.')

    if podspec_path is not None:
      print(ReadPodspecVersion(podspec_path))
    elif version_swift_path is not None:
      print(ReadVersionSwiftVersion(version_swift_path))
    else:
      parser.error('Library does not have a version file.')
    return 0
  
  if opts.validate:
    if extra_args:
      parser.error('No version can be given when using --validate.')
    
    ValidateFiles(podspec_path, version_swift_path)
    return 0
  
  if len(extra_args) != 1:
    parser.error('Expected one argument, the version number to ensure is in the sources.')
  
  if not _VERSION_RE.match(extra_args[0]):
    parser.error('Version does not appear to be in the form of x.y.z.')

  UpdatePodspec(podspec_path, extra_args[0])
  UpdateVersionSwift(version_swift_path, extra_args[0])
  ValidateFiles(podspec_path, version_swift_path)
  return 0

if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))
