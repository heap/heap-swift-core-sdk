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

_VERSION_RE = re.compile(r'^((?P<operator>|>=|<|<=|~>) *)?(?P<major>\d+)(\.(?P<minor>\d+)(\.(?P<revision>\d+))?(-(?P<prerelease>(alpha|beta|rc).\d+))?)?$')

_PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def Fail(message):
  sys.stderr.write('Error: %s\n' % message)
  sys.exit(1)



def UpdatePodspecDependency(podspec_path, dependency, version_string):

  previous = ReadPodspecDependency(podspec_path, dependency)

  pod_content = open(podspec_path).read()
  pod_content = re.sub(r'dependency \'' + re.escape(dependency) + r'\', *\'[^\']+\'',
                       'dependency \'%s\', \'%s\'' % (dependency, version_string),
                       pod_content)
  open(podspec_path, 'w').write(pod_content)

  print('Updated podspec dependency %s from %s to %s' % (dependency, previous, version_string))


def ReadPodspecDependency(podspec_path, dependency):

  pod_content = open(podspec_path).read()
  match = re.search(r'dependency \'' + re.escape(dependency) + r'\', *\'([^\']+)\'', pod_content)
  if not match:
    Fail('Failed to extract a version from podspec')
  return match.group(1)

def ValidatePodspecDependency(podspec_path, dependency, version_string):

  stored_version_string = ReadPodspecDependency(podspec_path, dependency)

  if version_string != stored_version_string:
    Fail('Stored version string was %s' % stored_version_string)
  
def main(args):
  usage = '%prog [OPTIONS] DEPENDENCY VERSION'
  description = (
      'Helper for setting podspec dependencies.'
  )
  parser = optparse.OptionParser(usage=usage, description=description)
  parser.add_option('--library',
                    default='core', action='store', type='string',
                    help='The library to use.')
  opts, extra_args = parser.parse_args(args)

  if opts.library == 'core':
    podspec_path = os.path.join(_PROJECT_ROOT, 'HeapSwiftCore.podspec')
    version_swift_path = os.path.join(_PROJECT_ROOT, 'Development/Sources/HeapSwiftCore/Version.swift')
  elif opts.library == 'interfaces':
    podspec_path = os.path.join(_PROJECT_ROOT, 'HeapSwiftCoreInterfaces.podspec')
    version_swift_path = None
  else:
    parser.error('Unknown library %s. Expected "core" or "interfaces"' % opts.library)

  if len(extra_args) != 2:
    parser.error('Expected two arguments, the dependency and the constraints.')

  dependency = extra_args[0]
  version = extra_args[1]
  
  if not _VERSION_RE.match(version):
    parser.error('Version does not appear to be in the form of x.y.z.')

  UpdatePodspecDependency(podspec_path, dependency, version)
  ValidatePodspecDependency(podspec_path, dependency, version)
  return 0

if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))
