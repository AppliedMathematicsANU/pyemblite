"""
Unit tests.
"""
import unittest
from unittest import TestCase
import numpy as np
from pyemblite import rtcore as rtc
from pyemblite import rtcore_scene as rtcs
from pyemblite import test_scene as rtcts
from pyemblite.mesh_construction import TriangleMesh
have_trimesh = False
try:
    import trimesh
    have_trimesh = True
except Exception:
    have_trimesh = False


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


class TestMultiIntersection(TestCase):

    def setUp(self):
        """Initialisation"""

        self.offsets = np.linspace(4.0, 32.0, 8)
        boxes = list(
            trimesh.primitives.Box(extents=[2.0, 2.0, 2.0])
            for offset in self.offsets
        )
        for box, offset in zip(boxes, self.offsets):
            box.apply_translation([0.0, 0.0, offset])

        self.embreeDevice = rtc.EmbreeDevice()
        self.scene = rtcs.EmbreeScene(self.embreeDevice)
        self.box_meshes = list(
            TriangleMesh(
                self.scene,
                np.asarray(box.vertices).astype(dtype=np.float32),
                np.asarray(box.faces).astype(np.int32)
            )
            for box in boxes
        )

    @unittest.skipUnless(have_trimesh, "Can't import trimesh.")
    def test_multi_hit_intersect_first_gid(self):
        """
        """
        origins = np.asarray([[0.0, 0.0, 0.0], ], dtype=np.float32)
        dirs = np.asarray([[1.0, 0.0, 0.0], ], dtype=np.float32)

        hits = self.scene.multi_hit_intersect_first_gid(vec_origins=origins, vec_directions=dirs)
        self.assertEqual(0, hits.shape[0])

        dirs = np.asarray([[0.0, 0.0, 1.0], ], dtype=np.float32)
        hits = self.scene.multi_hit_intersect_first_gid(vec_origins=origins, vec_directions=dirs)
        self.assertEqual(8, hits.shape[0])
        for idx, offset in enumerate(self.offsets):
            self.assertAlmostEqual(offset - 1.0, hits["tfar"][idx], 5)
            self.assertEqual(self.box_meshes[idx].mesh_id, hits["geomID"][idx])
            self.assertEqual(0, hits["rayIDX"][idx])
        self.assertEqual(len(self.box_meshes), len(np.unique(hits["geomID"])))

        origins = np.asarray([[0.5, 0.5, 0.0], [-0.5, -0.5, 0.0]], dtype=np.float32)
        dirs = np.asarray([[0.0, 0.0, 1.0], [0.0, 0.0, 1.0]], dtype=np.float32)
        hits = self.scene.multi_hit_intersect_first_gid(vec_origins=origins, vec_directions=dirs)
        self.assertEqual(16, hits.shape[0])
        for hits in [hits[hits["rayIDX"] == 0], hits[hits["rayIDX"] == 1]]:
            for idx, offset in enumerate(self.offsets):
                self.assertAlmostEqual(offset - 1.0, hits["tfar"][idx], 5)
                self.assertEqual(self.box_meshes[idx].mesh_id, hits["geomID"][idx])
        self.assertEqual(len(self.box_meshes), len(np.unique(hits["geomID"])))


class TestIntersectionCount(TestCase):

    def setUp(self):
        """Initialisation"""
        import logging

        self.logger = logging.getLogger(__name__ + "." + self.__class__.__name__)

        self.embreeDevice = rtc.EmbreeDevice()
        self.scene = rtcs.EmbreeScene(self.embreeDevice)
        self.trimesh_sphere = \
            trimesh.primitives.Sphere(center=(0.0, 0.0, 0.0), radius=2.0, subdivisions=4)
        self.sphere_triangle_mesh = \
            TriangleMesh(self.scene, self.trimesh_sphere.vertices, self.trimesh_sphere.faces)

    @unittest.skipUnless(have_trimesh, "Can't import trimesh.")
    def test_first_hit_intersect_pid_count_with_weight(self):
        """
        """
        self.logger.info("sphere num faces = %s", self.trimesh_sphere.faces.shape[0])
        directions = np.asarray(self.trimesh_sphere.triangles_center, dtype=np.float32).copy()
        directions /= np.linalg.norm(directions, axis=1).reshape((-1, 1))
        origins = np.zeros_like(directions)
        weights = np.ones_like(origins, shape=(origins.shape[0], ))
        counts_dict = \
            self.scene.first_hit_intersect_pid_count_with_weight(origins, directions, weights)
        self.assertEqual(1, len(counts_dict))
        self.assertTrue(0 in counts_dict)
        self.assertEqual(self.trimesh_sphere.faces.shape[0], counts_dict[0].shape[0])
        self.assertTrue("primID" in counts_dict[0].dtype.names)
        self.assertTrue("count" in counts_dict[0].dtype.names)
        self.assertTrue("weight" in counts_dict[0].dtype.names)
        self.assertTrue(
            np.all(
                np.sort(counts_dict[0]["primID"]) == np.arange(self.trimesh_sphere.faces.shape[0])
            )
        )
        self.assertTrue(np.all(counts_dict[0]["count"] == 1))
        self.assertTrue(np.all(counts_dict[0]["weight"] == 1))

        sgl_idxs = np.arange(1, self.trimesh_sphere.faces.shape[0], 2)
        self.logger.info("sgl_idxs.shape[0] = %s", sgl_idxs.shape[0])
        directions = np.asarray(self.trimesh_sphere.triangles_center, dtype=np.float32).copy()
        directions /= np.linalg.norm(directions, axis=1).reshape((-1, 1))
        directions = directions[sgl_idxs].copy()
        origins = np.zeros_like(directions)
        weights = np.ones((origins.shape[0], ), dtype=np.float32)
        counts_dict = \
            self.scene.first_hit_intersect_pid_count_with_weight(origins, directions, weights)
        self.assertEqual(1, len(counts_dict))
        self.assertTrue(0 in counts_dict)
        self.assertEqual(sgl_idxs.shape[0], counts_dict[0].shape[0])
        self.assertSequenceEqual(
            sorted(sgl_idxs.tolist()),
            sorted(counts_dict[0]["primID"].tolist())
        )
        self.assertTrue(np.all(counts_dict[0]["count"] == 1))
        self.assertTrue(np.all(counts_dict[0]["weight"] == 1))

        dbl_idxs = np.arange(0, self.trimesh_sphere.faces.shape[0], 2)
        sgl_idxs = np.arange(1, self.trimesh_sphere.faces.shape[0], 2)
        directions = np.asarray(self.trimesh_sphere.triangles_center, dtype=np.float32).copy()
        directions /= np.linalg.norm(directions, axis=1).reshape((-1, 1))
        directions = np.vstack((directions, directions[dbl_idxs]))
        origins = np.zeros_like(directions)
        weights = np.ones((origins.shape[0], ), dtype=np.float32)
        counts_dict = \
            self.scene.first_hit_intersect_pid_count_with_weight(origins, directions, weights)
        self.assertEqual(1, len(counts_dict))
        self.assertTrue(0 in counts_dict)
        self.assertEqual(self.trimesh_sphere.faces.shape[0], counts_dict[0].shape[0])
        counts_ary = counts_dict[0]
        sort_idx = np.argsort(counts_ary["primID"])
        counts_ary = counts_ary[sort_idx].copy()
        self.assertTrue(np.all(counts_ary[sgl_idxs]["count"] == 1))
        self.assertTrue(np.all(counts_ary[dbl_idxs]["count"] == 2))
        self.assertTrue(np.all(counts_ary["count"] == counts_ary["weight"]))

    @unittest.skipUnless(have_trimesh, "Can't import trimesh.")
    def test_first_hit_intersect_pid_count(self):
        """
        """
        self.logger.info("sphere num faces = %s", self.trimesh_sphere.faces.shape[0])
        directions = np.asarray(self.trimesh_sphere.triangles_center, dtype=np.float32).copy()
        directions /= np.linalg.norm(directions, axis=1).reshape((-1, 1))
        origins = np.zeros_like(directions)
        counts_dict = self.scene.first_hit_intersect_pid_count(origins, directions)
        self.assertEqual(1, len(counts_dict))
        self.assertTrue(0 in counts_dict)
        self.assertEqual(self.trimesh_sphere.faces.shape[0], counts_dict[0].shape[0])
        self.assertTrue(np.all(counts_dict[0][:, 1] == 1))

        sgl_idxs = np.arange(1, self.trimesh_sphere.faces.shape[0], 2)
        self.logger.info("sgl_idxs.shape[0] = %s", sgl_idxs.shape[0])
        directions = np.asarray(self.trimesh_sphere.triangles_center, dtype=np.float32).copy()
        directions /= np.linalg.norm(directions, axis=1).reshape((-1, 1))
        directions = directions[sgl_idxs].copy()
        origins = np.zeros_like(directions)
        counts_dict = self.scene.first_hit_intersect_pid_count(origins, directions)
        self.assertEqual(1, len(counts_dict))
        self.assertTrue(0 in counts_dict)
        self.assertEqual(sgl_idxs.shape[0], counts_dict[0].shape[0])
        self.assertSequenceEqual(
            sorted(sgl_idxs.tolist()),
            sorted(counts_dict[0][:, 0].tolist())
        )
        self.assertTrue(np.all(counts_dict[0][:, 1] == 1))

        dbl_idxs = np.arange(0, self.trimesh_sphere.faces.shape[0], 2)
        sgl_idxs = np.arange(1, self.trimesh_sphere.faces.shape[0], 2)
        directions = np.asarray(self.trimesh_sphere.triangles_center, dtype=np.float32).copy()
        directions /= np.linalg.norm(directions, axis=1).reshape((-1, 1))
        directions = np.vstack((directions, directions[dbl_idxs]))
        origins = np.zeros_like(directions)
        counts_dict = self.scene.first_hit_intersect_pid_count(origins, directions)
        self.assertEqual(1, len(counts_dict))
        self.assertTrue(0 in counts_dict)
        self.assertEqual(self.trimesh_sphere.faces.shape[0], counts_dict[0].shape[0])
        counts_ary = counts_dict[0]
        sort_idx = np.argsort(counts_ary[:, 0])
        counts_ary = counts_ary[sort_idx].copy()
        self.assertTrue(np.all(counts_ary[sgl_idxs][:, 1] == 1))
        self.assertTrue(np.all(counts_ary[dbl_idxs][:, 1] == 2))


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
