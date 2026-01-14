"""
Utilities.
"""


def get_default_embree_version():
    """
    Returns the integer Embree major version number.
    """
    import os

    env_version = os.environ.get("PYEMBLITE_EMBREE_MAJOR_VERSION", None)
    if env_version is not None:
        env_version = int(env_version)

    default_version = None
    if (env_version is None) or (env_version == 4):
        try:
            from .embree4 import rtcore4, rtcore_scene4, mesh_construction4, test_scene4  # noqa:
            default_version = 4
        except ImportError:
            pass

    if (default_version is None) and ((env_version is None) or (env_version == 3)):
        try:
            from .embree3 import rtcore3, rtcore_scene3, mesh_construction3, test_scene3  # noqa:
            default_version = 3
        except ImportError:
            pass

    if default_version is None:
        if env_version is None:
            raise RuntimeError(
                "No embree API (e.g. rtcore?) versions could be imported from .embree3 or .embree4"
            )
        else:
            raise RuntimeError(
                f"No embree API (e.g. rtcore{env_version}) versions"
                +
                f" could be imported from .embree{env_version}."
            )

    return default_version


def do_api_star_import(src_module_name, dst_module_name):
    """
    Imports the :samp:`src_module_name.*"` variables/functions into
    the :samp:`{dst_module_name}` module.
    """
    import importlib

    pkg_name = ".".join(__name__.split(".")[:-1])
    src_module = importlib.import_module(
        src_module_name,
        pkg_name if src_module_name.startswith(".") else None
    )
    dst_module = importlib.import_module(
        dst_module_name,
        pkg_name if dst_module_name.startswith(".") else None
    )
    attr_dict = {k: getattr(src_module, k) for k in dir(src_module) if not k.startswith("__")}
    for attr_name, attr_value in attr_dict.items():
        setattr(dst_module, attr_name, attr_value)


def do_embree_version_star_import(dst_module_name, embree_version=None):
    """
    Imports the :samp:`".embree?.module_name.*"` variables/functions into
    the :samp:`{dst_module_name}` module.
    """
    if embree_version is None:
        embree_version = get_default_embree_version()
    src_module_name = (
        ".embree" + str(embree_version) + "." + dst_module_name.split(".")[-1] + str(embree_version)
    )
    do_api_star_import(src_module_name=src_module_name, dst_module_name=dst_module_name)
