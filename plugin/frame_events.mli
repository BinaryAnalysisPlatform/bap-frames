open Bap.Std
open Bap_traces.Std

module Frame = Frame_piqi

(** [events_of_frame context frame] creates list of trace events from [frame].
    [context] function which returns true if frame thread_id (if contains) equal
    to current thread_id, false otherwise *)
val of_frame :
  context:(Frame.thread_id -> bool) ->
  ?arch:arch ->
  Frame.frame -> Trace.event list
