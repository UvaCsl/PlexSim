/* Generated by Cython 3.0a6 */

#ifndef __PYX_HAVE__plexsim__models
#define __PYX_HAVE__plexsim__models

#include "Python.h"
struct PyModel;

/* "plexsim/models.pxd":217
 * 
 * 
 * cdef public class Model [object PyModel, type PyModel_t]:             # <<<<<<<<<<<<<<
 *     """
 *     Interface for the models and serves a top of the hierarchy in the
 */
struct PyModel {
  PyObject_HEAD
  struct __pyx_vtabstruct_7plexsim_6models_Model *__pyx_vtab;
  PyObject *ptr;
  __Pyx_memviewslice _Model__states;
  __pyx_t_7plexsim_6models_state_t *_states;
  __Pyx_memviewslice _Model__newstates;
  __pyx_t_7plexsim_6models_state_t *_newstates;
  int _last_written;
  int _use_mcmc;
  __Pyx_memviewslice _agentStates;
  __Pyx_memviewslice _memory;
  size_t _memorySize;
  size_t _memento;
  PyObject *_updateType;
  PyObject *_nudgeType;
  size_t _sampleSize;
  __pyx_t_7plexsim_6models_Nudges _nudges;
  double _kNudges;
  size_t _nStates;
  double _z;
  struct __pyx_obj_7plexsim_6models_Rules *_rules;
  struct __pyx_obj_7plexsim_6models_Adjacency *adj;
  struct __pyx_obj_7plexsim_6models_RandomGenerator *_rng;
  struct __pyx_obj_7plexsim_6models_MCMC *_mcmc;
  PyObject *__dict__;
};

#ifndef __PYX_HAVE_API__plexsim__models

#ifndef __PYX_EXTERN_C
  #ifdef __cplusplus
    #define __PYX_EXTERN_C extern "C"
  #else
    #define __PYX_EXTERN_C extern
  #endif
#endif

#ifndef DL_IMPORT
  #define DL_IMPORT(_T) _T
#endif

__PYX_EXTERN_C DL_IMPORT(PyTypeObject) PyModel_t;

#endif /* !__PYX_HAVE_API__plexsim__models */

/* WARNING: the interface of the module init function changed in CPython 3.5. */
/* It now returns a PyModuleDef instance instead of a PyModule instance. */

#if PY_MAJOR_VERSION < 3
PyMODINIT_FUNC initmodels(void);
#else
/* WARNING: Use PyImport_AppendInittab("models", PyInit_models) instead of calling PyInit_models directly from Python 3.5 */
PyMODINIT_FUNC PyInit_models(void);

#if PY_VERSION_HEX >= 0x03050000 && (defined(__GNUC__) || defined(__clang__) || defined(_MSC_VER) || (defined(__cplusplus) && __cplusplus >= 201402L))
#if defined(__cplusplus) && __cplusplus >= 201402L
[[deprecated("Use PyImport_AppendInittab(\"models\", PyInit_models) instead of calling PyInit_models directly.")]] inline
#elif defined(__GNUC__) || defined(__clang__)
__attribute__ ((__deprecated__("Use PyImport_AppendInittab(\"models\", PyInit_models) instead of calling PyInit_models directly."), __unused__)) __inline__
#elif defined(_MSC_VER)
__declspec(deprecated("Use PyImport_AppendInittab(\"models\", PyInit_models) instead of calling PyInit_models directly.")) __inline
#endif
static PyObject* __PYX_WARN_IF_INIT_CALLED(PyObject* res) {
  return res;
}
#define PyInit_models() __PYX_WARN_IF_INIT_CALLED(PyInit_models())
#endif
#endif

#endif /* !__PYX_HAVE__plexsim__models */
