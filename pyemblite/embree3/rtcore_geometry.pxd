# rtcore_geometry wrapper

from .rtcore_ray cimport RTCIntersectContext, RTCRayN, RTCRayHitN
from .rtcore cimport RTCDevice, RTCBuildQuality, RTCFormat
from .rtcore_buffer cimport RTCBuffer
from .rtcore_ray cimport RTCFilterFunctionN
cimport cython
cimport numpy as np

cdef extern from "embree3/rtcore_geometry.h":

    # Opaque geometry type
    cdef struct RTCGeometryTy
    ctypedef RTCGeometryTy* RTCGeometry

    cdef unsigned int RTC_INVALID_GEOMETRY_ID

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

    # Types of geometries
    cdef enum RTCGeometryType:

        RTC_GEOMETRY_TYPE_TRIANGLE # triangle mesh
        RTC_GEOMETRY_TYPE_QUAD     # quad (triangle pair) mesh
        RTC_GEOMETRY_TYPE_GRID     # grid mesh

        RTC_GEOMETRY_TYPE_SUBDIVISION # Catmull-Clark subdivision surface

        RTC_GEOMETRY_TYPE_CONE_LINEAR_CURVE # Cone linear curves - discontinuous at edge boundaries
        RTC_GEOMETRY_TYPE_ROUND_LINEAR_CURVE # Round (rounded cone like) linear curves
        RTC_GEOMETRY_TYPE_FLAT_LINEAR_CURVE  # flat (ribbon-like) linear curves

        RTC_GEOMETRY_TYPE_ROUND_BEZIER_CURVE # round (tube-like) Bezier curves
        RTC_GEOMETRY_TYPE_FLAT_BEZIER_CURVE # flat (ribbon-like) Bezier curves
        RTC_GEOMETRY_TYPE_NORMAL_ORIENTED_BEZIER_CURVE # flat normal-oriented Bezier curves

        RTC_GEOMETRY_TYPE_ROUND_BSPLINE_CURVE = 32 # round (tube-like) B-spline curves
        RTC_GEOMETRY_TYPE_FLAT_BSPLINE_CURVE  = 33 # flat (ribbon-like) B-spline curves
        RTC_GEOMETRY_TYPE_NORMAL_ORIENTED_BSPLINE_CURVE # flat normal-oriented B-spline curves

        RTC_GEOMETRY_TYPE_ROUND_HERMITE_CURVE # round (tube-like) Hermite curves
        RTC_GEOMETRY_TYPE_FLAT_HERMITE_CURVE # flat (ribbon-like) Hermite curves
        RTC_GEOMETRY_TYPE_NORMAL_ORIENTED_HERMITE_CURVE # flat normal-oriented Hermite curves

        RTC_GEOMETRY_TYPE_SPHERE_POINT
        RTC_GEOMETRY_TYPE_DISC_POINT
        RTC_GEOMETRY_TYPE_ORIENTED_DISC_POINT

        RTC_GEOMETRY_TYPE_ROUND_CATMULL_ROM_CURVE # round (tube-like) Catmull-Rom curves
        RTC_GEOMETRY_TYPE_FLAT_CATMULL_ROM_CURVE # flat (ribbon-like) Catmull-Rom curves
        RTC_GEOMETRY_TYPE_NORMAL_ORIENTED_CATMULL_ROM_CURVE # flat normal-oriented Catmull-Rom curves

        RTC_GEOMETRY_TYPE_USER # user-defined geometry
        RTC_GEOMETRY_TYPE_INSTANCE # scene instance

    # Interpolation modes for subdivision surfaces */
    cdef enum RTCSubdivisionMode:

        RTC_SUBDIVISION_MODE_NO_BOUNDARY
        RTC_SUBDIVISION_MODE_SMOOTH_BOUNDARY
        RTC_SUBDIVISION_MODE_PIN_CORNERS
        RTC_SUBDIVISION_MODE_PIN_BOUNDARY
        RTC_SUBDIVISION_MODE_PIN_ALL

    # Curve segment flags */
    cdef enum RTCCurveFlags:

        RTC_CURVE_FLAG_NEIGHBOR_LEFT
        RTC_CURVE_FLAG_NEIGHBOR_RIGHT

    cdef struct RTCBounds
    # Arguments for RTCBoundsFunction
    cdef struct RTCBoundsFunctionArguments:

        void* geometryUserPtr
        unsigned int primID
        unsigned int timeStep
        RTCBounds* bounds_o


    # Bounding callback function
    ctypedef void (*RTCBoundsFunction)(const RTCBoundsFunctionArguments* args)

    # Arguments for RTCIntersectFunctionN
    cdef struct RTCIntersectFunctionNArguments:

        int* valid
        void* geometryUserPtr
        unsigned int primID
        RTCIntersectContext* context
        RTCRayHitN* rayhit
        unsigned int N
        unsigned int geomID

    # Intersection callback function
    ctypedef void (*RTCIntersectFunctionN)(const RTCIntersectFunctionNArguments* args)

    # Arguments for RTCOccludedFunctionN
    cdef struct RTCOccludedFunctionNArguments:

      int* valid;
      void* geometryUserPtr;
      unsigned int primID;
      RTCIntersectContext* context;
      RTCRayN* ray;
      unsigned int N;
      unsigned int geomID;


    # Occlusion callback function
    ctypedef void (*RTCOccludedFunctionN)(const RTCOccludedFunctionNArguments* args);

    # Arguments for RTCDisplacementFunctionN
    cdef struct RTCDisplacementFunctionNArguments:

      void* geometryUserPtr
      RTCGeometry geometry
      unsigned int primID
      unsigned int timeStep
      const float* u
      const float* v
      const float* Ng_x
      const float* Ng_y
      const float* Ng_z
      float* P_x
      float* P_y
      float* P_z
      unsigned int N


    # Displacement mapping callback function
    ctypedef void (*RTCDisplacementFunctionN)(const RTCDisplacementFunctionNArguments* args)

    # Creates a new geometry of specified type.
    RTCGeometry rtcNewGeometry(RTCDevice device, RTCGeometryType type)

    # Retains the geometry (increments the reference count).
    void rtcRetainGeometry(RTCGeometry geometry)

    # Releases the geometry (decrements the reference count)
    void rtcReleaseGeometry(RTCGeometry geometry)

    # Commits the geometry.
    void rtcCommitGeometry(RTCGeometry geometry)

    # Enables the geometry.
    void rtcEnableGeometry(RTCGeometry geometry)

    # Disables the geometry.
    void rtcDisableGeometry(RTCGeometry geometry)

    # Sets the number of motion blur time steps of the geometry.
    void rtcSetGeometryTimeStepCount(RTCGeometry geometry, unsigned int timeStepCount)

    # Sets the motion blur time range of the geometry.
    void rtcSetGeometryTimeRange(RTCGeometry geometry, float startTime, float endTime)

    # Sets the number of vertex attributes of the geometry.
    void rtcSetGeometryVertexAttributeCount(RTCGeometry geometry, unsigned int vertexAttributeCount);

    # Sets the ray mask of the geometry.
    void rtcSetGeometryMask(RTCGeometry geometry, unsigned int mask)

    # Sets the build quality of the geometry. */
    void rtcSetGeometryBuildQuality(RTCGeometry geometry, RTCBuildQuality quality)

    # Sets the maximal curve or point radius scale allowed by min-width feature.
    void rtcSetGeometryMaxRadiusScale(RTCGeometry geometry, float maxRadiusScale)


    # Sets a geometry buffer.
    void rtcSetGeometryBuffer(RTCGeometry geometry, RTCBufferType type, unsigned int slot, RTCFormat format, RTCBuffer buffer, size_t byteOffset, size_t byteStride, size_t itemCount)

    # Sets a shared geometry buffer.
    void rtcSetSharedGeometryBuffer(RTCGeometry geometry, RTCBufferType type, unsigned int slot, RTCFormat format, const void* ptr, size_t byteOffset, size_t byteStride, size_t itemCount)

    # Creates and sets a new geometry buffer.
    void* rtcSetNewGeometryBuffer(RTCGeometry geometry, RTCBufferType type, unsigned int slot, RTCFormat format, size_t byteStride, size_t itemCount);

    # Returns the pointer to the data of a buffer.
    void* rtcGetGeometryBufferData(RTCGeometry geometry, RTCBufferType type, unsigned int slot);

    # Updates a geometry buffer.
    void rtcUpdateGeometryBuffer(RTCGeometry geometry, RTCBufferType type, unsigned int slot)


    # Sets the intersection filter callback function of the geometry.
    void rtcSetGeometryIntersectFilterFunction(RTCGeometry geometry, RTCFilterFunctionN filter)

    # Sets the occlusion filter callback function of the geometry.
    void rtcSetGeometryOccludedFilterFunction(RTCGeometry geometry, RTCFilterFunctionN filter)


























####################################################################################################
#     ctypedef void (*RTCFilterFunc)(void* ptr, RTCRay& ray)
#     ctypedef void (*RTCFilterFunc4)(void* ptr, RTCRay4& ray)
#     ctypedef void (*RTCFilterFunc8)(void* ptr, RTCRay8& ray)
#     ctypedef void (*RTCFilterFunc16)(void* ptr, RTCRay16& ray)
#
#     ctypedef void (*RTCDisplacementFunc)(void* ptr, unsigned geomID, unsigned primID,
#                                          const float* u, const float* v,
#                                          const float* nx, const float* ny, const float* nz,
#                                          float* px, float* py, float* pz, size_t N)
#
#     unsigned rtcNewInstance(RTCScene target, RTCScene source)
#     void rtcSetTransform(RTCScene scene, unsigned geomID,
#                          RTCMatrixType layout, const float *xfm)
#     unsigned rtcNewTriangleMesh(RTCScene scene, RTCGeometryFlags flags,
#                                 size_t numTriangles, size_t numVertices,
#                                 size_t numTimeSteps)
#
#     unsigned rtcNewSubdivisionMesh (RTCScene scene, RTCGeometryFlags flags,
#                                     size_t numFaces, size_t numEdges,
#                                     size_t numVertices, size_t numEdgeCreases,
#                                     size_t numVertexCreases, size_t numHoles,
#                                     size_t numTimeSteps)
#     unsigned rtcNewHairGeometry (RTCScene scene, RTCGeometryFlags flags,
#                                  size_t numCurves, size_t numVertices,
#                                  size_t numTimeSteps)
#     void rtcSetMask(RTCScene scene, unsigned geomID, int mask)
#     void *rtcMapBuffer(RTCScene scene, unsigned geomID, RTCBufferType type)
#     void rtcUnmapBuffer(RTCScene scene, unsigned geomID, RTCBufferType type)
#     void rtcSetBuffer(RTCScene scene, unsigned geomID, RTCBufferType type,
#                       void *ptr, size_t offset, size_t stride)
#     void rtcEnable(RTCScene scene, unsigned geomID)
#     void rtcUpdate(RTCScene scene, unsigned geomID)
#     void rtcUpdateBuffer(RTCScene scene, unsigned geomID, RTCBufferType type)
#     void rtcDisable(RTCScene scene, unsigned geomID)
#     void rtcSetDisplacementFunction (RTCScene scene, unsigned geomID, RTCDisplacementFunc func, RTCBounds* bounds)
#     void rtcSetIntersectionFilterFunction (RTCScene scene, unsigned geomID, RTCFilterFunc func)
#     void rtcSetIntersectionFilterFunction4 (RTCScene scene, unsigned geomID, RTCFilterFunc4 func)
#     void rtcSetIntersectionFilterFunction8 (RTCScene scene, unsigned geomID, RTCFilterFunc8 func)
#     void rtcSetIntersectionFilterFunction16 (RTCScene scene, unsigned geomID, RTCFilterFunc16 func)
#     void rtcSetOcclusionFilterFunction (RTCScene scene, unsigned geomID, RTCFilterFunc func)
#     void rtcSetOcclusionFilterFunction4 (RTCScene scene, unsigned geomID, RTCFilterFunc4 func)
#     void rtcSetOcclusionFilterFunction8 (RTCScene scene, unsigned geomID, RTCFilterFunc8 func)
#     void rtcSetOcclusionFilterFunction16 (RTCScene scene, unsigned geomID, RTCFilterFunc16 func)
#     void rtcSetUserData (RTCScene scene, unsigned geomID, void* ptr)
#     void* rtcGetUserData (RTCScene scene, unsigned geomID)
#     void rtcDeleteGeometry (RTCScene scene, unsigned geomID)

