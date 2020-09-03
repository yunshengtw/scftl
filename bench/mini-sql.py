#!/usr/bin/python

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
