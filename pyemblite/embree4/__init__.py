from ctypes import CDLL as _CDLL
from pathlib import Path as _Path

_dll_dir = _Path(__file__).parent
_tbb_dll = None
_tbb_dll_path_str = str(_dll_dir / "tbb12.dll")
try:
    _tbb_dll = _CDLL(_tbb_dll_path_str)
except OSError:
    # print(f"Could not load {_tbb_dll_path_str}.")
    pass

del _dll_dir, _tbb_dll, _tbb_dll_path_str