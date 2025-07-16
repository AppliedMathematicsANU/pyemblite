# rtcore_buffer wrapper for Embree buffers.
cimport cython
cimport numpy as np
from .rtcore cimport RTCDevice

cdef extern from "embree3/rtcore_buffer.h":

    # Types of buffers
    cdef enum RTCBufferType:

        RTC_BUFFER_TYPE_INDEX
        RTC_BUFFER_TYPE_VERTEX
        RTC_BUFFER_TYPE_VERTEX_ATTRIBUTE
        RTC_BUFFER_TYPE_NORMAL
        RTC_BUFFER_TYPE_TANGENT
        RTC_BUFFER_TYPE_NORMAL_DERIVATIVE

        RTC_BUFFER_TYPE_GRID

        RTC_BUFFER_TYPE_FACE
        RTC_BUFFER_TYPE_LEVEL
        RTC_BUFFER_TYPE_EDGE_CREASE_INDEX
        RTC_BUFFER_TYPE_EDGE_CREASE_WEIGHT
        RTC_BUFFER_TYPE_VERTEX_CREASE_INDEX
        RTC_BUFFER_TYPE_VERTEX_CREASE_WEIGHT
        RTC_BUFFER_TYPE_HOLE

        RTC_BUFFER_TYPE_FLAGS

    # Opaque buffer type
    cdef struct RTCBufferTy
    ctypedef RTCBufferTy* RTCBuffer;

    # Creates a new buffer.
    RTCBuffer rtcNewBuffer(RTCDevice device, size_t byteSize);

    # Creates a new shared buffer.
    RTCBuffer rtcNewSharedBuffer(RTCDevice device, void* ptr, size_t byteSize);

    # Returns a pointer to the buffer data.
    void* rtcGetBufferData(RTCBuffer buffer)

    # Retains the buffer (increments the reference count).
    void rtcRetainBuffer(RTCBuffer buffer)

    # Releases the buffer (decrements the reference count).
    void rtcReleaseBuffer(RTCBuffer buffer)
