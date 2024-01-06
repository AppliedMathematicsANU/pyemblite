"""
Unit tests.
"""
from unittest import TestCase
import numpy as np
from pyemblite import rtcore as rtc
from pyemblite import rtcore_scene as rtcs
from pyemblite import test_scene as rtcts
from pyemblite.mesh_construction import TriangleMesh


def xplane(x):
    return [[[x, -1.0, -1.0],
             [x, +1.0, -1.0],
             [x, -1.0, +1.0]],
            [[x, +1.0, -1.0],
             [x, +1.0, +1.0],
             [x, -1.0, +1.0]]]


def xplane_only_points(x):
    # Indices are [[0, 1, 2], [1, 3, 2]]
    return [[x, -1.0, -1.0],
            [x, +1.0, -1.0],
            [x, -1.0, +1.0],
            [x, +1.0, +1.0]]


def define_rays_origins_and_directions():
    N = 4
    origins = np.zeros((N, 3), dtype='float32')
    origins[:, 0] = 0.1
    origins[0, 1] = -0.2
    origins[1, 1] = +0.2
    origins[2, 1] = +0.3
    origins[3, 1] = -8.2

    dirs = np.zeros((N, 3), dtype='float32')
    dirs[:, 0] = 1.0
    return origins, dirs


class TestPyEmblite(TestCase):
    def test_pyemblite_should_be_able_to_display_embree_version(self):

        embreeDevice = rtc.EmbreeDevice()
        print(embreeDevice)

    def test_pyemblite_should_be_able_to_create_a_scene(self):

        embreeDevice = rtc.EmbreeDevice()
        scene = rtcs.EmbreeScene(embreeDevice)
        self.assertIsNotNone(scene)

    def test_pyemblite_should_be_able_to_create_several_scenes(self):

        embreeDevice = rtc.EmbreeDevice()
        scene1 = rtcs.EmbreeScene(embreeDevice)
        self.assertIsNotNone(scene1)
        scene2 = rtcs.EmbreeScene(embreeDevice)
        self.assertIsNotNone(scene2)

    def test_pyemblite_should_be_able_to_create_a_device_if_not_provided(self):
        from pyemblite import rtcore_scene as rtcs

        scene = rtcs.EmbreeScene()
        self.assertIsNotNone(scene)

    def test_pyemblite_scene_flags(self):
        from pyemblite import rtcore_scene as rtcs

        scene = rtcs.EmbreeScene()
        # print(dir(rtcs))
        flags = \
            (
                rtcs.RTC_SCENE_FLAG_DYNAMIC
                |
                rtcs.RTC_SCENE_FLAG_ROBUST
            )
        self.assertNotEqual(flags, scene.get_flags())

        scene.set_flags(flags)
        self.assertEqual(flags, scene.get_flags())

    def test_pyemblite_scene_build_quality(self):
        from pyemblite import rtcore_scene as rtcs

        scene = rtcs.EmbreeScene()
        # print(dir(rtcs))
        quality = \
            (
                rtc.RTC_BUILD_QUALITY_HIGH
            )
        scene.set_build_quality(quality)


class TestGeometry(TestCase):

    def test_geom1(self):
        rtcts.TestScene().test_geom1()

    def test_geom2(self):
        rtcts.TestScene().test_geom2()

    def test_geom3(self):
        rtcts.TestScene().test_geom3()

    def test_mesh1(self):
        rtcts.TestScene().test_mesh1()


class TestIntersectionTriangles(TestCase):

    def setUp(self):
        """Initialisation"""

        import logging

        self.logger = logging.getLogger(__name__ + ".TestIntersectionTriangles")

        self.logger.info("Creating triangle arrays...")
        self.triangles = xplane(7.0)
        self.triangles = np.array(self.triangles, 'float32')

        self.logger.info("Creating device...")
        self.embreeDevice = rtc.EmbreeDevice()

        self.logger.info("Creating scene...")
        self.scene = rtcs.EmbreeScene(self.embreeDevice)

        self.logger.info("Creating mesh...")
        self.mesh = TriangleMesh(self.scene, self.triangles)
        self.logger.info("%s", dir(self.mesh))

        self.logger.info("Creating ray origins and directions...")
        origins, dirs = define_rays_origins_and_directions()
        self.origins = origins
        self.dirs = dirs

    def tearDown(self):
        del self.mesh
        del self.scene
        del self.embreeDevice

    def test_intersect_simple(self):
        res = self.scene.run(self.origins, self.dirs)
        self.logger.info("res=%s", res)
        self.assertSequenceEqual([0, 1, 1, -1], np.asarray(res).tolist())

    def test_intersect_distance(self):
        self.logger.info("origins=%s", self.origins)
        self.logger.info("dirs   =%s", self.dirs)
        res = self.scene.run(self.origins, self.dirs, query='DISTANCE')
        self.logger.info("res=%s", res)
        self.assertTrue(np.allclose([6.9, 6.9, 6.9, 1e37], res))

    def test_intersect(self):
        self.logger.info("Running intersection...")
        res = self.scene.run(self.origins, self.dirs, output=1, dists=100)
        self.logger.info("res=%s", res)

        self.assertTrue([0, 0, 0, -1], res['geomID'])
        ray_inter = res['geomID'] >= 0
        primID = res['primID'][ray_inter]
        u = res['u'][ray_inter]
        v = res['v'][ray_inter]
        tfar = res['tfar']
        self.assertTrue([0, 1, 1], primID)
        self.assertTrue(np.allclose([6.9, 6.9, 6.9, 100], tfar))
        self.assertTrue(np.allclose([0.4, 0.1, 0.15], u))
        self.assertTrue(np.allclose([0.5, 0.4, 0.35], v))

    def test_update_vertices(self):

        flags = \
            (
                rtcs.RTC_SCENE_FLAG_DYNAMIC
                |
                rtcs.RTC_SCENE_FLAG_ROBUST
            )

        self.scene.set_flags(flags)
        quality = \
            (
                rtc.RTC_BUILD_QUALITY_HIGH
            )
        self.scene.set_build_quality(quality)

        self.logger.info("Running intersection...")
        res = self.scene.run(self.origins, self.dirs, output=1, dists=100)
        self.logger.info("res=%s", res)

        self.assertTrue([0, 0, 0, -1], res['geomID'])
        ray_inter = res['geomID'] >= 0
        primID = res['primID'][ray_inter]
        u = res['u'][ray_inter]
        v = res['v'][ray_inter]
        tfar = res['tfar']
        self.assertTrue([0, 1, 1], primID)
        self.assertTrue(np.allclose([6.9, 6.9, 6.9, 100], tfar))
        self.assertTrue(np.allclose([0.4, 0.1, 0.15], u))
        self.assertTrue(np.allclose([0.5, 0.4, 0.35], v))

        new_vertices = \
            np.ascontiguousarray(
                self.triangles.astype(np.float32).reshape((3 * self.triangles.shape[0], 3))
                +
                np.asarray((1.0, 0.0, 0.0), dtype=np.float32)
            )
        self.mesh.update_vertices(new_vertices)
        self.scene.commit()
        self.logger.info("Running 2nd intersection, post vertex shift...")
        res = self.scene.run(self.origins, self.dirs, output=1, dists=100)
        self.logger.info("res=%s", res)

        self.assertTrue([0, 0, 0, -1], res['geomID'])
        ray_inter = res['geomID'] >= 0
        primID = res['primID'][ray_inter]
        u = res['u'][ray_inter]
        v = res['v'][ray_inter]
        tfar = res['tfar']
        self.logger.info("tfar=%s" % (tfar,))
        self.assertTrue([0, 1, 1], primID)
        self.assertTrue(np.allclose([7.9, 7.9, 7.9, 100], tfar))
        self.assertTrue(np.allclose([0.4, 0.1, 0.15], u))
        self.assertTrue(np.allclose([0.5, 0.4, 0.35], v))


class TestIntersectionTrianglesFromIndices(TestCase):

    def setUp(self):
        """Initialisation"""

        points = xplane_only_points(7.0)
        points = np.array(points, 'float32')
        indices = np.array([[0, 1, 2], [1, 3, 2]], 'uint32')

        self.embreeDevice = rtc.EmbreeDevice()
        self.scene = rtcs.EmbreeScene(self.embreeDevice)
        mesh = TriangleMesh(self.scene, points, indices)
        origins, dirs = define_rays_origins_and_directions()
        self.origins = origins
        self.dirs = dirs
        del mesh

    def test_intersect_simple(self):
        res = self.scene.run(self.origins, self.dirs)
        self.assertTrue([0, 1, 1, -1], res)

    def test_intersect(self):
        res = self.scene.run(self.origins, self.dirs, output=1)

        self.assertTrue([0, 0, 0, -1], res['geomID'])

        ray_inter = res['geomID'] >= 0
        primID = res['primID'][ray_inter]
        u = res['u'][ray_inter]
        v = res['v'][ray_inter]
        tfar = res['tfar'][ray_inter]
        self.assertTrue([0, 1, 1], primID)
        self.assertTrue(np.allclose([6.9, 6.9, 6.9], tfar))
        self.assertTrue(np.allclose([0.4, 0.1, 0.15], u))
        self.assertTrue(np.allclose([0.5, 0.4, 0.35], v))


def initialise_loggers(names, log_level=None, handler_class=None):
    """
    Initialises specified loggers to generate output at the
    specified logging level. If the specified named loggers do not exist,
    they are created.

    :type names: :obj:`list` of :obj:`str`
    :param names: List of logger names.
    :type log_level: :obj:`int`
    :param log_level: Log level for messages, typically
       one of :obj:`logging.DEBUG`, :obj:`logging.INFO`, :obj:`logging.WARN`, :obj:`logging.ERROR`
       or :obj:`logging.CRITICAL`.
       See :ref:`levels`.
    :type handler_class: One of the :obj:`logging.handlers` classes.
    :param handler_class: The handler class for output of log messages,
       for example :obj:`logging.StreamHandler`.

    """
    import logging
    if handler_class is None:
        handler_class = logging.StreamHandler
    if log_level is None:
        log_level = logging.WARNING
    for name in names:
        logr = logging.getLogger(name)
        handler = handler_class()
        logr.addHandler(handler)
        logr.setLevel(log_level)


if __name__ == '__main__':
    import logging
    from unittest import main

    initialise_loggers(["pyemblite", __name__, ], logging.WARNING)
    main()
