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
from libcpp.unordered_map cimport unordered_map
from libcpp.string cimport string
from libcpp.vector cimport vector
from libcpp.variant cimport variant

cdef extern from "nbt.h" nogil:
    cdef cppclass Array[T]:
        ctypedef T value_type

        ctypedef size_t size_type
        ctypedef ptrdiff_t difference_type

        cppclass iterator:
            T& operator*()
            iterator operator++()
            iterator operator--()
            iterator operator+(size_type)
            iterator operator-(size_type)
            difference_type operator-(iterator)
            bint operator==(iterator)
            bint operator!=(iterator)
            bint operator<(iterator)
            bint operator>(iterator)
            bint operator<=(iterator)
            bint operator>=(iterator)
        cppclass const_iterator(iterator):
            pass
        cppclass reverse_iterator:
            T& operator*()
            reverse_iterator operator++()
            reverse_iterator operator--()
            reverse_iterator operator+(size_type)
            reverse_iterator operator-(size_type)
            difference_type operator-(reverse_iterator)
            bint operator==(reverse_iterator)
            bint operator!=(reverse_iterator)
            bint operator<(reverse_iterator)
            bint operator>(reverse_iterator)
            bint operator<=(reverse_iterator)
            bint operator>=(reverse_iterator)
        cppclass const_reverse_iterator(reverse_iterator):
            pass
        Array() except +
        Array(Array&) except +
        Array(size_type) except +
        Array(size_type, T&) except +
        #Array[InputIt](InputIt, InputIt)
        T& operator[](size_type)
        #Array& operator=(Array&)
        bint operator==(Array&, Array&)
        bint operator!=(Array&, Array&)
        bint operator<(Array&, Array&)
        bint operator>(Array&, Array&)
        bint operator<=(Array&, Array&)
        bint operator>=(Array&, Array&)
        # void assign(size_type, const T&)
        # void assign[InputIt](InputIt, InputIt) except +
        T& at(size_type) except +
        T& back()
        iterator begin()
        const_iterator const_begin "begin"()
        # size_type capacity()
        # void clear()
        bint empty()
        iterator end()
        const_iterator const_end "end"()
        # iterator erase(iterator)
        # iterator erase(iterator, iterator)
        T& front()
        # iterator insert(iterator, const T&) except +
        # iterator insert(iterator, size_type, const T&) except +
        # iterator insert[InputIt](iterator, InputIt, InputIt) except +
        size_type max_size()
        # void pop_back()
        # void push_back(T&) except +
        # reverse_iterator rbegin()
        # const_reverse_iterator const_rbegin "crbegin"()
        # reverse_iterator rend()
        # const_reverse_iterator const_rend "crend"()
        # void reserve(size_type) except +
        # void resize(size_type) except +
        # void resize(size_type, T&) except +
        size_type size()
        # void swap(Array&)

        # C++11 methods
        T* data()
        const T* const_data "data"()
        # void shrink_to_fit() except +
        # iterator emplace(const_iterator, ...) except +
        # T& emplace_back(...) except +


    # raw objects
    ctypedef int8_t RawByteTag
    ctypedef int16_t RawShortTag
    ctypedef int32_t RawIntTag
    ctypedef int64_t RawLongTag
    ctypedef float RawFloatTag
    ctypedef double RawDoubleTag
    ctypedef Array[RawByteTag] RawByteArrayTag
    ctypedef string RawStringTag
    cdef cppclass RawListTag
    cdef cppclass RawCompoundTag
    ctypedef Array[RawIntTag] RawIntArrayTag
    ctypedef Array[RawLongTag] RawLongArrayTag

    # shared pointers to raw objects
    ctypedef shared_ptr[RawByteTag] CByteTag
    ctypedef shared_ptr[RawShortTag] CShortTag
    ctypedef shared_ptr[RawIntTag] CIntTag
    ctypedef shared_ptr[RawLongTag] CLongTag
    ctypedef shared_ptr[RawFloatTag] CFloatTag
    ctypedef shared_ptr[RawDoubleTag] CDoubleTag
    ctypedef shared_ptr[RawByteArrayTag] CByteArrayTag
    ctypedef shared_ptr[RawStringTag] CStringTag
    ctypedef shared_ptr[RawListTag] CListTag
    ctypedef shared_ptr[RawCompoundTag] CCompoundTag
    ctypedef shared_ptr[RawIntArrayTag] CIntArrayTag
    ctypedef shared_ptr[RawLongArrayTag] CLongArrayTag

    # lists containing shared pointers to raw objects
    ctypedef vector[CByteTag] ByteTagList
    ctypedef vector[CShortTag] ShortTagList
    ctypedef vector[CIntTag] IntTagList
    ctypedef vector[CLongTag] LongTagList
    ctypedef vector[CFloatTag] FloatTagList
    ctypedef vector[CDoubleTag] DoubleTagList
    ctypedef vector[CByteArrayTag] ByteArrayTagList
    ctypedef vector[CStringTag] StringTagList
    ctypedef vector[CListTag] ListTagList
    ctypedef vector[CCompoundTag] CompoundTagList
    ctypedef vector[CIntArrayTag] IntArrayTagList
    ctypedef vector[CLongArrayTag] LongArrayTagList

    cdef cppclass RawListTag(variant):
        pass

    cdef cppclass CompoundTagValue(variant):
        pass

    cdef cppclass RawCompoundTag(unordered_map[string, CompoundTagValue]):
        pass
