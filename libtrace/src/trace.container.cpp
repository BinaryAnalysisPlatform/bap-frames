/**
 * Implementation of trace container.
 */

#include "trace.container.hpp"
#include <stdio.h>
#include <iostream>
#include <string>

#define WRITE(x) { if (fwrite(&(x), sizeof(x), 1, ofs) != 1) { throw (TraceException("Unable to write to trace")); } }
#define READ(x) { if (fread(&(x), sizeof(x), 1, ifs) != 1) { throw (TraceException("Unable to read from trace")); } }
#ifdef _WIN32
typedef uint64_t traceoff_t;
#define SEEKNAME _fseeki64
#define SEEK(f,x) { if (SEEKNAME(f, x, SEEK_SET) != 0) { throw (TraceException("Unable to seek in trace to offset " + std::to_string(x))); } }
#define TELL(f) _ftelli64(f)
#else
typedef off_t traceoff_t;
#define SEEKNAME fseeko
#define SEEK(f,x) { if (SEEKNAME(f, x, SEEK_SET) != 0) { throw (TraceException("Unable to seek in trace to offset " + std::to_string(x))); } }
#define TELL(f) ftello(f)
#endif

namespace SerializedTrace {

  FILE *open_trace(const std::string& filename,
                  frame_architecture arch,
                  uint64_t machine,
                  uint64_t trace_version) {
    FILE *ofs = fopen(filename.c_str(), "wb");
    if (!ofs) throw TraceException("Unable to open trace file for writing");
    int64_t toc_off = 0LL, toc_num_frames = 0LL;

    WRITE(magic_number);
    WRITE(trace_version);
    uint64_t archt = (uint64_t) arch;
    WRITE(archt);
    WRITE(machine);
    WRITE(toc_num_frames);
    WRITE(toc_off);
    return ofs;
  }

  TraceContainerWriter::TraceContainerWriter(const std::string& filename,
                                             const meta_frame& meta,
                                             frame_architecture arch,
                                             uint64_t machine,
                                             uint64_t frames_per_toc_entry_in)
    : num_frames (0)
    , frames_per_toc_entry (frames_per_toc_entry_in)
    , ofs(open_trace(filename,arch,machine,3LL)) {
    std::string meta_data;
    if (!(meta.SerializeToString(&meta_data))) {
      throw TraceException("Unable to serialize meta frame to ostream");
    }

    uint64_t meta_size = meta_data.length();
    WRITE(meta_size);
    if (fwrite(meta_data.c_str(), 1, meta_size, ofs) != meta_size) {
      throw (TraceException("Unable to write meta frame to trace file"));
    }
  }

  void TraceContainerWriter::add(const frame &f) {
    if (num_frames > 0 && (num_frames % frames_per_toc_entry) == 0) {
      toc.push_back(TELL(ofs));
    }
    num_frames++;

    std::string s;
    if (!(f.SerializeToString(&s))) {
      throw (TraceException("Unable to serialize frame to ostream"));
    }
    uint64_t len = s.length();
    WRITE(len);
    if (fwrite(s.c_str(), 1, len, ofs) != len) {
      throw (TraceException("Unable to write frame to trace file"));
    }
  }

  void TraceContainerWriter::finish() {
    uint64_t toc_offset = TELL(ofs);
    // if we have a positive offset, then the device is seekable, so
    // we will write the TOC, otherwise we will skip it.
    if (toc_offset > 0) {
      assert ((num_frames - 1) / frames_per_toc_entry == toc.size());
      WRITE(frames_per_toc_entry);
      for (std::vector<uint64_t>::size_type i = 0; i < toc.size(); i++) {
        WRITE(toc[i]);
      }
      SEEK(ofs, num_trace_frames_offset);
      WRITE(num_frames);
      SEEK(ofs, toc_offset_offset);
      WRITE(toc_offset);
    }

    if (fclose(ofs) != 0) {
      throw TraceException("Error while closing the trace");
    }
    ofs = NULL;
  }

  TraceContainerReader::TraceContainerReader(std::string filename)
  {
    ifs = fopen(filename.c_str(), "rb");
    if (!ifs) { throw (TraceException("Unable to open trace for reading")); }

    /* Verify the magic number. */
    uint64_t magic_number_read;
    READ(magic_number_read);
    if (magic_number_read != magic_number) {
      throw (TraceException("Magic number not found in trace"));
    }

    READ(trace_version);
    if (trace_version > highest_supported_version ||
        trace_version < lowest_supported_version) {
      throw (TraceException("Unsupported trace version"));
    }

    uint64_t archt;
    READ(archt);
    arch = (frame_architecture) archt;

    READ(mach);

    /* Read number of trace frames. */
    READ(num_frames);

    /* Find offset of toc. */
    uint64_t toc_offset;
    READ(toc_offset);

    uint64_t meta_size;
    READ(meta_size);
    first_frame_offset = meta_offset + meta_size;

    std::vector<uint8_t> meta_buf(meta_size);
    if (fread(meta_buf.data(), 1, meta_buf.size(), ifs) != meta_buf.size()) {
      throw (TraceException("Unable to read meta frame"));
    }
    if (!meta.ParseFromArray(meta_buf.data(), meta_buf.size())) {
      throw (TraceException("Unable to parse meta frame"));
    }

    /* Find the toc. */
    SEEK(ifs, toc_offset);

    /* Read number of frames per toc entry. */
    READ(frames_per_toc_entry);

    /* Read each toc entry. */
    for (int i = 0; i < ((num_frames - 1) / frames_per_toc_entry); i++) {
      uint64_t offset;
      READ(offset);
      toc.push_back(offset);
    }

    /* We should be at the end of the file now. */
    traceoff_t us = TELL(ifs);
    traceoff_t end = SEEKNAME(ifs, 0, SEEK_END);
    if (us != TELL(ifs) || end != 0) {
      throw(TraceException("The table of contents is malformed."));
    }

    /* Seek to the first frame. */
    seek(0);
  }

  TraceContainerReader::~TraceContainerReader(void) noexcept {
    /* Nothing yet. */
  }

  uint64_t TraceContainerReader::get_num_frames(void) noexcept {
    return num_frames;
  }

  uint64_t TraceContainerReader::get_frames_per_toc_entry(void) noexcept {
    return frames_per_toc_entry;
  }

  frame_architecture TraceContainerReader::get_arch(void) noexcept {
    return arch;
  }

  uint64_t TraceContainerReader::get_machine(void) noexcept {
    return mach;
  }

  uint64_t TraceContainerReader::get_trace_version(void) noexcept {
    return trace_version;
  }

  void TraceContainerReader::seek(uint64_t frame_number) {
    /* First, make sure the frame is in range. */
    check_end_of_trace_num(frame_number, "seek() to non-existant frame");

    /* Find the closest toc entry, if any. */
    uint64_t toc_number = frame_number / frames_per_toc_entry;

    if (toc_number == 0) {
      current_frame = 0;
      SEEK(ifs, first_frame_offset);
    } else {
      current_frame = toc_number * frames_per_toc_entry;
      /* Use toc_number - 1 because there is no toc for frames [0,m). */
      SEEK(ifs, toc[toc_number - 1]);
    }

    while (current_frame != frame_number) {
      /* Read frame length and skip that far ahead. */
      uint64_t frame_len;
      READ(frame_len);
      SEEK(ifs, (uint64_t)TELL(ifs) + frame_len);
      current_frame++;
    }
  }

  std::unique_ptr<frame> TraceContainerReader::get_frame(void) {
    /* Make sure we are in bounds. */
    check_end_of_trace("get_frame() on non-existant frame");

    uint64_t frame_len;
    READ(frame_len);
    if (frame_len == 0) {
      throw (TraceException("Read zero-length frame at offset " + std::to_string(TELL(ifs))));
    }

    std::vector<uint8_t> buf(frame_len);

    /* Read the frame into buf. */
    if (fread(buf.data(), 1, frame_len, ifs) != frame_len) {
      throw (TraceException("Unable to read frame from trace"));
    }

    std::unique_ptr<frame> f(new frame);
    if (!(f->ParseFromArray(buf.data(), buf.size()))) {
      throw (TraceException("Unable to parse from string"));
    }
    current_frame++;

    return f;
  }

  std::unique_ptr<std::vector<frame> > TraceContainerReader::get_frames(uint64_t requested_frames) {
    check_end_of_trace("get_frames() on non-existant frame");

    std::unique_ptr<std::vector<frame> > frames(new std::vector<frame>);
    for (uint64_t i = 0; i < requested_frames && current_frame < num_frames; i++) {
      frames->push_back(*(get_frame()));
    }

    return frames;
  }

  bool TraceContainerReader::end_of_trace(void) noexcept {
    return end_of_trace_num(current_frame);
  }

  bool TraceContainerReader::end_of_trace_num(uint64_t frame_num) noexcept {
    if (frame_num + 1 > num_frames) {
      return true;
    } else {
      return false;
    }
  }

  void TraceContainerReader::check_end_of_trace_num(uint64_t frame_num, std::string msg) {
    if (end_of_trace_num(frame_num)) {
      throw (TraceException(msg));
    }
  }

    void TraceContainerReader::check_end_of_trace(std::string msg) {
      return check_end_of_trace_num(current_frame, msg);
    }
};
