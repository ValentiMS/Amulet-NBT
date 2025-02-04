import gzip
from math import trunc, floor, ceil
import zlib
from collections.abc import MutableMapping, MutableSequence
from io import BytesIO
from typing import Optional, Union, Tuple, List, Iterator, BinaryIO

import numpy
import os
from cpython cimport PyUnicode_DecodeUTF8, PyList_Append, PyBytes_FromStringAndSize

import re

cdef char _ID_END = 0
cdef char _ID_BYTE = 1
cdef char _ID_SHORT = 2
cdef char _ID_INT = 3
cdef char _ID_LONG = 4
cdef char _ID_FLOAT = 5
cdef char _ID_DOUBLE = 6
cdef char _ID_BYTE_ARRAY = 7
cdef char _ID_STRING = 8
cdef char _ID_LIST = 9
cdef char _ID_COMPOUND = 10
cdef char _ID_INT_ARRAY = 11
cdef char _ID_LONG_ARRAY = 12
cdef char _ID_MAX = 13

ID_END = _ID_END
ID_BYTE = _ID_BYTE
ID_SHORT = _ID_SHORT
ID_INT = _ID_INT
ID_LONG = _ID_LONG
ID_FLOAT = _ID_FLOAT
ID_DOUBLE = _ID_DOUBLE
ID_BYTE_ARRAY = _ID_BYTE_ARRAY
ID_STRING = _ID_STRING
ID_LIST = _ID_LIST
ID_COMPOUND = _ID_COMPOUND
ID_INT_ARRAY = _ID_INT_ARRAY
ID_LONG_ARRAY = _ID_LONG_ARRAY
ID_MAX = _ID_MAX

IMPLEMENTATION = "cython"

cdef dict TAG_CLASSES = {
    _ID_BYTE: TAG_Byte,
    _ID_SHORT: TAG_Short,
    _ID_INT: TAG_Int,
    _ID_LONG: TAG_Long,
    _ID_FLOAT: TAG_Float,
    _ID_DOUBLE: TAG_Double,
    _ID_BYTE_ARRAY: TAG_Byte_Array,
    _ID_STRING: TAG_String,
    _ID_LIST: _TAG_List,
    _ID_COMPOUND: _TAG_Compound,
    _ID_INT_ARRAY: TAG_Int_Array,
    _ID_LONG_ARRAY: TAG_Long_Array
}

_NON_QUOTED_KEY = re.compile(r"^[a-zA-Z0-9-]+$")

AnyNBT = Union[
    'TAG_Byte',
    'TAG_Short',
    'TAG_Int',
    'TAG_Long',
    'TAG_Float',
    'TAG_Double',
    'TAG_Byte_Array',
    'TAG_String',
    'TAG_List',
    'TAG_Compound',
    'TAG_Int_Array',
    'TAG_Long_Array'
]

SNBTType = str
cdef str CommaNewline = ",\n"
cdef str CommaSpace = ", "


class NBTError(Exception):
    """Some error in the NBT library."""


class NBTLoadError(NBTError):
    """The NBT data failed to load for some reason."""
    pass


class NBTFormatError(NBTLoadError):
    """Indicates the NBT format is invalid."""
    pass


class SNBTParseError(NBTError):
    """Indicates the SNBT format is invalid."""
    pass


cdef class buffer_context:
    cdef size_t offset
    cdef char *buffer
    cdef size_t size

cdef char *read_data(buffer_context context, size_t tag_size) except NULL:
    if tag_size > context.size - context.offset:
        raise NBTFormatError(
            f"NBT Stream too short. Asked for {tag_size:d}, only had {(context.size - context.offset):d}")

    cdef char*value = context.buffer + context.offset
    context.offset += tag_size
    return value

cdef void to_little_endian(void *data_buffer, int num_bytes, bint little_endian = False):
    if little_endian:
        return

    cdef unsigned char *buf = <unsigned char *> data_buffer
    cdef int i

    for i in range((num_bytes + 1) // 2):
        buf[i], buf[num_bytes - i - 1] = buf[num_bytes - i - 1], buf[i]

cdef str load_name(buffer_context context, bint little_endian):
    cdef unsigned short *pointer = <unsigned short *> read_data(context, 2)
    cdef unsigned short length = pointer[0]
    to_little_endian(&length, 2, little_endian)
    b = read_data(context, length)

    return PyUnicode_DecodeUTF8(b, length, "strict")

cdef tuple load_named(buffer_context context, char tagID, bint little_endian):
    cdef str name = load_name(context, little_endian)
    cdef _TAG_Value tag = load_tag(tagID, context, little_endian)
    return name, tag

cdef _TAG_Value load_tag(char tagID, buffer_context context, bint little_endian):
    if tagID == _ID_BYTE:
        return load_byte(context, little_endian)

    if tagID == _ID_SHORT:
        return load_short(context, little_endian)

    if tagID == _ID_INT:
        return load_int(context, little_endian)

    if tagID == _ID_LONG:
        return load_long(context, little_endian)

    if tagID == _ID_FLOAT:
        return load_float(context, little_endian)

    if tagID == _ID_DOUBLE:
        return load_double(context, little_endian)

    if tagID == _ID_BYTE_ARRAY:
        return load_byte_array(context, little_endian)

    if tagID == _ID_STRING:
        return TAG_String(load_string(context, little_endian))

    if tagID == _ID_LIST:
        return load_list(context, little_endian)

    if tagID == _ID_COMPOUND:
        return load_compound_tag(context, little_endian)

    if tagID == _ID_INT_ARRAY:
        return load_int_array(context, little_endian)

    if tagID == _ID_LONG_ARRAY:
        return load_long_array(context, little_endian)

cpdef bytes safe_gunzip(bytes data):
    if data[:2] == b'\x1f\x8b':  # if the first two bytes are this it should be gzipped
        try:
            data = gzip.GzipFile(fileobj=BytesIO(data)).read()
        except (IOError, zlib.error) as e:
            pass
    return data

cdef class _TAG_Value:
    tag_id = None

    def __hash__(self):
        return hash((self.tag_id, self.value))

    def copy(self):
        return self.__class__(self.value)

    cpdef str to_snbt(self, indent_chr=None):
        if isinstance(indent_chr, int):
            return self._pretty_to_snbt(" " * indent_chr)
        elif isinstance(indent_chr, str):
            return self._pretty_to_snbt(indent_chr)
        return self._to_snbt()

    cpdef str _to_snbt(self):
        raise NotImplementedError()

    cpdef str _pretty_to_snbt(self, indent_chr="", indent_count=0, leading_indent=True):
        return f"{indent_chr * indent_count * leading_indent}{self._to_snbt()}"

    cdef void write_value(self, buffer, little_endian) except *:
        raise NotImplementedError()

    cpdef bint strict_equal(self, other):
        cdef bint result
        result = isinstance(other, self.__class__)
        if result:
            result = result and self.tag_id == other.tag_id
        return result and self.__eq__(other)

    def __eq__(self, other):
        return primitive_conversion(self) == primitive_conversion(other)

    def __repr__(self):
        return self._to_snbt()

    def __reduce__(self):
        return unpickle_nbt, (self.tag_id, self.value)

BaseValueType = _TAG_Value

cdef class _Int(_TAG_Value):
    def __eq__(self, other):
        return primitive_conversion(self) == primitive_conversion(other)

    def __hash__(self):
        return hash((self.tag_id, self.value))

    def __add__(self, other):
        return primitive_conversion(self) + primitive_conversion(other)

    def __sub__(self, other):
        return primitive_conversion(self) - primitive_conversion(other)

    def __mul__(self, other):
        return primitive_conversion(self) * primitive_conversion(other)

    def __truediv__(self, other):
        return primitive_conversion(self) / primitive_conversion(other)

    def __floordiv__(self, other):
        return primitive_conversion(self) // primitive_conversion(other)

    def __mod__(self, other):
        return primitive_conversion(self) % primitive_conversion(other)

    def __divmod__(self, other):
        return divmod(primitive_conversion(self), primitive_conversion(other))

    def __pow__(self, power, modulo):
        return pow(primitive_conversion(self), power, modulo)

    def __lshift__(self, other):
        return primitive_conversion(self) << primitive_conversion(other)

    def __rshift__(self, other):
        return primitive_conversion(self) >> primitive_conversion(other)

    def __and__(self, other):
        return primitive_conversion(self) & primitive_conversion(other)

    def __xor__(self, other):
        return primitive_conversion(self) ^ primitive_conversion(other)

    def __or__(self, other):
        return primitive_conversion(self) | primitive_conversion(other)

    def __radd__(self, other):
        return primitive_conversion(other) + primitive_conversion(self)

    def __rsub__(self, other):
        return primitive_conversion(other) - primitive_conversion(self)

    def __rmul__(self, other):
        return primitive_conversion(other) * primitive_conversion(self)

    def __rtruediv__(self, other):
        return primitive_conversion(other) / primitive_conversion(self)

    def __rfloordiv__(self, other):
        return primitive_conversion(other) // primitive_conversion(self)

    def __rmod__(self, other):
        return primitive_conversion(other) % primitive_conversion(self)

    def __rdivmod__(self, other):
        return divmod(primitive_conversion(other), primitive_conversion(self))

    def __rpow__(self, other, modulo):
        return pow(primitive_conversion(other), primitive_conversion(self), modulo)

    def __rlshift__(self, other):
        return primitive_conversion(other) << primitive_conversion(self)

    def __rrshift__(self, other):
        return primitive_conversion(other) >> primitive_conversion(self)

    def __rand__(self, other):
        return primitive_conversion(other) & primitive_conversion(self)

    def __rxor__(self, other):
        return primitive_conversion(other) ^ primitive_conversion(self)

    def __ror__(self, other):
        return primitive_conversion(other) | primitive_conversion(self)

    def __neg__(self):
        return -self.value

    def __pos__(self):
        return +self.value

    def __abs__(self):
        return abs(self.value)

    def __invert__(self):
        return ~self.value

    def __int__(self):
        return self.value

    def __float__(self):
        return float(self.value)

    def __getattr__(self, item):
        return self.value.__getattribute__(item)

    def __dir__(self):
        return dir(self.value)

    def __ge__(self, other):
        return self.value.__ge__(primitive_conversion(other))

    def __gt__(self, other):
        return self.value.__gt__(primitive_conversion(other))

    def __le__(self, other):
        return self.value.__le__(primitive_conversion(other))

    def __lt__(self, other):
        return self.value.__lt__(primitive_conversion(other))


cdef class _Float(_TAG_Value):
    def __eq__(self, other):
        return primitive_conversion(self) == primitive_conversion(other)

    def __hash__(self):
        return hash((self.tag_id, self.value))

    def __add__(self, other):
        return float(primitive_conversion(self) + primitive_conversion(other))

    def __sub__(self, other):
        return float(primitive_conversion(self) - primitive_conversion(other))

    def __mul__(self, other):
        return float(primitive_conversion(self) * primitive_conversion(other))

    def __truediv__(self, other):
        return float(primitive_conversion(self) / primitive_conversion(other))

    def __floordiv__(self, other):
        return primitive_conversion(self) // primitive_conversion(other)

    def __mod__(self, other):
        return primitive_conversion(self) % primitive_conversion(other)

    def __divmod__(self, other):
        return divmod(primitive_conversion(self), primitive_conversion(other))

    def __pow__(self, power, modulo):
        return pow(primitive_conversion(self), power, modulo)

    def __lshift__(self, other):
        return primitive_conversion(self) << primitive_conversion(other)

    def __rshift__(self, other):
        return primitive_conversion(self) >> primitive_conversion(other)

    def __and__(self, other):
        return primitive_conversion(self) & primitive_conversion(other)

    def __xor__(self, other):
        return primitive_conversion(self) ^ primitive_conversion(other)

    def __or__(self, other):
        return primitive_conversion(self) | primitive_conversion(other)

    def __radd__(self, other):
        return float(primitive_conversion(other) + primitive_conversion(self))

    def __rsub__(self, other):
        return float(primitive_conversion(other) - primitive_conversion(self))

    def __rmul__(self, other):
        return primitive_conversion(other) * primitive_conversion(self)

    def __rtruediv__(self, other):
        return float(primitive_conversion(other) / primitive_conversion(self))

    def __rfloordiv__(self, other):
        return primitive_conversion(other) // primitive_conversion(self)

    def __rmod__(self, other):
        return primitive_conversion(other) % primitive_conversion(self)

    def __rdivmod__(self, other):
        return divmod(primitive_conversion(other), primitive_conversion(self))

    def __rpow__(self, other, modulo):
        return pow(primitive_conversion(other), primitive_conversion(self), modulo)

    def __rlshift__(self, other):
        return primitive_conversion(other) << primitive_conversion(self)

    def __rrshift__(self, other):
        return primitive_conversion(other) >> primitive_conversion(self)

    def __rand__(self, other):
        return primitive_conversion(other) & primitive_conversion(self)

    def __rxor__(self, other):
        return primitive_conversion(other) ^ primitive_conversion(self)

    def __ror__(self, other):
        return primitive_conversion(other) | primitive_conversion(self)

    def __neg__(self):
        return -self.value

    def __pos__(self):
        return +self.value

    def __abs__(self):
        return abs(self.value)

    def __float__(self):
        return self.value

    def __round__(self, n=None):
        return round(self.value, n)

    def __trunc__(self):
        return trunc(self.value)

    def __floor__(self):
        return floor(self.value)

    def __ceil__(self):
        return ceil(self.value)

    def __getattr__(self, item):
        return self.value.__getattribute__(item)

    def __dir__(self):
        return dir(self.value)


cdef inline primitive_conversion(obj):
    return obj.value if isinstance(obj, _TAG_Value) else obj


cdef class TAG_Byte(_Int):
    tag_id = _ID_BYTE
    cdef readonly char value

    def __init__(self, value = 0):
        self.value = int(primitive_conversion(value))

    cpdef str _to_snbt(self):
        return f"{self.value}b"

    cdef void write_value(self, buffer, little_endian):
        write_byte(self.value, buffer)

cdef class TAG_Short(_Int):
    tag_id = _ID_SHORT
    cdef readonly short value

    def __init__(self, value = 0):
        self.value = int(primitive_conversion(value))

    cpdef str _to_snbt(self):
        return f"{self.value}s"

    cdef void write_value(self, buffer, little_endian):
        write_short(self.value, buffer, little_endian)


cdef class TAG_Int(_Int):
    tag_id = _ID_INT
    cdef readonly int value

    def __init__(self, value = 0):
        self.value = int(primitive_conversion(value))

    cpdef str _to_snbt(self):
        return f"{self.value}"

    cdef void write_value(self, buffer, little_endian):
        write_int(self.value, buffer, little_endian)


cdef class TAG_Long(_Int):
    tag_id = _ID_LONG
    cdef readonly long long value

    def __init__(self, value = 0):
        self.value = int(primitive_conversion(value))

    cpdef str _to_snbt(self):
        return f"{self.value}L"

    cdef void write_value(self, buffer, little_endian):
        write_long(self.value, buffer, little_endian)


cdef class TAG_Float(_Float):
    tag_id = _ID_FLOAT
    cdef readonly float value

    def __init__(self, value = 0):
        self.value = float(primitive_conversion(value))

    cpdef str _to_snbt(self):
        return f"{self.value:.20f}".rstrip('0') + "f"

    cdef void write_value(self, buffer, little_endian):
        write_float(self.value, buffer, little_endian)


cdef class TAG_Double(_Float):
    tag_id = _ID_DOUBLE
    cdef readonly double value

    def __init__(self, value = 0):
        self.value = float(primitive_conversion(value))

    cpdef str _to_snbt(self):
        return f"{self.value:.20f}".rstrip('0') + "d"

    cdef void write_value(self, buffer, little_endian):
        write_double(self.value, buffer, little_endian)

cdef class _TAG_Array(_TAG_Value):
    cdef public object value
    big_endian_data_type = little_endian_data_type = numpy.dtype("int8")

    def __init__(self, object value = None):
        if value is None:
            value = numpy.zeros((0,), self.big_endian_data_type)
        elif isinstance(value, (list, tuple)):
            value = numpy.array(value, self.big_endian_data_type)
        elif isinstance(value, (TAG_Byte_Array, TAG_Int_Array, TAG_Long_Array)):
            value = value.value
        if isinstance(value, numpy.ndarray):
            if value.dtype != self.big_endian_data_type:
                value = value.astype(self.big_endian_data_type)
        else:
            raise NBTError(f'Unexpected object {value} given to {self.__class__.__name__}')

        self.value = value

    def __eq__(self, other):
        return numpy.array_equal(primitive_conversion(self), primitive_conversion(other))

    def __getitem__(self, item):
        return self.value.__getitem__(item)

    def __setitem__(self, key, value):
        self.value.__setitem__(key, value)

    def __deepcopy__(self, memo=None):
        return self.__class__(self.value.__deepcopy__(memo or {}))

    def __getattr__(self, item):
        return self.value.__getattribute__(item)

    def __dir__(self):
        return dir(self.value)

    def __array__(self):
        return self.value

    def __len__(self):
        return len(self.value)

    def __add__(self, other):
        return (primitive_conversion(self) + primitive_conversion(other)).astype(self.big_endian_data_type)

    def __sub__(self, other):
        return (primitive_conversion(self) - primitive_conversion(other)).astype(self.big_endian_data_type)

    def __mul__(self, other):
        return (primitive_conversion(self) - primitive_conversion(other)).astype(self.big_endian_data_type)

    def __matmul__(self, other):
        return (primitive_conversion(self) @ primitive_conversion(other)).astype(self.big_endian_data_type)

    def __truediv__(self, other):
        return (primitive_conversion(self) / primitive_conversion(other)).astype(self.big_endian_data_type)

    def __floordiv__(self, other):
        return (primitive_conversion(self) // primitive_conversion(other)).astype(self.big_endian_data_type)

    def __mod__(self, other):
        return (primitive_conversion(self) % primitive_conversion(other)).astype(self.big_endian_data_type)

    def __divmod__(self, other):
        return divmod(primitive_conversion(self), primitive_conversion(other))

    def __pow__(self, power, modulo):
        return pow(primitive_conversion(self), power, modulo).astype(self.big_endian_data_type)

    def __lshift__(self, other):
        return (primitive_conversion(self) << primitive_conversion(other)).astype(self.big_endian_data_type)

    def __rshift__(self, other):
        return (primitive_conversion(self) >> primitive_conversion(other)).astype(self.big_endian_data_type)

    def __and__(self, other):
        return (primitive_conversion(self) & primitive_conversion(other)).astype(self.big_endian_data_type)

    def __xor__(self, other):
        return (primitive_conversion(self) ^ primitive_conversion(other)).astype(self.big_endian_data_type)

    def __or__(self, other):
        return (primitive_conversion(self) | primitive_conversion(other)).astype(self.big_endian_data_type)

    def __radd__(self, other):
        return (primitive_conversion(other) + primitive_conversion(self)).astype(self.big_endian_data_type)

    def __rsub__(self, other):
        return (primitive_conversion(other) - primitive_conversion(self)).astype(self.big_endian_data_type)

    def __rmul__(self, other):
        return (primitive_conversion(other) * primitive_conversion(self)).astype(self.big_endian_data_type)

    def __rtruediv__(self, other):
        return (primitive_conversion(other) / primitive_conversion(self)).astype(self.big_endian_data_type)

    def __rfloordiv__(self, other):
        return (primitive_conversion(other) // primitive_conversion(self)).astype(self.big_endian_data_type)

    def __rmod__(self, other):
        return (primitive_conversion(other) % primitive_conversion(self)).astype(self.big_endian_data_type)

    def __rdivmod__(self, other):
        return divmod(primitive_conversion(other), primitive_conversion(self))

    def __rpow__(self, other, modulo):
        return pow(primitive_conversion(other), primitive_conversion(self), modulo).astype(self.big_endian_data_type)

    def __rlshift__(self, other):
        return (primitive_conversion(other) << primitive_conversion(self)).astype(self.big_endian_data_type)

    def __rrshift__(self, other):
        return (primitive_conversion(other) >> primitive_conversion(self)).astype(self.big_endian_data_type)

    def __rand__(self, other):
        return (primitive_conversion(other) & primitive_conversion(self)).astype(self.big_endian_data_type)

    def __rxor__(self, other):
        return (primitive_conversion(other) ^ primitive_conversion(self)).astype(self.big_endian_data_type)

    def __ror__(self, other):
        return (primitive_conversion(other) | primitive_conversion(self)).astype(self.big_endian_data_type)

    def __neg__(self):
        return (-self.value).astype(self.big_endian_data_type)

    def __pos__(self):
        return (+self.value).astype(self.big_endian_data_type)

    def __abs__(self):
        return abs(self.value).astype(self.big_endian_data_type)


BaseArrayType = _TAG_Array

cdef class TAG_Byte_Array(_TAG_Array):
    tag_id = _ID_BYTE_ARRAY
    big_endian_data_type = little_endian_data_type = numpy.dtype("int8")

    cpdef str _to_snbt(self):
        cdef int elem
        cdef list tags = []
        for elem in self.value:
            tags.append(f"{elem}B")
        return f"[B;{CommaSpace.join(tags)}]"

    cdef void write_value(self, buffer, little_endian):
        data_type = self.little_endian_data_type if little_endian else self.big_endian_data_type
        if self.value.dtype != data_type:
            if self.value.dtype != self.big_endian_data_type if little_endian else self.little_endian_data_type:
                print(f'[Warning] Mismatch array dtype. Expected: {data_type.str}, got: {self.value.dtype.str}')
            self.value = self.value.astype(data_type)
        write_array(self.value, buffer, 1, little_endian)

cdef class TAG_Int_Array(_TAG_Array):
    tag_id = _ID_INT_ARRAY
    big_endian_data_type = numpy.dtype(">i4")
    little_endian_data_type = numpy.dtype("<i4")

    cpdef str _to_snbt(self):
        cdef int elem
        cdef list tags = []
        for elem in self.value:
            tags.append(str(elem))
        return f"[I;{CommaSpace.join(tags)}]"

    cdef void write_value(self, buffer, little_endian):
        data_type = self.little_endian_data_type if little_endian else self.big_endian_data_type
        if self.value.dtype != data_type:
            if self.value.dtype != self.big_endian_data_type if little_endian else self.little_endian_data_type:
                print(f'[Warning] Mismatch array dtype. Expected: {data_type.str}, got: {self.value.dtype.str}')
            self.value = self.value.astype(data_type)
        write_array(self.value, buffer, 4, little_endian)

cdef class TAG_Long_Array(_TAG_Array):
    tag_id = _ID_LONG_ARRAY
    big_endian_data_type = numpy.dtype(">i8")
    little_endian_data_type = numpy.dtype("<i8")

    cpdef str _to_snbt(self):
        cdef long long elem
        cdef list tags = []
        for elem in self.value:
            tags.append(f"{elem}L")
        return f"[L;{CommaSpace.join(tags)}]"

    cdef void write_value(self, buffer, little_endian):
        data_type = self.little_endian_data_type if little_endian else self.big_endian_data_type
        if self.value.dtype != data_type:
            if self.value.dtype != self.big_endian_data_type if little_endian else self.little_endian_data_type:
                print(f'[Warning] Mismatch array dtype. Expected: {data_type.str}, got: {self.value.dtype.str}')
            self.value = self.value.astype(data_type)
        write_array(self.value, buffer, 8, little_endian)


def escape(string: str):
    return string.replace('\\', '\\\\').replace('"', '\\"')

def unescape(string: str):
    return string.replace('\\"', '"').replace("\\\\", "\\")

cdef class TAG_String(_TAG_Value):
    tag_id = _ID_STRING
    cdef readonly bytes py_bytes

    @property
    def value(self) -> str:
        return self.py_str

    @property
    def py_str(self) -> str:
        return self.py_bytes.decode("utf-8")

    def __init__(self, value = ""):
        if isinstance(value, bytes):
            self.py_bytes = value
        else:
            self.py_bytes = str(value).encode("utf-8")

    def __eq__(self, other):
        if isinstance(self, TAG_String) and isinstance(other, TAG_String):
            return self.py_bytes == other.py_bytes
        else:
            return primitive_conversion(self) == primitive_conversion(other)

    def __hash__(self):
        return hash((self.tag_id, self.value))

    def __len__(self) -> int:
        return len(self.value)

    cpdef str _to_snbt(self):
        return f"\"{escape(self.value)}\""

    cdef void write_value(self, buffer, little_endian):
        write_string(self.py_bytes, buffer, little_endian)

    def __getitem__(self, item):
        return self.value.__getitem__(item)

    def __add__(self, other):
        return primitive_conversion(self) + primitive_conversion(other)

    def __radd__(self, other):
        return primitive_conversion(other) + primitive_conversion(self)

    def __mul__(self, other):
        return primitive_conversion(self) * primitive_conversion(other)

    def __rmul__(self, other):
        return primitive_conversion(other) * primitive_conversion(self)

    def __str__(self):
        return self.value

    def __reduce__(self):
        return unpickle_nbt, (self.tag_id, self.py_bytes)

    def copy(self):
        return self.__class__(self.py_bytes)


cdef class _TAG_List(_TAG_Value):
    tag_id = _ID_LIST
    cdef public list value
    cdef public char list_data_type

    def __init__(self, value = None, char list_data_type = 1):
        self.list_data_type = list_data_type
        self.value = []
        if value:
            self._check_tag(value[0])
            self.value = list(value)
            for tag in value[1:]:
                self._check_tag(tag)
            #map(self._check_tag, value[1:])

    def _check_tag(self, value: AnyNBT):
        if not isinstance(value, _TAG_Value):
            raise TypeError(f"Invalid type {value.__class__.__name__} TAG_List. Must be an NBT object.")
        if not self.value:
            self.list_data_type = value.tag_id
        elif value.tag_id != self.list_data_type:
            raise TypeError(
                f"Invalid type {value.__class__.__name__} for TAG_List({TAG_CLASSES[self.list_data_type].__name__})"
            )

    def __getitem__(self, index: int) -> AnyNBT:
        return self.value[index]

    def __setitem__(self, index, value):
        if isinstance(index, slice):
            map(self._check_tag, value)
        else:
            self._check_tag(value)
        self.value[index] = value

    def __delitem__(self, index: int):
        del self.value[index]

    def __iter__(self) -> Iterator[AnyNBT]:
        return iter(self.value)

    def __contains__(self, item: AnyNBT) -> bool:
        return item in self.value

    def __len__(self) -> int:
        return len(self.value)

    def insert(self, index: int, value: AnyNBT):
        self._check_tag(value)
        self.value.insert(index, value)

    def append(self, value: AnyNBT) -> None:
        self._check_tag(value)
        self.value.append(value)

    cdef void write_value(self, buffer, little_endian) except *:
        cdef char list_type = self.list_data_type

        write_tag_id(list_type, buffer)
        write_int(<int> len(self.value), buffer, little_endian)

        cdef _TAG_Value subtag
        for subtag in self.value:
            if subtag.tag_id != list_type:
                raise ValueError("Asked to save TAG_List with different types! Found %s and %s" % (subtag.tag_id,
                                                                                                   list_type))
            write_tag_value(subtag, buffer, little_endian)

    cpdef str _to_snbt(self):
        cdef _TAG_Value elem
        cdef list tags = []
        for elem in self.value:
            tags.append(elem._to_snbt())
        return f"[{CommaSpace.join(tags)}]"

    cpdef str _pretty_to_snbt(self, indent_chr="", indent_count=0, leading_indent=True):
        cdef _TAG_Value elem
        cdef list tags = []
        for elem in self.value:
            tags.append(elem._pretty_to_snbt(indent_chr, indent_count + 1))
        if tags:
            return f"{indent_chr * indent_count * leading_indent}[\n{CommaNewline.join(tags)}\n{indent_chr * indent_count}]"
        else:
            return f"{indent_chr * indent_count * leading_indent}[]"


class TAG_List(_TAG_List, MutableSequence):
    pass


cdef class _TAG_Compound(_TAG_Value):
    tag_id = _ID_COMPOUND
    cdef public dict value

    def __init__(self, value = None):
        self.value = value or {}
        for key, value in self.value.items():
            self._check_entry(key, value)

    @staticmethod
    def _check_entry(key: str, value: AnyNBT):
        if not isinstance(key, str):
            raise TypeError(
                f"TAG_Compound key must be a string. Got {key.__class__.__name__}"
            )
        if not isinstance(value, _TAG_Value):
            raise TypeError(
                f"Invalid type {value.__class__.__name__} for key \"{key}\" in TAG_Compound. Must be an NBT object."
            )

    cpdef str _to_snbt(self):
        cdef str name
        cdef _TAG_Value elem
        cdef list tags = []
        for name, elem in self.value.items():
            if _NON_QUOTED_KEY.match(name) is None:
                tags.append(f'"{name}": {elem.to_snbt()}')
            else:
                tags.append(f'{name}: {elem.to_snbt()}')
        return f"{{{CommaSpace.join(tags)}}}"

    cpdef str _pretty_to_snbt(self, indent_chr="", indent_count=0, leading_indent=True):
        cdef str name
        cdef _TAG_Value elem
        cdef list tags = []
        for name, elem in self.value.items():
            tags.append(f'{indent_chr * (indent_count + 1)}"{name}": {elem._pretty_to_snbt(indent_chr, indent_count + 1, False)}')
        if tags:
            return f"{indent_chr * indent_count * leading_indent}{{\n{CommaNewline.join(tags)}\n{indent_chr * indent_count}}}"
        else:
            return f"{indent_chr * indent_count * leading_indent}{{}}"

    cdef void write_value(self, buffer, little_endian):
        cdef str key
        cdef _TAG_Value stag

        for key, stag in self.value.items():
            write_tag_id(stag.tag_id, buffer)
            write_tag_name(key, buffer, little_endian)
            stag.write_value(buffer, little_endian)
        write_tag_id(ID_END, buffer)

    def write_payload(self, buffer, name="", little_endian=False):
        write_tag_id(self.tag_id, buffer)
        write_tag_name(name, buffer, little_endian)
        write_tag_value(self, buffer, little_endian)

    def __getitem__(self, key: str) -> AnyNBT:
        return self.value[key]

    def __setitem__(self, key: str, value: AnyNBT):
        self._check_entry(key, value)
        self.value[key] = value

    def __delitem__(self, key: str):
        del self.value[key]

    def __iter__(self) -> Iterator[AnyNBT]:
        yield from self.value

    def __contains__(self, key: str) -> bool:
        return key in self.value

    def __len__(self) -> int:
        return self.value.__len__()


class TAG_Compound(_TAG_Compound, MutableMapping):
    pass


class NBTFile:
    __annotations__ = {'value': 'TAG_Compound', 'name': 'str'}

    def __init__(self, value=None, str name=""):
        self.value = TAG_Compound() if value is None else value
        self.name = name

    def to_snbt(self, indent_chr=None) -> str:
        return self.value.to_snbt(indent_chr)

    def save_to(self, filepath_or_buffer=None, compressed=True, little_endian=False) -> Optional[bytes]:
        buffer = BytesIO()
        self.value.write_payload(buffer, self.name, little_endian)
        data = buffer.getvalue()

        if compressed:
            gzip_buffer = BytesIO()
            with gzip.GzipFile(fileobj=gzip_buffer, mode='wb') as gz:
                gz.write(data)
            data = gzip_buffer.getvalue()

        if not filepath_or_buffer:
            return data

        if isinstance(filepath_or_buffer, str):
            with open(filepath_or_buffer, 'wb') as fp:
                fp.write(data)
        else:
            filepath_or_buffer.write(data)

    def __eq__(self, other):
        return isinstance(other, NBTFile) and self.value.__eq__(other.value) and self.name == other.name

    def __len__(self) -> int:
        return self.value.__len__()

    def keys(self):
        return self.value.keys()

    def values(self):
        self.value.values()

    def items(self):
        return self.value.items()

    def __getitem__(self, key: str) -> AnyNBT:
        return self.value[key]

    def __setitem__(self, key: str, tag: AnyNBT):
        self.value[key] = tag

    def __delitem__(self, key: str):
        del self.value[key]

    def __contains__(self, key: str) -> bool:
        return key in self.value

    def __repr__(self):
        return f'NBTFile("{self.name}":{self.to_snbt()})'

    def pop(self, k, default=None) -> AnyNBT:
        return self.value.pop(k, default)

    def get(self, k, default=None) -> AnyNBT:
        return self.value.get(k, default)


def load(
    filepath_or_buffer: Union[str, bytes, memoryview, BinaryIO, None] = None,  # TODO: This should become a required input
    compressed=True,
    count: int = None,
    offset: bool = False,
    little_endian: bool = False,
    buffer=None,  # TODO: this should get depreciated and removed.
) -> Union[NBTFile, Tuple[Union[NBTFile, List[NBTFile]], int]]:
    if isinstance(filepath_or_buffer, str):
        # if a string load from the file path
        if not os.path.isfile(filepath_or_buffer):
            raise NBTLoadError(f"There is no file at {filepath_or_buffer}")
        with open(filepath_or_buffer, "rb") as f:
            data_in = f.read()
    else:
        # TODO: when buffer is removed, remove this if block and make the next if block an elif part of the parent if block
        if filepath_or_buffer is None:  # For backwards compatability with buffer.
            if buffer is None:
                raise NBTLoadError("No object given to load.")
            filepath_or_buffer = buffer

        if isinstance(filepath_or_buffer, bytes):
            data_in = filepath_or_buffer
        elif isinstance(filepath_or_buffer, memoryview):
            data_in = filepath_or_buffer
        elif hasattr(filepath_or_buffer, "read"):
            data_in = filepath_or_buffer.read()
            if not isinstance(data_in, bytes):
                raise NBTLoadError(f"buffer.read() must return a bytes object. Got {type(data_in)} instead.")
        else:
            raise NBTLoadError("buffer did not have a read method.")

    if compressed:
        data_in = safe_gunzip(data_in)

    cdef buffer_context context = buffer_context()
    context.offset = 0
    context.buffer = data_in
    context.size = len(data_in)

    results = []

    if len(data_in) < 1:
        raise EOFError("load() was supplied an empty buffer")

    for i in range(count or 1):
        tag_type = context.buffer[context.offset]
        if tag_type != _ID_COMPOUND:
            raise NBTFormatError(f"Expecting tag type {ID_COMPOUND}, got {tag_type} instead")
        context.offset += 1

        name = load_name(context, little_endian)
        tag = load_compound_tag(context, little_endian)

        results.append(NBTFile(tag, name))

    if count is None:
        results = results[0]

    if offset:
        return results, context.offset

    return results

cdef TAG_Byte load_byte(buffer_context context, bint little_endian):
    cdef TAG_Byte tag = TAG_Byte(read_data(context, 1)[0])
    return tag

cdef TAG_Short load_short(buffer_context context, bint little_endian):
    cdef short*pointer = <short*> read_data(context, 2)
    cdef TAG_Short tag = TAG_Short.__new__(TAG_Short)
    tag.value = pointer[0]
    to_little_endian(&tag.value, 2, little_endian)
    return tag

cdef TAG_Int load_int(buffer_context context, bint little_endian):
    cdef int*pointer = <int*> read_data(context, 4)
    cdef TAG_Int tag = TAG_Int.__new__(TAG_Int)
    tag.value = pointer[0]
    to_little_endian(&tag.value, 4, little_endian)
    return tag

cdef TAG_Long load_long(buffer_context context, bint little_endian):
    cdef long long *pointer = <long long *> read_data(context, 8)
    cdef TAG_Long tag = TAG_Long.__new__(TAG_Long)
    tag.value = pointer[0]
    to_little_endian(&tag.value, 8, little_endian)
    return tag

cdef TAG_Float load_float(buffer_context context, bint little_endian):
    cdef float*pointer = <float*> read_data(context, 4)
    cdef TAG_Float tag = TAG_Float.__new__(TAG_Float)
    tag.value = pointer[0]
    to_little_endian(&tag.value, 4, little_endian)
    return tag

cdef TAG_Double load_double(buffer_context context, bint little_endian):
    cdef double *pointer = <double *> read_data(context, 8)
    cdef TAG_Double tag = TAG_Double.__new__(TAG_Double)
    tag.value = pointer[0]
    to_little_endian(&tag.value, 8, little_endian)
    return tag

cdef _TAG_Compound load_compound_tag(buffer_context context, bint little_endian):
    cdef char tagID
    #cdef str name
    cdef _TAG_Compound root_tag = TAG_Compound()
    #cdef _TAG_Value tag
    cdef tuple tup

    while True:
        tagID = read_data(context, 1)[0]
        if tagID == _ID_END:
            break
        else:
            tup = load_named(context, tagID, little_endian)
            root_tag[tup[0]] = tup[1]
    return root_tag

cdef bytes load_string(buffer_context context, bint little_endian):
    cdef unsigned short *pointer = <unsigned short *> read_data(context, 2)
    cdef unsigned short length = pointer[0]
    to_little_endian(&length, 2, little_endian)
    b = read_data(context, length)
    return PyBytes_FromStringAndSize(b, length)

cdef TAG_Byte_Array load_byte_array(buffer_context context, bint little_endian):
    cdef int*pointer = <int *> read_data(context, 4)
    cdef int length = pointer[0]

    to_little_endian(&length, 4, little_endian)

    byte_length = length
    cdef char*arr = read_data(context, byte_length)
    data_type = TAG_Byte_Array.little_endian_data_type if little_endian else TAG_Byte_Array.big_endian_data_type
    return TAG_Byte_Array(numpy.frombuffer(arr[:byte_length], dtype=data_type, count=length))

cdef TAG_Int_Array load_int_array(buffer_context context, bint little_endian):
    cdef int*pointer = <int*> read_data(context, 4)
    cdef int length = pointer[0]
    to_little_endian(&length, 4, little_endian)

    byte_length = length * 4
    cdef char*arr = read_data(context, byte_length)
    cdef object data_type = TAG_Int_Array.little_endian_data_type if little_endian else TAG_Int_Array.big_endian_data_type
    return TAG_Int_Array(numpy.frombuffer(arr[:byte_length], dtype=data_type, count=length))

cdef TAG_Long_Array load_long_array(buffer_context context, bint little_endian):
    cdef int*pointer = <int*> read_data(context, 4)
    cdef int length = pointer[0]
    to_little_endian(&length, 4, little_endian)

    byte_length = length * 8
    cdef char*arr = read_data(context, byte_length)
    cdef object data_type = TAG_Long_Array.little_endian_data_type if little_endian else TAG_Long_Array.big_endian_data_type
    return TAG_Long_Array(numpy.frombuffer(arr[:byte_length], dtype=data_type, count=length))

cdef _TAG_List load_list(buffer_context context, bint little_endian):
    cdef char list_type = read_data(context, 1)[0]
    cdef int*pointer = <int*> read_data(context, 4)
    cdef int length = pointer[0]
    to_little_endian(&length, 4, little_endian)

    cdef _TAG_List tag = TAG_List(list_data_type=list_type)
    cdef list val = tag.value
    cdef int i
    for i in range(length):
        PyList_Append(val, load_tag(list_type, context, little_endian))

    return tag

cdef inline void cwrite(object obj, char*buf, size_t length):
    obj.write(buf[:length])

cdef write_tag_id(char tag_id, object buffer):
    cwrite(buffer, &tag_id, 1)

cdef void write_tag_name(str name, object buffer, bint little_endian):
    write_string(name.encode("utf-8"), buffer, little_endian)

cdef void write_string(bytes value, object buffer, bint little_endian):
    cdef short length = <short> len(value)
    cdef char*s = value
    to_little_endian(&length, 2, little_endian)
    cwrite(buffer, <char*> &length, 2)
    cwrite(buffer, s, len(value))

cdef void write_array(object value, object buffer, char size, bint little_endian):
    value = value.tobytes()
    cdef char*s = value
    cdef int length = <int> len(value) // size
    to_little_endian(&length, 4, little_endian)
    cwrite(buffer, <char*> &length, 4)
    cwrite(buffer, s, len(value))

cdef void write_byte(char value, object buffer):
    cwrite(buffer, <char*> &value, 1)

cdef void write_short(short value, object buffer, bint little_endian):
    to_little_endian(&value, 2, little_endian)
    cwrite(buffer, <char*> &value, 2)

cdef void write_int(int value, object buffer, bint little_endian):
    to_little_endian(&value, 4, little_endian)
    cwrite(buffer, <char*> &value, 4)

cdef void write_long(long long value, object buffer, bint little_endian):
    to_little_endian(&value, 8, little_endian)
    cwrite(buffer, <char*> &value, 8)

cdef void write_float(float value, object buffer, bint little_endian):
    to_little_endian(&value, 4, little_endian)
    cwrite(buffer, <char*> &value, 4)

cdef void write_double(double value, object buffer, bint little_endian):
    to_little_endian(&value, 8, little_endian)
    cwrite(buffer, <char*> &value, 8)

cdef void write_tag_value(_TAG_Value tag, object buf, bint little_endian):
    cdef char tagID = tag.tag_id
    if tagID == _ID_BYTE:
        (<TAG_Byte> tag).write_value(buf, little_endian)

    if tagID == _ID_SHORT:
        (<TAG_Short> tag).write_value(buf, little_endian)

    if tagID == _ID_INT:
        (<TAG_Int> tag).write_value(buf, little_endian)

    if tagID == _ID_LONG:
        (<TAG_Long> tag).write_value(buf, little_endian)

    if tagID == _ID_FLOAT:
        (<TAG_Float> tag).write_value(buf, little_endian)

    if tagID == _ID_DOUBLE:
        (<TAG_Double> tag).write_value(buf, little_endian)

    if tagID == _ID_BYTE_ARRAY:
        (<TAG_Byte_Array> tag).write_value(buf, little_endian)

    if tagID == _ID_STRING:
        (<TAG_String> tag).write_value(buf, little_endian)

    if tagID == _ID_LIST:
        (<_TAG_List> tag).write_value(buf, little_endian)

    if tagID == _ID_COMPOUND:
        (<_TAG_Compound> tag).write_value(buf, little_endian)

    if tagID == _ID_INT_ARRAY:
        (<TAG_Int_Array> tag).write_value(buf, little_endian)

    if tagID == _ID_LONG_ARRAY:
        (<TAG_Long_Array> tag).write_value(buf, little_endian)

def unpickle_nbt(tag_id, tag_value):
    if tag_id == _ID_COMPOUND:
        return TAG_Compound(tag_value)
    elif tag_id == _ID_LIST:
        return TAG_List(tag_value)
    return TAG_CLASSES[tag_id](tag_value)


whitespace = re.compile('[ \t\r\n]*')
int_numeric = re.compile('-?[0-9]+[bBsSlL]?')
float_numeric = re.compile('-?[0-9]+\.?[0-9]*[fFdD]?')
alnumplus = re.compile('[-.a-zA-Z0-9_]*')
comma = re.compile('[ \t\r\n]*,[ \t\r\n]*')
colon = re.compile('[ \t\r\n]*:[ \t\r\n]*')
array_lookup = {'B': TAG_Byte_Array, 'I': TAG_Int_Array, 'L': TAG_Long_Array}

cdef int _strip_whitespace(str snbt, int index):
    cdef object match

    match = whitespace.match(snbt, index)
    if match is None:
        return index
    else:
        return match.end()

cdef int _strip_comma(str snbt, int index, str end_chr) except -1:
    cdef object match

    match = comma.match(snbt, index)
    if match is None:
        index = _strip_whitespace(snbt, index)
        if snbt[index] != end_chr:
            raise SNBTParseError(f'Expected a comma or {end_chr} at {index} but got ->{snbt[index:index + 10]} instead')
    else:
        index = match.end()
    return index

cdef int _strip_colon(str snbt, int index) except -1:
    cdef object match

    match = colon.match(snbt, index)
    if match is None:
        raise SNBTParseError(f'Expected : at {index} but got ->{snbt[index:index + 10]} instead')
    else:
        return match.end()

cdef tuple _capture_string(str snbt, int index):
    cdef str val, quote
    cdef bint strict_str
    cdef int end_index
    cdef object match

    if snbt[index] in ('"', "'"):
        quote = snbt[index]
        strict_str = True
        index += 1
        end_index = index
        while not (snbt[end_index] == quote and not (len(snbt[:end_index]) - len(snbt[:end_index].rstrip('\\')))):
            end_index += 1
        val = unescape(snbt[index:end_index])
        index = end_index + 1
    else:
        strict_str = False
        match = alnumplus.match(snbt, index)
        val = match.group()
        index = match.end()

    return val, strict_str, index

cdef tuple _parse_snbt_recursive(str snbt, int index=0):
    cdef dict data_
    cdef list array
    cdef str array_type_chr
    cdef object array_type, first_data_type, int_match, float_match
    cdef _TAG_Value nested_data, data
    cdef str val
    cdef bint strict_str

    index = _strip_whitespace(snbt, index)
    if snbt[index] == '{':
        data_ = {}
        index += 1
        index = _strip_whitespace(snbt, index)
        while snbt[index] != '}':
            # read the key
            key, _, index = _capture_string(snbt, index)

            # get around the colon
            index = _strip_colon(snbt, index)

            # load the data and save it to the dictionary
            nested_data, index = _parse_snbt_recursive(snbt, index)
            data_[key] = nested_data

            index = _strip_comma(snbt, index, '}')
        data = TAG_Compound(data_)
        # skip the }
        index += 1

    elif snbt[index] == '[':
        index += 1
        index = _strip_whitespace(snbt, index)
        if snbt[index:index + 2] in {'B;', 'I;', 'L;'}:
            # array
            array = []
            array_type_chr = snbt[index]
            array_type = array_lookup[array_type_chr]
            index += 2
            index = _strip_whitespace(snbt, index)

            while snbt[index] != ']':
                match = int_numeric.match(snbt, index)
                if match is None:
                    raise SNBTParseError(
                        f'Expected an integer value or ] at {index} but got ->{snbt[index:index + 10]} instead')
                else:
                    val = match.group()
                    if val[-1].isalpha():
                        if val[-1] == array_type_chr:
                            val = val[:-1]
                        else:
                            raise SNBTParseError(
                                f'Expected the datatype marker "{array_type_chr}" at {index} but got ->{snbt[index:index + 10]} instead')
                    array.append(int(val))
                    index = match.end()

                index = _strip_comma(snbt, index, ']')
            data = array_type(numpy.asarray(array, dtype=array_type.big_endian_data_type))
        else:
            # list
            array = []
            first_data_type = None
            while snbt[index] != ']':
                nested_data, index_ = _parse_snbt_recursive(snbt, index)
                if first_data_type is None:
                    first_data_type = nested_data.__class__
                if not isinstance(nested_data, first_data_type):
                    raise SNBTParseError(
                        f'Expected type {first_data_type.__name__} but got {nested_data.__class__.__name__} at {index}')
                else:
                    index = index_
                array.append(nested_data)
                index = _strip_comma(snbt, index, ']')

            if first_data_type is None:
                data = TAG_List()
            else:
                data = TAG_List(array, first_data_type().tag_id)

        # skip the ]
        index += 1

    else:
        val, strict_str, index = _capture_string(snbt, index)
        if strict_str:
            data = TAG_String(val)
        else:
            int_match = int_numeric.match(val)
            if int_match is not None and int_match.end() == len(val):
                # we have an int type
                if val[-1] in {'b', 'B'}:
                    data = TAG_Byte(int(val[:-1]))
                elif val[-1] in {'s', 'S'}:
                    data = TAG_Short(int(val[:-1]))
                elif val[-1] in {'l', 'L'}:
                    data = TAG_Long(int(val[:-1]))
                else:
                    data = TAG_Int(int(val))
            else:
                float_match = float_numeric.match(val)
                if float_match is not None and float_match.end() == len(val):
                    # we have a float type
                    if val[-1] in {'f', 'F'}:
                        data = TAG_Float(float(val[:-1]))
                    elif val[-1] in {'d', 'D'}:
                        data = TAG_Double(float(val[:-1]))
                    else:
                        data = TAG_Double(float(val))
                else:
                    # we just have a string type
                    data = TAG_String(val)

    return data, index

def from_snbt(snbt: str) -> AnyNBT:
    try:
        return _parse_snbt_recursive(snbt)[0]
    except SNBTParseError as e:
        raise SNBTParseError(e)
    except IndexError:
        raise SNBTParseError('SNBT string is incomplete. Reached the end of the string.')
