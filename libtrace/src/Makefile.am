AUTOMAKE_OPTIONS = subdir-objects
# enable PIC for x64 support
AM_CXXFLAGS = -fPIC -DPIC

lib_LIBRARIES = libtrace.a
pkginclude_HEADERS = trace.container.hpp arch.hpp frame.piqi.pb.h config.h

PIQI = piqi
PROTOC = protoc
PIQIFILE = ../../frame.piqi

frame.piqi.pb.cc frame.piqi.pb.h: frame.piqi.proto
	$(PROTOC) $< --cpp_out=. 

frame.piqi.proto: $(PIQIFILE)
	$(PIQI) to-proto $< -o $@

libtrace_a_SOURCES = frame.piqi.pb.h frame.piqi.pb.cc trace.container.cpp

utils_LDADD = libtrace.a -lprotobuf -lpthread

bin_PROGRAMS = readtrace copytrace
readtrace_SOURCES = readtrace.cpp
readtrace_LDADD = $(utils_LDADD)
copytrace_SOURCES = copytrace.cpp
copytrace_LDADD = $(utils_LDADD)
