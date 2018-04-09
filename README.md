# moonpol
moonpol is a traffic policer prototype on [libmoon](https://github.com/libmoon/libmoon) library. libmoon takes advantage of bringing DPDK and LuaJIT together, thus achieves high packet processing performance. Using this library, moonpol implements a token bucket algorithm for rate limiting and [DIR-24-8-BASIC](https://ieeexplore.ieee.org/document/662938/) for faster lookup.

## Supported HW
Any [DPDK supported NIC](http://dpdk.org/doc/nics) can utilize moonpol. In order to test usability before starting the policer, ['hello-world' example of libmoon library](https://github.com/libmoon/libmoon/blob/master/README.md#installation) can be tried first.

## Installation & Running
moonpol is nothing but a libmoon script. Therefore, it is strongly recommended to take a look at the [readme of libmoon](https://github.com/libmoon/libmoon) first. A configuration file is needed to run the policer. It is a list of subnets and rate limits in terms of pps.

```
# install dependencies and compile libmoon
sudo apt-get install git build-essential cmake linux-headers-`uname -r` lshw libnuma-dev
git clone https://github.com/libmoon/libmoon
git clone https://github.com/erkinkirdan/moonpol
mv moonpol/policer.lua moonpol/config libmoon
cd libmoon
./build.sh
# bind all NICs that are not actively used (no IP configured) to DPDK
sudo ./bind-interfaces.sh
# configure hugetlbfs
sudo ./setup-hugetlbfs.sh
# run policer
sudo ./build/libmoon policer.lua
```

### Helpers
generator.lua can be used for load generator under libmoon.

config_ru can be used for another configuration.

configgen.cpp is a small program for configuration file generator.
