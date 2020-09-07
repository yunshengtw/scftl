#!/usr/bin/python

# FSCQ: a verified file system
# 
# Copyright (c) 2015, Massachusetts Institute of Technology
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# run this as:
#   python mini-sql.py | sqlite3 /mnt/fscq/sqlite.db

scale = 1000

print ".bail ON"

print "create table x (a int, b string);"
for i in range(0, scale):
    print "insert into x (a, b) values ({0}, '{1}');".format(
        i, "foo {0} bar {0} bench {0} mark {0}".format(i) * 10)

for i in range(0, scale):
    print "update x set b = 'bar%d' where a = %d;" % (i, (i * 4));
