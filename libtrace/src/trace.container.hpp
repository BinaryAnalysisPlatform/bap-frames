#ifndef TRACE_CONTAINER_HPP
#define TRACE_CONTAINER_HPP

#ifndef _WIN32
#include "config.h"
#endif
#include "frame_arch.h"



/**
 * A container for trace frames.  We do not use protobuffers because
 * protobuffers can not stream output (the whole trace would have to
 * be in memory before being written) or input (the whole trace would
 * need to be unserialized to get one frame).
 *
 * The trace format is extremely simple. All numbers are
 * little-endian.
 *
 * [<uint64_t magic number>
 *  <uint64_t trace version number>
 *  <uint64_t frame_architecture>
 *  <uint64_t frame_machine, 0 for unspecified>
 *  <uint64_t n = number of trace frames>
 *  <uint64_t offset of field m (below)>
 *  <uint64_t sizeof(meta frame)>
 *  <meta frame>
 *  [ <uint64_t sizeof(trace frame 0)>
 *    <trace frame 0>
 *    ..............
 *    <uint64_t sizeof(trace frame n)>
 *    <trace frame n> ]
 *  <uint64_t m, where a table of contents entry is given
 *  for m, 2m, 3m, ..., ceil(n/m)>
 *  [ <uint64_t offset of sizeof(trace frame m)>
 *    <uint64_t offset of sizeof(trace frame 2m)>
 *    ...
 *    <uint64_t offset of sizeof(trace frame ceil(n/m))> ]]
 *
 *  One additional feature that might be nice is log_2(n) lookup
 *  time using a hierarchical toc.
 */

#include <exception>
#include <memory>
#include <stdint.h>
#include <string>
#include <vector>
#include <stdio.h>
#include "frame.piqi.pb.h"

namespace SerializedTrace {

  const uint64_t magic_number = 7456879624156307493LL;

  const uint64_t default_frames_per_toc_entry = 10000;
  const frame_architecture default_arch = frame_arch_i386;
  const uint64_t default_machine = frame_mach_i386_i386;

  const uint64_t magic_number_offset = 0LL;
  const uint64_t trace_version_offset = 8LL;
  const uint64_t frame_arch_offset = 16LL;
  const uint64_t frame_machine_offset = 24LL;
  const uint64_t num_trace_frames_offset = 32LL;
  const uint64_t toc_offset_offset = 40LL;
  const uint64_t meta_size_offset = 48LL;
  const uint64_t meta_offset = 56LL;

  const uint64_t lowest_supported_version = 2LL;
  const uint64_t highest_supported_version = 3LL;


    class TraceException: public std::exception
    {

    public:
      TraceException(std::string s)
        : msg (s)
        { }

      ~TraceException(void) noexcept { }

      virtual const char* what() const noexcept
        {
          return msg.c_str();
        }

    private:

      std::string msg;
    };

  class TraceContainerWriter {

    public:

    /** Creates a trace container writer that will output to
        [filename]. An entry will be added to the table of contents
        every [frames_per_toc_entry] entries.*/
    TraceContainerWriter(const std::string& filename,
                         const meta_frame& meta,
                         frame_architecture arch = default_arch,
                         uint64_t machine = default_machine,
                         uint64_t frames_per_toc_entry = default_frames_per_toc_entry);

    /** Add [frame] to the trace. */
    void add(const frame &f);

    // closes the trace and underlying file stream. If the stream is
    // seekable, the output a table of contents and update the header
    // with an offset to the TOC.
    void finish();

    private:


    /* Output fstream for trace container file.
     *
     *  We used to use fstreams, but Windows fstreams do not allow
     *  32-bit offsets. */
    FILE *ofs;

    /** The toc entries for frames added so far. */
    std::vector<uint64_t> toc;

    /** Number of frames added to the trace. */
    uint64_t num_frames;

    /** Frames per toc entry. */
    const uint64_t frames_per_toc_entry;

  };

  class TraceContainerReader {

  public:

    /** Creates a trace container reader that reads from [filename]. */
    TraceContainerReader(std::string filename);

    /** Destructor. */
    ~TraceContainerReader(void) noexcept;

    /** Returns the number of frames in the trace. */
    uint64_t get_num_frames(void) noexcept;

    /** Returns the number of frames per toc entry. */
    uint64_t get_frames_per_toc_entry(void) noexcept;

    /** Returns the architecture of the trace. */
    frame_architecture get_arch(void) noexcept;

    /** Returns the machine type (sub-architecture) of the trace. */
    uint64_t get_machine(void) noexcept;

    /** Returns trace version. */
    uint64_t get_trace_version(void) noexcept;

    /** Seek to frame number [frame_number]. The frame is numbered
     * 0. */
    void seek(uint64_t frame_number);;

    /** Return the frame pointed to by the frame pointer. Advances the
        frame pointer by one after. */
    std::unique_ptr<frame> get_frame(void);

    /** Return [num_frames] starting at the frame pointed to by the
        frame pointer. If there are not that many frames until the end
        of the trace, returns all until the end of the trace.  The
        frame pointer is set one frame after the last frame returned.
        If the last frame returned is the last frame in the trace, the
        frame pointer will point to an invalid frame. */
    std::unique_ptr<std::vector<frame> > get_frames(uint64_t num_frames);

    /** Return true if frame pointer is at the end of the trace. */
    bool end_of_trace(void) noexcept;

    const meta_frame *get_meta(void) const { return &meta; }

  protected:
    /** File to read trace from. */
    FILE *ifs;

    /** The toc entries from the trace. */
    std::vector<uint64_t> toc;

    /** Trace version. */
    uint64_t trace_version;

    /** Number of frames in the trace. */
    uint64_t num_frames;

    /** Number of frames per toc entry. */
    uint64_t frames_per_toc_entry;

    /** Base address in file where frames begin */
    uint64_t first_frame_offset;

    /** CPU architecture. */
    frame_architecture arch;

    /** Machine type. */
    uint64_t mach;

    meta_frame meta;

    /** Current frame number. */
    uint64_t current_frame;

    /** Return true if [frame_num] is at the end of the trace. */
    bool end_of_trace_num(uint64_t frame_num) noexcept;

    /** Raise exception if [frame_num] is at the end of the trace. */
    void check_end_of_trace_num(uint64_t frame_num, std::string msg);

    /** Raise exception if frame pointer is at the end of the trace. */
    void check_end_of_trace(std::string msg);

  };
};

#endif
