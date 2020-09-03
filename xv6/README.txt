Prerequisite:

* liblightnvm:
git clone https://github.com/OpenChannelSSD/liblightnvm.git
cd liblightnvm

# Default configuration, build and install
make configure
make
sudo make install


Init:

make all
make fs.img

Run:
mkdir /tmp/xv6fs 
./xv6fs fs.img /tmp/xv6fs -f -d -s

Some things that work:

ls -l /tmp/xv6fs/hello.txt
cat /tmp/xv6fs/hello.txt
echo hello > /tmp/xv6fs/x.txt
cat /tmp/xv6fs/x.txt
ls /tmp/xv6fs
ls -l /tmp/xv6fs

Unmount:

fusermount -u /tmp/xv6fs1

Test Failure cleaning:

sudo umount -l /tmp/xv6fs 

