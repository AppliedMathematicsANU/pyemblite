cimport cython
cimport numpy as np
import numpy as np
import logging
import numbers
from . cimport rtcore as rtc
from . cimport rtcore_ray as rtcr
from . cimport rtcore_geometry as rtcg
from . cimport rtcore_buffer as rtcb
from . cimport rtcore_scene as rtcs
from .rtcore cimport Vertex, Triangle


log = logging.getLogger(__name__)

cdef class TestScene:

    def logger(self):
        """
        """
        import logging
        return logging.getLogger(__name__ + ".TestScene")

    def test_geom1(self):
        cdef rtc.RTCDevice device = rtc.rtcNewDevice(NULL)  # "verbose=3"
        cdef rtcs.RTCScene scene = rtcs.rtcNewScene(device)
        cdef rtcg.RTCGeometry mesh = rtcg.rtcNewGeometry(device, rtcg.RTC_GEOMETRY_TYPE_TRIANGLE)
        rtcg.rtcReleaseGeometry(mesh)
        rtcs.rtcReleaseScene(scene)
        rtc.rtcReleaseDevice(device)

    def test_geom2(self):
        cdef rtc.EmbreeDevice device = rtc.EmbreeDevice()
        cdef rtcs.RTCScene scene = rtcs.rtcNewScene(device.device)
        cdef rtcg.RTCGeometry mesh = rtcg.rtcNewGeometry(device.device, rtcg.RTC_GEOMETRY_TYPE_TRIANGLE)
        rtcg.rtcReleaseGeometry(mesh)
        rtcs.rtcReleaseScene(scene)

    def test_geom3(self):
        cdef rtc.EmbreeDevice device = rtc.EmbreeDevice()
        cdef rtcs.EmbreeScene scene = rtcs.EmbreeScene(device)
        cdef rtcg.RTCGeometry mesh = rtcg.rtcNewGeometry(scene.device.device, rtcg.RTC_GEOMETRY_TYPE_TRIANGLE)
        rtcg.rtcReleaseGeometry(mesh)

        rtcs.rtcCommitScene(scene.scene_i)
        cdef rtc.RTCBounds bnds
        rtcs.rtcGetSceneBounds(scene.scene_i, &bnds)
        self.logger().info(bnds.lower_x, bnds.lower_y, bnds.lower_z, bnds.upper_x, bnds.upper_y, bnds.upper_z)

    def test_mesh1(self):
        from pyemblite.mesh_construction import TriangleMesh

        triangles = np.array((((0.0, 0.0, 0.0), (1.0,0.0,0.0), (1.0, 1.0, 0.0)),), dtype=np.float32)

        embreeDevice = rtc.EmbreeDevice()
        cdef rtcs.EmbreeScene scene = rtcs.EmbreeScene(embreeDevice)
        mesh = TriangleMesh(scene, triangles)
        rtcs.rtcCommitScene(scene.scene_i)
        cdef rtc.RTCBounds bnds
        rtcs.rtcGetSceneBounds(scene.scene_i, &bnds)
        self.logger().info(bnds.lower_x, bnds.lower_y, bnds.lower_z, bnds.upper_x, bnds.upper_y, bnds.upper_z)
        del mesh
        del scene
        del embreeDevice
