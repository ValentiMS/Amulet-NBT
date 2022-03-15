# cython: language_level=3, boundscheck=False, wraparound=False
# distutils: language = c++
# distutils: extra_compile_args = -std=c++17 /std:c++17
# distutils: extra_link_args = -std=c++17 /std:c++17

from libc.stdint cimport (
int8_t,
int16_t,
int32_t,
int64_t,
)

from libcpp.memory cimport shared_ptr
from libcpp.map cimport map
from libcpp.string cimport string
from libcpp.vector cimport vector
from libcpp.list cimport list as cpp_list
from libcpp.variant cimport variant

cdef extern from "nbt.h" nogil:

    # raw objects
    ctypedef int8_t ByteTag
    ctypedef int16_t ShortTag
    ctypedef int32_t IntTag
    ctypedef int64_t LongTag
    ctypedef float FloatTag
    ctypedef double DoubleTag
    ctypedef vector[ByteTag] ByteArrayTag
    ctypedef string StringTag
    cdef cppclass ListTag
    cdef cppclass CompoundTag
    ctypedef vector[IntTag] IntArrayTag
    ctypedef vector[LongTag] LongArrayTag

    # shared pointers to raw objects
    ctypedef shared_ptr[ByteTag] SharedByteTag
    ctypedef shared_ptr[ShortTag] SharedShortTag
    ctypedef shared_ptr[IntTag] SharedIntTag
    ctypedef shared_ptr[LongTag] SharedLongTag
    ctypedef shared_ptr[FloatTag] SharedFloatTag
    ctypedef shared_ptr[DoubleTag] SharedDoubleTag
    ctypedef shared_ptr[ByteArrayTag] SharedByteArrayTag
    ctypedef shared_ptr[StringTag] SharedStringTag
    ctypedef shared_ptr[ListTag] SharedListTag
    ctypedef shared_ptr[CompoundTag] SharedCompoundTag
    ctypedef shared_ptr[IntArrayTag] SharedIntArrayTag
    ctypedef shared_ptr[LongArrayTag] SharedLongArrayTag

    # lists containing shared pointers to raw objects
    ctypedef cpp_list[SharedByteTag] ByteTagList
    ctypedef cpp_list[SharedShortTag] ShortTagList
    ctypedef cpp_list[SharedIntTag] IntTagList
    ctypedef cpp_list[SharedLongTag] LongTagList
    ctypedef cpp_list[SharedFloatTag] FloatTagList
    ctypedef cpp_list[SharedDoubleTag] DoubleTagList
    ctypedef cpp_list[SharedByteArrayTag] ByteArrayTagList
    ctypedef cpp_list[SharedStringTag] StringTagList
    ctypedef cpp_list[SharedListTag] ListTagList
    ctypedef cpp_list[SharedCompoundTag] CompoundTagList
    ctypedef cpp_list[SharedIntArrayTag] IntArrayTagList
    ctypedef cpp_list[SharedLongArrayTag] LongArrayTagList

    cdef cppclass ListTag(variant):
        pass

    cdef cppclass CompoundTagValue(variant):
        pass

    cdef cppclass CompoundTag(map[string, CompoundTagValue]):
        pass
