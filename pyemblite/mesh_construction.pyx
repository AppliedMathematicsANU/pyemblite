cimport numpy as np
cimport cython
from . cimport rtcore as rtc
from . cimport rtcore_buffer as rtcb
from . cimport rtcore_ray as rtcr
from . cimport rtcore_scene as rtcs
from . cimport rtcore_geometry as rtcg
from .rtcore cimport Vertex, Triangle


cdef extern from "mesh_construction.h":
    int triangulate_hex[12][3]
    int triangulate_tetra[4][3]

cdef class TriangleMesh:
    r'''

    This class constructs a polygon mesh with triangular elements and
    adds it to the scene.

    Parameters
    ----------

    scene : EmbreeScene
        This is the scene to which the constructed polygons will be
        added.
    vertices : a np.ndarray of floats.
        This specifies the x, y, and z coordinates of the vertices in
        the polygon mesh. This should either have the shape
        (num_triangles, 3, 3), or the shape (num_vertices, 3), depending
        on the value of the `indices` parameter.
    indices : either None, or a np.ndarray of ints
        If None, then vertices must have the shape (num_triangles, 3, 3).
        In this case, `vertices` specifices the coordinates of each
        vertex of each triangle in the mesh, with vertices being
        duplicated if they are shared between triangles. For example,
        if indices is None, then vertices[2][1][0] should give you
        the x-coordinate of the 2nd vertex of the 3rd triangle.
        If indices is a np.ndarray, then it must have the shape
        (num_triangles, 3), and `vertices` must have the shape
        (num_vertices, 3). In this case, indices[2][1] tells you
        the index of the 2nd vertex of the 3rd triangle in `indices`,
        while vertices[5][2] tells you the z-coordinate of the 6th
        vertex in the mesh. Note that the indexing is assumed to be
        zero-based. In this setup, vertices can be shared between
        triangles, and the number of vertices can be less than 3 times
        the number of triangles.

    '''

    cdef Vertex* vertices
    cdef Triangle* indices
    cdef unsigned int meshID
    cdef rtcg.RTCGeometry mesh

    def __init__(self,
        rtcs.EmbreeScene scene,
        np.ndarray vertices,
        np.ndarray indices = None,
        rtc.RTCBuildQuality build_quality=rtc.RTC_BUILD_QUALITY_MEDIUM
    ):

        if indices is None:
            self._build_from_flat(scene, vertices, build_quality)
        else:
            self._build_from_indices(scene, vertices, indices, build_quality)

    cdef void _build_from_flat(
        self,
        rtcs.EmbreeScene scene,
        np.ndarray tri_vertices,
        rtc.RTCBuildQuality build_quality=rtc.RTC_BUILD_QUALITY_MEDIUM
    ):
        cdef int i, j
        cdef int nt = tri_vertices.shape[0]
        # In this scheme, we don't share any vertices.  This leads to cracks,
        # but also means we have exactly three times as many vertices as
        # triangles.
        cdef rtcg.RTCGeometry mesh = rtcg.rtcNewGeometry(scene.device.device, rtcg.RTC_GEOMETRY_TYPE_TRIANGLE)
        rtcg.rtcSetGeometryBuildQuality(mesh, build_quality)

        cdef Vertex * vertices = <Vertex *> rtcg.rtcSetNewGeometryBuffer(
                mesh,
                rtcb.RTC_BUFFER_TYPE_VERTEX,
                0,
                rtc.RTC_FORMAT_FLOAT3,
                sizeof(Vertex),
                nt * 3
            )
        for i in range(nt):
            for j in range(3):
                vertices[i*3 + j].x = tri_vertices[i,j,0]
                vertices[i*3 + j].y = tri_vertices[i,j,1]
                vertices[i*3 + j].z = tri_vertices[i,j,2]

        cdef Triangle * triangles = <Triangle *> rtcg.rtcSetNewGeometryBuffer(
                mesh,
                rtcb.RTC_BUFFER_TYPE_INDEX,
                0,
                rtc.RTC_FORMAT_UINT3,
                sizeof(Triangle),
                nt
            )

        for i in range(nt):
            triangles[i].v0 = i*3 + 0
            triangles[i].v1 = i*3 + 1
            triangles[i].v2 = i*3 + 2

        # Commit geometry to the scene
        rtcg.rtcCommitGeometry(mesh);
        cdef unsigned int meshID = rtcs.rtcAttachGeometry(scene.scene_i, mesh)

        self.vertices = vertices
        self.indices = triangles
        self.meshID = meshID
        self.mesh = mesh

    cdef void _build_from_indices(
        self,
        rtcs.EmbreeScene scene,
        np.ndarray tri_vertices,
        np.ndarray tri_indices,
        rtc.RTCBuildQuality build_quality=rtc.RTC_BUILD_QUALITY_MEDIUM
    ):
        cdef int i
        cdef int nv = tri_vertices.shape[0]
        cdef int nt = tri_indices.shape[0]

        cdef rtcg.RTCGeometry mesh = rtcg.rtcNewGeometry(scene.device.device, rtcg.RTC_GEOMETRY_TYPE_TRIANGLE);
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
        rtcg.rtcCommitGeometry(mesh);
        cdef unsigned int meshID = rtcs.rtcAttachGeometry(scene.scene_i, mesh)

        self.vertices = vertices
        self.indices = triangles
        self.meshID = meshID
        self.mesh = mesh

    @cython.boundscheck(False) # turn off bounds-checking for entire function
    @cython.wraparound(False)  # turn off negative index wrapping for entire function
    def update_vertices(self, np.ndarray[np.float32_t, ndim=2] new_vertices):
        """
        """
        cdef int i = 0
        cdef int nv = new_vertices.shape[0]
        cdef Vertex * vertices = <Vertex *>rtcg.rtcGetGeometryBufferData(self.mesh, rtcb.RTC_BUFFER_TYPE_VERTEX, 0)
        for i in range(nv):
            vertices[i].x = new_vertices[i, 0]
            vertices[i].y = new_vertices[i, 1]
            vertices[i].z = new_vertices[i, 2]

        # commit mesh
        rtcg.rtcUpdateGeometryBuffer(self.mesh, rtcb.RTC_BUFFER_TYPE_VERTEX, 0);
        rtcg.rtcCommitGeometry(self.mesh);

    @property
    def mesh_id(self):
        return self.meshID

    def __dealloc__(self):
        rtcg.rtcReleaseGeometry(self.mesh)


cdef class ElementMesh(TriangleMesh):
    r'''

    Currently, we handle non-triangular mesh types by converting them
    to triangular meshes. This class performs this transformation.
    Currently, this is implemented for hexahedral and tetrahedral
    meshes.

    Parameters
    ----------

    scene : EmbreeScene
        This is the scene to which the constructed polygons will be
        added.
    vertices : a np.ndarray of floats.
        This specifies the x, y, and z coordinates of the vertices in
        the polygon mesh. This should either have the shape
        (num_vertices, 3). For example, vertices[2][1] should give the
        y-coordinate of the 3rd vertex in the mesh.
    indices : a np.ndarray of ints
        This should either have the shape (num_elements, 4) or
        (num_elements, 8) for tetrahedral and hexahedral meshes,
        respectively. For tetrahedral meshes, each element will
        be represented by four triangles in the scene. For hex meshes,
        each element will be represented by 12 triangles, 2 for each
        face. For hex meshes, we assume that the node ordering is as
        defined here:
        http://homepages.cae.wisc.edu/~tautges/papers/cnmev3.pdf

    '''

    def __init__(
        self,
        rtcs.EmbreeScene scene,
        np.ndarray vertices,
        np.ndarray indices,
        rtc.RTCBuildQuality build_quality=rtc.RTC_BUILD_QUALITY_MEDIUM
    ):
        # We need now to figure out if we've been handed quads or tetrahedra.
        # If it's quads, we can build the mesh slightly differently.
        # http://stackoverflow.com/questions/23723993/converting-quadriladerals-in-an-obj-file-into-triangles
        if indices.shape[1] == 8:
            self._build_from_hexahedra(scene, vertices, indices, build_quality)
        elif indices.shape[1] == 4:
            self._build_from_tetrahedra(scene, vertices, indices, build_quality)
        else:
            raise NotImplementedError

    cdef void _build_from_hexahedra(
        self,
        rtcs.EmbreeScene scene,
        np.ndarray quad_vertices,
        np.ndarray quad_indices,
        rtc.RTCBuildQuality build_quality=rtc.RTC_BUILD_QUALITY_MEDIUM
    ):

        cdef int i, j
        cdef int nv = quad_vertices.shape[0]
        cdef int ne = quad_indices.shape[0]

        # There are six faces for every quad.  Each of those will be divided
        # into two triangles.
        cdef int nt = 6*2*ne

        cdef rtcg.RTCGeometry mesh = rtcg.rtcNewGeometry(scene.device.device, rtcg.RTC_GEOMETRY_TYPE_TRIANGLE)
        rtcg.rtcSetGeometryBuildQuality(mesh, build_quality)

        # first just copy over the vertices
        cdef Vertex * vertices = <Vertex *> rtcg.rtcSetNewGeometryBuffer(
                mesh,
                rtcb.RTC_BUFFER_TYPE_VERTEX,
                0,
                rtc.RTC_FORMAT_FLOAT3,
                sizeof(Vertex),
                nv
            )

        for i in range(nv):
            vertices[i].x = quad_vertices[i, 0]
            vertices[i].y = quad_vertices[i, 1]
            vertices[i].z = quad_vertices[i, 2]

        # now build up the triangles
        cdef Triangle * triangles = <Triangle *> rtcg.rtcSetNewGeometryBuffer(
                mesh,
                rtcb.RTC_BUFFER_TYPE_INDEX,
                0,
                rtc.RTC_FORMAT_UINT3,
                sizeof(Triangle),
                nt
            )

        for i in range(ne):
            for j in range(12):
                triangles[12*i+j].v0 = quad_indices[i][triangulate_hex[j][0]]
                triangles[12*i+j].v1 = quad_indices[i][triangulate_hex[j][1]]
                triangles[12*i+j].v2 = quad_indices[i][triangulate_hex[j][2]]

        # Commit geometry to the scene
        rtcg.rtcCommitGeometry(mesh);
        cdef unsigned int meshID = rtcs.rtcAttachGeometry(scene.scene_i, mesh)

        self.vertices = vertices
        self.indices = triangles
        self.meshID = meshID
        self.mesh = mesh

    cdef void _build_from_tetrahedra(
        self,
        rtcs.EmbreeScene scene,
        np.ndarray tetra_vertices,
        np.ndarray tetra_indices,
        rtc.RTCBuildQuality build_quality=rtc.RTC_BUILD_QUALITY_MEDIUM
    ):

        cdef int i, j
        cdef int nv = tetra_vertices.shape[0]
        cdef int ne = tetra_indices.shape[0]

        # There are four triangle faces for each tetrahedron.
        cdef int nt = 4*ne

        cdef rtcg.RTCGeometry mesh = rtcg.rtcNewGeometry(scene.device.device, rtcg.RTC_GEOMETRY_TYPE_TRIANGLE)
        rtcg.rtcSetGeometryBuildQuality(mesh, build_quality)

        # first just copy over the vertices
        cdef Vertex * vertices = <Vertex *> rtcg.rtcSetNewGeometryBuffer(
                mesh,
                rtcb.RTC_BUFFER_TYPE_VERTEX,
                0,
                rtc.RTC_FORMAT_FLOAT3,
                sizeof(Vertex),
                nv
            )

        for i in range(nv):
            vertices[i].x = tetra_vertices[i, 0]
            vertices[i].y = tetra_vertices[i, 1]
            vertices[i].z = tetra_vertices[i, 2]

        # Now build up the triangles
        cdef Triangle * triangles = <Triangle *> rtcg.rtcSetNewGeometryBuffer(
                mesh,
                rtcb.RTC_BUFFER_TYPE_INDEX,
                0,
                rtc.RTC_FORMAT_UINT3,
                sizeof(Triangle),
                nt
            )

        for i in range(ne):
            for j in range(4):
                triangles[4*i+j].v0 = tetra_indices[i][triangulate_tetra[j][0]]
                triangles[4*i+j].v1 = tetra_indices[i][triangulate_tetra[j][1]]
                triangles[4*i+j].v2 = tetra_indices[i][triangulate_tetra[j][2]]

        # Commit geometry to the scene
        rtcg.rtcCommitGeometry(mesh);
        cdef unsigned int meshID = rtcs.rtcAttachGeometry(scene.scene_i, mesh)

        self.vertices = vertices
        self.indices = triangles
        self.meshID = meshID
        self.mesh = mesh

