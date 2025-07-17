# rtcore_scene.pxd wrapper

cimport cython
cimport numpy as np
from libcpp cimport bool
from . cimport rtcore4 as rtc
from . cimport rtcore_ray4 as rtcr
from . cimport rtcore_geometry4 as rtcg

cdef extern from "embree4/rtcore_scene.h":

    ctypedef struct RTCRay
    ctypedef struct RTCRay4
    ctypedef struct RTCRay8
    ctypedef struct RTCRay16
    ctypedef struct RTCRayQueryContext
    cdef struct RTCIntersectArguments:
        rtcr.RTCRayQueryFlags flags  # intersection flags
        rtc.RTCFeatureFlags feature_mask  # selectively enable features for traversal
        rtcr.RTCRayQueryContext* context  # optional pointer to ray query context
        rtcg.RTCFilterFunctionN filter  # filter function to execute
        rtcg.RTCIntersectFunctionN intersect  # user geometry intersection callback to execute

    cdef struct RTCOccludedArguments:
        rtcr.RTCRayQueryFlags flags  # intersection flags
        rtc.RTCFeatureFlags feature_mask  # selectively enable features for traversal
        rtcr.RTCRayQueryContext* context  # optional pointer to ray query context
        rtcg.RTCFilterFunctionN filter  # filter function to execute
        rtcg.RTCOccludedFunctionN occluded  # user geometry occlusion callback to execute

    ctypedef struct RTCRayHit
    ctypedef struct RTCRayHit4
    ctypedef struct RTCRayHit8
    ctypedef struct RTCRayHit16

    # Scene flags
    cpdef enum RTCSceneFlags:
        RTC_SCENE_FLAG_NONE
        RTC_SCENE_FLAG_DYNAMIC
        RTC_SCENE_FLAG_COMPACT
        RTC_SCENE_FLAG_ROBUST
        RTC_SCENE_FLAG_FILTER_FUNCTION_IN_ARGUMENTS
        RTC_SCENE_FLAG_PREFETCH_USM_SHARED_ON_GPU

    cdef enum RTCAlgorithmFlags:
        RTC_INTERSECT1
        RTC_INTERSECT4
        RTC_INTERSECT8
        RTC_INTERSECT16


    # ctypedef void* RTCDevice
    ctypedef void* RTCScene

    cdef struct RTCBounds
    cdef struct RTCLinearBounds

    void rtcInitIntersectArguments(RTCIntersectArguments* args);
    void rtcInitOccludedArguments(RTCOccludedArguments* args);

    # Creates a new scene.
    RTCScene rtcNewScene(rtc.RTCDevice device);

    # Returns the device the scene got created in. The reference count of
    # the device is incremented by this function.
    rtc.RTCDevice rtcGetSceneDevice(RTCScene hscene)

    # Retains the scene (increments the reference count).
    void rtcRetainScene(RTCScene scene)

    # Releases the scene (decrements the reference count).
    void rtcReleaseScene(RTCScene scene)


    # Attaches the geometry to a scene.
    unsigned int rtcAttachGeometry(RTCScene scene, rtcg.RTCGeometry geometry)

    # Attaches the geometry to a scene using the specified geometry ID.
    void rtcAttachGeometryByID(RTCScene scene, rtcg.RTCGeometry geometry, unsigned int geomID)

    # Detaches the geometry from the scene.
    void rtcDetachGeometry(RTCScene scene, unsigned int geomID)

    # Gets a geometry handle from the scene.
    rtcg.RTCGeometry rtcGetGeometry(RTCScene scene, unsigned int geomID)


    # Commits the scene.
    void rtcCommitScene(RTCScene scene)

    # Commits the scene from multiple threads.
    void rtcJoinCommitScene(RTCScene scene)


    # Progress monitor callback function
    ctypedef bool (*RTCProgressMonitorFunction)(void* ptr, double n)

    # Sets the progress monitor callback function of the scene.
    void rtcSetSceneProgressMonitorFunction(RTCScene scene, RTCProgressMonitorFunction progress, void* ptr)

    # Sets the build quality of the scene.
    void rtcSetSceneBuildQuality(RTCScene scene, rtc.RTCBuildQuality quality)

    # Sets the scene flags.
    void rtcSetSceneFlags(RTCScene scene, RTCSceneFlags flags)

    # Returns the scene flags.
    RTCSceneFlags rtcGetSceneFlags(RTCScene scene)

    # Returns the axis-aligned bounds of the scene.
    void rtcGetSceneBounds(RTCScene scene, RTCBounds* bounds_o)

    # Returns the linear axis-aligned bounds of the scene.
    void rtcGetSceneLinearBounds(RTCScene scene, RTCLinearBounds* bounds_o)


    # Perform a closest point query of the scene.
    bool rtcPointQuery(RTCScene scene, rtc.RTCPointQuery* query, rtc.RTCPointQueryContext* context, rtc.RTCPointQueryFunction queryFunc, void* userPtr)

    # Perform a closest point query with a packet of 4 points with the scene.
    bool rtcPointQuery4(const int* valid, RTCScene scene, rtc.RTCPointQuery4* query, rtc.RTCPointQueryContext* context, rtc.RTCPointQueryFunction queryFunc, void** userPtr)

    # Perform a closest point query with a packet of 4 points with the scene.
    bool rtcPointQuery8(const int* valid, RTCScene scene, rtc.RTCPointQuery8* query, rtc.RTCPointQueryContext* context, rtc.RTCPointQueryFunction queryFunc, void** userPtr)

    # Perform a closest point query with a packet of 4 points with the scene.
    bool rtcPointQuery16(const int* valid, RTCScene scene, rtc.RTCPointQuery16* query, rtc.RTCPointQueryContext* context, rtc.RTCPointQueryFunction queryFunc, void** userPtr)

    # Intersects a single ray with the scene.
    void rtcIntersect1(RTCScene scene, rtcr.RTCRayHit* rayhit, RTCIntersectArguments* args)

    # Intersects a packet of 4 rays with the scene.
    void rtcIntersect4(const int* valid, RTCScene scene, rtcr.RTCRayHit4* rayhit, RTCIntersectArguments* args)

    # Intersects a packet of 8 rays with the scene.
    void rtcIntersect8(const int* valid, RTCScene scene, rtcr.RTCRayHit8* rayhit, RTCIntersectArguments* args)

    # Intersects a packet of 16 rays with the scene.
    void rtcIntersect16(const int* valid, RTCScene scene, rtcr.RTCRayHit16* rayhit, RTCIntersectArguments* args)

    # Tests a single ray for occlusion with the scene.
    void rtcOccluded1(RTCScene scene, rtcr.RTCRay* ray, RTCOccludedArguments* args)

    # Tests a packet of 4 rays for occlusion occluded with the scene.
    void rtcOccluded4(const int* valid, RTCScene scene, rtcr.RTCRay4* ray, RTCOccludedArguments* args)

    # Tests a packet of 8 rays for occlusion with the scene.
    void rtcOccluded8(const int* valid, RTCScene scene, rtcr.RTCRay8* ray, RTCOccludedArguments* args)

    # Tests a packet of 16 rays for occlusion with the scene.
    void rtcOccluded16(const int* valid, RTCScene scene, rtcr.RTCRay16* ray, RTCOccludedArguments* args)

    # collision callback
    cdef struct RTCCollision:
        unsigned int geomID0
        unsigned int primID0
        unsigned int geomID1
        unsigned int primID1

    ctypedef void (*RTCCollideFunc) (void* userPtr, RTCCollision* collisions, unsigned int num_collisions)

    # Performs collision detection of two scenes
    void rtcCollide (RTCScene scene0, RTCScene scene1, RTCCollideFunc callback, void* userPtr)


cdef class TestScene:
    pass


cdef class EmbreeScene:
    cdef RTCScene scene_i
    # Optional device used if not given, it should be as input of EmbreeScene
    cdef public int is_committed
    cdef rtc.EmbreeDevice device


cdef enum rayQueryType:
    intersect,
    occluded,
    distance

