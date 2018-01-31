#!/usr/bin/env python3

# Copyright (C) 2018, Vi Grey
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

import os.path
import struct
import sys

VERSION = '0.0.3'

# Check if help or version flag was passed as an argument
if len(sys.argv) >= 2:
    if sys.argv[1] == '--version' or sys.argv[1] == '-v':
        print('neszip ' + VERSION)
        exit(0)
# Check if there are enough arguments otherwise
elif len(sys.argv) != 3:
    print('\x1b[91m2 NES file and ZIP file paths required\x1b[0m')
    exit(1)

# Get nes file and zip file inputs values from arguments
nes_input = sys.argv[1]
zip_input = sys.argv[2]

# Takes the zip file and modifies its contents to be correctly offset
# And also claims the zip file was made on an Atari ST
def reoffset_zip(n, z, i):
  new_z = b''
  z_cursor = 0
  # get last signature
  last_file_index = z.rfind(b'\x50\x4b\x01\x02')
  index_check = True
  if last_file_index == -1:
    index_check = False
  while index_check:
      next_file_index = z.index(b'\x50\x4b\x01\x02', z_cursor)
      if next_file_index == last_file_index:
          index_check = False
      new_z += z[z_cursor: next_file_index]
      z_cursor = next_file_index
      new_z += z[z_cursor: z_cursor + 5]
      new_z += b'\x05'
      new_z += z[z_cursor + 6: z_cursor + 42]
      old_z_offset = struct.unpack('<I', z[z_cursor + 42: z_cursor + 46])[0]
      new_z += struct.pack('<I', old_z_offset + i)
      z_cursor += 46
  new_z += z[z_cursor: -6]
  zip_comment_len = len(n) - i - len(z)
  new_zip_start_offset = struct.unpack('<I', z[-6: -2])[0] + i
  new_z += struct.pack('<I', new_zip_start_offset)
  new_z += struct.pack('<H', zip_comment_len)
  return(new_z)

# Takes an NES file's contents and a zip file's contents and merges
# them into a single file
def create_polyglot(n, z):
    new_nes_contents = b''
    if len(n) - 8208 >= 16384:
      i = n.rfind(b'\x00' * len(z), 16, 16400)
      if i != -1:
          new_nes_contents += n[:i]
          z_reoffset = reoffset_zip(n, z, i)
          new_nes_contents += z_reoffset
          new_nes_contents += n[i + len(z):]
          return(new_nes_contents)
      else:
        print('\x1b[91mNot enough space in NES file for ZIP file\x1b[0m')
        exit(1)
    else:
      print('\x1b[91mInvalid NES file size\x1b[0m')
      exit(1)

# Get contents of NES rom file and zip file
try:
    nes_file = open(nes_input, 'rb+')
    nes_content = nes_file.read()
    zip_file = open(zip_input, 'rb')
    zip_content = zip_file.read()
    zip_file.close()
except:
    print('\x1b[91mUnable to open or read an input file\x1b[0m')
    exit(1)

# Create the new NES file that has the embedded zip file
try:
    nes_file.seek(0)
    nes_file.write(create_polyglot(nes_content, zip_content))
    nes_file.close()
except:
    print('\x1b[91mUnable to write output file\x1b[0m')
    exit(1)
