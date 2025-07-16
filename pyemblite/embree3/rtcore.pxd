# rtcore wrapper

cimport cython
cimport numpy as np
from libcpp cimport bool

cdef extern from "embree3/rtcore.h":
    cdef int RTC_VERSION_MAJOR
    cdef int RTC_VERSION_MINOR
    cdef int RTC_VERSION_PATCH

    cpdef enum RTCError:
        RTC_ERROR_NONE
        RTC_ERROR_UNKNOWN
        RTC_ERROR_INVALID_ARGUMENT
        RTC_ERROR_INVALID_OPERATION
        RTC_ERROR_OUT_OF_MEMORY
        RTC_ERROR_UNSUPPORTED_CPU
        RTC_ERROR_CANCELLED

    cdef const int RTC_MAX_INSTANCE_LEVEL_COUNT

    # Formats of buffers and other data structures
    cdef enum RTCFormat:

        RTC_FORMAT_UNDEFINED

        # 8-bit unsigned integer
        RTC_FORMAT_UCHAR
        RTC_FORMAT_UCHAR2
        RTC_FORMAT_UCHAR3
        RTC_FORMAT_UCHAR4

        # 8-bit signed integer
        RTC_FORMAT_CHAR
        RTC_FORMAT_CHAR2
        RTC_FORMAT_CHAR3
        RTC_FORMAT_CHAR4

        # 16-bit unsigned integer
        RTC_FORMAT_USHORT
        RTC_FORMAT_USHORT2
        RTC_FORMAT_USHORT3
        RTC_FORMAT_USHORT4

        # 16-bit signed integer
        RTC_FORMAT_SHORT
        RTC_FORMAT_SHORT2
        RTC_FORMAT_SHORT3
        RTC_FORMAT_SHORT4

        # 32-bit unsigned integer
        RTC_FORMAT_UINT
        RTC_FORMAT_UINT2
        RTC_FORMAT_UINT3
        RTC_FORMAT_UINT4

        # 32-bit signed integer
        RTC_FORMAT_INT
        RTC_FORMAT_INT2
        RTC_FORMAT_INT3
        RTC_FORMAT_INT4

        # 64-bit unsigned integer
        RTC_FORMAT_ULLONG
        RTC_FORMAT_ULLONG2
        RTC_FORMAT_ULLONG3
        RTC_FORMAT_ULLONG4

        # 64-bit signed integer
        RTC_FORMAT_LLONG
        RTC_FORMAT_LLONG2
        RTC_FORMAT_LLONG3
        RTC_FORMAT_LLONG4

        # 32-bit float
        RTC_FORMAT_FLOAT
        RTC_FORMAT_FLOAT2
        RTC_FORMAT_FLOAT3
        RTC_FORMAT_FLOAT4
        RTC_FORMAT_FLOAT5
        RTC_FORMAT_FLOAT6
        RTC_FORMAT_FLOAT7
        RTC_FORMAT_FLOAT8
        RTC_FORMAT_FLOAT9
        RTC_FORMAT_FLOAT10
        RTC_FORMAT_FLOAT11
        RTC_FORMAT_FLOAT12
        RTC_FORMAT_FLOAT13
        RTC_FORMAT_FLOAT14
        RTC_FORMAT_FLOAT15
        RTC_FORMAT_FLOAT16

        # 32-bit float matrix (row-major order)
        RTC_FORMAT_FLOAT2X2_ROW_MAJOR
        RTC_FORMAT_FLOAT2X3_ROW_MAJOR
        RTC_FORMAT_FLOAT2X4_ROW_MAJOR
        RTC_FORMAT_FLOAT3X2_ROW_MAJOR
        RTC_FORMAT_FLOAT3X3_ROW_MAJOR
        RTC_FORMAT_FLOAT3X4_ROW_MAJOR
        RTC_FORMAT_FLOAT4X2_ROW_MAJOR
        RTC_FORMAT_FLOAT4X3_ROW_MAJOR
        RTC_FORMAT_FLOAT4X4_ROW_MAJOR

        # 32-bit float matrix (column-major order)
        RTC_FORMAT_FLOAT2X2_COLUMN_MAJOR
        RTC_FORMAT_FLOAT2X3_COLUMN_MAJOR
        RTC_FORMAT_FLOAT2X4_COLUMN_MAJOR
        RTC_FORMAT_FLOAT3X2_COLUMN_MAJOR
        RTC_FORMAT_FLOAT3X3_COLUMN_MAJOR
        RTC_FORMAT_FLOAT3X4_COLUMN_MAJOR
        RTC_FORMAT_FLOAT4X2_COLUMN_MAJOR
        RTC_FORMAT_FLOAT4X3_COLUMN_MAJOR
        RTC_FORMAT_FLOAT4X4_COLUMN_MAJOR

        # special 12-byte format for grids
        RTC_FORMAT_GRID

    # Build quality levels
    cpdef enum RTCBuildQuality:
        RTC_BUILD_QUALITY_LOW
        RTC_BUILD_QUALITY_MEDIUM
        RTC_BUILD_QUALITY_HIGH
        RTC_BUILD_QUALITY_REFIT

    # typedef struct __RTCDevice {}* RTCDevice;
    ctypedef void* RTCDevice

    RTCDevice rtcNewDevice(const char* cfg)
    void rtcReleaseDevice(RTCDevice device)

    RTCError rtcGetError()
    ctypedef void (*RTCErrorFunc)(void *userPtr, RTCError code, const char* _str)
    void rtcSetErrorFunction(RTCErrorFunc func)

    # Embree 3
    void rtcSetDeviceErrorFunction(RTCDevice device, RTCErrorFunc func, void* userPtr)

    ctypedef bint RTCMemoryMonitorFunc(const ssize_t _bytes, const bint post)
    void rtcSetMemoryMonitorFunction(RTCMemoryMonitorFunc func)

    # Axis-aligned bounding box representation */
    cdef struct RTCBounds:

        float lower_x, lower_y, lower_z, align0;
        float upper_x, upper_y, upper_z, align1;


    # Linear axis-aligned bounding box representation */
    cdef struct RTCLinearBounds:
        RTCBounds bounds0;
        RTCBounds bounds1;

    # Point query structure for closest point query */
    cdef struct RTCPointQuery:

        float x                 # x coordinate of the query point
        float y                 # y coordinate of the query point
        float z                 # z coordinate of the query point
        float time              # time of the point query
        float radius            # radius of the point query

    # Structure of a packet of 4 query points */
    cdef struct RTCPointQuery4:

        float x[4]                 # x coordinate of the query point
        float y[4]                 # y coordinate of the query point
        float z[4]                 # z coordinate of the query point
        float time[4]              # time of the point query
        float radius[4]            # radius of the point query


    # Structure of a packet of 8 query points */
    cdef struct RTCPointQuery8:

        float x[8]                 # x coordinate of the query point
        float y[8]                 # y coordinate of the query point
        float z[8]                 # z coordinate of the query point
        float time[8]              # time of the point query
        float radius[8]            # radius ofr the point query


    # Structure of a packet of 16 query points */
    cdef struct RTCPointQuery16:

        float x[16]                 # x coordinate of the query point
        float y[16]                 # y coordinate of the query point
        float z[16]                 # z coordinate of the query point
        float time[16]              # time of the point quey
        float radius[16]            # radius of the point query

    cdef struct RTCPointQueryN

    cdef struct RTCPointQueryContext:

        # accumulated 4x4 column major matrices from world space to instance space.
        # undefined if size == 0.
        float world2inst[RTC_MAX_INSTANCE_LEVEL_COUNT][16]

        # accumulated 4x4 column major matrices from instance space to world space.
        # undefined if size == 0.
        float inst2world[RTC_MAX_INSTANCE_LEVEL_COUNT][16]

        # instance ids.
        unsigned int instID[RTC_MAX_INSTANCE_LEVEL_COUNT]

        # number of instances currently on the stack.
        unsigned int instStackSize


    # Initializes an intersection context.
    cdef void rtcInitPointQueryContext(RTCPointQueryContext* context)


    cdef struct RTCPointQueryFunctionArguments:

        # The (world space) query object that was passed as an argument of rtcPointQuery. The
        # radius of the query can be decreased inside the callback to shrink the
        # search domain. Increasing the radius or modifying the time or position of
        # the query results in undefined behaviour.
        RTCPointQuery* query

        # Used for user input/output data. Will not be read or modified internally.
        void* userPtr;

        # primitive and geometry ID of primitive
        unsigned int  primID
        unsigned int  geomID

        # the context with transformation and instance ID stack
        RTCPointQueryContext* context

        # If the current instance transform M (= context->world2inst[context->instStackSize])
        # is a similarity matrix, i.e there is a constant factor similarityScale such that,
        #    for all x,y: dist(Mx, My) = similarityScale * dist(x, y),
        # The similarity scale is 0, if the current instance transform is not a
        # similarity transform and vice versa. The similarity scale allows to compute
        # distance information in instance space and scale the distances into world
        # space by dividing with the similarity scale, for example, to update the
        # query radius. If the current instance transform is not a similarity
        # transform (similarityScale = 0), the distance computation has to be
        # performed in world space to ensure correctness. if there is no instance
        # transform (context->instStackSize == 0), the similarity scale is 1.
        float similarityScale


    ctypedef bool (*RTCPointQueryFunction)(RTCPointQueryFunctionArguments* args)


cdef extern from "embree3/rtcore_ray.h":
    pass

cdef struct Vertex:
    float x, y, z, r

cdef struct Triangle:
    int v0, v1, v2

cdef struct Vec3f:
    float x, y, z

cdef void print_error(RTCError code)

cdef class EmbreeDevice:
    cdef RTCDevice device
