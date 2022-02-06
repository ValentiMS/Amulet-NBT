from typing import Union, Iterable, SupportsBytes, List
from io import BytesIO
from copy import deepcopy
from math import floor, ceil
import sys

from .numeric cimport BaseNumericTag
from .const cimport ID_BYTE, ID_SHORT, ID_INT, ID_LONG
from .util cimport (
    write_byte,
    write_short,
    write_int,
    write_long,
    BufferContext,
    read_data,
    to_little_endian,
    read_byte,
)


cdef class BaseIntTag(BaseNumericTag):
    @classmethod
    def from_bytes(
        cls,
        bytes: Union[Iterable[int], SupportsBytes],
        byteorder: str,
        *,
        bint signed = False
    ) -> BaseIntTag:
        raise NotImplementedError

    def __and__(BaseIntTag self, other):
        raise NotImplementedError

    def __rand__(BaseIntTag self, other):
        raise NotImplementedError

    def __iand__(BaseIntTag self, other):
        raise NotImplementedError

    def __xor__(BaseIntTag self, other):
        raise NotImplementedError

    def __rxor__(BaseIntTag self, other):
        raise NotImplementedError

    def __ixor__(BaseIntTag self, other):
        raise NotImplementedError

    def __or__(BaseIntTag self, other):
        raise NotImplementedError

    def __ror__(BaseIntTag self, other):
        raise NotImplementedError

    def __ior__(BaseIntTag self, other):
        raise NotImplementedError

    def __lshift__(BaseIntTag self, other):
        raise NotImplementedError

    def __rlshift__(BaseIntTag self, other):
        raise NotImplementedError

    def __ilshift__(BaseIntTag self, other):
        raise NotImplementedError

    def __rshift__(BaseIntTag self, other):
        raise NotImplementedError

    def __rrshift__(BaseIntTag self, other):
        raise NotImplementedError

    def __irshift__(BaseIntTag self, other):
        raise NotImplementedError

    def __invert__(BaseIntTag self):
        raise NotImplementedError

    def __index__(self) -> int:
        raise NotImplementedError


cdef class ByteTag(BaseIntTag):
    """
    A class that behaves like an int but is stored in 1 byte.
    Can Store numbers between -(2^7) and (2^7 - 1)
    """
    tag_id = ID_BYTE

    def __init__(ByteTag self, value = 0):
        self.value_ = self._sanitise_value(int(value))

    def bit_length(self):
        return self.value_.bit_length()
    bit_length.__doc__ = int.bit_length.__doc__
    
    @property
    def denominator(self):
        """the denominator of a rational number in lowest terms"""
        return self.value_.denominator
    
    @property
    def imag(self):
        """the imaginary part of a complex number"""
        return self.value_.imag
    
    @property
    def numerator(self):
        """the numerator of a rational number in lowest terms"""
        return self.value_.numerator
    
    @property
    def real(self):
        """the real part of a complex number"""
        return self.value_.real
    
    def to_bytes(self, length, byteorder, *, object signed=False):
        return self.value_.to_bytes(length, byteorder, signed=signed)
    to_bytes.__doc__ = int.to_bytes.__doc__
    
    if sys.version_info >= (3, 8):
        def as_integer_ratio(self):
            return self.value_.as_integer_ratio()
        as_integer_ratio.__doc__ = int.as_integer_ratio.__doc__

    def conjugate(self):
        return self.value_.conjugate()
    conjugate.__doc__ = int.conjugate.__doc__

    def __str__(ByteTag self):
        return str(self.value_)

    def __dir__(ByteTag self):
        return list(set(list(super().__dir__()) + dir(self.value_)))

    def __eq__(ByteTag self, other):
        return self.value_ == other

    def __ge__(ByteTag self, other):
        return self.value_ >= other

    def __gt__(ByteTag self, other):
        return self.value_ > other

    def __le__(ByteTag self, other):
        return self.value_ <= other

    def __lt__(ByteTag self, other):
        return self.value_ < other

    def __reduce__(ByteTag self):
        return self.__class__, (self.value_,)

    def __deepcopy__(ByteTag self, memo=None):
        return self.__class__(deepcopy(self.value_, memo=memo))

    def __copy__(ByteTag self):
        return self.__class__(self.value_)

    def __hash__(ByteTag self):
        return hash((self.tag_id, self.value_))

    @property
    def value(ByteTag self):
        """
        A copy of the data stored in the class.
        Use the public API to modify the data within the class.
        """
        return self.value_

    def __repr__(ByteTag self):
        return f"{self.__class__.__name__}({self.value_})"

    def __add__(ByteTag self, other):
        return self.value_ + other

    def __radd__(ByteTag self, other):
        return other + self.value_

    def __iadd__(ByteTag self, other):
        res = self + other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __sub__(ByteTag self, other):
        return self.value_ - other

    def __rsub__(ByteTag self, other):
        return other - self.value_

    def __isub__(ByteTag self, other):
        res = self - other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __mul__(ByteTag self, other):
        return self.value_ * other

    def __rmul__(ByteTag self, other):
        return other * self.value_

    def __imul__(ByteTag self, other):
        res = self * other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __truediv__(ByteTag self, other):
        return self.value_ / other

    def __rtruediv__(ByteTag self, other):
        return other / self.value_

    def __itruediv__(ByteTag self, other):
        res = self / other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __floordiv__(ByteTag self, other):
        return self.value_ // other

    def __rfloordiv__(ByteTag self, other):
        return other // self.value_

    def __ifloordiv__(ByteTag self, other):
        res = self // other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __mod__(ByteTag self, other):
        return self.value_ % other

    def __rmod__(ByteTag self, other):
        return other % self.value_

    def __imod__(ByteTag self, other):
        res = self % other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __divmod__(ByteTag self, other):
        return divmod(self.value_, other)

    def __rdivmod__(ByteTag self, other):
        return divmod(other, self.value_)

    def __pow__(ByteTag self, power, modulo):
        return pow(self.value_, power, modulo)

    def __rpow__(ByteTag self, other, modulo):
        return pow(other, self.value_, modulo)

    def __ipow__(ByteTag self, other):
        res = pow(self, other)
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __neg__(ByteTag self):
        return self.value_.__neg__()

    def __pos__(ByteTag self):
        return self.value_.__pos__()

    def __abs__(ByteTag self):
        return self.value_.__abs__()

    def __int__(ByteTag self):
        return self.value_.__int__()

    def __float__(ByteTag self):
        return self.value_.__float__()

    def __round__(ByteTag self, n=None):
        return round(self.value_, n)

    def __trunc__(ByteTag self):
        return self.value_.__trunc__()

    def __floor__(ByteTag self):
        return floor(self.value_)

    def __ceil__(ByteTag self):
        return ceil(self.value_)

    def __bool__(ByteTag self):
        return self.value_.__bool__()

    @classmethod
    def from_bytes(
        cls,
        bytes: Union[Iterable[int], SupportsBytes],
        byteorder: str,
        *,
        bint signed = False
    ) -> ByteTag:
        return ByteTag(int.from_bytes(bytes, byteorder, signed))

    def __and__(ByteTag self, other):
        return self.value_ & other

    def __rand__(ByteTag self, other):
        return other & self.value_

    def __iand__(ByteTag self, other):
        res = self & other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __xor__(ByteTag self, other):
        return self.value_ ^ other

    def __rxor__(ByteTag self, other):
        return other ^ self.value_

    def __ixor__(ByteTag self, other):
        res = self ^ other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __or__(ByteTag self, other):
        return self.value_ | other

    def __ror__(ByteTag self, other):
        return other | self.value_

    def __ior__(ByteTag self, other):
        res = self | other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __lshift__(ByteTag self, other):
        return self.value_ << other

    def __rlshift__(ByteTag self, other):
        return other << self.value_

    def __ilshift__(ByteTag self, other):
        res = self << other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __rshift__(ByteTag self, other):
        return self.value_ >> other

    def __rrshift__(ByteTag self, other):
        return other >> self.value_

    def __irshift__(ByteTag self, other):
        res = self >> other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __invert__(ByteTag self):
        return self.value_.__invert__()

    def __index__(ByteTag self) -> int:
        return self.value_.__index__()

    cdef char _sanitise_value(ByteTag self, value):
        return (value & 0x7F) - (value & 0x80)

    cdef str _to_snbt(ByteTag self):
        return f"{self.value_}b"

    cdef void write_payload(ByteTag self, object buffer: BytesIO, bint little_endian) except *:
        write_byte(self.value_, buffer)

    @staticmethod
    cdef ByteTag read_payload(BufferContext buffer, bint little_endian):
        return ByteTag(read_byte(buffer))


cdef class ShortTag(BaseIntTag):
    """
    A class that behaves like an int but is stored in 2 bytes.
    Can Store numbers between -(2^15) and (2^15 - 1)
    """
    tag_id = ID_SHORT

    def __init__(ShortTag self, value = 0):
        self.value_ = self._sanitise_value(int(value))

    def bit_length(self):
        return self.value_.bit_length()
    bit_length.__doc__ = int.bit_length.__doc__
    
    @property
    def denominator(self):
        """the denominator of a rational number in lowest terms"""
        return self.value_.denominator
    
    @property
    def imag(self):
        """the imaginary part of a complex number"""
        return self.value_.imag
    
    @property
    def numerator(self):
        """the numerator of a rational number in lowest terms"""
        return self.value_.numerator
    
    @property
    def real(self):
        """the real part of a complex number"""
        return self.value_.real
    
    def to_bytes(self, length, byteorder, *, object signed=False):
        return self.value_.to_bytes(length, byteorder, signed=signed)
    to_bytes.__doc__ = int.to_bytes.__doc__
    
    if sys.version_info >= (3, 8):
        def as_integer_ratio(self):
            return self.value_.as_integer_ratio()
        as_integer_ratio.__doc__ = int.as_integer_ratio.__doc__

    def conjugate(self):
        return self.value_.conjugate()
    conjugate.__doc__ = int.conjugate.__doc__

    def __str__(ShortTag self):
        return str(self.value_)

    def __dir__(ShortTag self):
        return list(set(list(super().__dir__()) + dir(self.value_)))

    def __eq__(ShortTag self, other):
        return self.value_ == other

    def __ge__(ShortTag self, other):
        return self.value_ >= other

    def __gt__(ShortTag self, other):
        return self.value_ > other

    def __le__(ShortTag self, other):
        return self.value_ <= other

    def __lt__(ShortTag self, other):
        return self.value_ < other

    def __reduce__(ShortTag self):
        return self.__class__, (self.value_,)

    def __deepcopy__(ShortTag self, memo=None):
        return self.__class__(deepcopy(self.value_, memo=memo))

    def __copy__(ShortTag self):
        return self.__class__(self.value_)

    def __hash__(ShortTag self):
        return hash((self.tag_id, self.value_))

    @property
    def value(ShortTag self):
        """
        A copy of the data stored in the class.
        Use the public API to modify the data within the class.
        """
        return self.value_

    def __repr__(ShortTag self):
        return f"{self.__class__.__name__}({self.value_})"

    def __add__(ShortTag self, other):
        return self.value_ + other

    def __radd__(ShortTag self, other):
        return other + self.value_

    def __iadd__(ShortTag self, other):
        res = self + other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __sub__(ShortTag self, other):
        return self.value_ - other

    def __rsub__(ShortTag self, other):
        return other - self.value_

    def __isub__(ShortTag self, other):
        res = self - other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __mul__(ShortTag self, other):
        return self.value_ * other

    def __rmul__(ShortTag self, other):
        return other * self.value_

    def __imul__(ShortTag self, other):
        res = self * other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __truediv__(ShortTag self, other):
        return self.value_ / other

    def __rtruediv__(ShortTag self, other):
        return other / self.value_

    def __itruediv__(ShortTag self, other):
        res = self / other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __floordiv__(ShortTag self, other):
        return self.value_ // other

    def __rfloordiv__(ShortTag self, other):
        return other // self.value_

    def __ifloordiv__(ShortTag self, other):
        res = self // other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __mod__(ShortTag self, other):
        return self.value_ % other

    def __rmod__(ShortTag self, other):
        return other % self.value_

    def __imod__(ShortTag self, other):
        res = self % other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __divmod__(ShortTag self, other):
        return divmod(self.value_, other)

    def __rdivmod__(ShortTag self, other):
        return divmod(other, self.value_)

    def __pow__(ShortTag self, power, modulo):
        return pow(self.value_, power, modulo)

    def __rpow__(ShortTag self, other, modulo):
        return pow(other, self.value_, modulo)

    def __ipow__(ShortTag self, other):
        res = pow(self, other)
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __neg__(ShortTag self):
        return self.value_.__neg__()

    def __pos__(ShortTag self):
        return self.value_.__pos__()

    def __abs__(ShortTag self):
        return self.value_.__abs__()

    def __int__(ShortTag self):
        return self.value_.__int__()

    def __float__(ShortTag self):
        return self.value_.__float__()

    def __round__(ShortTag self, n=None):
        return round(self.value_, n)

    def __trunc__(ShortTag self):
        return self.value_.__trunc__()

    def __floor__(ShortTag self):
        return floor(self.value_)

    def __ceil__(ShortTag self):
        return ceil(self.value_)

    def __bool__(ShortTag self):
        return self.value_.__bool__()

    @classmethod
    def from_bytes(
        cls,
        bytes: Union[Iterable[int], SupportsBytes],
        byteorder: str,
        *,
        bint signed = False
    ) -> ShortTag:
        return ShortTag(int.from_bytes(bytes, byteorder, signed))

    def __and__(ShortTag self, other):
        return self.value_ & other

    def __rand__(ShortTag self, other):
        return other & self.value_

    def __iand__(ShortTag self, other):
        res = self & other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __xor__(ShortTag self, other):
        return self.value_ ^ other

    def __rxor__(ShortTag self, other):
        return other ^ self.value_

    def __ixor__(ShortTag self, other):
        res = self ^ other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __or__(ShortTag self, other):
        return self.value_ | other

    def __ror__(ShortTag self, other):
        return other | self.value_

    def __ior__(ShortTag self, other):
        res = self | other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __lshift__(ShortTag self, other):
        return self.value_ << other

    def __rlshift__(ShortTag self, other):
        return other << self.value_

    def __ilshift__(ShortTag self, other):
        res = self << other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __rshift__(ShortTag self, other):
        return self.value_ >> other

    def __rrshift__(ShortTag self, other):
        return other >> self.value_

    def __irshift__(ShortTag self, other):
        res = self >> other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __invert__(ShortTag self):
        return self.value_.__invert__()

    def __index__(ShortTag self) -> int:
        return self.value_.__index__()

    cdef short _sanitise_value(ShortTag self, value):
        return (value & 0x7FFF) - (value & 0x8000)

    cdef str _to_snbt(ShortTag self):
        return f"{self.value_}s"

    cdef void write_payload(ShortTag self, object buffer: BytesIO, bint little_endian) except *:
        write_short(self.value_, buffer, little_endian)

    @staticmethod
    cdef ShortTag read_payload(BufferContext buffer, bint little_endian):
        cdef short *pointer = <short*> read_data(buffer, 2)
        cdef ShortTag tag = ShortTag.__new__(ShortTag)
        tag.value_ = pointer[0]
        to_little_endian(&tag.value_, 2, little_endian)
        return tag


cdef class IntTag(BaseIntTag):
    """
    A class that behaves like an int but is stored in 4 bytes.
    Can Store numbers between -(2^31) and (2^31 - 1)
    """
    tag_id = ID_INT

    def __init__(IntTag self, value = 0):
        self.value_ = self._sanitise_value(int(value))

    def bit_length(self):
        return self.value_.bit_length()
    bit_length.__doc__ = int.bit_length.__doc__
    
    @property
    def denominator(self):
        """the denominator of a rational number in lowest terms"""
        return self.value_.denominator
    
    @property
    def imag(self):
        """the imaginary part of a complex number"""
        return self.value_.imag
    
    @property
    def numerator(self):
        """the numerator of a rational number in lowest terms"""
        return self.value_.numerator
    
    @property
    def real(self):
        """the real part of a complex number"""
        return self.value_.real
    
    def to_bytes(self, length, byteorder, *, object signed=False):
        return self.value_.to_bytes(length, byteorder, signed=signed)
    to_bytes.__doc__ = int.to_bytes.__doc__
    
    if sys.version_info >= (3, 8):
        def as_integer_ratio(self):
            return self.value_.as_integer_ratio()
        as_integer_ratio.__doc__ = int.as_integer_ratio.__doc__

    def conjugate(self):
        return self.value_.conjugate()
    conjugate.__doc__ = int.conjugate.__doc__

    def __str__(IntTag self):
        return str(self.value_)

    def __dir__(IntTag self):
        return list(set(list(super().__dir__()) + dir(self.value_)))

    def __eq__(IntTag self, other):
        return self.value_ == other

    def __ge__(IntTag self, other):
        return self.value_ >= other

    def __gt__(IntTag self, other):
        return self.value_ > other

    def __le__(IntTag self, other):
        return self.value_ <= other

    def __lt__(IntTag self, other):
        return self.value_ < other

    def __reduce__(IntTag self):
        return self.__class__, (self.value_,)

    def __deepcopy__(IntTag self, memo=None):
        return self.__class__(deepcopy(self.value_, memo=memo))

    def __copy__(IntTag self):
        return self.__class__(self.value_)

    def __hash__(IntTag self):
        return hash((self.tag_id, self.value_))

    @property
    def value(IntTag self):
        """
        A copy of the data stored in the class.
        Use the public API to modify the data within the class.
        """
        return self.value_

    def __repr__(IntTag self):
        return f"{self.__class__.__name__}({self.value_})"

    def __add__(IntTag self, other):
        return self.value_ + other

    def __radd__(IntTag self, other):
        return other + self.value_

    def __iadd__(IntTag self, other):
        res = self + other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __sub__(IntTag self, other):
        return self.value_ - other

    def __rsub__(IntTag self, other):
        return other - self.value_

    def __isub__(IntTag self, other):
        res = self - other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __mul__(IntTag self, other):
        return self.value_ * other

    def __rmul__(IntTag self, other):
        return other * self.value_

    def __imul__(IntTag self, other):
        res = self * other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __truediv__(IntTag self, other):
        return self.value_ / other

    def __rtruediv__(IntTag self, other):
        return other / self.value_

    def __itruediv__(IntTag self, other):
        res = self / other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __floordiv__(IntTag self, other):
        return self.value_ // other

    def __rfloordiv__(IntTag self, other):
        return other // self.value_

    def __ifloordiv__(IntTag self, other):
        res = self // other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __mod__(IntTag self, other):
        return self.value_ % other

    def __rmod__(IntTag self, other):
        return other % self.value_

    def __imod__(IntTag self, other):
        res = self % other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __divmod__(IntTag self, other):
        return divmod(self.value_, other)

    def __rdivmod__(IntTag self, other):
        return divmod(other, self.value_)

    def __pow__(IntTag self, power, modulo):
        return pow(self.value_, power, modulo)

    def __rpow__(IntTag self, other, modulo):
        return pow(other, self.value_, modulo)

    def __ipow__(IntTag self, other):
        res = pow(self, other)
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __neg__(IntTag self):
        return self.value_.__neg__()

    def __pos__(IntTag self):
        return self.value_.__pos__()

    def __abs__(IntTag self):
        return self.value_.__abs__()

    def __int__(IntTag self):
        return self.value_.__int__()

    def __float__(IntTag self):
        return self.value_.__float__()

    def __round__(IntTag self, n=None):
        return round(self.value_, n)

    def __trunc__(IntTag self):
        return self.value_.__trunc__()

    def __floor__(IntTag self):
        return floor(self.value_)

    def __ceil__(IntTag self):
        return ceil(self.value_)

    def __bool__(IntTag self):
        return self.value_.__bool__()

    @classmethod
    def from_bytes(
        cls,
        bytes: Union[Iterable[int], SupportsBytes],
        byteorder: str,
        *,
        bint signed = False
    ) -> IntTag:
        return IntTag(int.from_bytes(bytes, byteorder, signed))

    def __and__(IntTag self, other):
        return self.value_ & other

    def __rand__(IntTag self, other):
        return other & self.value_

    def __iand__(IntTag self, other):
        res = self & other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __xor__(IntTag self, other):
        return self.value_ ^ other

    def __rxor__(IntTag self, other):
        return other ^ self.value_

    def __ixor__(IntTag self, other):
        res = self ^ other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __or__(IntTag self, other):
        return self.value_ | other

    def __ror__(IntTag self, other):
        return other | self.value_

    def __ior__(IntTag self, other):
        res = self | other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __lshift__(IntTag self, other):
        return self.value_ << other

    def __rlshift__(IntTag self, other):
        return other << self.value_

    def __ilshift__(IntTag self, other):
        res = self << other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __rshift__(IntTag self, other):
        return self.value_ >> other

    def __rrshift__(IntTag self, other):
        return other >> self.value_

    def __irshift__(IntTag self, other):
        res = self >> other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __invert__(IntTag self):
        return self.value_.__invert__()

    def __index__(IntTag self) -> int:
        return self.value_.__index__()

    cdef int _sanitise_value(IntTag self, value):
        return (value & 0x7FFF_FFFF) - (value & 0x8000_0000)

    cdef str _to_snbt(IntTag self):
        return f"{self.value_}"

    cdef void write_payload(IntTag self, object buffer: BytesIO, bint little_endian) except *:
        write_int(self.value_, buffer, little_endian)

    @staticmethod
    cdef IntTag read_payload(BufferContext buffer, bint little_endian):
        cdef int*pointer = <int*> read_data(buffer, 4)
        cdef IntTag tag = IntTag.__new__(IntTag)
        tag.value_ = pointer[0]
        to_little_endian(&tag.value_, 4, little_endian)
        return tag


cdef class LongTag(BaseIntTag):
    """
    A class that behaves like an int but is stored in 8 bytes.
    Can Store numbers between -(2^63) and (2^63 - 1)
    """
    tag_id = ID_LONG

    def __init__(LongTag self, value = 0):
        self.value_ = self._sanitise_value(int(value))

    def bit_length(self):
        return self.value_.bit_length()
    bit_length.__doc__ = int.bit_length.__doc__
    
    @property
    def denominator(self):
        """the denominator of a rational number in lowest terms"""
        return self.value_.denominator
    
    @property
    def imag(self):
        """the imaginary part of a complex number"""
        return self.value_.imag
    
    @property
    def numerator(self):
        """the numerator of a rational number in lowest terms"""
        return self.value_.numerator
    
    @property
    def real(self):
        """the real part of a complex number"""
        return self.value_.real
    
    def to_bytes(self, length, byteorder, *, object signed=False):
        return self.value_.to_bytes(length, byteorder, signed=signed)
    to_bytes.__doc__ = int.to_bytes.__doc__
    
    if sys.version_info >= (3, 8):
        def as_integer_ratio(self):
            return self.value_.as_integer_ratio()
        as_integer_ratio.__doc__ = int.as_integer_ratio.__doc__

    def conjugate(self):
        return self.value_.conjugate()
    conjugate.__doc__ = int.conjugate.__doc__

    def __str__(LongTag self):
        return str(self.value_)

    def __dir__(LongTag self):
        return list(set(list(super().__dir__()) + dir(self.value_)))

    def __eq__(LongTag self, other):
        return self.value_ == other

    def __ge__(LongTag self, other):
        return self.value_ >= other

    def __gt__(LongTag self, other):
        return self.value_ > other

    def __le__(LongTag self, other):
        return self.value_ <= other

    def __lt__(LongTag self, other):
        return self.value_ < other

    def __reduce__(LongTag self):
        return self.__class__, (self.value_,)

    def __deepcopy__(LongTag self, memo=None):
        return self.__class__(deepcopy(self.value_, memo=memo))

    def __copy__(LongTag self):
        return self.__class__(self.value_)

    def __hash__(LongTag self):
        return hash((self.tag_id, self.value_))

    @property
    def value(LongTag self):
        """
        A copy of the data stored in the class.
        Use the public API to modify the data within the class.
        """
        return self.value_

    def __repr__(LongTag self):
        return f"{self.__class__.__name__}({self.value_})"

    def __add__(LongTag self, other):
        return self.value_ + other

    def __radd__(LongTag self, other):
        return other + self.value_

    def __iadd__(LongTag self, other):
        res = self + other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __sub__(LongTag self, other):
        return self.value_ - other

    def __rsub__(LongTag self, other):
        return other - self.value_

    def __isub__(LongTag self, other):
        res = self - other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __mul__(LongTag self, other):
        return self.value_ * other

    def __rmul__(LongTag self, other):
        return other * self.value_

    def __imul__(LongTag self, other):
        res = self * other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __truediv__(LongTag self, other):
        return self.value_ / other

    def __rtruediv__(LongTag self, other):
        return other / self.value_

    def __itruediv__(LongTag self, other):
        res = self / other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __floordiv__(LongTag self, other):
        return self.value_ // other

    def __rfloordiv__(LongTag self, other):
        return other // self.value_

    def __ifloordiv__(LongTag self, other):
        res = self // other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __mod__(LongTag self, other):
        return self.value_ % other

    def __rmod__(LongTag self, other):
        return other % self.value_

    def __imod__(LongTag self, other):
        res = self % other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __divmod__(LongTag self, other):
        return divmod(self.value_, other)

    def __rdivmod__(LongTag self, other):
        return divmod(other, self.value_)

    def __pow__(LongTag self, power, modulo):
        return pow(self.value_, power, modulo)

    def __rpow__(LongTag self, other, modulo):
        return pow(other, self.value_, modulo)

    def __ipow__(LongTag self, other):
        res = pow(self, other)
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __neg__(LongTag self):
        return self.value_.__neg__()

    def __pos__(LongTag self):
        return self.value_.__pos__()

    def __abs__(LongTag self):
        return self.value_.__abs__()

    def __int__(LongTag self):
        return self.value_.__int__()

    def __float__(LongTag self):
        return self.value_.__float__()

    def __round__(LongTag self, n=None):
        return round(self.value_, n)

    def __trunc__(LongTag self):
        return self.value_.__trunc__()

    def __floor__(LongTag self):
        return floor(self.value_)

    def __ceil__(LongTag self):
        return ceil(self.value_)

    def __bool__(LongTag self):
        return self.value_.__bool__()

    @classmethod
    def from_bytes(
        cls,
        bytes: Union[Iterable[int], SupportsBytes],
        byteorder: str,
        *,
        bint signed = False
    ) -> LongTag:
        return LongTag(int.from_bytes(bytes, byteorder, signed))

    def __and__(LongTag self, other):
        return self.value_ & other

    def __rand__(LongTag self, other):
        return other & self.value_

    def __iand__(LongTag self, other):
        res = self & other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __xor__(LongTag self, other):
        return self.value_ ^ other

    def __rxor__(LongTag self, other):
        return other ^ self.value_

    def __ixor__(LongTag self, other):
        res = self ^ other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __or__(LongTag self, other):
        return self.value_ | other

    def __ror__(LongTag self, other):
        return other | self.value_

    def __ior__(LongTag self, other):
        res = self | other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __lshift__(LongTag self, other):
        return self.value_ << other

    def __rlshift__(LongTag self, other):
        return other << self.value_

    def __ilshift__(LongTag self, other):
        res = self << other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __rshift__(LongTag self, other):
        return self.value_ >> other

    def __rrshift__(LongTag self, other):
        return other >> self.value_

    def __irshift__(LongTag self, other):
        res = self >> other
        if isinstance(res, (int, float)):
            return self.__class__(res)
        return res

    def __invert__(LongTag self):
        return self.value_.__invert__()

    def __index__(LongTag self) -> int:
        return self.value_.__index__()

    cdef long long _sanitise_value(LongTag self, value):
        return (value & 0x7FFF_FFFF_FFFF_FFFF) - (value & 0x8000_0000_0000_0000)

    cdef str _to_snbt(LongTag self):
        return f"{self.value_}L"

    cdef void write_payload(LongTag self, object buffer: BytesIO, bint little_endian) except *:
        write_long(self.value_, buffer, little_endian)

    @staticmethod
    cdef LongTag read_payload(BufferContext buffer, bint little_endian):
        cdef long long *pointer = <long long *> read_data(buffer, 8)
        cdef LongTag tag = LongTag.__new__(LongTag)
        tag.value_ = pointer[0]
        to_little_endian(&tag.value_, 8, little_endian)
        return tag


cdef class Named_ByteTag(ByteTag):
    def __init__(self, object value=0, str name=""):
        super().__init__(value)
        self.name = name

    def to_nbt(
        self,
        *,
        bint compressed=True,
        bint little_endian=False,
        str name="",
    ):
        return super().to_nbt(
            compressed=compressed,
            little_endian=little_endian,
            name=name or self.name
        )

    def save_to(
        self,
        object filepath_or_buffer=None,
        *,
        bint compressed=True,
        bint little_endian=False,
        str name="",
    ):
        return super().save_to(
            filepath_or_buffer,
            compressed=compressed,
            little_endian=little_endian,
            name=name or self.name
        )

    def __eq__(self, other):
        if isinstance(other, ByteTag) and super().__eq__(other):
            if isinstance(other, Named_ByteTag):
                return self.name == other.name
            return True
        return False

    def __repr__(self):
        return f'{self.__class__.__name__}({super().__repr__()}, "{self.name}")'

    def __dir__(self) -> List[str]:
        return list(set(list(super().__dir__()) + dir(self.value_)))

    def __copy__(self):
        return Named_ByteTag(self.value_, self.name)

    def __deepcopy__(self, memodict=None):
        return Named_ByteTag(
            deepcopy(self.value),
            self.name
        )

    def __reduce__(self):
        return Named_ByteTag, (self.value, self.name)


cdef class Named_ShortTag(ShortTag):
    def __init__(self, object value=0, str name=""):
        super().__init__(value)
        self.name = name

    def to_nbt(
        self,
        *,
        bint compressed=True,
        bint little_endian=False,
        str name="",
    ):
        return super().to_nbt(
            compressed=compressed,
            little_endian=little_endian,
            name=name or self.name
        )

    def save_to(
        self,
        object filepath_or_buffer=None,
        *,
        bint compressed=True,
        bint little_endian=False,
        str name="",
    ):
        return super().save_to(
            filepath_or_buffer,
            compressed=compressed,
            little_endian=little_endian,
            name=name or self.name
        )

    def __eq__(self, other):
        if isinstance(other, ShortTag) and super().__eq__(other):
            if isinstance(other, Named_ShortTag):
                return self.name == other.name
            return True
        return False

    def __repr__(self):
        return f'{self.__class__.__name__}({super().__repr__()}, "{self.name}")'

    def __dir__(self) -> List[str]:
        return list(set(list(super().__dir__()) + dir(self.value_)))

    def __copy__(self):
        return Named_ShortTag(self.value_, self.name)

    def __deepcopy__(self, memodict=None):
        return Named_ShortTag(
            deepcopy(self.value),
            self.name
        )

    def __reduce__(self):
        return Named_ShortTag, (self.value, self.name)


cdef class Named_IntTag(IntTag):
    def __init__(self, object value=0, str name=""):
        super().__init__(value)
        self.name = name

    def to_nbt(
        self,
        *,
        bint compressed=True,
        bint little_endian=False,
        str name="",
    ):
        return super().to_nbt(
            compressed=compressed,
            little_endian=little_endian,
            name=name or self.name
        )

    def save_to(
        self,
        object filepath_or_buffer=None,
        *,
        bint compressed=True,
        bint little_endian=False,
        str name="",
    ):
        return super().save_to(
            filepath_or_buffer,
            compressed=compressed,
            little_endian=little_endian,
            name=name or self.name
        )

    def __eq__(self, other):
        if isinstance(other, IntTag) and super().__eq__(other):
            if isinstance(other, Named_IntTag):
                return self.name == other.name
            return True
        return False

    def __repr__(self):
        return f'{self.__class__.__name__}({super().__repr__()}, "{self.name}")'

    def __dir__(self) -> List[str]:
        return list(set(list(super().__dir__()) + dir(self.value_)))

    def __copy__(self):
        return Named_IntTag(self.value_, self.name)

    def __deepcopy__(self, memodict=None):
        return Named_IntTag(
            deepcopy(self.value),
            self.name
        )

    def __reduce__(self):
        return Named_IntTag, (self.value, self.name)


cdef class Named_LongTag(LongTag):
    def __init__(self, object value=0, str name=""):
        super().__init__(value)
        self.name = name

    def to_nbt(
        self,
        *,
        bint compressed=True,
        bint little_endian=False,
        str name="",
    ):
        return super().to_nbt(
            compressed=compressed,
            little_endian=little_endian,
            name=name or self.name
        )

    def save_to(
        self,
        object filepath_or_buffer=None,
        *,
        bint compressed=True,
        bint little_endian=False,
        str name="",
    ):
        return super().save_to(
            filepath_or_buffer,
            compressed=compressed,
            little_endian=little_endian,
            name=name or self.name
        )

    def __eq__(self, other):
        if isinstance(other, LongTag) and super().__eq__(other):
            if isinstance(other, Named_LongTag):
                return self.name == other.name
            return True
        return False

    def __repr__(self):
        return f'{self.__class__.__name__}({super().__repr__()}, "{self.name}")'

    def __dir__(self) -> List[str]:
        return list(set(list(super().__dir__()) + dir(self.value_)))

    def __copy__(self):
        return Named_LongTag(self.value_, self.name)

    def __deepcopy__(self, memodict=None):
        return Named_LongTag(
            deepcopy(self.value),
            self.name
        )

    def __reduce__(self):
        return Named_LongTag, (self.value, self.name)
