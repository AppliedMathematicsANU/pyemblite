# rtcore_ray wrapper for ray query structs.

cimport cython
cimport numpy as np

cdef extern from "embree3/rtcore_ray.h":

    cdef const int RTC_MAX_INSTANCE_LEVEL_COUNT

    # RTCORE_ALIGN(16)
    # This is for a *single* ray
    cdef struct RTCRay:
        # Ray data
        float org_x
        float org_y
        float org_z
        float tnear

        float dir_x
        float dir_y
        float dir_z
        float time

        float tfar
        unsigned int mask
        unsigned int id
        unsigned int flags

    cdef struct RTCHit:
        float Ng_x
        float Ng_y
        float Ng_z

        float u
        float v

        unsigned int primID
        unsigned int geomID
        unsigned int instID[RTC_MAX_INSTANCE_LEVEL_COUNT]

    cdef struct RTCRayHit:
        RTCRay ray
        RTCHit hit

    # Ray structure for a packet of 4 rays
    cdef struct RTCRay4:

        float org_x[4]
        float org_y[4]
        float org_z[4]
        float tnear[4]

        float dir_x[4]
        float dir_y[4]
        float dir_z[4]
        float time[4]

        float tfar[4]
        unsigned int mask[4]
        unsigned int id[4]
        unsigned int flags[4]

    # Hit structure for a packet of 4 rays
    cdef struct RTCHit4:

        float Ng_x[4]
        float Ng_y[4]
        float Ng_z[4]

        float u[4]
        float v[4]

        unsigned int primID[4]
        unsigned int geomID[4]
        unsigned int instID[RTC_MAX_INSTANCE_LEVEL_COUNT][4]

    # Combined ray/hit structure for a packet of 4 rays
    cdef struct RTCRayHit4:

        RTCRay4 ray;
        RTCHit4 hit;

    # Ray structure for a packet of 8 rays
    cdef struct RTCRay8:
        float org_x[8]
        float org_y[8]
        float org_z[8]
        float tnear[8]

        float dir_x[8]
        float dir_y[8]
        float dir_z[8]
        float time[8]

        float tfar[8]
        unsigned int mask[8]
        unsigned int id[8]
        unsigned int flags[8]

    # Hit structure for a packet of 8 rays
    cdef struct RTCHit8:

        float Ng_x[8]
        float Ng_y[8]
        float Ng_z[8]

        float u[8]
        float v[8]

        unsigned int primID[8]
        unsigned int geomID[8]
        unsigned int instID[RTC_MAX_INSTANCE_LEVEL_COUNT][8]

    # Combined ray/hit structure for a packet of 8 rays
    struct RTCRayHit8:

        RTCRay8 ray
        RTCHit8 hit


    # Ray structure for a packet of 16 rays
    cdef struct RTCRay16:

        float org_x[16]
        float org_y[16]
        float org_z[16]
        float tnear[16]

        float dir_x[16]
        float dir_y[16]
        float dir_z[16]
        float time[16]

        float tfar[16]
        unsigned int mask[16]
        unsigned int id[16]
        unsigned int flags[16]


    # Hit structure for a packet of 16 rays
    cdef struct RTCHit16:

        float Ng_x[16]
        float Ng_y[16]
        float Ng_z[16]

        float u[16]
        float v[16]

        unsigned int primID[16]
        unsigned int geomID[16]
        unsigned int instID[RTC_MAX_INSTANCE_LEVEL_COUNT][16]


    # Combined ray/hit structure for a packet of 16 rays
    cdef struct RTCRayHit16:

        RTCRay16 ray
        RTCHit16 hit

    # Intersection context flags
    cdef enum RTCIntersectContextFlags:
        RTC_INTERSECT_CONTEXT_FLAG_NONE
        RTC_INTERSECT_CONTEXT_FLAG_INCOHERENT
        RTC_INTERSECT_CONTEXT_FLAG_COHERENT

    cdef struct RTCRayN
    cdef struct RTCRayNp
    cdef struct RTCHitN
    cdef struct RTCHitNp
    cdef struct RTCRayHitN
    cdef struct RTCRayHitNp

    cdef struct RTCIntersectContext

    # Arguments for RTCFilterFunctionN
    cdef struct RTCFilterFunctionNArguments:

        int* valid
        void* geometryUserPtr
        RTCIntersectContext* context
        RTCRayN* ray
        RTCHitN* hit
        unsigned int N

    # Filter callback function
    ctypedef void (*RTCFilterFunctionN)(const RTCFilterFunctionNArguments* args)

    # Intersection context passed to intersect/occluded calls
    cdef struct RTCIntersectContext:

        RTCIntersectContextFlags flags                     # intersection flags
        RTCFilterFunctionN filter                          # filter function to execute

        # unsigned int instStackSize                         # Number of instances currently on the stack.
        unsigned int instID[RTC_MAX_INSTANCE_LEVEL_COUNT]  # The current stack of instance ids.

        # float minWidthDistanceFactor;                      # curve radius is set to this factor times distance to ray origin

    void rtcInitIntersectContext(RTCIntersectContext* context)

