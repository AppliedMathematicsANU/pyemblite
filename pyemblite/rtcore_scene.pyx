cimport cython
cimport numpy as np
from libcpp cimport bool
from numpy cimport int32_t
import numpy as np
import logging
import numbers
from . cimport rtcore as rtc
from . cimport rtcore_buffer as rtcb
from . cimport rtcore_ray as rtcr
from . cimport rtcore_scene as rtcs
from . cimport rtcore_geometry as rtcg
from .rtcore cimport Vertex, Triangle


log = logging.getLogger(__name__)

cdef void error_printer(void *userPtr, rtc.RTCError code, const char *_str) noexcept:
    """
    error_printer function. depends on embree version
    """
    log.error("ERROR CAUGHT IN EMBREE")
    rtc.print_error(code)
    log.error("ERROR MESSAGE: %s" % _str)


cdef class EmbreeScene:
    def __init__(self, rtc.EmbreeDevice device=None):
        if device is None:
            # We store the embree device inside EmbreeScene to avoid premature deletion
            device = rtc.EmbreeDevice()
        self.device = device
        rtc.rtcSetDeviceErrorFunction(device.device, error_printer, NULL)
        self.scene_i = rtcNewScene(device.device)
        self.is_committed = 0

    def set_build_quality(self, rtc.RTCBuildQuality quality):
        rtcSetSceneBuildQuality(self.scene_i, quality)

    def get_flags(self):
        return rtcGetSceneFlags(self.scene_i)

    def set_flags(self, RTCSceneFlags flags):
        rtcSetSceneFlags(self.scene_i, flags)

    def commit(self):
        """
        """
        rtcCommitScene(self.scene_i)

    @cython.boundscheck(False) # turn off bounds-checking for entire function
    @cython.wraparound(False)  # turn off negative index wrapping for entire function
    def run(self, np.ndarray[np.float32_t, ndim=2] vec_origins,
                  np.ndarray[np.float32_t, ndim=2] vec_directions,
                  dists=None, query='INTERSECT', output=None):

        if self.is_committed == 0:
            # print("Committing scene...")
            rtcCommitScene(self.scene_i)
            self.is_committed = 1

        cdef rtc.RTCBounds bnds
        rtcGetSceneBounds(self.scene_i, &bnds)
        # print(bnds.lower_x, bnds.lower_y, bnds.lower_z, bnds.upper_x, bnds.upper_y, bnds.upper_z)


        cdef int nv = vec_origins.shape[0]
        cdef int vo_i, vd_i, vd_step
        cdef np.ndarray[np.int32_t, ndim=1] intersect_ids
        cdef np.ndarray[np.int32_t, ndim=1] primID
        cdef np.ndarray[np.int32_t, ndim=1] geomID
        cdef np.ndarray[np.float32_t, ndim=1] tfars
        cdef np.ndarray[np.float32_t, ndim=1] u
        cdef np.ndarray[np.float32_t, ndim=1] v
        cdef np.ndarray[np.float32_t, ndim=2] Ng
        cdef int32_t INVALID_GEOMETRY_ID=rtcg.RTC_INVALID_GEOMETRY_ID

        cdef rayQueryType query_type

        cdef bool do_dict_return = 0
        if (output is not None) and output:
            do_dict_return = 1



        if query == 'INTERSECT':
            query_type = intersect
        elif query == 'OCCLUDED':
            query_type = occluded
        elif query == 'DISTANCE':
            query_type = distance

        else:
            raise ValueError("Embree ray query type %s not recognized."
                "\nAccepted types are (INTERSECT,OCCLUDED,DISTANCE)" % (query))

        if dists is None:
            tfars = np.empty(nv, 'float32')
            tfars.fill(1e37)
        elif isinstance(dists, numbers.Number):
            tfars = np.empty(nv, 'float32')
            tfars.fill(dists)
        else:
            tfars = dists

        if do_dict_return:
            u = np.empty(nv, dtype="float32")
            v = np.empty(nv, dtype="float32")
            Ng = np.empty((nv, 3), dtype="float32")
            primID = np.empty(nv, dtype="int32")
            geomID = np.empty(nv, dtype="int32")
        else:
            intersect_ids = np.empty(nv, dtype="int32")
            intersect_ids.fill(INVALID_GEOMETRY_ID)

        cdef rtcr.RTCIntersectContext ray_ctx
        rtcr.rtcInitIntersectContext( &ray_ctx)

        cdef rtcr.RTCRayHit ray_hit
        vd_i = 0
        vd_step = 1
        # If vec_directions is 1 long, we won't be updating it.
        if vec_directions.shape[0] == 1: vd_step = 0

        for i in range(nv):
            ray_hit.ray.org_x = vec_origins[i, 0]
            ray_hit.ray.org_y = vec_origins[i, 1]
            ray_hit.ray.org_z = vec_origins[i, 2]
            ray_hit.ray.dir_x = vec_directions[vd_i, 0]
            ray_hit.ray.dir_y = vec_directions[vd_i, 1]
            ray_hit.ray.dir_z = vec_directions[vd_i, 2]
            ray_hit.ray.time = 0
            ray_hit.ray.mask = -1
            ray_hit.ray.flags = 0

            ray_hit.ray.tnear = 0.0
            ray_hit.ray.tfar = tfars[i]
            ray_hit.ray.id = i
            ray_hit.hit.geomID = rtcg.RTC_INVALID_GEOMETRY_ID
            ray_hit.hit.primID = rtcg.RTC_INVALID_GEOMETRY_ID
            # ray_hit.hit.instID = rtcg.RTC_INVALID_GEOMETRY_ID
            # print("PRE: %d" % ray_hit.hit.geomID)

            vd_i += vd_step

            if (query_type == intersect) or (query_type == distance):
                rtcIntersect1(self.scene_i, &ray_ctx, &ray_hit)
                # print("ray_hit.ray.tfar=%s" % ray_hit.ray.tfar)
                # print("PST: %d" % ray_hit.hit.geomID)
                # print("PST: %d" % ray_hit.hit.primID)

                if not do_dict_return:
                    if query_type == intersect:
                        intersect_ids[i] = ray_hit.hit.primID
                    else:
                        tfars[i] = ray_hit.ray.tfar
                else:
                    primID[i] = <int32_t>ray_hit.hit.primID
                    geomID[i] = <int32_t>ray_hit.hit.geomID
                    u[i] = ray_hit.hit.u
                    v[i] = ray_hit.hit.v
                    tfars[i] = ray_hit.ray.tfar

                    Ng[i, 0] = ray_hit.hit.Ng_x
                    Ng[i, 1] = ray_hit.hit.Ng_y
                    Ng[i, 2] = ray_hit.hit.Ng_z
            else:
                rtcOccluded1(self.scene_i, &ray_ctx, &(ray_hit.ray))
                intersect_ids[i] = <int32_t>ray_hit.hit.geomID

        if do_dict_return:
            return {'u':u, 'v':v, 'Ng': Ng, 'tfar': tfars, 'primID': primID, 'geomID': geomID}
        else:
            if query_type == distance:
                return tfars
            else:
                return intersect_ids

    def __dealloc__(self):
        rtcReleaseScene(self.scene_i)


cdef class EmbreeSceneExtended(object):
    cdef rtcs.RTCScene scene_i
    cdef rtc.EmbreeDevice device
    cdef rtcg.RTCGeometry mesh
    cdef Vertex* vertices
    cdef Triangle* indices
    cdef unsigned int meshID

    def __init__(self,
        np.ndarray vertices,
        np.ndarray indices,
        rtc.EmbreeDevice device=None
    ):
        if device is None:
            # We store the embree device inside EmbreeScene to avoid premature deletion
            device = rtc.EmbreeDevice()
        self.device = device
        rtc.rtcSetDeviceErrorFunction(device.device, error_printer, NULL)
        self.scene_i = rtcNewScene(device.device)
        self._build_from_indices(vertices, indices)
        rtcCommitScene(self.scene_i)

    def set_build_quality(self, rtc.RTCBuildQuality quality):
        rtcSetSceneBuildQuality(self.scene_i, quality)

    def get_flags(self):
        return rtcGetSceneFlags(self.scene_i)

    def set_flags(self, RTCSceneFlags flags):
        rtcSetSceneFlags(self.scene_i, flags)

    def __dealloc__(self):
        rtcReleaseScene(self.scene_i)
        rtcg.rtcReleaseGeometry(self.mesh)

    @cython.boundscheck(False) # turn off bounds-checking for entire function
    @cython.wraparound(False)  # turn off negative index wrapping for entire function
    cdef void _build_from_indices(
        self,
        np.ndarray[np.float64_t, ndim=2] tri_vertices,
        np.ndarray[np.int32_t, ndim=2] tri_indices,
        rtc.RTCBuildQuality build_quality=rtc.RTC_BUILD_QUALITY_MEDIUM
    ):
        cdef int i
        cdef int nv = tri_vertices.shape[0]
        cdef int nt = tri_indices.shape[0]

        cdef rtcg.RTCGeometry mesh = rtcg.rtcNewGeometry(
            self.device.device, rtcg.RTC_GEOMETRY_TYPE_TRIANGLE
        )
        rtcg.rtcSetGeometryBuildQuality(mesh, build_quality)
        # set up vertex and triangle arrays. In this case, we just read
        # them directly from the inputs
        cdef Vertex * vertices = <Vertex *> rtcg.rtcSetNewGeometryBuffer(
                mesh,
                rtcb.RTC_BUFFER_TYPE_VERTEX,
                0,
                rtc.RTC_FORMAT_FLOAT3,
                sizeof(Vertex),
                nv
            )

        for i in range(nv):
            vertices[i].x = tri_vertices[i, 0]
            vertices[i].y = tri_vertices[i, 1]
            vertices[i].z = tri_vertices[i, 2]

        cdef Triangle * triangles = <Triangle *> rtcg.rtcSetNewGeometryBuffer(
                mesh,
                rtcb.RTC_BUFFER_TYPE_INDEX,
                0,
                rtc.RTC_FORMAT_UINT3,
                sizeof(Triangle),
                nt
            )

        for i in range(nt):
            triangles[i].v0 = tri_indices[i][0]
            triangles[i].v1 = tri_indices[i][1]
            triangles[i].v2 = tri_indices[i][2]

        # Commit geometry to the scene
        rtcg.rtcCommitGeometry(mesh)
        cdef unsigned int meshID = rtcs.rtcAttachGeometry(self.scene_i, mesh)

        self.vertices = vertices
        self.indices = triangles
        self.meshID = meshID
        self.mesh = mesh

    @cython.boundscheck(False) # turn off bounds-checking for entire function
    @cython.wraparound(False)  # turn off negative index wrapping for entire function
    def run(
        self,
        np.ndarray[np.float32_t, ndim=2] vec_origins,
        np.ndarray[np.float32_t, ndim=2] vec_directions
    ):
        cdef int nv = vec_origins.shape[0]
        cdef np.ndarray[np.int32_t, ndim=1] intersect_ids = np.empty(nv, dtype="int32")

        cdef rtcr.RTCIntersectContext ray_ctx
        rtcr.rtcInitIntersectContext( &ray_ctx)
        cdef rtcr.RTCRayHit ray_hit

        for i in range(nv):
            ray_hit.ray.org_x = vec_origins[i, 0]
            ray_hit.ray.org_y = vec_origins[i, 1]
            ray_hit.ray.org_z = vec_origins[i, 2]
            ray_hit.ray.dir_x = vec_directions[i, 0]
            ray_hit.ray.dir_y = vec_directions[i, 1]
            ray_hit.ray.dir_z = vec_directions[i, 2]
            ray_hit.ray.time = 0
            ray_hit.ray.mask = -1
            ray_hit.ray.flags = 0

            ray_hit.ray.tnear = 0.0
            ray_hit.ray.tfar = 1e37
            ray_hit.ray.id = i
            ray_hit.hit.geomID = rtcg.RTC_INVALID_GEOMETRY_ID
            ray_hit.hit.primID = rtcg.RTC_INVALID_GEOMETRY_ID

            rtcIntersect1(self.scene_i, &ray_ctx, &ray_hit)

            intersect_ids[i] = ray_hit.hit.primID

        return intersect_ids

    @cython.boundscheck(False) # turn off bounds-checking for entire function
    @cython.wraparound(False)  # turn off negative index wrapping for entire function
    def shortest_distance(
        self,
        np.ndarray[np.float32_t, ndim=2] vec_origins,
        np.ndarray[np.float32_t, ndim=2] vec_directions,
        float offset=0.0
    ):
        cdef int nv = vec_origins.shape[0]
        cdef np.float32_t dist = 1e37

        cdef rtcr.RTCIntersectContext ray_ctx
        rtcr.rtcInitIntersectContext( &ray_ctx)
        cdef rtcr.RTCRayHit ray_hit

        for i in range(nv):
            ray_hit.ray.org_x = vec_origins[i, 0] + offset * vec_directions[i, 0]
            ray_hit.ray.org_y = vec_origins[i, 1] + offset * vec_directions[i, 1]
            ray_hit.ray.org_z = vec_origins[i, 2] + offset * vec_directions[i, 2]
            ray_hit.ray.dir_x = vec_directions[i, 0]
            ray_hit.ray.dir_y = vec_directions[i, 1]
            ray_hit.ray.dir_z = vec_directions[i, 2]
            ray_hit.ray.time = 0
            ray_hit.ray.mask = -1
            ray_hit.ray.flags = 0

            ray_hit.ray.tnear = 0.0
            ray_hit.ray.tfar = dist
            ray_hit.ray.id = i
            ray_hit.hit.geomID = rtcg.RTC_INVALID_GEOMETRY_ID
            ray_hit.hit.primID = rtcg.RTC_INVALID_GEOMETRY_ID

            rtcIntersect1(self.scene_i, &ray_ctx, &ray_hit)

            if ray_hit.ray.tfar < dist:
                dist = ray_hit.ray.tfar

        return dist

    @cython.boundscheck(False) # turn off bounds-checking for entire function
    @cython.wraparound(False)  # turn off negative index wrapping for entire function
    def intersections(
        self,
        np.ndarray[np.float32_t, ndim=2] vec_origins,
        np.ndarray[np.float32_t, ndim=2] vec_directions
    ):
        cdef int nv = vec_origins.shape[0]
        cdef np.float64_t u, v, f
        cdef Triangle t
        cdef Vertex p0, p1, p2
        cdef np.ndarray[np.int32_t, ndim=1] primID = np.empty(nv, dtype="int32")
        cdef np.ndarray[np.float64_t, ndim=2] normal = np.empty((nv, 3), dtype="float64")
        cdef np.ndarray[np.float64_t, ndim=2] loc = np.empty((nv, 3), dtype="float64")

        cdef rtcr.RTCIntersectContext ray_ctx
        rtcr.rtcInitIntersectContext( &ray_ctx)
        cdef rtcr.RTCRayHit ray_hit

        for i in range(nv):
            ray_hit.ray.org_x = vec_origins[i, 0]
            ray_hit.ray.org_y = vec_origins[i, 1]
            ray_hit.ray.org_z = vec_origins[i, 2]
            ray_hit.ray.dir_x = vec_directions[i, 0]
            ray_hit.ray.dir_y = vec_directions[i, 1]
            ray_hit.ray.dir_z = vec_directions[i, 2]
            ray_hit.ray.time = 0
            ray_hit.ray.mask = -1
            ray_hit.ray.flags = 0

            ray_hit.ray.tnear = 0.0
            ray_hit.ray.tfar = 1e37
            ray_hit.ray.id = i
            ray_hit.hit.geomID = rtcg.RTC_INVALID_GEOMETRY_ID
            ray_hit.hit.primID = rtcg.RTC_INVALID_GEOMETRY_ID

            rtcIntersect1(self.scene_i, &ray_ctx, &ray_hit)

            primID[i] = ray_hit.hit.primID

            if primID[i] >= 0:
                t = self.indices[primID[i]]
                p0 = self.vertices[t.v0]
                p1 = self.vertices[t.v1]
                p2 = self.vertices[t.v2]

                u = ray_hit.hit.u
                v = ray_hit.hit.v

                loc[i, 0] = p0.x + u * (p1.x - p0.x) + v * (p2.x - p0.x)
                loc[i, 1] = p0.y + u * (p1.y - p0.y) + v * (p2.y - p0.y)
                loc[i, 2] = p0.z + u * (p1.z - p0.z) + v * (p2.z - p0.z)

                f = 1.0 / (ray_hit.hit.Ng_x**2 + ray_hit.hit.Ng_y**2 + ray_hit.hit.Ng_z**2)**0.5
                normal[i, 0] = f * ray_hit.hit.Ng_x
                normal[i, 1] = f * ray_hit.hit.Ng_y
                normal[i, 2] = f * ray_hit.hit.Ng_z

        return { 'primID': primID, 'normal': normal, 'loc': loc }
