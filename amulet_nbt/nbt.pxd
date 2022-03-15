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
    ctypedef int8_t RawByteTag
    ctypedef int16_t RawShortTag
    ctypedef int32_t RawIntTag
    ctypedef int64_t RawLongTag
    ctypedef float RawFloatTag
    ctypedef double RawDoubleTag
    ctypedef vector[RawByteTag] RawByteArrayTag
    ctypedef string RawStringTag
    cdef cppclass RawListTag
    cdef cppclass RawCompoundTag
    ctypedef vector[RawIntTag] RawIntArrayTag
    ctypedef vector[RawLongTag] RawLongArrayTag

    # shared pointers to raw objects
    ctypedef shared_ptr[RawByteTag] ByteTag
    ctypedef shared_ptr[RawShortTag] ShortTag
    ctypedef shared_ptr[RawIntTag] IntTag
    ctypedef shared_ptr[RawLongTag] LongTag
    ctypedef shared_ptr[RawFloatTag] FloatTag
    ctypedef shared_ptr[RawDoubleTag] DoubleTag
    ctypedef shared_ptr[RawByteArrayTag] ByteArrayTag
    ctypedef shared_ptr[RawStringTag] StringTag
    ctypedef shared_ptr[RawListTag] ListTag
    ctypedef shared_ptr[RawCompoundTag] CompoundTag
    ctypedef shared_ptr[RawIntArrayTag] IntArrayTag
    ctypedef shared_ptr[RawLongArrayTag] LongArrayTag

    # lists containing shared pointers to raw objects
    ctypedef cpp_list[ByteTag] ByteTagList
    ctypedef cpp_list[ShortTag] ShortTagList
    ctypedef cpp_list[IntTag] IntTagList
    ctypedef cpp_list[LongTag] LongTagList
    ctypedef cpp_list[FloatTag] FloatTagList
    ctypedef cpp_list[DoubleTag] DoubleTagList
    ctypedef cpp_list[ByteArrayTag] ByteArrayTagList
    ctypedef cpp_list[StringTag] StringTagList
    ctypedef cpp_list[ListTag] ListTagList
    ctypedef cpp_list[CompoundTag] CompoundTagList
    ctypedef cpp_list[IntArrayTag] IntArrayTagList
    ctypedef cpp_list[LongArrayTag] LongArrayTagList

    cdef cppclass RawListTag(variant):
        pass

    cdef cppclass CompoundTagValue(variant):
        pass

    cdef cppclass RawCompoundTag(map[string, CompoundTagValue]):
        pass
