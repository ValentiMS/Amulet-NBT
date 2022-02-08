from .value cimport BaseTag, BaseMutableTag
from .util cimport BufferContext

cdef class ListTag(BaseMutableTag):
    cdef list value_
    cdef readonly char list_data_type

    cdef void _check_tag(self, BaseTag value, bint fix_if_empty=*) except *
    cdef void _check_tag_iterable(self, list value) except *

cdef class NamedListTag(ListTag):
    cdef public str name

    @staticmethod
    cdef NamedListTag read_named_payload(BufferContext buffer, bint little_endian)
